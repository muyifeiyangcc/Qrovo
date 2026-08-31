import UIKit
import WebKit

final class LandingViewController: QViewController {
    private var agreement = false
    override func viewDidLoad() {
        super.viewDidLoad()
        let image = UIImageView(image: UIImage.qAsset("login_bg")); image.contentMode = .scaleAspectFill; image.clipsToBounds = true; view.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: view.topAnchor), image.bottomAnchor.constraint(equalTo: view.bottomAnchor), image.leadingAnchor.constraint(equalTo: view.leadingAnchor), image.trailingAnchor.constraint(equalTo: view.trailingAnchor)])
        let newButton = button("I’m New", height: 44); let emailButton = button("Sign In By Email", height: 44)
        [newButton, emailButton].forEach { $0.layer.cornerRadius = 13 }
        let signup = UIButton(type: .system); let signupText = NSMutableAttributedString(string: "Don't have an account? ", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.white]); signupText.append(NSAttributedString(string: "Sign up", attributes: [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: QTheme.highlight, .underlineStyle: NSUnderlineStyle.single.rawValue])); signup.setAttributedTitle(signupText, for: .normal); signup.addAction(UIAction { [weak self] _ in self?.push(SignUpViewController()) }, for: .touchUpInside)
        let checkbox = UIButton(type: .custom); checkbox.configuration = nil; checkbox.backgroundColor = .clear; checkbox.setImage(UIImage(systemName: "circle"), for: .normal); checkbox.setImage(UIImage(systemName: "circle.inset.filled"), for: .selected); checkbox.tintColor = .white; checkbox.adjustsImageWhenHighlighted = false; checkbox.widthAnchor.constraint(equalToConstant: 16).isActive = true; checkbox.heightAnchor.constraint(equalToConstant: 16).isActive = true; checkbox.addAction(UIAction { [weak self] action in guard let sender = action.sender as? UIButton else { return }; sender.isSelected.toggle(); self?.agreement = sender.isSelected }, for: .touchUpInside)
        let agreementPrefix = label("By continuing you agree to our", size: 10, color: QTheme.secondaryText); agreementPrefix.numberOfLines = 1
        let termsLink = UIButton(type: .custom); termsLink.configuration = nil; termsLink.backgroundColor = .clear; termsLink.setAttributedTitle(NSAttributedString(string: "Terms of Service", attributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: QTheme.highlight, .underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal); termsLink.addAction(UIAction { [weak self] _ in self?.push(PolicyViewController(title: "Terms of Service")) }, for: .touchUpInside)
        let andLabel = label("and", size: 10, color: QTheme.secondaryText); andLabel.numberOfLines = 1
        let privacyLink = UIButton(type: .custom); privacyLink.configuration = nil; privacyLink.backgroundColor = .clear; privacyLink.setAttributedTitle(NSAttributedString(string: "Privacy Policy", attributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: QTheme.highlight, .underlineStyle: NSUnderlineStyle.single.rawValue]), for: .normal); privacyLink.addAction(UIAction { [weak self] _ in self?.push(PolicyViewController(title: "Privacy Policy")) }, for: .touchUpInside)
        [agreementPrefix, termsLink, andLabel, privacyLink].forEach { item in
            item.setContentHuggingPriority(.required, for: .horizontal)
            item.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        let agreementLine = UIStackView(arrangedSubviews: [agreementPrefix, termsLink, andLabel]); agreementLine.axis = .horizontal; agreementLine.alignment = .center; agreementLine.distribution = .fill; agreementLine.spacing = 1
        agreementLine.setContentHuggingPriority(.required, for: .horizontal); agreementLine.setContentCompressionResistancePriority(.required, for: .horizontal)
        let policyText = UIStackView(arrangedSubviews: [agreementLine, privacyLink]); policyText.axis = .vertical; policyText.alignment = .center; policyText.distribution = .fill; policyText.spacing = 0; policyText.heightAnchor.constraint(equalToConstant: 30).isActive = true
        policyText.setContentHuggingPriority(.required, for: .horizontal); policyText.setContentCompressionResistancePriority(.required, for: .horizontal)
        let policyRow = UIStackView(arrangedSubviews: [checkbox, policyText]); policyRow.axis = .horizontal; policyRow.alignment = .top; policyRow.spacing = 2; policyRow.heightAnchor.constraint(equalToConstant: 30).isActive = true
        policyRow.setContentHuggingPriority(.required, for: .horizontal); policyRow.setContentCompressionResistancePriority(.required, for: .horizontal)
        signup.heightAnchor.constraint(equalToConstant: 16).isActive = true
        [newButton, emailButton, signup, policyRow].forEach { view.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            newButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 45), newButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -45), newButton.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -206),
            emailButton.leadingAnchor.constraint(equalTo: newButton.leadingAnchor), emailButton.trailingAnchor.constraint(equalTo: newButton.trailingAnchor), emailButton.topAnchor.constraint(equalTo: newButton.bottomAnchor, constant: 20),
            signup.centerXAnchor.constraint(equalTo: view.centerXAnchor), signup.topAnchor.constraint(equalTo: emailButton.bottomAnchor, constant: 18),
            policyRow.centerXAnchor.constraint(equalTo: view.centerXAnchor), policyRow.topAnchor.constraint(equalTo: signup.bottomAnchor, constant: 14), policyRow.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16), policyRow.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
        newButton.addAction(UIAction { _ in AppCoordinator.shared.showMain() }, for: .touchUpInside)
        emailButton.addAction(UIAction { [weak self] _ in guard let self else { return }; guard agreement else { showMessage("Agreement required", "Please agree to the Terms of Service and Privacy Policy before continuing."); return }; push(SignInViewController()) }, for: .touchUpInside)
    }
    private func push(_ vc: UIViewController) { navigationController?.pushViewController(vc, animated: true) }
}

