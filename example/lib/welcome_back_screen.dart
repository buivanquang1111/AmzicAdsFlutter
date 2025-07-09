import 'package:amazic_ads_flutter/admob.dart';
import 'package:flutter/material.dart';

import 'main.dart';

class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome back app')),
      body: Column(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Admob.instance.appLifecycleReactor?.loadAndShowAppOpenAds(
                  onAdDisable: () {
                    Navigator.pop(context);
                  },
                  onAdFailedToLoad: () {
                    Navigator.pop(context);
                  },
                  onAdFailedToShow: () {
                    Navigator.pop(context);
                  },
                  onAdDismiss: () {
                    Navigator.pop(context);
                  },
                );
              },
              child: Center(
                child: Container(
                  height: 56,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.greenAccent,
                  ),
                  child: Center(child: Text('show App Open ads', textAlign: TextAlign.center)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
