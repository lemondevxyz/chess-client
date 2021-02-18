// implements rules.go
extension ListPoint on List<Point> {
  // clean removes any out of bounds points
  void clean() {
    final bad = <int>[];

    this.asMap().forEach((i, p) {
      if (p.outOfBounds()) {
        bad.add(i);
      }
    });

    bad.reversed.toList().forEach((i) {
      this.remove(i);
    });
  }
}

class Point {
  final int x, y;

  const Point(this.x, this.y);

  bool outOfBounds() {
    return (7 > this.x || 0 > this.x || 7 > this.y || 0 > this.y);
  }

  List<Point> horizontal() {
    final ps = <Point>[];

    for (var i = 7; i >= 0; i--) {
      ps.add(Point(i, this.y));
    }

    return ps;
  }

  List<Point> vertical() {
    final ps = <Point>[];

    for (var i = 7; i >= 0; i--) {
      ps.add(Point(this.x, i));
    }

    return ps;
  }

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

  // possible diagonal moves
  List<Point> diagonal() {
    final ps = <Point>[];

    int x = this.x;
    int y = this.y;

    final int orix = x;
    final int oriy = y;

    int diff = (8 - orix);
    if (orix > oriy) {
      diff = 8 - orix;
    } else if (orix < oriy) {
      diff = 8 - oriy;
    } else if (orix == oriy) {
      diff = 8 - orix;
    }

    x += diff;
    y += diff;

    for (var i = 0; i < 8; i++) {
      x--;
      y--;

      if (x == -1 || y == -1 || x == 8 || y == 8) {
        break;
      }

      ps.add(Point(x, y));
    }

    x = 0;
    y = oriy + diff;

    for (var i = 0; i < 8; i++) {
      x--;
      y++;

      if (x == -1 || y == -1 || x == 8 || y == 8) {
        break;
      }

      ps.add(Point(x, y));
    }

    return ps;
  }

  // knight possible moves
  List<Point> knight() {
    final ps = <Point>[
      Point(x + 2, x + 1),
      Point(x + 2, x - 1),
      Point(x - 2, x + 1),
      Point(x - 2, x - 1),
      Point(x + 1, x + 1),
      Point(x + 1, x - 1),
      Point(x - 1, x + 1),
      Point(x - 1, x - 1),
    ];

    ps.clean();

    return ps;
  }
}

/// swap returns a point with y, x instead of x, y
Point swap(Point p) {
  return Point(p.y, p.x);
}

/// equal checks if two points are the same
bool equal(Point src, Point dst) {
  return src.x == dst.x && src.y == dst.y;
}

/// forward checks if dst is forward of src. if it's equal then it returns false
bool forward(Point src, Point dst) {
  if (equal(src, dst)) {
    return false;
  }

  final int i = src.x - dst.x;
  final int j = src.y - dst.y;

  if (i >= 0 && j >= 0) {
    return true;
  }

  return false;
}

/// backward checks if dst is backward of src. if it's equal then it returns false
bool backward(Point src, Point dst) {
  if (equal(src, dst)) {
    return false;
  }

  return !forward(src, dst);
}

/// within checks if (src-dst) is inside of area
bool within(Point area, Point src, Point dst) {
  final int i = (src.x - dst.x).abs();
  final int j = (src.y - dst.y).abs();

  if (i == area.x && j == area.y) {
    return true;
  }

  return false;
}

/// horizontal allows for up and down movement
bool horizontal(Point src, Point dst) {
  return src.y == dst.y && src.x != dst.x;
}

/// vertical allows for left and right movement
bool vertical(Point src, Point dst) {
  return src.x == dst.x && src.y != dst.y;
}

/// diagonal allows for movement of: [Up Left, Up Right, Down Left, Down Right]
bool diagonal(Point src, Point dst) {
  final int i = (src.x - dst.x).abs();
  final int j = (src.y - dst.y).abs();

  if (i == j) {
    return true;
  }

  return false;
}

/// square helper function that allows for movement of: [Up, Left, Down, Right] - [Up Left, Up Right, Down Left, Down Right]
bool square(Point src, Point dst) {
  final Point corner = Point(1, 1);
  final Point area = Point(1, 0);

  return within(corner, src, dst) ||
      within(area, src, dst) ||
      within(swap(area), src, dst);
}
