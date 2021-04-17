import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

class Controls extends StatelessWidget {
  static double size = 36.0;

  final rest.HistoryService service;
  final Function() reverse;
  final Function() goToHub;
  final bool yourTurn;
  final bool isFinished;
  final bool disabled;

  const Controls(
      this.service, this.reverse, this.goToHub, this.yourTurn, this.isFinished,
      {this.disabled = false, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prev = service.canGoPrev();
    final next = service.canGoNext();
    final reset = service.canResetHistory();

    IconData turnIcon;
    Color turnColor;
    String turnTooltip;
    if (yourTurn) {
      turnIcon = Icons.check_circle;
      turnColor = Colors.green;
      turnTooltip = "Your turn";
    }
    if (!yourTurn || disabled) {
      turnIcon = Icons.cancel;
      turnColor = Colors.red;
      turnTooltip = "Not your turn";
    }
    if (disabled) turnColor = Theme.of(context).disabledColor;

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
    final wdgtturn = Icon(
      turnIcon,
      color: turnColor,
      size: size,
    );

    //final clr = Theme.of(context).hoverColor;

    return Row(
      children: <Widget>[
        around,
        IconButton(
          tooltip: !disabled ? "View previous move" : null,
          iconSize: size,
          icon: Icon(
            Icons.chevron_left,
            color: prev && ok && !disabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onPressed: !disabled
              ? () {
                  if (prev && ok) service.goPrev();
                }
              : null,
          //hoverColor: disabled ? Colors.transparent : clr,
        ),
        spacing,
        if (!disabled)
          Tooltip(
            message: turnTooltip,
            child: wdgtturn,
          )
        else
          wdgtturn,
        spacing,
        IconButton(
          tooltip: !disabled ? "Reset the board" : null,
          iconSize: size,
          icon: Icon(
            Icons.restore,
            color: reset && ok && !disabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onPressed: !disabled
              ? () {
                  if (reset && ok) service.resetHistory();
                }
              : null,
          //hoverColor: disabled ? Colors.transparent : clr,
        ),
        spacing,
        if (reverse != null)
          IconButton(
            tooltip: !disabled ? "Reverse the board" : null,
            iconSize: size,
            icon: Icon(
              Icons.swap_vert,
            ),
            color: Theme.of(context).primaryColor,
            onPressed: !disabled
                ? () {
                    if (reverse != null) reverse();
                  }
                : null,
            //hoverColor: disabled ? Colors.transparent : clr,
          ),
        spacing,
        IconButton(
          iconSize: size,
          icon: Icon(
            Icons.chevron_right,
            color: next && ok && !disabled
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onPressed: !disabled
              ? () {
                  if (next && ok) service.goNext();
                }
              : null,
          tooltip: !disabled ? "View next move" : null,
          //hoverColor: disabled ? Colors.transparent : clr,
        ),
        around,
      ],
    );
  }
}
