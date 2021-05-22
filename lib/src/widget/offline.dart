import 'dart:async';

import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';
import 'package:chess_client/icons.dart' as icons;
import 'package:url_launcher/url_launcher.dart' as launcher;

class _OfflineButton extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color bgclr;
  final Color fgclr;
  final String url;

  static const size = 20.0;

  const _OfflineButton(
      {@required this.icon,
      @required this.name,
      this.bgclr,
      @required this.fgclr,
      @required this.url});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: EdgeInsets.only(bottom: 10.0),
        child: TextButton(
          style: bgclr != null
              ? ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(bgclr),
                  padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                    vertical: size,
                  )))
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Icon(icon, color: fgclr, size: size * 2),
              Text("Login via $name",
                  style: TextStyle(color: fgclr, fontSize: size)),
            ],
          ),
          onPressed: () => launcher.launch(url),
        ),
      );
}

class OfflineRoute extends StatelessWidget {
  final rest.WebsocketService service;
  final bool testing;
  final GlobalKey<NavigatorState> navigator;

  const OfflineRoute(this.service,
      {this.testing = false, @required this.navigator});

  void authorizationDialog() {
    final show = () {
      showDialog(
          context: navigator.currentContext,
          builder: (BuildContext ctx) {
            final _ctrl = ScrollController();
            final platformAmount = testing ? 3 : service.platforms.length;

            return AlertDialog(
              title: const Text("Login"),
              content: Container(
                width: 325,
                height: 70 + (80 * platformAmount).toDouble(),
                child: Column(
                  children: <Widget>[
                    const Text(
                        "In-order to connect, you have to login via one of the following platforms..."),
                    if (service.platforms.length > 0 || testing)
                      Container(
                        height: 20,
                        width: 1,
                      ),
                    Expanded(
                      child: Scrollbar(
                        isAlwaysShown: true,
                        controller: _ctrl,
                        child: ListView(
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          controller: _ctrl,
                          children: <Widget>[
                            if (testing ||
                                service.platforms.contains("discord"))
                              _OfflineButton(
                                icon: icons.discord,
                                name: "Discord",
                                fgclr: Colors.white,
                                bgclr: const Color(0xFF7289da),
                                url: service.conf.http("discord/redirect"),
                              ),
                            if (testing || service.platforms.contains("google"))
                              _OfflineButton(
                                icon: icons.google,
                                name: "Google",
                                fgclr: Colors.white,
                                bgclr: const Color(0xFF4285f4),
                                url: service.conf.http("google/redirect"),
                              ),
                            if (testing || service.platforms.contains("github"))
                              _OfflineButton(
                                icon: icons.github,
                                name: "Github",
                                fgclr: Colors.white,
                                bgclr: const Color(0xFF4078c0),
                                url: service.conf.http("github/redirect"),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
    };

    if (!testing) {
      service.refreshPlatforms().whenComplete(() {
        show();
      });
    } else {
      show();
    }
  }

  void offlineDialog() {
    final context = navigator.currentContext;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("No internet connection or servers are down!"),
        duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    Widget layout;
    if (testing)
      layout = Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextButton(
            child: const Text("show authorization dialog"),
            onPressed: () => authorizationDialog(),
          ),
          TextButton(
            child: const Text("show offline dialog"),
            onPressed: () => offlineDialog(),
          ),
        ],
      );
    else
      layout = TextButton(
        child: const Text("Connect"),
        onPressed: () {
          service.connect().catchError((e) {
            print("$e");

            if (e == "offline")
              offlineDialog();
            else if (e == "unauthorized") // do dialog to authorize first
              authorizationDialog();
          });
        },
      );

    return Scaffold(
      appBar: AppBar(
        title: Text("Offline"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: layout,
      ),
    );
  }
}
