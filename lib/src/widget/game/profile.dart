import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/model/model.dart' as model;
import 'package:flutter/material.dart';

class _ProfilePiece extends StatelessWidget {
  final IconData icon;
  final int amount;
  final Color clr;

  static double size = 16.0;
  static const List<String> names = [
    "One",
    "Two",
    "Three",
    "Four",
    "Five",
    "Six",
    "Seven",
    "Eight"
  ];

  const _ProfilePiece(this.icon, this.amount, this.clr);

  @override
  build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size,
      child: Tooltip(
        message: "${names[amount - 1]} Dead",
        child: Stack(
          children: <Widget>[
            Center(
              child: Icon(
                icon,
                size: size,
                color: clr,
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Text(
                "$amount",
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontFamily: "monospace",
                  color: clr,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  final model.Profile profile;
  final Map<int, int> deadPieces;
  final bool p1;

  Profile(this.profile, this.p1, this.deadPieces);

  static final Color p1clr = Colors.grey[300];
  static final Color p2clr = Colors.grey[700];

  @override
  build(BuildContext context) {
    final clr = p1 == true ? p1clr : p2clr;

    return Container(
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage: NetworkImage(profile.picture),
        ),
        title: Text(profile.username),
        subtitle: Row(
          children: <Widget>[
            if (deadPieces != null)
              for (int index in deadPieces.keys)
                _ProfilePiece(PieceKind.getIcon(index), deadPieces[index], clr),
          ],
        ),
      ),
    );
  }
}
