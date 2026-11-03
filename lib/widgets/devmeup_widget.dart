import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DevMeUpWidget extends StatelessWidget {
  const DevMeUpWidget({super.key});

  // Function to open the URL
  void _launchURL(String url) async {
    await launchUrl(Uri.https(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchURL('devmeup.fr'),
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'DevMeUp',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
