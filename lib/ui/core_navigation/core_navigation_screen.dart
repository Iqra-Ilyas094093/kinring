import 'package:flutter/material.dart';

import '../chat/chat_list_screen.dart';
import '../groups/groups_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// 4-tab bottom navigation shell per product doc 5.1: Home | Groups |
/// Chat | Settings. (Previously 3 tabs — Chat added between Groups and
/// Settings.) Tab bodies are blank placeholders for now — this file only
/// owns the tab-switching structure.
class CoreNavigationScreen extends StatefulWidget {
  const CoreNavigationScreen({super.key});

  @override
  State<CoreNavigationScreen> createState() => _CoreNavigationScreenState();
}

class _CoreNavigationScreenState extends State<CoreNavigationScreen> {
  int _currentIndex = 0;

  static const _tabs = [HomeScreen(), GroupsScreen(), ChatListScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
