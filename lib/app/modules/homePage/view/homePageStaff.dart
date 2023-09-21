// ignore_for_file: must_be_immutable, file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:last_minute_driver/app/modules/homePage/view/panelWidgetStaff.dart';
import 'package:last_minute_driver/app/modules/logIn/view/login.dart';
import 'package:last_minute_driver/helper/snackbar.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/dimensions.dart';
import '../../patientDetails/controller/patientStaffController.dart';
import '../../patientDetails/view/patientDetailsStaff.dart';
import '../controller/homePageStaffController.dart';

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
            width: 40,
            height: 40,
          ),
          SizedBox(width: 2.0), // Add some spacing between logo and text
          Text(
            title,
            style: const TextStyle(
              color: AppColors.pink,
              fontFamily: 'RedHat',
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.indigo),
          onPressed: onNotificationPressed,
        ),
        IconButton(
          icon: Icon(Icons.logout, color: Colors.indigo),
          onPressed:onNotificationPressed,
        ),
      ],
    );

  }
}

class HomepageStaff extends GetView<HomepageStaffController> {
  // HomepageStaffController controller = Get.find();
  PatientDetailsStaffController patientController = Get.find();
  Completer<GoogleMapController> mapController = Completer();

  static const route = '/homepage-staff';
  bool patientAssign = false;
  String patientId='';
  HomepageStaff({super.key, this.patientAssign = false,this.patientId=''});
  static launch() => Get.toNamed(route);
  final panelController = PanelController();

  void _onMapCreated(GoogleMapController controller) {
    mapController.complete(controller);
  }

  @override
  Widget build(BuildContext context) {
    controller.onAmbulanceBooked(patientAssign,patientId);
    return MaterialApp(
      home: Scaffold(
          appBar: TransparentAppBar(
            title: " AmbuLance Go.",
            onNotificationPressed: () {
              // TODO: Handle notification button press
              // Implement your notification logic here
            },
            onLogoutPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  LogIn() ),
              );

            },
          ),
          body: Obx(
        () => controller.patientAssigned
            ? GetBuilder<PatientDetailsStaffController>(
                builder: (patientController) {
                return SlidingUpPanel(
                  maxHeight: patientController.additionaldata
                      ? Dimensions.height40 * 15
                      : Dimensions.height40 * 13,
                  controller: panelController,
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radius30),
                      topRight: Radius.circular(Dimensions.radius30)),
                  panelBuilder: (controller) =>
                      //patientController.additionaldata
                      // ? AdditionalData(
                      //     scrollController: controller,
                      //   )
                      // :
                      PatientDetailsStaff(
                    scrollController: controller,
                  ),
                  body: Stack(
                    alignment: Alignment.center,
                    children: [
                      renderMap(),
                    ],
                  ),
                );
              })
            : SlidingUpPanel(
                maxHeight: Dimensions.height40 * 6,
                minHeight: Dimensions.height40 * 6,
                isDraggable: false,
                controller: panelController,
                borderRadius: BorderRadius.circular(Dimensions.radius30),
                panelBuilder: (controller) => PanelWidgetStaff(),
                body: renderMap()),
      )),
    );
  }

  Widget renderMap() {
    return Obx((() => (controller.isLoading.value)
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          )
        : SizedBox(child: GetBuilder<HomepageStaffController>(
          builder: (_) {
            return GoogleMap(
              mapType: MapType.normal,
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(controller.currentLocation!.latitude,
                    controller.currentLocation!.longitude),
                zoom: 13.5,
              ),
              markers: controller.patientAssigned? {
                  Marker(
                    onTap: (){
                      snackbar('Patient Location');
                    },
                      markerId: const MarkerId('PatientLocation'),
                      position: controller.patientLocation),
                Marker(
                  onTap: () {
                    snackbar('Ambulance Location');
                  },
                  markerId: const MarkerId('driverLocation'),
                  position: LatLng(controller.driverLocation.latitude,
                      controller.driverLocation.longitude),
                ),
                Marker(
                  onTap: () {
                    snackbar('Your Location');
                  },
                  markerId: const MarkerId('myLocation'),
                  position: LatLng(controller.currentLocation!.latitude,
                      controller.currentLocation!.longitude),
                )
              }:{
                Marker(
                  onTap: () {
                    snackbar('Your Location');
                  },
                  markerId: const MarkerId('myLocation'),
                  position: LatLng(controller.currentLocation!.latitude,
                      controller.currentLocation!.longitude),
                )
              },
              polylines: {
                Polyline(
                    polylineId: const PolylineId('route'),
                    points: controller.polylineCoordinates,
                    color: AppColors.pink,
                    width: 6)
              },
            );
          },
        ))));
  }
}