class FormViewController: QViewController {
    let formScroll = UIScrollView(); let content = UIView(); let formStack = UIStackView()
    override func viewDidLoad() { super.viewDidLoad(); formScroll.alwaysBounceVertical = true; formScroll.keyboardDismissMode = .interactive; view.addSubview(formScroll); formScroll.translatesAutoresizingMaskIntoConstraints = false; content.translatesAutoresizingMaskIntoConstraints = false; formScroll.addSubview(content); NSLayoutConstraint.activate([formScroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), formScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), formScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), formScroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -76), content.leadingAnchor.constraint(equalTo: formScroll.contentLayoutGuide.leadingAnchor, constant: 16), content.trailingAnchor.constraint(equalTo: formScroll.contentLayoutGuide.trailingAnchor, constant: -16), content.topAnchor.constraint(equalTo: formScroll.contentLayoutGuide.topAnchor), content.bottomAnchor.constraint(equalTo: formScroll.contentLayoutGuide.bottomAnchor), content.widthAnchor.constraint(equalTo: formScroll.frameLayoutGuide.widthAnchor, constant: -32)]); formStack.axis = .vertical; formStack.spacing = 0; content.addSubview(formStack); formStack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([formStack.topAnchor.constraint(equalTo: content.topAnchor), formStack.leadingAnchor.constraint(equalTo: content.leadingAnchor), formStack.trailingAnchor.constraint(equalTo: content.trailingAnchor), formStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -30)]) }
    func addTitle(_ text: String, subtitle: String? = nil, showsBack: Bool = true) { if showsBack { let back = UIButton(type: .system); back.setImage(UIImage(systemName: "arrow.left"), for: .normal); back.tintColor = .white; back.contentHorizontalAlignment = .left; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); back.heightAnchor.constraint(equalToConstant: 40).isActive = true; formStack.addArrangedSubview(back); formStack.setCustomSpacing(15, after: back) } else { let topInset = UIView(); topInset.heightAnchor.constraint(equalToConstant: 26).isActive = true; formStack.addArrangedSubview(topInset) }; let title = label(text, size: 40, weight: .bold); title.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true; formStack.addArrangedSubview(title); formStack.setCustomSpacing(20, after: title); if let subtitle { formStack.addArrangedSubview(label(subtitle, size: 14, color: QTheme.secondaryText)); formStack.setCustomSpacing(16, after: formStack.arrangedSubviews.last!) } }
    func addField(_ title: String, _ field: UITextField) { let caption = label(title, size: 14, color: QTheme.secondaryText); caption.heightAnchor.constraint(equalToConstant: 17).isActive = true; formStack.addArrangedSubview(caption); formStack.setCustomSpacing(6, after: caption); formStack.addArrangedSubview(field); formStack.setCustomSpacing(14, after: field) }
    func addBottomButton(_ title: String, action: @escaping () -> Void) { let b = button(title, height: 52); b.addAction(UIAction { _ in action() }, for: .touchUpInside); view.addSubview(b); b.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([b.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), b.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), b.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)]) }
}

