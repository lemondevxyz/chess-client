import "package:chess_client/src/board/rules.dart";
import "package:chess_client/src/board/piece.dart";

class Board {
  List<Type> alt1 = List<Type>.filled(8, Type.pawnb);
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

  final List<List<Piece>> _data =
      List<List<Piece>>.filled(8, List<Piece>.filled(8, null));

  Board() {
    for (int i = 0; i < 4; i++) {
      int x = i;
      if (i == 2) {
        alt1 = alt2;
        alt2 = List<Type>.filled(8, Type.pawnf);
      }

      if (i >= 2) {
        x += 4;
      }

      for (int y = 0; y < 8; y++) {
        _data[x][y] = Piece(Point(x, y), Type.empty, 1);
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

  bool move(Piece p, Point dst) {}
}
