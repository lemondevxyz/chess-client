import "package:chess_client/src/board/rules.dart";

enum Type { empty, pawnf, pawnb, bishop, knight, rook, queen, king }

final Map<Type, String> typeMap = {
  Type.empty: "e",
  Type.pawnf: "p",
  Type.pawnb: "p",
  Type.bishop: "b",
  Type.knight: "n",
  Type.rook: "r",
  Type.queen: "q",
  Type.king: "k",
};

extension TypeToString on Type {
  String toShortString() {
    return typeMap[this].toUpperCase();
  }
}

class Piece {
  // pos
  Point pos;
  // player number
  int num;
  // piece type
  Type t = Type.empty;

  Piece(this.pos, this.t, this.num);

  bool canGo(Point dst) {
    // out of bounds
    if ((dst.x == -1 || dst.y == -1) && (dst.x > 7 || dst.y > 7)) {
      return false;
    }

    if (equal(this.pos, dst)) {
      return false;
    }

    switch (this.t) {
      case Type.empty:
        return true;
      case Type.pawnb:
      case Type.pawnf:
        {
          // 2 at start
          // 1 anytime else
          bool ok = false;
          if (this.t == Type.pawnb) {
            ok = backward(this.pos, dst);
          } else {
            ok = forward(this.pos, dst);
          }

          final Point area = Point(1, 0);
          if (pos.x == 6 || pos.x == 1) {
            return ok &&
                (within(Point(2, 0), this.pos, dst) ||
                    within(area, this.pos, dst));
          }

          return ok && within(area, this.pos, dst);
        }
      case Type.bishop:
        {
          // diagonal
          return diagonal(this.pos, dst);
        }
      case Type.knight:
        // 2,1 or -2, 1 or 2, -1 or -2, -1
        // 1,2 or -1, 2 or 1, -2 or -2, -1
        {
          final Point area = Point(2, 1);

          return within(area, this.pos, dst) ||
              within(swap(area), this.pos, dst);
        }
      case Type.rook:
        {
          // horizontal or vertical
          return horizontal(this.pos, dst) || vertical(this.pos, dst);
        }
      case Type.queen:
        // diagonal - square - vertical - horizontal
        return diagonal(this.pos, dst) ||
            square(this.pos, dst) ||
            vertical(this.pos, dst) ||
            horizontal(this.pos, dst);
      case Type.king:
        return square(this.pos, dst);
    }

    return false;
  }
}
