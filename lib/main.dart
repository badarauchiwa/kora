import 'package:flutter/material.dart';
import 'browser.dart';
import 'downloads.dart';
import 'files.dart';

void main() => runApp(const KoraApp());

class KoraApp extends StatelessWidget {
  const KoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Kora',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3C5D)), useMaterial3: true),
        darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1FA2B8), brightness: Brightness.dark), useMaterial3: true),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: IndexedStack(index: tab, children: [
            BrowserPage(onDownload: () => setState(() => tab = 1)),
            const DownloadsPage(),
            const FilesPage(),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (i) => setState(() => tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.public), label: 'Navigateur'),
            NavigationDestination(icon: Icon(Icons.download), label: 'Téléchargements'),
            NavigationDestination(icon: Icon(Icons.folder), label: 'Fichiers'),
          ],
        ),
      );
}
