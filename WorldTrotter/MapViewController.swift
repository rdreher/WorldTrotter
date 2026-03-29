//
//  MapViewController.swift
//  WorldTrotter
//
//  Created by Rafael Dreher on 4/3/18.
//  Copyright © 2018 Rafael Dreher. All rights reserved.
//

// View created programatically
// without using InterfaceBuilder
import UIKit
import MapKit
import CoreLocation

// MARK: - Weather API Model

private struct WeatherResponse: Decodable {
    let current: CurrentWeather

    struct CurrentWeather: Decodable {
        let temperature2m: Double

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
        }
    }
}

// MARK: - MapViewController

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    var mapView: MKMapView!

    // MARK: - Temperature Overlay

    private let overlayCard = UIView()
    private let overlayCityLabel = UILabel()
    private let overlayTempLabel = UILabel()

    override func loadView() {
        mapView = MKMapView()
        view = mapView

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        let segmentedControl = UISegmentedControl(items: ["Standard", "Hybrid", "Satellite"])
        segmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(mapTypeChanged(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)

        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        ])

        let zoomIn = makeZoomButton(title: "+", action: #selector(zoomIn))
        let zoomOut = makeZoomButton(title: "−", action: #selector(zoomOut))
        view.addSubview(zoomIn)
        view.addSubview(zoomOut)

        NSLayoutConstraint.activate([
            zoomIn.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            zoomIn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            zoomIn.widthAnchor.constraint(equalToConstant: 44),
            zoomIn.heightAnchor.constraint(equalToConstant: 44),

            zoomOut.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            zoomOut.bottomAnchor.constraint(equalTo: zoomIn.topAnchor, constant: -8),
            zoomOut.widthAnchor.constraint(equalToConstant: 44),
            zoomOut.heightAnchor.constraint(equalToConstant: 44)
        ])

        setupOverlayCard()
    }

    private func setupOverlayCard() {
        overlayCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)
        overlayCard.layer.cornerRadius = 14
        overlayCard.layer.shadowColor = UIColor.black.cgColor
        overlayCard.layer.shadowOpacity = 0.2
        overlayCard.layer.shadowRadius = 8
        overlayCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        overlayCard.alpha = 0
        overlayCard.translatesAutoresizingMaskIntoConstraints = false

        overlayCityLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        overlayCityLabel.textAlignment = .center
        overlayCityLabel.adjustsFontSizeToFitWidth = true
        overlayCityLabel.minimumScaleFactor = 0.7
        overlayCityLabel.translatesAutoresizingMaskIntoConstraints = false

        overlayTempLabel.font = UIFont.systemFont(ofSize: 40, weight: .semibold)
        overlayTempLabel.textAlignment = .center
        overlayTempLabel.translatesAutoresizingMaskIntoConstraints = false

        overlayCard.addSubview(overlayCityLabel)
        overlayCard.addSubview(overlayTempLabel)
        view.addSubview(overlayCard)

        NSLayoutConstraint.activate([
            overlayCityLabel.topAnchor.constraint(equalTo: overlayCard.topAnchor, constant: 14),
            overlayCityLabel.leadingAnchor.constraint(equalTo: overlayCard.leadingAnchor, constant: 16),
            overlayCityLabel.trailingAnchor.constraint(equalTo: overlayCard.trailingAnchor, constant: -16),

            overlayTempLabel.topAnchor.constraint(equalTo: overlayCityLabel.bottomAnchor, constant: 4),
            overlayTempLabel.leadingAnchor.constraint(equalTo: overlayCard.leadingAnchor, constant: 16),
            overlayTempLabel.trailingAnchor.constraint(equalTo: overlayCard.trailingAnchor, constant: -16),
            overlayTempLabel.bottomAnchor.constraint(equalTo: overlayCard.bottomAnchor, constant: -14),

            overlayCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlayCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            overlayCard.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6)
        ])
    }

    private func makeZoomButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.85)
        button.layer.cornerRadius = 8
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowRadius = 4
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc private func zoomIn() {
        var region = mapView.region
        region.span.latitudeDelta  = max(region.span.latitudeDelta  / 2, 0.002)
        region.span.longitudeDelta = max(region.span.longitudeDelta / 2, 0.002)
        mapView.setRegion(region, animated: true)
    }

    @objc private func zoomOut() {
        var region = mapView.region
        region.span.latitudeDelta  = min(region.span.latitudeDelta  * 2, 180)
        region.span.longitudeDelta = min(region.span.longitudeDelta * 2, 360)
        mapView.setRegion(region, animated: true)
    }

    @objc func mapTypeChanged(_ segControl: UISegmentedControl) {
        switch segControl.selectedSegmentIndex {
        case 0:
            mapView.preferredConfiguration = MKStandardMapConfiguration()
        case 1:
            mapView.preferredConfiguration = MKHybridMapConfiguration()
        case 2:
            mapView.preferredConfiguration = MKImageryMapConfiguration()
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        var region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        region.center = mapView.userLocation.coordinate
        mapView.setRegion(region, animated: true)
    }

    // MARK: - Temperature Lookup

    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        lookUpTemperature(at: coordinate)
    }

    private func lookUpTemperature(at coordinate: CLLocationCoordinate2D) {
        let direction = ConversionViewController.sharedDirection

        // Show loading state immediately (called on main thread from gesture handler)
        overlayCityLabel.text = "Fetching..."
        overlayTempLabel.text = "—"
        UIView.animate(withDuration: 0.25) { self.overlayCard.alpha = 1 }

        Task {
            async let temperatureTask = fetchTemperature(at: coordinate, direction: direction)
            async let cityTask = reverseGeocode(coordinate)

            do {
                let temperature = try await temperatureTask
                let city = await cityTask

                await MainActor.run {
                    overlayCityLabel.text = city
                    overlayTempLabel.text = String(format: "%.1f\(direction.inputSymbol)", temperature)
                }
            } catch {
                await MainActor.run {
                    overlayCityLabel.text = "Unavailable"
                    overlayTempLabel.text = "—"
                }
            }
        }
    }

    private func fetchTemperature(at coordinate: CLLocationCoordinate2D, direction: ConversionDirection) async throws -> Double {
        var urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(coordinate.latitude)"
            + "&longitude=\(coordinate.longitude)"
            + "&current=temperature_2m"
        if direction == .fahrenheitToCelsius {
            urlString += "&temperature_unit=fahrenheit"
        }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
        return response.current.temperature2m
    }

    private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks?.first?.locality
            ?? placemarks?.first?.name
            ?? "Unknown Location"
    }
}
