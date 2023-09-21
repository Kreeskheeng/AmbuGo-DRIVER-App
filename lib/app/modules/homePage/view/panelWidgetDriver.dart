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
                  if (booking['ambulanceStatus'] == 'not assigned') {
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
                                    .doc(data[index]['userId'])
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
                                    .doc(data[index]['userId'])
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

                        // Additional Rows or Widgets can be added here for other data
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Button(
                on_pressed: () async {
                  if (data.isNotEmpty) {
                    double currentLat =
                        controller.currentLocation?.latitude ?? 0.0;
                    double currentLng =
                        controller.currentLocation?.longitude ?? 0.0;

                    List<double> distances = [];
                    for (var booking in data) {
                      double destinationLat = booking['location']['lat'];
                      double destinationLng = booking['location']['lng'];

                      double dist = Geolocator.distanceBetween(
                          currentLat, currentLng, destinationLat, destinationLng);
                      distances.add(dist);
                    }

                    if (distances.isNotEmpty) {
                      int smallestIndex =
                      distances.indexOf(distances.reduce(min));
                      String bookedPatient = data[smallestIndex]['userId'];

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
                    } else {
                      snackbar('No suitable bookings to accept!');
                    }
                  } else {
                    snackbar('Nothing to accept!');
                  }
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
                  if (data.isNotEmpty) {
                    FirebaseFirestore.instance
                        .collection('bookings')
                        .doc(data[0]['userId'])
                        .update({
                      'ambulanceDetails': {'driverId': SPController().getUserId()},
                      'ambulanceStatus': 'assigned',
                    });
                  }
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
    );
  }
}
