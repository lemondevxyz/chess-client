import "package:chess_client/src/board/piece.dart";
import 'package:chess_client/src/board/utils.dart';
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:flutter/material.dart';

class HistoryItem {
  final MapPiece src;
  final MapPiece dst;

  const HistoryItem(this.src, this.dst);
}

class MapPiece {
  final int id;
  final Piece piece;

  const MapPiece(this.id, this.piece);
}

class Board with ChangeNotifier implements rest.HistoryService {
  static const int max = 8;
  final _data = List<Piece>.filled(
      32, Piece(Point(-1, -1), PieceKind.empty, false),
      growable: false);

  // this is a list of all moves done by the both players
  final _history = <HistoryItem>[];
  List<HistoryItem> get history => _history.toList(growable: false);
  // this represents the last move we moved to
  int _historyLast = 0;
  int get historyLast => _historyLast;

  Board() {
    const list = <int>[
      // 0 -> 7
      // 0   | 1    | 2    | 3    | 4    | 5    | 6    | 7
      // 0,0 | 1, 0 | 2, 0 | 3, 0 | 4, 0 | 5, 0 | 6, 0 | 7, 0
      PieceKind.rook, PieceKind.knight, PieceKind.bishop, PieceKind.queen,
      PieceKind.king, PieceKind.bishop, PieceKind.knight, PieceKind.rook,
      // 8 -> 15
      // 8   | 9    | 10   | 11   | 12   | 13   | 14   | 15
      // 0,1 | 1, 1 | 2, 1 | 3, 1 | 4, 1 | 5, 1 | 6, 1 | 7, 1
      PieceKind.pawn, PieceKind.pawn, PieceKind.pawn, PieceKind.pawn,
      PieceKind.pawn, PieceKind.pawn, PieceKind.pawn, PieceKind.pawn,
      // 16 -> 23
      // 16  | 17   | 18   | 19   | 20   | 21   | 22   | 23
      // 0,6 | 1, 6 | 2, 6 | 3, 6 | 4, 6 | 5, 6 | 6, 6 | 7, 6
      PieceKind.pawn, PieceKind.pawn, PieceKind.pawn, PieceKind.pawn,
      PieceKind.pawn, PieceKind.pawn, PieceKind.pawn, PieceKind.pawn,
      // 24 -> 31
      // 24  | 25   | 26   | 27   | 28   | 29   | 30   | 31
      // 0,7 | 1, 7 | 2, 7 | 3, 7 | 4, 7 | 5, 7 | 6, 7 | 7, 7
      PieceKind.rook, PieceKind.knight, PieceKind.bishop, PieceKind.queen,
      PieceKind.king, PieceKind.bishop, PieceKind.knight, PieceKind.rook,
    ];

    list.asMap().forEach((int index, int kind) {
      int x = index % 8;
      int y = index ~/ 8;

      bool p1 = false;
      if (index >= 16) {
        p1 = true;
        y += 4;
      }

      _data[index] = Piece(Point(x, y), kind, p1);
    });
  }

  Board.fromJson(List<dynamic> json) {
    json.asMap().forEach((int index, dynamic d) {
      _data[index] = Piece.fromJson(d);
    });
  }

  Board copy() {
    final brd = Board();
    _data.asMap().forEach((int index, Piece pec) {
      brd._data[index] = pec;
    });

    brd._history.addAll(_history);
    brd._historyLast = _historyLast;

    return brd;
  }

  List<Piece> toJson() {
    return _data;
  }

  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    String str = "";

    for (int x = 0; x < 8; x++) {
      if (x > 0) str += "\n";
      for (int y = 0; y < 8; y++) {
        final pec = get(Point(y, x));
        if (pec != null) {
          str += PieceKind.toShortString(pec.piece.kind);
        } else {
          str += " ";
        }

        str += " ";
      }
    }

    return str;
  }

  void set(int id, Point pos) {
    if (!(id >= 0 && id <= 31)) throw "id out of bounds";

    if (!pos.valid()) {
      _data[id].pos = Point(-1, -1);
    } else {
      final mm = get(pos);

      final pec = _data[id].copy();

      _history.add(HistoryItem(
        MapPiece(id, pec),
        mm != null
            ? MapPiece(mm.id, mm.piece.copy())
            : MapPiece(id, pec.copy()..pos = pos),
      ));
      _historyLast++;

      if (mm != null) {
        _data[mm.id].pos = Point(-1, -1);
      }

      _data[id].pos = pos;
    }

    notifyListeners();
  }

  void setKind(int id, int kind) {
    if (!isIDValid(id)) throw "id out of bounds";

    final pec = _data[id].copy();
    final cep = _data[id].copy();
    cep.kind = kind;
    _history.add(HistoryItem(MapPiece(id, pec.copy()), MapPiece(id, cep)));
    _data[id].kind = kind;
    _historyLast++;

    notifyListeners();
  }

  // get Returns a piece by it's point
  MapPiece get(Point src) {
    if (!src.valid()) throw "point out of bounds";

    for (int i = 0; i < _data.length; i++) {
      final pec = _data[i];

      if (pec.pos.equal(src)) return MapPiece(i, pec);
    }

    return null;
  }

  // getByIndex returns a piece by it's index
  Piece getByIndex(int id) {
    if (!isIDValid(id)) throw "id is invalid";

    return _data[id];
  }

  // canGoPrev basically checks if player can go back one move in the move history
  bool canGoPrev() {
    if (_historyLast == 0) return false;

    return true;
  }

  // goPrev goes back one move in the move history. safe on !canGoPrev
  void goPrev() {
    if (!canGoPrev()) return;

    _historyLast--;

    final move = _history[_historyLast];
    _data[move.src.id] = move.src.piece.copy();

    if (move.src.id != move.dst.id) _data[move.dst.id] = move.dst.piece.copy();

    notifyListeners();
  }

  // canGoNext determines if we can do the next move in the move history
  bool canGoNext() {
    if (_historyLast >= (_history.length)) return false;

    return true;
  }

  void _goNext() {
    if (!canGoNext()) return;

    final move = _history[_historyLast];

    _data[move.src.id] = move.src.piece.copy()..pos = move.dst.piece.pos;
    if (move.src.id != move.dst.id)
      _data[move.dst.id].pos = Point(-1, -1);
    else
      _data[move.src.id].kind = move.dst.piece.kind;

    _historyLast++;
  }

  // goNext does the next move in the move history. safe on !canGoNext
  void goNext() {
    _goNext();
    notifyListeners();
  }

  bool canResetHistory() {
    if (_historyLast == _history.length) return false;

    return true;
  }

  // resetHistory resets the history the last point. synchronizing the board with the server's board.
  void resetHistory() {
    for (var i = _historyLast; i < _history.length; i++) {
      _goNext();
    }

    notifyListeners();
  }

  Map<int, int> deadPieces(bool p1) {
    final m = <int, int>{};

    getRange(p1).forEach((int i) {
      if (_data[i].pos.equal(Point(-1, -1))) m[_data[i].kind]++;
    });

    return m;
  }
}
