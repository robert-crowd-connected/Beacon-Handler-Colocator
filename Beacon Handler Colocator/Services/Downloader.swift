//
//  UIImage+Extension.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 17/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation
import UIKit

class Downloader {
 
    static func downloadImage(from link: String, completion: @escaping (UIImage) -> Void) {
        guard let url = URL(string: link) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async() {
                completion(image)
            }
        }.resume()
    }
}