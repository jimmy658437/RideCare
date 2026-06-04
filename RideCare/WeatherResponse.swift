//
//  WeatherResponse.swift
//  RideCare
//
//  Created by 114-2Workshop12 on 2026/5/31.
//


import Foundation

struct WeatherResponse: Codable {

    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
        let pressure: Int
    }

    struct Weather: Codable {
        let icon: String
        let description: String
    }

    struct Wind: Codable {
        let speed: Double
        let deg: Int?       // 新增：風向 (角度 0-360)
        let gust: Double?   // 新增：陣風風速 (有些天氣狀態下不會有，設為 Optional)
    }

    struct Clouds: Codable {
        let all: Int
    }

    // 新增：系統資訊 (國家、日出、日落)
    struct Sys: Codable {
        let country: String?
        let sunrise: TimeInterval?
        let sunset: TimeInterval?
    }

    let main: Main
    let weather: [Weather]
    let wind: Wind
    let clouds: Clouds
    let sys: Sys?           // 新增
    let visibility: Int?    // 新增：能見度 (單位：公尺)
    let name: String
}
