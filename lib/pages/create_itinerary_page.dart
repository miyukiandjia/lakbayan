import 'package:flutter/material.dart';
import 'package:lakbayan/pages/overview_itinerary_page.dart';
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';

class Location {
  final String name;
  final String category;

  Location({required this.name, required this.category});
}

class ItineraryDay {
  String name;
  DateTime date;
  List<Location?> locations;

  ItineraryDay(
      {required this.name, required this.date, required this.locations});
}

class CreateItineraryPage extends StatefulWidget {
  const CreateItineraryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateItineraryPageState createState() => _CreateItineraryPageState();
}

class _CreateItineraryPageState extends State<CreateItineraryPage> {
  List<Location> allLocations = [];
  List<ItineraryDay> days = [
    ItineraryDay(name: "", date: DateTime.now(), locations: [null])
  ];
  final TextEditingController _itineraryNameController = TextEditingController();

  Future<void> _selectDate(BuildContext context, ItineraryDay day) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: day.date,
      firstDate: DateTime(2000, 1),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != day.date) {
      setState(() {
        day.date = pickedDate;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    readExcelData().then((loadedLocations) {
      setState(() {
        allLocations = loadedLocations;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Itinerary', style: TextStyle(fontSize: 50)),
      ),
      body: Padding(
  padding: const EdgeInsets.all(10.0),
  child: Column(
    children: [
      // This is the global Itinerary Name field.
      Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: TextField(
          controller: _itineraryNameController,
          decoration: const InputDecoration(labelText: "Itinerary Name"),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: days.length + 1,
          itemBuilder: (context, index) {
            if (index == days.length) {
              return IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    days.add(ItineraryDay(
                        name: "", date: DateTime.now(), locations: [null]));
                  });
                },
              );
            }
            return _buildDayCard(days[index], index);
          },
        ),
      ),
    ],
  ),
),
     floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OverviewItinerary(
              days: days,
              itineraryName: _itineraryNameController.text,  // Pass the itinerary name to the next page
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildDayCard(ItineraryDay day, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            if (index > 0)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      days.removeAt(index);
                    });
                  },
                ),
              ),
            Text('Day ${index + 1}',
                style:
                    const TextStyle(fontSize: 50, fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(labelText: "Day Name"),
              onChanged: (value) {
                day.name = value;
              },
            ),
            ElevatedButton(
              onPressed: () => _selectDate(context, day),
              child: Text(
                "${day.date.toLocal()}"
                    .split(' ')[0], // This displays the chosen date
                style: const TextStyle(fontSize: 18),
              ),
            ),
            ...day.locations.asMap().entries.map((entry) {
              int idx = entry.key;
              Location? location = entry.value;

              List<Location> availableLocations = allLocations
                  .where(
                      (loc) => !day.locations.contains(loc) || loc == location)
                  .toList();

              return LocationDropdown(
                locations: availableLocations,
                selectedLocation: location,
                onChanged: (Location? newValue) {
                  setState(() {
                    day.locations[idx] = newValue;
                  });
                },
                showRemoveButton: day.locations.length > 1,
                onRemove: () {
                  setState(() {
                    day.locations.removeAt(idx);
                  });
                },
              );
            }).toList(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  day.locations.add(null);
                });
              },
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
  final ValueChanged<Location?> onChanged;
  final bool showRemoveButton;
  final VoidCallback onRemove;

  const LocationDropdown({
    super.key,
    required this.locations,
    required this.selectedLocation,
    required this.onChanged,
    required this.showRemoveButton,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButton<Location>(
            isExpanded: true,
            value: selectedLocation,
            hint: const Text('Choose Destination/Location',
                style: TextStyle(fontSize: 50)),
            onChanged: onChanged,
            items: [
              const DropdownMenuItem<Location>(
                value: null,
                child: Text('Choose Destination/Location',
                    style: TextStyle(fontSize: 50)),
              ),
              ...locations.map<DropdownMenuItem<Location>>((Location location) {
                return DropdownMenuItem<Location>(
                  value: location,
                  child: Text('${location.name} - ${location.category}',
                      style: const TextStyle(fontSize: 50)),
                );
              }).toList(),
            ],
          ),
        ),
        if (showRemoveButton)
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
      ],
    );
  }
}
