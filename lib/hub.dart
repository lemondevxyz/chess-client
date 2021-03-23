import 'package:flutter/material.dart';
import 'global.dart' as global;

const notificationDuration = Duration(seconds: 3);

class HubRoute extends StatefulWidget {
  final String title = "Hub";

  @override
  _HubRouteState createState() => _HubRouteState();
}

class _HubRouteState extends State<HubRoute> {
  @override
  Widget build(BuildContext context) {
    global.server.onInvite.subscribe((_) {
      if (global.server.invites.length > 0) {
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
            global.server.getAvaliableUsers().then((List<String> l) {
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
                                  global.server.invite(str);
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
          global.server.disconnect();
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
            for (var i in global.server.invites)
              ListTile(
                title: Text("${i.id}"),
                onTap: () {
                  global.server.acceptInvite(i.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}
