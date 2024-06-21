import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:get/get.dart';
import 'package:last_minute_driver/app/modules/qr/HomePage.dart';
import 'package:last_minute_driver/app/modules/qr/QR%20Generator/QRGenerator.dart';
import 'package:last_minute_driver/widgets/button.dart';
import '../../../../helper/shared_preference.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/dimensions.dart';
import '../../../../widgets/big_text.dart';
import '../../homePage/controller/homePageDriverController.dart';
import '../controller/patientDriverController.dart';
import 'package:http/http.dart' as http;

class PatientDetailsDriver extends GetView<PatientDetailsDriverController> {
  HomepageDriverController homepageController = Get.find();
  ScrollController scrollController;
  String? patientId;
  PatientDetailsDriver({super.key, required this.scrollController, this.patientId = ''});

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
                              print('Calling onGetPatientLocation with lat: ${user['location']['lat']}, lng: ${user['location']['lng']}');
                              homepageController.onGetPatientLocation(user['location']['lat'], user['location']['lng']);
                              if (homepageController.document != null) {
                                patient = homepageController.document!;
                              }
                            } else {
                              print('User location data is missing or incomplete');
                            }
                          }
                        }
                      } else {
                        print('Snapshot does not have data');
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
                              Row(
                                children: [
                                   //Icon(
                                    // Icons.phone,
                                    // color: Colors.black, // Customize the color as needed
                                    // size: Dimensions.font15 * 1.2,
                                   // ),
                                  //SizedBox(width: Dimensions.width5), // Add some spacing between the icon and the text
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
                              SizedBox(width: Dimensions.width20*3),
                              GestureDetector(
                                onTap: () {

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
                      final emergencyTypeList = additionalData['emergencyType'] as List<dynamic>? ??  [];
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
                                  text:hospitalType,
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



                          // Additional Rows or Widgets can be added here for other data
                        ],
                      );
                    },
                  ),

                  //Button(
                    //on_pressed: () async {
                    //  final CollectionReference hospitalsCollection =
                     // FirebaseFirestore.instance.collection('bookings');

                     // const String apiKey =
                      //    'AIzaSyBtFdD1MNJWvqevGFtv5KgpHcgQXBusi4E';

                     // const int radius = 5000000;
                     // const double latitude = 0.3341163;
                     // const double longitude = 32.5638838;

                     // const String url =
                       //   'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=hospital&key=$apiKey';

                     // try {
                      //  var response = await http.get(Uri.parse(url));

                       // if (response.statusCode == 200) {
                       //   var json = jsonDecode(response.body);

                          // Check if the response contains results
                         // if (json.containsKey('results') &&
                           //   json['results'].isNotEmpty) {
                            // Process the hospital data here
                          //  List<dynamic> hospitals = json['results'];

                          //  Future<void> saveHospitalToFirestore(
                          //      String placeId,
                          //      String name,
                           //     String vicinity,
                           //     ) async {
                           //   try {
                            //    await hospitalsCollection
                              //      .doc(SPController().getUserId())
                              //      .update({
                              //    'nearest hospital': {
                              //      'name': name,
                              //      'vicinity': vicinity,
                              //    },
                             //   });

                              //  print(
                             //       'Hospital data saved to Firestore: $name');
                            //  } catch (e) {
                             //   print('Error saving hospital data: $e');
                           //   }
                           // }

                           // for (var hospital in hospitals) {
                           //   var placeId = hospital['place_id'] as String;
                           //   var name = hospital['name'] as String;
                           //   var vicinity = hospital['vicinity'] as String;

                            //  await saveHospitalToFirestore(
                            //      placeId, name, vicinity);

                            //  print(
                            //      'Hospital: $name, Place ID: $placeId, Vicinity: $vicinity');
                          //  }
                          //} else {
                         //   print('No hospitals found.');
                        //  }
                        //} else {
                        //  print('Failed to fetch data: ${response.statusCode}');
                      //  }
                      //} catch (e) {
                      //  print('Error: $e');
                     // }
                   // },
                    //height: Dimensions.height40 * 1.4,
                 //   width: Dimensions.width40 * 5,
                   // text: "Nearest hosp.",
                   // textColor: AppColors.pink,
                   // boxBorder: Border.all(width: 2, color: AppColors.pink),
                   // color: Colors.transparent,
                  //  radius: Dimensions.radius30,
                 // ),




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
                      homepageController.onAmbulanceBooked(false, '');

                      // QR Code Scanning
                      try {
                        final qrCode = await FlutterBarcodeScanner.scanBarcode(
                          '#ff6666',
                          'Cancel',
                          true,
                          ScanMode.QR,
                        );

                        if (qrCode == '-1') {
                          // User canceled the scan.
                          print('Scan canceled.');
                        } else if (qrCode.isNotEmpty) {
                          // QR code was successfully scanned.
                          print('Scanned QR Code: $qrCode');

                          // Save the scanned QR code result to Firestore
                          await FirebaseFirestore.instance.collection('scanned_codes').add({
                            'result': qrCode,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          // Navigate to the Stripe payment page (uncomment the code below if needed)
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => Wallet(), // Replace with your Stripe payment screen
                          //   ),
                          // );
                        } else {
                          // QR code scan failed.
                          print('Failed to scan QR Code.');
                        }
                      } on PlatformException {
                        print('Failed to scan QR Code.');
                      }
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
