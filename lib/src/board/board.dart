import "package:chess_client/src/board/generator.dart";
import "package:chess_client/src/board/piece.dart";
import 'package:event/event.dart';
import 'package:flutter/material.dart';

class Board with ChangeNotifier {
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

  List<List<Piece>> toJson() {
    return _data;
  }

  Board() {
    var alt1 = List<int>.filled(8, PieceKind.pawnb);
    List<int> alt2 = [
      PieceKind.rook,
      PieceKind.knight,
      PieceKind.bishop,
      PieceKind.king,
      PieceKind.queen,
      PieceKind.bishop,
      PieceKind.knight,
      PieceKind.rook,
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

        alt2 = List<int>.filled(8, PieceKind.pawnf);

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

  Color getBackground(Point pnt) {
    final x = pnt.x;
    final y = pnt.y;

    Color pri = _BoardState.pri;
    Color sec = _BoardState.sec;
    if ((x % 2) == 0) {
      pri = _BoardState.sec;
      sec = _BoardState.pri;
    }

    final clr = (y % 2) == 0 ? sec : pri;
    return clr;
  }

  @override
  Widget build(BuildContext context) {
    final brd = widget.board;

    return Expanded(
        child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.height - 120,
            ),
            child: Container(
                color: Colors.white12,
                margin: const EdgeInsets.all(20),
                child: Center(
                  child: GridView.builder(
                    itemCount: 8 * 8,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      Point pnt = Point.fromIndex(index);
                      if (widget.reverse) {
                        final x = 7 - pnt.x;
                        final y = 7 - pnt.y;

                        pnt = Point(x.abs(), y);
                      }

                      final pce = brd.get(pnt);
                      return GestureDetector(
                          onTap: () {
                            if (widget.ourTurn()) {
                              if (focus == null) {
                                if (pce != null) {
                                  if (widget.canFocus(pce)) {
                                    setState(() {
                                      focus = pnt;
                                    });
                                  }
                                }
                              } else {
                                final doMovement = () {
                                  widget.move(focus, pnt);

                                  setState(() {
                                    focus = null;
                                  });
                                };

                                if (pce != null) {
                                  final ecp = brd.get(focus);
                                  // well if we select an ally
                                  // then shift focus to that piece
                                  if (ecp.num == pce.num) {
                                    setState(() {
                                      focus = pnt;
                                    });
                                  } else {
                                    // allow killing of enemy
                                    doMovement();
                                  }
                                } else {
                                  doMovement();
                                }
                              }
                            }
                          },
                          child: Container(
                            color: (focus != null && pnt.equal(focus))
                                ? Theme.of(context).primaryColor
                                : getBackground(pnt),
                            child: Stack(
                              children: <Widget>[
                                if (pce != null)
                                  Image.asset(
                                    pce.filename(),
                                  ),
                              ],
                            ),
                          ));
                    },
                  ),
                ))));
  }
}

class BoardWidget extends StatefulWidget {
  final Board board;
  final Future<void> Function(Point src, Point dst) move;
  final bool Function() ourTurn;
  final bool Function(Piece) canFocus; // disallow selecting enemy pieces
  final bool reverse;

  BoardWidget(this.board, this.move, this.ourTurn, this.canFocus,
      {Key key, this.reverse = false})
      : super(key: key);

  @override
  _BoardState createState() => _BoardState();
}
