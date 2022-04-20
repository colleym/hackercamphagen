import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:mqtt_client/mqtt_browser_client.dart';

// Broker URL with websocket
const String broker = 'wss://mqtt.eclipseprojects.io/mqtt';
const int port = 443;
MqttClient? client;
MqttConnectionState? connectionState;
StreamSubscription? subscription;

int? co2;
List<TimeSeriesValue> co2Series = [];
int? temp;
List<TimeSeriesValue> tempSeries = [];
int? tvoc;
List<TimeSeriesValue> tvocSeries = [];

MaterialColor color = Colors.blue;

// repace with your co2ampel Wifi MAC-Address
String address = "10:52:1C:5B:1C:88";
String tvocTopic = "esp32/ccs811/tvoc/$address";
String co2Topic = "esp32/ccs811/co2/$address";
String tempTopic = "esp32/ccs811/temp/$address";

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: 'CO2 Ampel');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _connect() async {
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      return;
    }
    client = MqttBrowserClient(broker, UniqueKey().hashCode.toString());
    client!.port = port;
    client!.logging(on: true);
    client!.keepAlivePeriod = 30;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client!.connectionMessage = connMess;

    try {
      await client!.connect();
    } catch (_) {
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        connectionState = client!.connectionStatus!.state;
      });
    }

    subscription = client!.updates!.listen(_onMessage);

    _subscribeToTopic(co2Topic);
    _subscribeToTopic(tempTopic);
    _subscribeToTopic(tvocTopic);
  }

  void _subscribeToTopic(String topic) {
    if (connectionState == MqttConnectionState.connected) {
      client!.subscribe(topic, MqttQos.exactlyOnce);
    }
  }

  void _onMessage(List<MqttReceivedMessage> event) {
    final MqttPublishMessage recMess = event[0].payload as MqttPublishMessage;
    final String message =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    setState(() {
      if (recMess.variableHeader!.topicName == co2Topic) {
        co2 = int.parse(message);
        co2Series.add(TimeSeriesValue(DateTime.now(), co2!));
      } else if (recMess.variableHeader!.topicName == tempTopic) {
        temp = int.parse(message);
        tempSeries.add(TimeSeriesValue(DateTime.now(), temp!));
      } else if (recMess.variableHeader!.topicName == tvocTopic) {
        tvoc = int.parse(message);
        tvocSeries.add(TimeSeriesValue(DateTime.now(), tvoc!));
      }
      if (co2! < 800) {
        color = Colors.green;
      } else if (co2! < 1400) {
        color = Colors.yellow;
      } else {
        color = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _connect();
    return MaterialApp(
      title: 'CO2 Ampel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: color,
      ),
      home: Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            Center(child:Text(
              'CO2: $co2 ppm',
              style: Theme.of(context).textTheme.headline4,
            ),),
            SizedBox(
              height: 200,
              child: getSeries(co2Series),
            ),
            Center(child:Text(
              'Temp: $temp °C',
              style: Theme.of(context).textTheme.headline4,
            ),),
            SizedBox(
              height: 200,
              child: getSeries(tempSeries),
            ),
            Center(child: Text(
              'TVOC: $tvoc ppb',
              style: Theme.of(context).textTheme.headline4,
            ),),
            SizedBox(
              height: 200,
              child: getSeries(tvocSeries),
            ),
          ],
        ),
      ),
    ));
  }
}

Widget getSeries(List<TimeSeriesValue> series) {
  return charts.TimeSeriesChart(
    [
      charts.Series<TimeSeriesValue, DateTime>(
        id: 'CO2 Verlauf',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesValue value, _) => value.time,
        measureFn: (TimeSeriesValue value, _) => value.value,
        data: series,
        
      ),
    ],
    animate: true,
    domainAxis: const charts.DateTimeAxisSpec(
    tickFormatterSpec: charts.AutoDateTimeTickFormatterSpec(
      
      minute: charts.TimeFormatterSpec(
        format: 'mm',
        transitionFormat: 'HH:mm'
      ),
    ),
  ),
    dateTimeFactory: const charts.LocalDateTimeFactory(),
  );
}

class TimeSeriesValue {
  final DateTime time;
  final int value;

  TimeSeriesValue(this.time, this.value);
}
