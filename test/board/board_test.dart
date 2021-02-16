import "package:test/test.dart";
import "package:chess_client/src/board/board.dart";
import "package:chess_client/src/board/piece.dart";
import "package:chess_client/src/board/rules.dart";

void main() {
  test("board move", () {
    final Board b = Board();
    b.move(b.get(Point(1, 1)), Point(3, 1));

    Piece p = b.get(Point(3, 1));
    if (p == null) {
      print("piece doesn't actually move");
      expect(true, p != null);
    }

    Piece o = b.get(Point(6, 1));
    if (!b.move(o, Point(4, 1))) {
      print("pawn cannot move for some reason");
      expect(true, false);
    }

    if (b.move(p, Point(4, 1))) {
      print("pawn can move over other pawn");
      expect(false, true);
    }

    b.move(b.get(Point(1, 6)), Point(3, 6));
    if (!b.move(b.get(Point(7, 2)), Point(3, 6))) {
      print("bishop cannot step over pawn");
      expect(false, true);
    }
  });
}
