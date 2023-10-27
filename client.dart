import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:tic_tac_toe/gameboard.dart';

Logger logger = Logger('Client');

class Client {
  final IO.Socket socket;
  String? name;
  String? roomId;
  bool isJoined = false;
  List<List<Completer<List<dynamic>>>> completers =
      List.generate(3, (_) => List.generate(3, (_) => Completer()));

  Client(this.name, this.roomId)
      : socket = IO.io('http://localhost:3000', <String, dynamic>{
          'transports': ['websocket'],
        }) {
    socket.on('disconnect', (_) {
      print("disconnected from server");
    });
  }

  void show() {
    for (int i = 0; i < completers.length; i++) {
      for (int j = 0; j < completers[i].length; j++) {
        print("[$i][$j]: ${completers[i][j].isCompleted ? "X" : "O"}");
      }
      print("");
    }
  }

  /// Connect to a room and handle events.
  Future<dynamic> connectWithRoom() async {
    if (roomId != null) {
      socket.emit('setName', name);
      socket.emit('join', roomId);
      logger.info("Joining room: $roomId");
    }

    final completer = Completer<dynamic>();

    socket.on('joined', (data) {
      isJoined = true;
      logger.warning('${data[0]} has joined room: ${data[1]}');
      socket.emit('getRoomMembers', '${data[1]}');
      completer.complete("");
    });

    socket.on('nameSet', (data) {
      logger.info('${socket.id} has the name: $data');
    });

    socket.on("reached-limit", (data) {
      logger.warning(data);
      completer.complete(data); // Resolve the completer with the result
    });

    return await completer.future; // Return a Future to handle the result
  }

  /// Transfer moves to an opponent and handle received moves.
  void transferMoves(List<dynamic> moves) async {
    try {
      print("Sending moves: $moves");
      socket.emit('sendMove', moves);
    } catch (e) {
      // Handle any errors here, e.g., log or notify about the error.
      print("Error in transferMoves: $e");
    }
  }

  /// Create and join a new room with a random room ID.
  String createAndJoinRoom() {
    int roomId = Random().nextInt(9000) + 1000;
    socket.emit('setName', name);
    socket.emit('join', roomId.toString());
    logger.info("Joining room: $roomId");
    socket.on('joined', (data) {
      isJoined = true;
      logger.info('${data[0]} has joined room: ${data[1]}');
      socket.emit('getRoomMembers', '${data[1]}');
    });

    socket.on('message', (data) {
      logger.info('Received message: $data');
    });

    socket.on('nameSet', (data) {
      logger.info('${socket.id} has the name: $data');
    });

    return roomId.toString();
  }

  /// Get the opponent's name.
  Future<Map<String, int>> getOpponent(String player) async {
    Completer<Map<String, int>> completer = Completer();

    // Send player information to get the opponent
    socket.emit('sendPlayer', player);

    // Receive the opponent's name
    socket.on('sendOpp', (data) {
      final opponent = Map<String, int>.from(data);
      completer.complete(opponent);
      print("$player vs $opponent");
    });

    // Wait for the future to complete
    Map<String, int> opponent = await completer.future;

    // Return the opponent's name
    return opponent;
  }

  Future<int> playersInRoom(String room) async {
    Completer<int> completer = Completer();
    socket.emit('getCount', room);
    socket.on('receiveCount', (data) {
      completer.complete(data);
    });
    int count = await completer.future;
    return count;
  }
}
