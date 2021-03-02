import "package:chess_client/src/board/generator.dart";

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

class Invite {
  final String id;

  const Invite(this.id);

  Invite.fromJson(Map<String, dynamic> json) : id = json["id"];

  Map<String, String> toJson() => {"id": id};
}

class Move {
  final Point src;
  final Point dst;

  const Move(this.src, this.dst);

  Move.fromJson(Map<String, Point> json)
      : src = json["src"],
        dst = json["dst"];

  Map<String, Point> toJson() => {
        "src": src,
        "dst": dst,
      };
}

class Turn {
  final int player;

  const Turn(this.player);

  Turn.fromJson(Map<String, int> json) : player = json["player"];

  Map<String, int> toJson() => {
        "player": player,
      };
}

class Promotion {
  final int player;
  final Point dst;

  const Promotion(this.player, this.dst);

  Promotion.fromJson(Map<String, dynamic> json)
      : player = json["player"] as int,
        dst = json["dst"] as Point;

  Map<String, dynamic> toJson() => {
        "player": player,
        "dst": dst,
      };
}

class Promote {
  final Type type;
  final Point src;

  const Promote(this.type, this.src);

  Promote.fromJson(Map<String, dynamic> json)
      : type = json["type"] as Type,
        src = json["src"] as Point;

  Map<String, dynamic> toJson() => {
        "type": type,
        "src": src,
      };
}

// TODO: implement this
class Pause {}

class Message {
  final String message;

  const Message(this.message);

  Message.fromJson(Map<String, String> json) : message = json["message"];

  Map<String, String> toJson() => {
        "message": message,
      };
}
