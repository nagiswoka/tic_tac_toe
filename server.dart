import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:socket_io/socket_io.dart';

var logger = Logger('Server');
late List<List<Completer<List<dynamic>>>> completers;

void main() {
  // Create a Socket.IO server
  var server = Server();
  Map<String, String> users = {};
  Map<String, int> players = {};
  int val = 1;
  // Define a connection handler for new socket connections
  server.on('connect', (socket) {
    completers = List.generate(3, (_) => List.generate(3, (_) => Completer()));
    logger.info('A ${socket.id} is connected ');

    socket.on('setName', (name) {
      // Set the name for the user
      users[socket.id] = name;
      socket.emit('nameSet', name);
    });

    // Handle the "join" event from the client
    socket.on('join', (roomName) {
      if (checkPlayers(server, socket, roomName) < 2) {
        if (val > 2) val = 1;
        logger.info('User ${users[socket.id]} is joining room: $roomName');

        // Join the room
        socket.join(roomName);

        // Emit a "joined" event to acknowledge the client's room join
        socket.emit('joined', [users[socket.id], roomName]);
        players[socket.id] = val;
        val++;
      } else {
        logger.info("Room reached limit. Try connecting to another room");
        socket.emit("reached-limit",
            "Room reached limit. Try connecting to another room");
      }
    });

    socket.on('sendPlayer', (player) {
      // Find an opponent for the player
      print("player is : $player");
      String opp = "";
      for (var element in users.keys) {
        if (element != player) {
          opp = element;
        }
      }
      print("opp is $opp");
      // Send the opponent's name back to the player
      socket.emit('sendOpp', {opp: players[opp]});
    });

    // Handle other events, such as "message", "disconnect", etc.

    // Handle disconnections
    socket.on('disconnect', (_) {
      logger.info('User ${users[socket.id]} disconnected');
      completers = [];
      users = {}; // Clear the users list when a user disconnects
    });

    socket.on('getRoomMembers', (roomName) {
      // Get a list of members in a specific room
      final members = server.sockets.adapter.rooms[roomName]?.sockets ?? {};
      var memberIds = members.keys.toList();
      List<String?> players = [];
      for (var element in memberIds) {
        players.add(users[element]);
      }
      logger.info('Members in room $roomName: $users');
      // You can emit this list back to the client if needed.
    });

    socket.on('getCount', (room) {
      final members = server.sockets.adapter.rooms[room]?.sockets ?? {};
      print("---------------------------------");
      print("$room : ${members.length}");
      print("---------------------------------");

      socket.emit('receiveCount', members.length);
    });

    socket.on('sendMove', (data) async {
      //   try {
      // print("received data : ");
      // print(data);
      String roomName = data[0].keys.toList()[0];
      logger.info("Received 'sendMove' event for room: $roomName");
      logger.info("Data received => $data");
      completers[data[2]][data[3]].complete(data);
      // for (int i = 0; i < completers.length; i++) {
      //   for (int j = 0; j < completers[i].length; j++) {
      //     print("[$i][$j]: ${completers[i][j].isCompleted ? "X" : "O"}");
      //   }
      //   print("");
      // }

      // Emit the 'receiveMove' event to the specified room
      // server.to(roomName).emit('receiveMove', [data, completers]);

      final gameState = await serializeCompleters(completers);

      // Emit the 'receiveMove' event with the data and the serialized game state
      server.to(roomName).emit('receiveMove', [data, gameState]);
      logger.info("Sent data => $data");

      logger.info("Sent 'receiveMove' event to room: $roomName");
      //  } catch (e) {
      //     logger.severe("Error handling 'sendMove' event: $e");
      //   }
    });
  });

  // Listen on a specific port (e.g., 3000)
  server.listen(3000);
}

// Function to check the number of players in a room
int checkPlayers(Server server, Socket socket, String room) {
  int memberIds = 0;
  final members = server.sockets.adapter.rooms[room]?.sockets ?? {};
  memberIds = members.keys.length;
  logger.info(members.keys.toList());

  return memberIds;
}

Future<String> serializeCompleters(
    List<List<Completer<List<dynamic>>>> completers) async {
  List<List<dynamic>> list = [];

  for (int i = 0; i < completers.length; i++) {
    List<dynamic> temp = [];
    for (int j = 0; j < completers[i].length; j++) {
      if (completers[i][j].isCompleted) {
        var t = await completers[i][j].future;
        temp.add(t);
      } else {
        temp.add([]);
      }
    }
    list.add(temp);
  }
  Completer<dynamic> completer = Completer();
  completer.complete(json.encode(list));
  return await completer.future;
}

class CustomServer {
  static List<List<Completer<List<dynamic>>>> completers =
      List.generate(3, (_) => List.generate(3, (_) => Completer()));

  List<List<Completer<List<dynamic>>>> updateCompleters(List<dynamic> moves) {
    completers[moves[2]][moves[3]].complete(moves);
    print("server");
    for (int i = 0; i < completers.length; i++) {
      for (int j = 0; j < completers[i].length; j++) {
        print("[$i][$j]: ${completers[i][j].isCompleted ? "X" : "O"}");
      }
      print("");
    }
    return completers;
  }
}
