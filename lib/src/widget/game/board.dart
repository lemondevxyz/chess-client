import 'dart:collection';
import 'dart:ui' as ui;

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

class BoardMarker {
  final points = HashMap<String, void>();
  final Color color;
  final bool isCircle;
  // if isCircle is true and this variable is null, then default value(1.0) will be used.
  final double circlePercentage;
  // should our marker draw over the pieces???
  final bool drawOverPiece;

  BoardMarker(this.color,
      {this.isCircle, this.circlePercentage, this.drawOverPiece});

  addPoint(List<Point> ps) {
    ps.forEach((pec) {
      points[pec.toString()] = pec;
    });
  }
}

class BoardGraphics extends CustomPainter {
  static int max = 8;
  static int imgSize = 200;
  // these are for piece shadows
  static double shadowoffset = 2.0;
  static double shadowblur = 2.0;

  final List<BoardMarker> markerPoints;

  Color pri;
  Color sec;

  final Piece Function(Point src) getPiece;

  double div;

  BoardGraphics(this.pri, this.sec, this.markerPoints, this.getPiece);

  Color getBackground(Point pnt) {
    final x = pnt.x;
    final y = pnt.y;

    final Color pri = (x % 2 == 1) ? this.pri : this.sec;
    final Color sec = pri == this.pri ? this.sec : this.pri;

    final clr = (y % 2) == 0 ? sec : pri;
    return clr;
  }

  Point clickAt(double dx, double dy) {
    return Point(dx ~/ div, dy ~/ div);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // well to make the canvas have 1:1 aspect ratio, pick the smaller (width or height), and set it as the size for each piece, square, or circle.
    final res = size.height > size.width ? size.width : size.height;
    div = res / max;

    for (int x = 0; x < max; x++) {
      for (int y = 0; y < max; y++) {
        final drawers = <Function(Canvas)>[];
        final pnt = Point(x, y);

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
        markerPoints.forEach((BoardMarker mark) {
          final callback = (Canvas canvas) {
            if (mark.points.containsKey(pnt.toString())) {
              print("nyes $pnt");
              final paint = Paint()..color = mark.color;
              if (mark.isCircle == true) {
                final scale =
                    mark.circlePercentage == null ? 1.0 : mark.circlePercentage;
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
              fontSize: div,
              fontFamily: icon.fontFamily,
            ));
            builder.addText(String.fromCharCode(icon.codePoint));

            final para = builder.build();
            para.layout(ui.ParagraphConstraints(width: div));

            canvas.drawParagraph(para, Offset(minx, miny));
          }
        }

        drawers.forEach((callback) {
          callback(canvas);
        });
      }
    }
  }

  @override
  bool shouldRepaint(BoardGraphics old) =>
      old.pri != pri || old.sec != sec || old.markerPoints != markerPoints;
}
