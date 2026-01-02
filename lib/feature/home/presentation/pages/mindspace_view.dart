import 'package:flutter/material.dart';
import 'package:motion_ai/feature/home/presentation/pages/widgets/gradient_scaffold_widget.dart';

class MindspaceView extends StatefulWidget {
  const MindspaceView({super.key});

  @override
  State<MindspaceView> createState() => _MindspaceViewState();
}

class _MindspaceViewState extends State<MindspaceView> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    if (_chatController.text.isNotEmpty) {
      // Logic to send message
      _chatController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      useDashboardGradient: true,
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'MINDSPACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'sf_pro',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // --- LOGO ---
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset("assets/images/logo.png"),
              ),
            ),
            const SizedBox(height: 20),
            // --- HEADER TEXT ---
            const Text(
              'Chat with your notes',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'sf_pro',
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What can I help you discover?',
              style: TextStyle(
                color: Colors.white70,
                fontFamily: 'sf_pro',
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFAEFB2A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add Context Pill
                    GestureDetector(
                      onTap: () {
                        /* Handle context action */
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Add Context',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'sf_pro',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // TextField Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            cursorColor: Colors.black,
                            style: const TextStyle(
                              color: Colors.black,
                              fontFamily: 'sf_pro',
                              fontSize: 16,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ask MindSpace anything...',
                              hintStyle: TextStyle(color: Colors.black54),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _handleSendMessage(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _handleSendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4DE1C9),
                            ),
                            child: Image.asset(
                              "assets/images/send.png",
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Options Row
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18),
                        SizedBox(width: 4),
                        Text('Auto', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 16),
                        Icon(Icons.source, size: 18),
                        SizedBox(width: 4),
                        Text('All sources', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 16),
                        Icon(Icons.calendar_month_rounded, size: 18),
                        SizedBox(width: 4),
                        Text('AnyTime', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.history, size: 20, color: Color(0xFFAEFB2A)),
                  SizedBox(width: 8),
                  Text(
                    'MindSpace Chat History',
                    style: TextStyle(
                      color: Color(0xFFAEFB2A),
                      fontFamily: 'sf_pro',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
