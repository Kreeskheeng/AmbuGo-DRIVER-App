import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../utils/colors.dart';

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
          onPressed: onLogoutPressed,
        ),
      ],
    );
  }
}

class GeneratedQR extends StatefulWidget {
  final myQR;

  const GeneratedQR(this.myQR);

  @override
  _GeneratedQRState createState() => _GeneratedQRState();
}

class _GeneratedQRState extends State<GeneratedQR> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TransparentAppBar(
        title: 'Ride fare QR Code',
        onNotificationPressed: () {
          // Handle notification pressed
        },
        onLogoutPressed: () {
          // Handle logout pressed
        },
      ),
      body: Center(
        child: QrImageView(
          data: widget.myQR,
          version: QrVersions.auto,
        ),
      ),
    );
  }
}
