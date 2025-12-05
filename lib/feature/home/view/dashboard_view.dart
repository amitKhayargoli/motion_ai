import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/view/widgets/bottom_nav_widget.dart';
import 'package:motion_ai/feature/home/view/widgets/mobile_recordings_widget.dart';
import 'package:motion_ai/feature/home/view/widgets/today_card_widget.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF2E3D28),
              Color(0xFF000000),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'MOTION WORKSPACE',
                    style: TextStyle(
                      fontFamily: 'sf_pro',
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const TodayCardWidget(),
                const SizedBox(height: 30),
                const MobileRecordingsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
