import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';

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
  List<Location?> selectedLocations = [null];

  @override
  void initState() {
    super.initState();
    readExcelData().then((loadedLocations) {
      setState(() {
        locations = loadedLocations;
      });
    });
  }

  Future<List<Location>> readExcelData() async {
    try {
      ByteData data = await rootBundle.load("assets/locs.xlsx");
      var bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);
      List<Location> locations = [];

      for (var table in excel.tables.keys) {
        bool isFirstRow = true;
        for (var row in excel.tables[table]!.rows) {
          if (isFirstRow) {
            isFirstRow = false;
            continue;
          }
          String name = row[0]?.value?.toString() ?? "Unknown Name";
          String category = row[1]?.value?.toString() ?? "Unknown Category";
          locations.add(Location(name: name, category: category));
        }
      }
      return locations;
    } catch (e) {
      print(e);
      return [];
    }
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
                color: Color.fromARGB(255, 235, 231, 233),
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _removeLocation(int index) {
    setState(() {
      selectedLocations.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itinerary', style: TextStyle(fontSize: 30)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            Column(
              children: selectedLocations.asMap().entries.map((entry) {
                int idx = entry.key;
                Location? location = entry.value;

                List<Location> availableLocations = locations
                    .where((loc) =>
                        !selectedLocations.contains(loc) || loc == location)
                    .toList();

                return Column(
                  children: [
                    LocationDropdown(
                      key: UniqueKey(),
                      locations: availableLocations,
                      selectedLocation: location,
                      onChanged: (Location? newValue) {
                        setState(() {
                          selectedLocations[idx] = newValue;
                        });
                      },
                      showRemoveButton: selectedLocations.length > 1,
                      onRemove: () =>
                          _removeLocation(idx), // Passing the removal method
                    ),
                    const SizedBox(height: 15), // Spacer between dropdowns
                  ],
                );
              }).toList(),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  selectedLocations.add(null);
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _saveButton(context),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationDropdown extends StatelessWidget {
  final List<Location> locations;
  final Location? selectedLocation;
  final ValueChanged<Location?>? onChanged;
  final bool showRemoveButton;
  final VoidCallback? onRemove;

  const LocationDropdown({
    Key? key,
    required this.locations,
    this.selectedLocation,
    this.onChanged,
    this.showRemoveButton = false,
    this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            width: 800,
            height: 60,
            child: DropdownButton<Location>(
              isExpanded: true,
              value: selectedLocation,
              hint: const Text('Choose Destination/Location',
                  style: TextStyle(fontSize: 30)),
              onChanged: onChanged,
              items: [
                DropdownMenuItem<Location>(
                  value: null,
                  child: const Text('Choose Destination/Location',
                      style: TextStyle(fontSize: 30)),
                ),
                ...locations
                    .map<DropdownMenuItem<Location>>((Location location) {
                  return DropdownMenuItem<Location>(
                    value: location,
                    child: Text('${location.name} - ${location.category}',
                        style: const TextStyle(fontSize: 30)),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        if (showRemoveButton)
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: onRemove,
          ),
      ],
    );
  }
}
