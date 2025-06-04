import 'package:flutter/material.dart';
import 'package:forweather/providers/settings_provider.dart';
import 'package:forweather/views/home/home_weather.dart';
import 'package:forweather/views/settings/settings_page.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        initialRoute: "/",
        routes: {
          "/": (context) => const HomeWeather(),
        }
      ),
    )
  );
}