final class SignInViewController: FormViewController {
    private let email = UITextField(); private let password = UITextField()
    override func viewDidLoad() { super.viewDidLoad(); addTitle("Sign In"); email.placeholder = "Enter Email Address"; password.placeholder = "Enter Password"; [email, password].forEach { $0.textColor = .white; $0.backgroundColor = QTheme.surface; $0.layer.cornerRadius = 10; $0.layer.borderWidth = 1; $0.layer.borderColor = QTheme.divider.cgColor; $0.heightAnchor.constraint(equalToConstant: 42).isActive = true; $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1)); $0.leftViewMode = .always }; password.isSecureTextEntry = true; addField("Email", email); addField("Password", password); let forgot = UIButton(type: .system); forgot.setTitle("Forgot Password?", for: .normal); forgot.setTitleColor(QTheme.highlight, for: .normal); forgot.contentHorizontalAlignment = .left; forgot.addAction(UIAction { [weak self] _ in self?.navigationController?.pushViewController(ForgotPasswordViewController(), animated: true) }, for: .touchUpInside); formStack.addArrangedSubview(forgot); addBottomButton("Confirm profile") { [weak self] in guard let self else { return }; if QRepository.shared.authenticate(email: email.text ?? "", password: password.text ?? "") { AppCoordinator.shared.showMain() } else { showMessage("Unable to sign in", "Check your email and password and try again.") } } }
}

final class SignUpViewController: FormViewController {
    private let email = UITextField(); private let password = UITextField(); private let confirm = UITextField()
    override func viewDidLoad() { super.viewDidLoad(); addTitle("Sign Up"); email.placeholder = "Enter Email Address"; password.placeholder = "Enter Password"; confirm.placeholder = "Please Enter The Password Again"; [email, password, confirm].enumerated().forEach { index, f in f.textColor = .white; f.backgroundColor = QTheme.surface; f.layer.cornerRadius = 10; f.layer.borderWidth = 1; f.layer.borderColor = QTheme.divider.cgColor; f.heightAnchor.constraint(equalToConstant: 42).isActive = true; f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1)); f.leftViewMode = .always; f.isSecureTextEntry = index > 0; f.keyboardType = index == 0 ? .emailAddress : .numberPad }; addField("Email", email); addField("Password", password); addField("Password", confirm); addBottomButton("Confirm profile") { [weak self] in guard let self else { return }; let passwordIsSixDigits = password.text?.count == 6 && password.text?.allSatisfy({ $0.isNumber }) == true; guard email.text?.contains("@") == true, passwordIsSixDigits, password.text == confirm.text else { showMessage("Check your details", "Enter a valid email and matching six-digit password."); return }; guard QRepository.shared.register(email: email.text ?? "", password: password.text ?? "") else { showMessage("Account already exists", "Use a different email or sign in to continue."); return }; navigationController?.pushViewController(ProfileSetupViewController(), animated: true) } }
}

final class ForgotPasswordViewController: FormViewController {
    override func viewDidLoad() { super.viewDidLoad(); addTitle("Forgot\nPassword"); let email = textField("Enter Email Address"); let pass = textField("Enter Password", secure: true); let confirm = textField("Please Enter The Password Again", secure: true); addField("Email", email); addField("Password", pass); addField("Password", confirm); addBottomButton("Confirm profile") { [weak self] in guard let self else { return }; guard pass.text == confirm.text, (pass.text?.count ?? 0) >= 8, QRepository.shared.resetPassword(email: email.text ?? "", password: pass.text ?? "") else { showMessage("Unable to reset password", "Check the email and password fields."); return }; showMessage("Password updated", "You can sign in with your new password.") { self.navigationController?.popViewController(animated: true) } } }
}

