//
//  SpeechManager.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 10/1/23.
//

import Foundation
import AVFoundation
import SwiftUI

/*
struct SpeechView: View {
    @StateObject var ttsManager = TextToSpeechManager()
    @State var text = "Hello, World!"
    
    var body: some View {
        VStack {
            TextField("Enter text", text: $text)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                ttsManager.synthesizeSpeech(text: text) { url in
                    // You can play the audio using AVPlayer here if needed.
                    if let url = url {
                        let player = AVPlayer(url: url)
                        player.play()
                    }
                }
            }) {
                Text("Speak")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}
*/

class TextToSpeechManager: ObservableObject {
    var player: AVAudioPlayer?
    
    func synthesizeSpeech(text: String, completion: @escaping (URL?) -> Void) {
        
        let key = SPEECH_API_KEY
        let urlString = SPEECH_END_POINT
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/ssml+xml", forHTTPHeaderField: "Content-Type")
        request.addValue("audio-16khz-128kbitrate-mono-mp3", forHTTPHeaderField: "X-Microsoft-OutputFormat")
        request.addValue("\(key)", forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        request.addValue("ocp-demo", forHTTPHeaderField: "User-Agent") // replace with your app's name
        
        let ssml = """
        <speak version='1.0' xml:lang='en-US'>
            <voice xml:lang='en-US' xml:gender='Female' name='en-US-JennyNeural'>
                \(text)
            </voice>
        </speak>
        """
        request.httpBody = Data(ssml.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Network Error: \(error.debugDescription)")
                completion(nil)
                return
            }
            
            // let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            // let documentsDirectory = paths[0]
            // let filePath = "\(documentsDirectory)/output.mp3"
            do {
                // Create a temporary directory to save the audio file.
                let tempDir = NSTemporaryDirectory()
                let fileURL = URL(fileURLWithPath: tempDir).appendingPathComponent(UUID().uuidString).appendingPathExtension("mp3")
                
                // check the file size 
                self.checkFileSize(from: fileURL.path)
                
                try data.write(to: fileURL, options: .atomicWrite)
                self.playAudio(from: fileURL)
                
                completion(fileURL)
            } catch {
                print("File writing or Audio Player Error: \(error)")
                completion(nil)
            }
            
        }
        task.resume()
    }
    
    func playAudio(from url: URL) {
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.play()
        } catch {
            print("Audio Player Error: \(error)")
        }
    }
    
    func checkFileSize(from filePath: String) {
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let fileSize = attributes[.size] as? NSNumber {
                print("File size: \(fileSize) bytes")
            }
        } catch {
            print("Error getting file size: \(error.localizedDescription)")
        }
        
    }
    func stopAudio() {
        print("Stopping audio...")
        player?.stop()
    }
}
