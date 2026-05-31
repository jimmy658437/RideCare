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
    }

    struct Clouds: Codable {
        let all: Int
    }

    let main: Main
    let weather: [Weather]
    let wind: Wind
    let clouds: Clouds
    let name: String
}