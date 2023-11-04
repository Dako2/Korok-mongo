//
//  MapManager.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 9/29/23.
//
//
//  MapManager.swift
//  sheikah-slate-v0.0b
//
//  Created by Kevin Tang on 9/10/23.

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Combine

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct ServerResponse: Decodable {
    let message: MessageDetails
    
    struct MessageDetails: Decodable {
        let latitude: Double
        let longitude: Double
        let places: [String: PlaceCoordinates]
        
        struct PlaceCoordinates: Decodable {
            let latitude: Double
            let longitude: Double
        }
    }
}

struct ServerResponseTappedPlaces: Decodable {
    let message: String
    let status: String
}


struct Response: Codable {
    var latitude: Double
    var longitude: Double
    var places: [String: PlaceDetail]
}

struct PlaceDetail: Codable {
    var latitude: Double
    var longitude: Double
    var db_path: String
}

struct FullMapView: View {
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        MapView()
            .background(Color.white)
            .frame(width: screenWidth * 0.9, height: screenHeight * 0.8)
            .cornerRadius(10)
    }
}

struct MapView: View {
    
    @State private var userLocation: CLLocationCoordinate2D?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.329219, longitude: -121.88888),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var places: [Place] = []
    @State private var useGPSLocation: Bool = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // every 1 sec

    let locationManager = CLLocationManager()
    var body: some View {
        VStack {
            Toggle("Live location", isOn: $useGPSLocation)
                .padding()

            Map(
                coordinateRegion: $region,
                showsUserLocation: userLocation != nil,
                annotationItems: places) { place in
                    MapAnnotation(coordinate: place.coordinate) {
                        AnnotationView(place: place)
                    }
                }
        }
        .onReceive(timer) { _ in
            if useGPSLocation {
                loadLocationFromGPS()
            } else {
                loadLocationFromAPI()  // assuming you have this method for API-based location
            }
        }
        .onAppear {
            if useGPSLocation {
                loadLocationFromGPS()
            } else {
                loadLocationFromAPI()
            }
        }
    }
    
    func loadLocationFromAPI() {
        guard let url = URL(string: "\(Server_IP_Address)/api/places") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to fetch data: \(error.localizedDescription)")
                return
            }
            
            if let data = data {
                do {
                    let serverResponse = try JSONDecoder().decode(ServerResponse.self, from: data)
                    print("Server Response: \(serverResponse)") // Print the server response here

                    let decodedResponse = serverResponse.message
                    
                    DispatchQueue.main.async {
                        self.userLocation = CLLocationCoordinate2D(latitude: decodedResponse.latitude, longitude: decodedResponse.longitude)
                        self.region.center = self.userLocation!
                        self.places = decodedResponse.places.map {
                            Place(name: $0.key, coordinate: CLLocationCoordinate2D(latitude: $0.value.latitude, longitude: $0.value.longitude))
                        }
                    }
                } catch let decodingError {
                    print("Decoding error: \(decodingError)")
                }
            } else {
                print("No data received.")
            }
        }.resume()
    }
    
    func loadLocationFromGPS() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let userLoc = locationManager.location?.coordinate {
            self.userLocation = userLoc
            self.region.center = userLoc
            print("User Location: \(userLoc.latitude), \(userLoc.longitude)")
            // Append user location to the list
            self.places = [Place(name: "user", coordinate: userLoc)]
        }
    }
    
    struct AnnotationView: View {
        let place: Place
        
        var body: some View {
            Button(action: {
                // Your action when the pin is tapped
                pinTapped()
            }) {
                VStack {
                    Text(place.name)
                        .font(.caption)
                        .foregroundColor(.white)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Image(systemName: "mappin")
                        .foregroundColor(place.name == "user" ? .blue : .red)
                }
            }
        }
        
        func pinTapped() {
            print("Tapped on: \(place.name)")
            sendPlaceNameToServer(placeName: place.name)
            // Here, you can do other things based on the tapped pin, like updating some @State properties, etc.
            
        }
        func sendPlaceNameToServer(placeName: String) {
            
            guard let url = URL(string: "\(Server_IP_Address)/api/place_tapped") else {
                print("Invalid URL")
                return
            }
            
            guard let userId = UserDefaults.standard.string(forKey: "user_id") else {
                print("Failed to retrieve user_id from UserDefaults")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let payload: [String: Any] = ["place_name": placeName, "user_id": userId]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            } catch {
                print("Failed to serialize JSON: \(error.localizedDescription)")
                return
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Failed to send data: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    print("Server responded with a status code other than 2xx!")
                    return
                }

                guard let data = data else {
                    print("Successful request, but no data received.")
                    return
                }

                do {
                    let serverResponse = try JSONDecoder().decode(ServerResponseTappedPlaces.self, from: data)
                    print("Server Response: \(serverResponse.message)")

                    DispatchQueue.main.async {
                        if serverResponse.status == "success" {
                            SharedModel.shared.messageSender = serverResponse.message
                            print("Message sender updated to: \(serverResponse.message)")
                            //chatManager.chatHistory.append("Message sender updated to: \(serverResponse.message)")
                        }
                    }
                } catch let decodingError {
                    print("Decoding error: \(decodingError.localizedDescription)")
                }
            }.resume()
        }
    }
}

struct BottomSheetView<Content: View>: View {
    @Binding var isOpen: Bool

    let maxHeight: CGFloat
    let minHeight: CGFloat
    let content: Content

    @GestureState private var translation: CGFloat = 0

    init(isOpen: Binding<Bool>, maxHeight: CGFloat, @ViewBuilder content: () -> Content) {
        self.minHeight = 80
        self._isOpen = isOpen
        self.maxHeight = maxHeight
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Handle()
                self.content
            }
            .frame(width: geometry.size.width, height: self.isOpen ? self.maxHeight : self.minHeight, alignment: .top)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(y: self.isOpen ? 0 : geometry.size.height - self.minHeight)
            .offset(y: self.translation)
            .animation(.interactiveSpring(), value: isOpen)
            .gesture(DragGesture().updating(self.$translation) { value, state, _ in
                state = value.translation.height
            }.onEnded { value in
                let snapDistance = self.maxHeight * 0.25
                guard abs(value.translation.height) > snapDistance else {
                    return
                }
                self.isOpen = value.translation.height < 0
            })
        }
    }
}

struct Handle: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .frame(width: 30, height: 5)
            .foregroundColor(Color(.systemGray4))
            .padding(5)
    }
}
