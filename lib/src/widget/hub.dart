import 'dart:async';

import 'package:chess_client/src/board/board.dart' as board;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/hub/invite.dart' as hub;
import 'package:chess_client/src/widget/hub/watchable.dart' as hub;
import 'package:chess_client/icons.dart' as icons;
import 'package:flutter/material.dart';

const notificationDuration = Duration(seconds: 3);

class HubRoute extends StatefulWidget {
  static const String title = "Hub";
  final rest.HubService service;
  final bool testing;

  const HubRoute(this.service, {this.testing = false});

  @override
  _HubRouteState createState() => _HubRouteState();
}

class _HubRouteState extends State<HubRoute> {
  onInvite(dynamic d) {
    if (mounted) if (widget.service.invites.length > 0) {
      setState(() {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Received new invite"),
            duration: notificationDuration));
      });
    }
  }

  // variables that are used for testing
  final watchables = <String, model.Watchable>{};
  final invites = <order.Invite>[];

  final available = <order.Invite>[];

  void addUsersTimer(Timer t) {
    if (mounted || invites.length < 10)
      setState(() {
        invites.add(order.Invite(
          model.Profile("id", "picture", "username", "platform"),
        ));
      });
  }

  @override
  initState() {
    if (!widget.testing)
      widget.service.subscribe(order.OrderID.Invite, onInvite);
    else
      Timer.periodic(Duration(seconds: 1), addUsersTimer);

    super.initState();
  }

  @override
  dispose() {
    if (!widget.testing) widget.service.unsubscribe(order.OrderID.Invite);

    widget.service.watchables.clear();
    super.dispose();
  }

  void profileToInvite(List<model.Profile> list) {
    if (!widget.testing) {
      setState(() {
        available.clear();
        list.forEach((model.Profile pro) {
          available.add(
            order.Invite(pro),
          );
        });
      });
    }
  }

  Future<void> refreshUsers() {
    if (!widget.testing)
      widget.service.getAvaliableUsers().then((List<model.Profile> list) {
        profileToInvite(list);
      });
    else {
      setState(() {
        available.add(order.Invite(
          model.Profile("id", "picture", "username", "platform"),
        ));
      });
    }

    return Future.value(null);
  }

  static const int md = 1024;
  static const int sm = 768;

  @override
  Widget build(BuildContext context) {
    if (!widget.testing) {
      widget.service.getAvaliableUsers().then((List<model.Profile> list) {});
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(HubRoute.title),
        automaticallyImplyLeading: true,
      ),
      body: LayoutBuilder(
        builder: (BuildContext ctx, BoxConstraints cst) {
          final dir = (cst.maxWidth <= md || cst.maxHeight <= 768)
              ? Axis.vertical
              : Axis.horizontal;

          final rev = dir == Axis.vertical ? Axis.horizontal : Axis.vertical;

          final inv = hub.Invite(
            list: widget.testing ? invites : widget.service.invites,
            tap: widget.testing ? null : widget.service.acceptInvite,
            title: "Join a game",
            description: "Accept an invite to join a game",
          );
          final acpt = hub.Invite(
            list: available,
            tap: (order.Invite inv) {
              widget.service.invite(inv.profile);

              return Future.value(null);
            },
            title: "Invite",
            description:
                "Invite an available user to play with, invites expire after 30 seconds.",
            refresh: refreshUsers,
          );

          bool increaseHeight = false;

          Axis invaxis = cst.maxWidth >= md ? rev : Axis.vertical;
          if (cst.maxHeight < sm) {
            invaxis = Axis.vertical;
            increaseHeight = true;
          }

          final _controller = ScrollController();
          final watchable = !widget.testing
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
                );

          return Scrollbar(
            isAlwaysShown: increaseHeight,
            showTrackOnHover: true,
            controller: _controller,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              controller: _controller,
              child: Container(
                width: cst.maxWidth,
                height: cst.maxHeight *
                    (rev == Axis.horizontal && increaseHeight ? 2 : 1),
                padding: EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 20,
                ),
                child: Flex(
                  direction: dir,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        child: Flex(
                          direction: invaxis,
                          children: <Widget>[
                            Expanded(
                              child: acpt,
                            ),
                            if (invaxis == Axis.horizontal)
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 15.0),
                                color: Theme.of(ctx).dividerColor,
                                width: 1,
                              ),
                            Expanded(
                              child: inv,
                            ),
                          ],
                        ),
                      ),
                      flex:
                          (invaxis == Axis.vertical && increaseHeight) ? 6 : 3,
                    ),
                    Expanded(
                      child: Container(
                          child: watchable,
                          margin: invaxis == Axis.vertical && !increaseHeight
                              ? EdgeInsets.only(left: 15.0)
                              : EdgeInsets.all(0)),
                      flex: 6,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
