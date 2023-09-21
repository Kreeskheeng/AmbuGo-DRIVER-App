import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:last_minute_driver/app/modules/homePage/view/panelWidgetDriver.dart';
import 'package:last_minute_driver/app/modules/logIn/view/login.dart';
import 'package:last_minute_driver/helper/shared_preference.dart';
import 'package:last_minute_driver/helper/snackbar.dart';
import 'package:last_minute_driver/widgets/big_text.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/dimensions.dart';
import '../../../../widgets/button.dart';
import '../../patientDetails/controller/patientDriverController.dart';
import '../../patientDetails/view/patientDetailsDriver.dart';
import '../controller/homePageDriverController.dart';


// Define the TransparentAppBar class
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

class HomepageDriver extends GetView<HomepageDriverController> {
  PatientDetailsDriverController patientController = Get.find();
  Completer<GoogleMapController> mapController = Completer();

  static const route = '/homepage-driver';
  bool patientAssign = false;
  String patient = '';

  HomepageDriver

  ({super.key, this.patientAssign = false, this.patient = ''});

  static launch() => Get.toNamed(route);
  final panelController = PanelController();


  @override
  void initState() {
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      await controller.onAmbulanceBooked(patientAssign, patient);
      //await controller.initCurrentLocation(); // Initialize current location
    });
  }
  void _onMapCreated(GoogleMapController controller) {
    if (mapController.isCompleted) {
      mapController.complete(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: TransparentAppBar(
          title: " AmbuLance Go.",
          onNotificationPressed: () {
            // TODO: Handle notification button press
            // Implement your notification logic here
          },
          onLogoutPressed: () {
            LogIn.launch();
          },
        ),

        body: SafeArea(
          child: Obx(
                () =>
            controller.patientAssigned
                ? SlidingUpPanel(
              maxHeight: patientController.additionaldata
                  ? Dimensions.height40 * 17
                  : Dimensions.height40 * 11.8,
              controller: panelController,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(Dimensions.radius30),
                topRight: Radius.circular(Dimensions.radius30),
              ),
              panelBuilder: (panelController) =>
                  PatientDetailsDriver(
                    scrollController: panelController,
                    patientId: controller.bookedPatientId,
                  ),
              body: Stack(
                alignment: Alignment.center,
                children: [
                  renderMap(),
                ],
              ),
            )
                : SlidingUpPanel(
              maxHeight: Dimensions.height40 * 10,
              minHeight: Dimensions.height40 * 10,
              isDraggable: false,
              controller: panelController,
              borderRadius: BorderRadius.circular(Dimensions.radius30),
              panelBuilder: (controller) => PanelWidgetDriver(),
              body: renderMap(),
            ),
          ),
        ),
      ),
    );
  }



  Widget renderMap() {
      return Obx(
          () =>(controller.isLoading.value)
          ? Center(child: CircularProgressIndicator(color: AppColors.orange),
      )
          : Stack(
        children: [SizedBox(
            child: GetBuilder<HomepageDriverController>(
              builder: (_) {
                return GoogleMap(
                  mapType: MapType.normal,
                  onMapCreated: (controller) {

                    _onMapCreated(controller);
                  },
                  onCameraMove: (positioned) {

                    controller.latLng.add(positioned.target);
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      controller.currentLocation!.latitude!,
                      controller.currentLocation!.longitude!,
                    ),
                    zoom: 13.5,
                  ),
                  markers: {
                    if (controller.patientAssigned)
                      Marker(
                        onTap: () {
                          snackbar('Patient Location');
                        },
                        markerId: const MarkerId('PatientLocation'),
                        position: controller.destinationLocation,
                      ),
                    Marker(
                      onTap: () {
                        snackbar('Your Location');
                      },
                      markerId: const MarkerId('driverLocation'),
                      position: LatLng(
                        controller.currentLocation!.latitude!,
                        controller.currentLocation!.longitude!,
                      ),
                    ),
                  },
                  polylines: {
                    if (controller.patientAssigned)
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: controller.polylineCoordinates,
                        color: AppColors.pink,
                        width: 6,
                      ),
                  },
                );

              },
            ),
          ),
          controller.patientAssigned
              ? Positioned(
            top: Dimensions.screenHeight / 2.4,
            right: 0,
            child: Obx(
                  () =>
                  Column(
                    children: [
                      Container(
                        width: Dimensions.width40 * 5,
                        height: Dimensions.height40 * 1.1,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.black,
                        ),
                        child: Center(
                          child: BigText(
                            text: 'Key: ' +
                                SPController()
                                    .getUserId()
                                    .toString()
                                    .substring(0, 6),
                            size: Dimensions.font20 * 0.8,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Button(
                        on_pressed: () {},
                        text: '  Estimated Arrival: ${controller.time}',
                        color: AppColors.black,
                        textColor: AppColors.white,
                        width: Dimensions.width40 * 5,
                        height: Dimensions.height40 * 1.1,
                        textSize: Dimensions.font20 * 0.8,
                      ),
                    ],
                  ),
            ),
          )
              : const SizedBox(),
        ],
      ),
    );
  }
}