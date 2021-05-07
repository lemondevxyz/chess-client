import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

class Promotion extends StatelessWidget {
  final Function(int) promoteCallback;
  final bool p1;

  static double shadowblur = 2.0;
  static const list = <int>[
    PieceKind.rook,
    PieceKind.bishop,
    PieceKind.knight,
    PieceKind.queen,
  ];
  static const offset = <Offset>[
    Offset(2.0, 0),
    Offset(-2.0, 0),
    Offset(0, 2.0),
    Offset(0, -2.0),
  ];
  final Color iconclr;

  final Color shadowclr;

  const Promotion(this.p1, this.promoteCallback, {Key key})
      : this.iconclr = p1 ? Colors.white : Colors.black,
        this.shadowclr = p1 ? Colors.black : Colors.white,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        for (var kind in list)
          TextButton(
            child: Text(
              String.fromCharCode(PieceKind.getIcon(kind).codePoint),
              style: TextStyle(
                color: iconclr,
                fontSize: 48.0,
                fontFamily: PieceKind.getIcon(kind).fontFamily,
                shadows: <Shadow>[
                  Shadow(
                    color: shadowclr,
                    offset: offset[0],
                    blurRadius: shadowblur,
                  ),
                  Shadow(
                    color: shadowclr,
                    offset: offset[1],
                    blurRadius: shadowblur,
                  ),
                  Shadow(
                    color: shadowclr,
                    offset: offset[2],
                    blurRadius: shadowblur,
                  ),
                  Shadow(
                    color: shadowclr,
                    offset: offset[3],
                    blurRadius: shadowblur,
                  ),
                ],
              ),
            ),
            onPressed: () {
              promoteCallback(kind);
            },
          ),
      ],
    );
  }
}
