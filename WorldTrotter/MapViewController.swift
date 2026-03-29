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

        // Ignore taps on existing annotation views
        for annotation in mapView.annotations {
            if let annotationView = mapView.view(for: annotation),
               annotationView.frame.contains(point) {
                return
            }
        }

        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        lookUpTemperature(at: coordinate)
    }

    private func lookUpTemperature(at coordinate: CLLocationCoordinate2D) {
        Task {
            async let temperatureTask = fetchTemperature(at: coordinate)
            async let cityTask = reverseGeocode(coordinate)

            do {
                let temperature = try await temperatureTask
                let city = await cityTask

                await MainActor.run {
                    let existing = mapView.annotations.filter { !($0 is MKUserLocation) }
                    mapView.removeAnnotations(existing)

                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = city
                    annotation.subtitle = String(format: "%.1f°C", temperature)
                    mapView.addAnnotation(annotation)
                    mapView.selectAnnotation(annotation, animated: true)
                }
            } catch {
                // Network or decoding error — silently ignore
            }
        }
    }

    private func fetchTemperature(at coordinate: CLLocationCoordinate2D) async throws -> Double {
        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(coordinate.latitude)"
            + "&longitude=\(coordinate.longitude)"
            + "&current=temperature_2m"
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

    // MARK: - MKMapViewDelegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        let identifier = "TemperaturePin"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.annotation = annotation
        view.canShowCallout = true
        return view
    }
}
