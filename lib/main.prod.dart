import 'package:chess_client/src/rest/conf.dart';
import 'package:chess_client/src/rest/server.dart' as rest;

import 'main.dart' as mane;

void main() {
  mane.server = rest.Server(
      ServerConf(true, "chess.lemondev.xyz", Duration(seconds: 30)));
  mane.main();
}
