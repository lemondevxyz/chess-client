import 'package:chess_client/src/order/model.dart';
import 'package:flutter/material.dart';
import 'global.dart' as global;
import 'package:chess_client/src/widget/game.dart' as route;
import 'package:chess_client/src/widget/hub.dart' as route;

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
          MaterialPageRoute(builder: (BuildContext ctx) => route.HubRoute()),
          (_) => false);
  }

  void goToGame() {
    if (_navigator != null && _navigator.currentState != null)
      _navigator.currentState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext ctx) => route.GameRoute()),
          (_) => false);
  }

  void goToOffline() {
    if (_navigator != null && _navigator.currentState != null)
      _navigator.currentState.pushAndRemoveUntil(
          MaterialPageRoute(builder: (BuildContext ctx) => OfflineRoute()),
          (_) => false);
  }

  @override
  initState() {
    if (global.debug == global.Debugging.none) {
      global.server.connect();
    }

    try {
      global.server.onConnect.unsubscribe(onConnect);
      global.server.onDisconnect.unsubscribe(onDisconnect);
      global.server.onGame.unsubscribe(onGame);
      global.server.onDone.unsubscribe(onDone);
    } catch (e) {}

    global.server.onConnect.subscribe(onConnect);
    global.server.onDisconnect.subscribe(onDisconnect);
    global.server.onGame.subscribe(onGame);
    global.server.onDone.subscribe(onDone);

    super.initState();
  }

  void onConnect(_) => goToHub();
  void onDisconnect(_) => goToOffline();
  void onGame(_) => goToGame();

  void onDone(Done d) {
    print("dialog ondone");

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

    switch (global.debug) {
      case global.Debugging.none:
        {
          //onDisconnect(null);

          global.server.onDone.subscribe((Done d) {});

          break;
        }
      case global.Debugging.game:
        break;
    }

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
            global.server.connect();
          },
        ),
      ),
    );
  }
}
