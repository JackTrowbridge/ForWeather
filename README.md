# ForWeather
A simple weather app which shows your place's temperature, humidity, visibility, and wind speed.

The app includes changing your preferred temperature unit to celsius or fahrenheit, and the background colour changes based on the weather type.

This app utilizes APIs such as OpenWeatherMap("https://openweathermap.org/") and Algolia("https://www.algolia.com/"). Algolia is used for the search feature to search cities.

# First Run

Clone the repository, either downloading it as a zip or clone it via the GitHub CLI.

Then install the dependencies.
```
flutter pub get
```

### API Keys
To ensure security, I have not added the API keys to this repo. Instead you'll have to make your own.

I've added a `.envEXAMPLE` file which you'll find in the project's root structure. Simply duplicate the file and rename it to `.env`
```
root:
  - .envEXAMPLE (Duplicate this and/or rename it to .env)
```

### Run the app
After successfully installing the dependencies, and setting up your API keys. You can now run the project in debug mode using the following command.
```
flutter run --debug
```
Alternatively, if you're using Android Studio then you can just press play with your device connected and it should run everything for you.

Your app should now be running in the emulator, or on a phone if you have it connected.

# Need help?
If you encounter any issues or have questions, feel free to contact me through my email `jjt2004@icloud.com`, or create an issue on this Github page. Thanks!
