import "dart:convert";
import "package:chess_client/src/board/generator.dart";
import "package:chess_client/src/board/board.dart";
import 'package:event/event.dart';

enum UpdateID {
  None,
  Board,
  Promotion,
  Pause,
  Message,
  Turn,
  Invite,
}

class Update extends EventArgs {
  final dynamic json;
  UpdateID id;
  Object obj;

  Update(this.id, this.json) {
    switch (this.id) {
      case UpdateID.Board:
        this.obj = UpdateBoard.fromJson(this.json);
        break;
      case UpdateID.Promotion:
        this.obj = UpdatePromotion.fromJson(this.json);
        break;
      case UpdateID.Pause:
        // TODO: implement...
        break;
      case UpdateID.Message:
        this.obj = UpdateMessage.fromJson(this.json);
        break;
      case UpdateID.Turn:
        this.obj = UpdateTurn.fromJson(this.json);
        break;
      case UpdateID.Invite:
        this.obj = UpdateInvite.fromJson(this.json);
        break;
    }
  }

  factory Update.fromJson(Map<String, dynamic> json) {
    return Update(json["id"], json["data"]);
  }
}

// here update models are defined.
// sent to update the board on the client.
class UpdateBoard {
  final Board board;

  const UpdateBoard(this.board);
  UpdateBoard.fromJson(List<dynamic> json) : board = Board.fromJson(json);

  String toJson() => jsonEncode(this.board);
}

// whenever a pawn reaches the end [X: 0, Y: 7]
class UpdatePromotion {
  final int player;
  final Point dst;

  const UpdatePromotion(this.player, this.dst);

  UpdatePromotion.fromJson(Map<String, dynamic> json)
      : player = json["player"],
        dst = json["dst"];

  Map<String, dynamic> toJson() => {
        "player": player,
        "dst": dst,
      };
}

// sent whenever a message is sent.
class UpdateMessage {
  final String message;

  const UpdateMessage(this.message);

  UpdateMessage.fromJson(Map<String, dynamic> json) : message = json["message"];

  Map<String, dynamic> toJson() => {
        "message": message,
      };
}

// sent whenever a player moves a piece.
class UpdateTurn {
  final int player;

  const UpdateTurn(this.player);

  UpdateTurn.fromJson(Map<String, dynamic> json) : player = json["player"];

  Map<String, dynamic> toJson() => {
        "player": player,
      };
}

// sent whenever a player recieves an invite
class UpdateInvite {
  final String id;

  const UpdateInvite(this.id);

  UpdateInvite.fromJson(Map<String, dynamic> json) : id = json["id"];

  Map<String, dynamic> toJson() => {
        "id": id,
      };
}
