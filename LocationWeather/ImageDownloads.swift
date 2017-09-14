//
//  ImageDownloads.swift
//  GPSWeather
//
//  Created by win on 9/14/17.
//  Copyright © 2017 win. All rights reserved.
//

import UIKit

// Extension to download images with URL
extension UIImageView {
    func downloadImage(from url: String) {
        let urlRequest = URLRequest(url: URL(string: url)!)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if error == nil {
                DispatchQueue.main.async {
                    // Set image to image view
                    self.image = UIImage(data: data!)
                }
            }
        }
        task.resume()
    }
}