final class ProfileSetupViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    private let avatarView = UIImageView()
    private let nameField = UITextField()
    private let birthdayField = UITextField()
    private let genderField = UITextField()
    private var selectedAvatar: UIImage?
    private var birthdaySheetPending = false
    private var keyboardHideObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        birthdayField.delegate = self
        addTitle("Set Up Your\nProfile", showsBack: true)
        avatarView.image = QRepository.shared.currentUser?.avatarAsset.flatMap { UIImage.qAsset($0) ?? UIImage(contentsOfFile: $0) }
        avatarView.contentMode = .scaleAspectFill; avatarView.layer.cornerRadius = 15; avatarView.clipsToBounds = true; avatarView.backgroundColor = QTheme.surface
        avatarView.widthAnchor.constraint(equalToConstant: 114).isActive = true; avatarView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        let camera = UIImageView(image: UIImage(systemName: "camera")); camera.tintColor = .white; camera.contentMode = .scaleAspectFit; camera.widthAnchor.constraint(equalToConstant: 32).isActive = true; camera.heightAnchor.constraint(equalToConstant: 32).isActive = true
        let addLabel = label("Add photo", size: 14, color: QTheme.secondaryText); let addStack = stack(7); addStack.alignment = .center; addStack.addArrangedSubview(camera); addStack.addArrangedSubview(addLabel); avatarView.addSubview(addStack); addStack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([addStack.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor), addStack.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)])
        let add = UIButton(type: .system); add.addAction(UIAction { [weak self] _ in self?.chooseAvatar() }, for: .touchUpInside); avatarView.addSubview(add); add.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([add.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor), add.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor), add.topAnchor.constraint(equalTo: avatarView.topAnchor), add.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor)])
        nameField.placeholder = "Your name"; birthdayField.placeholder = "Birthday"; genderField.placeholder = "Male / Female"
        [nameField, birthdayField, genderField].forEach { field in field.textColor = .white; field.font = .systemFont(ofSize: 15); field.backgroundColor = QTheme.surface; field.layer.cornerRadius = 10; field.layer.borderWidth = 1; field.layer.borderColor = QTheme.divider.cgColor; field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1)); field.leftViewMode = .always; field.heightAnchor.constraint(equalToConstant: 42).isActive = true }
        let nameCaption = label("Name", size: 14, color: QTheme.secondaryText); let hint = label("This is how people will find you.", size: 12, color: QTheme.secondaryText)
        let nameColumn = stack(6); nameColumn.addArrangedSubview(nameCaption); nameColumn.addArrangedSubview(nameField); nameColumn.addArrangedSubview(hint)
        let profileRow = UIStackView(arrangedSubviews: [avatarView, nameColumn]); profileRow.axis = .horizontal; profileRow.alignment = .top; profileRow.spacing = 16; formStack.addArrangedSubview(profileRow); formStack.setCustomSpacing(14, after: profileRow)
        let divider = UIView(); divider.backgroundColor = QTheme.mutedText; divider.heightAnchor.constraint(equalToConstant: 1).isActive = true; formStack.addArrangedSubview(divider); formStack.setCustomSpacing(6, after: divider)
        addField("Birthday", birthdayField)
        birthdayField.rightView = UIImageView(image: UIImage(systemName: "calendar")); birthdayField.rightView?.tintColor = .white; birthdayField.rightView?.contentMode = .scaleAspectFit; birthdayField.rightView?.frame = CGRect(x: 0, y: 0, width: 22, height: 22); birthdayField.rightViewMode = .always
        formStack.addArrangedSubview(label("Gender", size: 14, color: QTheme.secondaryText)); formStack.setCustomSpacing(6, after: formStack.arrangedSubviews.last!); let gender = UISegmentedControl(items: ["Male", "Female"]); gender.selectedSegmentIndex = 1; gender.selectedSegmentTintColor = QTheme.brightPurple; gender.backgroundColor = QTheme.surface; gender.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal); gender.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected); gender.heightAnchor.constraint(equalToConstant: 44).isActive = true; gender.addAction(UIAction { [weak self] action in guard let c = action.sender as? UISegmentedControl else { return }; self?.genderField.text = c.selectedSegmentIndex == 0 ? "Male" : "Female" }, for: .valueChanged); genderField.text = "Female"; formStack.addArrangedSubview(gender)
        addBottomButton("Confirm profile") { [weak self] in self?.saveProfile() }
    }

    private func chooseAvatar() { let sheet = QMediaActionSheet { [weak self] source in guard let self, UIImagePickerController.isSourceTypeAvailable(source) else { return }; let picker = UIImagePickerController(); picker.sourceType = source; picker.delegate = self; self.present(picker, animated: true) }; sheet.modalPresentationStyle = .overFullScreen; present(sheet, animated: true) }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { if let image = info[.originalImage] as? UIImage { selectedAvatar = image; avatarView.image = image }; picker.dismiss(animated: true) }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        guard textField === birthdayField else { return true }
        openBirthdayPicker()
        return false
    }

    private func openBirthdayPicker() {
        guard !birthdaySheetPending else { return }
        birthdaySheetPending = true
        view.endEditing(true)
        keyboardHideObserver = NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.presentBirthdayPickerIfNeeded()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.presentBirthdayPickerIfNeeded()
        }
    }

    private func presentBirthdayPickerIfNeeded() {
        guard birthdaySheetPending else { return }
        if let keyboardHideObserver { NotificationCenter.default.removeObserver(keyboardHideObserver); self.keyboardHideObserver = nil }
        birthdaySheetPending = false
        let sheet = QDatePickerSheet { [weak self] date in let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; self?.birthdayField.text = f.string(from: date) }
        sheet.modalPresentationStyle = .overFullScreen
        present(sheet, animated: true)
    }

    private func saveProfile() { let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; guard !name.isEmpty else { showMessage("Name required", "Add your name to continue."); return }; QRepository.shared.updateCurrentUser(name: name, birthday: birthdayField.text, gender: genderField.text); if let selectedAvatar { _ = QRepository.shared.saveCurrentAvatar(selectedAvatar) }; showMessage("Profile ready", "Your profile is ready to explore.") { AppCoordinator.shared.showMain() } }
}

