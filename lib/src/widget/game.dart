import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/clickable.dart' as game;
import 'package:chess_client/src/widget/game/controls.dart' as game;
import 'package:chess_client/src/widget/game/profile.dart' as game;
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
  bool get isOurTurn => false;
  bool isReverse = false;
  bool isFinished = false;

  game.Markers markers;

  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  void toggleReverse() {
    isReverse = !isReverse;
  }

  @override
  Widget build(BuildContext context) {
    final p1 = widget.service.p1;

    if (markers == null) {
      markers = game.Markers(
        Theme.of(context).errorColor,
        Theme.of(context).primaryColor.withOpacity(0.54),
        Theme.of(context).primaryColor,
      );
    }

    final brd = widget.testing ? widget.service.board : widget._brd;
    final wdgt = game.Board(brd, markers);

    model.Profile top = !p1 ? widget.service.profile : widget.service.vsprofile;
    bool topp1 = false;

    model.Profile bot = p1 ? widget.service.vsprofile : widget.service.profile;
    bool botp1 = true;

    if (isReverse) {
      model.Profile placeholder = top;

      top = bot;
      bot = placeholder;

      bool p1 = topp1;
      topp1 = botp1;
      botp1 = p1;
    }

    final black = Colors.grey[700];
    final white = Colors.grey[300];

    return Column(
      children: <Widget>[
        game.Profile(top, brd.deadPieces(topp1), clr: topp1 ? white : black),
        if (isFinished && !widget.testing)
          wdgt
        else
          game.Clickable(wdgt, widget.service),
        game.Profile(top, brd.deadPieces(botp1), clr: botp1 ? black : white),
        game.Controls(
            brd, toggleReverse, widget.goToHub, isOurTurn, isFinished),
        //game
      ],
    );
  }
}
