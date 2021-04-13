import "package:chess_client/src/board/board.dart";
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
  final bool p1;

  const Game(this.board, this.p1);

  Game.fromJson(Map<String, dynamic> json)
      : board = Board.fromJson(json["board"]),
        p1 = json["p1"];
}

class Invite {
  // it's a variable cause it's easier to test
  static const expiry = Duration(seconds: 30);
  final String id;
  // as a command, the server doesn't use this field.

  const Invite(this.id);

  Invite.fromJson(Map<String, dynamic> json) : id = json["id"];

  Map<String, String> toJson() => {"id": id};
}

class Move {
  final int id;
  final Point dst;

  const Move(this.id, this.dst);

  Move.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        dst = Point.fromJson(json["dst"] as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        "id": id,
        "dst": dst.toJson(),
      };
}

class Possible {
  final int id;
  final List<Map<String, dynamic>> points;

  Possible(this.id, this.points);

  Possible.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        points = json["points"];

  Map<String, dynamic> toJson() => {
        if (id != null) "id": id,
        if (points != null) "points": points,
      };
}

class Turn {
  final bool p1;
  const Turn(this.p1);

  Turn.fromJson(Map<String, dynamic> json) : p1 = json["p1"];
}

class Promotion {
  final int id;
  final int kind;

  const Promotion(this.id, this.kind);

  Promotion.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        kind = json["kind"];

  Map<String, dynamic> toJson() => {
        "id": id,
        "kind": kind,
      };
}

class Promote {
  final int type;
  final int id;

  Promote(this.id, this.type);

  Promote.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        type = json["type"] as int;

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
      };
}

class Castling {
  final int src;
  final int dst;

  const Castling(this.src, this.dst);

  Castling.fromJson(Map<String, dynamic> json)
      : src = json["src"],
        dst = json["dst"];

  Map<String, dynamic> toJson() => {
        "src": src,
        "dst": dst,
      };
}

class Done {
  final bool p1;

  Done(this.p1);

  Done.fromJson(Map<String, dynamic> json) : p1 = json["p1"];

  Map<String, dynamic> toJson() => {
        "p1": p1,
      };
}
