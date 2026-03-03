import 'package:flutter/material.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A0F), Color(0xFF2F5D15), Color(0xFF224210)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'HELP CENTER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          letterSpacing: 2,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'sf_pro',
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FAQ section
                      _SectionCard(
                        title: 'Frequently Asked Questions',
                        child: Column(
                          children: [
                            _FaqTile(
                              question: 'What is Motion AI?',
                              answer:
                                  'Motion AI is your personal productivity workspace. '
                                  'It helps you capture ideas through voice recordings, '
                                  'organize notes, manage tasks, and chat with an AI '
                                  'assistant — all in one place.',
                            ),
                            const _CardDivider(),
                            _FaqTile(
                              question: 'How do I record audio?',
                              answer:
                                  'Tap the microphone button on the home screen to start '
                                  'recording. You can also shake your device to quickly '
                                  'begin a recording. Your recordings are automatically '
                                  'saved and can be transcribed.',
                            ),
                            const _CardDivider(),
                            _FaqTile(
                              question: 'How do notes work?',
                              answer:
                                  'Notes can be created manually or generated from audio '
                                  'transcriptions. They are synced to your workspace so '
                                  'you can access them from anywhere. Use the notes tab '
                                  'to view and edit your notes.',
                            ),
                            const _CardDivider(),
                            _FaqTile(
                              question: 'What are workspaces?',
                              answer:
                                  'Workspaces help you organize your content into separate '
                                  'spaces. For example, you might have a workspace for '
                                  'work and another for personal projects. Each workspace '
                                  'has its own notes, recordings, and tasks.',
                            ),
                            const _CardDivider(),
                            _FaqTile(
                              question: 'How do I wave to switch workspaces?',
                              answer:
                                  'When the "Wave to Switch Workspace" feature is enabled, '
                                  'you can wave your hand over the phone\'s proximity sensor '
                                  '(near the top of the screen) to cycle through your '
                                  'workspaces. A quick wave triggers the switch — holding '
                                  'your hand too long is ignored to prevent accidental '
                                  'triggers. You can toggle this feature in Settings under '
                                  'Gestures.',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Contact section
                      _SectionCard(
                        title: 'Contact & Support',
                        child: Column(
                          children: const [
                            _ContactRow(
                              icon: Icons.email_outlined,
                              text: 'support@motion-ai.app',
                            ),
                            _CardDivider(),
                            _ContactRow(
                              icon: Icons.language,
                              text: 'www.motion-ai.app',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // About section
                      _SectionCard(
                        title: 'About This App',
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            'Motion AI helps you capture, organize, and revisit '
                            'your thoughts effortlessly. Record voice memos, take '
                            'notes, manage tasks, and let AI help you stay on top '
                            'of everything.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontFamily: 'sf_pro',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'sf_pro',
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            color: Colors.white.withOpacity(0.05),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        iconColor: const Color(0xFFAEFB2A),
        collapsedIconColor: Colors.white38,
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: 'sf_pro',
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontFamily: 'sf_pro',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFAEFB2A), size: 20),
          const SizedBox(width: 14),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontFamily: 'sf_pro',
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(color: Colors.white.withOpacity(0.1), height: 1);
  }
}
