// ignore_for_file: file_names, unused_import

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:last_minute_driver/app/modules/homePage/view/homePageStaff.dart';

import '../../../../utils/colors.dart';
import '../../../../utils/dimensions.dart';
import '../../../../widgets/big_text.dart';
import '../../../../widgets/button.dart';
import '../../../../widgets/drop_down.dart';
import '../../../../widgets/text_field.dart';
import '../controller/createProfileStaffController.dart';
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onNotificationPressed;
  final VoidCallback onLogoutPressed;

  TransparentAppBar({
    required this.title,
    required this.onNotificationPressed,
    required this.onLogoutPressed,


  });

  @override
  Size get preferredSize => Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Image.asset(
            'assets/images/ambugo.jpg', // Update with your logo image path
            width: 45,
            height: 45,
          ),
          SizedBox(width: 2.0), // Add some spacing between logo and text
          Text(
            title,
            style: const TextStyle(
              color: AppColors.pink,
              fontFamily: 'RedHat',
              fontWeight: FontWeight.bold,
              fontSize: 27.6,
            ),
          ),
        ],
      ),
      actions: [

      ],
    );

  }
}

class CreateProfileStaff extends GetView<CreateProfileStaffController> {
  static const route = '/createprofile-staff';
  static launch() => Get.toNamed(route);
  const CreateProfileStaff({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: "AmbuLance Go",
        onNotificationPressed: () {
          // TODO: Handle notification button press
          // Implement your notification logic here
        },
        onLogoutPressed: () {

        },
      ),
      body: SizedBox(
        width: Dimensions.screenWidth,
        height: Dimensions.screenHeight,
        child: SafeArea(
          child: Padding(
              padding: EdgeInsets.fromLTRB(
                  Dimensions.width15,
                  Dimensions.height40 * 2,
                  Dimensions.width15,
                  Dimensions.height30),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    BigText(
                      text: 'Create Profile',
                      size: Dimensions.font26 * 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(
                      height: Dimensions.height30,
                    ),
                    Text_Field(
                        radius: Dimensions.radius20,
                        text_field_width: double.maxFinite,
                        text_field_height: Dimensions.height20 * 3,
                        text_field: TextField(
                          controller: controller.name,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.indigo,
                            ),
                            hintText: 'Name',
                          ),
                        )),
                    SizedBox(
                      height: Dimensions.height20,
                    ),
                    Text_Field(
                        radius: Dimensions.radius20,
                        text_field_width: double.maxFinite,
                        text_field_height: Dimensions.height20 * 3,
                        text_field: Center(
                          child: TextField(
                            controller: controller.mobileNumber,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.phone,
                                color: Colors.indigo,
                              ),
                              hintText: 'Mobile No.',
                            ),
                          ),
                        )),
                    SizedBox(
                      height: Dimensions.height20,
                    ),
                    Text_Field(
                        radius: Dimensions.radius20,
                        text_field_width: double.maxFinite,
                        text_field_height: Dimensions.height20 * 6,
                        text_field: Center(
                          child: SingleChildScrollView(
                            child: TextField(
                              controller: controller.address,
                              maxLines: null,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.location_city,
                                  color:Colors.indigo,
                                ),
                                hintText: 'Address',
                              ),
                            ),
                          ),
                        )),
                    SizedBox(
                      height: Dimensions.height20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropDown(
                          width: Dimensions.width40 * 4.5,
                          height: Dimensions.height20 * 3,
                          name: 'Gender',
                          value: controller.value,
                          items: controller.dropDownList.map((String items) {
                            return DropdownMenuItem(
                              alignment: Alignment.center,
                              value: items,
                              child: Text(items),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            controller.onChangedList(newValue.toString());
                          },
                        ),
                        Text_Field(
                            radius: Dimensions.radius20,
                            text_field_width: Dimensions.width40 * 4.5,
                            text_field_height: Dimensions.height20 * 3,
                            text_field: TextField(
                              controller: controller.bloodGroup,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.bloodtype,
                                  color: AppColors.pink,
                                ),
                                hintText: 'Blood Group',
                              ),
                            )),
                      ],
                    ),
                    SizedBox(
                      height: Dimensions.height20,
                    ),
                    Text_Field(
                        radius: Dimensions.radius20,
                        text_field_width: double.maxFinite,
                        text_field_height: Dimensions.height20 * 3,
                        text_field: TextField(
                          controller: controller.medicalLicence,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.car_rental,
                              color: Colors.indigo,
                            ),
                            hintText: 'Medical Licence',
                          ),
                        )),
                    SizedBox(
                      height: Dimensions.height40 * 5,
                    ),
                    Button(
                      width: double.maxFinite,
                      height: Dimensions.height40 * 1.5,
                      radius: Dimensions.radius20 * 2,
                      on_pressed: () {
                        controller.onCreateProfileStaff();
                        
                      },
                      text: 'CONTINUE',
                      color: AppColors.pink,
                    ),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
