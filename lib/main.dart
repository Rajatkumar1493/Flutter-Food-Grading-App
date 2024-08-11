import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Grading',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: EnterIpScreen(),
    );
  }
}

class EnterIpScreen extends StatefulWidget {
  @override
  _EnterIpScreenState createState() => _EnterIpScreenState();
}

class _EnterIpScreenState extends State<EnterIpScreen> {
  final TextEditingController _ipController = TextEditingController();

  void _submitIp() {
    if (_ipController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyHomePage(ipAddress: _ipController.text),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid IP address'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enter IP Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Server IP Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitIp,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String ipAddress;

  MyHomePage({required this.ipAddress});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String message = 'Fetching data...';
  List<dynamic> data = [];
  bool isFirstFetch = true;
  int totalFruits = 0;
  int totalWeight = 0;

  @override
  void initState() {
    super.initState();
    fetchData();
    Timer.periodic(Duration(seconds: 5), (timer) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('http://${widget.ipAddress}:5000/data'));
    if (response.statusCode == 200) {
      final fetchedData = jsonDecode(response.body) as List;
      setState(() {
        data = fetchedData;
        totalFruits = calculateTotalFruits(fetchedData);
        totalWeight = calculateTotalWeight(fetchedData);
        message = '';
      });
      if (isFirstFetch) {
        isFirstFetch = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data Fetched Successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        message = 'Failed to fetch data';
        // Reset data to empty list and totals to 0 if fetch fails
        data = [];
        totalFruits = 0;
        totalWeight = 0;
      });
    }
  }

  int calculateTotalFruits(List<dynamic> data) {
    return data.length;
  }

  int calculateTotalWeight(List<dynamic> data) {
    int totalWeight = 0;
    for (var row in data) {
      totalWeight += int.parse(row[3]);
    }
    return totalWeight;
  }

  Map<String, dynamic> summarizeData(List<dynamic> data) {
    Map<String, dynamic> summary = {};
    for (var row in data) {
      String grade = row[0];
      String quality = row[1];
      int weight = int.parse(row[3]);
      String key = "${grade}_$quality";

      if (summary.containsKey(key)) {
        summary[key]['count'] += 1;
        summary[key]['weight'] += weight;
      } else {
        summary[key] = {'count': 1, 'weight': weight};
      }
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarizeData(data);

    return Scaffold(
      appBar: AppBar(
        title: Text('Fruit Grading'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                if (data.isNotEmpty) ...[
                  Text(
                    'Total Fruits: ${totalFruits}',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Total Weight: ${totalWeight} g',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 10),
                  DataTable(
                    columnSpacing: 20.0,
                    columns: [
                      DataColumn(label: Text('Grade')),
                      DataColumn(label: Text('Quality')),
                      DataColumn(label: Text('No. of Fruits')),
                      DataColumn(label: Text('Weight (g)')),
                    ],
                    rows: summary.entries.map<DataRow>((entry) {
                      var parts = entry.key.split('_');
                      return DataRow(
                        cells: [
                          DataCell(Text(parts[0])),
                          DataCell(Text(parts[1])),
                          DataCell(Text(entry.value['count'].toString())),
                          DataCell(Text(entry.value['weight'].toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Display placeholders when data is empty
                  Text(
                    'Total Fruits: 0',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Total Weight: 0 g',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
