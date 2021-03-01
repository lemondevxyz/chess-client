import "package:chess_client/src/board/generator.dart";

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

  Piece.fromJson(Map<String, dynamic> json)
      : num = json["player"],
        t = Type.values[json["type"]];

  Piece(this.pos, this.t, this.num);

  String toString() {
    return this.t.toString().split('.').last;
  }

  // canGo returns true if dst is a legal move
  bool canGo(Point dst) {
    // out of bounds
    if (!dst.valid()) {
      return false;
    }
    if (this.pos.equal(dst)) {
      return false;
    }

    return this.possib().exists(dst);
  }

  // possib returns possible moves from this.pos
  List<Point> possib() {
    final ps = <Point>[];

    switch (this.t) {
      case Type.pawnb:
      case Type.pawnf:
        {
          if (this.t == Type.pawnb) {
            ps.add(Point(this.pos.x + 1, this.pos.y));
          } else {
            ps.add(Point(this.pos.x - 1, this.pos.y));
          }

          // at start you can move two points
          if (this.pos.x == 1 || this.pos.x == 6) {
            ps.add(Point(this.pos.x - 2, this.pos.y));
            ps.add(Point(this.pos.x + 2, this.pos.y));
          }

          break;
        }
      case Type.bishop:
        {
          ps.addAll(this.pos.diagonal());
          break;
        }
      case Type.knight:
        // 2,1 or -2, 1 or 2, -1 or -2, -1
        // 1,2 or -1, 2 or 1, -2 or -2, -1
        {
          ps.addAll(this.pos.knight());
          break;
        }
      case Type.rook:
        {
          ps.addAll(this.pos.rook());
          break;
        }
      case Type.queen:
        ps.addAll(this.pos.queen());
        break;
      case Type.king:
        ps.addAll(this.pos.square());
        break;
    }
    ps.clean();

    return ps;
  }
}
