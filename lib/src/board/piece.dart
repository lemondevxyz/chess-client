import 'package:chess_client/icons.dart' as icons;
import 'package:flutter/widgets.dart';

class Point {
  final int x, y;

  const Point(this.x, this.y);

  Point.fromJson(Map<String, dynamic> json)
      : x = json["x"],
        y = json["y"];

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
      };

  factory Point.fromIndex(int i) {
    final x = (i / 8).abs().toInt();
    final y = (i % 8).abs().toInt();

    return Point(x, y);
  }

  Point reverse() => Point((7 - x).abs(), (7 - y).abs());

  String toString() => "$x:$y";

  // valid returns false if the point is out of bounds
  bool valid() => (this.x < 8 && this.x >= 0) && (this.y < 8 && this.y >= 0);

  bool equal(Point dst) => dst.x == x && dst.y == y;

  Point copy() => Point(x, y);
}

class PieceKind {
  static const empty = 0;
  static const pawn = 1;
  static const bishop = 2;
  static const knight = 3;
  static const rook = 4;
  static const queen = 5;
  static const king = 6;

  static const values = <int>[
    empty,
    pawn,
    bishop,
    knight,
    rook,
    queen,
    king,
  ];

  final value;

  const PieceKind(this.value);

  static const Map<int, String> names = {
    empty: "empty",
    pawn: "pawn",
    bishop: "bishop",
    knight: "knight",
    rook: "rook",
    queen: "queen",
    king: "king",
  };

  static final Map<int, IconData> icondata = {
    empty: null,
    pawn: icons.pawn,
    bishop: icons.bishop,
    knight: icons.knight,
    rook: icons.rook,
    queen: icons.queen,
    king: icons.king,
  };

  String toString() {
    return value == empty ? "" : PieceKind.names[value];
  }

  static String toShortString(int val) {
    final str = PieceKind.names[val];
    if (val == 0) return " ";

    return str.substring(0, 1);
  }

  static IconData getIcon(int val) {
    return icondata[val];
  }
}

class Piece {
  // pos
  Point pos;
  // player number
  bool p1;
  // piece type
  int kind = PieceKind.empty;

  Piece.fromJson(Map<String, dynamic> json)
      : p1 = json["p1"],
        pos = Point.fromJson(json["pos"]),
        kind = PieceKind.values[json["kind"]];

  Map<String, dynamic> toJson() => {
        "p1": p1,
        "type": kind,
        "pos": pos,
      };

  Piece(this.pos, this.kind, this.p1);

  Piece copy() {
    return Piece(this.pos, this.kind, this.p1);
  }

  String toString() => "$pos/${PieceKind(kind).toString()}/${p1 ? 1 : 0}";
}
