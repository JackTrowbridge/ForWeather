import 'package:flutter/material.dart';
import 'package:forweather/views/widgets/glass_container.dart';
class SearchResult extends StatelessWidget {
  final String? cityName;
  final String? countryName;
  final String? countryCode;
  const SearchResult({super.key, required this.cityName, required this.countryName, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Colors.black,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$cityName",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "$countryName",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }
}