final class QMediaActionSheet: UIViewController {
    private let onSelect: (UIImagePickerController.SourceType) -> Void
    init(onSelect: @escaping (UIImagePickerController.SourceType) -> Void) { self.onSelect = onSelect; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.62); let card = UIView(); card.backgroundColor = UIColor(hex: "1A1740"); card.layer.cornerRadius = 18; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)]); let title = UILabel(); title.text = "Add photo"; title.textColor = .white; title.font = .systemFont(ofSize: 17, weight: .bold); title.textAlignment = .center; let photos = button("Choose from Photos", icon: "photo"); let camera = button("Take Photo", icon: "camera"); let cancel = button("Cancel", icon: "xmark", filled: false); photos.addAction(UIAction { [weak self] _ in guard let self else { return }; let select = self.onSelect; self.dismiss(animated: true) { select(.photoLibrary) } }, for: .touchUpInside); camera.addAction(UIAction { [weak self] _ in guard let self else { return }; let select = self.onSelect; self.dismiss(animated: true) { select(.camera) } }, for: .touchUpInside); cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside); let stack = UIStackView(arrangedSubviews: [title, photos, camera, cancel]); stack.axis = .vertical; stack.spacing = 10; card.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)]) }
    private func button(_ title: String, icon: String, filled: Bool = true) -> UIButton { let b = QGradientButton(frame: .zero); b.setTitle("  \(title)", for: .normal); b.setImage(UIImage(systemName: icon), for: .normal); b.tintColor = .white; b.setTitleColor(.white, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold); b.layer.cornerRadius = 12; b.heightAnchor.constraint(equalToConstant: 46).isActive = true; if !filled { b.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }; b.layer.borderWidth = 1; b.layer.borderColor = UIColor.white.cgColor }; return b }
}

final class QPublishMediaSheet: UIViewController {
    private let isVideo: Bool
    private let onSelect: (UIImagePickerController.SourceType) -> Void
    init(isVideo: Bool, onSelect: @escaping (UIImagePickerController.SourceType) -> Void) {
        self.isVideo = isVideo
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.64)
        let card = UIView()
        card.backgroundColor = UIColor(hex: "1A1740")
        card.layer.cornerRadius = 18
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.clipsToBounds = true
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        let background = UIImageView(image: UIImage.qAsset("alert_bg"))
        background.contentMode = .scaleAspectFill
        background.alpha = 0.45
        card.addSubview(background)
        background.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([background.leadingAnchor.constraint(equalTo: card.leadingAnchor), background.trailingAnchor.constraint(equalTo: card.trailingAnchor), background.topAnchor.constraint(equalTo: card.topAnchor), background.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let grabber = UIView()
        grabber.backgroundColor = UIColor.white.withAlphaComponent(0.38)
        grabber.layer.cornerRadius = 2
        card.addSubview(grabber)
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([grabber.topAnchor.constraint(equalTo: card.topAnchor, constant: 9), grabber.centerXAnchor.constraint(equalTo: card.centerXAnchor), grabber.widthAnchor.constraint(equalToConstant: 38), grabber.heightAnchor.constraint(equalToConstant: 4)])
        let title = UILabel()
        title.text = isVideo ? "Add video" : "Add photo"
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.textAlignment = .center
        let library = sheetButton(isVideo ? "Choose video from Photos" : "Choose from Photos", icon: isVideo ? "video" : "photo")
        let camera = sheetButton(isVideo ? "Record Video" : "Take Photo", icon: isVideo ? "video.badge.plus" : "camera")
        let cancel = sheetButton("Cancel", icon: "xmark", filled: false)
        library.addAction(UIAction { [weak self] _ in self?.select(.photoLibrary) }, for: .touchUpInside)
        camera.addAction(UIAction { [weak self] _ in self?.select(.camera) }, for: .touchUpInside)
        cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [title, library, camera, cancel])
        stack.axis = .vertical
        stack.spacing = 10
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), stack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 19), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)])
    }
    private func sheetButton(_ title: String, icon: String, filled: Bool = true) -> UIButton {
        let button = QGradientButton(frame: .zero)
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .white
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
        if !filled {
            button.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
            button.layer.borderWidth = 1
            button.layer.borderColor = QTheme.divider.cgColor
        }
        return button
    }
    private func select(_ source: UIImagePickerController.SourceType) {
        dismiss(animated: true) { [weak self] in self?.onSelect(source) }
    }
}

