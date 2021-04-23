import 'package:chess_client/src/board/piece.dart';
import 'package:flutter/material.dart';

class _ProfileIcon extends StatelessWidget {
  final IconData icon;
  final int amount;
  final Color clr;

  static double size = 16.0;

  const _ProfileIcon(this.icon, this.amount, this.clr);

  @override
  build(BuildContext context) {
    return SizedBox(
      width: (amount - 1) * size,
      height: size,
      child: Container(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            for (int i = 0; i < amount; i++)
              Positioned(
                left: (i * size) * 0.4,
                child: Icon(
                  icon,
                  size: size,
                  color: clr,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Profile extends StatelessWidget {
  final ImageProvider image;
  final String name;
  final Map<int, int> deadPieces;
  final Color clr;

  const Profile(this.image, this.name, this.deadPieces,
      {this.clr = Colors.white});

  @override
  build(BuildContext context) {
    return Container(
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage: image,
        ),
        title: Text(name),
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
