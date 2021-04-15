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
  final history = <HistoryItem>[];
  // this represents the last move we moved to
  int historyLast = 0;

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
      final mm = d as Map<String, dynamic>;
      _data[index] = Piece.fromJson(d);
    });
  }

  Board duplicate() {
    final brd = Board();
    brd._data.addAll(_data);

    brd.history.addAll(history);
    brd.historyLast = historyLast;

    return brd;
  }

  List<Piece> toJson() {
    return _data;
  }

  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    String str = "";

    this._data.asMap().forEach((int index, Piece pec) {
      if (index != 0) {
        str += "\n";
      }

      if (pec != null) {
        str += PieceKind.toShortString(pec.kind) + " ";
      } else {
        str += "  ";
      }
    });

    return str;
  }

  void set(int id, Point pos) {
    if (!(id >= 0 && id <= 31)) throw "id out of bounds";

    if (!pos.valid()) {
      _data[id].pos = Point(-1, -1);
    } else {
      final cep = get(pos);
      if (cep != null) {
        _data[cep.id].pos = Point(-1, -1);
      }
      _data[id].pos = pos;
    }

    notifyListeners();
  }

  void setKind(int id, int kind) {
    if (id >= 0 && id <= 31) throw "id out of bounds";

    this._data[id].kind = kind;

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

  // canGoPrev basically goes back one move in the move history
  bool canGoPrev() {
    if (historyLast == 0) return false;

    return true;
  }

  // goPrev goes back one move in the move history. safe on !canGoPrev
  void goPrev() {
    if (!this.canGoPrev()) return;

    historyLast--;

    final move = history[historyLast];
    Piece pec = move.src.piece.copy();
    Piece cep = move.dst.piece.copy();

    if (cep != null) this.set(move.src.id, cep.pos);
    if (pec != null) this.set(move.dst.id, pec.pos);
  }

  // canGoNext determines if we can do the next move in the move history
  bool canGoNext() {
    if (historyLast >= (history.length)) return false;

    return true;
  }

  // goNext does the next move in the move history. safe on !canGoNext
  void goNext() {
    if (!this.canGoNext()) return;

    final move = history[historyLast];

    final dst = move.dst.piece.pos;

    _data[move.dst.id].pos = Point(-1, -1);
    set(move.src.id, dst);

    historyLast++;
  }

  bool canResetHistory() {
    if (historyLast == history.length) return false;

    return true;
  }

  void resetHistory() {
    for (var i = historyLast; i < history.length; i++) {
      final move = history[historyLast];

      final dst = move.dst.piece.pos;

      _data[move.dst.id].pos = Point(-1, -1);
      _data[move.src.id].pos = dst;

      historyLast++;
    }

    notifyListeners();
  }
}
