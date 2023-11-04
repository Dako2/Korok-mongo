//
//  ConfigView.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
import Foundation
import SwiftUI

struct ConfigView: View {
    let serverURLs: [String] = Server_IP_Address_List
    @State private var manualServerURL: String = "your_sever_IP_address"
    @State private var showPicker: Bool = false
    @State private var latencyResult: String = "Please test..."
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Configuration")
                .font(.largeTitle)
                .fontWeight(.heavy)
                .padding(.top, 30)
            
            HStack {
                TextField("Enter Server Address", text: $manualServerURL)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8.0)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: manualServerURL) { newValue in
                        setGlobalVariable(to: newValue)
                    }
                
                Button(action: {
                    self.showPicker.toggle()
                }) {
                    Image(systemName: "arrow.down.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(.leading)
                }
                .actionSheet(isPresented: $showPicker) {
                    ActionSheet(title: Text("Select Server Address"), buttons: serverURLs.map { url in
                        .default(Text(url), action: {
                            self.manualServerURL = url
                        })
                    } + [.cancel()])
                }
            }
            
            
            HStack{
                Button("Latency Test") {
                    getServerLatency(for: manualServerURL)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8.0)
                
                Text(latencyResult)
                    .font(.body)
                    .foregroundColor(Color.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8.0)
            }
            Spacer()
        }
        .onTapGesture {
            dismissKeyboard()
        }
    }
    
    func setGlobalVariable(to newValue: String) {
        Server_IP_Address = newValue
    }
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func getServerLatency(for url: String) {
        guard let validURL = URL(string: url) else {
            latencyResult = "Invalid URL"
            return
        }
        
        let startTime = Date()
        let task = URLSession.shared.dataTask(with: validURL) { _, _, error in
            let latency = Date().timeIntervalSince(startTime)
            DispatchQueue.main.async {
                if error != nil {
                    latencyResult = "Connection Error"
                } else {
                    latencyResult = String(format: "Latency: %.2f ms", latency * 1000)
                }
            }
        }
        task.resume()
    }
}
