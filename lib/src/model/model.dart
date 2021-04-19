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
