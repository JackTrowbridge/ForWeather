import 'package:flutter/material.dart';


class SettingsProvider extends ChangeNotifier{

  bool isCelsius = true;

  void setTemperatureUnit(bool isCelsius) {
    this.isCelsius = isCelsius;
    notifyListeners();
  }

}