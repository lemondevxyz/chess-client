import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/rest/server.dart';
import 'package:flutter/material.dart';

class GameRoute extends StatelessWidget {
  const GameRoute(this.s);

  final Server s;
  final String title = "Game";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          BoardWidget(s.board),
        ],
      ),
    );
  }
}
