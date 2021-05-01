import 'dart:async';
import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/board/utils.dart' as utils;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/rest/conf.dart';
import 'package:chess_client/src/rest/interface.dart';
import "package:http/http.dart" as http;
import "dart:convert";
import "package:websocket/websocket.dart";

// Server is a definition of the server we communicate with.
class Server implements ServerService {
  final ServerConf conf;

  // InviteService
  final _invites = List<order.Invite>.empty(growable: true);
  final _inviteTimers = List<Timer>.empty(growable: true);

  List<order.Invite> get invites => _invites.toList(growable: false);
  Future<void> invite(String id, String platform) async {
    if (!inGame) {
      final inv = order.Invite(id);
      inv.platform = platform;

      return _postRequest(Server.routes["invite"], jsonEncode(inv.toJson()));
    }

    return Future.error("in game");
  }

  void cleanInvite() {
    _invites.clear();
    _inviteTimers.forEach((t) {
      if (t != null) t.cancel();
    });
    _inviteTimers.clear();

    _notify(order.OrderID.Invite, null);
  }

  Future<void> acceptInvite(String id) async {
    if (!inGame) {
      final fut = Completer<void>();
      this
          ._postRequest(
              Server.routes["accept"], jsonEncode(order.Invite(id).toJson()))
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

  Future<List<model.Profile>> getAvaliableUsers() async {
    final c = Completer<List<model.Profile>>();
    _getRequest(Server.routes["avali"]).then((str) {
      final obj = jsonDecode(str) as List<dynamic>;
      final list = <model.Profile>[];

      obj.asMap().forEach((int i, dynamic d) {
        list.add(model.Profile.fromJson(d as Map<String, dynamic>));
      });

      c.complete(list);
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  // WatchableService
  final watchables = HashMap<String, model.Watchable>();
  Future<void> refreshWatchable() {
    final c = Completer<void>();
    _getRequest("watchable").then((String str) {
      final Map<String, dynamic> m = jsonDecode(str);
      m.forEach((index, d) {
        final decode = model.Watchable.fromJson(d);
        watchables[index] = decode;
      });

      c.complete();
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  // SubscribeService
  final Map<order.OrderID, Function(dynamic)> _event = {};
  void subscribe(order.OrderID id, Function(dynamic) callback) {
    if (callback == null) throw "callback is null";

    _event[id] = callback;
  }

  void unsubscribe(order.OrderID id) {
    if (!_event.containsKey(id)) return;

    _event.remove(id);
  }

  bool isSubscribed(order.OrderID id) {
    return _event.containsKey(id);
  }

  void _notify(order.OrderID id, dynamic value) {
    if (!_event.containsKey(id)) throw "no subscription attached to this id";

    _event[id](value);
  }

  // BoardSystem
  bool _playerTurn;
  order.Game _game;
  bool get playerTurn => _playerTurn;
  bool get inGame => _game != null;
  bool get p1 => inGame ? _game.p1 : null;
  Board get board => inGame ? _game.brd : null;

  Future<HashMap<String, Point>> possib(int id) async {
    final c = Completer<HashMap<String, Point>>();
    _postRequest(Server.routes["possib"], jsonEncode(model.Possible(id, null)))
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

    return _sendCommand(order.Order(
      order.OrderID.Done,
      order.Done(p1),
    ));
  }

  Future<void> promote(int id, int type) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (p1 != playerTurn) {
      return Future.error("not your turn");
    }

    if (!(utils.isIDValid(id))) {
      return Future.error("parameters are invalid");
    }

    return _sendCommand(order.Order(
      order.OrderID.Promote,
      order.Promote(id, type),
    ));
  }

  Future<void> move(int id, Point dst) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (p1 != playerTurn) {
      return Future.error("not your turn");
    }

    if (!(utils.isIDValid(id)) || dst == null || !dst.valid()) {
      return Future.error("parameters are invalid");
    }

    return _sendCommand(order.Order(
      order.OrderID.Move,
      order.Move(id, dst),
    ));
  }

  Future<void> castling(int src, int dst) async {
    if (!inGame) {
      return Future.error("not in game");
    }

    if (p1 != playerTurn) {
      return Future.error("not your turn");
    }

    if (!(utils.isIDValid(src)) && !(utils.isIDValid(dst))) {
      return Future.error("bad parameters");
    }

    return _sendCommand(order.Order(
      order.OrderID.Castling,
      order.Castling(src, dst),
    ));
  }

  bool ourTurn() {
    if (!inGame) {
      throw "not in game";
    }

    return playerTurn == p1;
  }

  // WebsocketService
  order.Credentials _credentials;

  model.Profile get profile => _credentials.profile;
  model.Profile get vsprofile => _game.profile;

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
          final o = order.Order.fromJson(map);
          switch (o.id) {
            case order.OrderID.Credentials:
              try {
                final cred = order.Credentials.fromJson(o.obj);

                _credentials = cred;
                _headers["Authorization"] = "Bearer ${cred.token}";
              } catch (e) {
                print("listen.credentials: $e");
              }
              break;
            case order.OrderID.Invite:
              try {
                final inv = order.Invite.fromJson(o.obj);
                _inviteReceiver(inv);
              } catch (e) {
                print("listen.invite: $e");
              }
              break;
            case order.OrderID.Move:
              try {
                final move = order.Move.fromJson(o.obj);

                board.set(move.id, move.dst);
              } catch (e) {
                print("listen.move: $e");
              }
              break;
            case order.OrderID.Promote:
              try {
                final promote = order.Promote.fromJson(o.obj);

                _notify(order.OrderID.Promote, promote);
              } catch (e) {
                print("listen.promote: $e");
              }
              break;
            case order.OrderID.Promotion:
              try {
                final promotion = order.Promotion.fromJson(o.obj);

                board.setKind(promotion.id, promotion.kind);
              } catch (e) {
                print("listen.promotion: $e");
              }
              break;
            case order.OrderID.Castling:
              // trust server data
              try {
                final move = order.Castling.fromJson(o.obj);

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
            case order.OrderID.Turn:
              try {
                final turn = order.Turn.fromJson(o.obj);

                _playerTurn = turn.p1;
                _notify(order.OrderID.Turn, turn);
              } catch (e) {
                print("listen.turn: $e");
              }
              break;
            case order.OrderID.Checkmate:
              try {
                final checkmate = order.Turn.fromJson(o.obj);

                _notify(order.OrderID.Checkmate, checkmate);
              } catch (e) {
                print("listen.checkmate: $e");
              }
              break;
            case order.OrderID.Game:
              try {
                final g = order.Game.fromJson(o.obj);
                _gameReceiver(g);
              } catch (e) {
                print("listen.game: $e");
              }
              break;
            case order.OrderID.Done:
              try {
                final d = order.Done.fromJson(o.obj);
                _doneReceiver(d);
              } catch (e) {
                print("listen.done: $e");
              }
          }
        }
      });

      ws.done.then((_) {
        //print("websocket done ${ws.closeCode}, ${ws.closeReason}");
        _notify(order.OrderID.Disconnect, null);
        _clean();
      });

      try {
        _notify(order.OrderID.Credentials, null);
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
    // where to get watchable games
    "watchable": "watchable",
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

    http.get(url, headers: _headers).then((r) {
      if (r.statusCode != 200) {
        c.completeError("${r.body}");
      } else {
        //print("get statuscode ${r.body}");
        c.complete(r.body);
      }
    }).catchError((e) {
      // print("get $e");
      c.completeError(e);
    });

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
          // print("post statuscode ${r.body}");
          c.complete(r.body);
        }
      });
    } catch (e) {
      // print("post ee $e");
      c.completeError(e);
    }

    return c.future;
  }

  Future<void> _sendCommand(order.Order cmd) async {
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

  void _inviteReceiver(order.Invite i) {
    _invites.add(i);

    _notify(order.OrderID.Invite, null);

    _inviteTimers.add(Timer(order.Invite.expiry, () {
      if (_invites.length > 0) {
        _invites.removeLast();
      }
    }));
  }

  void _gameReceiver(order.Game g) {
    _game = g;
    _notify(order.OrderID.Game, null);
    cleanInvite();
  }

  void _doneReceiver(order.Done d) {
    _notify(order.OrderID.Done, d);
    _game = null;
  }

  Server(this.conf);
}
