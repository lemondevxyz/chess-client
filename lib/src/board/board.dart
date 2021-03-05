import 'dart:convert';

import "package:chess_client/src/board/generator.dart";
import "package:chess_client/src/board/piece.dart";
import 'package:flutter/material.dart';

class Board {
  static const int max = 8;
  var _data = List<List<Piece>>.empty(growable: true);

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

  Board() {
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

  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    String str = "";

    this._data.asMap().forEach((x, l) {
      if (x != 0) {
        str += "\n";
      }

      l.forEach((p) {
        if (p != null) {
          str += p.t.toShortString() + " ";
        } else {
          str += "  ";
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

  bool canGo(Piece p, Point dst) {
    if (p == null || !dst.valid()) {
      return false;
    }

    int x = p.pos.x;
    int y = p.pos.y;

    bool ok = p.canGo(dst);
    if (p.t == Type.pawnf || p.t == Type.pawnb) {
      if (p.t == Type.pawnf) {
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
    if (p.t != Type.knight) {
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

      this._data[p.pos.x][p.pos.y] = null;

      p.pos = dst;
      this.set(p);
    }

    return ok;
  }
}

class _BoardState extends State<BoardWidget> {
  static final Color pri = Colors.white;
  static final Color sec = Colors.grey[400];

  final List<Container> cont = List<Container>.empty(growable: true);

  Point focus;

  @override
  Widget build(BuildContext context) {
    final b = widget.b;

    Color primary = pri;
    Color secondary = sec;

    var cont = <Widget>[];

    List<Point> possib;
    if (focus != null) {
      final Piece p = b.get(focus);
      if (p != null) {
        possib = p.possib();
      }
    }

    for (var x = 0; x < Board.max; x++) {
      if ((x % 2) == 1) {
        primary = sec;
        secondary = pri;
      } else {
        primary = pri;
        secondary = sec;
      }

      for (var y = 0; y < Board.max; y++) {
        final Piece p = b.get(Point(x, y));
        Color clr = primary;
        if ((y % 2) == 1) {
          clr = secondary;
        }

        Widget w;
        if (p != null) {
          String str = filenames[p.t];
          if (p.num == 1) {
            str = "dark/" + str;
          } else {
            str = "light/" + str;
          }

          w = Image.asset(str);
        } else {
          if (possib != null) {
            for (var point in possib) {
              if (Point(x, y).equal(point)) {
                w = Container(
                  decoration: new BoxDecoration(
                    color: Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.all(20),
                );
                break;
              }
            }
          }
        }

        final Container c = Container(color: clr, child: w);

        cont.add(GestureDetector(
            onTap: () {
              if (p != null) {
                setState(() {
                  focus = Point(x, y);
                  debugPrint("$x:$y focus");
                });
              }
              if (focus != null) {
                final Piece p = b.get(focus);
                if (p != null) {
                  setState(() {
                    bool bo = b.move(p, Point(x, y));
                    debugPrint("$focus $bo $x:$y $p");

                    //focus = null;
                    possib = null;
                    print("$b");
                  });
                }
              }
            },
            child: c));
      }
    }

    return Expanded(
      child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.height - 100,
          ),
          child: Container(
              color: Colors.white12,
              margin: const EdgeInsets.all(20),
              child: Center(
                  child: GridView.count(
                shrinkWrap: true,
                //physics: NeverScrollableScrollPhysics(),
                children: cont,
                crossAxisCount: 8,
                mainAxisSpacing: 5.0,
                childAspectRatio: 1.0,
              )))),
    );
  }
}

class BoardWidget extends StatefulWidget {
  const BoardWidget(this.b);
  final Board b;

  @override
  createState() => _BoardState();
}
