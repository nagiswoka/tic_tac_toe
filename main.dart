import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:tic_tac_toe/matrix.dart';

void main() {
  runApp(const TicTacToe());
}

class TicTacToe extends StatelessWidget {
  const TicTacToe({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TicTacToe',
      home: Games(),
    );
  }
}

class Games extends StatefulWidget {
  const Games({super.key});

  @override
  State<Games> createState() => _GamesState();
}

class _GamesState extends State<Games> {
  int player = 1;
  int count = 0;
  List<List<int>> matrixValues =
      List.generate(3, (_) => List.generate(3, (_) => 0));

  late ConfettiController _controllerCenter;
  late ConfettiController _controllerCenterRight;
  late ConfettiController _controllerCenterLeft;
  late ConfettiController _controllerTopCenter;
  late ConfettiController _controllerBottomCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 10));
    _controllerCenterRight =
        ConfettiController(duration: const Duration(seconds: 10));
    _controllerCenterLeft =
        ConfettiController(duration: const Duration(seconds: 10));
    _controllerTopCenter =
        ConfettiController(duration: const Duration(seconds: 10));
    _controllerBottomCenter =
        ConfettiController(duration: const Duration(seconds: 10));
  }

  void goToFreshStart(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TicTacToe()),
      (Route<dynamic> route) => false,
    );
  }

  bool isBingo(List<List<int>> grid, int member) {
    int count = 0;
    //left to right
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        if (grid[row][col] == member) {
          count++;
        }
      }
      if (count == 3) {
        return true;
      } else {
        count = 0;
      }
    }
    //top to bottom
    for (var col = 0; col < 3; col++) {
      for (var row = 0; row < 3; row++) {
        if (grid[row][col] == member) {
          count++;
        }
      }
      if (count == 3) {
        return true;
      } else {
        count = 0;
      }
    }

    //diagonal
    for (var i = 0; i < 3; i++) {
      if (grid[i][i] == member) {
        count++;
      }
    }
    if (count == 3) {
      return true;
    } else {
      count = 0;
    }

    for (var i = 0; i < 3; i++) {
      if (grid[i][3 - i - 1] == member) {
        count++;
      }
    }
    return count == 3 ? true : false;
  }

  void showWinnerDialog(int winningPlayer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Stack(
          alignment: AlignmentDirectional.center,
          children: [
            ConfettiWidget(
              confettiController: _controllerCenter,
              colors: const [
                Colors.red,
                Colors.purple,
                Colors.amber,
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.deepPurple,
              ],
              numberOfParticles: 100,
              maxBlastForce: 200,
              blastDirection: 0,
              blastDirectionality: BlastDirectionality.explosive,
              gravity: 0.2,
              shouldLoop: true,
            ),
            AlertDialog(
              title: Text('Player $winningPlayer wins!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    goToFreshStart(context);
                    // Close the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Tic Tac Toe"),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.grey[800],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int row = 0; row < 3; row++)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int col = 0; col < 3; col++)
                    Matrix(
                      currentPlayer: player,
                      onTap: () {
                        setState(() {
                          int temp = 0;
                          if (matrixValues[row][col] == 0) {
                            temp = player;
                            matrixValues[row][col] = player;
                            player = player % 2 + 1;
                            if (isBingo(matrixValues, temp)) {
                              showWinnerDialog(temp);
                              _controllerCenter.play();
                            }
                          }
                        });
                      },
                      value: matrixValues[row][col],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
