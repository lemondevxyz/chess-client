import 'package:chess_client/src/board/board.dart';
import 'package:chess_client/src/board/generator.dart';
import 'package:chess_client/src/order/model.dart' as model;
import 'package:chess_client/src/order/order.dart';

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
  int get player;
  int get playerTurn;

  Future<List<Point>> possib(Point src);
  Future<void> move(Point src, Point dst);
  Future<void> promote(Point src, int type);

  bool ourTurn();
}

// this is meant for the Board
abstract class HistoryService {
  bool canGoPrev();
  bool canGoNext();
  void goPrev();
  void goNext();

  void resetHistory();
}

abstract class InviteService {
  Future<List<String>> getAvaliableUsers();
  Future<void> acceptInvite(String id);
  Future<void> invite(String id);
  List<model.Invite> get invites;
}

abstract class SubscribeService {
  void subscribe(OrderID id, Function(dynamic) callback);
  void unsubscribe(OrderID id);
  bool isSubscribed(OrderID id);
}

abstract class WebsocketService {
  Future<void> connect();
  Future<void> disconnect();
  bool isConnected();
}
