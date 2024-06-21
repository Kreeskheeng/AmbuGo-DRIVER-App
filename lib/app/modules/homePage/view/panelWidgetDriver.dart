import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:last_minute_driver/app/data/repo/distance_repo.dart';
import 'package:last_minute_driver/helper/snackbar.dart';
import 'package:last_minute_driver/utils/colors.dart';
import '../../../../helper/shared_preference.dart';
import '../../../../utils/dimensions.dart';
import '../../../../widgets/big_text.dart';
import '../../../../widgets/button.dart';
import '../controller/homePageDriverController.dart';

class PanelWidgetDriver extends GetView<HomepageDriverController> {
  DistanceRepository repo = DistanceRepository();
  static const route = '/panelWidget';
  var data = [];
  ScrollController scrollController;

  PanelWidgetDriver({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Dimensions.width15, Dimensions.height10, Dimensions.width15, Dimensions.height30),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: Dimensions.height10,
            ),
            Align(
              alignment: Alignment.center,
              child: BigText(
                text: 'BOOKINGS',
                color: const Color(0xFFFF0000),
                size: Dimensions.font26 * 1.39,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: Dimensions.height10,
            ),
            SizedBox(
              height: Dimensions.height20,
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: ((context, snapshot) {
                data.clear();
                if (snapshot.hasData) {
                  final bookings = snapshot.data!.docs;
                  for (var booking in bookings) {
                    final bookingData = booking.data() as Map<String, dynamic>;
                    final ambulanceStatus = bookingData['ambulanceStatus'];
                    final declinedDrivers = bookingData['declinedDrivers'] ?? [];

                    // Combine conditions
                    if (ambulanceStatus == 'not assigned' && !declinedDrivers.contains(SPController().getUserId())) {
                      data.add(booking);
                    }
                  }
                }

                return Column(
                  children: data.map<Widget>((booking) {
                    final bookingData = booking.data() as Map<String, dynamic>;
                    final userName = bookingData['userName'];
                    final userId = booking.id;
                    final additionalData = bookingData['additionalData'] as Map<String, dynamic>;
                    final preferredHospital = additionalData['preferredHospital'] ?? 'Preferred Hospital Not Set Yet!';
                    final oxygenNeed = additionalData['Is Oxygen needed'] ?? 'Oxygen Need Not Set Yet!';

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Add the image above the notification text
                            Align(
                              alignment: Alignment.center,
                              child: Image.asset(
                                'assets/images/ambugo.jpg', // Path to your asset image
                                height: 55, // Adjust the height as needed
                                width: 55,  // Adjust the width as needed
                              ),
                            ),
                            SizedBox(
                              height: Dimensions.height10,
                            ),
                            // Heading for New Request Notification
                            Align(
                              alignment: Alignment.center,
                              child: BigText(
                                text: 'New Ambulance Request',
                                color: Colors.lightGreen[900],
                                size: Dimensions.font26 * 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              children: [
                                // Custom Shape for Patient's Profile Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                  child: Image.asset(
                                    'assets/images/pname.png',
                                    height: 60, // Increased height
                                    width: 45,  // Increased width
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(width: 15),
                                BigText(
                                  text: 'Name:',
                                  color: Colors.black,
                                  size: Dimensions.font20,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: BigText(
                                    maxLines: null,
                                    text: userName,
                                    size: Dimensions.font15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                  child: Image.asset(
                                    'assets/images/location.png',
                                    height: 65, // Increased height
                                    width: 50,  // Increased width
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                BigText(
                                  text: 'Location:',
                                  color: Colors.black,
                                  size: Dimensions.font20,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: FutureBuilder<String>(
                                    future: _getAreaNameFromCoordinates(
                                      bookingData['location']['lat'],
                                      bookingData['location']['lng'],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return BigText(
                                          text: 'Loading...',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      } else if (snapshot.hasError) {
                                        return BigText(
                                          text: 'Error',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      } else {
                                        return BigText(
                                          maxLines: null,
                                          text: snapshot.data ?? 'Unknown location',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                  child: Image.asset(
                                    'assets/images/distance1.png',
                                    height: 50, // Increased height
                                    width: 50,  // Increased width
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                BigText(
                                  text: 'Distance:',
                                  color: Colors.black,
                                  size: Dimensions.font20,
                                  fontWeight: FontWeight.bold,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: FutureBuilder<double>(
                                    future: _calculateDistance(
                                      controller.currentLocation?.latitude ?? 0.0,
                                      controller.currentLocation?.longitude ?? 0.0,
                                      bookingData['location']['lat'],
                                      bookingData['location']['lng'],
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return BigText(
                                          text: 'Calculating...',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      } else if (snapshot.hasError) {
                                        return BigText(
                                          text: 'Error',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      } else {
                                        return BigText(
                                          maxLines: null,
                                          text: '${snapshot.data?.toStringAsFixed(2) ?? 'Unknown'} km',
                                          size: Dimensions.font15,
                                          fontWeight: FontWeight.bold,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Button(
                                  on_pressed: () async {
                                    double currentLat = controller.currentLocation?.latitude ?? 0.0;
                                    double currentLng = controller.currentLocation?.longitude ?? 0.0;

                                    double destinationLat = bookingData['location']['lat'];
                                    double destinationLng = bookingData['location']['lng'];

                                    double dist = Geolocator.distanceBetween(
                                        currentLat, currentLng, destinationLat, destinationLng);

                                    String bookedPatient = userId;

                                    FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(bookedPatient)
                                        .update({
                                      'ambulanceDetails': {
                                        'driverId': SPController().getUserId(),
                                      },
                                      'ambulanceStatus': 'assigned',
                                      'rideKey': SPController().getUserId().toString().substring(0, 6),
                                    });

                                    controller.onAmbulanceBooked(true, bookedPatient);
                                  },
                                  text: 'Accept',
                                  textColor: AppColors.white,
                                  radius: Dimensions.radius20 * 2,
                                  width: Dimensions.width40 * 4,
                                  height: Dimensions.height40 * 1.2,
                                  color: AppColors.pink,
                                ),
                                Button(
                                  on_pressed: () {
                                    FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(userId)
                                        .update({
                                      'declinedDrivers': FieldValue.arrayUnion([SPController().getUserId()]),
                                    });
                                    controller.onAmbulanceBooked(true, '');
                                  },
                                  text: 'Decline',
                                  textColor: AppColors.pink,
                                  radius: Dimensions.radius20 * 2,
                                  width: Dimensions.width40 * 4,
                                  height: Dimensions.height40 * 1.2,
                                  color: AppColors.white,
                                  boxBorder: Border.all(width: 2, color: AppColors.pink),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );


                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getAreaNameFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Customize this to return the desired parts of the address
        return ' ${place.subLocality ?? ''}${place.locality ?? ''}, ${place.country ?? ''}';
      }
    } catch (e) {
      print('Error: $e');
    }
    return 'Unknown location';
  }
  // Function to calculate the distance
  Future<double> _calculateDistance(double startLat, double startLng, double endLat, double endLng) async {
    double distance = Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // Convert to kilometers
    return distance;
  }

}
