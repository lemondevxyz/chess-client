import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/rest/server.dart';
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  final Server s;

  const GameRoute(this.s);
  final String title = "Game";

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<GameRoute> {
  Future<void> tryMove(Point src, Point dst) async {
    return widget.s.move(src, dst);
  }

  @override
  Widget build(BuildContext context) {
    widget.s.onTurn.subscribe((_) {
      setState(() {});
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
              "Your turn? : ${widget.s.player == widget.s.playerTurn ? 'YES' : 'NO'}"),
          BoardWidget(widget.s.board, widget.s.player, widget.s.move, () {
            if (widget.s.player == widget.s.playerTurn) {
              return true;
            }

            return false;
          }),
        ],
      ),
    );
  }
}
