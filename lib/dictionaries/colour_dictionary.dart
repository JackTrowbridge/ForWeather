import 'package:flutter/material.dart';

class ColourDictionary{

  Color getWeatherColour(String weatherType) {
    switch (weatherType) {
      case "Clouds":
        return Colors.grey;
      case "Clear":
        return Colors.yellow;
      case "Snow":
        return Colors.white;
      case "Rain":
        return Colors.blue;
      case "Drizzle":
        return Colors.lightBlue;
      case "Thunderstorm":
        return Colors.deepPurple;
      default:
        return Colors.white54; // Default color for unknown weather types
    }
  }

}