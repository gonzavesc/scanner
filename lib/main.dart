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
  String proteins = "";
  String carbs = "";
  String fat = "";
  String calories = "";
  String productName = "";
  double totalProtein = 0;
  double totalFat = 0;
  double totalCarbs = 0;
  double totalCalories = 0;
  void testDecode(String barcode) async {
    var apiReturn = await apiTest(barcode);
    var decodedReturn = getData(apiReturn);
    print(decodedReturn);
    setState(() {
      proteins = decodedReturn['nutriments']['proteins_value'].toString();
      carbs = decodedReturn['nutriments']['carbohydrates_value'].toString();
      fat = decodedReturn['nutriments']['fat_value'].toString();
      productName = decodedReturn['product_name'];
      calories = decodedReturn['nutriments']['energy-kcal_value'].toString();
      print(calories);
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

  Future apiUpload(Map jsonData) async {
    String path = 'food/upload';
    HttpClientRequest request = await HttpClient().post(_host, 5002, path) /*1*/
      ..headers.contentType = ContentType.json /*2*/
      ..write(jsonEncode(jsonData)); /*3*/
    HttpClientResponse response = await request.close(); /*4*/
  }

  Map getData(String data) {
    return json.decode(data);
  }

  void totalValues(String quantity) {
    setState(() {
      totalProtein = double.parse(quantity) * double.parse(proteins) / 100;
      totalCarbs = double.parse(quantity) * double.parse(carbs) / 100;
      totalFat = double.parse(quantity) * double.parse(fat) / 100;
      totalCalories = double.parse(quantity) * double.parse(calories) / 100;
    });
  }

  final _titleController = TextEditingController();
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
              TextField(
                decoration: InputDecoration(
                  labelText: "Quantity in grams",
                ),
                keyboardType: TextInputType.number,
                controller: _titleController,
                onSubmitted: (value) {
                  totalValues(value);
                },
              ),
              RaisedButton(
                onPressed: () {
                  totalValues(_titleController.text);
                },
                child: Text("Update"),
              ),
              Row(
                children: <Widget>[Text("Product name: "), Text(productName)],
              ),
              Row(
                children: <Widget>[Text("Protein per 100g: "), Text(proteins)],
              ),
              Row(
                children: <Widget>[Text("Carbs per 100g: "), Text(carbs)],
              ),
              Row(
                children: <Widget>[Text("Fat per 100g: "), Text(fat)],
              ),
              Row(
                children: <Widget>[Text("Calories per 100g: "), Text(calories)],
              ),
            ],
          ),
        ),
      if (scanResult != null)
        Card(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text("Total protein: "),
                  Text(totalProtein.toString())
                ],
              ),
              Row(
                children: <Widget>[
                  Text("Total Carbs: "),
                  Text(totalCarbs.toString())
                ],
              ),
              Row(
                children: <Widget>[
                  Text("Total fat: "),
                  Text(totalFat.toString())
                ],
              ),
              Row(
                children: <Widget>[
                  Text("Total Calories: "),
                  Text(totalCalories.toString())
                ],
              ),
              RaisedButton(
                onPressed: () {
                  var jsonData = {
                    'code': scanResult.rawContent,
                    'quantity': _titleController.text,
                    'product_name': productName,
                    'nutriments':{'calories':calories,'fat_value':fat,'proteins_value':proteins,'carbohydrates_value':carbs}
                  };
                  apiUpload(jsonData);
                  print(jsonData);
                },
                child: Text("Upload to google"),
              )
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
      testDecode(scanResult.rawContent ?? "");
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
