//
//  NetworkManager.swift
//  sheikah-slate-v0.1
//
//  Created by Kevin Tang on 10/25/23.
//

import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    
    func sendRequest(_ request: URLRequest, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            guard let data = data else {
                completion(.failure(.dataMissing))
                return
            }
            completion(.success(data))
        }.resume()
    }
    
    enum NetworkError: Error {
        case networkError(Error)
        case dataMissing
        case invalidURL
    }
}
