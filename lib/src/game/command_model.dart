import "dart:convert";
import "package:chess_client/src/board/generator.dart";

// here models are defined.
class ModelCmdPiece {
  final Point src;
  final Point dst;

  const ModelCmdPiece(this.src, this.dst);

  ModelCmdPiece.fromJSON(Map<String, dynamic> json)
      : src = jsonDecode(json["src"]),
        dst = jsonDecode(json["dst"]);

  Map<String, dynamic> toJson() => {
        "src": jsonEncode(src),
        "dst": jsonEncode(dst),
      };
}

class ModelCmdPromotion {
  final Point src;
  final Type type;

  const ModelCmdPromotion(this.src, this.type);

  ModelCmdPromotion.fromJSON(Map<String, dynamic> json)
      : src = jsonDecode(json["src"]),
        type = jsonDecode(json["type"]);

  Map<String, dynamic> toJson() => {
        "src": jsonEncode(src),
        "type": jsonEncode(type),
      };
}

class ModelCmdMessage {
  final String msg;

  const ModelCmdMessage(this.msg);

  ModelCmdMessage.fromJSON(Map<String, dynamic> json)
      : msg = jsonDecode(json["message"]);

  Map<String, dynamic> toJson() => {
        "message": jsonEncode(msg),
      };
}
