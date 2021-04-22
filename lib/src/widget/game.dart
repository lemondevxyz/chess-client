// Our widgets
import 'dart:collection';

import 'package:chess_client/icons.dart' as icons;
import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/board/utils.dart' as utils;
import 'package:chess_client/src/model/order.dart' as order;
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
  bool _reverse = false;

  int focusid;
  int promoteid;

  Key rebuild = Key("");

  final markers = <game.BoardMarker>[];

  bool get yourTurn => widget.testing
      ? true
      : (!_isFinished ? p1 == widget.service.playerTurn : false);

  Board _board() {
    if (widget.testing) {
      return brd;
    } else {
      if (!_isFinished && widget.service.board != null) {
        return widget.service.board;
      } else {
        return brd;
      }
    }
  }

  Piece getPiece(Point src) {
    if (!widget.testing) {
      if (_board() == null) return null;
      final mp = _board().get(src);
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
    if (!(parameter is order.Turn)) {
      print("checkmate has bad struct");
      return;
    }

    final c = parameter as order.Turn;
    setState(() {
      final king = brd.getByIndex(utils.getKing(p1));
      markers[0].addPoint(<Point>[king.pos]);

      checkmate = c.p1;
    });
  }

  onPromote(dynamic d) {
    if (!(d is order.Promote)) throw "dynamic is not of type model.Promote";

    final pro = d as order.Promote;
    setState(() {
      promoteid = pro.id;
      showDialog(
        context: widget._navigator.currentContext,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text("Promote your piece!"),
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
        },
      );
    });
  }

  onTurn() {
    setState(() {
      if (markers.length > 2) {
        markers[0].points.clear();
        markers[1].points.clear();
      }
    });
  }

  onDone(dynamic parameter) {
    widget.service.board.removeListener(onTurn);
    brd = widget.service.board.copy();
    _isFinished = true;

    brd.addListener(onTurn);
    rebuild = UniqueKey();

    setState(() {});

    if (!(parameter is order.Done)) throw "bad parameter for done";
    final d = parameter as order.Done;

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
    widget.service.unsubscribe(order.OrderID.Done);
    widget.service.unsubscribe(order.OrderID.Turn);
    widget.service.unsubscribe(order.OrderID.Promote);
    widget.service.unsubscribe(order.OrderID.Checkmate);

    final brd = _board();
    if (brd != null) brd.removeListener(onTurn);

    super.dispose();
  }

  @override
  initState() {
    if (!widget.testing) {
      widget.service.subscribe(order.OrderID.Done, onDone);
      widget.service.subscribe(order.OrderID.Checkmate, onCheckmate);
      widget.service.subscribe(order.OrderID.Turn, (_) {
        onTurn();
        checkmate = false;
      });
      widget.service.subscribe(order.OrderID.Promote, onPromote);

      p1 = widget.service.p1;
      _reverse = !widget.service.p1;
    }

    _board().removeListener(onTurn);
    _board().addListener(onTurn);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (markers.length == 0) {
      final pri = Theme.of(context).primaryColor;

      markers.add(game.BoardMarker(pri));
      markers.add(
        game.BoardMarker(pri.withOpacity(0.54),
            drawOverPiece: true, isCircle: true, circlePercentage: 0.5),
      );
    }

    final bg = game.BoardGraphics(
        Colors.white, Colors.blueGrey, markers, getPiece,
        reverse: _reverse);

    final brdwidget = GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (_board().historyLast != _board().history.length) {
          _board().resetHistory();
          return;
        }

        if (_isFinished) return;

        if (promoteid != null) return;

        Point dst =
            bg.clickAt(details.localPosition.dx, details.localPosition.dy);
        final mm = widget.service.board.get(dst);

        if (widget.service.playerTurn != p1) return;

        if (mm != null) {
          final pec = mm.piece;
          // our piece?
          if (pec.p1 == p1) {
            // are we focused at a previous piece?
            if (focusid != null) {
              final cep = widget.service.board.getByIndex(focusid);

              // are they king and rook? then do castling
              final ok1 =
                  pec.kind == PieceKind.king && cep.kind == PieceKind.rook;
              final ok2 =
                  pec.kind == PieceKind.rook && cep.kind == PieceKind.king;
              if (ok1 || ok2) {
                widget.service.castling(focusid, mm.id);

                setState(() {
                  markers[1].points.clear();
                  markers[0].points.clear();

                  focusid = null;
                });
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

            widget.service.possib(mm.id).then((HashMap<String, Point> ll) {
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
        painter: bg,
        child: Container(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(icons.arrow_back),
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
                            widget.service.unsubscribe(order.OrderID.Done);
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
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(child: Container()),
              Expanded(
                flex: 20,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: brdwidget,
                ),
              ),
              game.Controls(widget.service.board, reverse, widget.goToHub,
                  yourTurn, _isFinished),
              //Expanded(child: Container()),
            ],
          ),
        ],
      ),
    );
  }
}
