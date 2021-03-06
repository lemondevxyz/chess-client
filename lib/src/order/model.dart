import "package:chess_client/src/board/board.dart";
import "package:chess_client/src/board/generator.dart";
import 'package:chess_client/src/board/piece.dart';

class Credentials {
  final String token;
  final String publicId;

  const Credentials(this.token, this.publicId);

  Credentials.fromJson(Map<String, dynamic> json)
      : token = json["token"],
        publicId = json["public_id"];

  Map<String, String> toJson() => {
        "token": token,
        "public_id": publicId,
      };
}

class Game {
  final Board board;
  final int player;

  const Game(this.board, this.player);

  Game.fromJson(Map<String, dynamic> json)
      : board = Board.fromJson(json["board"]),
        player = json["player"];

  Map<String, dynamic> toJson() => {
        "board": board.toJson(),
        "player": player,
      };
}

class Invite {
  // it's a variable cause it's easier to test
  static var expiry = Duration(seconds: 30);
  final String id;
  // as a command, the server doesn't use this field.

  const Invite(this.id);

  Invite.fromJson(Map<String, dynamic> json) : id = json["id"];

  Map<String, String> toJson() => {"id": id};
}

class Move {
  final Point src;
  final Point dst;

  const Move(this.src, this.dst);

  Move.fromJson(Map<String, dynamic> json)
      : src = json["src"],
        dst = json["dst"];

  Map<String, dynamic> toJson() => {
        "src": src.toJson(),
        "dst": dst.toJson(),
      };
}

class Turn {
  final int player;

  const Turn(this.player);

  Turn.fromJson(Map<String, dynamic> json) : player = json["player"];

  Map<String, int> toJson() => {
        "player": player,
      };
}

class Promotion {
  final Type type;
  final Point dst;

  const Promotion(this.type, this.dst);

  Promotion.fromJson(Map<String, dynamic> json)
      : type = Type.values[json["type"] as int],
        dst = Point.fromJSON(json["dst"]);

  Map<String, dynamic> toJson() => {
        "type": type.index,
        "dst": dst,
      };
}

class Promote {
  final Type type;
  final Point src;

  const Promote(this.type, this.src);

  Promote.fromJson(Map<String, dynamic> json)
      : type = Type.values[json["type"] as int],
        src = json["src"] as Point;

  Map<String, dynamic> toJson() => {
        "type": type.index,
        "src": src,
      };
}

// TODO: implement this
class Pause {}

class Message {
  final String message;

  const Message(this.message);

  Message.fromJson(Map<String, dynamic> json) : message = json["message"];

  Map<String, String> toJson() => {
        "message": message,
      };
}

class Done {
  final int result;

  bool get lost => result == -1;
  bool get draw => result == 0;
  bool get stalemate => draw;
  bool get won => result == 1;

  const Done(this.result);

  Done.fromJson(Map<String, dynamic> json) : result = json["result"];

  Map<String, int> toJson() => {
        "result": result,
      };
}
