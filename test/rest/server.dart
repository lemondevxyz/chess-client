import "package:test/test.dart";
import "package:chess_client/src/rest/server.dart";

void main() {
  final s = Server(defaultServConf);
  test("websocket connection", () {
    expect(s.connect(), completion(null));
  });

  test("command request", () {
    expect(s.sendCommand(), completion(null));
  });
}
