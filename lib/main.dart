import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_iot/chart.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // home: MyHomePage(title: 'Flutter Demo Home Page'),
      home: LineChartSample6(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String broker = 'wss://mqtt.eclipse.org';
  static int port = 1883;
  String clientIdentifier = 'ios';

  mqtt.MqttClient client;
  mqtt.MqttConnectionState  connectionState;

  double _temp = 20;

  StreamSubscription _subscription;

  void _subcribleToTopic(String topic) {
    if (connectionState == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] Subscribing to ${topic.trim()}');
      client.subscribe(topic, mqtt.MqttQos.exactlyOnce);
    }
  }

  void _testWebSocket() {
    var channel = IOWebSocketChannel.connect("wss://mqtt.eclipse.org:443/mqtt", pingInterval: Duration(milliseconds: 1000), protocols: ["mqtt"]);
    // channel.stream.listen((event) {
    //   print("listening...");
    //   print(event.toString());
    // }, onError: (e) {
    //   print(e);
    // });
    try {
      print("a");
      // channel = IOWebSocketChannel.connect("wss://mqtt.eclipse.org:443/mqtt", pingInterval: Duration(milliseconds: 1000), protocols: ["mqtt"]);
    } catch (e) {
      print(e);
    }
    print(channel.stream.handleError((onError) {
      print("error");
      print(onError.toString());
    }));
  }

  _testSocket() async{
      Socket socket;
  socket = await Socket.connect("mqtt.eclipse.org", 1883);
  socket.listen((event) {
    print('OKE');
    print(event.toString());
   });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_temp',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _testSocket,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  void _connect() async {
    client = mqtt.MqttClient(broker, '');
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 30;
    client.onDisconnected = _onDisconnected;

    final mqtt.MqttConnectMessage onMessage = mqtt.MqttConnectMessage()
          .withClientIdentifier(clientIdentifier)
          .startClean()
          .keepAliveFor(30)
          .withWillQos(mqtt.MqttQos.atMostOnce);
    print('[MQTT client] MQTT client connecting.... $onMessage');
    client.connectionMessage = onMessage;

    try {
      await client.connect();
    } catch (e) {
      print("ERROR try catch: $e");
      _disconnect();
    }
    if (client.connectionStatus.state == mqtt.MqttConnectionState.connected) {
      print('[MQTT client] connected');
      setState(() {
        connectionState = client.connectionStatus.state;
      });
    } else {
      print('[MQTT client] ERROR: MQTT client connection fail, stat is ${client.connectionStatus.state}');
      _disconnect();
    }

    _subscription = client.updates.listen(_onMessage);

    _subcribleToTopic('sensor/temp');
  }

  void _disconnect() {
    print('[MQTT client] disconnected');
    client.disconnect();
    _onDisconnected();
  }

  void _onDisconnected() {
    print('[MQTT client] _onDisconnected');
    setState(() {
      connectionState = client.connectionStatus.state;
      client = null;
      _subscription.cancel();
      _subscription = null;
    });
    print('[MQTT client] MQTT client disconnected');
  }

  void _onMessage(List<mqtt.MqttReceivedMessage> event) {
    print("Event length: " + event.length.toString());
    final mqtt.MqttPublishMessage recMessage = event[0].payload as mqtt.MqttPublishMessage;
    final String message = mqtt.MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
    print('[MQTT client] MQTT message: topic is <${event[0].topic}>, '
        'payload is <-- $message -->');
    print(client.connectionStatus.state);
    print("[MQTT client] message with topic: ${event[0].topic}");
    print("[MQTT client] message with message: $message");
    setState(() {
      _temp = double.parse(message);
    });
  }
}
