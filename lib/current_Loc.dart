import 'package:geolocator/geolocator.dart';

Future<Position?> getCurrentLocation() async {
  try {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return null;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return null;
      }
    }

    return await Geolocator.getCurrentPosition();
  } catch (e) {
    print(e);
    return null;
  }
}
