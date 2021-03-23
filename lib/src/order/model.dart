import "package:chess_client/src/board/board.dart";
import "package:chess_client/src/board/generator.dart";
import 'package:chess_client/src/board/piece.dart';
import 'package:event/event.dart';

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
      : src = Point.fromJson(json["src"] as Map<String, dynamic>),
        dst = Point.fromJson(json["dst"] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        "src": src.toJson(),
        "dst": dst.toJson(),
      };
}

class Possible {
  final Point src;
  final List<Map<String, dynamic>> points;

  Possible(this.src, this.points);

  Possible.fromJson(Map<String, dynamic> json)
      : points = json["points"],
        src = Point.fromJson(json["src"]);

  Map<String, dynamic> toJson() => {
        if (points != null) "points": points,
        if (src != null) "src": src,
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
  final int type;
  final Point dst;

  const Promotion(this.type, this.dst);

  Promotion.fromJson(Map<String, dynamic> json)
      : type = json["type"] as int,
        dst = Point.fromJson(json["dst"]);

  Map<String, dynamic> toJson() => {
        "type": type,
        "dst": dst,
      };
}

class Promote extends EventArgs {
  final int type;
  final Point src;

  Promote(this.type, this.src);

  Promote.fromJson(Map<String, dynamic> json)
      : type = json["type"] as int,
        src = Point.fromJson(json["src"]);

  Map<String, dynamic> toJson() => {
        "type": type,
        "src": src,
      };
}

// Castling is the same as move, so it's useless to re-define the class
// [O]
/*
class Castling extends Move {
  Castling(Point src, Point dst) : super(src, dst);
}
*/

class Message {
  final String message;

  const Message(this.message);

  Message.fromJson(Map<String, dynamic> json) : message = json["message"];

  Map<String, String> toJson() => {
        "message": message,
      };
}

class Done extends EventArgs {
  final int result;

  bool get isLost => result == -1;
  //bool get isDraw => result == 0;
  bool get isStalemate => result == 0;
  bool get isWon => result == 1;

  Done(this.result);

  Done.fromJson(Map<String, dynamic> json) : result = json["result"];

  Map<String, int> toJson() => {
        "result": result,
      };
}
