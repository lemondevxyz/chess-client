import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/hub/watchable.dart' as hub;
import 'package:chess_client/icons.dart' as icons;
import 'package:flutter/material.dart';

const notificationDuration = Duration(seconds: 3);

class HubRoute extends StatefulWidget {
  final String title = "Hub";
  final rest.HubService service;
  final bool testing;

  const HubRoute(this.service, {this.testing = false});

  @override
  _HubRouteState createState() => _HubRouteState();
}

class _HubRouteState extends State<HubRoute> {
  onInvite(dynamic) {
    if (mounted) if (widget.service.invites.length > 0) {
      setState(() {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Received new invite"),
            duration: notificationDuration));
      });
    }
  }

  final watchables = <String, model.Watchable>{};

  @override
  dispose() {
    widget.service.watchables.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.testing) {
      widget.service.unsubscribe(order.OrderID.Invite);
      widget.service.subscribe(order.OrderID.Invite, onInvite);
    }

    handleClick(String name) {
      switch (name) {
        case "Invite":
          {
            widget.service.getAvaliableUsers().then((List<model.Profile> l) {
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
                            for (var profile in l)
                              Card(
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                      leading: CircleAvatar(
                                        foregroundImage:
                                            NetworkImage(profile.picture),
                                      ),
                                      title: Text(profile.username),
                                      subtitle: Text(
                                        profile.platform,
                                      ),
                                      onTap: () {
                                        widget.service.invite(profile);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  });
            }).catchError((e) {
              debugPrint("hub.getAvaliableUsers $e");
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
            icon: Icon(
              icons.more_vert,
            ),
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
      body: LayoutBuilder(builder: (_, BoxConstraints cst) {
        final dir =
            cst.maxWidth > cst.maxHeight ? Axis.vertical : Axis.horizontal;

        return ListView(
          scrollDirection: dir,
          children: <Widget>[
            /*
            Flex(
              direction:
                  dir == Axis.horizontal ? Axis.vertical : Axis.horizontal,
              children: <Widget>[
                Text("Avaliable Users"),
                Text("Invite"),
              ],
            ),
            */
            SizedBox(
              height: cst.maxHeight,
              width: cst.maxWidth,
              child: !widget.testing
                  ? hub.Watchable(
                      widget.service.refreshWatchable,
                      widget.service.watchables,
                      widget.service.joinWatchable,
                    )
                  : hub.Watchable(
                      () {
                        watchables[UniqueKey().toString()] = model.Watchable(
                          model.Profile(
                            "white",
                            "white",
                            "white",
                            "white",
                          ),
                          model.Profile(
                            "black",
                            "black",
                            "black",
                            "black",
                          ),
                          board.Board(),
                        );

                        return Future.value(null);
                      },
                      watchables,
                      (_) {},
                    ),
            ),
          ],
        );
      }),
    );
  }
}
