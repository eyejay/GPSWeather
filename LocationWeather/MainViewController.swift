//
//  MainViewController.swift
//  GPSWeather
//
//  Created by win on 7/31/17.
//  Copyright © 2017 win. All rights reserved.
//

import UIKit
// Location services
import CoreLocation
// Map view
import MapKit
// Internet connectivity
import SystemConfiguration
// Audio/Video handling
import AVFoundation

class MainViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    // MARK: - Properties
    
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var favoriteStar: UIButton!
    @IBOutlet weak var currentLocationSwitch: UISwitch!
    @IBOutlet weak var weatherConditionLabel: UILabel!
    @IBOutlet weak var termperatureLabel: UILabel!
    @IBOutlet weak var weatherConditionImage: UIImageView!
    @IBOutlet weak var soundButton: UIBarButtonItem!
    
    @IBOutlet weak var day1: UILabel!
    @IBOutlet weak var conditionImage1: UIImageView!
    @IBOutlet weak var temperature1: UILabel!
    @IBOutlet weak var day2: UILabel!
    @IBOutlet weak var conditionImage2: UIImageView!
    @IBOutlet weak var temperature2: UILabel!
    @IBOutlet weak var day3: UILabel!
    @IBOutlet weak var conditionImage3: UIImageView!
    @IBOutlet weak var temperature3: UILabel!
    @IBOutlet weak var weatherCondition1: UILabel!
    @IBOutlet weak var weatherCondition2: UILabel!
    @IBOutlet weak var weatherCondition3: UILabel!
    
    var player: AVAudioPlayer?
    var soundOn: Bool = true
    
    // Weather data
    var weatherCondition: String?
    var imageURL: String?
    var weatherDataSource: String?
    var countryInitials: String?
    let TotalNumberOfWeatherDetails: Int = 19
    
    // Location data
    var locationManager:CLLocationManager?
    let geoCoder = CLGeocoder()
    var currentLocation: String = ""
    // Area to display on map
    let latMeters: CLLocationDistance = 1600
    let longMeters: CLLocationDistance = 1600
    var isComingFromFavoritesOrBackground = false
    
    enum Setting {
        case generalLocationSetting
        case appSpecificLocationSetting
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad >")
        // Handle events through delegate callbacks
        searchBar.delegate = self
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        // Set mapview hidden at the start
        mapView.isHidden = true
        // Monitor app going to background and foreground
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillDisappear), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(viewWillAppear), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
      print("viewDidLoad <")
    }
        
    override func viewWillAppear(_ animated: Bool) {
        print("vieWillAppear >")
        super.viewDidAppear(true)
        
        // Continue if location services are enabled and user location switch is on
        if isComingFromFavoritesOrBackground {
            if currentLocationSwitch.isOn {
                let status = CLLocationManager.authorizationStatus()
                checkLocationServicesAuthorization(status)
            } else {
                // Coming back from background or table view controller
                resetView()
                if currentLocation != "" {
                    getLocationCoordinatesAndWeatherFromLocality(currentLocation)
                    searchBar.resignFirstResponder()
                }
            }
            isComingFromFavoritesOrBackground = false
        }
        print("viewWillAppear <")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("viewWillDisappear >")
        stopPlayback()
        isComingFromFavoritesOrBackground = true
        locationManager?.stopUpdatingLocation()
        print("viewWillDisappear <")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    // Keeps updating current user location on the map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        // Keep updating user location on the map view
        showMapWithLocation(location!, 500, 500)
    }
    
    // Monitor location services authorization changes
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("locationManager didChangeAuthorization >")
        checkLocationServicesAuthorization(status)
    }
    
    // Monitors location manager errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - UITextFieldDelegate
    
    // On Return key, hide keyboard and process text search
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !currentLocationSwitch.isOn {
            if searchBar.text == "" {
                displayAlert("Enter city name to search")
            } else {
                searchBar.resignFirstResponder()
                let searchText = searchBar.text!
                // Process text search - get location coordinates and weather data based on locality/city name
                getLocationCoordinatesAndWeatherFromLocality(searchText)
            }
            print("textFieldDidEndEditing <")
        }
        return true
    }
    
    // End editing and hide keyboard on touch outside
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        searchBar.resignFirstResponder()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        searchBar.text = ""
    }
    
    // MARK: - Methods
    
    // Process  location coordinates to fetch locality/city name and weather data
    func getAddressAndWeatherFromLocationCoordinates() {
        print("getAddressAndWeatherFromLocationCoordinates >")
        // If internet is not available, return
        if !isInternetAvailable() {
            displayAlert("No internet! Please check your data connection settings to continue")
            return
        }
        guard let coordinates = locationManager?.location else {
            print("Location manager returned no coordinates")
            displayAlert("No coordinates found, please try again")
            return
        }
        // Process coordinates
        geoCoder.reverseGeocodeLocation(coordinates) { (placemarks, error) in
            print("reverseGeocoder >>")
            if let error = error {
                DispatchQueue.main.async {
                    print("reverseGeocoder Error: \(error.localizedDescription)")
                    self.displayAlert("Reverse geocoding failed, please try again")
                }
            } else {
                if let placemarks = placemarks, placemarks.count > 0, let placemark = placemarks.first {
                    // Fetch weather data - completion: update views
                    WeatherData.getWeatherDetails(placemark, self.weatherDataSource!, self.updateAllViews)
                } else {
                    print("Problems with data received from geocoder")
                }
            }
            print("reverseGeoCoder <<")
        }
        print("getAddressAndWeatherFromLocationCoordinates <")
    }
    
    // Process locality/city name to fetch location coordinates and weather data
    func getLocationCoordinatesAndWeatherFromLocality(_ searchText: String) {
        print("getLocationCoordinatesAndWeatherFromLocality >")
        stopPlayback()
        // If internet is not available, return
        if !isInternetAvailable() {
            displayAlert("No internet! Please check your data connection settings to continue")
            return
        }
        print("searchText: \(searchText)")
        geoCoder.geocodeAddressString(searchText) { (placemarks, error) in
            print("forwardGeoCoder >>")
            if let error = error {
                DispatchQueue.main.async {
                    print("forwardGeocoder Error: \(error.localizedDescription)")
                    self.displayAlert("Location \(searchText) not found or invalid!")
                    self.resetView()
                }
            } else {
                if let placemarks = placemarks, placemarks.count > 0, let placemark = placemarks.first, let _ = placemark.locality {
                    // Locality found, fetch weather data - completion: update views
                    WeatherData.getWeatherDetails(placemark, self.weatherDataSource!, self.updateAllViews)
                } else {
                    if let placemarks = placemarks, placemarks.count > 0, let placemark = placemarks.first {
                        print("name: \(placemark.name) locality: \(placemark.locality) country: \(placemark.country) sublocality: \(placemark.subLocality) administrativeArea: \(placemark.administrativeArea) subAdm: \(placemark.subAdministrativeArea)")}
                    print("Problems with data received from geocoder Or country name")
                    self.displayAlert("\(searchText) is not a valid city!")
                }
            }
            print("forwardGeoCoder <<")
        }
        print("getLocationCoordinatesAndWeatherFromLocality <")
    }
    
    // Update all views
    // [weatherDetails:response] = countryInitials, temp, condition, imageUrl, day1, tempMin1,tempMax1, condition1, imageUrl1, day2, tempMin2, tempMax2, condition2, imageUrl2, day3, tempMin3, tempMax3, condition3, imageUrl3
    func updateAllViews(_ placemark: CLPlacemark, _ weatherDetails: [String : String], _ error: Error?) {
        print("updateAllViews >")
        if error != nil {
            print("URL Error: \(error!.localizedDescription)")
            displayAlert("Unable to fetch weather data. Please refresh.")
        } else if weatherDetails.isEmpty || weatherDetails.count != TotalNumberOfWeatherDetails {
            // Display alert if unable to fetch complete weather details
            print("JSON Error")
            displayAlert("Unable to fetch weather data. Please refresh.")
        } else {
            if let temp = weatherDetails["temp"], let condition = weatherDetails["condition"], let imageUrl = weatherDetails["imageUrl"], let countryInit = weatherDetails["countryInitials"] {
                // Update current weather condition
                termperatureLabel.text = "\(temp)°C"
                weatherConditionLabel.text = condition
                weatherCondition = condition
                countryInitials = countryInit
                weatherConditionImage.downloadImage(from: imageUrl)
                if soundOn {
                    playSound(weatherCondition!)
                }
            }
            if let daily1 = weatherDetails["day1"], let tempMin1 = weatherDetails["tempMin1"], let tempMax1 = weatherDetails["tempMax1"], let condition1 = weatherDetails["condition1"], let imageUrl1 = weatherDetails["imageUrl1"], let daily2 = weatherDetails["day2"], let tempMin2 = weatherDetails["tempMin2"], let tempMax2 = weatherDetails["tempMax2"], let condition2 = weatherDetails["condition2"], let imageUrl2 = weatherDetails["imageUrl2"], let daily3 = weatherDetails["day3"], let tempMin3 = weatherDetails["tempMin3"], let tempMax3 = weatherDetails["tempMax3"], let condition3 = weatherDetails["condition3"], let imageUrl3 = weatherDetails["imageUrl3"] {
                // Update Forecast
                day1.text = daily1
                let temp1 = "\(tempMax1)/\(tempMin1)°C"
                temperature1.text = temp1
                conditionImage1.downloadImage(from: imageUrl1)
                weatherCondition1.text = condition1
                day2.text = daily2
                let temp2 = "\(tempMax2)/\(tempMin2)°C"
                temperature2.text = temp2
                conditionImage2.downloadImage(from: imageUrl2)
                weatherCondition2.text = condition2
                day3.text = daily3
                let temp3 = "\(tempMax3)/\(tempMin3)°C"
                temperature3.text = temp3
                conditionImage3.downloadImage(from: imageUrl3)
                weatherCondition3.text = condition3
            }
            if weatherConditionImage.isHidden {
                weatherConditionImage.isHidden = false
                conditionImage1.isHidden = false
                conditionImage2.isHidden = false
                conditionImage3.isHidden = false
            }
        }
        // Update location data even if weather data unavailable
        if let locality = placemark.locality, let country = placemark.country, let coordinates = placemark.location {
            countryLabel.text = country
            cityLabel.text = locality
            currentLocation = "\(locality), \(countryInitials!)"
            if let street = placemark.thoroughfare {
                if currentLocationSwitch.isOn {
                    streetLabel.text = street
                }
            }
            // If user is in search mode, show searched location on the map
            if !currentLocationSwitch.isOn {
                showMapWithLocation(coordinates, latMeters, longMeters)
            } else {
                locationManager?.startUpdatingLocation()
            }
            // Set favorite image if location exists
            setFavoriteImage()
        }
        print("updateAllViews <")
    }
    
    // Show location on the map based on coordinates and distance span
    func showMapWithLocation(_ location: CLLocation, _ latitudinalMeters: CLLocationDistance, _ longitudinalMeters: CLLocationDistance) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        let myLocation = CLLocationCoordinate2DMake(latitude, longitude)
        let region:MKCoordinateRegion = MKCoordinateRegionMakeWithDistance(myLocation, latitudinalMeters, longitudinalMeters)
        mapView.setRegion(region, animated: true)
        self.mapView.showsUserLocation = true
        mapView.isHidden = false
    }
    
    // Display alert with Open Location Settings
    func displayOpenSettingsAlert(_ setting: Setting) {
        print("displayOpenSettingsAlert >")
        let title = "Location services are not enabled"
        let msg = "To use this app, you need to enable Location Services"
        let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Settings", style: .default) { value in
            var path = ""
            if setting == Setting.generalLocationSetting {
                path = "App-Prefs:root=Privacy&path=LOCATION"
            } else {
                path = UIApplicationOpenSettingsURLString
            }
            if let settingsURL = URL(string: path), UIApplication.shared.canOpenURL(settingsURL) {
                UIApplication.shared.openURL(settingsURL)
            }
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Display alert with Ok action
    func displayAlert(_ message: String){
        print("displayAlert >")
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // Sets the star image if location exists after search
    func setFavoriteImage() {
        print("setFavoriteImage >")
        if let savedFavorites = UserDefaults.standard.stringArray(forKey: "userFavorites") {
            savedFavorites.contains(currentLocation) ? favoriteStar.setImage(UIImage(named: "favoriteStar"), for: .normal) : favoriteStar.setImage(UIImage(named: "emptyStar"), for: .normal)
        }
        print("setFavoriteImage <")
    }
    
    // Check if location exists in favorites, add if it does not, remove otherwise
    func addRemoveFavorites() {
        print("addRemoveFavorites >")
        var savedFavorites = [String]()
        if let history = UserDefaults.standard.stringArray(forKey: "userFavorites") {
            savedFavorites = history
            if savedFavorites.contains(currentLocation) {
                // Location exists in favorits - remove from favorites
                if let index = savedFavorites.index(of:currentLocation) {
                    savedFavorites.remove(at: index)
                    UserDefaults.standard.set(savedFavorites, forKey: "userFavorites")
                    favoriteStar.setImage(UIImage(named: "emptyStar"), for: .normal)
                    print("\(currentLocation) removed from userFavorites: \(savedFavorites)")
                }
            } else {
                // Location doesn't exist in favorites - add to favorites
                savedFavorites.insert(currentLocation, at: 0)
                UserDefaults.standard.set(savedFavorites, forKey: "userFavorites")
                favoriteStar.setImage(UIImage(named: "favoriteStar"), for: .normal)
                print("\(currentLocation) added to userFavorites: \(savedFavorites)")
                
            }
        } else {
            // Only first time - key userFovorites does not exist, create new
            savedFavorites.append(currentLocation)
            UserDefaults.standard.set(savedFavorites, forKey: "userFavorites")
            favoriteStar.setImage(UIImage(named: "favoriteStar"), for: .normal)
            print("\(currentLocation) added to empty userFavorites: \(savedFavorites)")
        }
        print("addRemoveFavorites <")
    }
    
    // Check if application is authorized to use location services 
    func checkLocationServicesAuthorization(_ status: CLAuthorizationStatus) {
        print("checkLocationServicesAuthorization >")
        switch status {
        case .notDetermined:
            // Request in app use authorization.
            locationManager?.requestWhenInUseAuthorization()
            break
        case .denied, .restricted:
            print("Location services denied status: \(status.rawValue)")
            if CLLocationManager.locationServicesEnabled() {
                // Display alert with app specific Location Settings action
                displayOpenSettingsAlert(Setting.appSpecificLocationSetting)
            } else {
                print("Location services disabled. Display alert message")
                //Location services disabled. Display alert with general location settings
                displayOpenSettingsAlert(Setting.generalLocationSetting)
            }
            break
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location services authorized")
            // Process location and weather data based on location coordinates
            getAddressAndWeatherFromLocationCoordinates()
            break
        }
        print("checkLocationServicesAuthorization <")
    }
    
    // Check internet connectivity
    func isInternetAvailable() -> Bool
    {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
    
    // Reset label texts
    func resetView() {
        searchBar.text = ""
        mapView.isHidden = true
        cityLabel.text = ""
        countryLabel.text = ""
        streetLabel.text = ""
        
        day1.text = ""
        day2.text = ""
        day3.text = ""
        temperature1.text = ""
        temperature2.text = ""
        temperature3.text = ""
        termperatureLabel.text = ""
        weatherCondition1.text = ""
        weatherCondition2.text = ""
        weatherCondition3.text = ""
        weatherConditionLabel.text = ""
        conditionImage1.isHidden = true
        conditionImage2.isHidden = true
        conditionImage3.isHidden = true
        weatherConditionImage.isHidden = true
        favoriteStar.setImage(UIImage(named: "emptyStar"), for: .normal)
        
        stopPlayback()
        if isInternetAvailable() {
            searchBar.isEnabled = true
            searchBar.becomeFirstResponder()
        } else {
            displayAlert("Search Disabled: No internet connection")
        }
    }
    
    // Play sounds
    func playSound(_ description: String){
        var sound = ""
        if description.contains("Rain") {
            sound = "rain"
        } else if description.contains("Shower") {
            sound = "shower"
        } else if description.contains("Thunderstorm") {
            sound = "thunderstorm"
        } else {
            sound = "clear"
        }
        guard let url = Bundle.main.url(forResource: sound, withExtension: "mp3") else {
            print("Sound file error")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            guard let player = player else { return }
            player.prepareToPlay()
            player.play()
            player.numberOfLoops = -1
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // If player is playing, stop playback
    func stopPlayback() {
        guard let player = player else { return }
        if (player.isPlaying) {
            player.stop()
            player.currentTime = 0
        }
    }
    
    // MARK: - Actions
    
    // Set/Delete favorites
    @IBAction func setFavoritePressed(_ sender: UIButton) {
        if cityLabel.text != "" {
            addRemoveFavorites()
        }
    }
    
    // Switch between user location and search location
    @IBAction func userLocationSwitch(_ sender: UISwitch) {
        if sender.isOn {
            print("switch On")
            searchBar.text = ""
            searchBar.resignFirstResponder()
            searchBar.isEnabled = false
            mapView.isHidden = true
            stopPlayback()
            // Process location coordinates to get locality/city name and weather data
            getAddressAndWeatherFromLocationCoordinates()
        } else {
            print("switch Off")
            resetView()
            currentLocation = ""
            locationManager?.stopUpdatingLocation()
        }
    }
    
    // Show favorites table view
    @IBAction func goToFavorites(_ sender: Any) {
        print("goToFavorites >")
        stopPlayback()
        locationManager?.stopUpdatingLocation()
        performSegue(withIdentifier: "favorites", sender: self)
    }
    // Back to start page
    @IBAction func backToHome(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func refresh(_ sender: Any) {
        if currentLocationSwitch.isOn {
            stopPlayback()
            // Process location coordinates to get locality/city name and weather data
            getAddressAndWeatherFromLocationCoordinates()
        } else {
            if cityLabel.text != "" {
                // Process locality/city to get location coordinates and weather data
                getLocationCoordinatesAndWeatherFromLocality(currentLocation)
            }
        }
    }
    
    @IBAction func soundOnOff(_ sender: Any) {
        if soundOn {
            stopPlayback()
            soundOn = false
            soundButton.image = UIImage(named: "mute")
        }
        else {
            soundOn = true
            soundButton.image = UIImage(named: "speakerOn")
            if weatherConditionLabel.text != "" {
                playSound(weatherCondition!)
            }
        }
    }
    
    @IBAction func unwindToMainView(sender: UIStoryboardSegue) {
        
        // return the view from table view to main view
    }
    
    // Take screenshot and present activity view to save or share image on social media
    @IBAction func share(_ sender: Any) {
        
        // Capture snapshot if view is not empty
        if currentLocation != "" {
            UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, false, 0.0)
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
            let screenshot = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            // Show Activity View with sharing options
            let activityViewController = UIActivityViewController(activityItems: [screenshot!], applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "favorites" {
            let navController = segue.destination as! UINavigationController
            let destinationViewController = navController.topViewController as! FavoritesTableViewController
            // Pass weather data source to Favorites table view controller
            destinationViewController.weatherDataSource = weatherDataSource!
        }
    }

}


