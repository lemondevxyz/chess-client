import 'package:chess_client/game.dart';
import 'package:chess_client/hub.dart';
import 'package:flutter/material.dart';
import 'global.dart' as global;

const notificationDuration = Duration(seconds: 3);

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  App() {
    if (global.debug == global.Debugging.none) {
      global.server.connect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

    String initialRoute = "offline";
    switch (global.debug) {
      case global.Debugging.none:
        {
          global.server.onConnect.subscribe((_) {
            if (_navigator != null) _navigator.currentState.pushNamed("hub");
          });

          global.server.onDisconnect.subscribe((_) {
            if (_navigator != null)
              _navigator.currentState.pushNamed("offline");
          });

          global.server.onGame.subscribe((_) {
            if (_navigator != null) _navigator.currentState.pushNamed("game");
          });

          break;
        }
      case global.Debugging.game:
        if (global.debug == global.Debugging.game) {
          initialRoute = "game";
        }
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
      /*
      routes: <String, WidgetBuilder>{
        "offline": ((context) => OfflineRoute()),
        "hub": ((context) => HubRoute()),
        "game": ((context) => GameRoute()),
      },
      initialRoute: initialRoute,
      navigatorKey: _navigator,
      */
      home: GameRoute(),
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
