//
//  NetworkManager.swift
//  WeatherApp
//
//  Created by Юрий on 12.05.2025.
//

import Foundation

class WeatherAPI {
    private let apiKey = "fa8b3df74d4042b9aa7135114252304"
    private let baseURL = "https://api.weatherapi.com/v1"
    
    // Запрос текущей погоды
    func fetchCurrentWeather(lat: Double, lon: Double, completion: @escaping (Result<CurrentWeatherResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/current.json?key=\(apiKey)&q=\(lat),\(lon)"
        performRequest(urlString: urlString, completion: completion)
    }
    
    // Запрос прогноза (на 7 дней)
    func fetchForecast(lat: Double, lon: Double, completion: @escaping (Result<ForecastResponse, Error>) -> Void) {
        let urlString = "\(baseURL)/forecast.json?key=\(apiKey)&q=\(lat),\(lon)&days=7"
        performRequest(urlString: urlString, completion: completion)
    }
    
    private func performRequest<T: Decodable>(urlString: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else { return }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(T.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
