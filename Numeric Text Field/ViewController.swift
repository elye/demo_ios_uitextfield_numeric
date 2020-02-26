import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    static let DELEGATE_SIMPLE_FILTER = 100
    static let DELEGATE_COMPLEX_FILTER = 200

    override func viewDidLoad() {
        super.viewDidLoad()

        _ = setupTextFiled(placeholder: "Default TextField", yPos: 200)

        setupTextFiled(placeholder: "Number Pad Only", yPos: 250)
            .keyboardType = .numberPad

        setupTextFiled(placeholder: "Number Pad Without Paste", yPos: 300, providedView: PastelessTextFiled())
            .keyboardType = .numberPad

        _ = with(setupTextFiled(placeholder: "With Simple Delegate Filter", yPos: 350)) {
            $0.tag = ViewController.DELEGATE_SIMPLE_FILTER
            $0.delegate = self
        }

        setupTextFiled(placeholder: "With Target Editing", yPos: 400)
            .addTarget(self, action: #selector(self.myTextFieldDidChange), for: .editingChanged)

        _ = with(setupTextFiled(placeholder: "With Complex Delegate Filter", yPos: 450)) {
            $0.tag = ViewController.DELEGATE_COMPLEX_FILTER
            $0.delegate = self
        }
    }

    @objc private func myTextFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, let intText = Int(text) {
            textField.text = "\(intText)"
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
        default:
            return true
        }
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

public func with<T: AnyObject>(_ object: T, block: (T) -> Void) -> T {
    block(object)
    return object
}

class PastelessTextFiled: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return super.canPerformAction(action, withSender: sender)
            && (action == #selector(UIResponderStandardEditActions.cut)
            || action == #selector(UIResponderStandardEditActions.copy))
    }
}
