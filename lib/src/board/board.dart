import "package:chess_client/src/board/rules.dart";
import "package:chess_client/src/board/piece.dart";
import 'package:flutter/material.dart';

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

  static const int max = 8;
  var _data = List<List<Piece>>.empty(growable: true);

  Board() {
    for (var i = 0; i < max; i++) {
      this._data.add(List<Piece>.filled(max, null));
    }

    for (var i = 0; i < 2; i++) {
      int x = i;
      int num = 1;
      if (i == 1) {
        alt1 = [];
        alt1.addAll(alt2);

        alt2 = List<Type>.filled(8, Type.pawnf);

        x += 5;
        num++;
      }

      for (var y = 0; y < 8; y++) {
        this._data[x][y] = Piece(
          Point(x, y),
          alt2[y],
          num,
        );
        this._data[x + 1][y] = Piece(
          Point(x + 1, y),
          alt1[y],
          num,
        );
      }
    }
  }

  String toString() {
    String str = "";

    this._data.asMap().forEach((x, l) {
      if (x != 0) {
        str += "\n";
      }

      l.forEach((p) {
        if (p != null) {
          str += p.t.toShortString() + " ";
        } else {
          str += " ";
        }
      });
    });

    return str;
  }

  void set(Piece p) {
    if (p != null) {
      if (p.t == Type.empty) {
        this._data[p.pos.x][p.pos.y] = null;
      } else {
        this._data[p.pos.x][p.pos.y] = p;
      }
    }
  }

  Piece get(Point p) {
    return this._data[p.x][p.y];
  }

  bool move(Piece p, Point dst) {
    bool ok = p.canGo(dst);

    if (p.t == Type.pawnf || p.t == Type.pawnb) {
      int x = p.pos.x;
      if (p.t == Type.pawnf) {
        x--;
      } else {
        x++;
      }

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

    if (ok) {
      this._data[dst.x][dst.y] = null;

      p.pos = dst;
      this.set(p);
    }

    return ok;
  }

  /*
  static final Color pri = Colors.white;
  static final Color sec = Colors.grey[200];

  List<Row> _rows = List<Row>.filled(8, Row());

  @override
  Widget build(BuildContext context, State state) {
    //Container c = Container();
    for (var x = 0; x < Board.max; x++) {
      for (var y = 0; y < Board.max; y++) {
        Color bg = Board.pri;
        if ((x % 1) == 0) {
          bg = Board.sec;
        }

        if ((y % 1) == 0) {
          if (bg == Board.pri) {
            bg = Board.sec;
          } else if (bg == Board.sec) {
            bg = Board.pri;
          }
        }
      }
    }
  }
  */
}
