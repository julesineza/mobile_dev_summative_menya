import 'package:flutter/material.dart';


class BottomNavigation extends StatefulWidget {
  const BottomNavigation({
    super.key, 
    required this.currentIndex,
    required this.onSelected,
    });

    final int currentIndex;
    final ValueChanged<int> onSelected;

    void _onItemTapped(int index) {
    onSelected(index);
  }

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: widget._onItemTapped,
      elevation:0,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Students',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assessment),
          label: 'Assess',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Progress',
        ),
      ],
    );
  }
}