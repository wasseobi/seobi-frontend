import 'package:geolocator/geolocator.dart';

/// GPS 위치 정보를 관리하는 레포지토리 클래스
class GpsRepository {
  /// 싱글톤 인스턴스
  static final GpsRepository _instance = GpsRepository._internal();

  /// 내부 생성자
  GpsRepository._internal();

  /// 공장 생성자
  factory GpsRepository() => _instance;

  /// 위치 서비스가 활성화되어 있는지 확인
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// 위치 권한 확인
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// 위치 권한 요청
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// 현재 위치 가져오기
  ///
  /// 위치 서비스가 활성화되어 있지 않거나 권한이 거부된 경우 에러를 반환합니다.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다.');
    }

    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        '위치 권한이 영구적으로 거부되어 권한을 요청할 수 없습니다. 설정에서 권한을 활성화해주세요.',
      );
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 마지막으로 알려진 위치 가져오기
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  /// 위치 업데이트를 지속적으로 수신하는 스트림 얻기
  Stream<Position> getPositionStream({
    int distanceFilter = 10,
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// 두 위치 간의 거리 계산 (미터 단위)
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// 두 위치 간의 방향 계산 (도 단위)
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
