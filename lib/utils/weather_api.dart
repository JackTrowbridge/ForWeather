import 'package:forweather/api/api_key.dart';
import 'package:http/http.dart' as http;
import 'package:g_json/g_json.dart';

import '../models/current_weather.dart';
import '../models/get_weather_object.dart';

class WeatherAPI {

  Future<GetWeatherObject> getCurrentWeather(String city, String country, String countryCode) async {

    final String apiKey = APIKey().getOpenWeatherAPIKey();

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };

    final Uri url = Uri.parse(
        "https://api.openweathermap.org/data/2.5/weather?q=$city,$countryCode&appid=$apiKey&units=metric");

    try {
      final response = await http.get(url, headers: headers).timeout(
          const Duration(seconds: 5));
      final responseParsed = JSON.parse(response.body);

      if (response.statusCode != 200) {
        return GetWeatherObject(
          errorMessage: responseParsed["message"].stringValue,
          statusCode: response.statusCode,
        );
      }

      CurrentWeather currentWeather = CurrentWeather(
          weatherType: responseParsed["weather"][0]["main"].stringValue,
          temperature: responseParsed["main"]["temp"].integerValue,
          feelsLike: responseParsed["main"]["feels_like"].integerValue,
          windSpeed: responseParsed["wind"]["speed"].ddoubleValue * 3.6,
          humidity: responseParsed["main"]["humidity"].ddoubleValue,
          visibility: responseParsed["visibility"].ddoubleValue / 1000,
          location: responseParsed["name"].stringValue,
          country: country,
          countryCode: countryCode,
      );

      return GetWeatherObject(
        currentWeather: currentWeather,
        statusCode: response.statusCode,
      );

    } catch (e, stacktrace) {
      print("Error fetching weather data: $e");
      print("Stack trace: $stacktrace");
    }

    return GetWeatherObject(
      statusCode: 009,
    );
  }

}