import 'package:flutter/material.dart';

import 'home_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';

class RootNavigationPage extends StatefulWidget {
  const RootNavigationPage({super.key});

  @override
  State<RootNavigationPage> createState() => _RootNavigationPageState();
}

class _RootNavigationPageState extends State<RootNavigationPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _pages = const [
      HomePage(),
      NotificationsPage(),
      ProfilePage(),
    ];
    _navigatorKeys = List.generate(
      _pages.length,
      (_) => GlobalKey<NavigatorState>(),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      _navigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    final NavigatorState? currentNavigator =
        _navigatorKeys[_selectedIndex].currentState;
    if (currentNavigator?.canPop() ?? false) {
      currentNavigator!.maybePop();
      return false;
    }
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    return true;
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _selectedIndex != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (_) => _pages[index],
          settings: settings,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: List.generate(
            _pages.length,
            (index) => _buildOffstageNavigator(index),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: colorScheme.primary.withOpacity(0.12),
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Mes trajets',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
