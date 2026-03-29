//
//  ConversionViewController.swift
//  WorldTrotter
//
//  Created by Rafael Dreher on 4/2/18.
//  Copyright © 2018 Rafael Dreher. All rights reserved.
//

import UIKit

enum ConversionDirection {
    case fahrenheitToCelsius
    case celsiusToFahrenheit

    var inputUnit: UnitTemperature  { self == .fahrenheitToCelsius ? .fahrenheit : .celsius }
    var outputUnit: UnitTemperature { self == .fahrenheitToCelsius ? .celsius : .fahrenheit }
    var inputSymbol: String         { self == .fahrenheitToCelsius ? "°F" : "°C" }
    var outputSymbol: String        { self == .fahrenheitToCelsius ? "°C" : "°F" }
}

class ConversionViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var outputLabel: UILabel!
    @IBOutlet var textField: UITextField!

    private let suffixLabel = UILabel()
    static var sharedDirection: ConversionDirection = .fahrenheitToCelsius

    private var direction: ConversionDirection = .fahrenheitToCelsius {
        didSet {
            ConversionViewController.sharedDirection = direction
            textField.text = nil
            inputValue = nil
            suffixLabel.text = direction.inputSymbol
            suffixLabel.sizeToFit()
        }
    }

    @IBAction func inputFieldEditingChanged(_ textField: UITextField) {
        if let text = textField.text, let number = numberFormatter.number(from: text) {
            inputValue = Measurement(value: number.doubleValue, unit: direction.inputUnit)
        } else {
            inputValue = nil
        }
    }

    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        textField.resignFirstResponder()
    }

    var inputValue: Measurement<UnitTemperature>? {
        didSet { updateOutputLabel() }
    }

    var outputValue: Measurement<UnitTemperature>? {
        inputValue?.converted(to: direction.outputUnit)
    }

    let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 1
        nf.locale = Locale(identifier: "en_US")
        return nf
    }()

    func updateOutputLabel() {
        if let outputValue {
            outputLabel.textColor = outputValue.value < 0 ? .blue : .orange
            outputLabel.text = (numberFormatter.string(from: NSNumber(value: outputValue.value)) ?? "...") + direction.outputSymbol
        } else {
            outputLabel.textColor = .orange
            outputLabel.text = "..."
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string.isEmpty { return true }
        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return replacementText.isValidDouble(maxDecimalPlaces: 2)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self

        suffixLabel.text = direction.inputSymbol
        suffixLabel.font = textField.font
        suffixLabel.textColor = textField.textColor
        suffixLabel.sizeToFit()
        textField.rightView = suffixLabel
        textField.rightViewMode = .always

        let segControl = UISegmentedControl(items: ["°F → °C", "°C → °F"])
        segControl.selectedSegmentIndex = 0
        segControl.addTarget(self, action: #selector(directionChanged(_:)), for: .valueChanged)
        segControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segControl)

        NSLayoutConstraint.activate([
            segControl.topAnchor.constraint(equalTo: outputLabel.bottomAnchor, constant: 24),
            segControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        updateOutputLabel()
    }

    @objc private func directionChanged(_ sender: UISegmentedControl) {
        direction = sender.selectedSegmentIndex == 0 ? .fahrenheitToCelsius : .celsiusToFahrenheit
    }
}

extension String {
    func isValidDouble(maxDecimalPlaces: Int) -> Bool {
        let formatter = NumberFormatter()
        formatter.allowsFloats = true
        formatter.locale = Locale(identifier: "en_US")
        let decimalSeparator = formatter.decimalSeparator ?? "."

        if formatter.number(from: self) != nil {
            let split = self.components(separatedBy: decimalSeparator)
            let digits = split.count == 2 ? split.last ?? "" : ""
            return digits.count <= maxDecimalPlaces
        }

        return false
    }
}
