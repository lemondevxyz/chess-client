import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'global.dart' as global;

class GameRoute extends StatefulWidget {
  final title = "Game";
  final brd = Board();

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  final Event moved = Event();
  final testing = global.debug == global.Debugging.game;

  bool _reverse = false;

  _GameState() {
    if (!testing) {
      _reverse = (global.server.player == 1 ? false : true);
    }

    _board().addListener(() {
      setState(() {});
    });
  }

  Board _board() {
    if (testing) {
      return widget.brd;
    } else {
      return global.server.board;
    }
  }

  bool _yourTurn() {
    if (testing) {
      return true;
    } else {
      return global.server.player == global.server.playerTurn;
    }
  }

  Future<void> Function(Point, Point) _move() {
    if (testing) {
      return (Point src, Point dst) {
        if (!src.valid() || !dst.valid()) {
          return Future.error("invalid dst or src");
        }

        widget.brd.move(widget.brd.get(src), dst);
        //moved.broadcast();

        return Future.value();
      };
    } else {
      return global.server.move;
    }
  }

  bool Function(Piece) _canFocus() {
    if (testing) {
      return (_) {
        return true;
      };
    } else {
      return (Piece pce) {
        return pce.num == global.server.player;
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
            BoardWidget(_board(), _move(), _yourTurn, _canFocus(),
                reverse: _reverse),
          ],
        ),
      ),
    );
  }
}
