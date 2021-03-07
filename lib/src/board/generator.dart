// implements generate.go
import 'package:chess_client/src/board/piece.dart';

class Direction {
  static const int up = 0x0001;
  static const int down = 0x0010;
  static const int right = 0x0100;
  static const int left = 0x1000;

  static final dirs = <int>[up, down, right, left].toList(growable: false);

  static int set(int one, int two) {
    return one | two;
  }

  static int clear(int one, int two) {
    return one & ~two;
  }

  static bool has(int one, int two) {
    return (one & two) != 0;
  }
}

extension ListPoint on List<Point> {
  // clean removes any out of bounds points
  void clean() {
    final bad = <int>[];

    this.asMap().forEach((i, p) {
      if (!p.valid()) {
        bad.add(i);
      }
    });

    bad.reversed.toList().forEach((i) {
      this.remove(i);
    });
  }

  // exists checks if dst is inside the list
  bool exists(Point dst) {
    for (var i = 0; i < this.length; i++) {
      final Point v = this[i];
      if (v.equal(dst)) {
        return true;
      }
    }

    return false;
  }

  // outside generates a new list, containing every point that does not exist in this list...
  List<Point> outside() {
    final ps = <Point>[];
    for (var x = 0; x < 8; x++) {
      for (var y = 0; y < 8; y++) {
        final pos = Point(x, y);
        if (!this.exists(pos)) {
          ps.add(pos);
        }
      }
    }

    return ps;
  }

  String toShortString() {
    String str = "";

    this.forEach((p) {
      str += p.toString() + " ";
    });

    return str;
  }
}

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

  // valid returns false if the point is out of bounds
  bool valid() {
    return this.x < 8 && this.x >= 0 && this.y < 8 && this.y >= 0;
  }

  // horizontal returns all possible horizontal points excluding the original point
  List<Point> horizontal() {
    final ps = <Point>[];

    for (var i = 7; i >= 0; i--) {
      if (this.x != i) {
        ps.add(Point(i, this.y));
      }
    }

    return ps;
  }

  // vertical returns all possible vertical points excluding the original point
  List<Point> vertical() {
    final ps = <Point>[];

    for (var i = 7; i >= 0; i--) {
      if (this.y != i) {
        ps.add(Point(this.x, i));
      }
    }

    return ps;
  }

  // rook returns horizontal and vertical combined
  List<Point> rook() {
    final List<Point> ps = this.vertical();
    ps.addAll(this.horizontal());

    return ps;
  }

  // square returns [{+1, +1}, {+1, 0}, {+1, -1}, {0, +1}, {0, -1}, {-1, 1}, {-1, 0}, {-1, -1}]
  List<Point> square() {
    final ps = <Point>[
      Point(this.x + 1, this.y + 1),
      Point(this.x + 1, this.y),
      Point(this.x + 1, this.y - 1),
      Point(this.x, this.y + 1),
      Point(this.x, this.y - 1),
      Point(this.x - 1, this.y + 1),
      Point(this.x - 1, this.y),
      Point(this.x - 1, this.y - 1),
    ];

    ps.clean();

    return ps;
  }

  // diagonal returns possible diagonal moves
  List<Point> diagonal() {
    final ps = <Point>[];

    int x = 0;
    int y = 0;

    int res = this.x - this.y;
    if (res > 0) {
      x = res;
    } else {
      y = res.abs();
    }

    ps.add(Point(x, y));

    // top left
    // to bottom right
    for (var i = 0; i < 8; i++) {
      x++;
      y++;

      final p = Point(x, y);
      if (!p.valid()) {
        break;
      } else if (p.equal(this)) {
        continue;
      }

      ps.add(p);
    }

    y = 7;
    x = 0;

    res = this.x + this.y;
    if (res < 7) {
      y = res;
    } else {
      x = x + (res - 7);
    }
    ps.add(Point(x, y));

    // top right
    // to bottom left
    for (var i = 0; i < 8; i++) {
      x++;
      y--;

      final p = Point(x, y);
      if (!p.valid()) {
        break;
      } else if (p.equal(this)) {
        continue;
      }

      ps.add(p);
    }

    // just in-case
    ps.clean();
    return ps;
  }

  // queen returns queen's possible moves, which are a combination of rook, and bishop..
  List<Point> queen() {
    final List<Point> ps = this.diagonal();
    ps.addAll(this.rook());
    ps.addAll(this.square());

    return ps;
  }

  // knight possible moves: [{+2, +1}, {-2, +1}, {+2, -1}, {-2, -1}, {+1, +2}, {+1, -2}, {-1, +2}, {-1, -1}]
  List<Point> knight() {
    final ps = <Point>[
      // 2, 1
      Point(this.x + 2, this.y + 1), // +, +
      Point(this.x + 2, this.y - 1), // +, -
      Point(this.x - 2, this.y + 1), // -, +
      Point(this.x - 2, this.y - 1), // -, -
      // 1, 2
      Point(this.x + 1, this.y + 2), // +, +
      Point(this.x + 1, this.y - 2), // +, -
      Point(this.x - 1, this.y + 2), // -, +
      Point(this.x - 1, this.y - 2), // -, -
    ];

    ps.clean();

    return ps;
  }

  Point swap() {
    return Point(this.y, this.x);
  }

  bool equal(Point dst) {
    return this.x == dst.x && this.y == dst.y;
  }

  String toString() {
    return "${this.x}:${this.y}";
  }

  int direction(Point dst) {
    final int x = dst.x - this.x;
    final int y = dst.y - this.y;

    int dir = 0x0000;
    if (x > 0) {
      dir = Direction.set(dir, Direction.down);
    } else if (x < 0) {
      dir = Direction.set(dir, Direction.up);
    }

    if (y > 0) {
      dir = Direction.set(dir, Direction.right);
    } else if (y < 0) {
      dir = Direction.set(dir, Direction.left);
    }

    return dir;
  }
}
