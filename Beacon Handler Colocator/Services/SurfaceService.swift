//
//  SurfaceService.swift
//  Beacon Handler Colocator
//
//  Created by TCode on 23/03/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Alamofire
import Foundation

class SurfaceService {
    
    private init() {
        let serverIndex = UserDefaults.standard.value(forKey: kServerUsedIndexStorageKey) as? Int ?? 2
        if serverIndex == 0 {
            baseURL = developmentDomain
        } else if serverIndex == 1 {
            baseURL = stagingDomain
        } else {
            baseURL = productionDomain
        }
    }
    
    static var shared = SurfaceService()
    
    private let developmentDomain = "https://real-development.colocator.net/v2/"
    private let stagingDomain = "https://staging.colocator.net/v2/"
    private let productionDomain = "https://production.colocator.net/v2/"
    
    private var baseURL = "https://staging.colocator.net/v2/"
    private var surfaceSufix = "surfaces"
    
    public var surfaceId: String? = nil
    public var isGeoSurface: Bool? = nil
    public var tileName: String? = nil
    public var mapHeight: Int? = nil
    public var mapWidth: Int? = nil
    
    public func getSurfaceData(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)\(surfaceSufix)") else {
            completion(false)
            return
        }
        guard let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let token = UserDefaults.standard.value(forKey: kAuthorizationTokenStorageKey) as? String else {
                completion(false)
                return
        }
        
        let parameters: Parameters = ["app": key]
        let headers: HTTPHeaders = [
            "Authorization" : token,
            "Content-Type": "application/json"
        ]
        let encoding: ParameterEncoding = URLEncoding.default
        
        AF.request(url,
                   method: .get,
                   parameters: parameters,
                   encoding: encoding,
                   headers: headers)
            .responseString {
                response in
                
                switch response.result {
                    
                case let .success(value):
                    guard let responseData = value.data(using: .utf8) else {
                        completion(false)
                        return
                    }
                    guard let responseJSON = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
                        completion(false)
                        return
                    }
                    
                    if let code = responseJSON["code"] as? String, !code.contains("200") {
                        print("Get surfaces request unsuccessful. Code: \(code) \(responseJSON["description"] as? String ?? "unknown description")")
                        completion(false)
                        return
                    }
                    
                    guard let surfacesJSON = responseJSON["surfaces"] as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    
                    for surfaceJSON in surfacesJSON {
                        guard let isWorldSurface = surfaceJSON["worldSurface"] as? Int else {
                            continue
                        }
                        
                        if isWorldSurface == 0 {
                            guard let tile = surfaceJSON["tileName"] as? String,
                                let transform = surfaceJSON["transform"] as? Int,
                                let id = surfaceJSON["id"] as? String else {
                                    continue
                            }
                            
                            self.surfaceId = id
                            self.tileName = tile
                            self.isGeoSurface = transform == 1
                          
                            if self.isGeoSurface == false {
                                guard let height = surfaceJSON["height"] as? Int,
                                   let width = surfaceJSON["width"] as? Int else {
                                       completion(false)
                                       return
                                }
                                
                                self.mapHeight = height
                                self.mapWidth = width
                                
                                 let fullDownloadString = "https://colocator-tiles.s3-eu-west-1.amazonaws.com/surfacete/" + tile
                                Downloader.downloadImage(from: fullDownloadString) { _ in }
                                
                                completion(true)
                                return
                                
                            } else {
                                completion(true)
                                return
                            }
                        }
                    }
                    
                    completion(false)
                    return
                    
                case let .failure(error):
                    print("Failed to get surfaces \(error.localizedDescription)")
                    completion(false)
                }
        }
    }
}
