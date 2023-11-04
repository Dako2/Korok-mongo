//
//  ChatView.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
//

import Foundation
import SwiftUI
//import Firebase
import UIKit

class MessageManager: ObservableObject {
    @Published var messages: [Message] = []
    
    func updateMessage(withId id: UUID, newText: String?, newImage: String?, newAudio: URL?) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].text = newText ?? messages[index].text
            messages[index].image = newImage ?? messages[index].image
            messages[index].audioURL = newAudio ?? messages[index].audioURL
        }
    }
}

struct ChatView: View {
    
    @State private var messageText: String = ""
    @State private var image: UIImage?
    //@State private var messages: [Message] = []
    
    @State private var isImagePickerPresented: Bool = false
    @State private var isActionSheetPresented: Bool = false
    @State private var selectedSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var isImageViewerPresented: Bool = false // To manage the state of Image Viewer
    @State private var selectedImageForViewer: UIImage?  // New State variable for ImageViewer
    
    @StateObject var chatManager = ChatManager()
    @StateObject var ttsManager = TextToSpeechManager()
    
    struct MessageView: View {
        let message: Message
        @State private var isImageViewerPresented: Bool = false
        
        var body: some View {
            Group {
                HStack {
                    if message.sender == "user" {
                        Spacer() // Push content to the right for user
                    }
                    
                    VStack(alignment: .leading) {
                        Text(message.sender ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let text = message.text {
                            Text(text)
                                //.padding()
                                .background(Color.gray.opacity(0.0))
                                //.cornerRadius(8)
                        } else if let imagePath = message.image, let image = loadImage(fromPath: imagePath) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                                .onTapGesture {
                                    self.isImageViewerPresented = true
                                }
                                .sheet(isPresented: $isImageViewerPresented) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .edgesIgnoringSafeArea(.all)
                                }
                        }
                    }
                    if message.sender != "user" {
                        Spacer() // Push content to the left for bot
                    }
                }
            }
        }
    }
    
    var body: some View {
        VStack {
            List(chatManager.chatHistory) { message in
                MessageView(message: message)
            }
            
            HStack {
                Button(action: {
                    isActionSheetPresented = true
                }) {
                    Image(systemName: "camera")
                }
                
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                }
                
                TextField("Type a message...", text: $messageText)
                
                Button(action: {
                    if let img = image {
                        let imagePath = saveImageLocally(img)
                        // chatManager.chatHistory.append(Message(sender: "user", text: nil, image: imagePath))
                        chatManager.sendMessage(message: Message(sender: "user", text: nil, image: imagePath, timestamp: Date()))
                        image = nil
                    } else if !messageText.isEmpty {
                        // chatManager.chatHistory.append(Message(sender: "user", text: messageText, image: nil))
                        // simulateBotResponse(messageText) // Here, you call the bot function after sending a user message
                        chatManager.sendMessage(message: Message(sender: "user", text: messageText, image: nil, timestamp: Date()))
                        messageText = ""
                    }
                }) {
                    Image(systemName: "paperplane")
                }
            }
            .padding()
            .actionSheet(isPresented: $isActionSheetPresented) {
                ActionSheet(title: Text("Choose a photo"), buttons: [
                    .default(Text("Take a Photo")) {
                        selectedSourceType = .camera // Set source type to camera
                        isImagePickerPresented = true
                    },
                    .default(Text("Choose from Library")) {
                        selectedSourceType = .photoLibrary // Set source type to photo library
                        isImagePickerPresented = true
                    },
                    .cancel()
                ])
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $image, isPresented: $isImagePickerPresented, sourceType: selectedSourceType)
            }
        }
        .sheet(isPresented: $isImageViewerPresented) {
            ImageViewer(image: $selectedImageForViewer)  // Pass the selectedImageForViewer to ImageViewer
        }
        .onTapGesture {
            UIApplication.shared.endEditing()
            ttsManager.stopAudio()
        }
    }
    
    
    func simulateBotResponse(_ userMessage: String) {
        let botMessage = Message(sender: "bot", text: userMessage, image: nil, timestamp: Date()) // Bot replies with the same message
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Delaying the bot response by 1 second
            chatManager.chatHistory.append(botMessage)
        }
    }

    // Function to save image locally and return its path
    func saveImageLocally(_ image: UIImage) -> String? {
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try data.write(to: imagePath)
            return imagePath.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }


}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Function to get documents directory
func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

// Function to load image from local path
func loadImage(fromPath path: String) -> UIImage? {
    let url = URL(fileURLWithPath: path)
    do {
        let data = try Data(contentsOf: url)
        return UIImage(data: data)
    } catch {
        print("Error loading image : \(error)")
    }
    return nil
}

struct ImageViewer: View {
    @Binding var image: UIImage?
    
    var body: some View {
        NavigationView {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .navigationBarItems(trailing: Button("Close") {
                        image = nil // Resetting image to close viewer
                    })
            } else {
                Text("No Image Selected")
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.isPresented = false
        }
    }
}
