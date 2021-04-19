import 'dart:collection';

import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/model/order.dart' as order;

abstract class ServerService
    implements
        BoardService,
        InviteService,
        WebsocketService,
        SubscribeService,
        GameService,
        HubService {}

abstract class GameService
    implements WebsocketService, SubscribeService, BoardService {}

// widget/hub.dart
abstract class HubService
    implements InviteService, SubscribeService, WebsocketService {}

// this only implemented in the server
// TODO: implement this in normal board
abstract class BoardService {
  Board get board;
  bool get p1;
  bool get playerTurn;

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

abstract class InviteService {
  Future<List<String>> getAvaliableUsers();
  Future<void> acceptInvite(String id);
  Future<void> invite(String id);
  List<order.Invite> get invites;
}

abstract class SubscribeService {
  void subscribe(order.OrderID id, Function(dynamic) callback);
  void unsubscribe(order.OrderID id);
  bool isSubscribed(order.OrderID id);
}

abstract class WebsocketService {
  Future<void> connect();
  Future<void> disconnect();
  bool isConnected();
}
