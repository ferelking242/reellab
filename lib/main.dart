import 'package:flutter/material.dart';

import 'package:tiktok_flutter/data/server_config.dart';
import 'package:tiktok_flutter/screens/connect_server_screen.dart';
import 'package:tiktok_flutter/screens/feed_screen.dart';
import 'package:tiktok_flutter/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServerConfig.init();
  setup();
  runApp(const ReelApp());
}

class ReelApp extends StatelessWidget {
  const ReelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ServerConfig.instance.isConfigured
          ? FeedScreen()
          : ConnectServerScreen(
              onConnected: () {
                // Replace with feed once server is configured
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => FeedScreen()),
                  (_) => false,
                );
              },
            ),
    );
  }
}
