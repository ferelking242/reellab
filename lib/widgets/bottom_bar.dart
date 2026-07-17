import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tiktok_flutter/screens/feed_viewmodel.dart';
import 'package:get_it/get_it.dart';

class BottomBar extends StatelessWidget {
  static const double _iconSize = 20.0;
  static const double _createW = 38.0;

  const BottomBar({super.key});

  Widget get _createIcon => Container(
        width: 45.0,
        height: 27.0,
        child: Stack(children: [
          Container(
              margin: const EdgeInsets.only(left: 10.0),
              width: _createW,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 250, 45, 108),
                  borderRadius: BorderRadius.circular(7.0))),
          Container(
              margin: const EdgeInsets.only(right: 10.0),
              width: _createW,
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 32, 211, 234),
                  borderRadius: BorderRadius.circular(7.0))),
          Center(
              child: Container(
            height: double.infinity,
            width: _createW,
            decoration: BoxDecoration(
                color:
                    GetIt.instance<FeedViewModel>().actualScreen == 0
                        ? Colors.white
                        : Colors.black,
                borderRadius: BorderRadius.circular(7.0)),
            child: Icon(
              Icons.add,
              color: GetIt.instance<FeedViewModel>().actualScreen == 0
                  ? Colors.black
                  : Colors.white,
              size: 20.0,
            ),
          )),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final isIOS = !kIsWeb && Theme.of(context).platform == TargetPlatform.iOS;
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black12))),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _menuBtn(Icons.home_outlined, Icons.home, 'Home', 0),
              _menuBtn(Icons.search, Icons.search, 'Search', 1),
              const SizedBox(width: 15),
              _createIcon,
              const SizedBox(width: 15),
              _menuBtn(
                  Icons.message_outlined, Icons.message, 'Messages', 2),
              _menuBtn(Icons.person_outline, Icons.person, 'Profil', 3),
            ],
          ),
          SizedBox(height: isIOS ? 40 : 10),
        ],
      ),
    );
  }

  Widget _menuBtn(
      IconData icon, IconData activeIcon, String label, int index) {
    final vm = GetIt.instance<FeedViewModel>();
    final isActive = vm.actualScreen == index;
    final isDarkBg = vm.actualScreen == 0;
    final color = isDarkBg
        ? (isActive ? Colors.white : Colors.white70)
        : (isActive ? Colors.black : Colors.black54);

    return GestureDetector(
      onTap: () => vm.setActualScreen(index),
      child: SizedBox(
        height: 45,
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon,
                color: color, size: _iconSize),
            const SizedBox(height: 7),
            Text(label,
                style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                    color: color,
                    fontSize: 11.0)),
          ],
        ),
      ),
    );
  }
}
