import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/home_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/meetings_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/mindspace_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/notes_view.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/bottom_nav_widget.dart';

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
    const NotesListView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      floatingActionButton: (_selectedIndex == 0 || _selectedIndex == 3)
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFFAEFB2A),
              elevation: 8,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.black, size: 30),
            )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: pages[_selectedIndex],
    );
  }
}
