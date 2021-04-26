import 'package:chess_client/src/board/board.dart';

class Profile {
  final String id;
  final String picture;
  final String username;
  final String platform;

  const Profile(this.id, this.picture, this.username, this.platform);

  Map<String, dynamic> toJson() => {
        "id": id,
        "picture": picture,
        "username": username,
        "platform": platform,
      };

  Profile.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        picture = json["picture"],
        username = json["username"],
        platform = json["platform"];
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
