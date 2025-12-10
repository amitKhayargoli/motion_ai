import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/view/home_view.dart';
import 'package:motion_ai/feature/home/view/meetings_view.dart';
import 'package:motion_ai/feature/home/view/mindspace_view.dart';
import 'package:motion_ai/feature/home/view/notes_view.dart';
import 'package:motion_ai/feature/home/view/widgets/bottom_nav_widget.dart';

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

  List<Widget> pages = [
    const HomeView(),
    const MeetingsView(),
    const MindspaceView(),
    const NotesView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: BottomNavWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: pages[_selectedIndex],
    );
  }
}
