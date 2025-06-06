import 'dart:ui';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:forweather/dictionaries/colour_dictionary.dart';
import 'package:forweather/models/current_weather.dart';
import 'package:forweather/models/get_weather_object.dart';
import 'package:forweather/models/location.dart';
import 'package:forweather/providers/settings_provider.dart';
import 'package:forweather/utils/storage_utils.dart';
import 'package:forweather/utils/weather_api.dart';
import 'package:forweather/utils/weather_converter.dart';
import 'package:forweather/views/settings/settings_page.dart';
import 'package:forweather/views/widgets/glass_container.dart';
import 'package:forweather/views/widgets/search.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class HomeWeather extends StatefulWidget {
  const HomeWeather({super.key});

  @override
  State<HomeWeather> createState() => _HomeWeatherState();
}

class _HomeWeatherState extends State<HomeWeather> {

  final GlobalKey<ScaffoldState> _key = GlobalKey(); // Create a key

  Color primaryColor = ColourDictionary().getWeatherColour("");
  Duration colourTransitionDuration = const Duration(seconds: 2);

  CurrentWeather? currentWeather;
  String currentDate = "";

  bool showSearchBar = false;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSearchFocused = false;

  List<Location> searchedLocations = [];

  bool showErrorMessage = false;
  String defaultErrorMessage = "We couldn't find the weather for this location. Please try again.";
  String errorMessage = "";

  int currentTemperature = 0;
  int currentFeelsLike = 0;

  bool isSearchLoading = false;

  RefreshController refreshController = RefreshController(initialRefresh: false);

  double celsiusToFahrenheit(int celsius) {
    return (celsius * 9 / 5) + 32;
  }


  void _settingsChanged(){

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    setState(() {
      if(settingsProvider.isCelsius) {
        currentTemperature = currentWeather?.temperature.toInt() ?? 0;
        currentFeelsLike = currentWeather?.feelsLike.toInt() ?? 0;
      } else {
        currentTemperature = celsiusToFahrenheit(currentWeather?.temperature.toInt() ?? 0).toInt();
        currentFeelsLike = celsiusToFahrenheit(currentWeather?.feelsLike.toInt() ?? 0).toInt();
      }
    });

  }

  @override
  void initState() {
    super.initState();

    searchFocusNode.addListener(_onSearchFocusChange);
    searchController.addListener(_searchCity);

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    settingsProvider.addListener(_settingsChanged);

    DateTime now = DateTime.now();
    setState(() {
      currentDate = DateFormat('EEEE, d MMMM').format(now);
    });

    // Fetch weather data when the widget is initialized
    _checkForCurrentWeather();
  }

  void _checkForCurrentWeather() async {
    final storageUtils = StorageUtils();
    CurrentWeather? storedWeather = await storageUtils.getCurrentWeatherFromStorage();
    if(storedWeather == null){
      _fetchWeatherData("Portsmouth", "United Kingdom", "GB");
    }else{
      _fetchWeatherData(storedWeather.location, storedWeather.country, storedWeather.countryCode);
    }
  }

  void _fetchWeatherData(String city, String country, String countryCode) async {

    GetWeatherObject getWeatherObject =
        await WeatherAPI().getCurrentWeather(city, country, countryCode);

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (getWeatherObject.statusCode == 200) {
      setState(() {
        isSearchLoading = false;
        currentWeather = getWeatherObject.currentWeather;
        primaryColor = ColourDictionary().getWeatherColour(currentWeather!.weatherType);
        if( settings.isCelsius) {
          currentTemperature = currentWeather!.temperature.toInt();
          currentFeelsLike = currentWeather!.feelsLike.toInt();
        } else if(!settings.isCelsius) {
          currentTemperature = celsiusToFahrenheit(currentWeather!.temperature).toInt();
          currentFeelsLike = celsiusToFahrenheit(currentWeather!.feelsLike).toInt();
        }

        if(currentWeather != null) StorageUtils().storeCurrentWeather(currentWeather!);
      });
    } else {
      print("Error fetching weather data: ${getWeatherObject.errorMessage}");

      setState(() {
        showErrorMessage = true;
        errorMessage = defaultErrorMessage;
      });
      if(getWeatherObject.errorMessage == "city not found") { // TODO: Handle this better, maybe use status codes
        setState(() {
          errorMessage = "We couldn't find weather for $city, $country. Please try again.";
        });
        Future.delayed(const Duration(seconds: 5), () {
          setState(() {
            showErrorMessage = false;
            errorMessage = defaultErrorMessage;
          });
        });
      }

    }
  }

  void _onRefresh() async{

    // Refresh the weather data
    if (currentWeather != null) {
      _fetchWeatherData(currentWeather!.location, currentWeather!.country, currentWeather!.countryCode);
    } else {
      _checkForCurrentWeather();
    }

    // Complete the refresh
    refreshController.refreshCompleted();

  }

