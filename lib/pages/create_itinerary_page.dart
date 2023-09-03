import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'package:excel/excel.dart';
import 'dart:io';

class Location {
  final String name;
  final String category;

  Location({required this.name, required this.category});
}

class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({super.key});

  @override
  _CreateItineraryPageState createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  List<Location> locations = [];
  Location? selectedLocation;

  @override
  void initState() {
    super.initState();
    locations = readExcelData();
    if (locations.isNotEmpty) {
      selectedLocation = locations[0];
    }
  }

  List<Location> readExcelData() {
    var file = 'lib/fonts/Davao.xlsx';
    var bytes = File(file).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Location> locations = [];

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows) {
        // Assuming name is in the first column and category is in the second column
        locations.add(
            Location(name: row[0].toString(), category: row[1].toString()));
      }
    }
    return locations;
  }

  Widget _saveButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OverviewItinerary(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          primary: const Color(0xFFAD547F),
          onPrimary: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: const Text('Save',
            style: TextStyle(
                fontSize: 50,
                color: Color(0xFFAD547F),
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Itinerary',
          style: TextStyle(fontSize: 30),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selectedLocation != null) ...[
              DropdownButton<Location>(
                value: selectedLocation,
                onChanged: (Location? newValue) {
                  setState(() {
                    selectedLocation = newValue!;
                  });
                },
                items: locations
                    .map<DropdownMenuItem<Location>>((Location location) {
                  return DropdownMenuItem<Location>(
                    value: location,
                    child: Text('${location.name} - ${location.category}'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _saveButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
