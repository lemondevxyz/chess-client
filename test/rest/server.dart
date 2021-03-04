import 'dart:async';
import 'package:event/event.dart';
import "package:test/test.dart";
import "package:chess_client/src/rest/server.dart";

void main() {
  // all these tests require chess-server to be running.
  final p1 = Server(defaultServConf);
  final connect = Completer();
  final disconnect = Completer();

  Function(EventArgs) handler;
  handler = (_) {
    connect.complete();
  };

  p1.onConnect.subscribe(handler);

  test("websocket connection", () {
    expect(p1.connect(), completion(null));
  });

  test("websocket onConnect", () {
    Future.delayed(Duration(milliseconds: 200)).then((_) {
      if (!connect.isCompleted) {
        connect.completeError("timeout after 200ms");
      }
    });

    expect(connect.future, completion(null));
    p1.onConnect.unsubscribe(handler);
  });

  test("websocket disconnect", () {
    handler = (_) {
      disconnect.complete();
    };
    p1.onDisconnect.subscribe(handler);

    expect(p1.disconnect(), completes);
  });

  test("websocket onDisconnect", () {
    Future.delayed(Duration(milliseconds: 200)).then((_) {
      if (!disconnect.isCompleted) {
        disconnect.completeError("timeout after 200ms");
      }
    });

    expect(disconnect.future, completion(null));
    p1.onDisconnect.unsubscribe(handler);
  });

  test("websocket reconnect", () {
    expect(p1.connect(), completes);
  });

  test("authorization test", () {
    expect(p1.getRequest(Server.routes["protect"]), completes);
  });

  final p2 = Server(defaultServConf);
  test("authorization test fail", () {
    final fut = Completer();
    p2.getRequest(Server.routes["protect"]).then((_) {
      fut.completeError("no error was thrown. want error 'socket is null'");
    }).catchError((_) {
      fut.complete();
    });

    expect(fut.future, completes);
  });

  final ids = List<String>.empty(growable: true);
  test("get avaliable users", () {
    final fut = Completer<List<String>>();
    p2.connect().then((_) {
      p2.getAvaliableUsers().then((list) {
        if (list.length != 2) {
          fut.completeError("list length is not 2. list: $list");
        } else {
          ids.addAll(list);
          fut.complete(list);
        }
      }).catchError((e) {
        fut.completeError(e);
      });
    }).catchError((e) {
      fut.completeError(e);
    });

    expect(fut.future, completion(isA<List<String>>()));
  });

  test("send invite", () {
    String inviteID = "";
    for (var id in ids) {
      if (id != p2.publicId) {
        inviteID = id;
        break;
      }
    }

    expect(p2.invite(inviteID), completes);
  });

  test("receive invite", () {
    expect(p1.invites.length, 1);
  });

  test("accept invite", () {
    expect(p1.acceptInvite(p1.invites[0].id), completes);
  });

  test("player numbers", () {
    expect(p1.player, isNot(p2.player));
  });

  test("in game after accept invite", () {
    expect(p1.inGame, true);
    expect(p2.inGame, true);
  });

  test("our turn?", () {
    expect(p1.player, p1.playerTurn);
  });
}
