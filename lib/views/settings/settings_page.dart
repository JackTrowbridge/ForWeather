import 'package:flutter/material.dart';
import 'package:forweather/providers/settings_provider.dart';
import 'package:forweather/views/widgets/glass_container.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final Color currentColour;
  const SettingsPage({super.key, required this.currentColour});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {

    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {

        return Scaffold(
          backgroundColor: widget.currentColour,
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [

                    const SizedBox(height: 75),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [

                            Text(
                                "Settings",
                                style: TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                )
                            ),
                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.black,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Text(
                                      "Select your preferred temperature unit",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: widget.currentColour,
                                      )
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [

                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            settings.setTemperatureUnit(true);
                                          });
                                        },
                                        child: GlassContainer(
                                            isSelected: settings.isCelsius,
                                            selectedColor: widget.currentColour,
                                            child: Text(
                                              "Celsius",
                                              style: TextStyle(
                                                color: widget.currentColour,
                                              )
                                            )
                                        ),
                                      ),

                                      const SizedBox(width: 10),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            settings.setTemperatureUnit(false);
                                          });
                                        },
                                        child: GlassContainer(
                                            isSelected: !settings.isCelsius,
                                            selectedColor: widget.currentColour,
                                            child: Text(
                                              "Fahrenheit",
                                                style: TextStyle(
                                                  color: widget.currentColour,
                                                )
                                            )
                                        ),
                                      )

                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text("Your current selection is: " + (settings.isCelsius ? "Celsius" : "Fahrenheit"),
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: widget.currentColour,
                                      )
                                  ),
                                ],
                              ),
                            )

                          ],
                        ),
                      ],
                    ),

                  ],
                ),
              ),

              // Back Button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: GlassContainer(
                      child: Text(
                        "Go Back",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                )
              )
            ],
          ),
        );

      },
    );

  }
}
