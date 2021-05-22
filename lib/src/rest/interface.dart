import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/model/order.dart' as order;
import 'package:chess_client/src/model/model.dart' as model;
import 'package:chess_client/src/rest/conf.dart' as rest;

abstract class ServerService
    implements
        BoardService,
        InviteService,
        WebsocketService,
        SubscribeService,
        WatchableService,
        GameService,
        HubService {}

// widget/game.dart
abstract class GameService
    implements WebsocketService, SubscribeService, BoardService {}

// widget/hub.dart
abstract class HubService
    implements
        InviteService,
        WatchableService,
        SubscribeService,
        WebsocketService {}

// this only implemented in the server
// TODO: implement this in normal board
abstract class BoardService {
  Board get board;
  bool get p1;
  bool get playerTurn;

  model.GameProfile get profile;

  Future<HashMap<String, Point>> possib(int id);
  Future<void> move(int id, Point dst);
  Future<void> castling(int kingid, int rookid);
  Future<void> promote(int id, int type);
  Future<void> leaveGame();

  bool ourTurn();
}

// this is meant for the Board
abstract class HistoryService {
  bool canGoPrev();
  void goPrev();

  bool canGoNext();
  void goNext();

  bool canResetHistory();
  void resetHistory();
}

abstract class WatchableService {
  Future<void> refreshWatchable();
  HashMap<String, model.Watchable> get watchables;
  Future<void> joinWatchable(model.Generic m);
  Future<void> leaveWatchable();
}

abstract class InviteService {
  Future<List<model.Profile>> getAvaliableUsers();
  Future<void> acceptInvite(order.Invite inv);
  Future<void> invite(model.Profile pro);
  List<order.Invite> get invites;
}

abstract class SubscribeService {
  void subscribe(order.OrderID id, Function(dynamic) callback);
  void unsubscribe(order.OrderID id);
  bool isSubscribed(order.OrderID id);
}

abstract class WebsocketService {
  model.Profile get playerprofile;
  rest.ServerConf get conf;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> refreshPlatforms();

  List<String> get platforms;

  bool isConnected();
}
