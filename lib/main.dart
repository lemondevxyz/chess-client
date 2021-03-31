import 'package:chess_client/src/order/model.dart';
import 'package:chess_client/src/order/order.dart';
import 'package:flutter/material.dart';
import 'package:chess_client/src/widget/game.dart' as widget;
import 'package:chess_client/src/widget/hub.dart' as widget;
import 'package:chess_client/src/rest/server.dart' as rest;

class Debugging {
  static const none = 0;
  static const game = 1;
}

final server = rest.Server(rest.defaultServConf);
const debug = Debugging.game;

void main() {
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  GlobalKey<NavigatorState> _navigator;

  void goToHub() {
    if (_navigator != null && _navigator.currentState != null)
      _navigator.currentState.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (BuildContext ctx) => widget.HubRoute(server)),
          (_) => false);
  }

  void goToGame() {
    if (_navigator != null && _navigator.currentState != null)
      _navigator.currentState.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (BuildContext ctx) =>
                  widget.GameRoute(debug == Debugging.game, server)),
          (_) => false);
  }

  void goToOffline() {
    if (_navigator != null && _navigator.currentState != null)
      _navigator.currentState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext ctx) => OfflineRoute()),
          (_) => false);
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  initState() {
    switch (debug) {
      case Debugging.none:
        server.connect();
        break;
    }

    super.initState();
  }

  _AppState() {
    server.unsubscribe(OrderID.Credentials);
    server.unsubscribe(OrderID.Disconnect);
    server.unsubscribe(OrderID.Game);
    server.unsubscribe(OrderID.Done);

    server.subscribe(OrderID.Credentials, onConnect);
    server.subscribe(OrderID.Disconnect, onDisconnect);
    server.subscribe(OrderID.Game, onGame);
    server.subscribe(OrderID.Done, onDone);
  }

  void onConnect(_) => goToHub();
  void onDisconnect(_) => goToOffline();
  void onGame(_) => goToGame();

  void onDone(dynamic parameter) {
    if (!(dynamic is Done)) throw "bad parameter for done";

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
        context: _navigator.currentContext,
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
                  if (_navigator != null) {
                    goToHub();
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
  Widget build(BuildContext context) {
    _navigator = GlobalKey<NavigatorState>();

    return MaterialApp(
      title: 'Chess',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        buttonTheme: ButtonThemeData(
          buttonColor: Colors.deepPurple, //  <-- dark color
          textTheme: ButtonTextTheme.primary,
        ),
        focusColor: Colors.deepPurple[200],
        fontFamily: "Dubai",
      ),
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (BuildContext ctx) {
          if (debug == Debugging.game) return widget.GameRoute(true, server);

          return OfflineRoute();
        });
      },
      navigatorKey: _navigator,
    );
  }
}

class OfflineRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //tryConnect();

    return Scaffold(
      appBar: AppBar(
        title: Text("Offline"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: TextButton(
          child: Text("Connect"),
          onPressed: () {
            server.connect();
          },
        ),
      ),
    );
  }
}
