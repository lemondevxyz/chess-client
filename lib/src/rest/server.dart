import 'dart:async';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import "package:event/event.dart";
import 'package:chess_client/src/board/generator.dart';
import "package:http/http.dart" as http;
import "dart:convert";
import "package:websocket/websocket.dart";

class ServerConf {
  // amount of time to wait, before we completely stop trying to reconnect.
  bool ssl;
  Duration timeout;

  Uri url;

  String earl(String proto, String path) {
    return Uri(
            scheme: proto, host: this.url.host, port: this.url.port, path: path)
        .toString();
  }

  String http(String path) {
    String proto = "http";
    if (this.ssl) {
      proto = "https";
    }

    return this.earl(proto, path);
  }

  String ws(String path) {
    String proto = "ws";
    if (this.ssl) {
      proto = "wss";
    }

    return this.earl(proto, path);
  }

  ServerConf(bool ssl, String host, int port, Duration timeout) {
    this.url = Uri(
      host: host,
      port: port,
    );
    this.ssl = ssl;
    this.timeout = timeout;
  }
}

final defaultServConf =
    ServerConf(false, "localhost", 8080, Duration(seconds: 20));

// Server is a definition of the server we communicate with.
class Server {
  final ServerConf conf;

  Credentials _credentials;

  String get publicId => this._credentials.publicId;

  static const reconnectDuration = Duration(seconds: 30);
  static const routes = {
    // where to send cmd requests
    "cmd": "/cmd",
    // where to send invite request
    "invite": "/invite",
    // where to accept invite requests
    "accept": "/accept",
    // where to upgrade http connection to websocket
    "ws": "/ws",
    // where to send requests to test authorization.
    "protect": "/protect",
    // where to get users that want to play
    "avali": "/avali",
    // where to get avaliable moves
    "possib": "/possib",
  };

  final Map<String, String> _headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  WebSocket _socket;

  // easier cancellation later
  final invites = List<Invite>.empty(growable: true);
  final _inviteTimers = List<Timer>.empty(growable: true);

  // events
  final onConnect = Event(); // on websocket connection
  final onDisconnect = Event(); // on websocket disconnection
  final onInvite = Event(); // on invite, whenever the player receives an invite
  final onGame = Event(); // on game, whenever a game starts
  final onTurn = Event(); // when the turn changes
  final onPromote = Event<Promote>();

  // lock for invite system;
  int _playerTurn;
  Game _game;

  int get playerTurn => _playerTurn;
  bool get inGame => _game != null;
  int get player => inGame ? _game.player : 0;
  Board get board => inGame ? _game.board : null;

  Future<String> getRequest(String route) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = this.conf.http(route);

    try {
      http.get(url, headers: _headers).then((r) {
        if (r.statusCode != 200) {
          c.completeError("${r.body}");
        } else {
          c.complete(r.body);
        }
      }).catchError((e) {
        c.completeError(e);
      });
    } catch (e) {
      c.completeError(e);
    }

