//
//  UpdatingServerBeaconsService.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 27/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Alamofire
import Foundation

class UpdatingServerBeaconsService {
    
    private init() {}
       
    static var shared = UpdatingServerBeaconsService()
    
    private var baseURL = "https://staging.colocator.net/v2/"
    private var beaconSufix = "beacons"
    private var surfaceSufix = "surfaces"
    
    public var surfaceId = "worldSurface"
    
    public func putBeacon(beacon: ServerBeacon, completion: @escaping (Bool, String?) -> Void) {
        guard let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
           let token = UserDefaults.standard.value(forKey: kAuthorizationTokenStorageKey) as? String else {
            completion(false, kNoAuthorizationDataFound)
            return
        }
        guard let url = URL(string: "\(baseURL)\(beaconSufix)?app=\(key)") else {
            completion(false, kWrongUrlFormat)
            return
        }
      
        let parameters: Parameters = ["id": beacon.id,
                                      "lat": beacon.lat,
                                      "lng": beacon.lng,
                                      "alt": beacon.alt,
                                      "surfaceId": beacon.surfaceId,
                                      "beaconType": beacon.beaconType,
                                      "beaconState": beacon.beaconState]
        let headers: HTTPHeaders = [
            "Authorization" : token,
            "Content-Type": "application/json"
        ]
        let encoding: ParameterEncoding = JSONEncoding.default
        
        AF.request(url,
                   method: .post,
                   parameters: parameters,
                   encoding: encoding,
                   headers: headers)
            .responseString {
                response in
                
                if response.response?.statusCode == 200 {
                    completion(true, nil)
                    return
                }
                
                switch response.result {
                    
                case let .success(value):
                    guard let responseData = value.data(using: .utf8) else {
                        completion(false, kResponseDataDoesntMatchExpectedType)
                        return
                    }
                    guard let responseJSON = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
                        completion(false, kResponseDataDoesntMatchExpectedType)
                        return
                    }
                    
                    if let code = responseJSON["code"] as? String, !code.contains("200") {
                        let issueDescription = responseJSON["description"] as? String ?? kIssueDefaultDescription
                        completion(false, "Response Code " + code + " " + issueDescription)
                        return
                    }
                    
                    completion(true, nil)
                    
                case let .failure(error):
                    completion(false, kRequestFailed + (error.errorDescription ?? kIssueDefaultDescription))
                }
        }
    }
    
    public func updateBeacon(beacon: ServerBeacon, completion: @escaping (Bool, String?) -> Void) {
        guard let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let token = UserDefaults.standard.value(forKey: kAuthorizationTokenStorageKey) as? String else {
                completion(false, kNoAuthorizationDataFound)
                return
        }
        guard let url = URL(string: "\(baseURL)\(beaconSufix)/\(beacon.id)?app=\(key)") else {
            completion(false, kWrongUrlFormat)
            return
        }
       
        let parameters: Parameters = ["id": beacon.id,
                                      "lat": beacon.lat,
                                      "lng": beacon.lng,
                                      "alt": beacon.alt,
                                      "surfaceId": beacon.surfaceId,
                                      "beaconType": beacon.beaconType,
                                      "beaconState": beacon.beaconState]
        let headers: HTTPHeaders = [
            "Authorization" : token,
            "Content-Type": "application/json"
        ]
        let encoding: ParameterEncoding = JSONEncoding.default
        
        AF.request(url,
                   method: .put,
                   parameters: parameters,
                   encoding: encoding,
                   headers: headers)
            .responseString {
                response in
                
                //TODO Fix this error
                print(response)
                
                switch response.result {
                    
                case let .success(value):
                    guard let responseData = value.data(using: .utf8) else {
                        completion(false, kResponseDataDoesntMatchExpectedType)
                        return
                    }
                    guard let responseJSON = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
                        completion(false, kResponseDataDoesntMatchExpectedType)
                        return
                    }

                    if let code = responseJSON["code"] as? String, !code.contains("200") {
                       let issueDescription = responseJSON["description"] as? String ?? kIssueDefaultDescription
                        completion(false, "Response Code " + code + " " + issueDescription)
                        return
                    }

                    completion(true, nil)
                    
                case let .failure(error):
                    completion(false, kRequestFailed + (error.errorDescription ?? kIssueDefaultDescription))
                }
        }
    }
    
    public func getBeacon(withId id: String, completion: @escaping (Bool, String?, ServerBeacon?) -> Void) {
        guard let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let token = UserDefaults.standard.value(forKey: kAuthorizationTokenStorageKey) as? String else {
                completion(false, kNoAuthorizationDataFound, nil)
                return
        }
        guard let url = URL(string: "\(baseURL)\(beaconSufix)/\(id)?app=\(key)") else {
            completion(false, kWrongUrlFormat, nil)
            return
        }
        
        let parameters: Parameters = [:]
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
                        completion(false, kResponseDataDoesntMatchExpectedType, nil)
                        return
                    }
                    guard let responseJSON = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
                        completion(false, kResponseDataDoesntMatchExpectedType, nil)
                        return
                    }
                    
                    if let code = responseJSON["code"] as? String, !code.contains("200") {
                       let issueDescription = responseJSON["description"] as? String ?? kIssueDefaultDescription
                        completion(false, "Response Code " + code + " " + issueDescription, nil)
                        return
                    }
                    
                    guard let id = responseJSON["id"] as? String,
                        let lat = responseJSON["lat"] as? Double,
                        let lng = responseJSON["lng"] as? Double,
                        let alt = responseJSON["alt"] as? Double,
                        let surfaceId = responseJSON["surfaceId"] as? String,
                        let beaconType = responseJSON["beaconType"] as? String,
                        let beaconState = responseJSON["beaconState"] as? String else {
                            print("GET Beacon response doesn't contain all required fields\n\(responseJSON)")
                            completion(false, kResponseIsMissingFields, nil)
                            return
                    }
                    
                    let serverBeacon = ServerBeacon(id: id, lat: lat, lng: lng, alt: alt, surfaceId: surfaceId, beaconType: beaconType, beaconState: beaconState)
                    completion(true, nil, serverBeacon)
                    
                case let .failure(error):
                    completion(false, kRequestFailed + (error.errorDescription ?? kIssueDefaultDescription), nil)
                }
        }
    }
    
    public func getSurfaceTileName(completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(baseURL)\(surfaceSufix)") else {
            completion(false, nil)
            return
        }
        guard let key = UserDefaults.standard.value(forKey: kApplicationKeyStorageKey) as? String,
            let token = UserDefaults.standard.value(forKey: kAuthorizationTokenStorageKey) as? String else {
                completion(false, nil)
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
                        completion(false, nil)
                        return
                    }
                    guard let responseJSON = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
                        completion(false, nil)
                        return
                    }
                    
                    if let code = responseJSON["code"] as? String, !code.contains("200") {
                        print("Get surfaces request unsuccessful. Code: \(code) \(responseJSON["description"] as? String ?? "unknown description")")
                        completion(false, nil)
                        return
                    }
                    
                    guard let surfacesJSON = responseJSON["surfaces"] as? [[String: Any]] else {
                        completion(false, nil)
                        return
                    }
                    
                    for surfaceJSON in surfacesJSON {
                        let isWorldSurface = surfaceJSON["worldSurface"] as? Bool ?? false
                        
                        if isWorldSurface == true {
                            self.surfaceId = surfaceJSON["id"] as? String ?? "worldSurface"
                            completion(true, surfaceJSON["tileName"] as? String ?? "")
                            return
                        }
                    }
                    
                    completion(true, nil)
                    
                case let .failure(error):
                    print("Failed to get surfaces \(error.localizedDescription)")
                    completion(false, nil)
                }
        }
    }
}
