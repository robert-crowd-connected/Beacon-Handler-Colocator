//
//  ConstantsAndStorageKeys.swift
//  Beacon Handler Colocator
//
//  Created by Mobile Developer on 27/02/2020.
//  Copyright © 2020 Crowd Connected. All rights reserved.
//

import Foundation

// Storage Keys

let kMajorValueStorageKey = "MAJORVALUESTORAGEKEY"
let kBeaconCattegoryStorageKey = "BEACONCATEGORYSTORAGEKEY"
let kRegionUUIDStorageKey = "REGIONUUIDSTORAGEKEY"

let kApplicationKeyStorageKey = "APPLICATIONKEYSTORAGEKEY"
let kAuthorizationTokenStorageKey = "AUTHORIZATIONTOKENSTORAGEKEY"


// Error Messages

let kNoAuthorizationDataFound = "No Authorizarion data found on device. Check your App Key and Token"
let kWrongUrlFormat = "Cannot create a valid URL for your request"
let kResponseDataDoesntMatchExpectedType = "Server response data doesn't match expectation"
let kResponseIsMissingFields = "Server response is missing fields or doesn't match expected format"
let kIssueDefaultDescription = " Unknown issue"
let kRequestFailed = "Request failed "

let kDefaultRequestErrorMessage = "The beacon couldn't be updated because of server communication issues"
