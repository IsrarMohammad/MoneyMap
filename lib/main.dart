import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:moneymap/models/user_settings.dart';
import 'package:moneymap/utils/theme.dart';

import 'package:moneymap/viewmodels/expense_viewmodel.dart';
import 'package:moneymap/viewmodels/income_viewmodel.dart';
import 'package:moneymap/viewmodels/category_viewmodel.dart';
import 'package:moneymap/viewmodels/budget_viewmodel.dart';
import 'package:moneymap/viewmodels/report_viewmodel.dart';
import 'package:moneymap/viewmodels/settings_viewmodel.dart';

import 'package:moneymap/services/notification_service.dart';

import 'package:moneymap/views/dashboard_page.dart';
import 'package:moneymap/views/settings_page.dart';
import 'package:moneymap/views/add_expense_page.dart';
import 'package:moneymap/views/add_income_page.dart';
import 'package:moneymap/views/categories_page.dart';
import 'package:moneymap/views/budget_page.dart';
import 'package:moneymap/views/reports_page.dart';

// Main application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Optional: Firebase initialization (uncomment if using cloud sync)
  // await Firebase.initializeApp();

  // Initialize local notifications
  await NotificationService().init();

  runApp(const MoneyMapApp());
}

class MoneyMapApp extends StatelessWidget {
  const MoneyMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MultiProvider: makes all ViewModels available to app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => IncomeViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => BudgetViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel()..loadSettings(),
        ), // Load on startup
      ],
      child: Consumer<SettingsViewModel>(
        builder: (context, settingsVM, child) {
          // Determining theme mode based on user settings
          final userSettings = settingsVM.userSettings;
          ThemeMode themeMode;
          switch (userSettings?.themeMode ?? AppThemeMode.system) {
            case AppThemeMode.light:
              themeMode = ThemeMode.light;
              break;
            case AppThemeMode.dark:
              themeMode = ThemeMode.dark;
              break;
            case AppThemeMode.system:
              themeMode = ThemeMode.system;
          }

          return MaterialApp(
            title: 'MoneyMap',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeMode,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}

/// A simple main navigation scaffold. Expand with BottomNavigationBar or Drawer as desired.
class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static final List<Widget> _pages = [
    DashboardPage(),
    ReportsPage(),
    CategoriesPage(),
    BudgetPage(),
    SettingsPage(),
  ];

  static final List<String> _titles = [
    'Dashboard',
    'Reports',
    'Categories',
    'Budgets',
    'Settings',
  ];

  static final List<IconData> _icons = [
    Icons.dashboard,
    Icons.pie_chart,
    Icons.category,
    Icons.account_balance_wallet,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(
          _pages.length,
          (i) =>
              BottomNavigationBarItem(icon: Icon(_icons[i]), label: _titles[i]),
        ),
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: _getFabForTab(_selectedIndex),
    );
  }

  // FAB for quick add expense/income on relevant tabs
  Widget? _getFabForTab(int index) {
    if (index == 0) {
      // Dashboard: Add Expense
      return FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Expense'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpensePage()),
        ),
      );
    }
    if (index == 1) {
      // Reports: Add Income (example)
      return FloatingActionButton.extended(
        icon: const Icon(Icons.attach_money),
        label: const Text('Income'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddIncomePage()),
        ),
      );
    }
    return null;
  }
}
