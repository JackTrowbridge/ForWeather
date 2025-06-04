
import 'current_weather.dart';

class GetWeatherObject{
  final CurrentWeather? currentWeather;
  final String? errorMessage;
  final int? statusCode;

  GetWeatherObject({
    this.currentWeather,
    this.errorMessage,
    required this.statusCode,
  });
}