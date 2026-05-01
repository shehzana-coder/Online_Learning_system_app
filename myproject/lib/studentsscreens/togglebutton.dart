import 'package:flutter/material.dart';

// Light Theme Configuration
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.pink,
  primaryColor: Colors.pink,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.pink,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    shadowColor: Colors.black.withOpacity(0.1),
    elevation: 4,
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
        color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(
        color: Colors.black, fontSize: 24, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.black87, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.pink,
      foregroundColor: Colors.white,
    ),
  ),
);

// Dark Theme Configuration
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.pink,
  primaryColor: Colors.pink,
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.pink,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: Colors.grey[900],
    shadowColor: Colors.pink.withOpacity(0.2),
    elevation: 4,
  ),
  textTheme: TextTheme(
    headlineLarge: TextStyle(
        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: TextStyle(
        color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.pink,
      foregroundColor: Colors.black,
    ),
  ),
);

class ThemeToggleScreen extends StatefulWidget {
  const ThemeToggleScreen({super.key});

  @override
  State<ThemeToggleScreen> createState() => _ThemeToggleScreenState();
}

class _ThemeToggleScreenState extends State<ThemeToggleScreen> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme Toggle',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Theme Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Custom Theme Toggle Button in app bar
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: ThemeToggleButton(
                isDarkMode: isDarkMode,
                onToggle: toggleTheme,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Theme: ${isDarkMode ? 'Dark Mode' : 'Light Mode'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Preview',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is how your app will look with the selected theme.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Sample Button'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Theme Colors:',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  ColorSwatch(
                    color: Colors.pink,
                    label: 'Primary (Pink)',
                  ),
                  ColorSwatch(
                    color: isDarkMode ? Colors.black : Colors.white,
                    label: isDarkMode
                        ? 'Background (Black)'
                        : 'Background (White)',
                  ),
                  ColorSwatch(
                    color: isDarkMode ? Colors.white : Colors.black,
                    label: isDarkMode ? 'Text (White)' : 'Text (Black)',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: ThemeToggleButton(
                  isDarkMode: isDarkMode,
                  onToggle: toggleTheme,
                  large: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onToggle;
  final bool large;

  const ThemeToggleButton({
    Key? key,
    required this.isDarkMode,
    required this.onToggle,
    this.large = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = large ? 80.0 : 60.0;
    final iconSize = large ? 24.0 : 16.0;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size / 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size / 4),
          color: isDarkMode ? Colors.pink : Colors.grey[300],
          border: Border.all(
            color: isDarkMode ? Colors.pink : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isDarkMode ? size / 2 : 2,
              top: 2,
              child: Container(
                width: size / 2 - 4,
                height: size / 2 - 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.black : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: iconSize,
                  color: isDarkMode ? Colors.pink : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const ColorSwatch({
    Key? key,
    required this.color,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
