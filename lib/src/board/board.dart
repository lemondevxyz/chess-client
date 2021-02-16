import "package:chess_client/src/board/rules.dart";
import "package:chess_client/src/board/piece.dart";

class Board {
  var alt1 = List<Type>.filled(8, Type.pawnb);
  List<Type> alt2 = [
    Type.rook,
    Type.knight,
    Type.bishop,
    Type.king,
    Type.queen,
    Type.bishop,
    Type.knight,
    Type.rook,
  ];

  var _data = List<List<Piece>>.filled(8, List<Piece>.filled(8, null));

  Board() {
    for (int i = 0; i < 2; i++) {
      int x = i;
      int num = 1;
      if (i == 1) {
        alt1 = alt2;
        alt2 = List<Type>.filled(8, Type.pawnf);

        x += 5;
        num = 2;
      }

      for (int y = 0; y < 8; y++) {
        _data[x][y] = Piece(Point(x, y), alt1[y], num);
        _data[x + 1][y] = Piece(Point(x, y), alt2[y], num);
      }
    }
  }

  String toString() {
    String str = "";

    for (var x = 0; x < _data.length; x++) {
      if (x != 0) {
        str += "\n";
      }

      var v = _data[x];
      for (var y = 0; y < v.length; y++) {
        str += _data[x][y].t.toShortString() + " ";
      }
    }

    return str;
  }

  void set(Piece p) {
    if (p != null) {
      if (p.t == Type.empty) {
        this._data[p.pos.x][p.pos.y] = null;
      } else {
        this._data[p.pos.x][p.pos.x] = p;
      }
    }
  }

  Piece get(Point p) {
    return this._data[p.x][p.y];
  }

  bool move(Piece p, Point dst) {
    bool ok = p.canGo(dst);

    if (p.t == Type.pawnf || p.t == Type.pawnb) {
      final int x = p.pos.x + 1;
      final int y = p.pos.y;

      if (!ok) {
        if (this.get(Point(x, y + 1)) != null) {
          ok = true;
        } else if (this.get(Point(x, y - 1)) != null) {
          ok = true;
        }
      } else {
        Piece o = this.get(Point(x, y));
        if (o != null) {
          ok = false;
        }
      }
    }

    p.pos = dst;
    if (ok) {
      this.set(p);
    }

    return ok;
  }
}
