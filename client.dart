import 'dart:async';

import 'package:logging/logging.dart';

import 'dart:math';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// The `Client` class represents a client that can connect to a server using the Socket.IO protocol.
/// It provides methods to join a room, connect with a room, and create and join a room.
///
final List<List<Completer<List<dynamic>>>> completers =
    List.generate(3, (_) => List.generate(3, (_) => Completer()));
Logger logger = Logger("Client");
Map<String, Completer<List<dynamic>>> moveCompleters = {};

class Client {
  final String name;
  final IO.Socket socket;
  final String? roomId;
  bool isJoined = false;
  bool isPlayer1 = false;
  bool isPlayer2 = false;

  /// Creates a new instance of the `Client` class with the specified name and room ID.
  /// @param name The name of the client.
  /// @param roomId The ID of the room the client is connected to. Can be null if not connected to any room.
  Client(this.name, this.roomId)
      : socket = IO.io('http://localhost:3000', <String, dynamic>{
          'transports': ['websocket'],
        });

  /// Joins a room by emitting a "join" event with the room name.
  /// @param roomName The name of the room to join.

  /// Connects the client with the room by setting the client's name, joining the room, and handling events.
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

    socket.on('disconnect', (_) {
      logger.info('Disconnected from the server');
    });

    socket.on("reached-limit", (data) {
      logger.warning(data);
      completer.complete(data); // Resolve the completer with the result
    });

    return await completer.future; // Return a Future to handle the result
  }

  // Future<List<dynamic>> transferMoves(List<dynamic> moves) async {
  //   if (moves[0] != null) {
  //     String moveKey = "${moves[2]}_${moves[3]}";
  //     print(moveKey);
  //     Completer<List<dynamic>> completer = Completer<List<dynamic>>();
  //     moveCompleters[moveKey] = completer;

  //     socket.emit('sendMove', moves);

  //     socket.on('receiveMove', (data) {
  //       // Retrieve the associated Completer and complete it
  //       Completer<List<dynamic>> moveCompleter = moveCompleters[moveKey]!;
  //       moveCompleter.complete(data);

  //       // Remove the Completer from the map after completing
  //       moveCompleters.remove(moveKey);
  //       print("map : ${moveCompleter.future}");
  //       logger.info("Received moves: $data");
  //     });

  //     socket.on('disconnect', (_) {
  //       logger.info('Disconnected from the server');
  //     });

  //     return await completer.future;
  //   } else {
  //     logger.warning("Opponent ID is not available. Cannot send move.");
  //     return Future.error("Opponent ID not available");
  //   }
  // }

  Future<List<dynamic>> transferMoves(List<dynamic> moves) async {
    // If the opponent's ID is available, send the move to the opponent
    // Set the target player to the opponent
    print("sending moves: $moves");
    socket.emit('sendMove', moves);
    completers[moves[2]][moves[3]].complete(moves);

    Completer<List<dynamic>> completer = Completer();
    var val = [];
    socket.on('receiveMove', (data) async {
      print("Received moves: $data");
      completers[data[2]][data[3]].complete(data);
      val = await completer.future;
      print(" val : $val");
      //completer.complete(data);
      for (int i = 0; i < completers.length; i++) {
        for (int j = 0; j < completers[i].length; j++) {
          print("[$i][$j]: ${completers[i][j].isCompleted ? "X" : "O"}");
        }
        print("");
      } // Add a new line after each row
    });

    socket.on('disconnect', (_) {
      logger.info('Disconnected from the server');
    });

    return completer.future;
  }

  /// Creates and joins a new room with a random room ID.
  /// @return The room ID as a string.
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

    socket.on('disconnect', (_) {
      logger.info('Disconnected from the server');
    });

    return roomId.toString();
  }

  Future<String> getOpponent(String player) async {
    Completer<String> completer = Completer();

    // sending player to get the opponent
    socket.emit('sendPlayer', player);

    // getting the opponent
    socket.on('sendOpp', (data) {
      completer.complete(data);
    });

    // Wait for the future to complete
    String opponent = await completer.future;

    // Log the opponent
    logger.info("$player vs $opponent");

    // You can return the opponent now
    return opponent;
  }
}
