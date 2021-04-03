import 'dart:math' as math;

import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

class Controls extends StatelessWidget {
  static double size = 36.0;

  final rest.HistoryService service;
  final Function() reverse;
  final Function() goToHub;
  final bool yourTurn;
  final bool isFinished;

  const Controls(
      this.service, this.reverse, this.goToHub, this.yourTurn, this.isFinished,
      {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prev = service.canGoPrev();
    final next = service.canGoNext();
    final reset = service.canResetHistory();

    IconData turnIcon;
    if (yourTurn)
      turnIcon = Icons.check_circle;
    else
      turnIcon = Icons.cancel;

    Color turnColor;
    if (yourTurn)
      turnColor = Colors.green;
    else
      turnColor = Colors.red;

    String turnTooltip;
    if (yourTurn)
      turnTooltip = "Your turn";
    else
      turnTooltip = "Not your turn";

    const around = Spacer(flex: 5);

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final min = width > height ? height : width;
    final size = min / 16;

    final spacing = SizedBox(
      width: size,
      height: size,
    );

    final ok = isFinished || yourTurn;

    return Row(
      children: <Widget>[
        around,
        Tooltip(
          message: "Return to hub",
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: IconButton(
              onPressed: () {
                if (isFinished) goToHub();
              },
              iconSize: size,
              icon: Icon(
                Icons.exit_to_app,
                color: isFinished
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
        spacing,
        Tooltip(
          message: "View previous move",
          child: IconButton(
            iconSize: size,
            icon: Icon(
              Icons.chevron_left,
              color: prev && ok
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (prev && ok) service.goPrev();
            },
          ),
        ),
        spacing,
        Tooltip(
          message: turnTooltip,
          child: Icon(
            turnIcon,
            color: turnColor,
            size: size,
          ),
        ),
        spacing,
        Tooltip(
          message: "Reset the board",
          child: IconButton(
            iconSize: size,
            icon: Icon(
              Icons.restore,
              color: reset && ok
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (reset && ok) service.resetHistory();
            },
          ),
        ),
        spacing,
        if (reverse != null)
          Tooltip(
            message: "Reverse the board",
            child: IconButton(
              iconSize: size,
              icon: Icon(
                Icons.swap_vert,
              ),
              color: Theme.of(context).primaryColor,
              onPressed: () {
                if (reverse != null) reverse();
              },
            ),
          ),
        spacing,
        Tooltip(
          message: "View next move",
          child: IconButton(
            iconSize: size,
            icon: Icon(
              Icons.chevron_right,
              color: next && ok
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (next && ok) service.goNext();
            },
          ),
        ),
        around,
      ],
    );
  }
}
