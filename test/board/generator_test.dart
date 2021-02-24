import 'package:chess_client/src/board/generator.dart';
import 'package:test/test.dart';

void main() {
  test('valid', () {
    expect(Point(0, 0).valid(), true);

    expect(Point(7, 8).valid(), false);
    expect(Point(8, 7).valid(), false);

    expect(Point(-1, 0).valid(), false);
    expect(Point(0, -1).valid(), false);
  });

  test('equal', () {
    expect(Point(0, 0).equal(Point(0, 0)), true);

    expect(Point(0, 0).equal(Point(1, 0)), false);
    expect(Point(0, 0).equal(Point(0, 1)), false);

    expect(Point(0, 0).equal(Point(1, 1)), false);
  });

  test("point direction", () {
    final p = Point(4, 4);

    expect(p.direction(Point(4, 3)), Direction.left);
    expect(p.direction(Point(4, 5)), Direction.right);

    expect(p.direction(Point(3, 4)), Direction.up);
    expect(p.direction(Point(5, 4)), Direction.down);

    expect(
        p.direction(Point(3, 3)), Direction.set(Direction.up, Direction.left));
    expect(
        p.direction(Point(3, 5)), Direction.set(Direction.up, Direction.right));
    expect(p.direction(Point(5, 3)),
        Direction.set(Direction.down, Direction.left));
    expect(p.direction(Point(5, 5)),
        Direction.set(Direction.down, Direction.right));
  });

  test("direction operations", () {
    int dir = Direction.set(Direction.up, Direction.right);
    if (!Direction.has(dir, Direction.right) ||
        !Direction.has(dir, Direction.up)) {
      expect(true, false);
    }

    dir = Direction.set(Direction.down, Direction.left);
    if (Direction.has(dir, Direction.right) ||
        Direction.has(dir, Direction.up)) {
      expect(false, false);
    }

    for (int i = 0; i < Direction.dirs.length; i++) {
      dir = Direction.dirs[i];

      Direction.dirs.forEach((v) {
        if (v != dir) {
          if (Direction.has(dir, v)) {
            print("${dir.toRadixString(4)} has ${v.toRadixString(4)}");
            expect(false, true);
          }
        }
      });
    }
  });

  test('swap', () {
    final x = Point(1, 0);
    final y = Point(0, 1);

    expect(x.equal(y.swap()), true);
    expect(y.equal(x.swap()), true);
  });

  test('horizontal', () {
    final Point x = Point(1, 1);
    final want = <Point>[
      Point(7, 1),
      Point(6, 1),
      Point(5, 1),
      Point(4, 1),
      Point(3, 1),
      Point(2, 1),
      Point(0, 1),
    ];

    final have = x.horizontal();
    for (int i = 0; i < want.length; i++) {
      Point v = want[i];
      if (!have.exists(v)) {
        print("$v does not exist");
        expect(false, true);
      }
    }

    final outside = want.outside();
    for (int i = 0; i < outside.length; i++) {
      Point v = outside[i];
      if (have.exists(v)) {
        print("points outside of horizontal match..");
        expect(true, false);
      }
    }
  });

  test('vertical', () {
    final Point x = Point(1, 1);
    final want = <Point>[
      Point(1, 7),
      Point(1, 6),
      Point(1, 5),
      Point(1, 4),
      Point(1, 3),
      Point(1, 2),
      Point(1, 0),
    ];

    final have = x.vertical();
    for (int i = 0; i < want.length; i++) {
      Point v = want[i];
      if (!have.exists(v)) {
        print("$v does not exist");
        expect(false, true);
      }
    }

    final outside = want.outside();
    for (int i = 0; i < outside.length; i++) {
      Point v = outside[i];
      if (have.exists(v)) {
        print("points outside of vertical match..");
        expect(true, false);
      }
    }
  });

  test('diagonal', () {
    final Point x = Point(4, 3);
    final want = <Point>[
      // bottom right
      Point(7, 6),
      Point(6, 5),
      Point(5, 4),
      // bottom left
      Point(3, 2),
      Point(2, 1),
      Point(1, 0),
      // top right
      Point(3, 4),
      Point(2, 5),
      Point(1, 6),
      Point(0, 7),
      // top left
      Point(5, 2),
      Point(6, 1),
      Point(7, 0),
    ];

    final have = x.diagonal();
    for (int i = 0; i < want.length; i++) {
      Point v = want[i];
      if (!have.exists(v)) {
        print("${want.toShortString()}");
        print("${have.toShortString()}");
        print("$v does not exist");
        expect(false, true);
      }
    }

    final outside = want.outside();
    for (int i = 0; i < outside.length; i++) {
      Point v = outside[i];
      if (have.exists(v)) {
        print("points outside of vertical match..");
        expect(true, false);
      }
    }
  });

  /*
  test('vertical', () {
    final Point x = Point(1, 1);
    Point y = Point(1, 0);

    expect(vertical(x, y), true);

    y = Point(1, 2);
    expect(vertical(x, y), true);

    y = Point(2, 2);
    expect(vertical(x, y), false);

    y = Point(2, 1);
    expect(vertical(x, y), false);
  });

  test('square', () {
    final Point x = Point(1, 1);
    List<Point> y = [
      Point(2, 2),
      Point(2, 1),
      Point(2, 0),
      Point(1, 0),
      Point(1, 2),
      Point(0, 2),
      Point(0, 1),
      Point(0, 0),
    ];

    y.forEach((Point p) {
      expect(square(x, p), true);
    });
    y.removeRange(0, y.length);

    y.add(Point(3, 1));
    y.add(Point(1, 3));
    y.add(Point(-1, 1));
    y.add(Point(1, -1));
    y.forEach((Point p) {
      expect(square(x, p), false);
    });
  });
  */
}
