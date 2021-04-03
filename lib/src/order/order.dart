// [U] refers to an Update, [C] refers to a Command.
// While [O] refers to an Update and a Command.
enum OrderID {
  Empty,
  Credentials, // [U]
  Invite, // [O]
  Game, // [U]
  Move, // [O]
  Possible, // [O]
  Turn, // [U]
  Promote, // [C]
  Promotion, // [U]
  Castling, // [O]
  Checkmate, // [U]
  Message, // [O]
  Done, // [U]
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