final class QDatePickerSheet: UIViewController {
    private let onDone: (Date) -> Void
    init(onDone: @escaping (Date) -> Void) { self.onDone = onDone; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func dateLabel(_ text: String, size: CGFloat, weight: UIFont.Weight, color: UIColor = QTheme.text) -> UILabel { let view = UILabel(); view.text = text; view.textColor = color; view.font = .systemFont(ofSize: size, weight: weight); return view }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.62); let card = UIView(); card.backgroundColor = UIColor(hex: "1A1740"); card.layer.cornerRadius = 18; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)]); let title = dateLabel("Birthday", size: 17, weight: .bold); title.textAlignment = .center; let picker = UIDatePicker(); picker.datePickerMode = .date; picker.preferredDatePickerStyle = .wheels; picker.maximumDate = Date(); let done = QGradientButton(frame: .zero); done.setTitle("Done", for: .normal); done.layer.cornerRadius = 12; done.heightAnchor.constraint(equalToConstant: 46).isActive = true; done.addAction(UIAction { [weak self, weak picker] _ in guard let self else { return }; dismiss(animated: true) { self.onDone(picker?.date ?? Date()) } }, for: .touchUpInside); let stack = UIStackView(arrangedSubviews: [title, picker, done]); stack.axis = .vertical; stack.spacing = 10; card.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 24), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)]) }
}

final class QDrawFilterSheet: UIViewController {
    private let sheetTitle: String
    private let options: [String]
    private let selectedIndex: Int
    private let onSelect: (Int) -> Void

    init(title: String, options: [String], selectedIndex: Int, onSelect: @escaping (Int) -> Void) {
        sheetTitle = title
        self.options = options
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        dismissTap.delegate = self
        view.addGestureRecognizer(dismissTap)

        let card = UIView()
        card.backgroundColor = UIColor(hex: "171326")
        card.layer.cornerRadius = 22
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.clipsToBounds = true
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let grabber = UIView()
        grabber.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        grabber.layer.cornerRadius = 2
        card.addSubview(grabber)
        grabber.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grabber.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            grabber.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            grabber.widthAnchor.constraint(equalToConstant: 38),
            grabber.heightAnchor.constraint(equalToConstant: 4)
        ])

        let title = UILabel()
        title.text = sheetTitle
        title.textColor = .white
        title.font = .systemFont(ofSize: 17, weight: .bold)
        title.textAlignment = .center
        card.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])

        options.enumerated().forEach { index, option in
            let row = UIButton(type: .system)
            row.setTitle(index == selectedIndex ? "✓  \(option)" : option, for: .normal)
            row.setTitleColor(index == selectedIndex ? .white : QTheme.secondaryText, for: .normal)
            row.titleLabel?.font = .systemFont(ofSize: 16, weight: index == selectedIndex ? .semibold : .regular)
            row.contentHorizontalAlignment = .left
            row.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            row.backgroundColor = index == selectedIndex ? QTheme.purple.withAlphaComponent(0.82) : QTheme.surface
            row.layer.cornerRadius = 12
            row.heightAnchor.constraint(equalToConstant: 48).isActive = true
            row.addAction(UIAction { [weak self] _ in
                self?.dismiss(animated: true) { self?.onSelect(index) }
            }, for: .touchUpInside)
            stack.addArrangedSubview(row)
        }
    }

    @objc private func dismissSheet() { dismiss(animated: true) }
}

extension QDrawFilterSheet: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view === view
    }
}

