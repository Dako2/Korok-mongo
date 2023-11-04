//
//  Globals.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
//

import Foundation
import Security

class SharedModel: ObservableObject {
    static let shared = SharedModel()
    @Published var messageSender: String = "Bot"
}

var Server_IP_Address_List: [String] = []
var Server_IP_Address: String = ""
var SPEECH_REGION = "westus"
var SPEECH_END_POINT = "https://\(SPEECH_REGION).tts.speech.microsoft.com/cognitiveservices/v1" //"https://westus.api.cognitive.microsoft.com/sts/v1.0/issuetoken"
var SPEECH_API_KEY = "50bcc09140984559a5880bb22818d8a0"

func loadConfig() {
    if let path = Bundle.main.path(forResource: "configs", ofType: "plist") {
        if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
            if let addresses = dict["SERVER_IP_ADDRESS_LIST"] as? [String] {
                Server_IP_Address_List = addresses
                Server_IP_Address = Server_IP_Address_List.first ?? "http://defaultAddress:9090"
            }
        }
    }
}

struct UserSettings {
    static let shared = UserSettings()
    
    private let userUUIDKey = "userUUID"
    private let defaults = UserDefaults.standard
    
    var userUUID: UUID {
        if let uuidString = defaults.string(forKey: userUUIDKey), let uuid = UUID(uuidString: uuidString) {
            return uuid
        } else {
            let newUUID = UUID()
            defaults.setValue(newUUID.uuidString, forKey: userUUIDKey)
            return newUUID
        }
    }
}


