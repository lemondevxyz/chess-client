import 'dart:convert';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import "package:test/test.dart";

void main() {
  test("credentials", () {
    final map = Credentials("token", "public_id").toJson();
    expect(jsonEncode(map), '{"token":"token","public_id":"public_id"}');
  });

  test("invite", () {
    final map = Invite("id").toJson();
    expect(jsonEncode(map), '{"id":"id"}');
  });

  test("game", () {
    final b = Board();
    final map = Game(b, 1).toJson();

    expect(jsonEncode(map),
        '{"board":[[{"player":1,"type":5},{"player":1,"type":4},{"player":1,"type":3},{"player":1,"type":7},{"player":1,"type":6},{"player":1,"type":3},{"player":1,"type":4},{"player":1,"type":5}],[{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2},{"player":1,"type":2}],[null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null],[null,null,null,null,null,null,null,null],[{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1},{"player":2,"type":1}],[{"player":2,"type":5},{"player":2,"type":4},{"player":2,"type":3},{"player":2,"type":7},{"player":2,"type":6},{"player":2,"type":3},{"player":2,"type":4},{"player":2,"type":5}]],"player":1}');
  });

  test("move", () {
    final m = Move(Point(1, 1), Point(2, 2));
    expect(jsonEncode(m), '{"src":{"x":1,"y":1},"dst":{"x":2,"y":2}}');
  });

  test("turn", () {
    final t = Turn(1);
    expect(jsonEncode(t), '{"player":1}');
  });

  test("promotion", () {
    // TODO: replace type with kind
    final p = Promotion(Type.rook, Point(1, 1));
    expect(jsonEncode(p), '{"type":5,"dst":{"x":1,"y":1}}');
  });

  test("promote", () {
    final p = Promote(Type.rook, Point(1, 1));
    expect(jsonEncode(p), '{"type":5,"src":{"x":1,"y":1}}');
  });

  test("message", () {
    final m = Message("henlo");
    expect(jsonEncode(m), '{"message":"henlo"}');
  });

  test("done", () {
    final d = Done(1);
    expect(jsonEncode(d), '{"result":1}');
  });

  test("order move", () {
    final m = Move(Point(1, 1), Point(2, 2));
    final o = Order(OrderID.Move, m);

    expect(jsonEncode(o),
        '{"id":4,"data":{"src":{"x":1,"y":1},"dst":{"x":2,"y":2}}}');
  });
}
