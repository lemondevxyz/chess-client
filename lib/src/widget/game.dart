import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import 'package:chess_client/src/rest/interface.dart';
// Our widgets
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:chess_client/src/widget/game/promotion.dart' as game;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'global.dart' as global;

abstract class _GameService
    implements WebsocketService, SubscribeService, BoardService {}

class GameRoute extends StatefulWidget {
  final title = "Game";
  final bool testing;
  final _GameService service;

  const GameRoute(this.testing, this.service);

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  Board brd = Board();
  bool _reverse = false;
  bool _isFinished = true;
  Point _promote;
  Object redrawObject;

  onPromote(Promote pro) {
    setState(() {
      _promote = pro.src;
    });
  }

  onDone(_) {
    brd = widget.service.board.duplicate();
    _isFinished = true;

    setState(() {
      redrawObject = Object();
    });
  }

  @override
  dispose() {
    super.dispose();

    if (widget.service.isSubscribed(OrderID.Promote))
      widget.service.unsubscribe(OrderID.Promote);
    if (widget.service.isSubscribed(OrderID.Done))
      widget.service.unsubscribe(OrderID.Done);
  }

  @override
  initState() {
    super.initState();
    if (!widget.testing) {
      _reverse = (widget.service.player == 1 ? false : true);

      widget.service.subscribe(OrderID.Promote, onPromote);
      widget.service.subscribe(OrderID.Done, onDone);
    }

    _board().addListener(() {
      setState(() {});
    });
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
      return widget.service.player == widget.service.playerTurn;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text("Your Turn: ${_yourTurn() ? 'yes' : 'no'}"),
            TextButton(
              child: Text("reverse"),
              onPressed: () {
                setState(() {
                  _reverse = !_reverse;
                });
              },
            ),
            if (widget.testing)
              TextButton(
                child: Text("reset board"),
                onPressed: (() {
                  setState(() {
                    brd = Board();
                  });
                }),
              ),
            Expanded(
              child: Stack(
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
            ),
          ],
        ),
      ),
    );
  }
}