final class PolicyViewController: QViewController {
    private let pageTitle: String
    init(title: String = "Privacy Policy") { pageTitle = title; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { pageTitle = "Privacy Policy"; super.init(coder: coder) }
    override func viewDidLoad() {
        super.viewDidLoad()
        let header = navHeader(pageTitle)
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false

        let webView = WKWebView(frame: .zero)
        webView.backgroundColor = QTheme.background
        webView.isOpaque = false
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            webView.topAnchor.constraint(equalTo: header.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        guard let url = URL(string: "https://www.baidu.com") else { return }
        webView.load(URLRequest(url: url))
    }
}

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate, UINavigationControllerDelegate {
    private let repo = QRepository.shared
    private let customTabBar = QCustomTabBar()
    private var claimedPublishTask: QDrawTask?
    private var claimedPublishAt: Date?
    override func viewDidLoad() {
        super.viewDidLoad(); delegate = self
        let appearance = UITabBarAppearance(); appearance.configureWithOpaqueBackground(); appearance.backgroundColor = UIColor(hex: "0D0F12", alpha: 0.97); appearance.shadowColor = UIColor(hex: "24262B")
        configure(appearance.stackedLayoutAppearance); configure(appearance.inlineLayoutAppearance); configure(appearance.compactInlineLayoutAppearance)
        tabBar.standardAppearance = appearance; tabBar.scrollEdgeAppearance = appearance; tabBar.backgroundImage = UIImage(); tabBar.shadowImage = UIImage(); tabBar.backgroundColor = UIColor(hex: "0D0F12"); tabBar.isTranslucent = false; tabBar.itemPositioning = .fill; tabBar.tintColor = .clear; tabBar.unselectedItemTintColor = .clear; tabBar.layer.cornerRadius = 0; tabBar.layer.masksToBounds = true
        let pages: [(UIViewController, String, String)] = [(ExploreViewController(), "Explore", "tab1"), (DrawViewController(), "Draw", "tab2"), (PublishViewController(), "Publish", "tab3"), (InboxViewController(), "Inbox", "tab4"), (ProfileViewController(), "Profile", "tab5")]
        viewControllers = pages.enumerated().map { index, item in
            let nav = UINavigationController(rootViewController: item.0); nav.delegate = self; nav.setNavigationBarHidden(true, animated: false)
            let normal = (UIImage.qAsset(item.2) ?? UIImage.qAsset("tab/\(item.2)") ?? UIImage(systemName: "circle"))?.withRenderingMode(.alwaysOriginal)
            let selected = (UIImage.qAsset("\(item.2)_sel") ?? UIImage.qAsset("tab/\(item.2)_sel") ?? normal)?.withRenderingMode(.alwaysOriginal)
            let tab = UITabBarItem(title: item.1, image: normal, selectedImage: selected); tab.imageInsets = UIEdgeInsets(top: 2, left: 0, bottom: -2, right: 0); tab.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1); tab.tag = index; nav.tabBarItem = tab; return nav
        }
        tabBar.isHidden = true; tabBar.alpha = 0; tabBar.isUserInteractionEnabled = false
        viewControllers?.forEach { $0.additionalSafeAreaInsets.bottom = 83 }
        customTabBar.onSelect = { [weak self] index in self?.selectTab(index) }
        view.addSubview(customTabBar); customTabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor), customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor), customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor), customTabBar.heightAnchor.constraint(equalToConstant: 83)])
        selectedIndex = 0; customTabBar.selectedIndex = 0
    }
    private func configure(_ item: UITabBarItemAppearance) { item.normal.iconColor = .clear; item.selected.iconColor = .clear; item.normal.titleTextAttributes = [.foregroundColor: UIColor(hex: "77757F"), .font: UIFont.systemFont(ofSize: 10, weight: .regular)]; item.selected.titleTextAttributes = [.foregroundColor: UIColor(hex: "B778FF"), .font: UIFont.systemFont(ofSize: 10, weight: .medium)]; item.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1); item.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 1) }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); updateTabBarVisibility() }
    private func updateTabBarVisibility() { tabBar.isHidden = true; tabBar.alpha = 0; guard let nav = selectedViewController as? UINavigationController else { return }; let isRoot = nav.viewControllers.count == 1; customTabBar.isHidden = !isRoot; nav.additionalSafeAreaInsets.bottom = isRoot ? 83 : 0 }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) { updateTabBarVisibility() }
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool { guard let index = viewControllers?.firstIndex(of: viewController) else { return true }; if !repo.isSignedIn && index >= 2 { showGuestSignInSheet(); return false }; return true }
    private func showGuestSignInSheet() { let alert = QAlertViewController(titleText: "Sign In Required", messageText: "Please sign in to continue.", cancelTitle: nil, confirmTitle: "Sign In") { AppCoordinator.shared.showAuth() }; alert.modalPresentationStyle = .overFullScreen; alert.modalTransitionStyle = .crossDissolve; present(alert, animated: true) }
    func presentPublish(for post: QPost) { let task = post.taskID.flatMap { repo.drawTask(id: $0) } ?? QDrawTask(id: "post-\(post.id)", title: post.title, body: "Complete the task and share your proof.", mediaAsset: post.mediaAssets.first ?? "default_photo", durationHours: 24, distanceMiles: nil); presentPublish(for: task) }
    func presentPublish(for task: QDrawTask) {
        guard repo.isSignedIn else { showToast("Sign in to publish a task"); return }
        if !repo.hasDrawnToday {
            presentClaimedPublish(task)
            return
        }
        let confirmation = QAlertViewController(titleText: "Use this task?", messageText: "Using this task requires 120 coins.", cancelTitle: "Cancel", confirmTitle: "Confirm") { [weak self] in
            guard let self else { return }
            guard self.repo.spendCoins(120) else {
                let insufficient = QAlertViewController(titleText: "Not Enough Coins", messageText: "You need 120 coins to use this task. Please recharge.", cancelTitle: nil, confirmTitle: "Recharge") { [weak self] in
                    guard let self else { return }
                    let recharge = RechargeViewController()
                    if let navigationController = self.selectedViewController as? UINavigationController {
                        navigationController.pushViewController(recharge, animated: true)
                        self.updateTabBarVisibility()
                    } else {
                        let navigationController = UINavigationController(rootViewController: recharge)
                        navigationController.setNavigationBarHidden(true, animated: false)
                        navigationController.modalPresentationStyle = .fullScreen
                        self.present(navigationController, animated: true)
                    }
                }
                insufficient.modalPresentationStyle = .overFullScreen
                insufficient.modalTransitionStyle = .crossDissolve
                self.present(insufficient, animated: true)
                return
            }
            self.presentClaimedPublish(task)
        }
        confirmation.modalPresentationStyle = .overFullScreen
        confirmation.modalTransitionStyle = .crossDissolve
        present(confirmation, animated: true)
    }
    private func presentClaimedPublish(_ task: QDrawTask) { claimedPublishTask = task; claimedPublishAt = Date(); let publish = PublishViewController(task: task, claimedAt: claimedPublishAt); publish.modalPresentationStyle = .fullScreen; present(publish, animated: true) }
    func clearClaimedPublishTask() { claimedPublishTask = nil; claimedPublishAt = nil }
    func showExplore() { guard let controllers = viewControllers, controllers.indices.contains(0), let nav = controllers[0] as? UINavigationController else { return }; nav.popToRootViewController(animated: false); selectedIndex = 0; customTabBar.selectedIndex = 0; updateTabBarVisibility() }
    private func selectTab(_ index: Int) { guard let controllers = viewControllers, controllers.indices.contains(index) else { return }; guard tabBarController(self, shouldSelect: controllers[index]) else { return }; if index == 2 { guard let task = claimedPublishTask else { showToast("Draw a task before publishing"); return }; let publish = PublishViewController(task: task, claimedAt: claimedPublishAt); publish.modalPresentationStyle = .fullScreen; present(publish, animated: true); return }; selectedIndex = index; customTabBar.selectedIndex = index }
    private func showToast(_ text: String) {
        let toast = UIView()
        toast.backgroundColor = UIColor(hex: "242033").withAlphaComponent(0.96)
        toast.layer.cornerRadius = 12
        toast.clipsToBounds = true

        let message = UILabel()
        message.text = text
        message.textColor = .white
        message.font = .systemFont(ofSize: 13, weight: .medium)
        message.textAlignment = .center
        message.numberOfLines = 2
        toast.addSubview(message)
        message.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            message.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16),
            message.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16),
            message.topAnchor.constraint(equalTo: toast.topAnchor, constant: 10),
            message.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -10)
        ])

        view.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -94),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 36),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -36),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])
        UIView.animate(withDuration: 0.25, delay: 1.6, options: .curveEaseIn, animations: { toast.alpha = 0 }) { _ in toast.removeFromSuperview() }
    }
}

