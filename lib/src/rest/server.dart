import 'dart:async';

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

  String get publicId {
    return this._credentials.publicId;
  }

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

  final Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  WebSocket _socket;

  final update = Event<Order>();

  Future<String> getRequest(String route) async {
    if (this._socket == null) {
      return Future.error("socket is null");
    }

    final c = Completer<String>();
    final String url = this.conf.http(route);

    try {
      http.get(url, headers: headers).then((r) {
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
    if (this._socket == null) {
      return Future.error("socket is null");
    }

    final c = Completer();
    final String url = this.conf.http(route);

    try {
      http.post(url, body: data, headers: headers).then((r) {
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

  Future<void> invite(String id) async {
    return this
        .postRequest(Server.routes["invite"], jsonEncode(Invite(id).toJson()));
  }

  Future<void> acceptInvite(String id) async {
    return this
        .postRequest(Server.routes["accept"], jsonEncode(Invite(id).toJson()));
  }

  Future<void> connect() async {
    final fut = Completer<void>();
    final handler = (Order o) {
      if (o.id == OrderID.Credentials) {
        final cred = Credentials.fromJson(o.obj);
        this._credentials = cred;
        this.headers["Authorization"] = "Bearer ${cred.token}";
      }
    };
    this.update.subscribe(handler);

    WebSocket.connect(this.conf.ws(Server.routes["ws"])).then((ws) {
      this._socket = ws;
      ws.listen((data) {
        final map = jsonDecode(data);
        if (map is Map<String, dynamic>) {
          this.update.broadcast(Order.fromJson(map));
        }
      });
      fut.complete();
      // TODO: add onclose function..
    }).catchError((e) {
      fut.completeError(e);
    });

    return fut.future;
  }

  Server(this.conf);
}
