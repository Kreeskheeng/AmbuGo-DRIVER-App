import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:last_minute_driver/app/modules/homePage/controller/homePageStaffController.dart';
import 'package:last_minute_driver/app/modules/medicalReport/view/medicalReport.dart';
import 'package:last_minute_driver/widgets/button.dart';

import '../../../../utils/colors.dart';
import '../../../../utils/dimensions.dart';
import '../../../../widgets/big_text.dart';
import '../controller/patientStaffController.dart';

class PatientDetailsStaff extends StatelessWidget {
  PatientDetailsStaffController controller = Get.find();
  HomepageStaffController homepageStaffController = Get.find();
  ScrollController scrollController;
  PatientDetailsStaff({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(Dimensions.width15, Dimensions.height10,
          Dimensions.width15, Dimensions.height30),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: SizedBox(
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(homepageStaffController.patientId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Loading');
                    }

                    var data = snapshot.data!;
                    if (data == null ||
                        data['userId'] != homepageStaffController.patientId ||
                        data['ambulanceStatus'] != 'assigned') {
                      return const Text('No patient data found');
                    }

                    var patientDocument = data;
                    var patient = homepageStaffController.document;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: Dimensions.width20 * 4,
                          height: Dimensions.height10 / 5,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        SizedBox(height: Dimensions.height15),
                        BigText(
                          text: 'Patient Details',
                          size: Dimensions.font20 * 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                        SizedBox(height: Dimensions.height20 * 1.5),
                        Button(
                          on_pressed: () {},
                          text: 'Estimated Arrival: ${patientDocument['ambulanceLocation']?['time'] ?? 'N/A'}',
                          color: AppColors.black,
                          textColor: AppColors.white,
                          width: Dimensions.width40 * 6,
                          height: Dimensions.height40 * 1.1,
                          textSize: Dimensions.font20 * 0.8,
                        ),
                        SizedBox(height: Dimensions.height20 * 1.5),
                        if (patient != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BigText(
                                text: 'Name  ',
                                size: Dimensions.font15 * 1.2,
                              ),
                              BigText(
                                text: patient['name'] ?? 'N/A',
                                size: Dimensions.font15 * 1.2,
                              )
                            ],
                          ),
                          SizedBox(height: Dimensions.height15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BigText(
                                text: 'Phone number  ',
                                size: Dimensions.font15 * 1.2,
                              ),
                              BigText(
                                text: patient['phone']?.toString() ?? 'N/A',
                                size: Dimensions.font15 * 1.2,
                              ),
                            ],
                          ),
                          SizedBox(height: Dimensions.height15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BigText(
                                text: 'User Id  ',
                                size: Dimensions.font15 * 1.2,
                              ),
                              BigText(
                                text: patient['user Id'] ?? 'N/A',
                                size: Dimensions.font15 * 1.2,
                              ),
                            ],
                          ),
                          const Divider(
                            thickness: 1,
                            color: AppColors.lightGrey,
                            height: 40,
                          ),
                        ],
                        // Rest of your UI code...
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Button(
            on_pressed: () {
              MedicalReport.launch();
            },
            text: 'Create Medical Report',
            height: Dimensions.height40 * 1.3,
            color: AppColors.pink,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
