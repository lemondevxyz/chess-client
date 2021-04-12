// Our widgets
import 'package:chess_client/src/widget/game/board.dart' as game;
// flutter
import 'package:flutter/material.dart';

/*
class GameRoute extends StatefulWidget {
  final title = "Game";
  final bool testing;
  final rest.GameService service;
  final Function() goToHub;
  final GlobalKey<NavigatorState> _navigator;

  const GameRoute(this.testing, this.service, this.goToHub, this._navigator);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  Board brd = Board();
  bool _reverse = false;
  bool _isFinished = false;
  Point _promote;
  Object redrawObject;
  int checkmate;
  int player;

  onCheckmate(dynamic parameter) {
    if (!(parameter is model.Turn)) {
      print("checkmate has bad struct");
      return;
    }

    final c = parameter as model.Turn;
    setState(() {
      checkmate = c.player;
    });
  }

  onPromote(dynamic parameter) {
    if (!(parameter is model.Promote)) {
      print("promote has bad struct");
      return;
    }

    final p = parameter as model.Promote;

    setState(() {
      _promote = p.src;
    });
  }

  onDone(dynamic parameter) {
    widget.service.board.removeListener(onTurn);
    brd = widget.service.board.duplicate();
    _isFinished = true;

    brd.addListener(onTurn);

    setState(() {
      redrawObject = Object();
    });

    if (!(parameter is model.Done)) throw "bad parameter for done";
    final d = parameter as model.Done;

    String text;
    if (d.result == widget.service.player) {
      text = "You won";
    } else if (d.result != 0) {
      text = "You lost";
    } else if (d.result == 0) {
      text = "Stalemate";
    }

    showDialog(
        context: widget._navigator.currentContext,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(text),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "The game ended. Would you like to stay or go back to the hub?"),
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
  dispose() {
    widget.service.unsubscribe(OrderID.Done);
    widget.service.unsubscribe(OrderID.Turn);
    widget.service.unsubscribe(OrderID.Promote);
    widget.service.unsubscribe(OrderID.Checkmate);

    _board().removeListener(onTurn);

    super.dispose();
  }

  @override
  initState() {
    if (!widget.testing) {
      _reverse = (widget.service.player == 1 ? false : true);

      widget.service.subscribe(OrderID.Promote, onPromote);
      widget.service.subscribe(OrderID.Done, onDone);
      widget.service.subscribe(OrderID.Checkmate, onCheckmate);
      widget.service.subscribe(OrderID.Turn, (_) {
        onTurn();
        checkmate = -1;
      });

      player = widget.service.player;
    }

    _board().removeListener(onTurn);
    _board().addListener(onTurn);

    super.initState();
  }

  Board _board() {
    if (widget.testing) {
      return brd;
    } else {
      if (!_isFinished) {
        return widget.service.board;
      } else {
        return brd;
      }
    }
  }

  bool _yourTurn() {
    if (widget.testing) {
      return true;
    } else {
      if (!_isFinished)
        return widget.service.player == widget.service.playerTurn;
      else // only meant for analysis, therefore board cannot be modified
        return false;
    }
  }

  Future<void> Function(Point, Point) _move() {
    if (widget.testing) {
      return (Point src, Point dst) {
        if (!src.valid() || !dst.valid()) {
          return Future.error("invalid dst or src");
        }

        _board().move(_board().get(src), dst);

        return Future.value();
      };
    } else {
      return widget.service.move;
    }
  }

  bool Function(Piece) _canFocus() {
    if (widget.testing) {
      return (_) {
        return true;
      };
    } else {
      return (Piece pce) {
        return pce.num == widget.service.player;
      };
    }
  }

  onTurn() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: !_isFinished,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Leave game",
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  final String txt = _isFinished
                      ? "Are you sure you want to leave? You'll lose the ability analyse this game!"
                      : "Are your sure you want to leave this game? You'll lose the game!";

                  return AlertDialog(
                    title: Text("Are you sure?"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(txt),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: Text("leave"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (!_isFinished) {
                            widget.service.unsubscribe(OrderID.Done);
                            widget.service.leaveGame();
                          }

                          widget.goToHub();
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
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: game.Controls(
                _board(),
                () {
                  setState(() {
                    _reverse = !_reverse;
                  });
                },
                widget.goToHub,
                _yourTurn(),
                _isFinished,
              ),
            ),
            Stack(
              children: <Widget>[
                game.BoardWidget(
                  _board(),
                  _move(),
                  _yourTurn,
                  playerNumber: player,
                  reverse: _reverse,
                  possib: !widget.testing ? widget.service.possib : null,
                  key: ValueKey<Object>(redrawObject),
                  isCheckmate: () {
                    if (widget.testing)
                      return false;
                    else
                      return widget.service.player == checkmate;
                  },
                ),
                if (_promote != null && !widget.testing)
                  game.Promotion(
                    widget.service.player,
                    (int type) {
                      widget.service.promote(this._promote, type).then((_) {
                        setState(() {
                          this._promote = null;
                        });
                      }).catchError(() {
                        print(
                            "trying to promote: point: $_promote - type: $type");
                      });
                    },
                  )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/

class GameRoute extends StatelessWidget {
  @override
  Widget build(BuildContext build) {
    return game.BoardWidget();
  }
}
