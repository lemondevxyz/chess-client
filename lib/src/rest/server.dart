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

  // platforms
  final platforms = <String>[];

  Future<void> refreshPlatform(String platform) async {
    final com = Completer<void>();

    http.get(conf.http(platform + "/private")).then((http.Response r) {
      if (r.statusCode == 404) {
        com.completeError("404 on $platform");
      } else {
        com.complete();
      }
    }).catchError((e) {
      com.completeError(e);
    });

    return com.future;
  }

  Future<void> refreshPlatforms() async {
    final c = Completer<void>();

    platforms.clear();

    refreshPlatform("discord")
        .then((_) => platforms.add("discord"))
        .whenComplete(() {
      refreshPlatform("google")
          .then((_) => platforms.add("google"))
          .whenComplete(() {
        refreshPlatform("github")
            .then((_) => platforms.add("github"))
            .whenComplete(() {
          c.complete();
        }).catchError((_) {});
      }).catchError((_) {});
    }).catchError((_) {});

    return c.future;
  }

  // isLoggedIn sends a request a private route, to check if the user is logged in or not.
  Future<bool> isLoggedIn() {
    final c = Completer<bool>();

    final String url = conf.http(Server.routes["private"]);
    http.get(url, headers: _headers).then((http.Response r) {
      if (r.statusCode == 200)
        c.complete(true);
      else
        c.complete(false);
    }).catchError((e) {
      c.completeError("offline");
    });

    return c.future;
  }

  // InviteService
  final _invites = List<order.Invite>.empty(growable: true);
  final _inviteTimers = List<Timer>.empty(growable: true);

  List<order.Invite> get invites => _invites.toList(growable: false);
  Future<void> invite(model.Profile pro) async {
    if (!inGame) {
      return _postRequest(
          Server.routes["invite"],
          jsonEncode(<String, dynamic>{
            "profile": pro.toJson(),
          }));
    }

    return Future.error("in game");
  }

  void cleanInvite() {
    _invites.clear();
    _inviteTimers.forEach((t) {
      if (t != null) t.cancel();
    });
    _inviteTimers.clear();
  }

  Future<void> acceptInvite(order.Invite ord) async {
    if (!inGame) {
      final fut = Completer<void>();
      this
          ._postRequest(Server.routes["accept"], jsonEncode(ord.toJson()))
          .then((_) {
        fut.complete();
        cleanInvite();
        _notify(order.OrderID.Invite, null);
      }).catchError((e) {
        _invites.remove(ord);

        _notify(order.OrderID.Invite, null);

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

    watchables.clear();

    _getRequest(routes["watchable/list"]).then((String str) {
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

  Future<void> joinWatchable(model.Generic m) {
    final c = Completer<void>();
    _postRequest(routes["watchable/join"], jsonEncode(m)).then((String s) {
      try {
        _profile = model.GameProfile.fromJson(jsonDecode(s));
        if (_game != null) {
          _notify(order.OrderID.Game, null);
          cleanInvite();
        }

        c.complete();
      } catch (e) {
        c.completeError(e);
      }
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  Future<void> leaveWatchable() {
    final c = Completer<void>();
    _postRequest(routes["watchable/leave"], "").then((_) {
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

  model.GameProfile _profile;
  model.GameProfile get profile => _profile;

  Board get board => inGame ? _game.brd : null;

  Future<HashMap<String, Point>> possib(int id) async {
    if (!inGame) return Future.error("you have to be in game");

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
      order.Done(0),
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

  model.Profile get playerprofile => _credentials.profile;

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

    isLoggedIn().then((bool b) {
      if (!b) {
        print("yoo no authorized");
        c.completeError("unauthorized");
      } else {
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
                  break;
              }
            }
          });

          ws.done.then((_) {
            //print("websocket done ${ws.closeCode}, ${ws.closeReason}");
            try {
              _notify(order.OrderID.Disconnect, null);
            } catch (e) {}
            _clean();
          });

          try {
            _notify(order.OrderID.Credentials, null);
          } catch (e) {}
        }).catchError((e) {
          c.completeError(e);
        });
      }
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  // internal
  static const reconnectDuration = Duration(seconds: 30);
  static const routes = {
    // where to send cmd requests, only works in game
    "cmd": "cmd",
    // where to send invite request
    "invite": "invite",
    // where to accept invite requests
    "accept": "accept",
    // where to upgrade http connection to websocket
    "ws": "ws",
    // where to send requests to test authorization.
    "private": "private",
    // where to get users that are not in game
    "avali": "avali",
    // where to get avaliable moves(only in game)
    "possib": "possib",
    // where to get watchable games
    "watchable/list": "watchable/list",
    // where to join watchable games
    "watchable/join": "watchable/join",
    // where to a watchable game(only works when spectacting)
    "watchable/leave": "watchable/leave",
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
        c.complete(r.body);
      }
    }).catchError((e) {
      c.completeError(e);
    });

    return c.future;
  }

  Future<String> _postRequest(String route, String data) async {
    if (!isConnected()) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = conf.http(routes[route]);

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
    if (!inGame) return Future.error("you must be in game");

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

  void _gameReceiver(order.Game g) async {
    _game = g;
    if (_game.profile != null) {
      final p1 = g.p1;

      _profile = model.GameProfile(
        p1 ? playerprofile : _game.profile,
        !p1 ? playerprofile : _game.profile,
      );

      _notify(order.OrderID.Game, null);
      cleanInvite();
    }
  }

  void _doneReceiver(order.Done d) {
    _notify(order.OrderID.Done, d);
    _game = null;
  }

  Server(this.conf);
}
