import 'dart:ui';

import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

class Promotion extends StatelessWidget {
  final Function(int) promoteCallback;
  final int player;

  const Promotion(this.player, this.promoteCallback, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              //print("${constraints.minWidth} ${constraints.minHeight}");
              return Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    for (var i in <int>[
                      PieceKind.rook,
                      PieceKind.knight,
                      PieceKind.bishop,
                      PieceKind.queen
                    ])
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            promoteCallback(i);
                          },
                          child: Image.asset(
                            Piece(Point(0, 0), i, player).filename(),
                            width: constraints.minWidth / 6,
                            height: constraints.minWidth / 6,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
