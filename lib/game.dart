import 'dart:ui';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'global.dart' as global;

class GameRoute extends StatefulWidget {
  final title = "Game";

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  Board brd = Board();
  final testing = global.debug == global.Debugging.game;
  bool _reverse = false;
  Point _promote;

  @override
  initState() {
    super.initState();
    if (!testing) {
      _reverse = (global.server.player == 1 ? false : true);
      global.server.onPromote.subscribe((Promote pro) {
        setState(() {
          _promote = pro.src;
        });
      });
    }

    _board().addListener(() {
      setState(() {});
    });
  }

  Board _board() {
    if (testing) {
      return brd;
    } else {
      return global.server.board;
    }
  }

  bool _yourTurn() {
    if (testing) {
      return true;
    } else {
      return global.server.player == global.server.playerTurn;
    }
  }

  Future<void> Function(Point, Point) _move() {
    if (testing) {
      return (Point src, Point dst) {
        if (!src.valid() || !dst.valid()) {
          return Future.error("invalid dst or src");
        }

        _board().move(_board().get(src), dst);

        return Future.value();
      };
    } else {
      return global.server.move;
    }
  }

  bool Function(Piece) _canFocus() {
    if (testing) {
      return (_) {
        return true;
      };
    } else {
      return (Piece pce) {
        return pce.num == global.server.player;
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Your Turn: ${_yourTurn() ? 'yes' : 'no'}"),
            TextButton(
              child: Text("reverse"),
              onPressed: () {
                setState(() {
                  _reverse = !_reverse;
                });
              },
            ),
            if (testing)
              TextButton(
                child: Text("reset board"),
                onPressed: (() {
                  setState(() {
                    brd = Board();
                  });
                }),
              ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  BoardWidget(
                    _board(),
                    _move(),
                    _yourTurn,
                    _canFocus(),
                    reverse: _reverse,
                    possib: !testing ? global.server.possib : null,
                  ),
                  if (_promote != null && !testing)
                    Positioned.fill(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              print(
                                  "${constraints.minWidth} ${constraints.minHeight}");
                              print(
                                  "${constraints.maxWidth} ${constraints.maxHeight}");
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
                                            global.server
                                                .promote(_promote, i)
                                                .then((_) {
                                              setState(() {
                                                this._promote = null;
                                              });
                                            }).catchError((e) {
                                              print("trying to promote: $e");
                                            });
                                          },
                                          child: Image.asset(
                                            Piece(Point(0, 0), i,
                                                    global.server.player)
                                                .filename(),
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
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
