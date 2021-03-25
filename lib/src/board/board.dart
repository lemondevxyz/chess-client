import "package:chess_client/src/board/generator.dart";
import "package:chess_client/src/board/piece.dart";
import 'package:chess_client/src/order/model.dart';
import 'package:flutter/material.dart';

class Board with ChangeNotifier {
  static const int max = 8;
  var _data = List<List<Piece>>.empty(growable: true);

  // this is a list of all moves done by the both player
  final moveList = <Move>[];
  // this represents the last move we reverted to
  // if equal to len(moveList) means it hasn't been modified
  int lastMove = -1;

  Board.fromJson(List<dynamic> json) {
    for (var i = 0; i < max; i++) {
      this._data.add(List<Piece>.filled(max, null));
    }

    json.asMap().forEach((x, list) {
      list.asMap().forEach((y, piece) {
        if (piece != null) {
          this._data[x][y] = Piece.fromJson(piece);
        }
      });
    });
  }

  Board duplicate() {
    final brd = Board();
    _data.asMap().forEach((x, l) {
      l.asMap().forEach((y, pec) {
        if (pec == null) {
          brd._data[x][y] = null;
        } else {
          brd._data[x][y] = Piece(pec.pos, pec.t, pec.num);
        }
      });
    });

    return brd;
  }

  List<List<Piece>> toJson() {
    return _data;
  }

  Board() {
    var alt1 = List<int>.filled(8, PieceKind.pawnb);
    List<int> alt2 = [
      PieceKind.rook,
      PieceKind.knight,
      PieceKind.bishop,
      PieceKind.queen,
      PieceKind.king,
      PieceKind.bishop,
      PieceKind.knight,
      PieceKind.rook,
    ];

    for (var i = 0; i < max; i++) {
      this._data.add(List<Piece>.filled(max, null));
    }

    for (var i = 0; i < 2; i++) {
      int x = i;
      int num = 2;
      if (i == 1) {
        alt1 = [];
        alt1.addAll(alt2);

        alt2 = List<int>.filled(8, PieceKind.pawnf);

        x += 5;
        num--;
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

  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    String str = "";

    this._data.asMap().forEach((x, l) {
      if (x != 0) {
        str += "\n";
      }

      l.forEach((p) {
        if (p != null) {
          str += PieceKind.toShortString(p.t) + " ";
        } else {
          str += "  ";
        }
      });
    });

    return str;
  }

  void set(Piece p) {
    if (p != null) {
      if (p.t == PieceKind.empty) {
        this._data[p.pos.x][p.pos.y] = null;
      } else {
        this._data[p.pos.x][p.pos.y] = p;
      }

      notifyListeners();
    }
  }

  Piece get(Point p) {
    final pie = this._data[p.x][p.y];
    if (pie != null) {
      pie.pos = p;
    }

    return pie;
  }

  bool canGo(Piece p, Point dst) {
    if (p == null || !dst.valid()) {
      return false;
    }

    int x = p.pos.x;
    int y = p.pos.y;

    bool ok = p.canGo(dst);
    if (p.t == PieceKind.pawnf || p.t == PieceKind.pawnb) {
      if (p.t == PieceKind.pawnf) {
        x--;
      } else {
        x++;
      }

      // maybe pawn is going forward/backward
      if (ok) {
        // oops there is a piece in the way...
        if (this.get(dst) != null) {
          return false;
        }
      } else {
        <Point>[
          Point(x, y + 1),
          Point(x, y - 1),
        ].forEach((p) {
          if (dst.equal(p)) {
            ok = true;
          }
        });

        // okay pawn is going +1, +1
        // or +1, -1
        if (ok) {
          final o = this.get(dst);
          // no piece there or piece belongs to us..
          if (o == null || o.num == p.num) {
            ok = false;
          }
        }
      }

      return ok;
    } else {
      if (!ok) {
        return ok;
      }
    }

    final int dir = p.pos.direction(dst);
    if (p.t != PieceKind.knight) {
      for (var i = 0; i < 8; i++) {
        if (Direction.has(dir, Direction.up)) {
          x--;
        } else if (Direction.has(dir, Direction.down)) {
          x++;
        }

        if (Direction.has(dir, Direction.left)) {
          y--;
        } else if (Direction.has(dir, Direction.right)) {
          y++;
        }

        final o = Point(x, y);
        if (!o.valid() || o.equal(dst)) {
          break;
        }

        // something is in the way...
        if (this.get(o) != null) {
          return false;
        }
      }
    }

    return true;
  }

  bool move(Piece p, Point dst) {
    if (p == null || !dst.valid()) {
      return false;
    }

    bool ok = this.canGo(p, dst);
    if (ok) {
      final o = this.get(dst);
      // friendly fire not allowed !!!
      if (o != null && o.num == p.num) {
        return false;
      }

      final src = p.pos;
      this._data[p.pos.x][p.pos.y] = null;

      p.pos = dst;

      this.moveList.add(Move(src, dst));

      this.set(p);
    }

    return ok;
  }

  bool canRevertMove() {
    if (lastMove <= 0) {
      return false;
    }

    return true;
  }

  void revertMove() {
    if (!canRevertMove()) {
      return;
    }

    lastMove--;

    final previousMove = moveList[lastMove];

    final dst = previousMove.dst;
    final pec = get(dst);

    this._data[dst.x][dst.y] = null;

    pec.pos = previousMove.src;
    set(pec);
  }
}
