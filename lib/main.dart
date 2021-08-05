import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:scan/scan.dart';

var apiURL = "http://gradesaver.xyz/api/users/event";
ThemeData dark = ThemeData(
    // colorScheme: ColorScheme.dark(),
    scaffoldBackgroundColor: Color(0xFF102334),
    primaryColor: Color(0xFF1d91f4),
    accentColor: Colors.white);

void main() => runApp(MaterialApp(
      home: MyHome(),
      themeMode: ThemeMode.dark,
      darkTheme: dark,
      debugShowCheckedModeBanner: false,
    ));

class MyHome extends StatelessWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset("assets/back.jpg", height: MediaQuery.of(context).size.height, width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            toolbarHeight: 70,
            title: Text(
              'BYF ticket checker',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: 200,
                      child: Image.asset(
                        'assets/obm_logo.png',
                      )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 30, 40, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Enter API URL",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        TextFormField(
                          style: TextStyle(
                              color: Color(
                                0xFFFFFFFF,
                              ),
                              fontSize: 15),
                          autofillHints: [AutofillHints.url],
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Color(0xFF5F85DB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Color(0xFF14faa2)),
                            ),
                            filled: true,
                            hintStyle: TextStyle(color: Color(0xFF509b8f), fontSize: 10),
                            hintText: "eg: https://plebits.com/API/v2/",
                            fillColor: Color(0xFF1a2835),
                            prefixIcon: Icon(
                              Icons.link,
                              color: Colors.white,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 5),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            apiURL = value.trim();
                          },
                        ),
                      ],
                    ),
                  ),
                  MaterialButton(
                    color: Colors.blueAccent,
                    highlightColor: Colors.red,
                    enableFeedback: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => QRViewExample(),
                      ));
                    },
                    child: Text(
                      'Start',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class QRViewExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  ScanController controller = ScanController();
  String qrcode = 'Unknown';

  Widget statusIcon = Icon(
    Icons.camera_rounded,
    color: Color(0xFFFFFFFF),
  );
  String widgetText = "start scanning tickets to show their status";

  Color buttonColor = Colors.blueAccent;
  Color statusColor = Colors.blueGrey;
  bool flashOn = false;
  bool isScanning = true;
  bool isLoading = false;
  late Widget statusWidget;

  void setDefault() {
    flashOn = false;
    buttonColor = Colors.blueAccent;
    widgetText = "start scanning tickets to show their status";
    statusColor = Colors.blueGrey;
    statusIcon = Icon(
      Icons.camera_rounded,
      color: Color(0xFFFFFFFF),
    );
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pause();
    }
    controller.resume();
  }

  Future _asyncInputDialog(BuildContext context) async {
    String ticketData = '';
    return showDialog(
      context: context,
      barrierDismissible: false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter code Manually'),
          content: new Row(
            children: [
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(labelText: 'Ticket Code', hintText: 'eg. m2pc-6cod-4j7d-3dac'),
                onChanged: (value) {
                  ticketData = value;
                },
              ))
            ],
          ),
          actions: [
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text('Check'),
              onPressed: () async {
                await checkCode(ticketData).then((value) => Navigator.pop(context));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    statusWidget = Padding(
      padding: EdgeInsets.fromLTRB(30, 20, 30, 30),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(10)), color: statusColor),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widgetText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton(backgroundColor: buttonColor, onPressed: () {}, child: statusIcon),
      bottomNavigationBar: BottomAppBar(
        color: Color(0xFF1de6af),
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(flashOn ? Icons.flash_off : Icons.flash_on),
              color: Color(0xFF102334),
              onPressed: () {
                controller.toggleTorchMode();
                setState(() {
                  flashOn = !flashOn;
                });
              },
            ),
            IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
              color: Color(0xFF102334),
              onPressed: () async {
                setDefault();
                setState(() {
                  isScanning = !isScanning;
                });
                isScanning ? controller.resume() : controller.pause();
              },
            ),
            SizedBox(
              width: 40,
            ),
            IconButton(
              icon: Icon(Icons.text_fields),
              color: Color(0xFF102334),
              onPressed: () async {
                setDefault();
                setState(() {});
                await _asyncInputDialog(context);
              },
            ),
            IconButton(
              icon: Icon(Icons.settings),
              color: Color(0xFF102334),
              onPressed: () {
                Vibration.cancel();
                super.dispose();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
              flex: 1,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                      color: Colors.white,
                    ))
                  : statusWidget)
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return SizedBox(
      width: 250, // custom wrap size
      height: 250,

      child: ScanView(
        controller: controller,
        scanAreaScale: 0.9,
        scanLineColor: Colors.red,
        onCapture: (data) {
          print(data);
          checkCode(data);
        },
      ),
    );
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  Future checkCode(String? code) async {
    Vibration.cancel();
    setState(() {
      isLoading = true;
    });
    try {
      String body = code!.contains("code") ? code.replaceAll("code", "ticket") : '{"ticket": "$code"}';
      var response = await http.post(
        Uri.parse(apiURL),
        body: body,
        headers: {"Accept": "*", "Content-Type": "application/json"},
      );
      final responseData = await (jsonDecode(response.body));
      final result = responseData['works'];
      print(result);
      setState(() {
        isLoading = false;
        isScanning = false;
        statusIcon = Icon(
          result == "True"
              ? Icons.verified_user
              : result == "Entered"
                  ? Icons.people
                  : result == "Hold"
                      ? Icons.watch_later
                      : Icons.error,
          color: Colors.white,
        );
        buttonColor = result == "True"
            ? Colors.green
            : result == "Entered"
                ? Colors.black
                : result == "Hold"
                    ? Colors.amber
                    : Colors.red;
        statusColor = buttonColor;
        widgetText = result == "True"
            ? "Welcome! You can enter."
            : result == "Entered"
                ? "You've entered once before :("
                : result == "Hold"
                    ? "Ticket is still on hold"
                    : "Invalid ticket!";
      });

      result == "True"
          ? Vibration.vibrate(pattern: [300, 100, 300, 100])
          : result == "Entered"
              ? Vibration.vibrate(duration: 3000)
              : result == "Hold"
                  ? Vibration.vibrate(duration: 300)
                  : Vibration.vibrate(pattern: [300, 50, 300, 100, 300, 50, 300, 100, 300, 50, 300, 100]);

      return result;
    } catch (e) {
      print(e);
    }
  }
}
