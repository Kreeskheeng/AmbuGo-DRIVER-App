import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:last_minute_driver/app/data/repo/distance_repo.dart';
import 'package:shimmer/shimmer.dart';

class HomepageDriverController extends GetxController {
  Completer<GoogleMapController> mapControl = Completer();
  Geolocator geolocator = Geolocator();
  late bool _serviceEnabled;
  DistanceRepository repo = DistanceRepository();

  late Position currentLocation = Position(
    latitude: 0.334873, // Default latitude
    longitude: 32.567497, // Default longitude
    timestamp: DateTime.now(), // Default timestamp
    accuracy: 0.0, // Default accuracy
    altitude: 0.0, // Default altitude
    heading: 0.0, // Default heading
    speed: 0.0, // Default speed
    speedAccuracy: 0.0, // Default speed accuracy
  );

  late LatLng selectedLatLng;
  StreamController<LatLng> latLng = StreamController.broadcast();
  late List<geocoding.Placemark> placemarks;
  RxString? selectedAddress = "Loading".obs;
  RxString estimatedTime = '15 mins'.obs;
  RxBool isLoading = false.obs;

  TextEditingController enterLocation = TextEditingController();

  void onChangedselectedAddress(String addressLocation) {
    selectedAddress!(addressLocation);
  }

  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    double distanceInKm = distanceInMeters / 1000;
    return distanceInKm;
  }

  double calculateRideFare(double startLat, double startLng, double endLat, double endLng, Duration rideDuration) {
    double baseFareUGX = 2000; // Example base fare in Ugandan Shillings
    double distanceRateUGX = 500; // Example rate per kilometer in Ugandan Shillings
    double timeRateUGX = 100; // Example rate per minute in Ugandan Shillings

    double distanceInKm = calculateDistance(startLat, startLng, endLat, endLng);
    double distanceFareUGX = distanceInKm * distanceRateUGX;
    double timeFareUGX = rideDuration.inMinutes * timeRateUGX;
    double totalFareUGX = baseFareUGX + distanceFareUGX + timeFareUGX;

    return totalFareUGX.roundToDouble(); // Round to the nearest whole number
  }

  Future<void> onUpdateLocationFirebase() async {


    double distanceToDestination = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    Duration estimatedTime = calculateEstimatedTime(distanceToDestination);
    double rideFare = calculateRideFare(
      currentLocation.latitude,
      currentLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
      estimatedTime,
    );

    await FirebaseFirestore.instance.collection('bookings').doc(bookedPatientId).update({
      'ambulanceLocation': {
        't': estimatedTime.toString(),
        'distance': distanceToDestination,
        'lat': currentLocation.latitude,
        'lng': currentLocation.longitude,
      },
      'rideFare': rideFare, // Push the calculated ride fare to Firestore
    });


  }

  Duration calculateEstimatedTime(double distanceInKm) {
    double averageSpeedKmPerHour = 60; // Example average speed in km/h
    double estimatedTimeInHours = distanceInKm / averageSpeedKmPerHour;
    int estimatedHours = estimatedTimeInHours.floor();
    int estimatedMinutes = ((estimatedTimeInHours - estimatedHours) * 60).round();

    if (estimatedMinutes >= 60) {
      estimatedHours++;
      estimatedMinutes -= 60;
    }

    return Duration(hours: estimatedHours, minutes: estimatedMinutes);
  }

  final _patientAssigned = false.obs;
  final _bookedPatientId = ''.obs;
  String get bookedPatientId => _bookedPatientId.value;
  bool get patientAssigned => _patientAssigned.value;
  DocumentSnapshot<Map<String, dynamic>>? document;

  onAmbulanceBooked(bool x, String bookedPatient) async {
    if (x == false) {
      _patientAssigned(x);
      _bookedPatientId(bookedPatient);
      polylineCoordinates.clear();
      update();
    }
    if (x == true && bookedPatient != '') {
      print(bookedPatient + '---');
      _patientAssigned(x);
      _bookedPatientId(bookedPatient);
      document = await FirebaseFirestore.instance.collection('users').doc(bookedPatient).get();
      update();
    }
  }

  @override
  void onReady() {
    getPermission();
    getCurrentLocation();
    updateTime();
    Timer.periodic(Duration(seconds: 1), (timer) {
      updateTime();
    });
    super.onReady();
  }

  void getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Location Denied once');
          return;
        }
      }

      _serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      update();

      GoogleMapController googleMapController = await mapControl.future;
      Geolocator.getPositionStream().listen((newLoc) {
        currentLocation = newLoc;
        googleMapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(newLoc.latitude, newLoc.longitude))));
        update();

        if (patientAssigned) {
          getPolyPoints();
          onUpdateLocationFirebase();
        }
      });
    } catch (e) {

      isLoading.value = false;
      update();
    }
  }

  void getPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location Denied once');
      }
    }
  }

  List<LatLng> polylineCoordinates = [];

  void getPolyPoints() async {
    try {
      polylineCoordinates.clear();
      PolylinePoints polylinePoints = PolylinePoints();
      print('Fetching route points...');
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyBtFdD1MNJWvqevGFtv5KgpHcgQXBusi4E',
        PointLatLng(destinationLocation.latitude, destinationLocation.longitude),
        PointLatLng(currentLocation.latitude, currentLocation.longitude),
      );

      if (result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
        update();
      }
    } catch (e) {

    }
  }

  final _destinationLocation = const LatLng(0, 0).obs;
  LatLng get destinationLocation => _destinationLocation.value;

  final _time = ''.obs;
  String get time => _time.value;

  void updateTime() {
    DateTime currentTime = DateTime.now();
    _time.value = currentTime.toString();
  }

  onGetPatientLocation(double lat, double lng) async {
    _destinationLocation(LatLng(lat, lng));
    getPolyPoints();
    onUpdateLocationFirebase();

    double distanceToDestination = calculateDistance(
      currentLocation.latitude,
      currentLocation.longitude,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );
    Duration estimatedTime = calculateEstimatedTime(distanceToDestination);
    _time.value = estimatedTime.toString();
  }
}

class CustomShimmer extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const CustomShimmer.rectangular({
    Key? key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(),
        super(key: key);

  const CustomShimmer.circular({
    Key? key,
    required this.width,
    required this.height,
  }) : shapeBorder = const CircleBorder(),
        super(key: key);

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: Colors.grey[300]!,
        shape: shapeBorder,
      ),
    ),
  );
}
