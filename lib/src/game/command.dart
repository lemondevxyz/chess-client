import "dart:convert";
import "package:chess_client/src/board/generator.dart";

enum CmdID {
  None,
  Piece,
  Promotion,
  PauseGame,
  Message,
}

// here command models are defined.
// CmdPiece is used whenever you wanna move a piece.
class CmdPiece {
  final Point src;
  final Point dst;

  const CmdPiece(this.src, this.dst);

  CmdPiece.fromJson(Map<String, dynamic> json)
      : src = jsonDecode(json["src"]),
        dst = jsonDecode(json["dst"]);

  Map<String, dynamic> toJson() => {
        "src": jsonEncode(src),
        "dst": jsonEncode(dst),
      };
}

// CmdPromotion is only used whenever a pawn reaches the end of the board.
class CmdPromotion {
  final Point src;
  final Type type;

  const CmdPromotion(this.src, this.type);

  CmdPromotion.fromJson(Map<String, dynamic> json)
      : src = jsonDecode(json["src"]),
        type = jsonDecode(json["type"]);

  Map<String, dynamic> toJson() => {
        "src": jsonEncode(src),
        "type": jsonEncode(type),
      };
}

// CmdMessage is used to send a message to the other player.
class CmdMessage {
  final String msg;

  const CmdMessage(this.msg);

  CmdMessage.fromJson(Map<String, dynamic> json)
      : msg = jsonDecode(json["message"]);

  Map<String, dynamic> toJson() => {
        "message": jsonEncode(msg),
      };
}
