import 'dart:async';

import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/game/command.dart';
import 'package:chess_client/src/game/command_model.dart';
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

  String _id = "";

  static const _routes = {
    // where to send cmd requests
    "cmd": "/cmd",
    // where to send invite request
    "inv": "/inv",
    // where to accept invite requests
    "accept": "/accept",
    // where to upgrade http connection to websocket
    "ws": "/ws",
  };
  WebSocket _socket;

  Future<void> _request(String route, String data) async {
    if (this._socket == null) {
      return Future.error("socket is null");
    }

    final c = Completer();

    final String url = this.conf.http(route);
    final Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer ${this._id}",
    };

    try {
      http.post(url, body: data, headers: headers).then((r) {
        print("asdads");
        if (r.statusCode != 200) {
          c.completeError("${r.body}");
        }
      });
    } catch (e) {
      c.completeError(e);
    }

    return c.future;
  }

  Future<void> sendCommand(Command cmd) async {
    return this._request(Server._routes["cmd"], jsonEncode(cmd));
  }

  Future<void> cmdPiece(Point src, Point dst) async {
    String data = "";
    try {
      data = jsonEncode(ModelCmdPiece(src, dst));
    } catch (e) {
      return Future.error(e);
    }

    final cmd = Command(CommandID.Piece, data);
    return sendCommand(cmd);
  }

  Future<void> invite(String id) async {
    final json = <String, String>{"id": id};
    return this._request(Server._routes["inv"], jsonEncode(json));
  }

  Future<void> acceptInvite(String id) async {
    final json = <String, String>{"id": id};
    return this._request(Server._routes["accept"], jsonEncode(json));
  }

  Future<void> connect() async {
    WebSocket.connect(this.conf.ws(Server._routes["ws"])).then((ws) {
      this._socket = ws;
      return;
      // TODO: add onclose function..
    }).catchError((e) {
      throw e;
    });
  }

  Server(this.conf);
}
