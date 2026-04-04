// Copyright (c) 2026 Jacken Xu (lightant@gmail.com)
// All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/generated/app_localizations.dart';
import 'views/home_view.dart';
import 'views/chat_view.dart';
import 'views/insight_view.dart';
import 'views/settings_view.dart';

import 'providers/records_provider.dart';
import 'providers/settings_provider.dart';

import 'package:flutter_gemma/flutter_gemma.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  runApp(const ProviderScope(child: CardioInsightApp()));
}

class CardioInsightApp extends ConsumerWidget {
  const CardioInsightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Custom Colors from React App
    const primaryColor = Color(0xFFFF783C); // #FF783C
    const scaffoldLight = Color(0xFFF9FAFB); // #F9FAFB

    return MaterialApp(
      title: 'Cardio Insight',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF3F4F6),
          onSurface: const Color(0xFF1F2937),
        ),
        scaffoldBackgroundColor: scaffoldLight,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF374151), // Gray-700
          surfaceContainerHighest: const Color(0xFF4B5563), // Gray-600
          onSurface: const Color(0xFFF9FAFB), // Gray-50
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate-900
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937), // Gray-800
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF1E293B), // Slate-800
          margin: EdgeInsets.zero,
        ),
        textTheme: GoogleFonts.notoSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Request permissions on launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recordsProvider.notifier).refresh();
    });
  }

  static const List<Widget> _views = [
    HomeView(),
    ChatView(),
    InsightView(),
    SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // Custom Header logic for Main Screen
      appBar: _selectedIndex == 0
          ? AppBar(
              toolbarHeight: 64,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF783C),
                          Color(0xFFEF4444),
                        ], // cardio-orange to red-500
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.monitor_heart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFF783C),
                        Color(0xFFDC2626),
                      ], // cardio-orange to red-600
                    ).createShader(bounds),
                    child: const Text(
                      'Cardio Insight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Required for ShaderMask
                      ),
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  height: 1,
                ),
              ),
            )
          : null,
      body: IndexedStack(index: _selectedIndex, children: _views),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, l10n.home),
                _buildNavItem(1, Icons.chat_bubble_rounded, l10n.chat),
                _buildNavItem(2, Icons.auto_awesome_rounded, l10n.insights),
                _buildNavItem(3, Icons.settings_rounded, l10n.settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? const Color(0xFFFF783C)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        curve: Curves.easeOut,
        transform: isSelected
            ? Matrix4.diagonal3Values(1.1, 1.1, 1.0)
            : Matrix4.identity(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
