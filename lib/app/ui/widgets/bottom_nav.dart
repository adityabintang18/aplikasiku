import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavBar({super.key, required this.navigationShell});

  final List<IconData> icons = const [
    Icons.home_rounded,
    Icons.swap_horiz_rounded,
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  final List<String> labels = const [
    'Beranda',
    'Transaksi',
    'Statistik',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: navigationShell.currentIndex,
      onTap: navigationShell.goBranch,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      showUnselectedLabels: true,
      items: List.generate(icons.length, (index) {
        return BottomNavigationBarItem(
          icon: Icon(icons[index]),
          label: labels[index],
        );
      }),
    );
  }
}
