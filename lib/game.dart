import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
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
  _GameState() {
    if (global.debug == global.Debugging.game) {
      moved.subscribe((_) {
        print("new move");
        setState(() {});
        print("should redraw");
      });
    }
  }

  Board _board() {
    if (global.debug == global.Debugging.game) {
      return widget.brd;
    } else {
      return global.server.board;
    }
  }

  bool _yourTurn() {
    if (global.debug == global.Debugging.game) {
      return true;
    } else {
      return global.server.player == global.server.playerTurn;
    }
  }

  Future<void> Function(Point, Point) _move() {
    if (global.debug == global.Debugging.game) {
      return (Point src, Point dst) {
        if (!src.valid() || !dst.valid()) {
          return Future.error("invalid dst or src");
        }

        widget.brd.move(widget.brd.get(src), dst);
        print("moved $src to $dst");
        moved.broadcast();
        print("event broadcast");

        return Future.value();
      };
    } else {
      return global.server.move;
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
            BoardWidget(_board(), _move(), _yourTurn),
          ],
        ),
      ),
    );
  }
}
