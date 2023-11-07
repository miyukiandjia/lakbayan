import 'dart:math';
import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:lakbayan/constants.dart';

class EnhancedSimulatedAnnealing {
  final directions = gmaps.GoogleMapsDirections(apiKey: API_KEY);
  Map<String, double> distanceCache = {};

  double euclideanDistance(Location a, Location b) {
    return sqrt(
        pow(a.latitude - b.latitude, 2) + pow(a.longitude - b.longitude, 2));
  }

  Future<double> totalDistance(List<Location> locations) async {
    double distance = 0.0;
    for (int i = 0; i < locations.length - 1; i++) {
      String cacheKey =
          "${locations[i].latitude},${locations[i].longitude}-${locations[i + 1].latitude},${locations[i + 1].longitude}";
      if (distanceCache.containsKey(cacheKey)) {
        distance += distanceCache[cacheKey]!;
      } else {
        gmaps.DirectionsResponse response = await directions.directions(
          gmaps.Location(
              lat: locations[i].latitude, lng: locations[i].longitude),
          gmaps.Location(
              lat: locations[i + 1].latitude, lng: locations[i + 1].longitude),
          travelMode: gmaps.TravelMode.driving,
        );
        if (response.status == 'OK' && response.routes.isNotEmpty) {
          double routeDistance =
              (response.routes[0].legs[0].distance.value).toDouble();
          distance += routeDistance;
          distanceCache[cacheKey] = routeDistance;
        }
      }
    }
    return distance;
  }

  List<Location> getNeighbor(List<Location> locations) {
    List<Location> newLocations = List.from(locations);
    int a = (newLocations.length * Random().nextDouble()).toInt();
    int b = (newLocations.length * Random().nextDouble()).toInt();
    while (b == a) {
      b = (newLocations.length * Random().nextDouble()).toInt();
    }
    Location temp = newLocations[a];
    newLocations[a] = newLocations[b];
    newLocations[b] = temp;
    return newLocations;
  }

  List<Location> perturbRoute(List<Location> currentRoute) {
    List<Location> newRoute = List.from(currentRoute);
    Random rand = Random();

    int index1 = rand.nextInt(newRoute.length);
    int index2 = rand.nextInt(newRoute.length);
    while (index1 == index2) {
      index2 = rand.nextInt(newRoute.length);
    }

    Location temp = newRoute[index1];
    newRoute[index1] = newRoute[index2];
    newRoute[index2] = temp;

    return newRoute;
  }

  Future<double> calculateRouteCost(List<Location> route) async {
    double cost = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      cost += euclideanDistance(route[i], route[i + 1]);
    }
    return cost;
  }

  Future<List<Location>> simulatedAnnealingOptimization(
      List<Location> initialRoute,
      {bool useReheat = false}) async {
    // ignore: avoid_print
    print("Starting simulated annealing optimization...");

    List<Location> currentRoute = List.from(initialRoute);
    List<Location> bestRoute = List.from(initialRoute);

    double currentCost = await calculateRouteCost(currentRoute);
    double bestCost = currentCost;

    double temperature = 1.0;
    double coolingRate = 0.995;

    Random rand = Random();

    int iteration = 0;
    int maxIterations = 10; // Setting the maximum iterations to 10

    while (temperature > 0.01 && iteration < maxIterations) {
      List<Location> newRoute = perturbRoute(List.from(currentRoute));
      double newCost = await calculateRouteCost(newRoute);

      if (newCost < currentCost ||
          rand.nextDouble() < exp((currentCost - newCost) / temperature)) {
        currentRoute = newRoute;
        currentCost = newCost;

        if (currentCost < bestCost) {
          bestRoute = currentRoute;
          bestCost = currentCost;
        }
      }

      temperature *= coolingRate;

      // Reheat logic, which is used only if useReheat is set to true
      if (useReheat && temperature < 0.01) {
        temperature = 0.3; // Reheat to 30% of the initial temperature
      }

      iteration++;
    }

    // ignore: avoid_print
    print(
        "Finished optimization after $iteration iterations with cost: $currentCost");
    return bestRoute;
  }

  Future<List<Location>> generateOptimizedRoute(
      List<Location> initialRoute) async {
    return await simulatedAnnealingOptimization(initialRoute);
  }
}

class Location {
  final String name;
  final String category;
  final double latitude; // Add latitude field
  final double longitude; // Add longitude field

  Location({
    required this.name,
    required this.category,
    required this.latitude, // Initialize latitude
    required this.longitude, // Initialize longitude
  });

  @override
  String toString() {
    return 'Location(name: $name, category: $category, latitude: $latitude, longitude: $longitude)';
  }
}
