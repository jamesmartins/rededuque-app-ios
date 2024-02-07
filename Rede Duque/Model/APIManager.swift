//
//  APIManager.swift
//  Despesas
//
//  Created by Duane de Moura Silva on 08/10/23.
//

import Foundation

enum HTTPMethod {
    case get
    case post(body: [String: Any])
    case delete
    case put
}

class APIManager {
    
    func performRequest<T: Decodable>(urlString: String, method: HTTPMethod, token: String = "", authorizationCode: Bool = true) async throws -> T {
        guard let url = URL(string: urlString) else {
            print("0 - erro no request \(#function):\n\(URLError(.badURL).localizedDescription)\n")
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        
        if !token.isEmpty {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if authorizationCode {
            request.addValue("VVNOMFZHeldxMkVJR1JCWmZkNVpxMU1icHFGRzhROHlXUWZrTnowVEQ4Y0VqekFGWURIUEt3wqLCog==", forHTTPHeaderField: "authorizationCode")
        }
        
        switch method {
        case .get:
            request.httpMethod = "GET"
        case .post(let body):
            request.httpMethod = "POST"
            
            if !body.isEmpty {
                do {
                    let  jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = jsonData
                } catch let serializationError {
                    throw serializationError
                }
            }
        case .delete:
            request.httpMethod = "DELETE"
        case .put:
            request.httpMethod = "PUT"	
        }
        
        let configuration = URLSessionConfiguration.default
        /*
        configuration.timeoutIntervalForRequest = 300
        configuration.timeoutIntervalForResource = 5*/
        let customCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
        configuration.urlCache = customCache
        let session = URLSession(configuration: configuration)
        
        var data : Data
        var response : URLResponse?
        
        do {
            (data, response ) = try await session.data(for: request)
        } catch let error {
            print("1 - erro no request \(#function):\n\(error)\n")
            print("Response:\(response?.description ?? "null")")
            throw error
        }
        
        var decodedData : T
        do {
            decodedData = try JSONDecoder().decode(T.self, from: data)
        } catch let error {
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            print("2 - erro no request \(#function):\n\(error)\n")
            throw error
        }
        
        return decodedData
    }
}
