import 'package:json_annotation/json_annotation.dart';

part 'current_weather.g.dart';

@JsonSerializable()
class CurrentWeather{
  final String weatherType;
  final int temperature;
  final int feelsLike;
  final double windSpeed;
  final double humidity;
  final double visibility;
  final String location;
  final String country;
  final String countryCode;

  CurrentWeather({
    required this.weatherType,
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.humidity,
    required this.visibility,
    required this.location,
    required this.country,
    required this.countryCode,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) => _$CurrentWeatherFromJson(json);
  Map<String, dynamic> toJson() => _$CurrentWeatherToJson(this);

}