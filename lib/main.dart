import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/logistics_screen.dart';
import 'screens/loadout_screen.dart';
import 'screens/more_screen.dart';
import 'screens/mortar_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const WarDogsApp());
}

class WarDogsApp extends StatelessWidget {
  const WarDogsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '战狗小助手',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      // IndexedStack：切走再切回来，填了一半的坐标还在
      body: IndexedStack(
        index: _index,
        children: const [
          MortarScreen(),
          LogisticsScreen(),
          LoadoutScreen(),
          MoreScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: C.bg,
          border: Border(top: BorderSide(color: C.border)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: C.bg,
            indicatorColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 12,
                color: states.contains(WidgetState.selected)
                    ? C.gold
                    : C.textFaint,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: 24,
                color: states.contains(WidgetState.selected)
                    ? C.gold
                    : C.textFaint,
              ),
            ),
          ),
          child: NavigationBar(
            height: 62,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.my_location_outlined),
                  selectedIcon: Icon(Icons.my_location),
                  label: '迫击炮'),
              NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping),
                  label: '后勤'),
              NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: '配装'),
              NavigationDestination(
                  icon: Icon(Icons.info_outline),
                  selectedIcon: Icon(Icons.info),
                  label: '更多'),
            ],
          ),
        ),
      ),
    );
  }
}
