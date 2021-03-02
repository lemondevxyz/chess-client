// this is basically command + update combined. since they share the same json fields.
class Order {
  final int id;
  final dynamic obj;

  const Order(this.id, this.obj);

  Order.fromJSON(Map<String, dynamic> json)
      : id = json["id"],
        obj = json["data"];

  Map<String, dynamic> toJson() => {
        "id": id,
        "data": obj,
      };
}
