//
//  StartPageViewController.swift
//  GPSWeather
//
//  Created by win on 8/8/17.
//  Copyright © 2017 win. All rights reserved.
//

import UIKit

class StartPageViewController: UIViewController {
    
    // MARK: - Properties
    private var weatherDataSource: String?
    private let OpenWeatherMap: String = "OpenWeatherMap"
    private let Yahoo: String = "Yahoo"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        let navController = segue.destination as! UINavigationController
        let destController = navController.topViewController as! MainViewController
        // Pass weather data source
        destController.weatherDataSource = weatherDataSource!
    }
    
    // MARK: - Actions
    
    @IBAction func yahooPressed(_ sender: UIButton) {
        weatherDataSource = Yahoo
        performSegue(withIdentifier: "main", sender: self)
    }
    
    @IBAction func openWeatherMapPressed(_ sender: UIButton) {
        weatherDataSource = OpenWeatherMap
        performSegue(withIdentifier: "main", sender: self)
    }
    
}
