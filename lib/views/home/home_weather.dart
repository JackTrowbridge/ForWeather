import 'dart:ui';

import 'package:algoliasearch/algoliasearch.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:easy_debounce/easy_throttle.dart';
import 'package:flutter/material.dart';
import 'package:forweather/api/api_key.dart';
import 'package:forweather/models/location.dart';
import 'package:intl/intl.dart';

import '../../models/current_weather.dart';
import '../../models/get_weather_object.dart';
import '../../utils/weather_api.dart';

class HomeWeather extends StatefulWidget {
  const HomeWeather({super.key});

  @override
  State<HomeWeather> createState() => _HomeWeatherState();
}

class _HomeWeatherState extends State<HomeWeather> {
  CurrentWeather? currentWeather;
  String currentDate = "";

  bool showSearchBar = true;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  bool isSearchFocused = false;

  List<Location> searchedLocations = [];

  @override
  void initState() {
    super.initState();

    searchFocusNode.addListener(_onSearchFocusChange);
    searchController.addListener(_searchCity);

    DateTime now = DateTime.now();
    setState(() {
      currentDate = DateFormat('EEEE, d MMMM').format(now);
    });

    // Fetch weather data when the widget is initialized
    _fetchWeatherData();
  }

  void _fetchWeatherData() async {
    print("Fetching weather data...");

    GetWeatherObject getWeatherObject =
        await WeatherAPI().getCurrentWeather("Portsmouth");

    if (getWeatherObject.statusCode == 200) {
      setState(() {
        currentWeather = getWeatherObject.currentWeather;
      });
    } else {
      print("Error fetching weather data: ${getWeatherObject.errorMessage}");
    }
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

    print("Searching for city: $input");
    setState(() {
      searchedLocations.clear();
    });

    final indexName = "dev_forweather";

    final client = SearchClient(
        appId: APIKey().getAlgoliaApplicationID(),
        apiKey: APIKey().getAlgoliaAPIKey());

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
      );

      setState(() {
        searchedLocations.add(location);
        print("Found location: ${location.name}, ${location.country}");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 66),
      body: SafeArea(
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
                        GestureDetector(
                          onTap: () {
                            // Handle location edit action
                            print("Edit location tapped");
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
                                Icons.edit,
                                color: Colors.black,
                                size: 32,
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
                          child: Text(
                            currentDate,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 255, 255, 66),
                            ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        // Current Weather
                        Row(
                          children: [
                            Text(
                              currentWeather != null
                                  ? currentWeather!.weatherType
                                  : "",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.cloud_outlined,
                              color: Colors.black,
                            )
                          ],
                        ),

                        const SizedBox(height: 31),
                        // Temperature
                        Text(
                          currentWeather != null
                              ? "${currentWeather!.temperature}°"
                              : "",
                          style: TextStyle(
                            fontSize: 177,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    )
                  ],
                ),

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
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 40,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.waves_outlined,
                                  color: Color.fromARGB(255, 255, 255, 66),
                                  size: 70,
                                ),
                                Text(
                                  currentWeather != null
                                      ? "${currentWeather!.windSpeed.toInt()}km/h"
                                      : "",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                ),
                                Text(
                                  "Wind",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.water_drop_outlined,
                                  color: Color.fromARGB(255, 255, 255, 66),
                                  size: 70,
                                ),
                                Text(
                                  currentWeather != null
                                      ? "${currentWeather!.humidity.toInt()}%"
                                      : "",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                ),
                                Text(
                                  "Humidity",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                )
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.remove_red_eye,
                                  color: Color.fromARGB(255, 255, 255, 66),
                                  size: 70,
                                ),
                                Text(
                                  currentWeather != null
                                      ? currentWeather!.visibility % 1 == 0
                                          ? "${currentWeather!.visibility.toInt()}km"
                                          : "${currentWeather!.visibility.toStringAsFixed(1)}km"
                                      : "",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                ),
                                Text(
                                  "Visibility",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color.fromARGB(255, 255, 255, 66),
                                  ),
                                )
                              ],
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
                          const SizedBox(height: 90),
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
                            Column(
                              children: [
                                SearchResult(
                                  cityName: location.name,
                                  countryName: location.country,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),

                        ],
                      )
                    ],
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
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

class GlassContainer extends StatelessWidget {
  final Widget child;
  final width;

  const GlassContainer({super.key, required this.child, this.width});

  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            width: width,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.all(Radius.circular(25)),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
            child: child,
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.all(Radius.circular(25)),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

class SearchResult extends StatelessWidget {
  final String? cityName;
  final String? countryName;
  const SearchResult({super.key, required this.cityName, required this.countryName});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Colors.black,
              size: 20,
            ),
            Flexible(
              child: Text(
                "$cityName, $countryName",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        )
    );
  }
}