    return c.future;
  }

  Future<String> postRequest(String route, String data) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = this.conf.http(route);

    try {
      http.post(url, body: data, headers: _headers).then((r) {
        if (r.statusCode != 200) {
          c.completeError("${r.body}");
        } else {
          c.complete(r.body);
        }
      });
    } catch (e) {
      c.completeError(e);
    }

    return c.future;
  }

  Future<List<String>> getAvaliableUsers() async {
    final c = Completer<List<String>>();
    getRequest(Server.routes["avali"]).then((str) {
      final obj = jsonDecode(str);
      final List<String> list = obj != null ? List.from(obj) : null;
      c.complete(list);
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  Future<void> sendCommand(Order cmd) async {
    String json = "";
    try {
      json = jsonEncode(cmd);
    } catch (e) {
      return Future.error(e);
    }

    return this.postRequest(Server.routes["cmd"], json);
  }

  Future<List<Point>> possib(Point src) async {
    final c = Completer<List<Point>>();
    postRequest(Server.routes["possib"], jsonEncode(Possible(src, null)))
        .then((body) {
      final json = jsonDecode(body);
      final ls = <Point>[];

      (json["points"] as List<dynamic>).forEach((x) {
        if (x is Map<String, dynamic>) {
          ls.add(Point.fromJson(x));
        }
      });

      c.complete(ls);
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  Future<void> promote(Point src, int type) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (player != playerTurn) {
      return Future.error("not your turn");
    }

    if (src == null || !src.valid()) {
      return Future.error("parameters are invalid");
    }

    return this.sendCommand(Order(
      OrderID.Promote,
      Promote(type, src),
    ));
  }

  Future<void> move(Point src, Point dst) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (player != playerTurn) {
      return Future.error("not your turn");
    }

    if (src == null || dst == null || !src.valid() || !dst.valid()) {
      return Future.error("parameters are invalid");
    }

    return this.sendCommand(Order(
      OrderID.Move,
      Move(src, dst),
    ));
  }

  Future<void> invite(String id) async {
    if (!inGame) {
      return this.postRequest(
          Server.routes["invite"], jsonEncode(Invite(id).toJson()));
    }

    return Future.error("in game");
  }

  bool isConnected() {
    if (_socket != null) {
      return true;
    }

    return false;
  }

  void _clean() async {
    _game = null;
    _headers.remove("Authorization");
    _socket = null;
    cleanInvite();
  }

  void cleanInvite() {
    this.invites.clear();
    this._inviteTimers.forEach((t) {
      t.cancel();
    });
    this._inviteTimers.clear();
    this.onInvite.broadcast();
  }

  Future<void> acceptInvite(String id) async {
    if (!inGame) {
      final fut = Completer<void>();
      this
          .postRequest(Server.routes["accept"], jsonEncode(Invite(id).toJson()))
          .then((_) {
        fut.complete();
        this.cleanInvite();
      }).catchError((e) {
        this.invites.remove(id);
        fut.completeError(e);
      });

      return fut.future;
    }

    return Future.error("in game");
  }

  Future<void> disconnect() async {
    if (isConnected()) {
      _socket.close(WebSocketStatus.normalClosure);
    } else {
      return Future.error("not connected");
    }
  }

  bool ourTurn() {
    if (!inGame) {
      throw "not in game";
    }

    return playerTurn == _game.player;
  }

  Future<void> connect() async {
    if (isConnected()) {
      return Future.error("already connected");
    }

    final c = Completer<void>();

    WebSocket.connect(this.conf.ws(Server.routes["ws"])).then((ws) {
      c.complete();

      _socket = ws;

      ws.stream.listen((data) {
        final map = jsonDecode(data);
        if (map is Map<String, dynamic>) {
          final o = Order.fromJson(map);
          switch (o.id) {
            case OrderID.Credentials:
              try {
                final cred = Credentials.fromJson(o.obj);

                this._credentials = cred;
                this._headers["Authorization"] = "Bearer ${cred.token}";
              } catch (e) {
                print("listen.credentials: $e");
              }
              break;
            case OrderID.Invite:
              try {
                final inv = Invite.fromJson(o.obj);
                _inviteReceiver(inv);
              } catch (e) {
                print("listen.invite: $e");
              }
              break;
            case OrderID.Move:
              try {
                final move = Move.fromJson(o.obj);

                final pec = board.get(move.src);
                pec.pos = move.dst;
                board.set(Piece(move.src, PieceKind.empty, 0));
                board.set(pec);
              } catch (e) {
                print("listen.move: $e");
              }
              break;
            case OrderID.Promote:
              try {
                final promote = Promote.fromJson(o.obj);
                onPromote.broadcast(promote);
                print("we can promote bro");
              } catch (e) {
                print("listen.promote: $e");
              }
              break;
            case OrderID.Promotion:
              try {
                final promotion = Promotion.fromJson(o.obj);

                final pec = board.get(promotion.dst);
                if (pec == null) {
                  print(
                      "listen.promotion: null piece, something wrong with the synchrozation");
                  return;
                }

                board.set(Piece(pec.pos, promotion.type, pec.num));
              } catch (e) {
                print("listen.promotion: $e");
              }
              break;
            case OrderID.Castling:
              try {
                final move = Move.fromJson(o.obj);

                int rooky;
                int kingy;
                if (move.src.y == 0 || move.dst.y == 0) {
                  rooky = 3;
                  kingy = 2;
                } else if (move.src.y == 7 || move.dst.y == 7) {
                  rooky = 5;
                  kingy = 6;
                } else {
                  print("listen.castling: hmm wrong format $move");
                }

                if (rooky != 0 && kingy != 0) {
                  final pec = board.get(move.src);
                  if (pec == null) {
                    print(
                        "listen.castling: null castling, something wrong with the synchrozation");
                    return;
                  }

                  board.set(Piece(move.src, PieceKind.empty, 0));
                  board.set(Piece(move.dst, PieceKind.empty, 0));

                  board.set(
                      Piece(Point(move.src.x, rooky), PieceKind.rook, pec.num));
                  board.set(
                      Piece(Point(move.src.x, kingy), PieceKind.king, pec.num));
                }
              } catch (e) {
                print("listen.castling: $e");
              }
              break;
            case OrderID.Turn:
              try {
                final turn = Turn.fromJson(o.obj);
                this._playerTurn = turn.player;
              } catch (e) {
                print("listen.turn: $e");
              }
              break;
            case OrderID.Game:
              try {
                final g = Game.fromJson(o.obj);
                _gameReceiver(g);
              } catch (e) {
                print("listen.game: $e");
              }
              break;
            case OrderID.Done:
              try {
                final d = Done.fromJson(o.obj);
                _doneReceiver(d);
              } catch (e) {
                print("listen.done: $e");
              }
          }
        }
      });

      ws.done.then((_) {
        print("websocket done ${ws.closeCode}, ${ws.closeReason}");
        this.onDisconnect.broadcast();
        this._clean();
      });

      try {
        onConnect.broadcast();
      } catch (e) {
        c.completeError(e);
      }
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  void _inviteReceiver(Invite i) {
    this.invites.add(i);
    this.onInvite.broadcast();

    this._inviteTimers.add(Timer(Invite.expiry, () {
          if (this.invites.length > 0) {
            this.invites.removeLast();
          }
        }));
  }

  void _gameReceiver(Game g) {
    this._game = g;
    onGame.broadcast();
    // no need to clear invite. acceptInvite does it automatically.
  }

  void _doneReceiver(Done d) {
    this._game = null;
  }

  Server(this.conf);
}
