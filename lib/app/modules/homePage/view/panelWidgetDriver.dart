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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Dimensions.width15, Dimensions.height10, Dimensions.width15, Dimensions.height30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: Dimensions.height30,
          ),
          Align(
            alignment: Alignment.center,
            child: BigText(
              text: 'Emergency',
              color: const Color(0xFFFF0000),
              size: Dimensions.font26 * 1.4,
            ),
          ),
          SizedBox(
            height: Dimensions.height30,
          ),
          Center(child: BigText(text: 'Patient Located')),
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
                  final declinedDrivers = bookingData['declinedDrivers'] ?? [];

                  // Check if the current driver has already declined the request
                  if (!declinedDrivers.contains(SPController().getUserId())) {
                    data.add(booking);
                  }
                }
              }

              return SizedBox(
                height: Dimensions.height40 * 3,
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final bookingData = data[index].data() as Map<String, dynamic>;
                    final userName = bookingData['userName'];
                    final userId = data[index].id;

                    return Column(
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
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(userId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final documentData =
                                    snapshot.data!.data() as Map<String, dynamic>;
                                    final additionalData =
                                    documentData['additionalData'] as Map<String, dynamic>;
                                    final preferredHospital =
                                        additionalData['preferredHospital'] ??
                                            'Preferred Hospital Not Set Yet!';

                                    return BigText(
                                      maxLines: null,
                                      text: preferredHospital,
                                      size: Dimensions.font15,
                                    );
                                  } else {
                                    return Text(
                                        'Loading...'); // Show loading indicator
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
                            BigText(
                              text: 'OXYGEN NEED: ',
                              color: const Color(0xFFFF0000),
                              size: Dimensions.font15,
                            ),
                            SizedBox(
                              width: Dimensions.width15,
                            ),
                            Expanded(
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(userId)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final documentData =
                                    snapshot.data!.data() as Map<String, dynamic>;
                                    final additionalData =
                                    documentData['additionalData'] as Map<String, dynamic>;
                                    final oxygenNeed =
                                        additionalData['Is Oxygen neeeded'] ??
                                            'Oxygen Need Not Set Yet!';

                                    return BigText(
                                      maxLines: null,
                                      text: oxygenNeed,
                                      size: Dimensions.font15,
                                    );
                                  } else {
                                    return Text(
                                        'Loading...'); // Show loading indicator
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
                                double currentLat =
                                    controller.currentLocation?.latitude ?? 0.0;
                                double currentLng =
                                    controller.currentLocation?.longitude ?? 0.0;

                                double destinationLat = data[index]['location']['lat'];
                                double destinationLng = data[index]['location']['lng'];

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
                                  // Instead of changing ambulanceStatus, add the current driver to declinedDrivers list
                                  'declinedDrivers': FieldValue.arrayUnion([SPController().getUserId()]),
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
                              width: Dimensions.width40 * 2,
                              height: Dimensions.height40 * 1.2,
                              color: AppColors.pink,
                            ),
                            Button(
                              on_pressed: () {
                                // No need to update ambulanceStatus here
                                // Instead, add the current driver to declinedDrivers list
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
                              width: Dimensions.width40 * 2,
                              height: Dimensions.height40 * 1.2,
                              color: AppColors.white,
                              boxBorder: Border.all(width: 2, color: AppColors.pink),
                            ),
                          ],
                        ),

                        SizedBox(
                          height: Dimensions.height15,
                        ),
                      ],
                    );
                  },
                ),
              );
            }),
          ),
          SizedBox(
            height: Dimensions.height20,
          ),
        ],
      ),
    );
  }
}
