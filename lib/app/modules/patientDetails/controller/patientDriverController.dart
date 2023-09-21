import 'package:get/get.dart';

class PatientDetailsDriverController extends GetxController {

  //next page
  bool additionaldata = true;
  onPageChanged(bool x) {
    additionaldata = x;
    update();
  }

}
