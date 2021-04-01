// other dependecies
import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import 'package:chess_client/src/rest/interface.dart' as rest;
// Our widgets
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/controls.dart' as game;
import 'package:chess_client/src/widget/game/promotion.dart' as game;
// flutter
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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

  onPromote(dynamic parameter) {
    if (!(parameter is Promote)) {
      print("promote has bad struct");
      return;
    }

    final p = parameter as Promote;

    setState(() {
      _promote = p.src;
    });
  }

  onDone(dynamic parameter) {
    widget.service.board.removeListener(onTurn);
    brd = widget.service.board.duplicate();
    _isFinished = true;

    brd.addListener(onTurn);
    brd.history.forEach((i) {
      print("${i.src} ${i.dst}");
    });

    setState(() {
      redrawObject = Object();
    });

    if (!(parameter is Done)) throw "bad parameter for done";
    final d = parameter as Done;

    String text;
    if (d.isWon) {
      text = "You won";
    } else if (d.isLost) {
      text = "You lost";
    } else if (d.isStalemate) {
      text = "Draw";
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
    _board().removeListener(onTurn);

    super.dispose();
  }

  @override
  initState() {
    if (!widget.testing) {
      _reverse = (widget.service.player == 1 ? false : true);

      widget.service.unsubscribe(OrderID.Promote);
      widget.service.subscribe(OrderID.Promote, onPromote);
      widget.service.unsubscribe(OrderID.Done);
      widget.service.subscribe(OrderID.Done, onDone);
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
        automaticallyImplyLeading: false,
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
                _isFinished ? true : _yourTurn(),
              ),
            ),
            Stack(
              children: <Widget>[
                game.BoardWidget(
                  _board(),
                  _move(),
                  _yourTurn,
                  _canFocus(),
                  reverse: _reverse,
                  possib: !widget.testing ? widget.service.possib : null,
                  key: ValueKey<Object>(redrawObject),
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
