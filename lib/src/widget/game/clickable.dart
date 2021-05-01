import 'dart:collection';

import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/rest/interface.dart' as rest;
import 'package:chess_client/src/widget/game/board.dart' as game;
import 'package:flutter/material.dart';

class Clickable extends StatefulWidget {
  final game.Board wdgt;
  final rest.BoardService service;

  const Clickable(this.wdgt, this.service);

  @override
  createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> {
  int focusid;

  clear() {
    widget.wdgt.markers.clearFocus();
    widget.wdgt.markers.clearPossib();
  }

  @override
  build(BuildContext build) {
    final brd = widget.wdgt.brd;
    final markers = widget.wdgt.markers;

    final ourTurn = widget.service.ourTurn;
    final p1 = widget.service.p1;

    final move = widget.service.move;
    final castling = widget.service.castling;
    final possib = widget.service.possib;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        if (brd.canResetHistory()) {
          brd.resetHistory();
          return;
        }

        Point dst = widget.wdgt.graphics
            .clickAt(details.localPosition.dx, details.localPosition.dy);
        final mm = widget.wdgt.brd.get(dst);

        if (!ourTurn()) return;

        if (mm != null) {
          final pec = mm.piece;
          // our piece?

          if (focusid == mm.id) {
            setState(() {
              focusid = null;

              clear();
            });

            return;
          }

          if (pec.p1 == p1) {
            // are we focused at a previous piece?
            if (focusid != null) {
              final cep = brd.getByIndex(focusid);

              // are they king and rook? then do castling
              final ok1 =
                  pec.kind == PieceKind.king && cep.kind == PieceKind.rook;
              final ok2 =
                  pec.kind == PieceKind.rook && cep.kind == PieceKind.king;
              if (ok1 || ok2) {
                castling(focusid, mm.id);

                setState(() {
                  focusid = null;
                });
                return;
              }
            }
            // then select it
            setState(() {
              clear();
              markers.setFocus(dst);

              focusid = mm.id;
            });

            possib(mm.id).then((HashMap<String, Point> ll) {
              markers.addPossib(ll.values.toList(growable: false));
            }).then((_) {
              setState(() {});
            });
          } else {
            // not our piece? then move there
            if (focusid != null) {
              move(focusid, dst);

              setState(() {
                clear();

                focusid = null;
              });
            }
          }
        } else {
          if (focusid != null) {
            move(focusid, dst).catchError((e) {
              print("error $e");
            }).then((_) {
              focusid = null;
            });

            setState(clear);
          }
        }
      },
      child: widget.wdgt,
    );
  }
}
