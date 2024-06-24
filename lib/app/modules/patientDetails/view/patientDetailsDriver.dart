import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:last_minute_driver/app/modules/qr/QR%20Generator/QRGenerator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:last_minute_driver/widgets/button.dart';
import 'package:last_minute_driver/utils/colors.dart';
import 'package:last_minute_driver/utils/dimensions.dart';
import 'package:last_minute_driver/widgets/big_text.dart';
import 'package:last_minute_driver/helper/shared_preference.dart';
import '../../homePage/controller/homePageDriverController.dart';
import '../../qr/QR Generator/GeneratedQR.dart';
import '../controller/patientDriverController.dart';

class PatientDetailsDriver extends GetView<PatientDetailsDriverController> {
  HomepageDriverController homepageController = Get.find();
  ScrollController scrollController;
  String? patientId;
  PatientDetailsDriver({super.key, required this.scrollController, this.patientId = ''});

  void _launchPhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle error: unable to launch the phone call.
    }
  }

  final _rideFare = ''.obs; // Store the ride fare

  @override
  void initState() {
    initState();
    // Retrieve the ride fare from Firebase when the widget is initialized
    retrieveRideFare();
  }

  // Retrieve the ride fare from Firebase
  void retrieveRideFare() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> rideInfoDoc =
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(SPController().getUserId())
          .get();
      String rideFare = rideInfoDoc['rideFare'].toString(); // Change the field name as per your Firestore structure

      _rideFare(rideFare);
    } catch (e) {

    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Dimensions.width15, Dimensions.height10, Dimensions.width15, Dimensions.height30),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    child: Image.asset(
                      'assets/images/ambugo.jpg',
                      height: 70, // Increased height
                      width: 70,  // Increased width
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: Dimensions.width20 * 4,
                    height: Dimensions.height10 / 5,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  SizedBox(
                    height: Dimensions.height15,
                  ),
                  BigText(
                    text: 'Patient Details',
                    size: Dimensions.font20 * 1.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.lightGreen[900],
                  ),
                  SizedBox(
                    height: Dimensions.height20 * 1.8,
                  ),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
                    builder: (context, snapshot) {
                      DocumentSnapshot<Map<String, dynamic>>? patient;
                      if (snapshot.hasData) {
                        final List<DocumentSnapshot> users = snapshot.data!.docs;
                        for (var user in users) {
                          if (user['userId'] == patientId && user['ambulanceStatus'] == 'assigned') {
                            // Ensure location data is not null
                            if (user['location'] != null && user['location']['lat'] != null && user['location']['lng'] != null) {
                              // print('Calling onGetPatientLocation with lat: ${user['location']['lat']}, lng: ${user['location']['lng']}');
                              homepageController.onGetPatientLocation(user['location']['lat'], user['location']['lng']);
                              if (homepageController.document != null) {
                                patient = homepageController.document!;
                              }
                            } else {
                              // Handle null location data
                            }
                          }
                        }
                      } else {
                        // Handle loading state
                      }
                      return patient == null
                          ? const Text('Loading')
                          : Column(
                        children: [
                          Row(
                            children: [
                              BigText(
                                text: 'Name:  ',
                                size: Dimensions.font20,
                                color: const Color(0xFFFF0000),
                                fontWeight: FontWeight.bold,
                              ),
                              BigText(
                                text: patient['name'],
                                size: Dimensions.font15 * 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height15,
                          ),
                          Row(
                            children: [
                              BigText(
                                text: 'Contact:  ',
                                size: Dimensions.font20,
                                color: const Color(0xFFFF0000),
                                fontWeight: FontWeight.bold,
                              ),
                              BigText(
                                text: patient['phone'].toString(),
                                size: Dimensions.font15 * 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height15,
                          ),
                          Row(
                            children: [
                              BigText(
                                text: 'Call:',
                                size: Dimensions.font20,
                                color: const Color(0xFFFF0000),
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(width: Dimensions.width20 * 3),
                              GestureDetector(
                                onTap: () {
                                  _launchPhoneCall(patient?['phone']);
                                },
                                child: Image.asset(
                                  'assets/images/call.png', // Replace with your image asset path
                                  height: Dimensions.font20 * 2.5, // Adjust size as needed
                                  width: Dimensions.font20 * 3.5, // Adjust size as needed
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
                                text: 'Text:  ',
                                size: Dimensions.font20,
                                color: const Color(0xFFFF0000),
                                fontWeight: FontWeight.bold,
                              ),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Type your message...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  maxLines: null, // Allows multiple lines of input
                                  keyboardType: TextInputType.multiline,
                                ),
                              ),
                              SizedBox(width: 10),
                              IconButton(
                                icon: Icon(Icons.send),
                                onPressed: () {
                                  // Implement send functionality
                                  print('Sending message...');
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(
                    height: Dimensions.height20 * 1.8,
                  ),
                  const Divider(
                    thickness: 1,
                    color: AppColors.lightGrey,
                    height: 30,
                  ),
                  SizedBox(
                    height: Dimensions.height15,
                  ),
                  BigText(
                    text: 'Additional Data',
                    size: Dimensions.font20 * 1.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.lightGreen[900],
                  ),
                  SizedBox(
                    height: Dimensions.height20 * 1.8,
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('bookings').doc(patientId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text('Loading...');
                      }

                      final bookingData = snapshot.data!.data() as Map<String, dynamic>;
                      final additionalData = bookingData['additionalData'] as Map<String, dynamic>?;

                      if (additionalData == null) {
                        return const Text('Additional data not available.');
                      }

                      final preferredHospital = additionalData['preferredHospital'] as String? ?? 'Preferred Hospital Not Set Yet!';
                      final oxygenNeed = additionalData['Is Oxygen neeeded'] as String? ?? 'Oxygen Need Not Set Yet!';
                      final emergencyTypeList = additionalData['emergencyType'] as List<dynamic>? ?? [];
                      final hospitalType = additionalData['hospitalType'] as String? ?? 'Hospital Type Not Set Yet!';

                      final emergencyTypeText = emergencyTypeList.isNotEmpty ? emergencyTypeList.join(', ') : 'Emergency Type Not Set Yet!';

                      return Column(
                        children: [
                          Row(
                            children: [
                              BigText(
                                text: 'EMERGENCY TYPE: ',
                                color: const Color(0xFFFF0000),
                                size: Dimensions.font20,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(
                                width: Dimensions.width15,
                              ),
                              Expanded(
                                child: BigText(
                                  maxLines: null,
                                  text: emergencyTypeText,
                                  size: Dimensions.font20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height10,
                          ),
                          Row(
                            children: [
                              BigText(
                                text: 'Hosp. TYPE: ',
                                color: const Color(0xFFFF0000),
                                size: Dimensions.font20,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(
                                width: Dimensions.width15,
                              ),
                              Expanded(
                                child: BigText(
                                  maxLines: null,
                                  text: hospitalType,
                                  size: Dimensions.font20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height10,
                          ),
                          Row(
                            children: [
                              BigText(
                                text: 'PREFERRED Hosp.: ',
                                color: const Color(0xFFFF0000),
                                size: Dimensions.font20,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(
                                width: Dimensions.width15,
                              ),
                              Expanded(
                                child: BigText(
                                  maxLines: null,
                                  text: preferredHospital,
                                  size: Dimensions.font20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height10,
                          ),
                          Row(
                            children: [
                              BigText(
                                text: 'OXYGEN NEED: ',
                                color: const Color(0xFFFF0000),
                                size: Dimensions.font20,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(
                                width: Dimensions.width15,
                              ),
                              Expanded(
                                child: BigText(
                                  maxLines: null,
                                  text: oxygenNeed,
                                  size: Dimensions.font20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: Dimensions.height20 * 1.8,
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(
                    thickness: 1,
                    color: AppColors.lightGrey,
                    height: 30,
                  ),
                  Button(
                    on_pressed: () async {
                      // Update ambulance status and perform necessary actions
                      await FirebaseFirestore.instance.collection('bookings').doc(patientId).update({
                        'ambulanceStatus': 'completed',
                      });
                      
                        // Clear the declinedDrivers array
                      await FirebaseFirestore.instance.collection('bookings').doc(patientId).update({
                        'declinedDrivers': [],
                      });
                      homepageController.onAmbulanceBooked(false, '');

                      // Navigate to the QR code screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GeneratedQR(_rideFare.value),
                        ),
                      );
                    },
                    height: Dimensions.height40 * 1.3,
                    width: Dimensions.width40 * 6,
                    text: "Ride Completed",
                    textColor: AppColors.white,
                    color: AppColors.pink,
                    radius: Dimensions.radius30,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
