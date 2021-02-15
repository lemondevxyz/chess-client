import 'package:chess_client/src/board/rules.dart';
import 'package:test/test.dart';

void main() {
  test('equal', () {
    expect(equal(Point(0, 0), Point(0, 0)), true);

    expect(equal(Point(0, 0), Point(1, 0)), false);
    expect(equal(Point(0, 0), Point(0, 1)), false);

    expect(equal(Point(0, 0), Point(1, 1)), false);
  });

  test('swap', () {
    final x = Point(1, 0);
    final y = Point(0, 1);

    expect(equal(x, swap(y)), true);
    expect(equal(y, swap(x)), true);
  });

  test('forward', () {
    final Point x = Point(2, 2);
    Point y = Point(2, 2);

    expect(forward(x, y), false);

    y = Point(1, 1);
    expect(forward(x, y), true);

    y = Point(2, 1);
    expect(forward(x, y), true);

    y = Point(1, 2);
    expect(forward(x, y), true);
  });

  test('backward', () {
    final Point x = Point(2, 2);
    Point y = Point(2, 2);

    expect(backward(x, y), false);

    y = Point(3, 2);
    expect(backward(x, y), true);

    y = Point(2, 3);
    expect(backward(x, y), true);

    y = Point(3, 3);
    expect(backward(x, y), true);
  });

  test('within', () {
    final Point area = Point(1, 1);

    final Point x = Point(1, 1);
    Point y = Point(0, 0);

    expect(within(area, x, y), true);

    y = Point(2, 2);
    expect(within(area, x, y), true);

    y = Point(2, 0);
    expect(within(area, x, y), true);

    y = Point(0, 2);
    expect(within(area, x, y), true);

    y = Point(1, 0);
    expect(within(area, x, y), false);
  });

  test('horizontal', () {
    final Point x = Point(1, 1);
    Point y = Point(0, 1);
    expect(horizontal(x, y), true);

    y = Point(2, 1);
    expect(horizontal(x, y), true);

    y = Point(2, 2);
    expect(horizontal(x, y), false);

    y = Point(1, 2);
    expect(horizontal(x, y), false);
  });

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

  test('diagonal', () {
    final Point x = Point(1, 1);
    Point y = Point(0, 0);
    expect(diagonal(x, y), true);

    y = Point(2, 2);
    expect(diagonal(x, y), true);

    y = Point(0, 2);
    expect(diagonal(x, y), true);

    y = Point(2, 0);
    expect(diagonal(x, y), true);

    y = Point(2, 1);
    expect(diagonal(x, y), false);

    y = Point(1, 2);
    expect(diagonal(x, y), false);

    y = Point(0, 1);
    expect(diagonal(x, y), false);

    y = Point(1, 0);
    expect(diagonal(x, y), false);
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
}
