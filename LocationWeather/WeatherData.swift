//
//  WeatherData.swift
//  GPSWeather
//
//  Created by win on 8/6/17.
//  Copyright © 2017 win. All rights reserved.
//

import Foundation
import CoreLocation

struct WeatherData {
    
    // MARK: - Properties
    
    // API key to access information, not needed for Yahoo
    private static let OpenWeatherMapApiKey: String = "824dd6d74ce055192cd6f4983c761161"
    private static let OpenWeatherMap: String = "OpenWeatherMap"
    private static let Yahoo: String = "Yahoo"
    
    // MARK: - Methods
    
    // Get web api response and pass on to completion handler - UpdateAllViews
    static func getWeatherDetails(_ placemark: CLPlacemark, _ weatherDataSource: String, _ completion: @escaping (CLPlacemark, [String : String], Error?) -> ()) {
        print("getWeatherDetails >")
        var encodedURL = ""
        var weatherForecast: [String:String] = [:]
        let latitude = placemark.location!.coordinate.latitude
        let longitude = placemark.location!.coordinate.longitude
        
        if weatherDataSource == OpenWeatherMap {
            let url = "http://api.openweathermap.org/data/2.5/forecast/daily?lat=\(latitude)&lon=\(longitude)&units=metric&appid=\(OpenWeatherMapApiKey)"
            encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        }
        else if weatherDataSource == Yahoo {
            let url = "http://query.yahooapis.com/v1/public/yql?q=select * from weather.forecast where woeid in (SELECT woeid FROM geo.places WHERE text=\"(\(latitude),\(longitude))\") and u='c'&format=json"
            encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
        }
        
        let urlRequest = URLRequest(url: URL(string: encodedURL)!)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            print("URL Session >>")
            if error != nil {
                DispatchQueue.main.async {
                    completion(placemark, weatherForecast, error!)
                }
            } else {
                weatherForecast = parseJson(data!, weatherDataSource)
                DispatchQueue.main.async {
                    completion(placemark, weatherForecast, nil)
                }
            }
            print("URL Session <<")
        }
        task.resume()
        print("getWeatherDetails <")
    }
    
    // Parse JSON data based on weather source site
    // Returns: countryInitials, temp, condition, imageUrl, day1, tempMin1,tempMax1, condition1, imageUrl1, day2, tempMin2, tempMax2, condition2, imageUrl2, day3, tempMin3, tempMax3, condition3, imageUrl3
    private static func parseJson(_ jsonData: Data, _ weatherSource: String) -> [String : String] {
        print("parseJson >")
        var weatherForecast: [String : String] = [:]
        do {
            let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as! NSDictionary
            if weatherSource == OpenWeatherMap {
                weatherForecast = parseOpenWeatherMapForecast(json)
            }
            else if weatherSource == Yahoo {
                weatherForecast = parseYahooForecast(json)
            }
        } catch let error {
            print("JSON Error: \(error.localizedDescription)")
        }
        print("parseJson <")
        return weatherForecast
    }
    
    // Parse JSON data for Open Weather Map
    private static func parseOpenWeatherMapForecast(_ json: NSDictionary) -> [String:String] {
        print("parseOpenWeatherMapForecast >")
        var openWeatherMapForecast: [String:String] = [:]
        // Get weather details
        if let location = json["city"] as? NSDictionary, let countryInitials = location["country"] as? String {
            openWeatherMapForecast["countryInitials"] = "\(countryInitials)"
        }
        // Return if forecast not readable
        guard let forecast = json["list"] as? NSArray, let forecast0 = forecast[0] as? NSDictionary, let forecast1 = forecast[1] as? NSDictionary, let forecast2 = forecast[2] as? NSDictionary, let forecast3 = forecast[3] as? NSDictionary else {
            // Unable to read forecast / Incomplete data
            return openWeatherMapForecast
        }
        // Current condition
        if let tempDetails = forecast0["temp"] as? NSDictionary, let temperature = tempDetails["day"] as? Double {
            openWeatherMapForecast["temp"] = "\(Int(temperature.rounded()))"
        }
        if let weather = forecast0["weather"] as? NSArray, let items = weather[0] as? NSDictionary, let condition = items["description"] as? String, let weatherIcon = items["icon"] {
            openWeatherMapForecast["condition"] = (condition.capitalized)
            openWeatherMapForecast["imageUrl"] = ("http://openweathermap.org/img/w/\(weatherIcon).png")
        }
        // Forecast Day1
        if let tempDetails = forecast1["temp"] as? NSDictionary, let tempMin = tempDetails["min"] as? Double, let tempMax = tempDetails["max"] as? Double {
            openWeatherMapForecast["tempMin1"] = "\(Int(tempMin.rounded()))"
            openWeatherMapForecast["tempMax1"] = "\(Int(tempMax.rounded()))"
        }
        if let weather = forecast1["weather"] as? NSArray, let items = weather[0] as? NSDictionary, let condition = items["description"] as? String, let weatherIcon = items["icon"] {
            openWeatherMapForecast["condition1"] = (condition.capitalized)
            openWeatherMapForecast["imageUrl1"] = ("http://openweathermap.org/img/w/\(weatherIcon).png")
        }
        // Forecast Day2
        if let tempDetails = forecast2["temp"] as? NSDictionary, let tempMin = tempDetails["min"] as? Double, let tempMax = tempDetails["max"] as? Double {
            openWeatherMapForecast["tempMin2"] = "\(Int(tempMin.rounded()))"
            openWeatherMapForecast["tempMax2"] = "\(Int(tempMax.rounded()))"
        }
        if let weather = forecast2["weather"] as? NSArray, let items = weather[0] as? NSDictionary, let condition = items["description"] as? String, let weatherIcon = items["icon"] {
            openWeatherMapForecast["condition2"] = (condition.capitalized)
            openWeatherMapForecast["imageUrl2"] = ("http://openweathermap.org/img/w/\(weatherIcon).png")
        }
        // Forecast Day3
        if let tempDetails = forecast3["temp"] as? NSDictionary, let tempMin = tempDetails["min"] as? Double, let tempMax = tempDetails["max"] as? Double {
            openWeatherMapForecast["tempMin3"] = "\(Int(tempMin.rounded()))"
            openWeatherMapForecast["tempMax3"] = "\(Int(tempMax.rounded()))"
        }
        if let weather = forecast3["weather"] as? NSArray, let items = weather[0] as? NSDictionary, let condition = items["description"] as? String, let weatherIcon = items["icon"] {
            openWeatherMapForecast["condition3"] = (condition.capitalized)
            openWeatherMapForecast["imageUrl3"] = ("http://openweathermap.org/img/w/\(weatherIcon).png")
        }
        
        // Get next 3 days of the week(Fri, Sat, ...) from calender if weather details are found
        // OpenWeatherMap doesn't provide forecast by day names
        if !openWeatherMapForecast.isEmpty {
            let days = getNextThreeDaysOfWeek()
            openWeatherMapForecast["day1"] = days[0]
            openWeatherMapForecast["day2"] = days[1]
            openWeatherMapForecast["day3"] = days[2]
        }
        print("parseOpenWeatherMapForecast <")
        return openWeatherMapForecast
    }
    
    // Parse JSON data for Yahoo
    private static func parseYahooForecast(_ json: NSDictionary) -> [String:String] {
        print("parseYahooForecast >")
        var yahooForecast: [String:String] = [:]
        // Return if json data not readable
        guard let query = json["query"] as? NSDictionary, let results = query["results"] as? NSDictionary, let channel = results["channel"] as? NSDictionary, let item = channel["item"] as? NSDictionary else {
            // Unable to read data
            return yahooForecast
        }
        // Get country initials "London, UK"
        if let title = item["title"] as? String {
            let startIndex = title.index(title.endIndex, offsetBy: -19)
            let endIndex = title.index(title.endIndex, offsetBy: -16)
            let range = startIndex..<endIndex
            let countryInitials = (title.substring(with: range)).replacingOccurrences(of: " ", with: "")
            yahooForecast["countryInitials"] = countryInitials
        }
        // Get current weather condition
        if  let condition = item["condition"] as? NSDictionary, let temperature = condition["temp"] as? String, let description = condition["text"] as? String, let weatherIcon = condition["code"] {
            yahooForecast["temp"] = temperature
            yahooForecast["condition"] = description
            yahooForecast["imageUrl"] = "http://l.yimg.com/a/i/us/we/52/\(weatherIcon).gif"
        }
        // Get forecast: Start from forecast[1] -> next day onward
        guard let forecast = item["forecast"] as? NSArray, let day1 = forecast[1] as? NSDictionary, let day2 = forecast[2] as? NSDictionary, let day3 = forecast[3] as? NSDictionary else {
            // Unable to read forecast / Incomplete data
            return yahooForecast
        }
        // Forecast Day 1
        if let day = day1["day"] as? String, let lowTemp = day1["low"] as? String, let highTemp = day1["high"] as? String, let condition = day1["text"] as? String, let icon = day1["code"] {
            yahooForecast["day1"] = day
            yahooForecast["tempMin1"] = lowTemp
            yahooForecast["tempMax1"] = highTemp
            yahooForecast["condition1"] = condition
            yahooForecast["imageUrl1"] = "http://l.yimg.com/a/i/us/we/52/\(icon).gif"
        }
        // Forecast Day 2
        if let day = day2["day"] as? String, let lowTemp = day2["low"] as? String, let highTemp = day2["high"] as? String, let condition = day2["text"] as? String, let icon = day2["code"] {
            yahooForecast["day2"] = day
            yahooForecast["tempMin2"] = lowTemp
            yahooForecast["tempMax2"] = highTemp
            yahooForecast["condition2"] = condition
            yahooForecast["imageUrl2"] = "http://l.yimg.com/a/i/us/we/52/\(icon).gif"
        }
        // Forecast Day 3
        if let day = day3["day"] as? String, let lowTemp = day3["low"] as? String, let highTemp = day3["high"] as? String, let condition = day3["text"] as? String, let icon = day3["code"] {
            yahooForecast["day3"] = day
            yahooForecast["tempMin3"] = lowTemp
            yahooForecast["tempMax3"] = highTemp
            yahooForecast["condition3"] = condition
            yahooForecast["imageUrl3"] = "http://l.yimg.com/a/i/us/we/52/\(icon).gif"
        }
        print("parseYahooForecast <")
        return yahooForecast
    }
    
    // Get next three days of the week
    private static func getNextThreeDaysOfWeek() -> [String] {
        let today = Date()
        let gregorian = Calendar(identifier: .gregorian)
        let dateComponents = gregorian.dateComponents([.weekday], from: today)
        let todaysWeekday = dateComponents.weekday!
        var nextThreeDays: [Int] = []
        for i in 1...3 {
            nextThreeDays.append((todaysWeekday - 1 + i) % 7 + 1)
        }
        
        let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let nextThreeDaysNames = nextThreeDays.map({ weekdayNames[$0 - 1] })
        return nextThreeDaysNames
    }
    
}
