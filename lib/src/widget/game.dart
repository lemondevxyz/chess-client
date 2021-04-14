// Our widgets
import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/board/utils.dart' as utils;
import 'package:chess_client/src/order/model.dart' as model;
import 'package:chess_client/src/order/order.dart';
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/controls.dart' as game;
// flutter
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  final title = "Game";
  final bool testing;
  final rest.GameService service;
  final Function() goToHub;
  final GlobalKey<NavigatorState> _navigator;

  const GameRoute(this.testing, this.service, this.goToHub, this._navigator);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  Board brd = Board();
  bool _isFinished = false;
  bool checkmate;
  bool p1;
  bool _reverse;
  int focusid;

  final markers = <game.BoardMarker>[
    game.BoardMarker(Colors.blue),
    game.BoardMarker(Colors.purple,
        drawOverPiece: true, isCircle: true, circlePercentage: 0.5),
  ];

  Piece getPiece(Point src) {
    if (!widget.testing) {
      if (widget.service.board == null) return null;
      final mp = widget.service.board.get(src);
      if (mp == null) return null;

      return mp.piece;
    } else {
      return Piece(Point(0, 0), PieceKind.pawn, (src.x % 2) == 1);
    }
  }

  void reverse() {
    _reverse = !_reverse;

    setState(() {});
  }

  onCheckmate(dynamic parameter) {
    if (!(parameter is model.Turn)) {
      print("checkmate has bad struct");
      return;
    }

    final c = parameter as model.Turn;
    setState(() {
      final king = brd.getByIndex(utils.getKing(p1));
      markers[0].addPoint(<Point>[king.pos]);

      checkmate = c.p1;
    });
  }

  onDone(dynamic parameter) {
    widget.service.board.removeListener(onTurn);
    brd = widget.service.board.duplicate();
    _isFinished = true;

    brd.addListener(onTurn);

    setState(() {});

    if (!(parameter is model.Done)) throw "bad parameter for done";
    final d = parameter as model.Done;

    String text;
    if (d.p1 == widget.service.p1) {
      text = "You won";
    } else {
      text = "You lost";
    }

    showDialog(
        context: widget._navigator.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "The game ended. Would you like to stay or go back to the hub?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text("leave"),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (widget._navigator != null) {
                    widget.goToHub();
                  }
                },
              ),
              TextButton(
                child: Text("stay"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  dispose() {
    widget.service.unsubscribe(OrderID.Done);
    widget.service.unsubscribe(OrderID.Turn);
    widget.service.unsubscribe(OrderID.Promote);
    widget.service.unsubscribe(OrderID.Checkmate);

    final brd = _board();
    if (brd != null) brd.removeListener(onTurn);

    super.dispose();
  }

  @override
  initState() {
    print("testing: ${widget.testing}");
    if (!widget.testing) {
      widget.service.subscribe(OrderID.Done, onDone);
      widget.service.subscribe(OrderID.Checkmate, onCheckmate);
      widget.service.subscribe(OrderID.Turn, (_) {
        onTurn();
        checkmate = false;
      });

      p1 = widget.service.p1;
      _reverse = !widget.service.p1;
    }

    _board().removeListener(onTurn);
    _board().addListener(onTurn);

    super.initState();
  }

  Board _board() {
    if (widget.testing) {
      return brd;
    } else {
      if (!_isFinished) {
        return widget.service.board;
      } else {
        return brd;
      }
    }
  }

  onTurn() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bg = game.BoardGraphics(
        Colors.white, Colors.blueGrey, markers, getPiece,
        reverse: _reverse);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: !_isFinished,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Leave game",
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  final String txt = _isFinished
                      ? "Are you sure you want to leave? You'll lose the ability analyse this game!"
                      : "Are your sure you want to leave this game? You'll lose the game!";

                  return AlertDialog(
                    title: Text("Are you sure?"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(txt),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text("leave"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (!_isFinished) {
                            widget.service.unsubscribe(OrderID.Done);
                            widget.service.leaveGame();
                          }

                          widget.goToHub();
                        },
                      ),
                      TextButton(
                        child: Text("stay"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                });
          },
        ),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final height = constraints.maxHeight;
            final width = constraints.maxWidth;

            double size = width > height ? height : width;
            size = size * 0.85;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    Point dst = bg.clickAt(
                        details.localPosition.dx, details.localPosition.dy);
                    final mm = widget.service.board.get(dst);

                    if (widget.service.playerTurn != p1) {
                      print("not our turn");
                      return;
                    }

                    if (mm != null) {
                      final pec = mm.piece;
                      if (pec.p1 == p1) {
                        // our piece? well are we focused at a previous piece
                        if (focusid != null) {
                          print("id $focusid");
                          final cep = widget.service.board.getByIndex(focusid);

                          // are they king and rook? then do castling
                          final ok1 = pec.kind == PieceKind.king &&
                              cep.kind == PieceKind.rook;
                          final ok2 = pec.kind == PieceKind.rook &&
                              cep.kind == PieceKind.king;
                          if (ok1 || ok2) {
                            widget.service.castling(focusid, mm.id);
                            return;
                          }
                        }
                        // then select it
                        setState(() {
                          markers[1].points.clear();
                          markers[0].points.clear();
                          markers[0].addPoint(<Point>[
                            dst,
                          ]);

                          focusid = mm.id;
                        });

                        widget.service
                            .possib(mm.id)
                            .then((HashMap<String, Point> ll) {
                          markers[1].points.addAll(ll);
                        }).then((_) {
                          setState(() {});
                        });
                      } else {
                        // not our piece? then move there
                        if (focusid != null) {
                          widget.service.move(focusid, dst);

                          setState(() {
                            markers[1].points.clear();
                            markers[0].points.clear();

                            focusid = null;
                          });
                        }
                      }
                    } else {
                      if (focusid != null) {
                        widget.service.move(focusid, dst).catchError((e) {
                          print("error $e");
                        }).then((_) {
                          focusid = null;
                        });

                        setState(() {
                          markers[1].points.clear();
                          markers[0].points.clear();
                        });
                      }
                    }
                  },
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: bg,
                  ),
                ),
                game.Controls(widget.service.board, reverse, widget.goToHub,
                    widget.service.playerTurn == p1, _isFinished),
              ],
            );
          },
        ),
      ),
    );
  }
}
