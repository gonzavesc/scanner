import 'dart:async';
import 'dart:io' show Platform;
import 'dart:io';
import 'dart:convert';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(_MyApp());
}

class _MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  ScanResult scanResult;
  String _host = "192.168.1.59";
  var contents;
  String proteins="";
  void testDecode(String barcode)async{
    var apiReturn = await apiTest(barcode);
    var decodedReturn = getData(apiReturn);
    print(decodedReturn);
    setState(() {
      proteins=decodedReturn['nutriments']['proteins_value'].toString();
    });
  }
  Future apiTest(String barCode) async {
    String path = 'food/' + barCode;
    final completer = Completer<String>();
    final contents = StringBuffer();
    print(path);
    HttpClientRequest request = await HttpClient().get(_host, 5002, path); /*1*/
    HttpClientResponse response = await request.close(); /*4*/
    
    response.transform(utf8.decoder).listen((data) {
      contents.write(data);
    }, onDone: () => completer.complete(contents.toString()));
    return completer.future;
  }
  Map getData(String data){
    return json.decode(data);
  }

  @override
  Widget build(BuildContext context) {
    var contentList = <Widget>[
      if (scanResult != null)
        Card(
          child: Column(
            children: <Widget>[
              ListTile(
                title: Text("Raw Content"),
                subtitle: Text(scanResult.rawContent ?? ""),
              ),
              RaisedButton(onPressed: () {
                testDecode(scanResult.rawContent ?? "");
              }),
              Text(proteins)
            ],
          ),
        )
    ];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Barcode Scanner Example'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.camera),
              tooltip: "Scan",
              onPressed: scan,
            )
          ],
        ),
        body: Column(
          children: contentList,
        ),
      ),
    );
  }

  Future scan() async {
    try {
      var result = await BarcodeScanner.scan();

      setState(() => scanResult = result);
    } on PlatformException catch (e) {
      var result = ScanResult(
        type: ResultType.Error,
        format: BarcodeFormat.unknown,
      );

      if (e.code == BarcodeScanner.cameraAccessDenied) {
        setState(() {
          result.rawContent = 'The user did not grant the camera permission!';
        });
      } else {
        result.rawContent = 'Unknown error: $e';
      }
      setState(() {
        scanResult = result;
      });
    }
  }
}
