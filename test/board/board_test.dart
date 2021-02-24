import "package:test/test.dart";
import "package:chess_client/src/board/board.dart";
import "package:chess_client/src/board/piece.dart";
import "package:chess_client/src/board/generator.dart";

void main() {
  test("board move", () {
    final Board b = Board();
    Piece p = b.get(Point(1, 1));
    if (!b.move(p, Point(3, 1))) {
      print("something majorly wrong with Board.move");
      expect(false, true);
    }

    if (p == null) {
      print("piece doesn't actually move");
      expect(false, p != null);
    } else {
      Piece o = b.get(Point(6, 1));
      if (!b.move(o, Point(4, 1))) {
        print("pawn cannot move for some reason");
        expect(false, true);
      }

      if (b.move(p, Point(4, 1))) {
        print("pawn can move over other pawn");
        expect(false, true);
      }
    }

    p = b.get(Point(1, 6));
    b.move(p, Point(3, 6));
    if (!b.move(b.get(Point(7, 2)), Point(3, 6))) {
      print("bishop cannot kill enemy pawn");
      expect(false, true);
    }
  });

  // this tests the ability of pieces to move over each other....
  // if the piece isn't knight, this would be illegal ..
  /*
  test("board move over", () {
    final Board b = Board();
  });
  */
}
