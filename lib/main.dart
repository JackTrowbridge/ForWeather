import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forweather/providers/settings_provider.dart';
import 'package:forweather/views/home/home_weather.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const InitializePage());
}

class InitializePage extends StatefulWidget {
  const InitializePage({super.key});

  @override
  State<InitializePage> createState() => _InitializePageState();
}

class _InitializePageState extends State<InitializePage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _initializeEnvironment();
  }

  bool isLoading = true;

  void _initializeEnvironment() async{
    await dotenv.load(fileName: ".env");
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return
      isLoading
          ? const Center(child: CircularProgressIndicator()) // TODO: Make nicer
          :
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
            initialRoute: "/",
            routes: {
              "/": (context) => const HomeWeather(),
            }
        ),
      );
  }
}
