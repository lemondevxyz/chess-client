import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

String numToString(int i) {
  switch (i) {
    case 1:
      return "A";
    case 2:
      return "B";
    case 3:
      return "C";
    case 4:
      return "D";
    case 5:
      return "E";
    case 6:
      return "F";
    case 7:
      return "G";
    case 8:
      return "H";
  }

  return "";
}

class _BoardState extends State<BoardWidget> {
  static final Color pri = Colors.white;
  static final Color sec = Colors.grey[400];

  static final double indexSizeDivider = 7;
  static final double indexPadding = 2.5;

  List<Point> _points = List<Point>.empty(growable: true);

  // which piece we're focused at
  // basically which square has the purple background
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

  void _setPoints() async {
    if (focus != null && widget.possib != null) {
      widget.possib(focus).then((_value) {
        setState(() {
          _points = _value;
        });
      }).catchError((e) {
        print("possib $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brd = widget.board;
    final height = MediaQuery.of(context).size.height - 150;

    return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: height,
          maxHeight: height,
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

                  final orix = pnt.x;
                  final oriy = pnt.y;

                  if (widget.reverse) {
                    final x = 7 - pnt.x;
                    final y = 7 - pnt.y;

                    pnt = Point(x.abs(), y);
                  }

                  Piece pce;
                  if (brd != null) {
                    pce = brd.get(pnt);
                  }

                  Color bg;

                  final bool playersKing = (pce != null &&
                      pce.t == PieceKind.king &&
                      pce.num == widget.playerNumber);

                  if (focus != null && pnt.equal(focus))
                    bg = Theme.of(context).primaryColor;
                  else if (widget.isCheckmate != null &&
                      widget.isCheckmate() &&
                      playersKing)
                    bg = Theme.of(context).errorColor;
                  else
                    bg = getBackground(pnt);

                  return GestureDetector(
                    onTap: () {
                      if (widget.board.canResetHistory()) {
                        widget.board.resetHistory();
                        setState(() {
                          focus = null;
                        });
                        return;
                      }

                      if (widget.ourTurn()) {
                        if (focus == null) {
                          if (pce != null) {
                            if (widget.playerNumber == null ||
                                widget.playerNumber == pce.num) {
                              setState(() {
                                focus = pnt;
                                _setPoints();
                              });
                            }
                          }
                        } else {
                          final doMovement = () {
                            widget.move(focus, pnt);

                            setState(() {
                              _points.clear();
                              focus = null;
                            });
                          };

                          if (pce != null) {
                            final ecp = brd.get(focus);
                            // well if we select an ally
                            // then shift focus to that piece
                            if (ecp.num == pce.num) {
                              if ((pce.t == PieceKind.king &&
                                      ecp.t == PieceKind.rook) ||
                                  (pce.t == PieceKind.rook &&
                                      ecp.t == PieceKind.king)) {
                                doMovement();
                              } else {
                                setState(() {
                                  focus = pnt;
                                  _setPoints();
                                });
                              }
                            } else {
                              // if it's an enemy then sure do the move
                              doMovement();
                            }
                          } else {
                            // movement to an empty square
                            doMovement();
                          }
                        }
                      }
                    },
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) =>
                              Container(
                        color: bg,
                        child: Stack(
                          children: <Widget>[
                            if (oriy == 0)
                              // number of square, 1 through 8
                              // drawn horizontally
                              Container(
                                child: Text(
                                  "${(!widget.reverse ? 8 - orix : orix + 1).abs()}",
                                  style: TextStyle(
                                    fontSize:
                                        constraints.maxWidth / indexSizeDivider,
                                  ),
                                ),
                                padding: EdgeInsets.only(left: indexPadding),
                              ),
                            if (orix == 7)
                              // letter of square, a through h
                              // drawn vertically
                              Align(
                                alignment: FractionalOffset.bottomRight,
                                child: Container(
                                  child: Text(
                                    "${numToString((widget.reverse ? 8 - oriy : oriy + 1).abs())}",
                                    style: TextStyle(
                                      fontSize: constraints.maxWidth /
                                          indexSizeDivider,
                                    ),
                                  ),
                                ),
                              ),
                            if (pce != null)
                              Center(
                                child: Image.asset(
                                  pce.filename(),
                                  width: constraints.maxWidth - 10,
                                  height: constraints.maxHeight - 10,
                                ),
                              ),
                            if (_points.exists(pnt))
                              Center(
                                child: Container(
                                  width: constraints.maxWidth / 2,
                                  height: constraints.maxHeight / 2,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.54),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )));
  }
}

class BoardItem extends StatelessWidget {
  final Piece pec;
  final double size;

  final double x;
  final double y;

  BoardItem(this.pec, this.size, {Key key})
      : x = pec.pos.x * size,
        y = pec.pos.y * size,
        super(key: key);

  @override
  Widget build(BuildContext build) {
    return Positioned(
      width: this.size,
      height: this.size,
      left: x,
      top: y,
      child: Image.asset(
        pec.filename(),
        width: this.size,
        height: this.size,
      ),
    );
  }
}

class BoardMarker {
  HashMap<String, void> points;
  final Color color;

  BoardMarker(this.points, this.color);
}

class BoardBackground extends CustomPainter {
  static int size = 8;
  final List<BoardMarker> markerPoints;

  final Color pri;
  final Color sec;

  const BoardBackground(this.pri, this.sec, this.markerPoints);

  Color getBackground(Point pnt) {
    final x = pnt.x;
    final y = pnt.y;

    final Color pri = (x % 2 == 1) ? this.pri : this.sec;
    final Color sec = pri == this.pri ? this.sec : this.pri;

    final clr = (y % 2) == 0 ? sec : pri;
    return clr;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final res = size.height > size.width ? size.width : size.height;
    final div = res / 8;
    for (int x = 0; x < BoardBackground.size; x++) {
      for (int y = 0; y < BoardBackground.size; y++) {
        double minx = x * div;
        double miny = y * div;

        double maxx = (x + 1) * div;
        double maxy = (y + 1) * div;

        final rect = Rect.fromLTRB(
          minx,
          miny,
          maxx,
          maxy,
        );

        final paint = Paint();
        paint.color = getBackground(Point(x, y));

        canvas.drawRect(rect, paint);

        markerPoints.forEach((BoardMarker mark) {
          if (mark.points.containsKey(Point(x, y).toString())) {
            final paint = Paint();
            paint.color = mark.color;

            canvas.drawRect(rect, paint);

            return;
          }
        });
      }
    }
  }

  @override
  bool shouldRepaint(BoardBackground oldDelegate) {
    return oldDelegate.markerPoints != markerPoints;
  }
}

class BoardWidget extends StatefulWidget {
  final Board board;
  final Future<void> Function(Point src, Point dst) move;
  final bool Function() ourTurn;
  final int playerNumber;
  final bool reverse;
  final Future<List<Point>> Function(Point) possib;
  final bool Function() isCheckmate;

  BoardWidget(this.board, this.move, this.ourTurn,
      {Key key,
      this.reverse = false,
      this.possib,
      this.playerNumber,
      this.isCheckmate})
      : super(key: key);

  @override
  _BoardState createState() => _BoardState();
}
