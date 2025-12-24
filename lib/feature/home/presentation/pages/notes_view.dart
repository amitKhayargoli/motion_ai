import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/notes_card_widget.dart';

class NotesListView extends StatelessWidget {
  const NotesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A0F), // top
              Color(0xFF2F5D15), // middle
              Color(0xFF224210), // bottom
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    const Text(
                      'NOTES',
                      style: TextStyle(
                        color: Colors.white60,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'sf_pro',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 10, bottom: 120),
                  children: const [
                    NoteCard(
                      title: "Project Alpha Kickoff",
                      content:
                          "Discussed the roadmap for Q4. Key deliverables include the new API integration...",
                      category: "Work",
                      time: "2h ago",
                      isPinned: true,
                    ),
                    NoteCard(
                      title: "Grocery List",
                      bulletPoints: ["Avocados", "Oat milk", "Sourdough bread"],
                      category: "Personal",
                      time: "Yesterday",
                    ),
                    NoteCard(
                      title: "Book Recommendations",
                      content:
                          "\"The Design of Everyday Things\" by Don Norman. \"Thinking, Fast and Slow\" by Daniel Kahneman...",
                      category: "Reading",
                      time: "Oct 24",
                    ),
                    NoteCard(
                      title: "App Ideas 🚀",
                      content:
                          "A plant watering tracker that uses AI to identify plant types. Simple UI, green theme...",
                      category: "Idea",
                      time: "Oct 20",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? const Color(0xFFAEFB2A) : Colors.white38),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFFAEFB2A) : Colors.white38,
            fontSize: 10,
            fontFamily: 'sf_pro',
          ),
        ),
      ],
    );
  }
}
