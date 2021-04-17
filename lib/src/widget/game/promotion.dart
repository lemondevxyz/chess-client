import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

class Promotion extends StatelessWidget {
  final Function(int) promoteCallback;
  final bool p1;

  const Promotion(this.p1, this.promoteCallback, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final list = <Piece>[
      Piece(Point(-1, -1), PieceKind.rook, p1),
      Piece(Point(-1, -1), PieceKind.bishop, p1),
      Piece(Point(-1, -1), PieceKind.knight, p1),
      Piece(Point(-1, -1), PieceKind.queen, p1),
    ];
    final iconclr = p1 ? Colors.white : Colors.black;

    return LayoutBuilder(builder: (BuildContext ctx, BoxConstraints box) {
      final size = box.maxWidth / 7;
      return Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            for (var pec in list)
              IconButton(
                iconSize: size,
                icon: Icon(
                  PieceKind.getIcon(pec.kind),
                  color: iconclr,
                ),
                onPressed: () {
                  promoteCallback(pec.kind);
                },
              ),
          ],
        ),
      );
    });
  }
}
