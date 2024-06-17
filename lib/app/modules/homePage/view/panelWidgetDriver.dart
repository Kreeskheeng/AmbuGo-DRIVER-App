import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
                text: 'Emergency',
                color: const Color(0xFFFF0000),
                size: Dimensions.font26 * 1.5,
              ),
            ),
            SizedBox(
              height: Dimensions.height10,
            ),
            Center(child: BigText(text: 'Patient Requests')),
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
                    final oxygenNeed = additionalData['Is Oxygen neeeded'] ?? 'Oxygen Need Not Set Yet!';

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                BigText(
                                  text: 'PATIENT NAME: ',
                                  color: const Color(0xFFFF0000),
                                  size: Dimensions.font15,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: BigText(
                                    maxLines: null,
                                    text: userName,
                                    size: Dimensions.font15,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              children: [
                                BigText(
                                  text: 'PREFERRED Hosp.: ',
                                  color: const Color(0xFFFF0000),
                                  size: Dimensions.font15,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: BigText(
                                    maxLines: null,
                                    text: preferredHospital,
                                    size: Dimensions.font15,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: Dimensions.height15,
                            ),
                            Row(
                              children: [
                                BigText(
                                  text: 'OXYGEN NEED: ',
                                  color: const Color(0xFFFF0000),
                                  size: Dimensions.font15,
                                ),
                                SizedBox(
                                  width: Dimensions.width15,
                                ),
                                Expanded(
                                  child: BigText(
                                    maxLines: null,
                                    text: oxygenNeed,
                                    size: Dimensions.font15,
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
                                    double currentLat =
                                        controller.currentLocation?.latitude ?? 0.0;
                                    double currentLng =
                                        controller.currentLocation?.longitude ?? 0.0;

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
                                      'rideKey': SPController()
                                          .getUserId()
                                          .toString()
                                          .substring(0, 6),
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
}
