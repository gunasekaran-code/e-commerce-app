import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {  // ✅ Must be ProfilePage
  final Map<String, dynamic> userData;
  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Profile Page', style: TextStyle(color: Colors.white)),
    );
  }
}