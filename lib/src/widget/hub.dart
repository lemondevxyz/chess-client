import 'package:chess_client/src/order/order.dart';
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

const notificationDuration = Duration(seconds: 3);

class HubRoute extends StatefulWidget {
  final String title = "Hub";
  final rest.HubService service;

  const HubRoute(this.service);

  @override
  _HubRouteState createState() => _HubRouteState();
}

class _HubRouteState extends State<HubRoute> {
  onInvite(dynamic) {
    if (widget.service.invites.length > 0) {
      setState(() {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Received new invite"),
            duration: notificationDuration));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.service.unsubscribe(OrderID.Invite);
    widget.service.subscribe(OrderID.Invite, onInvite);

    handleClick(String name) {
      switch (name) {
        case "Invite":
          {
            widget.service.getAvaliableUsers().then((List<String> l) {
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
                                  widget.service.invite(str);
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
          widget.service.disconnect();
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
            for (var i in widget.service.invites)
              ListTile(
                title: Text("${i.id}"),
                onTap: () {
                  widget.service.acceptInvite(i.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}
