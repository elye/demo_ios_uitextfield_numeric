import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    static let DELEGATE_SIMPLE_FILTER = 100
    static let DELEGATE_COMPLEX_FILTER = 200
    static let DELEGATE_WHOLENUMBER_FILTER = 300
    static let DELEGATE_WHOLENUMBER_FILTER_FORMAT = 400
    static let MAX_VALUE = 999_999_999_999_999_999

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = setupTextFiled(placeholder: "Default TextField", yPos: 50)

        setupTextFiled(placeholder: "Number Pad Only", yPos: 100)
            .keyboardType = .numberPad

        setupTextFiled(placeholder: "Number Pad Without Paste", yPos: 150, providedView: PastelessTextFiled())
            .keyboardType = .numberPad

        with(setupTextFiled(placeholder: "With Simple Delegate Filter", yPos: 200)) {
            $0.tag = ViewController.DELEGATE_SIMPLE_FILTER
            $0.delegate = self
        }

        setupTextFiled(placeholder: "With Target Editing", yPos: 250)
            .addTarget(self, action: #selector(self.textFieldFilter), for: .editingChanged)

        with(setupTextFiled(placeholder: "With Complex Delegate Filter", yPos: 300)) {
            $0.tag = ViewController.DELEGATE_COMPLEX_FILTER
            $0.delegate = self
        }

        setupTextFiled(placeholder: "With WholeNumber Filter Editing", yPos: 350)
            .addTarget(self, action: #selector(self.wholeNumberFilter), for: .editingChanged)

        setupTextFiled(placeholder: "With WholeNumber Fixed Length Undo", yPos: 400)
            .addTarget(self, action: #selector(self.wholeNumberFilterUndo), for: .editingChanged)

        with(setupTextFiled(placeholder: "With WholeNumber Fixed Length", yPos: 450)) {
            $0.tag = ViewController.DELEGATE_WHOLENUMBER_FILTER
            $0.delegate = self
        }

        with(setupTextFiled(placeholder: "With WholeNumber Format Fixed Length", yPos: 500)) {
            $0.tag = ViewController.DELEGATE_WHOLENUMBER_FILTER_FORMAT
            $0.delegate = self
        }

    }

    @objc private func textFieldFilter(_ textField: UITextField) {
        if let text = textField.text, let intText = Int(text) {
            textField.text = "\(intText)"
        } else {
            textField.text = ""
        }
    }

    @objc private func wholeNumberFilter(_ textField: UITextField) {
        if let text = textField.text,
            let number = Decimal(string: text.filter { $0.isWholeNumber }) {
            textField.text = "\(number)"
        } else {
            textField.text = ""
        }
    }

    private var lastValue = ""
    @objc private func wholeNumberFilterUndo(_ textField: UITextField) {
        if let text = textField.text,
            let number = Decimal(string: text.filter { $0.isWholeNumber }) {
            if (number <= Decimal(ViewController.MAX_VALUE)) {
                lastValue = "\(number)"
            }
            textField.text = lastValue
        } else {
            textField.text = ""
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let invalidCharacters = CharacterSet(charactersIn: "0123456789").inverted
        switch (textField.tag) {
        case ViewController.DELEGATE_SIMPLE_FILTER:
           return (string.rangeOfCharacter(from: invalidCharacters) == nil)
        case ViewController.DELEGATE_COMPLEX_FILTER:
            return complexFilter(string, invalidCharacters, textField, range)
        case ViewController.DELEGATE_WHOLENUMBER_FILTER:
            return wholeNumberTextFieldFilter(string, invalidCharacters, textField, range)
        case ViewController.DELEGATE_WHOLENUMBER_FILTER_FORMAT:
            return wholeNumberTextFieldFilterFormat(string, invalidCharacters, textField, range)
        default:
            return true
        }
    }

    private func wholeNumberTextFieldFilter(_ string: String, _ invalidCharacters: CharacterSet, _ textField: UITextField, _ range: NSRange) -> Bool {
        if (string.rangeOfCharacter(from: invalidCharacters) == nil) {
            if let text = textField.text {
                let str = (text as NSString).replacingCharacters(in: range, with: string)
                if let number = Decimal(string: str.filter { $0.isWholeNumber }) {
                    if (number <= Decimal(ViewController.MAX_VALUE)) { textField.text = "\(number)" }
                    return false
                }
            }
            return true
        }
        return false
    }

    private func wholeNumberTextFieldFilterFormat(_ string: String, _ invalidCharacters: CharacterSet, _ textField: UITextField, _ range: NSRange) -> Bool {
        if (string.rangeOfCharacter(from: invalidCharacters) == nil) {
            if let text = textField.text {
                let str = (text as NSString).replacingCharacters(in: range, with: string)
                if let number = Decimal(string: str.filter { $0.isWholeNumber }) {
                    if (number <= Decimal(ViewController.MAX_VALUE)) { textField.text = Formatter.currencyFormat.string(for: number) }
                    return false
                }
            }
            return true
        }
        return false
    }

    private func complexFilter(_ string: String, _ invalidCharacters: CharacterSet, _ textField: UITextField, _ range: NSRange) -> Bool {
        if (string.rangeOfCharacter(from: invalidCharacters) == nil) {
            if let text = textField.text {
                var str = (text as NSString).replacingCharacters(in: range, with: string)
                if Set(str) == ["0"] {
                    textField.text = "0"
                    return false
                } else if str.first == "0" {
                    str.removeFirst()
                    textField.text = str
                    return false
                }
            }
            return true
        }
        return false
    }

    private func setupTextFiled(placeholder: String, yPos: Int, providedView: UITextField? = nil) -> UITextField {
        let textField = providedView ?? UITextField()
        textField.placeholder = placeholder
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textAlignment = .center
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 4.0
        view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.topAnchor, constant: CGFloat(yPos)),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50.0),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50.0),
            textField.heightAnchor.constraint(equalToConstant: 30)
        ])
        return textField
    }
}

public func with<T: AnyObject>(_ object: T, block: (T) -> Void) {
    block(object)
}

class PastelessTextFiled: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
            && (action == #selector(UIResponderStandardEditActions.cut)
            || action == #selector(UIResponderStandardEditActions.copy))
    }
}

private extension Formatter {
    static let currencyFormat: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}
