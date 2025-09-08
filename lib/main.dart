import 'package:flutter/material.dart';

void main() {
  runApp( MaterialApp(
    debugShowCheckedModeBanner: false,
    home: StreetMap(),
  ));
}


class StreetMap extends StatefulWidget {
  const StreetMap({super.key});

  @override
  State<StreetMap> createState() => _StreetMapState();
}

class _StreetMapState extends State<StreetMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar:AppBar(
        title: Text('Street Map'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
    );
  }
}

