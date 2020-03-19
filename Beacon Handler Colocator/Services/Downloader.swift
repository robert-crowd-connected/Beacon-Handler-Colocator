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
 
    static var mapImage: UIImage?
    
    static func downloadImage(from link: String, completion: @escaping (UIImage?) -> Void) {
        if mapImage != nil {
            completion(mapImage!)
            return
        }
        
        guard let url = URL(string: link) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data) else {
                    completion(nil)
                    return
            }
            
            DispatchQueue.main.async() {
                Downloader.mapImage = image
                completion(image)
            }
        }.resume()
    }
}
