//
//  NetworkManager.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.

import Foundation
import UIKit
import SwiftUI

struct Message: Identifiable, Equatable {
    var id = UUID()
    var sender: String?
    var text: String? //content
    var image: String? //content
    var audioURL: URL?
    let timestamp: Date
}

struct User {
    let id: UUID
    let name: String
}

struct MessageResponse: Codable {
    let success: Bool
    let message: NetworkMessage
}

struct NetworkMessage: Codable {
    let text: String
}

private func getCurrentUserId() -> String? {
    // Fetch the user ID from wherever you're storing it (e.g. UserDefaults, session, etc.)
    return UserDefaults.standard.string(forKey: "user_id")
}

class ChatManager: ObservableObject {
    @Published var chatHistory: [Message] = []
    var ttsManager = TextToSpeechManager()

    func sendMessage(message: Message) {
        // append user's message
        DispatchQueue.main.async {
            self.chatHistory.append(message)
        }
        // append bot's message
        if let text = message.text, !text.isEmpty {
            sendTextMessage(text: text) { [weak self] botmessage in
                if let botMessageUnwrapped = botmessage {
                    print("\n\n\n",botMessageUnwrapped, "\n\n\n")
                    // Split the message into parts based on the "=== found local vectdata ===" delimiter
                    let parts = botMessageUnwrapped.components(separatedBy: "=== found local vectdata ===")
                    // Getting the individual parts
                    let part1 = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let part2 = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                    let part2_new = part2.replacingOccurrences(of: "[{\"}]", with: "", options: .regularExpression)
                    let truncatedString = String(part2_new.prefix(250)) + "\n......"
                    let botMessageUnwrapped = part1 + "\n\n=== found local vectdata ===\n\n" + truncatedString
                    // Debugging output
                    print("Part 1:")
                    print(part1)
                    print("\nPart 2:")
                    print(part2_new)
                                                    
                    self?.ttsManager.synthesizeSpeech(text: part1) { url in
                        DispatchQueue.main.async {
                            self?.chatHistory.append(Message(sender: SharedModel.shared.messageSender, text: botMessageUnwrapped, image: nil, audioURL: url, timestamp: Date()))
                        }
                    }
                }
            }
        } else if let imagePath = message.image {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let image = loadImage(fromPath: imagePath) {
                    self?.sendImageMessage(image: image) { botmessage in
                        DispatchQueue.main.async {
                            self?.chatHistory.append(Message(sender: SharedModel.shared.messageSender, text: botmessage, image: nil, timestamp: Date()))
                        }
                    }
                }
            }
        }
    }
    
    private func handleError(_ error: String) {
        print(error)
        DispatchQueue.main.async {
            self.chatHistory.append(Message(sender: "Bot", text: error, image: nil, timestamp: Date()))
        }
    }
    
    private func sendTextMessage(text: String, completion: @escaping (String?) -> Void) {
        
        guard let userId = getCurrentUserId() else {
            return self.handleError("Unable to fetch user ID")
        }
        // Prepare the URL for your server's chat API
        guard let apiUrl = URL(string: "\(Server_IP_Address)/api/chat") else {
            return self.handleError("Invalid API URL")
        }
        
        // Create a request
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a dictionary with the message data
        //
        let messageData = ["user_id": userId, "message": text]
        
        do {
            request.httpBody = try JSONEncoder().encode(messageData)
        } catch {
            return self.handleError("Failed to encode message data as JSON")
        }
        
        URLSession.shared.dataTask(with: request) { (data, _, error) in
            if let error = error {
                return self.handleError("Error: \(error.localizedDescription), server \(apiUrl) cannot be reached")
            }
            
            guard let data = data else {
                return self.handleError("Data is nil")
            }
            
            do {
                let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let botResponse = responseJSON?["message"] as? String {
                    // Now, you can update your UI with the textToDisplay
                    completion(botResponse)
                    //DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Delaying the bot response by 1 second
                    //    self.chatHistory.append(Message(sender: "bot", text: botResponse, image: nil))
                    //}
                } else {
                    self.handleError("Invalid server response format")
                }
            } catch {
                self.handleError("Error parsing server response JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func sendImageMessage(image: UIImage, completion: @escaping (String?) -> Void) {
        
        guard let apiUrl = URL(string: "\(Server_IP_Address)/api/image") else { print("Invalid API URL"); return }
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            return self.handleError("Unable to compress the image")
        }
        
        request.httpBody = createBody(boundary: boundary, data: imageData, mimeType: "image/jpeg", filename: "image.jpg")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                return self.handleError("Failed to upload image: \(error.localizedDescription)")
            }
            guard let data = data else {
                return self.handleError("Data is nil")
            }
        
            do {
                let response = try JSONDecoder().decode(MessageResponse.self, from: data)
                
                if response.success {
                    completion(response.message.text)
                    self.chatHistory.append(Message(sender: "bot", text: response.message.text, image: nil, timestamp: Date()))
                } else {
                    self.handleError("Server responded with success=false.")
                }
            } catch {
                self.handleError("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func createBody(boundary: String, data: Data, mimeType: String, filename: String) -> Data {
        var body = Data()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    
}

 
