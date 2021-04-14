import 'dart:async';
import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import 'package:chess_client/src/rest/conf.dart';
import 'package:chess_client/src/rest/interface.dart';
import "package:http/http.dart" as http;
import "dart:convert";
import "package:websocket/websocket.dart";

// Server is a definition of the server we communicate with.
class Server implements ServerService {
  final ServerConf conf;

  // InviteService
  final _invites = List<Invite>.empty(growable: true);
  final _inviteTimers = List<Timer>.empty(growable: true);

  List<Invite> get invites => _invites.toList(growable: false);
  Future<void> invite(String id) async {
    if (!inGame) {
      return _postRequest(
          Server.routes["invite"], jsonEncode(Invite(id).toJson()));
    }

    return Future.error("in game");
  }

  void cleanInvite() {
    _invites.clear();
    _inviteTimers.forEach((t) {
      if (t != null) t.cancel();
    });
    _inviteTimers.clear();

    _notify(OrderID.Invite, null);
  }

  Future<void> acceptInvite(String id) async {
    if (!inGame) {
      final fut = Completer<void>();
      this
          ._postRequest(
              Server.routes["accept"], jsonEncode(Invite(id).toJson()))
          .then((_) {
        fut.complete();
        cleanInvite();
      }).catchError((e) {
        _invites.remove(id);
        fut.completeError(e);
      });

      return fut.future;
    }

    return Future.error("in game");
  }

