Motion: Local-First AI Productivity Platform 🧠

<!-- Badges: Updated for amitKhayargoli/motion_ai -->

Motion is a next-generation, unified mobile productivity platform designed to eliminate tool fragmentation. Built with an "Offline-First" architecture, it seamlessly captures meeting notes, voice recordings, tasks, and visual diagrams, and uses Vector Search AI to enable powerful semantic information retrieval, even when you're offline.

<div style="display:flex">
<img width="459" height="827" alt="image" src="https://github.com/user-attachments/assets/4e5451f8-bfc8-43e8-a8ab-c20b17ad6c1e" />
<img width="459" height="827" alt="image" src="https://github.com/user-attachments/assets/6e2959ab-753b-4ce8-96e2-d36da39df51d" />
</div>



<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">✨ Features</h2>

Motion is designed to transform unstructured meeting data into structured, actionable knowledge.

Local-First Architecture: Ensures full Create/Read/Update/Delete (CRUD) functionality and sub-100ms load times, regardless of internet connectivity, using Isar Database.

Semantic Search (AI-Powered): Go beyond keyword matching. Utilize MongoDB Atlas Vector Search to query your notes based on meaning and context, finding concepts even if you use different words.

Meeting Intelligence: Auto-syncs with your calendar, creates pre-populated meeting workspaces, and handles real-time voice transcription.

Voice-to-Task Automation: Integrated Speech-to-Text (STT) and an integrated LLM automatically generates concise summaries and extracts "To-Do" action items directly from audio.

Whiteboard Engine: A vector-based drawing canvas allows for editable diagrams and flowcharts to be stored alongside your notes.

Cross-Platform Consistency: Developed entirely with Flutter, providing a native-like experience on both iOS and Android from a single codebase.

<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">📸 Mockups</h2>

Visualizing the integrated workflow—from recording to intelligent retrieval. (Replace these placeholder images with actual screenshots!)

Meeting Workspace (Recording)

Note Review & AI Summary

Semantic Search Interface







<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">📦 Getting Started</h2>

These instructions assume you have Flutter set up.

<h3 style="font-size: 1.4em; font-weight: 700; padding-top: 10px; padding-bottom: 5px;">Prerequisites</h3>

Flutter SDK: Stable channel (3.x or newer). Install Flutter

IDE: VS Code or Android Studio with Flutter/Dart extensions.

<h3 style="font-size: 1.4em; font-weight: 700; padding-top: 10px; padding-bottom: 5px;">Installation</h3>

Clone the repository:

git clone [https://github.com/amitKhayargoli/motion_ai.git](https://github.com/amitKhayargoli/motion_ai.git)


Navigate to the project directory:

cd motion_app_v1


Install dependencies (Isar code generation required):

flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs


Database Setup: Motion requires a MongoDB Atlas connection string and potentially an API key for the external transcription service.

Create a file named .env in the root directory and add your keys (e.g., MONGO_URI, WHISPER_API_KEY).

<h3 style="font-size: 1.4em; font-weight: 700; padding-top: 10px; padding-bottom: 5px;">Running the App</h3>

Run the app on your connected device or simulator:

flutter run


<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">🛠️ Built With</h2>

Flutter - The UI toolkit for cross-platform development.

Dart - The programming language.

Isar Database - High-performance local NoSQL database for the "Local-First" architecture.

MongoDB Atlas - Cloud database supporting the flexible BSON structure and Vector Search capabilities.

[State Management Package] - (e.g., Riverpod or Bloc for MVVM implementation).

[External AI Service] - (e.g., Whisper API for high-fidelity transcription).

<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">🤝 Contributing</h2>

We welcome contributions to Motion! Please follow these steps:

Fork the Project.

Create your Feature Branch (git checkout -b feature/new-ai-model).

Commit your Changes (git commit -m 'feat: Add new transcription model option').

Push to the Branch (git push origin feature/new-ai-model).

Open a detailed Pull Request.

<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">📄 License</h2>

Distributed under the MIT License. See the LICENSE file for more details.

<h2 style="font-size: 1.8em; font-weight: 800; padding-top: 15px; padding-bottom: 5px;">📧 Contact</h2>

[Your Name] - [Your Email Address]

Project Link: https://www.google.com/url?sa=E&source=gmail&q=https://github.com/amitKhayargoli/motion_ai
