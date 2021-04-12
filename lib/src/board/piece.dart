import 'package:chess_client/chess_client_icons.dart';
import "package:chess_client/src/board/generator.dart";
import 'package:flutter/widgets.dart';

// TODO: replace this with a class + change the name
class PieceKind {
  static const empty = 0;
  static const pawnf = 1;
  static const pawnb = 2;
  static const bishop = 3;
  static const knight = 4;
  static const rook = 5;
  static const queen = 6;
  static const king = 7;

  static const values = <int>[
    empty,
    pawnf,
    pawnb,
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
    pawnf: "pawn",
    pawnb: "pawn",
    bishop: "bishop",
    knight: "knight",
    rook: "rook",
    queen: "queen",
    king: "king",
  };

  static const Map<int, IconData> icons = {
    empty: null,
    pawnf: ChessClient.pawn,
    pawnb: ChessClient.pawn,
    bishop: ChessClient.bishop,
    knight: ChessClient.knight,
    rook: ChessClient.rook,
    queen: ChessClient.rook,
    king: ChessClient.king,
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
    return icons[val];
  }
}

class Piece {
  // pos
  Point pos;
  // player number
  int num;
  // piece type
  int t = PieceKind.empty;

  Piece.fromJson(Map<String, dynamic> json)
      : num = json["player"],
        t = PieceKind.values[json["type"]];

  Map<String, dynamic> toJson() => {
        "player": this.num,
        "type": t,
      };

  Piece(this.pos, this.t, this.num);

  Piece copy() {
    return Piece(this.pos, this.t, this.num);
  }

  // canGo returns true if dst is a legal move
  bool canGo(Point dst) {
    // out of bounds
    if (!dst.valid()) {
      return false;
    }
    if (this.pos.equal(dst)) {
      return false;
    }

    return this.possib().exists(dst);
  }

  // possib returns possible moves from this.pos
  List<Point> possib() {
    final ps = <Point>[];

    switch (this.t) {
      case PieceKind.pawnb:
      case PieceKind.pawnf:
        {
          if (this.t == PieceKind.pawnb) {
            ps.add(Point(this.pos.x + 1, this.pos.y));
          } else {
            ps.add(Point(this.pos.x - 1, this.pos.y));
          }

          // at start you can move two points
          if (this.pos.x == 1 || this.pos.x == 6) {
            ps.add(Point(this.pos.x - 2, this.pos.y));
            ps.add(Point(this.pos.x + 2, this.pos.y));
          }

          break;
        }
      case PieceKind.bishop:
        {
          ps.addAll(this.pos.diagonal());
          break;
        }
      case PieceKind.knight:
        // 2,1 or -2, 1 or 2, -1 or -2, -1
        // 1,2 or -1, 2 or 1, -2 or -2, -1
        {
          ps.addAll(this.pos.knight());
          break;
        }
      case PieceKind.rook:
        {
          ps.addAll(this.pos.rook());
          break;
        }
      case PieceKind.queen:
        ps.addAll(this.pos.queen());
        break;
      case PieceKind.king:
        ps.addAll(this.pos.square());
        break;
    }
    ps.clean();

    return ps;
  }

  String toString() => "$pos/${PieceKind(t).toString()}/$num";
}
