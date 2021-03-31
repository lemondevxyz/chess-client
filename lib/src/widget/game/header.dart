import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  static double size = 36.0;

  final Function() reverse;
  final rest.HistoryService service;
  final bool yourTurn;

  const Header(this.service, this.reverse, this.yourTurn, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prev = service.canGoPrev();
    final next = service.canGoNext();

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
    const spacing = Spacer();

    return Row(
      children: <Widget>[
        around,
        Tooltip(
          message: "View previous move",
          child: IconButton(
            iconSize: Header.size,
            icon: Icon(
              Icons.chevron_left,
              color: prev
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (prev) service.goPrev();
            },
          ),
        ),
        spacing,
        Tooltip(
          message: turnTooltip,
          child: Icon(
            turnIcon,
            color: turnColor,
            size: Header.size,
          ),
        ),
        spacing,
        Tooltip(
          message: "Reset the board",
          child: IconButton(
            iconSize: Header.size,
            icon: Icon(
              Icons.restore,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () {
              service.resetHistory();
            },
          ),
        ),
        spacing,
        if (reverse != null)
          Tooltip(
            message: "Reverse the board",
            child: IconButton(
              iconSize: Header.size,
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
            iconSize: Header.size,
            icon: Icon(
              Icons.chevron_right,
              color: next
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (next) service.goNext();
            },
          ),
        ),
        around,
      ],
    );
  }
}
