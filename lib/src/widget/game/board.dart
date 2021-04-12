import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/widget/game/piece_icons.dart' as icons;
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
  final points = HashMap<String, void>();
  final Color color;
  final bool isCircle;
  // if isCircle is true and this variable is null, then default value(1.0) will be used.
  final double circlePercentage;
  // should our marker draw over the pieces???
  final bool drawOverPiece;

  BoardMarker(this.color,
      {this.isCircle, this.circlePercentage, this.drawOverPiece});

  addPoint(Point pec) {
    points[pec.toString()] = pec;
  }
}

class BoardBackground extends CustomPainter {
  static int size = 8;
  static int imgSize = 200;

  final List<BoardMarker> markerPoints;

  Color pri;
  Color sec;

  final HashMap<String, Piece> pieces;
  final _images = <String, ui.Image>{} as HashMap<String, ui.Image>;

  ValueNotifier<int> _repaint;
  Animation<double> _anim;
  AnimationController _controller;

  double div;

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

  BoardBackground(this.pri, this.sec, this.markerPoints, this.pieces,
      {ValueNotifier<int> repaint, AnimationController controller})
      : super(repaint: Listenable.merge(<Listenable>[repaint, controller])) {
    if (controller != null) {
      _controller = controller;

      _anim = Tween<double>(begin: 0, end: 5).animate(controller);

      _anim.addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      });

      _controller.forward();
    }

    _repaint = repaint;
    loadCache();
  }

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

  final icon = icons.Pawn();

  @override
  void paint(Canvas canvas, Size size) {
    final res = size.height > size.width ? size.width : size.height;
    div = res / BoardBackground.size;

    final imgscale = (div < BoardBackground.imgSize
        ? div / BoardBackground.imgSize
        : BoardBackground.imgSize / div);

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

                final double diff = 1.0 / mark.circlePercentage;
                final x = minx + (radius * diff);
                final y = miny + (radius * diff);

                canvas.drawCircle(Offset(x, y), radius, paint);
              } else
                canvas.drawRect(rect, paint);
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

    icon.paint(canvas, size);
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
  final markers = <BoardMarker>[];

  @override
  initState() {
    Timer(Duration(seconds: 2), () {
      final bm = BoardMarker(Colors.amber);
      bm.addPoint(Point(4, 4));

      markers.add(bm);
    });

    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  build(BuildContext build) {
    final bg = BoardBackground(
      Colors.white,
      Colors.grey[900],
      markers,
      <String, Piece>{"4:3": Piece(Point(4, 3), PieceKind.king, 2)}
          as HashMap<String, Piece>,
      repaint: ValueNotifier(0),
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
