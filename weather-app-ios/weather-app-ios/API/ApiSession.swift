//
//  ApiSession.swift
//  weather-app-ios
//
//  Created by 本前宏樹 on 2023/08/27.
//

import Foundation

enum SessionError: Error {
    case noResponse
    case unacceptableStatuCode(Int)
    case noData
}

enum Result<T> {
    case success(T)
    case failure(Error)
}

enum HttpMethod: String {
    case `get` = "GET"
    case post = "POST"
}

protocol Requestable {
    associatedtype Response: Decodable
    var baseURL: URL { get }
    var path: String { get }
    var httpMethod: HttpMethod { get }
}

final class Session {
    func send<T: Requestable>(_ requestable: T, completion: @escaping (Result<T.Response>) -> ()) {
        let url = requestable.baseURL.appendingPathComponent(requestable.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestable.httpMethod.rawValue

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                completion(.failure(SessionError.noResponse))
                return
            }

            guard 200..<300 ~= response.statusCode else {
                completion(.failure(SessionError.unacceptableStatuCode(response.statusCode)))
                return
            }

            guard let data = data else {
                completion(.failure(SessionError.noData))
                return
            }

            do {
                let objects = try JSONDecoder().decode(T.Response.self, from: data)
                completion(.success(objects))
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}

struct Weather: Codable {
    let icon: String
    let temp: String
    let date: String
}

struct WeatherApiRequestable: Requestable {
    typealias Response = [Weather]
    var baseURL: URL = URL(string: "https://qiita.com")!
    var path: String = "/api/v2/items"
    var httpMethod: HttpMethod = .get
}

func getWeather() {
    let requestable = WeatherApiRequestable()
    let session = Session()
    session.send(requestable) { result in
        switch result {
        case .success(let articles):
            print(articles.count)
        case .failure(let error):
            print(error)
        }
    }
}
