import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

class Controls extends StatelessWidget {
  static double size = 36.0;

  final Function() reverse;
  final rest.HistoryService service;
  final bool yourTurn;

  const Controls(this.service, this.reverse, this.yourTurn, {Key key})
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

    final size = MediaQuery.of(context).size.height / 16;

    final spacing = SizedBox(
      width: size,
      height: size,
    );
    return Row(
      children: <Widget>[
        around,
        Tooltip(
          message: "View previous move",
          child: IconButton(
            iconSize: size,
            icon: Icon(
              Icons.chevron_left,
              color: prev && yourTurn
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (prev && yourTurn) service.goPrev();
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
              color: reset && yourTurn
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (reset && yourTurn) service.resetHistory();
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
              color: next && yourTurn
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (next && yourTurn) service.goNext();
            },
          ),
        ),
        around,
      ],
    );
  }
}
