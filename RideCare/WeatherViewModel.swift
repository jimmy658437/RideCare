//
//  WeatherViewModel.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/31.
//


import Foundation
import Combine

@MainActor
final class WeatherViewModel: ObservableObject {

    @Published var temperature: Double?
    @Published var feelsLikeTemperature: Double?
    @Published var humidity: Int?
    @Published var pressure: Int?
    @Published var cloudiness: Int?
    @Published var windSpeed: Double?
    @Published var weatherIcon: String?
    @Published var weatherDescription: String?

    @Published var city = "Taipei"

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "openWeatherAPIKey") ?? ""
    }

    func fetchWeather() async {
        
        guard !apiKey.isEmpty else {
            print("OpenWeather API Key 尚未設定")
            return
        }

        guard let encodedCity =
            city.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            )
        else { return }

        let urlString =
        "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(apiKey)&units=metric&lang=zh_tw"

        guard let url = URL(string: urlString)
        else { return }

        do {

            let (data, _) =
            try await URLSession.shared.data(from: url)

            let result =
            try JSONDecoder().decode(
                WeatherResponse.self,
                from: data
            )

            temperature = result.main.temp
            feelsLikeTemperature = result.main.feels_like
            humidity = result.main.humidity
            pressure = result.main.pressure

            windSpeed = result.wind.speed
            cloudiness = result.clouds.all

            weatherIcon = result.weather.first?.icon
            weatherDescription = result.weather.first?.description

            city = result.name

        } catch {

            print("Weather Error:", error)
        }
    }
}
