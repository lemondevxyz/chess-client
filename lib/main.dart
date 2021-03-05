import 'package:chess_client/game.dart';
import 'package:chess_client/hub.dart';
import 'package:chess_client/src/rest/server.dart';
import 'package:flutter/material.dart';

const notificationDuration = Duration(seconds: 3);

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  final s = Server(defaultServConf);

  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

    s.onConnect.subscribe((_) {
      _navigator.currentState.pushNamed("hub");
    });

    s.onDisconnect.subscribe((_) {
      _navigator.currentState.pushNamed("offline");
    });

    s.onGame.subscribe((_) {
      _navigator.currentState.pushNamed("game");
    });

    return MaterialApp(
      title: 'Chess',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.deepPurple, //  <-- dark color
            textTheme: ButtonTextTheme.primary,
          )),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case "offline":
            return MaterialPageRoute(builder: (context) => OfflineRoute(s));
          case "hub":
            return MaterialPageRoute(builder: (context) => HubRoute(s));
          case "game":
            return MaterialPageRoute(builder: (context) => GameRoute(s));
          default:
            return MaterialPageRoute(builder: (context) => Text("undefined"));
        }
      },
      initialRoute: "offline",
      navigatorKey: _navigator,
    );
  }
}

/*
class _AppState extends State<App> {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
    final s = widget.s;
    final m = MaterialApp(
      title: 'Chess',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.deepPurple, //  <-- dark color
            textTheme: ButtonTextTheme.primary,
          )),
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case "offline":
            return MaterialPageRoute(builder: (context) => OfflineRoute(s));
          case "hub":
            return MaterialPageRoute(builder: (context) => HubRoute(s));
          case "game":
            return MaterialPageRoute(builder: (context) => GameRoute(s));
          default:
            return MaterialPageRoute(builder: (context) => Text("undefined"));
        }
      },
      initialRoute: "offline",
      navigatorKey: _navigator,
    );

    s.onConnect.subscribe((_) {
      _navigator.currentState.pushNamed("hub");
    });

    s.onDisconnect.subscribe((_) {
      _navigator.currentState.pushNamed("offline");
    });

    s.onGame.subscribe((_) {
      _navigator.currentState.pushNamed("game");
    });

    return m;
  }
}
*/

class OfflineRoute extends StatelessWidget {
  final Server s;
  const OfflineRoute(this.s);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offline"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: TextButton(
          child: Text("Connect"),
          onPressed: () {
            s.connect();
          },
        ),
      ),
    );
  }
}
