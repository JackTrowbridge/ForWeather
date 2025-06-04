// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentWeather _$CurrentWeatherFromJson(Map<String, dynamic> json) =>
    CurrentWeather(
      weatherType: json['weatherType'] as String,
      temperature: (json['temperature'] as num).toInt(),
      feelsLike: (json['feelsLike'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      location: json['location'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String,
    );

Map<String, dynamic> _$CurrentWeatherToJson(CurrentWeather instance) =>
    <String, dynamic>{
      'weatherType': instance.weatherType,
      'temperature': instance.temperature,
      'feelsLike': instance.feelsLike,
      'windSpeed': instance.windSpeed,
      'humidity': instance.humidity,
      'visibility': instance.visibility,
      'location': instance.location,
      'country': instance.country,
      'countryCode': instance.countryCode,
    };
