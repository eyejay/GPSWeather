//
//  FavoritesTableViewCell.swift
//  GPSWeather
//
//  Created by win on 8/3/17.
//  Copyright © 2017 win. All rights reserved.
//

import UIKit

class FavoritesTableViewCell: UITableViewCell {

    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var descriptionImage: UIImageView!
    @IBOutlet weak var cityName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
