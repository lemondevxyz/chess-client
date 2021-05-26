import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/clickable.dart' as game;
import 'package:chess_client/src/widget/game/controls.dart' as game;
import 'package:chess_client/src/widget/game/profile.dart' as game;
import 'package:chess_client/src/widget/game/promotion.dart' as game;

import 'package:chess_client/icons.dart' as icons;
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  final rest.GameService service;
  final void Function() goToHub;
  final bool testing;
  final GlobalKey<NavigatorState> _navigator;

  final _brd = board.Board();

  GameRoute(this.service, this.goToHub, this._navigator,
      {this.testing = false});

  @override
  createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  bool get isOurTurn {
    if (!widget.testing) if (widget.service.p1 != null)
      return widget.service.p1 == widget.service.playerTurn;

    return false;
  }

  bool get spectating {
    if (!widget.testing)
      return widget.service.p1 == null;
    else
      return false;
  }

  bool isReverse = false;
  bool isFinished = false;
  bool get p1 => widget.testing ? true : widget.service.p1;

  Key redrawControls;

  game.Markers markers;

  onPromote(dynamic d) {
    if (!(d is order.Promote)) throw "onPromote: !(d is order.Promote)";

    final promote = d as order.Promote;

    setState(() {
      showDialog(
        context: widget._navigator.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Promote your piece"),
            content: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: game.Promotion(p1, (int kind) {
                if (!widget.testing)
                  widget.service.promote(promote.id, kind).then((_) {
                    Navigator.of(context).pop();
                  }).catchError((e) {
                    print("promote: $e");
                  });
                else
                  Navigator.of(context).pop();
              }),
            ),
          );
        },
        barrierDismissible: false,
      );
    });
  }

  onTurn(_) => setState(() {
        redrawControls = UniqueKey();
      });

  onDone(dynamic parameter) {
    final done = parameter as order.Done;
    final title = order.DoneReason.getString(done.reason, widget.service.p1);

    dialog(
        title, "You can stay here to analyse the game\nor go back to the hub");
  }

  @override
  initState() {
    if (!widget.testing) {
      widget.service.subscribe(order.OrderID.Promote, onPromote);
      widget.service.subscribe(order.OrderID.Turn, onTurn);
      widget.service.subscribe(order.OrderID.Done, onDone);

      if (widget.service.p1 != null) isReverse = !widget.service.p1;
    }

    super.initState();
  }

  @override
  dispose() {
    if (!widget.testing) {
      widget.service.unsubscribe(order.OrderID.Promote);
      widget.service.unsubscribe(order.OrderID.Turn);
      widget.service.unsubscribe(order.OrderID.Done);
    }

    super.dispose();
  }

  void toggleReverse() {
    setState(() {
      isReverse = !isReverse;
    });
  }

  void dialog(String title, String description) {
    showDialog(
        context: widget._navigator.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(description),
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
  Widget build(BuildContext context) {
    if (markers == null) {
      markers = game.Markers(
        checkmate: Theme.of(context).errorColor,
        possib: Theme.of(context).primaryColor.withOpacity(0.54),
        focus: Theme.of(context).primaryColor,
      );
    }

    final brd = !widget.testing ? widget.service.board : widget._brd;

    final wdgt = game.Board(brd, markers, reverse: this.isReverse);

    model.Profile top;
    model.Profile bot;

    bool topp1 = false;
    bool botp1 = true;
    if (widget.testing) {
      // plug
      top = model.Profile("2", "https://lemondev.xyz/android-icon-192x192.png",
          "black player", "client");
      bot = model.Profile("1", "https://lemondev.xyz/android-icon-192x192.png",
          "white player", "client");
    } else {
      if (widget.service.profile == null) {
        top = model.Profile("black", "", "black", "");
        bot = model.Profile("white", "", "white", "");
      } else {
        top = widget.service.profile.black;
        topp1 = false;

        bot = widget.service.profile.white;
        botp1 = true;
      }

      if (isReverse) {
        model.Profile placeholder = top;

        top = bot;
        bot = placeholder;

        bool p1 = topp1;
        topp1 = botp1;
        botp1 = p1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Game"),
        leading: IconButton(
          icon: Icon(icons.arrow_back),
          onPressed: () {
            const title = "Forfeit?";
            const description =
                "Are you sure you want to leave? leaving this game\nwill you make you lose!";

            dialog(title, description);
          },
        ),
      ),
      body: Center(
        child: Container(
          child: LayoutBuilder(
            builder: (BuildContext ctx, BoxConstraints cnt) {
              final dir = cnt.maxHeight > cnt.maxWidth
                  ? Axis.vertical
                  : Axis.horizontal;

              final p1 = game.Profile(top, topp1, brd.deadPieces(topp1));
              final p2 = game.Profile(bot, botp1, brd.deadPieces(botp1));
              final cntrls = game.Controls(brd, toggleReverse, widget.goToHub,
                  isOurTurn, isFinished || spectating,
                  dir: dir == Axis.vertical ? Axis.horizontal : Axis.vertical,
                  key: redrawControls);
              final brdwidget = (isFinished || widget.testing || spectating)
                  ? wdgt
                  : game.Clickable(wdgt, widget.service);

              if (dir == Axis.vertical) {
                return Column(
                  children: <Widget>[
                    p1,
                    Flexible(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: brdwidget,
                      ),
                    ),
                    p2,
                    cntrls,
                    if (widget.testing)
                      TextButton(
                        child: Text("promote dialog"),
                        onPressed: () {
                          onPromote(order.Promote(
                            1,
                            0,
                          ));
                        },
                      ),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: cntrls,
                    ),
                    AspectRatio(
                      aspectRatio: 0.9,
                      child: Container(
                        margin: EdgeInsets.only(left: 12.5),
                        child: Column(
                          children: <Widget>[
                            p1,
                            Expanded(
                              child: brdwidget,
                            ),
                            p2,
                          ],
                        ),
                      ),
                    ),
                    if (widget.testing)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: <Widget>[
                            TextButton(
                              child: Text("promote dialog"),
                              onPressed: () {
                                onPromote(order.Promote(
                                  1,
                                  0,
                                ));
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
