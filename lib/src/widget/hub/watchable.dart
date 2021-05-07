import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/widget/game/board.dart';
import 'package:chess_client/src/widget/game/profile.dart' as game;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class Watchable extends StatefulWidget {
  final Future<void> Function() refresh;
  final Map<String, model.Watchable> set;
  final Future<void> Function(model.Generic m) spectate;

  const Watchable(this.refresh, this.set, this.spectate);

  @override
  createState() => _WatchableState();
}

class _WatchableState extends State<Watchable> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Watchable", style: Theme.of(context).textTheme.headline3),
              TextButton(
                child: Text("Refresh List"),
                onPressed: () {
                  widget.set.clear();
                  widget.refresh().then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          Container(
            child: Text(
              "Choose a game to spectate",
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(top: 25),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  for (String id in widget.set.keys)
                    Container(
                      width: 400,
                      height: 400,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: AspectRatio(
                        aspectRatio: 0.5,
                        child: Column(
                          children: <Widget>[
                            game.Profile(widget.set[id].p2, false,
                                widget.set[id].brd.deadPieces(false)),
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: Board(
                                widget.set[id].brd,
                                null,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  child: game.Profile(widget.set[id].p1, true,
                                      widget.set[id].brd.deadPieces(true)),
                                ),
                                TextButton(
                                    child: Text("Spectate"),
                                    onPressed: () {
                                      widget
                                          .spectate(model.Generic(id))
                                          .catchError((_) {
                                        widget.set.clear();
                                        widget.refresh().then((_) {
                                          if (mounted) setState(() {});
                                        });
                                      });
                                    }),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