  Future<List<String>> getAvaliableUsers() async {
    final c = Completer<List<String>>();
    _getRequest(Server.routes["avali"]).then((str) {
      final obj = jsonDecode(str);
      final List<String> list = obj != null ? List.from(obj) : null;
      c.complete(list);
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  // SubscribeService
  final Map<OrderID, Function(dynamic)> _event = {};
  void subscribe(OrderID id, Function(dynamic) callback) {
    if (callback == null) throw "callback is null";
    /*
    if (_event.containsKey(id))
      throw "there's already a subscribed function to this id";
      */

    _event[id] = callback;
  }

  void unsubscribe(OrderID id) {
    if (!_event.containsKey(id)) return;

    _event.remove(id);
  }

  bool isSubscribed(OrderID id) {
    return _event.containsKey(id);
  }

  void _notify(OrderID id, dynamic value) {
    if (!_event.containsKey(id)) throw "no subscription attached to this id";

    _event[id](value);
  }

  // BoardSystem
  bool _playerTurn;
  Game _game;
  bool get playerTurn => _playerTurn;
  bool get inGame => _game != null;
  bool get p1 => inGame ? _game.p1 : null;
  Board get board => inGame ? _game.board : null;

  Future<HashMap<String, Point>> possib(int id) async {
    final c = Completer<HashMap<String, Point>>();
    _postRequest(Server.routes["possib"], jsonEncode(Possible(id, null)))
        .then((body) {
      final json = jsonDecode(body);
      final map = <String, Point>{};

      (json["points"] as Map<String, dynamic>)
          .forEach((String name, dynamic value) {
        map[name] = Point.fromJson(value);
      });

      c.complete(map as HashMap<String, Point>);
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  Future<void> leaveGame() async {
    if (!inGame) return Future.error("not in game");

    return _sendCommand(Order(
      OrderID.Done,
      Done(p1),
    ));
  }

  Future<void> promote(int id, int type) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (p1 != playerTurn) {
      return Future.error("not your turn");
    }

    if (!(id <= 31 && id >= 0)) {
      return Future.error("parameters are invalid");
    }

    return _sendCommand(Order(
      OrderID.Promote,
      Promote(id, type),
    ));
  }

  Future<void> move(int id, Point dst) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (p1 != playerTurn) {
      return Future.error("not your turn");
    }

    if (!(id >= 0 && id <= 31) || dst == null || !dst.valid()) {
      return Future.error("parameters are invalid");
    }

    return _sendCommand(Order(
      OrderID.Move,
      Move(id, dst),
    ));
  }

  bool ourTurn() {
    if (!inGame) {
      throw "not in game";
    }

    return playerTurn == p1;
  }

  // WebsocketService
  Credentials _credentials;
  String get publicId => _credentials.publicId;
  WebSocket _socket;

  bool isConnected() {
    if (_socket != null) {
      return true;
    }

    return false;
  }

  Future<void> disconnect() async {
    if (isConnected()) {
      _socket.close(WebSocketStatus.normalClosure);
    } else {
      return Future.error("not connected");
    }
  }

  Future<void> connect() async {
    if (isConnected()) {
      return Future.error("already connected");
    }

    final c = Completer<void>();

    WebSocket.connect(conf.ws(Server.routes["ws"])).then((ws) {
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

                _credentials = cred;
                _headers["Authorization"] = "Bearer ${cred.token}";
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

                board.set(move.id, move.dst);
              } catch (e) {
                print("listen.move: $e");
              }
              break;
            case OrderID.Promote:
              try {
                final promote = Promote.fromJson(o.obj);

                _notify(OrderID.Promote, promote);
              } catch (e) {
                print("listen.promote: $e");
              }
              break;
            case OrderID.Promotion:
              try {
                final promotion = Promotion.fromJson(o.obj);

                board.setKind(promotion.id, promotion.kind);
              } catch (e) {
                print("listen.promotion: $e");
              }
              break;
            case OrderID.Castling:
              // trust server data
              try {
                final move = Castling.fromJson(o.obj);

                final king = board.getByIndex(move.src);
                final rook = board.getByIndex(move.dst);

                if (king.kind != PieceKind.king)
                  throw "bad type. should be king, instead got ${king.kind}";
                else if (rook.kind != PieceKind.rook)
                  throw "bad type. should be rook, instead got ${rook.kind}";

                int rookx;
                int kingx;
                if (rook.pos.x == 0) {
                  rookx = 3;
                  kingx = 2;
                } else if (rook.pos.x == 7) {
                  rookx = 5;
                  kingx = 6;
                }

                board.set(move.src, Point(kingx, king.pos.y));
                board.set(move.dst, Point(rookx, rook.pos.y));
              } catch (e) {
                print("listen.castling: $e");
              }
              break;
            case OrderID.Turn:
              try {
                final turn = Turn.fromJson(o.obj);

                _playerTurn = turn.p1;
                _notify(OrderID.Turn, turn);
              } catch (e) {
                print("listen.turn: $e");
              }
              break;
            case OrderID.Checkmate:
              try {
                final checkmate = Turn.fromJson(o.obj);

                _notify(OrderID.Checkmate, checkmate);
              } catch (e) {
                print("listen.checkmate: $e");
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
        //print("websocket done ${ws.closeCode}, ${ws.closeReason}");
        _notify(OrderID.Disconnect, null);
        _clean();
      });

      try {
        _notify(OrderID.Credentials, null);
      } catch (e) {
        c.completeError(e);
      }
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  // internal
  static const reconnectDuration = Duration(seconds: 30);
  static const routes = {
    // where to send cmd requests
    "cmd": "cmd",
    // where to send invite request
    "invite": "invite",
    // where to accept invite requests
    "accept": "accept",
    // where to upgrade http connection to websocket
    "ws": "ws",
    // where to send requests to test authorization.
    "protect": "protect",
    // where to get users that want to play
    "avali": "avali",
    // where to get avaliable moves
    "possib": "possib",
  };

  final Map<String, String> _headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String> _getRequest(String route) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = conf.http(route);

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

  Future<String> _postRequest(String route, String data) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = conf.http(route);

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

  Future<void> _sendCommand(Order cmd) async {
    String json = "";
    try {
      json = jsonEncode(cmd);
    } catch (e) {
      return Future.error(e);
    }

    return _postRequest(Server.routes["cmd"], json);
  }

  void _clean() async {
    _game = null;
    _headers.remove("Authorization");
    _socket = null;
    cleanInvite();
  }

  void _inviteReceiver(Invite i) {
    _invites.add(i);

    _notify(OrderID.Invite, null);

    _inviteTimers.add(Timer(Invite.expiry, () {
      if (_invites.length > 0) {
        _invites.removeLast();
      }
    }));
  }

  void _gameReceiver(Game g) {
    _game = g;
    _notify(OrderID.Game, null);
    // no need to clear invite. acceptInvite does it automatically.
  }

  void _doneReceiver(Done d) {
    _notify(OrderID.Done, d);
    _game = null;
  }

  Server(this.conf);
}
