//
//  WeatherManager.swift
//  CryoTunes Player
//
//  Created by Michael Fluharty on 3/26/26.
//

import Foundation
import WeatherKit
import CoreLocation

@Observable
class WeatherManager: NSObject, CLLocationManagerDelegate {
    var temperature: String = "--"
    var condition: String = ""
    var locationName: String = ""

    private let weatherService = WeatherService.shared
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestWeather() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        lastLocation = location

        // Reverse geocode for city name
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality {
                Task { @MainActor in
                    self?.locationName = city
                }
            }
        }

        // Fetch weather
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                let temp = Int(weather.currentWeather.temperature.converted(to: .fahrenheit).value)
                let cond = weather.currentWeather.condition.description
                await MainActor.run {
                    self.temperature = "\(temp)°F"
                    self.condition = cond
                }
            } catch {
                print("Weather error: \(error)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
