
import 'package:device/flutter_serial.dart';
import 'package:device/serial.dart';
import 'package:device/usb_serial.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_serial_communication/flutter_serial_communication.dart';
import 'package:flutter_serial_communication/models/device_info.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:serial_communication/serial_communication.dart';

void main() {
  runApp( UsbSerialCom());
  // runApp( FlutterSerialCom());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterSerialCommunicationPlugin = FlutterSerialCommunication();
  bool isConnected = false;
  List<DeviceInfo> connectedDevices = [];
  var responce;

  SerialCommunication serialCommunication = SerialCommunication();

var serialList;

  @override
  void initState() {
    super.initState();
    getSerialComm();
    _flutterSerialCommunicationPlugin
        .getSerialMessageListener()
        .receiveBroadcastStream()
        .listen((event) {
setState(() {
  responce="calling";
});
      debugPrint("Received From machine Native:  $event");
    });

    _flutterSerialCommunicationPlugin
        .getDeviceConnectionListener()
        .receiveBroadcastStream()
        .listen((event) {
      setState(() {
        isConnected = event;
      });
    });
  }
  getSerialComm() async {
    print("call serial comm");
    serialList = await serialCommunication.getAvailablePorts();
    print(serialList);

  }

  _getAllConnectedDevicedButtonPressed() async {
    try {
      PermissionStatus status;
        status = await Permission.storage.request();

      print(status);
      if(status.isDenied){

      }
      getSerialComm();
    } catch (e, stackTrace) {
      // Handle the exception
      print("Exception: $e");
      print("Stack Trace: $stackTrace");
    }
    List<DeviceInfo> newConnectedDevices =
        await _flutterSerialCommunicationPlugin.getAvailableDevices();
    print(newConnectedDevices);
    setState(() {
      connectedDevices = newConnectedDevices;
    });
  }

  _connectButtonPressed(DeviceInfo deviceInfo) async {
    print("this is device info $deviceInfo");

    // await _flutterSerialCommunicationPlugin.setDTR(true);
    // await _flutterSerialCommunicationPlugin.setRTS(true);
    try{


    bool isConnectionSuccess =
        await _flutterSerialCommunicationPlugin.connect(deviceInfo, 115200);
    debugPrint("Is Connection Success:  $isConnectionSuccess");

    print("send message");
    String data = "CMDSTATUSX";
    print(data.codeUnits);
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList(data.codeUnits));
    debugPrint("Is Message Sent:  $isMessageSent");

    var response = await _flutterSerialCommunicationPlugin
        .getSerialMessageListener()
        .receiveBroadcastStream();
    (response.handleError((error) {
      print(error);
    }));
    }catch(e){
      print("from catch");
      print(e);
    }
    print("response variable");
    print(responce);
    debugPrint("-----------------");
  }

  _disconnectButtonPressed() async {
    await _flutterSerialCommunicationPlugin.disconnect();
  }

  _sendMessageButtonPressed() async {
    print("send message");
    String data = "CMDSTATUSX";
    bool isMessageSent = await _flutterSerialCommunicationPlugin
        .write(Uint8List.fromList(data.codeUnits));
    debugPrint("Is Message Sent:  $isMessageSent");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Serial Communication Example App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text("device info "),
              Text("Is Connected: $isConnected"),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: _getAllConnectedDevicedButtonPressed,
                child: const Text("Get All Connected Devices"),
              ),
              const SizedBox(height: 16.0),
              ...connectedDevices.asMap().entries.map((entry) {
                return Row(
                  children: [
                    Flexible(child: Text(entry.value.productName)),
                    const SizedBox(width: 16.0),
                    FilledButton(
                      onPressed: () {
                        _connectButtonPressed(entry.value);
                      },
                      child: const Text("Connect"),
                    ),
                  ],
                );
              }).toList(),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: isConnected ? _disconnectButtonPressed : null,
                child: const Text("Disconnect"),
              ),
              const SizedBox(height: 16.0),
              FilledButton(
                onPressed: isConnected ? _sendMessageButtonPressed : null,
                child: const Text("Send Message To Connected Device"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
