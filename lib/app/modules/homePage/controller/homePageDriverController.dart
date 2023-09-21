import 'dart:async';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:last_minute_driver/app/data/repo/distance_repo.dart';


class HomepageDriverController extends GetxController {
  Completer<GoogleMapController> mapControl = Completer();
  Geolocator geolocator = Geolocator();
  Position? currentLocation;
  late bool _serviceEnabled;
  DistanceRepository repo = DistanceRepository();

  //late Position currentLocation = Position(
   // latitude: 0.334873, // Default latitude
   // longitude: 32.567497, // Default longitude
   // timestamp: DateTime.now(), // Default timestamp
   // accuracy: 0.0, // Default accuracy
   // altitude: 0.0, // Default altitude
    //heading: 0.0, // Default heading
    //speed: 0.0, // Default speed
   // speedAccuracy: 0.0, // Default speed accuracy
  //);



  late LatLng selectedLatLng;
  //late LatLng selectedLatLng;
  StreamController<LatLng> latLng = StreamController.broadcast();
  late List<geocoding.Placemark> placemarks;
  RxString? selectedAddress = "Loading".obs;

  RxString estimatedTime = '15 mins'.obs;
  RxBool isLoading = false.obs;


  //Future<void> initCurrentLocation() async {
  //  try {
  //    LocationPermission permission = await Geolocator.requestPermission();
   //   if (permission == LocationPermission.denied ||
   //       permission == LocationPermission.deniedForever) {
        // Handle permission denied cases
    //    return;
    //  }

    //  Position position = await Geolocator.getCurrentPosition();
    // currentLocation = position; // Update the currentLocation here
   // } catch (e) {
   //   isLoading.value = false;
      // Handle exceptions
   // }
  //}

  //late PermissionStatus _permissionGranted;
  //location
  TextEditingController enterLocation = TextEditingController();

  onChangedselectedAddress(String addressLocation) {
    selectedAddress!(addressLocation);
  }


  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    // Convert distance to kilometers
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
    print('Updating ambulance location in Firestore...');

    double distanceToDestination = calculateDistance(
      currentLocation!.latitude!,
      currentLocation!.longitude!,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );

    // Calculate the estimated time using your logic
    Duration estimatedTime = calculateEstimatedTime(distanceToDestination);
    // Calculate the ride fare using the current and destination locations, and the estimated time
    double rideFare = calculateRideFare(
      currentLocation!.latitude!,
      currentLocation!.longitude!,
      destinationLocation.latitude,
      destinationLocation.longitude,
      estimatedTime,
    );

    await FirebaseFirestore.instance.collection('bookings').doc(bookedPatientId).update({
      'ambulanceLocation': {
        't': estimatedTime.toString(),
        'distance': distanceToDestination,
        'lat': currentLocation!.latitude!,
        'lng': currentLocation!.longitude!,
      },
      'rideFare': rideFare, // Push the calculated ride fare to Firestore
    });

    print('Ambulance location updated successfully.');
  }

  Duration calculateEstimatedTime(double distanceInKm) {
    double averageSpeedKmPerHour = 60; // Example average speed in km/h

    double estimatedTimeInHours = distanceInKm / averageSpeedKmPerHour;
    int estimatedHours = estimatedTimeInHours.floor();
    int estimatedMinutes = ((estimatedTimeInHours - estimatedHours) * 60).round();

    // Correct the case where rounding might cause estimatedMinutes to exceed 59
    if (estimatedMinutes >= 60) {
      estimatedHours++;
      estimatedMinutes -= 60;
    }

    return Duration(minutes: estimatedMinutes);
  }





  //nextPage
  final _patientAssigned = false.obs;
  final _bookedPatientId = ''.obs;
  String get bookedPatientId => _bookedPatientId.value;
  bool get patientAssigned => _patientAssigned.value;
  DocumentSnapshot<Map<String, dynamic>>? document;
  onAmbulanceBooked(bool x, String bookedPatient)async {

    if(x==false){
      _patientAssigned(x);
      _bookedPatientId(bookedPatient);
      polylineCoordinates.clear();
      update();
    }
    if(x=true&&bookedPatient!=''){
      print(bookedPatient+'---');
      _patientAssigned(x);
      _bookedPatientId(bookedPatient);
      document=await FirebaseFirestore.instance.collection('users').doc(bookedPatient).get();
      update();
    }


  }

  @override
  void onReady() {
    getPermission();
    getCurrentLocation();
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

      GoogleMapController googleMapController = await mapControl.future; // Use mapControl instead of mapController
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
      print("Error fetching location: $e");
      isLoading.value = false; // Handle error by stopping loading state
      update(); // Notify UI to update loading state
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
    polylineCoordinates.clear();
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyBu60-4S559TmDx6ky9KTJ5Pl2VD0qQ4O8',
        PointLatLng(
            destinationLocation.latitude, destinationLocation.longitude),
        PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!));

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        update();
      }
    }
  }

  final _destinationLocation = const LatLng(0, 0).obs;
  LatLng get destinationLocation => _destinationLocation.value;

  final _time=''.obs;
  String get time=>_time.value;


  void updateTime() {
    // Get the current time and update the reactive variable
    DateTime currentTime = DateTime.now();
    _time.value = currentTime.toString(); // You can format the time as needed
  }




  onGetPatientLocation(double lat, double lng) async {
    _destinationLocation(LatLng(lat, lng));
    getPolyPoints();
    onUpdateLocationFirebase();

    // Calculate estimated time and update the reactive variable
    double distanceToDestination = calculateDistance(
      currentLocation!.latitude!,
      currentLocation!.longitude!,
      destinationLocation.latitude,
      destinationLocation.longitude,
    );
    Duration estimatedTime = calculateEstimatedTime(distanceToDestination);
    _time.value = estimatedTime.toString();
  }

}