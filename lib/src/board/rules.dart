// implements rules.go

class Point {
  final int x, y;

  const Point(this.x, this.y);
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
