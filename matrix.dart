import 'package:flutter/material.dart';

typedef MyCall = void Function();

class Matrix extends StatelessWidget {
  const Matrix(
      {super.key,
      required this.currentPlayer,
      required this.onTap,
      required this.value});
  final int currentPlayer;
  final MyCall onTap;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color:
          value == 0 ? Colors.amber : (value == 1 ? Colors.blue : Colors.green),
      child: SizedBox(
        width: 100,
        height: 100,
        child: InkWell(
          onTap: () {
            onTap();
          },
          child: Center(
            child: Text(
              value == 0 ? "" : value.toString(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}
