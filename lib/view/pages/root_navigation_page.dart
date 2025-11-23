import 'package:flutter/material.dart';

import '../theme/page_theme_provider.dart';
import 'home_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'traffic_info_page.dart';

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
      TrafficInfoPage(),
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
    final brightness = Theme.of(context).brightness;
    final pageColors = PageThemeColors.forPage(_selectedIndex, brightness);

    return PageThemeProvider(
      colors: pageColors,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final NavigatorState? currentNavigator =
              _navigatorKeys[_selectedIndex].currentState;
          if (currentNavigator?.canPop() ?? false) {
            currentNavigator!.maybePop();
            return;
          }
          if (_selectedIndex != 0) {
            setState(() {
              _selectedIndex = 0;
            });
            return;
          }
          // Allow the system to pop (exit app)
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          body: Stack(
            children: List.generate(
              _pages.length,
              (index) => _buildOffstageNavigator(index),
            ),
          ),
          bottomNavigationBar: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: _selectedIndex == 2
                    ? Theme.of(context).colorScheme.copyWith(
                        primary: Colors.blue.shade700, // Bleu au lieu d'orange pour l'onglet Notifications
                      )
                    : Theme.of(context).colorScheme,
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                backgroundColor: Colors.transparent,
                elevation: 0,
                indicatorColor: _selectedIndex == 2 
                    ? Colors.blue.shade50.withValues(alpha: 0.3) // Bleu clair pour l'onglet Notifications au lieu d'orange
                    : pageColors.primary.withValues(alpha: 0.15),
                height: 72,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                animationDuration: const Duration(milliseconds: 300),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.route_outlined, color: _selectedIndex == 0 ? pageColors.primary : Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                    selectedIcon: Icon(Icons.route, color: pageColors.primary),
                    label: 'Mes trajets',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.traffic_outlined, color: _selectedIndex == 1 ? pageColors.primary : Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                    selectedIcon: Icon(Icons.traffic, color: pageColors.primary),
                    label: 'Info Trafic',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.notifications_outlined, 
                      color: _selectedIndex == 2 
                          ? Colors.blue.shade700 // Bleu au lieu d'orange pour contraste
                          : Theme.of(context).brightness == Brightness.dark 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600
                    ),
                    selectedIcon: Icon(Icons.notifications, color: Colors.blue.shade700), // Bleu au lieu d'orange
                    label: 'Notifications',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline, color: _selectedIndex == 3 ? pageColors.primary : Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
                    selectedIcon: Icon(Icons.person, color: pageColors.primary),
                    label: 'Profil',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