  void _onSearchFocusChange() {
    setState(() {
      isSearchFocused = !isSearchFocused;
    });
  }

  void _searchCity() {
    EasyDebounce.debounce('searchCity', Duration(milliseconds: 500),
        () => _search(searchController.text));
  }

  void _search(String input) async {

    setState(() {
      searchedLocations.clear();
    });

    final indexName = dotenv.env['ALGOLIA_INDEX_NAME'] ?? "";

    final client = SearchClient(
        appId: dotenv.env['ALGOLIA_APP_ID'] ?? "",
        apiKey: dotenv.env['ALGOLIA_API_KEY'] ?? "");

    final search = await client.search(
        searchMethodParams: SearchMethodParams(requests: [
      SearchForHits(
        indexName: indexName,
        query: input,
        hitsPerPage: 5,
      )
    ]));

    final searchResults = search.toJson();
    for (final hit in searchResults["results"][0]["hits"]) {

      // TODO: Handle duplicates better using toSet
      if (searchedLocations.any((location) =>
          location.name == hit["city"] && location.country == hit["country"])) {
        continue; // Skip duplicates
      }

      final location = Location(
        name: hit["city"] ?? "Unknown",
        country: hit["country"] ?? "Unknown",
        countryCode: hit["iso2"] ?? "Unknown",
      );

      setState(() {
        searchedLocations.add(location);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<SettingsProvider>(
      builder: (context, settings, child){

        return Scaffold(
          key: _key,
          resizeToAvoidBottomInset: false,
          body: AnimatedContainer(
            duration: colourTransitionDuration,
            curve: Curves.easeInOut,
            color: primaryColor,
            child: SafeArea(
              child: SmartRefresher(
                controller: refreshController,
                enablePullUp: false,
                enablePullDown: true,
                onRefresh: _onRefresh,

                child: Stack(
                  children: [
                    Column(
                      children: [
                        // Centered Information
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                const SizedBox(height: 40),
                
                                // Location
                                Text(
                                  currentWeather != null
                                      ? currentWeather!.country
                                      : "Loading...",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      showSearchBar = !showSearchBar;
                                      searchController.clear();
                                      if (showSearchBar) {
                                        searchFocusNode.requestFocus();
                                      } else {
                                        searchFocusNode.unfocus();
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        currentWeather != null
                                            ? currentWeather!.location
                                            : "Loading...",
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.search,
                                        color: Colors.black,
                                        size: 20,
                                      )
                                    ],
                                  ),
                                ),
                
                                const SizedBox(height: 31),
                
                                // Date
                                Container(
                                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration: colourTransitionDuration,
                                    curve: Curves.easeInOut,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                    child: Text(
                                      currentDate,
                                    ),
                                  ),
                                ),
                
                                const SizedBox(height: 13),
                
                                // Current Weather
                                Row(
                                  children: [
                                    Text(
                                      currentWeather != null
                                          ? WeatherConverter().getWeatherString(currentWeather!.weatherType)
                                          : "",
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      WeatherConverter().getIcon(currentWeather?.weatherType ?? ""),
                                      color: Colors.black,
                                    )
                                  ],
                                ),
                
                                const SizedBox(height: 31),
                                // Temperature
                                currentWeather != null ?
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic, // Important for baseline alignment
                                  children: [
                                    Text(
                                      currentWeather != null ? "${currentTemperature.toInt()}°" : "",
                                      style: const TextStyle(
                                        fontSize: 177,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      settings.isCelsius
                                          ? "C"
                                          : "F",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ) : LoadingAnimationWidget.inkDrop(
                                    color: Colors.black,
                                    size: 177,
                                ),
                
                              ],
                            )
                          ],
                        ),
                
                        isSearchLoading ? LoadingAnimationWidget.waveDots(
                            color: Colors.black,
                            size: 100,
                        ) : const SizedBox.shrink(),
                
                        const SizedBox(height: 16),
                
                        // Weather Details and Weekly forecast
                        Padding(
                          padding: const EdgeInsets.only(left: 28, right: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 40),
                                  // Daily Summary
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Daily Summary",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        currentWeather != null
                                            ? "Now it feels like +${currentWeather!.feelsLike}°, actually +${currentWeather!.temperature}°."
                                            : "Loading weather data...",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.black,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  spacing: 30,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TweenAnimationBuilder<Color?>(
                                              tween: ColorTween(end: primaryColor),
                                              duration: colourTransitionDuration,
                                              builder:(context, color, child) {
                                                return Icon(
                                                  Icons.waves_outlined,
                                                  color: color,
                                                  size: 70,
                                                );
                                              }
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              currentWeather != null
                                                  ? "${currentWeather!.windSpeed.toInt()}km/h"
                                                  : "",
                                            ),
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              "Wind",
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TweenAnimationBuilder<Color?>(
                                              tween: ColorTween(end: primaryColor),
                                              duration: colourTransitionDuration,
                                              builder:(context, color, child) {
                                                return Icon(
                                                  Icons.water_drop_outlined,
                                                  color: color,
                                                  size: 70,
                                                );
                                              }
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              currentWeather != null
                                                  ? "${currentWeather!.humidity.toInt()}%"
                                                  : "",
                                            ),
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              "Humidity",
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          TweenAnimationBuilder<Color?>(
                                              tween: ColorTween(end: primaryColor),
                                              duration: colourTransitionDuration,
                                              builder:(context, color, child) {
                                                return Icon(
                                                  Icons.remove_red_eye,
                                                  color: color,
                                                  size: 70,
                                                );
                                              }
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              currentWeather != null
                                                  ? currentWeather!.visibility % 1 == 0
                                                  ? "${currentWeather!.visibility.toInt()}km"
                                                  : "${currentWeather!.visibility.toStringAsFixed(1)}km"
                                                  : "",
                                            ),
                                          ),
                                          AnimatedDefaultTextStyle(
                                            duration: colourTransitionDuration,
                                            curve: Curves.easeInOut,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: primaryColor,
                                            ),
                                            child: Text(
                                              "Visibility",
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                
                              /*

                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 40),
                              // Daily Summary
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Weekly Forecast",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                
                              for (int i = 0; i < 4; i++)
                                DayWeatherCard(
                                  key: Key("day_$i"),
                                ),
                
                            ],
                          )
                
                          */
                            ],
                          ),
                        ),
                      ],
                    ),
                
                    // Search bar
                    showSearchBar
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const SizedBox(height: 100),
                            GlassContainer(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 20,
                                child: TextField(
                                  focusNode: searchFocusNode,
                                  controller: searchController,
                                  decoration: InputDecoration(
                                      filled: false,
                                      hintText: "Search for a city...",
                                      hintStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                      ),
                                      border: InputBorder.none,
                                      suffixIcon: isSearchFocused
                                          ? IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          setState(() {
                                            searchController.clear();
                                            searchedLocations.clear();
                                          });
                                        },
                                        icon: Icon(Icons.clear,
                                            color: Colors.black, size: 20),
                                      )
                                          : Icon(Icons.search,
                                          color: Colors.black, size: 20)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                
                            for (final location in searchedLocations)
                              GestureDetector(
                                onTap: (){
                                  setState(() {
                                    showSearchBar = false;
                                    isSearchLoading = true;
                                    searchController.clear();
                                    searchedLocations.clear();
                                    searchFocusNode.unfocus();
                                  });
                
                                  _fetchWeatherData(location.name, location.country, location.countryCode);
                                },
                                child: Column(
                                  children: [
                                    SearchResult(
                                      cityName: location.name,
                                      countryName: location.country,
                                      countryCode: location.countryCode,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                
                          ],
                        )
                      ],
                    )
                        : const SizedBox.shrink(),
                
                    // Error message
                    showErrorMessage ? Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 30),
                        child: GlassContainer(
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ) : const SizedBox.shrink(),
                
                    // Drawer Button
                    IconButton(
                        onPressed: () {
                          if (_key.currentState!.isDrawerOpen) {
                            _key.currentState!.closeDrawer();
                          } else {
                            _key.currentState!.openDrawer();
                          }
                        },
                        icon: Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 30,
                        )
                    ),
                
                  ],
                ),
              ),
            ),
          ),

          // Drawer
          drawer: Drawer(
            backgroundColor: Colors.black,
            width: MediaQuery.of(context).size.width * 0.5,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  color: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  alignment: Alignment.bottomLeft,
                  child: const Text(
                    "ForWeather",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                /// Use Expanded to fill the remaining space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.settings, color: primaryColor),
                        title: Text(
                          "Settings",
                          style: TextStyle(color: primaryColor),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsPage(currentColour: primaryColor),
                            ),
                          );
                        },
                      ),
                      const Spacer(), // Push the version to the bottom
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Version 1.0.0",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white54,
                              ),
                            ),
                            Text(
                              "© 2025 ForWeather",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "Made with ❤️ by ",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white54,
                                  ),
                                ),
                                Text(
                                  "Jack Trowbridge",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white54,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        );
      }
    );
  }
}


class DayWeatherCard extends StatelessWidget {
  const DayWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        spacing: 8,
        children: [
          Text(
            "26°",
          ),
          Icon(
            Icons.wb_sunny_outlined,
            color: Colors.black,
          ),
          Text("21 Jan")
        ],
      ),
    );
  }
}


