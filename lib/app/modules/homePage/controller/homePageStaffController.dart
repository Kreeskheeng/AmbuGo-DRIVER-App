
import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomepageStaffController extends GetxController {
  RxBool isLoading = true.obs;
  Geolocator geolocator = Geolocator();
  late Position? currentLocation;
  late bool _serviceEnabled;
  late StreamController<LatLng> latLng = StreamController();

  //location
  TextEditingController enterLocation = TextEditingController();
  final selectedAddress =
      'kampala city, Something Something, SomeCity, '.obs;
  onChangedselectedAddress(String addressLocation) {
    selectedAddress(addressLocation);
  }

 
  final _patientAssigned = false.obs;
  bool get patientAssigned => _patientAssigned.value;
  final _patientId=''.obs;
  String get patientId=>_patientId.value;

  DocumentSnapshot<Map<String, dynamic>>? document;
  onAmbulanceBooked(bool x,String y)async {
    if(x==false){
      polylineCoordinates.clear();
      _patientAssigned(x);
    _patientId(y);
      update();
    }
    if(x=true&&y!=''){
      _patientAssigned(x);
    _patientId(y);
      document=await FirebaseFirestore.instance.collection('users').doc(y).get();
      
      update();
    }
    
  }

  @override
  void onInit() {
    getPermission();
    getCurrentLocation();
    super.onInit();
  }

  void getCurrentLocation() async {
    try {
      currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update ambulance's location in Firestore
      await FirebaseFirestore.instance.collection('ambulances').doc('ambulanceLocation').update({
        'latitude': currentLocation!.latitude,
        'longitude': currentLocation!.longitude,
      });

      log("Got Current Location");
      isLoading.value = false;
    } catch (e) {
      log("Error getting current location: $e");
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

    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) {
      debugPrint('Location services are disabled');
    }
  }

  List<LatLng> polylineCoordinates = [];
  void getPolyPoints() async {
    polylineCoordinates.clear();
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyBu60-4S559TmDx6ky9KTJ5Pl2VD0qQ4O8',
        PointLatLng(
            patientLocation.latitude, patientLocation.longitude),
        PointLatLng(driverLocation.latitude, driverLocation.longitude));

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        update();
      }
    }
  }




  final _patientLocation = const LatLng(0, 0).obs;
  LatLng get patientLocation => _patientLocation.value;
  final _driverLocation = const LatLng(0, 0).obs;
  LatLng get driverLocation => _driverLocation.value;

  final _time=''.obs;
  String get time=>_time.value;

  onGetPatientLocation(double patientLat, double patientLng, double driverLat, double driverLng, String estimatedTime) {
    _patientLocation(LatLng(patientLat, patientLng));
    _driverLocation(LatLng(driverLat, driverLng));
    _time(estimatedTime);
    getPolyPoints();
    // onUpdateLocationFirebase();
  }

}
