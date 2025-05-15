//
//  Model.swift
//  WeatherApp
//
//  Created by Юрий on 12.05.2025.
//

import Foundation

struct CurrentWeatherResponse: Codable {
    let location: Location
    let current: CurrentWeather
}

struct ForecastResponse: Codable {
    let location: Location
    let current: CurrentWeather
    let forecast: Forecast
}

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
}

struct CurrentWeather: Codable {
    let tempC: Double
    let condition: WeatherCondition
}

struct WeatherCondition: Codable {
    let text: String
    let icon: String
    
    var iconURL: URL? {
        let baseURL = "https:\(icon)"
        return URL(string: baseURL)
    }
}

struct Forecast: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let day: Day
    let hour: [Hour]
}

struct Day: Codable {
    let maxtempC: Double
    let mintempC: Double
    let condition: WeatherCondition
}

struct Hour: Codable {
    let time: String
    let tempC: Double
    let condition: WeatherCondition
}
