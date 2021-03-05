import 'package:chess_client/main.dart';
import 'package:chess_client/src/rest/server.dart';
import 'package:flutter/material.dart';

class HubRoute extends StatefulWidget {
  const HubRoute(this.s);
  final String title = "Hub";
  final Server s;

  @override
  _HubRouteState createState() => _HubRouteState();
}

class _HubRouteState extends State<HubRoute> {
  @override
  Widget build(BuildContext context) {
    final Server s = widget.s;

    s.onInvite.subscribe((_) {
      if (s.invites.length > 0) {
        setState(() {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Received new invite"),
              duration: notificationDuration));
        });
      }
    });

    handleClick(String name) {
      switch (name) {
        case "Invite":
          {
            s.getAvaliableUsers().then((List<String> l) {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Avaliable users"),
                      content: Container(
                        width: 300,
                        child: ListView(
                          shrinkWrap: true,
                          children: <Widget>[
                            for (var str in l)
                              ListTile(
                                title: Text("$str"),
                                onTap: () {
                                  s.invite(str);
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  });
            }).catchError((e) {
              debugPrint("adsd $e");
            });

            break;
          }
        case "Disconnect":
          s.disconnect();
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: handleClick,
            itemBuilder: (BuildContext context) {
              return {'Invite', 'Disconnect'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            for (var i in s.invites)
              ListTile(
                title: Text("${i.id}"),
                onTap: () {
                  s.acceptInvite(i.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}
