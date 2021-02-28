enum CommandID {
  None,
  Piece,
  Promotion,
  PauseGame,
  Message,
}

class Command {
  final CommandID id;
  final String data;

  const Command(this.id, this.data);

  Command.fromJSON(Map<String, dynamic> json)
      : id = json["id"],
        data = json["data"];

  Map<String, dynamic> toJson() => {
        "id": id,
        "data": data,
      };
}
