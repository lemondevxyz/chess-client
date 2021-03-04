import 'dart:async';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import "package:event/event.dart";
import 'package:chess_client/src/board/generator.dart';
import "package:http/http.dart" as http;
import "dart:io";
import "dart:convert";

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

  // lock for invite system;
  int _playerTurn;
  Game _game;

  int get playerTurn => _playerTurn;
  bool get inGame => _game != null;
  int get player => _game.player;
  Board get board => _game.board;

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
      });
    } catch (e) {
      c.completeError(e);
    }

    return c.future;
  }

  Future<void> postRequest(String route, String data) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer();
    final String url = this.conf.http(route);

    try {
      http.post(url, body: data, headers: _headers).then((r) {
        if (r.statusCode != 200) {
          c.completeError("${r.body}");
        } else {
          c.complete();
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

  Future<void> cmdPiece(Point src, Point dst) async {
    return sendCommand(Order(OrderID.Move, Move(src, dst)));
  }

  Future<void> move(Point src, Point dst) {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (player != playerTurn) {
      return Future.error("not your turn");
    }

    if (!src.valid() || !dst.valid()) {
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
      if (_socket.readyState == WebSocket.open) {
        return true;
      }
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

  Future<void> connect() async {
    if (isConnected()) {
      return Future.error("already connected");
    }

    final c = Completer<void>();

    WebSocket.connect(this.conf.ws(Server.routes["ws"])).then((ws) {
      c.complete();

      onConnect.broadcast();
      _socket = ws;

      ws.listen((data) {
        final map = jsonDecode(data);
        if (map is Map<String, dynamic>) {
          final o = Order.fromJson(map);
          switch (o.id) {
            case OrderID.Credentials:
              try {
                final cred = Credentials.fromJson(o.obj);
                _credentialsReceiver(cred);
              } catch (e) {}
              break;
            case OrderID.Invite:
              try {
                final inv = Invite.fromJson(o.obj);
                _inviteReceiver(inv);
              } catch (e) {}
              break;
            case OrderID.Move:
              try {
                final move = Move.fromJson(o.obj);
                _moveReceiver(move);
              } catch (e) {}
              break;
            case OrderID.Turn:
              try {
                final turn = Turn.fromJson(o.obj);
                _turnReceiver(turn);
              } catch (e) {}
              break;
            case OrderID.Game:
              try {
                final g = Game.fromJson(o.obj);
                _gameReceiver(g);
              } catch (e) {}
              break;
            case OrderID.Done:
              try {
                final d = Done.fromJson(o.obj);
                _doneReceiver(d);
              } catch (e) {}
          }
        }
      });

      ws.done.then((_) {
        print("done");
        this.onDisconnect.broadcast();
        this._clean();
      });
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  void _credentialsReceiver(Credentials c) {
    this._credentials = c;
    this._headers["Authorization"] = "Bearer ${c.token}";
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
    // no need to clear everything. acceptInvite does it automatically.
  }

  void _moveReceiver(Move m) {
    if (inGame) {
      board.move(board.get(m.src), m.dst);
    }
  }

  void _turnReceiver(Turn t) {
    print("adssa ${t.toJson()}");
    if (inGame) {
      this._playerTurn = t.player;
    } else {
      this._playerTurn = 0;
    }
  }

  void _doneReceiver(Done d) {
    this._game = null;
  }

  Server(this.conf);
}
