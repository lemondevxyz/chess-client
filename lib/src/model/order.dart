import "package:chess_client/src/board/board.dart";
import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/model/model.dart';

// [U] refers to an Update, [C] refers to a Command.
// While [O] refers to an Update and a Command.
enum OrderID {
  Empty,
  Credentials, // [U]
  Invite, // [O]
  Watchable, // [U]
  Game, // [U]
  Move, // [O]
  Possible, // [O]
  Turn, // [U]
  Promote, // [C]
  Promotion, // [U]
  Castling, // [O]
  Checkmate, // [U]
  // Message, // Deprecated
  Done, // [O]
  Disconnect, // Not actually an order, but more so to inform other components that the connection has been closed
}

class Order {
  final OrderID id;
  final dynamic obj;

  Order(this.id, this.obj);

  Order.fromJson(Map<String, dynamic> json)
      : id = OrderID.values[json["id"] as int],
        obj = json["data"];

  Map<String, dynamic> toJson() {
    return {
      "id": id.index,
      "data": obj.toJson != null ? obj.toJson() : obj,
    };
  }
}

class Credentials {
  final String token;
  final Profile profile;

  const Credentials(this.token, this.profile);

  Credentials.fromJson(Map<String, dynamic> json)
      : token = json["token"],
        profile = Profile.fromJson(json["profile"]);
}

class Watchable {
  final Profile p1;
  final Profile p2;
  final Board board;

  const Watchable(this.p1, this.p2, this.board);

  Watchable.fromJson(Map<String, dynamic> json)
      : p1 = Profile.fromJson(json["p1"]),
        p2 = Profile.fromJson(json["p2"]),
        board = Board.fromJson(json["board"]);
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
  // optional parameters
  String platform;
  Profile profile;

  Invite(this.id);

  Invite.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        profile = Profile.fromJson(json["profile"]);

  Map<String, String> toJson() => {
        "id": id,
        "platform": platform,
      };
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
  final int kind;
  final int id;

  Promote(this.id, this.kind);

  Promote.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        kind = json["kind"] as int;

  Map<String, dynamic> toJson() => {
        "id": id,
        "kind": kind,
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
