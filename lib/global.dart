import 'package:chess_client/src/rest/server.dart' as rest;

class Debugging {
  static const none = 0;
  static const game = 1;
}

final server = rest.Server(rest.defaultServConf);
const debug = Debugging.game;
