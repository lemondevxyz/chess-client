import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';
import 'package:chess_client/icons.dart' as icons;

class Controls extends StatelessWidget {
  static double size = 36.0;

  final rest.HistoryService service;
  final Function() toggleReverse;
  final Function() goToHub;
  final bool isOurTurn;
  final bool isFinished;

  final Axis dir;

  const Controls(this.service, this.toggleReverse, this.goToHub, this.isOurTurn,
      this.isFinished,
      {Key key, this.dir = Axis.horizontal})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final prev = service.canGoPrev();
    final next = service.canGoNext();
    final reset = service.canResetHistory();

    IconData turnIcon;
    Color turnColor;
    String turnTooltip;
    if (isOurTurn) {
      turnIcon = icons.check_circle;
      turnColor = Colors.green;
      turnTooltip = "Your turn";
    }
    if (!isOurTurn) {
      turnIcon = icons.cancel;
      turnColor = Colors.red;
      turnTooltip = "Not your turn";
    }

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final min = width > height ? height : width;
    final size = min / 16;

    final spacing = SizedBox(
      width: size,
      height: size,
    );

    final ok = isFinished || isOurTurn;
    final wdgtturn = Icon(
      turnIcon,
      color: turnColor,
      size: size,
    );

    return Flex(
      direction: dir,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        IconButton(
          tooltip: "View previous move",
          iconSize: size,
          icon: Icon(
            icons.keyboard_arrow_left,
            color: prev && ok
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onPressed: () {
            if (prev && ok) service.goPrev();
          },
          //hoverColor: disabled ? Colors.transparent : clr,
        ),
        spacing,
        Tooltip(
          message: turnTooltip,
          child: wdgtturn,
        ),
        spacing,
        IconButton(
            tooltip: "Reset the board",
            iconSize: size,
            icon: Icon(
              icons.restore,
              color: reset && ok
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).disabledColor,
            ),
            onPressed: () {
              if (reset && ok) service.resetHistory();
            }
            //hoverColor: disabled ? Colors.transparent : clr,
            ),
        spacing,
        if (toggleReverse != null)
          IconButton(
            tooltip: "Reverse the board",
            iconSize: size,
            icon: Icon(
              icons.swap_vert,
            ),
            color: Theme.of(context).primaryColor,
            onPressed: () {
              if (toggleReverse != null) toggleReverse();
            },
            //hoverColor: disabled ? Colors.transparent : clr,
          ),
        spacing,
        IconButton(
          iconSize: size,
          icon: Icon(
            icons.keyboard_arrow_right,
            color: next && ok
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          onPressed: () {
            if (next && ok) service.goNext();
          },
          tooltip: "View next move",
          //hoverColor: disabled ? Colors.transparent : clr,
        ),
      ],
    );
  }
}
