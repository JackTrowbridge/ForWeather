import 'dart:convert';

import 'package:forweather/models/current_weather.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageUtils{

  Future<CurrentWeather?> getCurrentWeatherFromStorage() async{

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String? weatherJson = sharedPreferences.getString("currentWeather");
    if(weatherJson == null){
      print("No current weather data found in storage.");
      return null;
    }

    Map<String, dynamic> weatherMap = jsonDecode(weatherJson);
    CurrentWeather currentWeather = CurrentWeather.fromJson(weatherMap);

    return currentWeather;
  }

  void storeCurrentWeather(CurrentWeather currentWeather) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    String weatherJson = jsonEncode(currentWeather.toJson());
    await sharedPreferences.setString("currentWeather", weatherJson);

    print("Current weather data stored successfully.");
  }

}