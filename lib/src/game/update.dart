import "dart:convert";
import "package:chess_client/src/board/generator.dart";

enum UpdateID {
  None,
  Board,
  Promotion,
  Pause,
  Message,
  Turn,
  Invite,
}

// here command models are defined.
class UpdateBoard {}

class CmdPromotion {
  final Point src;
  final Type type;

  const CmdPromotion(this.src, this.type);

  CmdPromotion.fromJSON(Map<String, dynamic> json)
      : src = jsonDecode(json["src"]),
        type = jsonDecode(json["type"]);

  Map<String, dynamic> toJson() => {
        "src": jsonEncode(src),
        "type": jsonEncode(type),
      };
}

class CmdMessage {
  final String msg;

  const CmdMessage(this.msg);

  CmdMessage.fromJSON(Map<String, dynamic> json)
      : msg = jsonDecode(json["message"]);

  Map<String, dynamic> toJson() => {
        "message": jsonEncode(msg),
      };
}
