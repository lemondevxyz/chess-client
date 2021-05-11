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
    double sz = MediaQuery.of(context).size.shortestSide / 1.5;
    sz = sz > 400 ? sz : 400;

    final _controller = ScrollController();

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                "Watchable",
                style: Theme.of(context).textTheme.headline3,
                textAlign: TextAlign.left,
              ),
              TextButton(
                child: Text("Refresh List"),
                onPressed: () {
                  //widget.set.clear();
                  widget.refresh().then((_) {
                    if (mounted) setState(() {});
                  });
                },
              ),
            ],
          ),
          Container(
            child: Text("Choose a game to spectate", textAlign: TextAlign.left),
          ),
          Expanded(
            child: SizedBox(
              height: sz,
              child: Scrollbar(
                isAlwaysShown: true,
                controller: _controller,
                showTrackOnHover: true,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  controller: _controller,
                  children: <Widget>[
                    for (var id in widget.set.keys)
                      Container(
                        //padding: EdgeInsets.only(right: 5.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Column(
                            children: <Widget>[
                              game.Profile(widget.set[id].p2, false,
                                  widget.set[id].brd.deadPieces(false)),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 1.0,
                                  child: Board(
                                    widget.set[id].brd,
                                    null,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ],
      ),
    );
  }
}
