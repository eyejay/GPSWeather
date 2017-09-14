//
//  FavoritesTableViewController.swift
//  GPSWeather
//
//  Created by win on 8/3/17.
//  Copyright © 2017 win. All rights reserved.
//

import UIKit
import CoreLocation

class FavoritesTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Properties
    
    @IBOutlet weak var favoritesTableView: UITableView!
    let NoInternet = "No Internet: Weather data wont be displayed"
    var favoritesList: [String] = []
    let mainViewController = MainViewController()
    var weatherDataSource:String = ""
    var tableData: [[String:String]] = []
    var data: [[String:String]] = []
    var selectedCity:String = ""
    var noInternetEntry: Bool = false
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("FavoritesTableView viewDidLoad >")
        // Load favorite locations list
        if let history = UserDefaults.standard.stringArray(forKey: "userFavorites") {
            favoritesList = history
            print("favoriteHistory: \(favoritesList)")
        }
        print("FavoritesTableView viewDidLoad <")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("FavoritesTableView viewWillAppear >")
        
        if !mainViewController.isInternetAvailable() {
            print("display alert")
            let alertController = UIAlertController(title: "Alert", message: NoInternet, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        } else {
            // Get values ready for the table
            getTableData()
        }
        print("FavoritesTableView viewWillAppear <")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table View DataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Number of cells in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !mainViewController.isInternetAvailable() {
            noInternetEntry = true
            return favoritesList.count
        }
        return tableData.count
    }
    
    // Monitor row selection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if !noInternetEntry  {
            selectedCity = tableData[indexPath.row]["location"]!
            performSegue(withIdentifier: "backToMain", sender: self)
        }
    }
    
    // Remove the favorite from storage and table view if row is swiped and Delete is clicked Online/Offline
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print("tableView editingStyle >")
        if editingStyle == UITableViewCellEditingStyle.delete {
            
            if noInternetEntry {
                // Delete a favorite offline
                // Pick selected favorite
                let location = favoritesList[indexPath.row]
                print("Selected City: \(location)")
                // Remove selected favorite from the tableView's data list
                print("\(location): removing from userFavorites: \(favoritesList)")
                favoritesList.remove(at: indexPath.row)
                UserDefaults.standard.set(favoritesList, forKey: "userFavorites")
            } else {
                // Pick selected favorite
                let location = tableData[indexPath.row]["location"]!
                print("Selected City: \(location)")
                // Remove selected favorite from the tableView's data list
                tableData.remove(at: indexPath.row)
                
                // Remove selected favorite from the storage
                let index = favoritesList.index(of:location)
                print("\(location) removing from userFavorites: \(favoritesList)")
                favoritesList.remove(at: index!)
                UserDefaults.standard.set(favoritesList, forKey: "userFavorites")
            }
            // Reload table view
            tableView.reloadData()
        }
        print("tableView editingStyle <")
    }
    
    // Update the values of table view cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! FavoritesTableViewCell
        let index = indexPath.row
        
        if noInternetEntry {
            cell.cityName.text = favoritesList[index]
            cell.temperature.text = "--°C"
            return cell
        }
        cell.cityName.text = tableData[index]["location"]!
        cell.temperature.text = "\(tableData[index]["temp"]!)°C"
        cell.descriptionImage.downloadImage(from: tableData[index]["imageUrl"]!)
      
        return cell
    }
    
    // MARK - Methods
    
    // Process locality/city name and fetch weather data
    func getTableData() {
        print("getTableData >")
        for item in favoritesList {
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(item) { (placemarks, error) in
                print("forwardGeoCoder >>")
                if let error = error {
                    print("forwardGeocoder Error: \(error.localizedDescription)")
                } else {
                    if let placemarks = placemarks, placemarks.count > 0, let placemark = placemarks.first {
                        // Fetch weather data - completion: update views
                        WeatherData.getWeatherDetails(placemark, self.weatherDataSource, self.updateTableData)
                    } else {
                        print("Problems with data received from geocoder")
                    }
                }
                print("forwardGeoCoder <<")
            }
        }
        print("getTableData <")
    }
    
    // Update location and temperature details into array and reload table view
    func updateTableData(_ placemark: CLPlacemark, _ weatherDetails: [String:String], _ error: Error?) {
        print("updateTableData >")
        if error == nil && !weatherDetails.isEmpty {
            if let temperature = weatherDetails["temp"], let imageURL = weatherDetails["imageUrl"], let countryInitials = weatherDetails["countryInitials"], let placemarkName = placemark.name {
                // Add location and weather details to data source
                let cityCountryInitials = "\(placemarkName), \(countryInitials)"
                data.append(["location":cityCountryInitials, "temp":temperature, "imageUrl":imageURL])
                //print("location: \(cityCountryInitials) temp: \(temperature) imageUrl: \(imageURL)")
                //print("tableDadatCount: \(data.count) favCount: \(favoritesList.count)")
            }
        }
        // Only update the table view once all locations are processed/added
        if data.count == favoritesList.count {
            // Set main table data source after sorting data in alphabetical order of location/city names
            tableData = data.sorted { $0["location"]! < $1["location"]! }
            // Reload table cells once data source is ready
            favoritesTableView.reloadData()
        }
        print("updateTableData <")
    }
    
    // MARK: - Actions
    
    // Go back to main view if cancel is pressed
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        noInternetEntry = false
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    
    // Triggered from didSelectRowAt to unwind back to main view and open passed location
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("prepare unwind segue >")
        if segue.identifier == "backToMain" {
            print("Prepare segue back to main >")
            let destinationViewController = segue.destination as! MainViewController
            // Set selected city row in the main view controller
            destinationViewController.currentLocation = selectedCity
            // Get destination view controller ready to display selected city
            destinationViewController.isComingFromFavoritesOrBackground = true
            if destinationViewController.currentLocationSwitch.isOn {
                destinationViewController.currentLocationSwitch.isOn = false
                destinationViewController.searchBar.isEnabled = true
            }
        }
        print("Prepare unwind segue <")
    }
    
    
}
