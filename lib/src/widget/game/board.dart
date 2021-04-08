import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final HashMap<String, void> points;
  final Color color;
  final bool isCircle;
  // if isCircle is true and this variable is null, then defualt value(1.0) will be used.
  final double circlePercentage;
  // should our marker draw over the pieces???
  final bool drawOverPiece;

  const BoardMarker(this.points, this.color,
      {this.isCircle, this.circlePercentage, this.drawOverPiece});
}

class BoardBackground extends CustomPainter {
  static int size = 8;
  static int imgSize = 200;

  final List<BoardMarker> markerPoints;

  Color pri;
  Color sec;

  final HashMap<String, Piece> pieces;
  ValueNotifier<int> _repaint;

  final _images = <String, ui.Image>{} as HashMap<String, ui.Image>;

  loadCache() {
    final pecs = <Piece>[
      Piece(Point(0, 0), PieceKind.rook, 1),
      Piece(Point(0, 0), PieceKind.knight, 1),
      Piece(Point(0, 0), PieceKind.bishop, 1),
      Piece(Point(0, 0), PieceKind.queen, 1),
      Piece(Point(0, 0), PieceKind.king, 1),
      Piece(Point(0, 0), PieceKind.pawnf, 1),
    ];

    for (var i = 0; i < 2; i++) {
      pecs.asMap().forEach((int index, Piece pec) {
        if (i == 1) pec.num = 2;
        final name = pec.filename();

        rootBundle.load(name).then((img) {
          ui.decodeImageFromList(Uint8List.view(img.buffer), (ui.Image img) {
            _images[name] = img;
            if (_images.length == 12) _repaint.value++;
          });
        });
      });
    }
  }

  final Animation<double> _pos;

  BoardBackground(this.pri, this.sec, this.markerPoints, this.pieces,
      {@required Listenable repaint, @required Animation<double> animation})
      : _pos = Tween<double>(begin: 0, end: 300).animate(animation),
        super(repaint: repaint) {
    loadCache();
    _repaint = repaint;
  }

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
    final div = res / BoardBackground.size;
    final imgscale = (div < BoardBackground.imgSize
        ? div / BoardBackground.imgSize
        : BoardBackground.imgSize / div);

    // print("animatin??");

    for (int x = 0; x < BoardBackground.size; x++) {
      for (int y = 0; y < BoardBackground.size; y++) {
        final drawers = <Function()>[];
        final pnt = Point(x, y);

        // minimum x and y
        double minx = x * div;
        double miny = y * div;
        // maximum x and y
        double maxx = (x + 1) * div;
        double maxy = (y + 1) * div;
        final rect = Rect.fromLTRB(minx, miny, maxx, maxy);
        // draw all squares
        canvas.drawRect(rect, Paint()..color = getBackground(Point(x, y)));
        // draw all markers
        markerPoints.forEach((BoardMarker mark) {
          if (mark.points.containsKey(Point(x, y).toString())) {
            final callback = () {
              final paint = Paint()..color = mark.color;
              if (mark.isCircle == true) {
                final scale =
                    mark.circlePercentage == null ? 1.0 : mark.circlePercentage;
                final radius = scale * (div / 2);

                final x = minx + (radius * 2);
                final y = miny + (radius * 2);

                canvas.drawCircle(Offset(x, y), scale * (div / 2), paint);
              } else
                canvas.drawRect(rect, paint);

              return;
            };

            if (mark.drawOverPiece == true)
              drawers.add(callback);
            else
              callback();
          }
        });

        // save the canvas
        // because we want to scale down the image
        // then restore the canvas
        if (_images.length == 12) {
          final pec = pieces[pnt.toString()];
          if (pec != null) {
            canvas.save();
            // scale down the canvas, cause we cannot scale down the image :(
            // note: if there's a better way to do this, hit me up!!!!
            canvas.scale(imgscale);
            // draw the darn thing
            // (minx|miny) / imgscale
            // will center the image in it's position
            canvas.drawImage(_images[pec.filename()],
                Offset(minx / imgscale, miny / imgscale), Paint());

            canvas.restore();
          }
        }

        // remember drawOverPiece, well this is also the only way to do this
        // basically store the drawing function in an array(drawer) and execute them later.
        // canvas.save & canvas.restore don't work
        drawers.forEach((fn) {
          fn();
        });
      }
    }

    if (_images.length == 12) {
      final pec = Piece(Point(4, 3), PieceKind.rook, 1);

      canvas.save();
      // scale down the canvas, cause we cannot scale down the image :(
      // note: if there's a better way to do this, hit me up!!!!
      canvas.scale(imgscale);
      // draw the darn thing
      // (minx|miny) / imgscale
      // will center the image in it's position
      canvas.drawImage(_images[pec.filename()], Offset(_pos.value, 0), Paint());

      canvas.restore();
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
  @override
  build(BuildContext build) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: CustomPaint(
            painter: BoardBackground(
              Colors.white,
              Colors.blueGrey,
              <BoardMarker>[
                BoardMarker(
                  <String, Point>{
                    "4:3": Point(4, 3),
                    "6:3": Point(6, 3),
                  } as HashMap,
                  Colors.amber,
                ),
                BoardMarker(
                  <String, Point>{
                    "3:3": Point(3, 3),
                  } as HashMap,
                  Colors.red.withOpacity(0.75),
                  drawOverPiece: false,
                  isCircle: true,
                  circlePercentage: 0.5,
                ),
              ],
              <String, Piece>{"3:3": Piece(Point(3, 3), PieceKind.king, 2)}
                  as HashMap,
              repaint: ValueNotifier(0),
              animation: AnimationController(
                  vsync: this, duration: const Duration(seconds: 10)),
            ),
          ),
        ),
      ],
    );
  }
}

class BoardWidget extends StatefulWidget {
  @override
  _BoardWidgetState createState() => _BoardWidgetState();
}
