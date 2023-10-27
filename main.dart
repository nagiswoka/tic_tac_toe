import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:tic_tac_toe/client.dart';
import 'package:tic_tac_toe/luffy.dart';

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
  Map<int, String> players = {};
  List<List<int>> matrixValues =
      List.generate(3, (_) => List.generate(3, (_) => 0));

  // List<List<int>> movesHistory =
  //     List.generate(3, (_) => List.generate(3, (_) => 0));

  late ConfettiController _controllerCenter;
  // late ConfettiController _controllerCenterRight;
  // late ConfettiController _controllerCenterLeft;
  // late ConfettiController _controllerTopCenter;
  // late ConfettiController _controllerBottomCenter;

  late Client client;

  String name = "";
  String roomId = "";
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  bool isWelcomeDialogShown = false;
  Map<String, int> opp = {};

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 10));
  }

  void goToFreshStart(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TicTacToe()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> setOpponent() async {
    opp = await client.getOpponent(client.socket.id!);
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

  void joinRoom() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Join Room'),
          actions: <Widget>[
            TextFormField(
              controller: _roomController,
              cursorHeight: 20.0,
              decoration: const InputDecoration(
                icon: Icon(Icons.home),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(255, 0, 0, 0),
                    style: BorderStyle.solid,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10.0),
                      right: Radius.circular(10.0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.deepPurpleAccent,
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10.0),
                      right: Radius.circular(10.0)),
                ),
                labelText: "Room ID",
                labelStyle: TextStyle(
                  color: Colors.black,
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                ),
                focusColor: Colors.indigo,
              ),
              textAlign: TextAlign.justify,
              onChanged: (value) {
                roomId = value;
              },
            ),
            const SizedBox(
              height: 5,
            ),
            ElevatedButton(
              onPressed: () async {
                client = Client(name, roomId);
                String data = await client.connectWithRoom();
                if (data.isNotEmpty) {
                  reachedLimit();
                } else {
                  await setOpponent();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
              child: const Text("Join Room"),
            ),
          ],
        );
      },
    );
  }

  void welcome() {
    showDialog(
      barrierColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Let's Play"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                cursorHeight: 20.0,
                decoration: const InputDecoration(
                  icon: Icon(Icons.person),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 0, 0, 0),
                      style: BorderStyle.solid,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(10.0),
                        right: Radius.circular(10.0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.deepPurpleAccent,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(10.0),
                        right: Radius.circular(10.0)),
                  ),
                  labelText: "Enter Name",
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontStyle: FontStyle.normal,
                    fontWeight: FontWeight.bold,
                  ),
                  focusColor: Colors.indigo,
                ),
                textAlign: TextAlign.justify,
                onChanged: (value) {
                  name = value;
                },
              ),
              const Divider(
                height: 5,
                color: Colors.white,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      joinRoom();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                    child: const Text("Join Room"),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      createRoom();
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                    child: const Text("Create Room"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void createRoom() {
    Navigator.of(context).pop();
    client = Client(name, roomId);
    String room = client.createAndJoinRoom();
    roomId = room;
    showDialog(
      barrierColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Let's Play"),
          content: Text('The created Room ID : $room'),
          actions: [
            ElevatedButton(
              onPressed: () {
                //goToFreshStart(context);
                showWaitingForOpponentDialog();
                waitForPlayer2ToJoin(room);
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              child: const Text('Play'),
            ),
          ],
        );
      },
    );
  }

  void reachedLimit() {
    Navigator.of(context).pop();
    showDialog(
      barrierColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Limit Reached!"),
          content: const Text('Try connecting another room'),
          actions: [
            ElevatedButton(
              onPressed: () {
                //goToFreshStart(context);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
              child: const Text('Okay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isWelcomeDialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        welcome();
      });
      isWelcomeDialogShown = true;
    }
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
                      onTap: () async {
                        client.transferMoves(
                            [opp, 3 - opp[opp.keys.toList()[0]]!, row, col]);
                        updateGame();
                      },
                      currentPlayer: player,
                      value: matrixValues[row][col],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void updateGame() {
    client.socket.on('receiveMove', (data) {
      print("received data => $data");
      final deserializedCompleters = deserializeCompleters(data[1]);
      for (var i = 0; i < deserializedCompleters.length; i++) {
        for (var j = 0; j < deserializedCompleters[0].length; j++) {
          if (deserializedCompleters[i][j].length > 0 &&
              !client.completers[i][j].isCompleted) {
            client.completers[i][j].complete(deserializedCompleters[i][j]);
          }
        }
      }
      client.show();
    });
    _updateMatrixValues();
  }

  void _updateMatrixValues() async {
    for (var i = 0; i < client.completers.length; i++) {
      for (var j = 0; j < client.completers[0].length; j++) {
        if (client.completers[i][j].isCompleted) {
          var t = await client.completers[i][j].future;
          setState(() {
            matrixValues[i][j] = t[1];
          });
        }
      }
    }
  }

// Call the function where you need to update the state

  void showWaitingForOpponentDialog() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text("Waiting for Opponent"),
          content: Text("Please wait for an opponent to join..."),
        );
      },
    );
  }

  void waitForPlayer2ToJoin(String room) async {
    // Check periodically if player 2 has joined
    // print("---------------------");
    // int c = await client.playersInRoom(room);
    // print(c);
    // print("---------------------");
    while (opp.isEmpty) {
      int c = await client.playersInRoom(room);
      if (c == 2) {
        await setOpponent(); // Set the opponent
        Navigator.of(context).pop(); // Close the waiting dialog
      }
      await Future.delayed(
          const Duration(seconds: 1)); // Delay before checking again
    }
  }
}
