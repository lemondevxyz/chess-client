import 'package:flutter/material.dart';
//import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/widget/game/profile.dart' as game;

class Invite extends StatelessWidget {
  final List<order.Invite> list;
  final Future<void> Function(order.Invite) tap;

  final String title;
  final String description;
  final Future<void> Function() refresh;

  const Invite(
      {@required this.list,
      @required this.tap,
      @required this.title,
      @required this.description,
      this.refresh});

  @override
  Widget build(BuildContext ctx) {
    final _controller = ScrollController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(ctx).textTheme.headline3,
          textAlign: TextAlign.left,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: Text(
                  description,
                  textAlign: TextAlign.left,
                ),
                padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 5.0),
              ),
            ),
            if (refresh != null)
              TextButton(
                  child: Text("Refresh List"),
                  onPressed: () {
                    refresh();
                  }),
          ],
        ),
        Expanded(
          child: Scrollbar(
            isAlwaysShown: true,
            controller: _controller,
            showTrackOnHover: true,
            child: ListView(
              scrollDirection: Axis.vertical,
              controller: _controller,
              children: <Widget>[
                for (var pro in list)
                  GestureDetector(
                    onTap: () {
                      if (tap != null) tap(pro);
                    },
                    child: Card(
                      child: game.Profile(pro.profile, false, {}),
                      elevation: 1.0,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
