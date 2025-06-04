import 'package:flutter/material.dart';
import 'package:forweather/views/home/home_weather.dart';

void main() {
  runApp(
    MaterialApp(
      initialRoute: "/",
      routes: {
        "/": (context) => const HomeWeather(),
      }
    )
  );
}