final class QCustomTabBar: UIView {
    var onSelect: ((Int) -> Void)?
    var selectedIndex = 0 { didSet { updateSelection() } }
    private let items = [("Explore", "tab1"), ("Draw", "tab2"), ("Publish", "tab3"), ("Inbox", "tab4"), ("Profile", "tab5")]
    private var buttons: [UIButton] = []
    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { super.init(coder: coder); build() }
    private func build() {
        backgroundColor = UIColor(hex: "0D0F12")
        let separator = UIView(); separator.backgroundColor = UIColor(hex: "24262B"); addSubview(separator); separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([separator.leadingAnchor.constraint(equalTo: leadingAnchor), separator.trailingAnchor.constraint(equalTo: trailingAnchor), separator.topAnchor.constraint(equalTo: topAnchor), separator.heightAnchor.constraint(equalToConstant: 1)])
        let row = UIStackView(); row.axis = .horizontal; row.distribution = .fillEqually; row.alignment = .fill; addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16), row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16), row.topAnchor.constraint(equalTo: topAnchor, constant: 8), row.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -5)])
        items.enumerated().forEach { index, item in
            let button = QCustomTabButton(type: .custom); button.tag = index; button.addAction(UIAction { [weak self] action in guard let sender = action.sender as? UIButton else { return }; self?.onSelect?(sender.tag) }, for: .touchUpInside)
            let image = (UIImage.qAsset(item.1) ?? UIImage.qAsset("tab/\(item.1)"))?.withRenderingMode(.alwaysOriginal); button.setImage(image, for: .normal); button.setImage((UIImage.qAsset("\(item.1)_sel") ?? UIImage.qAsset("tab/\(item.1)_sel") ?? image)?.withRenderingMode(.alwaysOriginal), for: .selected)
            button.setTitle(item.0, for: .normal); button.setTitleColor(UIColor(hex: "77757F"), for: .normal); button.setTitleColor(UIColor(hex: "B778FF"), for: .selected); button.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular); button.titleLabel?.textAlignment = .center; button.imageView?.contentMode = .scaleAspectFit; row.addArrangedSubview(button); buttons.append(button)
        }
        updateSelection()
    }
    private func updateSelection() { buttons.enumerated().forEach { $0.element.isSelected = $0.offset == selectedIndex } }
}

final class QCustomTabButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        let iconSize: CGFloat = 24
        imageView?.frame = CGRect(x: (bounds.width - iconSize) / 2, y: 3, width: iconSize, height: iconSize)
        titleLabel?.frame = CGRect(x: 0, y: 31, width: bounds.width, height: 16)
    }
}
