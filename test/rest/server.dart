import "dart:convert";
import 'dart:async';
import "package:test/test.dart";
import "package:chess_client/src/rest/server.dart";

void main() {
  // all these tests require chess-server to be running.
  final p1 = Server(defaultServConf);

  test("websocket connection", () {
    expect(p1.connect(), completion(null));
  });

  test("authorization test", () {
    expect(p1.getRequest(Server.routes["protect"]), completion(isA<String>()));
  });

  final p2 = Server(defaultServConf);
  test("authorization test fail", () {
    final fut = Completer();
    p2.getRequest(Server.routes["protect"]).then((_) {
      fut.completeError("no error was thrown. want error 'socket is null'");
    }).catchError((_) {
      fut.complete();
    });

    // i do this cause it's the only way i know to test against a successful future
    // dart devs pls fix.
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
}
