import 'package:chess_client/src/board/piece.dart';
import 'package:chess_client/src/model/model.dart' as model;
import 'package:flutter/material.dart';

class _ProfileIcon extends StatelessWidget {
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

  const _ProfileIcon(this.icon, this.amount, this.clr);

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
  final Color clr;

  const Profile(this.profile, this.deadPieces, {this.clr = Colors.white});

  @override
  build(BuildContext context) {
    return Container(
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage: NetworkImage(profile.picture),
        ),
        title: Text(profile.username),
        subtitle: Row(
          children: <Widget>[
            for (int index in deadPieces.keys)
              _ProfileIcon(
                  PieceKind.getIcon(index), deadPieces[index], this.clr),
          ],
        ),
      ),
    );
  }
}
