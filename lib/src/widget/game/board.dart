import 'dart:collection';
import 'dart:ui' as ui;

import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

String numToLetter(int i) {
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

class Marker {
  final points = HashMap<String, void>();
  final Color color;
  final double circlePercentage;
  // should our marker draw over the pieces???
  final bool drawOverPiece;

  Marker(this.color, {this.circlePercentage, this.drawOverPiece});

  addPoint(List<Point> ps) {
    ps.forEach((pec) {
      points[pec.toString()] = pec;
    });
  }
}

class Markers extends ChangeNotifier {
  static int focus = 2;
  static int possib = 1;
  static int checkmate = 0;

  final _data = <Marker>[];

  add(Marker value) {
    _data.add(value);
    notifyListeners();
  }

  remove(Marker value) {
    _data.remove(value);
    notifyListeners();
  }

  forEach(Function(Marker) fn) {
    _data.forEach(fn);
    notifyListeners();
  }

  Markers(Color focus, Color possib, Color checkmate) {
    _data.add(Marker(checkmate));
    _data.add(Marker(focus));
    _data.add(Marker(possib, drawOverPiece: true, circlePercentage: 0.5));
  }

  setCheckmate(Point src) => _data[checkmate].addPoint(<Point>[src]);
  setFocus(Point src) => _data[focus].addPoint(<Point>[src]);
  addPossib(List<Point> ps) => _data[possib].addPoint(ps);

  operator [](int i) => _data[i];
  operator []=(int i, Marker value) => _data[i] = value;
}

class _BoardGraphics extends CustomPainter {
  static int max = 8;
  // how to much resize piece icons
  static double txtrm = 25;
  // these are for piece shadows
  static double cShadowOffset = 2.0;
  static double cShadowBlur = 0.0;
  // indicatorSize is the font percentage for the indicator(letters and numbers alongside the square)
  static double indicatorPercentage = 0.20;

  final Markers markerPoints;

  Color pri;
  Color sec;

  final Piece Function(Point src) getPiece;
  final bool reverse;

  double div = 0.0;

  _BoardGraphics(this.pri, this.sec, this.markerPoints, this.getPiece,
      {this.reverse = false});

  Color getBackground(Point pnt) {
    final x = pnt.x;
    final y = pnt.y;

    final Color pri = (x % 2 == 1) ? this.pri : this.sec;
    final Color sec = pri == this.pri ? this.sec : this.pri;

    final clr = (y % 2) == 0 ? sec : pri;
    return clr;
  }

  void drawIndicator(Canvas canvas, double minx, double miny, int number,
      {bool letter}) {
    // indicatorSize is the square size multiplied by indicatorPercentage
    // indicator is the letter/number drawn alongside squares
    final indicatorSize = div * indicatorPercentage;

    final int x = minx ~/ div;
    final int y = miny ~/ div;

    number = reverse ? 8 - number.abs() : number + 1;
    final str =
        letter == true ? numToLetter(number).toLowerCase() : number.toString();

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ),
    );

    builder.pushStyle(ui.TextStyle(
      color: getBackground(Point(x + 1, y)),
      fontSize: indicatorSize,
      fontWeight: FontWeight.bold,
      fontFamily: "monospace",
    ));
    builder.addText(str);

    final para = builder.build();
    para.layout(ui.ParagraphConstraints(width: 0));

    canvas.drawParagraph(para, Offset(minx, miny - 5));
  }

  Point clickAt(double dx, double dy) {
    final src = Point(dx ~/ div, dy ~/ div);

    return reverse ? src.reverse() : src;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // well to make the canvas have 1:1 aspect ratio, pick the smaller (width or height), and set it as the size for each piece, square, or circle.
    final res = size.shortestSide;
    div = res / max;

    for (int x = 0; x < max; x++) {
      for (int y = 0; y < max; y++) {
        final drawers = <Function(Canvas)>[];
        final pnt = !reverse ? Point(x, y) : Point(x, y).reverse();
        // minimum x and y
        double minx = x * div;
        double miny = y * div;
        // maximum x and y
        double maxx = (x + 1) * div;
        double maxy = (y + 1) * div;
        final rect = Rect.fromLTRB(minx, miny, maxx, maxy);
        // draw all squares
        final paint = Paint();
        paint.color = getBackground(Point(x, y));
        canvas.drawRect(rect, paint);
        // draw all markers
        markerPoints.forEach((Marker mark) {
          final callback = (Canvas canvas) {
            if (mark.points.containsKey(pnt.toString())) {
              final paint = Paint()..color = mark.color;
              if (mark.circlePercentage != null) {
                final scale = mark.circlePercentage;

                final radius = scale * (div / 2);

                final double diff = 1.0 / scale;
                final x = minx + (radius * diff);
                final y = miny + (radius * diff);

                canvas.drawCircle(Offset(x, y), radius, paint);
              } else
                canvas.drawRect(rect, paint);
            }
          };

          if (mark.drawOverPiece != null && mark.drawOverPiece == true)
            drawers.add(callback);
          else
            callback(canvas);
        });

        final pec = getPiece(pnt);
        // draw the piece
        if (pec != null) {
          final icon = PieceKind.getIcon(pec.kind);
          final clr = !pec.p1 ? Colors.black : Colors.white;
          final shadowclr = !pec.p1 ? Colors.white : Colors.black;
          if (icon != null) {
            final builder = ui.ParagraphBuilder(
              ui.ParagraphStyle(
                textAlign: TextAlign.center,
              ),
            );

            builder.pushStyle(ui.TextStyle(
              color: clr,
              fontSize: div - txtrm,
              fontFamily: icon.fontFamily,
              shadows: <Shadow>[
                Shadow(
                  color: shadowclr,
                  offset: Offset(0, cShadowOffset),
                  blurRadius: cShadowBlur,
                ),
                Shadow(
                  color: shadowclr,
                  offset: Offset(0, cShadowOffset * -1),
                  blurRadius: cShadowBlur,
                ),
                Shadow(
                  color: shadowclr,
                  offset: Offset(cShadowOffset, 0),
                  blurRadius: cShadowBlur,
                ),
                Shadow(
                  color: shadowclr,
                  offset: Offset(cShadowOffset * -1, 0),
                  blurRadius: cShadowBlur,
                ),
              ],
            ));
            builder.addText(String.fromCharCode(icon.codePoint));

            final para = builder.build();
            para.layout(ui.ParagraphConstraints(width: div - txtrm));

            canvas.save();

            // canvas.drawPaint(Paint()..color = shadowclr);
            canvas.drawParagraph(
                para, Offset(minx + (txtrm / 2), miny + (txtrm / 2)));

            canvas.restore();
          }
        }
        // draw markers that have drawOverPiece as true
        drawers.forEach((callback) {
          callback(canvas);
        });
        final indicatorSize = (div * indicatorPercentage);
        if (x == 0) {
          drawIndicator(canvas, minx + (0.5 * indicatorSize),
              miny + (0.5 * indicatorSize), y,
              letter: false);
        }
        if (y == 7) {
          minx = (minx + div) - (indicatorSize);
          miny = (miny + div) - (indicatorSize);
          drawIndicator(canvas, minx, miny, x, letter: true);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardGraphics old) =>
      old.pri != pri ||
      old.sec != sec ||
      old.markerPoints != markerPoints ||
      old.reverse != reverse;
}

class Board extends StatefulWidget {
  final board.Board brd;
  final Markers markers;
  final _BoardGraphics graphics;

  Board(this.brd, this.markers)
      : graphics = _BoardGraphics(Colors.white, Colors.blueGrey, markers,
            (Point src) => brd.get(src).piece);

  @override
  createState() => _BoardState();
}

class _BoardState extends State<Board> {
  @override
  initState() {
    widget.brd.addListener(redraw);
    widget.markers.addListener(redraw);
    super.initState();
  }

  @override
  dispose() {
    widget.brd.removeListener(redraw);
    widget.markers.addListener(redraw);
    super.dispose();
  }

  void redraw() {
    setState(() {});
  }

  @override
  build(BuildContext context) {
    return CustomPaint(
      painter: widget.graphics,
      child: Container(),
    );
  }
}
