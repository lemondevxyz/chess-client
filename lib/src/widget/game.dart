import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/clickable.dart' as game;
import 'package:chess_client/src/widget/game/controls.dart' as game;
import 'package:chess_client/src/widget/game/profile.dart' as game;

import 'package:chess_client/icons.dart' as icons;
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  final rest.GameService service;
  final void Function() goToHub;
  final bool testing;
  final GlobalKey<NavigatorState> _navigator;
  final bool spectating;

  final _brd = board.Board();

  GameRoute(this.service, this.goToHub, this._navigator,
      {this.testing = false, this.spectating = false});

  @override
  createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  bool get isOurTurn => false;
  bool isReverse = false;
  bool isFinished = false;
  Key redrawControls;

  game.Markers markers;

  onTurn(_) => redrawControls = UniqueKey();

  onDone(dynamic parameter) {
    final done = parameter as order.Done;
    String title = "Draw";
    if (done.p1 != null) {
      final won = done.p1 == widget.service.p1;
      title = won ? "You won" : "You Lost";
    }

    dialog(
        title, "You can stay here to analyse the game\nor go back to the hub");
  }

  @override
  initState() {
    widget.service.subscribe(order.OrderID.Turn, onTurn);
    widget.service.subscribe(order.OrderID.Done, onDone);

    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  void toggleReverse() {
    isReverse = !isReverse;
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
    bool p1 = true;
    if (!widget.testing) {
      p1 = widget.service.p1;
    }

    if (markers == null) {
      markers = game.Markers(
        checkmate: Theme.of(context).errorColor,
        possib: Theme.of(context).primaryColor.withOpacity(0.54),
        focus: Theme.of(context).primaryColor,
      );
    }

    final brd = !widget.testing ? widget.service.board : widget._brd;

    final wdgt = game.Board(brd, markers);

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
      top = !p1 ? widget.service.profile : widget.service.vsprofile;
      topp1 = false;

      bot = p1 ? widget.service.vsprofile : widget.service.profile;
      botp1 = true;

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
                  isOurTurn, isFinished || widget.spectating,
                  dir: dir == Axis.vertical ? Axis.horizontal : Axis.vertical,
                  key: redrawControls);
              final brdwidget = Expanded(
                child: (isFinished || widget.testing)
                    ? wdgt
                    : game.Clickable(wdgt, widget.service),
              );

              if (dir == Axis.vertical) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    p1,
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: brdwidget,
                    ),
                    p2,
                    cntrls,
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
                            brdwidget,
                            p2,
                          ],
                        ),
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
