import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('定位服务没有开启，可以在系统设置里打开，或手动选择城市');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('没有拿到定位权限，也可以手动选择城市');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException('定位权限已被永久关闭，请到系统设置中开启，或手动选择城市');
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationServiceDisabledException {
      throw LocationException('定位服务没有开启，可以手动选择城市');
    } catch (_) {
      throw LocationException('暂时定不到位，可以手动选择城市');
    }
  }
}
