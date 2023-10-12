import 'package:logging/logging.dart';
import 'package:socket_io/socket_io.dart';

var logger = Logger('Server');
void main() {
  // Create a Socket.IO server
  var server = Server();
  Map<String, String> users = {};
  // Define a connection handler for new socket connections

  server.on('connect', (socket) {
    logger.info('A ${socket.id} is connected ');

    socket.on('setName', (name) {
      users[socket.id] = name;
      socket.emit('nameSet', name);
    });

    // Handle the "join" event from the client
    socket.on('join', (roomName) {
      if (checkPlayers(server, socket, roomName) < 2) {
        logger.info('User ${users[socket.id]} is joining room: $roomName');

        // Join the room
        socket.join(roomName);

        // Emit a "joined" event to acknowledge the client's room join
        print(
            "------------------------------------------- $users --------------------------------------------");

        socket.emit('joined', [users[socket.id], roomName]);
      } else {
        logger.info("Room reached limit try connecting another room");
        socket.emit(
            "reached-limit", "Room reached limit try connecting another room");
      }
    });

    socket.on('sendPlayer', (player) {
      print("the player asked for opp is : $player");
      String opp = "";
      for (var element in users.keys) {
        if (element != player) {
          opp = element;
        }
      }
      print("${users[socket.id]} opponent is: ${users[opp]} ");
      socket.emit('sendOpp', opp);
    });

    socket.on('gotOpp', (data) {
      print("----------------------------------------------------------");
      print("${data[0]}opponent is ${data[1]}");
      print("----------------------------------------------------------");
    });

    // Handle other events, such as "message", "disconnect", etc.

    // Handle disconnections
    socket.on('disconnect', (_) {
      logger.info('User ${users[socket.id]} disconnected');
      users = {};
    });

    socket.on('getRoomMembers', (roomName) {
      final members = server.sockets.adapter.rooms[roomName]?.sockets ?? {};
      var memberIds = members.keys.toList();
      List<String?> players = [];
      for (var element in memberIds) {
        players.add(users[element]);
      }
      logger.info('Members in room $roomName: $users');
      // You can emit this list back to the client if needed.
    });

    socket.on('sendMove', (data) {
      try {
        String roomName = data[0];

        logger.info("Received 'sendMove' event for room: $roomName");
        logger.info("Data received: $data");

        // Emit the 'receiveMove' event to the specified room
        server.to(roomName).emit('receiveMove', data);
        logger.info("sent data : ${users[data[0]]}");

        logger.info("Sent 'receiveMove' event to room: $roomName");
      } catch (e) {
        logger.severe("Error handling 'sendMove' event: $e");
      }
    });
  });

  // Listen on a specific port (e.g., 3000)
  server.listen(3000);
}

int checkPlayers(Server server, Socket socket, String room) {
  int memberIds = 0;
  final members = server.sockets.adapter.rooms[room]?.sockets ?? {};
  memberIds = members.keys.length;
  logger.info(members.keys.toList());

  return memberIds;
}
