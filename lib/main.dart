import 'package:chess_client/src/model/order.dart' as order;
import 'package:flutter/material.dart';
import 'package:chess_client/src/widget/game.dart' as widget;
import 'package:chess_client/src/widget/hub.dart' as widget;
import 'package:chess_client/src/rest/server.dart' as rest;
import 'package:chess_client/src/rest/conf.dart' as rest;

class Debugging {
  static const none = 0;
  static const game = 1;
  static const boardwidget = 2;
}

rest.Server server = rest.Server(
    rest.ServerConf(false, "localhost", Duration(seconds: 0), port: 8080));
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
              builder: (BuildContext ctx) => widget.GameRoute(
                    server,
                    goToHub,
                    _navigator,
                    testing: debug == Debugging.game,
                  )),
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
      case Debugging.game:
        goToGame();
    }

    super.initState();
  }

  _AppState() {
    server.unsubscribe(order.OrderID.Credentials);
    server.unsubscribe(order.OrderID.Disconnect);
    server.unsubscribe(order.OrderID.Game);
    server.unsubscribe(order.OrderID.Done);

    server.subscribe(order.OrderID.Credentials, onConnect);
    server.subscribe(order.OrderID.Disconnect, onDisconnect);
    server.subscribe(order.OrderID.Game, onGame);
    server.subscribe(order.OrderID.Done, onDone);
  }

  void onConnect(_) => goToHub();
  void onDisconnect(_) => goToOffline();
  void onGame(_) => goToGame();

  void onDone(dynamic parameter) {}

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
      ),
      onGenerateRoute: (RouteSettings settings) {
        return MaterialPageRoute(builder: (BuildContext ctx) {
          switch (debug) {
            case Debugging.game:
              return widget.GameRoute(null, goToHub, _navigator,
                  testing: false);
          }

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
