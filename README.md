# GPSWeather

Simple iOS Weather app that displays user's current location or desired place on the map as well as current weather condition with forecast, fetched from one of two available sources. Option to set a location as favorite. Favorites view displays all locations with current weather conditions. Option to remove a location from favorites view or open it's detailed forecast on main view. Option to save the screenshot or share on social media.

### Technologies: 
iOS, XCode 8.2 Beta, Swift 3, XML, JSON, Git 
### Layout: 
Auto layouts tested in storyboard for iPhone 4s, SE, 7, 7s
Auto layouts tested in simulator for iPhone 5 to iPhone 7s
### Deployment Target:
Current deployment target set to iOS 9.3 devices for testing on real device

## Completed Tasks:

- Get GPS location through phone's' location services.
- Reverse geocode coordinates to match location address(city etc).
- Geocode location to match coordinates latitude/longitude.
- Basic UI that displays current user location on the map and shows city, temperature country.
- UI - Added street and weather description values.
- All location services availability checks and alerts to avoid crash.
- Tested with Json response from Yahoo Weather/OpenWeatherMap Apis. 
- UI - Switch between user location and open search. 
- UI - User to be able to search a location and set as favorite. 
- UI - Favorite locations to be displayed on a table view with current weather condition.
- UI - Added weather description icons.
- More restrictions on user input, resigning/gaining first responder
- Stored favorite locations locally.
- App handling going to background and foregournd.
- Enable/Disable functionalities based on availability of data connection and location services
- UI - Startup view
- Option to choose source from Yahoo/OpenWeatherMap
- Change background music based on weather description cear/rain/thunderstorm.
- Code cleaning and optimization
- Fixed issues related to yahoo api, changed query to fetch data using coordinates and parsed new json response.
- UI - Added three-day forecast
- UI - Added support for deleting favorites directly from favorites view
- UI - Added support for openning locations' forecasts directly from favorites view
- UI - Commercial application look and feel, layout for iPhone 7
- Bug fixing, code cleaning
- Added screenshots
- UI - Added support for saving or sharing screenshot on social media
- Auto layouts

## Ongoing/Possible Tasks:
- Location and weather to be updated with map view swipes.
- Testing/Bug fixing

## Source Files Details:

### StartPageViewController
Displays main page and forwards user's' selection for weather data source to MainViewController

### MainViewController 
Holds location manager, uses Geocoder to fetch location to pass on to WeatherData which fetches weather condition and forecast details to update main views using completion handler. Provides options to search weather at user's' location or random search and navigates to either back to Start view or Favorites view.

### WeatherData 
Receives location placemark and fetches weather data from the given/chosen source. Parses JSON response with helper method and returns key weather details in a dictionary.

### FavoritesTableViewController
Manages table view for user’s favorites locations history and updates rows with FavoritesTableViewCells. Option to delete a favorite location or open directly in main page with forecast.

### FavoritesTableViewCells 
Contains views to display location, temperature and weather condtion image.

### ImageDownloads 
Extension to UIImageView to download images with URL
