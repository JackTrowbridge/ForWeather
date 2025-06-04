import 'package:flutter/material.dart';

class WeatherConverter{

  IconData? getIcon(String weatherType){

    switch(weatherType){
      case "Clouds":
        return Icons.cloud_outlined;
      case "Clear":
        return Icons.wb_sunny_outlined;
      case "Snow":
        return Icons.snowing;
      case "Rain":
        return Icons.water_drop_outlined;
      case "Drizzle":
        return Icons.water_drop_outlined;
      case "Thunderstorm":
        return Icons.thunderstorm_outlined;
    }

    return null;
  }

  String getWeatherString(String weatherType){

    switch(weatherType){
      case "Clouds":
        return "Cloudy";
      case "Clear":
        return "Sunny";
      case "Snow":
        return "Snowing";
      case "Rain":
        return "Raining";
      case "Drizzle":
        return "Slightly Raining";
      case "Thunderstorm":
        return "Thundering";
    }

    return weatherType;
  }

}