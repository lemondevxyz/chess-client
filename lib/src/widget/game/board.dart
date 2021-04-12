import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:chess_client/chess_client_icons.dart';
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

class BoardBackground extends CustomPainter {
  static int size = 8;
  static int imgSize = 200;
  // these are for piece shadows
  static double shadowoffset = 2.0;
  static double shadowblur = 2.0;

  final List<BoardMarker> markerPoints;

  Color pri;
  Color sec;

  final HashMap<String, Piece> pieces;
  final _images = <String, ui.Image>{} as HashMap<String, ui.Image>;

  double div;

  BoardBackground(this.pri, this.sec, this.markerPoints, this.pieces);

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
    div = res / BoardBackground.size;

    for (int x = 0; x < BoardBackground.size; x++) {
      for (int y = 0; y < BoardBackground.size; y++) {
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
            if (mark.points.containsKey(Point(x, y).toString())) {
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

          if (mark.drawOverPiece)
            drawers.add(callback);
          else
            callback(canvas);
        });

        final pec = pieces[pnt.toString()];
        if (pec != null) {
          final icon = ChessClient.pawn;
          final clr = (pec.num == 1 ? Colors.black : Colors.white);
          final shadowclr = clr == Colors.black ? Colors.white : Colors.black;

          TextPainter tp = TextPainter(textDirection: TextDirection.rtl);

          tp.text = TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              color: clr,
              fontSize: div,
              fontFamily: icon.fontFamily,
              shadows: <Shadow>[
                Shadow(
                    color: shadowclr,
                    offset: Offset(0.0, shadowoffset),
                    blurRadius: shadowblur),
                Shadow(
                    color: Colors.black,
                    offset: Offset(0.0, shadowoffset),
                    blurRadius: shadowblur),
                Shadow(
                    color: Colors.black,
                    offset: Offset(shadowoffset, 0.0),
                    blurRadius: shadowblur),
                Shadow(
                    color: Colors.black,
                    offset: Offset(-shadowoffset, 0.0),
                    blurRadius: shadowblur),
              ],
            ),
          );
          tp.layout();

          tp.paint(canvas, Offset(minx, miny));
        }

        drawers.forEach((callback) {
          callback(canvas);
        });
      }
    }
  }

  @override
  bool shouldRepaint(BoardBackground old) =>
      old.pri != pri ||
      old.sec != sec ||
      old.markerPoints != markerPoints ||
      old.pieces != pieces ||
      (old._images.length == 0 && _images.length == 12);
}

class _BoardWidgetState extends State<BoardWidget>
    with SingleTickerProviderStateMixin {
  final markers = <BoardMarker>[
    BoardMarker(Colors.red, isCircle: true, drawOverPiece: false)
      ..addPoint(<Point>[
        Point(4, 3),
      ]),
  ];

  @override
  build(BuildContext build) {
    final bg = BoardBackground(
      Colors.white,
      Colors.grey[900],
      markers,
      <String, Piece>{"4:3": Piece(Point(4, 3), PieceKind.king, 2)}
          as HashMap<String, Piece>,
    );

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        final pos = details.localPosition;

        final pnt = bg.clickAt(pos.dx, pos.dy);
        print("point $pnt");
      },
      child: CustomPaint(
        isComplex: true,
        willChange: true,
        painter: bg,
      ),
    );
  }
}

class BoardWidget extends StatefulWidget {
  @override
  _BoardWidgetState createState() => _BoardWidgetState();
}
