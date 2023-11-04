//
//  sheikah_slate_v0_1App.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
//

import SwiftUI
import AVKit
import Combine
 
struct CustomVideoPlayer: UIViewControllerRepresentable {
    var player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false // Hide controls
        return controller
    }
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct OpeningAnimationView: View {
    @State private var videoFinishedPlaying = false
    private var player: AVPlayer

    init() {
        if let url = Bundle.main.url(forResource: "Zelda_shortened", withExtension: "mp4") {
            player = AVPlayer(url: url)
        } else {
            player = AVPlayer()
            print("Failed to load video.")
        }
    }

    var body: some View {
        VStack {
            if videoFinishedPlaying {
                ContentView() // The view you transition to after the video finishes
            } else {
                CustomVideoPlayer(player: player)
                    .onAppear {
                        player.rate = 4.0
                        player.play()
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.pause() // Pause the video
                            videoFinishedPlaying = true
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        player.pause()
                        videoFinishedPlaying = true
                    }
            }
        }
    }
}

@main
struct sheikah_slate_v0_1App: App {
    var sharedModel = SharedModel()
    init() {
        if UserDefaults.standard.string(forKey: "user_id") == nil {
            let userId = UUID().uuidString
            UserDefaults.standard.set(userId, forKey: "user_id")
        }
        loadConfig() // Force initialization at app launch
    }

    var body: some Scene {
        WindowGroup {
            OpeningAnimationView()
        }
    }
}
