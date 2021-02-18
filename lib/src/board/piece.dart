import "package:chess_client/src/board/rules.dart";

enum Type { empty, pawnf, pawnb, bishop, knight, rook, queen, king }

final Map<Type, String> typeMap = {
  Type.empty: "",
  Type.pawnf: "p",
  Type.pawnb: "p",
  Type.bishop: "b",
  Type.knight: "n",
  Type.rook: "r",
  Type.queen: "q",
  Type.king: "k",
};

final Map<Type, String> filenames = {
  Type.empty: "",
  Type.pawnf: "pawn.png",
  Type.pawnb: "pawn.png",
  Type.bishop: "bishop.png",
  Type.knight: "knight.png",
  Type.rook: "rook.png",
  Type.queen: "queen.png",
  Type.king: "king.png",
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

  String toString() {
    return this.t.toString().split('.').last;
  }

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

  List<Point> possib() {
    final ps = <Point>[];

    int x = this.pos.x;
    int y = this.pos.y;

    switch (this.t) {
      case Type.pawnb:
        {
          ps.add(Point(x + 1, y));
          if (this.pos.x == 1) {
            ps.add(Point(x + 2, y));
          }

          // stupid case-block-not-terminated
          // i hate you so much
          return ps;
        }
      case Type.pawnf:
        {
          ps.add(Point(x - 1, y));
          if (this.pos.x == 6) {
            ps.add(Point(x - 2, y));
          }

          // stupid case-block-not-terminated
          // i hate you so much
          return ps;
        }
      case Type.bishop:
        {
          return this.pos.diagonal();
        }
      case Type.knight:
        // 2,1 or -2, 1 or 2, -1 or -2, -1
        // 1,2 or -1, 2 or 1, -2 or -2, -1
        {
          return this.pos.knight();
        }
      case Type.rook:
        {
          return this.pos.horizontal() + this.pos.vertical();
        }
      case Type.queen:
        {
          return this.pos.diagonal() +
              this.pos.horizontal() +
              this.pos.vertical() +
              this.pos.square();
        }
      case Type.king:
        return this.pos.square();
    }

    return ps;
  }
}
