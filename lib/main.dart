import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'services/settings_service.dart';
import 'services/temperature_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settingsService = SettingsService();
  await settingsService.loadSettings();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsService),
        ChangeNotifierProvider(create: (_) => TemperatureService(settingsService)),
      ],
      child: const PoolTempApp(),
    ),
  );
}

class PoolTempApp extends StatelessWidget {
  const PoolTempApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'ThermaPool',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            textTheme: GoogleFonts.interTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              centerTitle: true,
            ),
            // High contrast ratios for accessibility
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              secondary: Colors.blue,
              error: Colors.red.shade700,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFF121212),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            // High contrast ratios for accessibility in dark mode
            colorScheme: ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.blue,
              error: Colors.red.shade400,
            ),
          ),
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const MainTabView(),
        );
      },
    );
  }
}

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _selectedIndex = 0;
  late PageController _pageController;
  
  // Only 2 screens - Settings accessed via AppBar
  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: WaterDropNavBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        waterDropColor: Colors.blue,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          );
        },
        selectedIndex: _selectedIndex,
        barItems: [
          BarItem(
            filledIcon: Icons.home,
            outlinedIcon: Icons.home_outlined,
          ),
          BarItem(
            filledIcon: Icons.show_chart,
            outlinedIcon: Icons.show_chart_outlined,
          ),
        ],
      ),
    );
  }
}