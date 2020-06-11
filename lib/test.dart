
import 'dart:io';

Future main() async{
  Socket socket;
  socket = await Socket.connect("mqtt.eclipse.org:443/mqtt", 443);
  socket.listen((event) {
    print(event.toString());
   });
}