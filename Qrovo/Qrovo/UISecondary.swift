import UIKit
import AVFoundation
import StoreKit
import AVKit

final class FieldNoteViewController: RootPageViewController {
    private let postID: String
    private var commentField = UITextField()
    private let composer = UIView()
    init(post: QPost) { self.postID = post.id; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); rebuild(); setupComposer(); scroll.contentInset.bottom = 92; scroll.verticalScrollIndicatorInsets.bottom = 92 }
    override func rebuild() { guard let post = QRepository.shared.post(postID) else { navigationController?.popViewController(animated: true); return }; body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(fieldHeader()); let user = QRepository.shared.user(post.authorID); let identity = stack(2); identity.addArrangedSubview(label(user?.name ?? "Unknown", size: 15, weight: .semibold)); identity.addArrangedSubview(label("\(post.location) · \(relativeTime(post.createdAt))", size: 12, color: QTheme.secondaryText)); let head = UIStackView(arrangedSubviews: [avatar(post.authorID, size: 44), identity, UIView()]); head.spacing = 10; head.alignment = .center; head.isUserInteractionEnabled = true; head.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openAuthorProfile))); if post.authorID != QRepository.shared.currentUserID { let message = button("✈  Message", height: 44, filled: false); message.widthAnchor.constraint(equalToConstant: 96).isActive = true; message.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium); message.addAction(UIAction { [weak self] _ in guard let self else { return }; guard QRepository.shared.canMessage(userID: post.authorID) else { self.showMessage("Connect to Chat", "Follow each other to unlock messages."); return }; self.push(ChatViewController(userID: post.authorID)) }, for: .touchUpInside); head.addArrangedSubview(message) }; body.addArrangedSubview(head); body.setCustomSpacing(16, after: head); body.addArrangedSubview(mediaGrid(post.mediaAssets)); body.setCustomSpacing(18, after: body.arrangedSubviews.last!); body.addArrangedSubview(label(post.title, size: 18, weight: .bold)); body.addArrangedSubview(label(post.body, size: 14, color: .white)); body.setCustomSpacing(10, after: body.arrangedSubviews.last!); body.addArrangedSubview(label("\(formattedDate(post.createdAt))", size: 11, color: QTheme.mutedText)); body.setCustomSpacing(16, after: body.arrangedSubviews.last!); let tryButton = button("◎  Try this task", height: 44); tryButton.addAction(UIAction { [weak self] _ in guard let self, let tabs = tabBarController as? MainTabBarController, let post = QRepository.shared.post(postID) else { return }; tabs.presentPublish(for: post) }, for: .touchUpInside); body.addArrangedSubview(tryButton); body.setCustomSpacing(12, after: tryButton); let actions = UIStackView(); actions.distribution = .fillEqually; let like = actionButton("\(post.isLiked ? "♥" : "♡")  \(post.likes)"); let comment = actionButton("◯  \(post.comments.count)"); let save = actionButton(post.isSaved ? "▣  Saved" : "▢  Save"); like.addAction(UIAction { _ in QRepository.shared.toggleLike(postID: self.postID) }, for: .touchUpInside); comment.addAction(UIAction { [weak self] _ in self?.commentField.becomeFirstResponder() }, for: .touchUpInside); save.addAction(UIAction { _ in QRepository.shared.toggleSave(postID: self.postID) }, for: .touchUpInside); [like, comment, save].forEach { actions.addArrangedSubview($0) }; actions.heightAnchor.constraint(equalToConstant: 36).isActive = true; body.addArrangedSubview(actions); body.setCustomSpacing(18, after: actions); body.addArrangedSubview(label("The conversation", size: 16, weight: .semibold)); post.comments.filter { !QRepository.shared.blockedUserIDs.contains($0.authorID) }.forEach { body.addArrangedSubview(commentRow($0)) } }
    @objc private func openAuthorProfile() { guard let post = QRepository.shared.post(postID), post.authorID != QRepository.shared.currentUserID else { return }; push(OtherProfileViewController(userID: post.authorID)) }
    private func fieldHeader() -> UIView { let v = UIView(); v.heightAnchor.constraint(equalToConstant: 48).isActive = true; let back = UIButton(type: .system); back.setImage(UIImage(systemName: "arrow.left"), for: .normal); back.tintColor = .white; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); v.addSubview(back); back.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: v.leadingAnchor), back.centerYAnchor.constraint(equalTo: v.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 32), back.heightAnchor.constraint(equalToConstant: 40)]); let title = label("Field note", size: 16, weight: .semibold); v.addSubview(title); title.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([title.centerXAnchor.constraint(equalTo: v.centerXAnchor), title.centerYAnchor.constraint(equalTo: v.centerYAnchor)]); let more = UIButton(type: .system); more.setImage(UIImage(systemName: "ellipsis"), for: .normal); more.tintColor = .white; more.isHidden = QRepository.shared.post(postID)?.authorID == QRepository.shared.currentUserID; more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside); v.addSubview(more); more.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([more.trailingAnchor.constraint(equalTo: v.trailingAnchor), more.centerYAnchor.constraint(equalTo: v.centerYAnchor), more.widthAnchor.constraint(equalToConstant: 32), more.heightAnchor.constraint(equalToConstant: 40)]); return v }
    private func setupComposer() { composer.backgroundColor = UIColor(hex: "111418"); composer.layer.borderColor = QTheme.divider.cgColor; composer.layer.borderWidth = 1; view.addSubview(composer); composer.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([composer.leadingAnchor.constraint(equalTo: view.leadingAnchor), composer.trailingAnchor.constraint(equalTo: view.trailingAnchor), composer.bottomAnchor.constraint(equalTo: view.bottomAnchor), composer.heightAnchor.constraint(equalToConstant: 92)]); let av = avatar(QRepository.shared.currentUserID ?? "me", size: 36); composer.addSubview(av); av.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([av.leadingAnchor.constraint(equalTo: composer.leadingAnchor, constant: 16), av.topAnchor.constraint(equalTo: composer.topAnchor, constant: 20)]); commentField = textField("Write a thoughtful reply..."); commentField.heightAnchor.constraint(equalToConstant: 40).isActive = true; composer.addSubview(commentField); commentField.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([commentField.leadingAnchor.constraint(equalTo: av.trailingAnchor, constant: 10), commentField.centerYAnchor.constraint(equalTo: av.centerYAnchor), commentField.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -88)]); let sendButton = UIButton(type: .system); sendButton.setImage(UIImage(systemName: "paperplane"), for: .normal); sendButton.tintColor = QTheme.secondaryText; sendButton.backgroundColor = QTheme.surfaceSecondary; sendButton.layer.cornerRadius = 22; composer.addSubview(sendButton); sendButton.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([sendButton.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -16), sendButton.centerYAnchor.constraint(equalTo: av.centerYAnchor), sendButton.widthAnchor.constraint(equalToConstant: 44), sendButton.heightAnchor.constraint(equalToConstant: 44)]); sendButton.addAction(UIAction { [weak self] _ in guard let self, let text = commentField.text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }; QRepository.shared.addComment(postID: self.postID, text: text); commentField.text = "" }, for: .touchUpInside) }
    private func mediaGrid(_ names: [String]) -> UIView {
        let assets = names.isEmpty ? ["default_photo"] : Array(names.prefix(3))
        let container = UIView()
        container.heightAnchor.constraint(equalToConstant: 270).isActive = true
        if assets.count == 1 {
            let item = mediaItem(assets[0], in: container)
            container.addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([item.leadingAnchor.constraint(equalTo: container.leadingAnchor), item.trailingAnchor.constraint(equalTo: container.trailingAnchor), item.topAnchor.constraint(equalTo: container.topAnchor), item.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
            return container
        }
        if assets.count == 2 {
            let scroll = UIScrollView()
            scroll.isPagingEnabled = true
            scroll.showsHorizontalScrollIndicator = false
            container.addSubview(scroll)
            scroll.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([scroll.leadingAnchor.constraint(equalTo: container.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: container.trailingAnchor), scroll.topAnchor.constraint(equalTo: container.topAnchor), scroll.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
            let row = UIStackView(); row.spacing = 8; row.alignment = .fill
            scroll.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor), row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor), row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor), row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor)])
            for asset in assets {
                let item = mediaItem(asset, in: row)
                item.translatesAutoresizingMaskIntoConstraints = false
                row.addArrangedSubview(item)
                item.widthAnchor.constraint(equalTo: container.widthAnchor).isActive = true
            }
            return container
        }
        let main = mediaItem(assets[0], in: container)
        let top = mediaItem(assets[1], in: container)
        let bottom = mediaItem(assets[2], in: container)
        let side = UIStackView(arrangedSubviews: [top, bottom]); side.axis = .vertical; side.spacing = 8; side.distribution = .fillEqually
        container.addSubview(main); container.addSubview(side)
        main.translatesAutoresizingMaskIntoConstraints = false; side.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([main.leadingAnchor.constraint(equalTo: container.leadingAnchor), main.topAnchor.constraint(equalTo: container.topAnchor), main.bottomAnchor.constraint(equalTo: container.bottomAnchor), main.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.654), side.leadingAnchor.constraint(equalTo: main.trailingAnchor, constant: 8), side.trailingAnchor.constraint(equalTo: container.trailingAnchor), side.topAnchor.constraint(equalTo: container.topAnchor), side.bottomAnchor.constraint(equalTo: container.bottomAnchor)])
        return container
    }
    private func mediaItem(_ asset: String, in parent: UIView) -> UIView {
        let item = UIButton(type: .system)
        item.backgroundColor = QTheme.surface
        item.layer.cornerRadius = 14
        item.clipsToBounds = true
        let image = UIImageView(image: safeImage([asset]))
        image.contentMode = .scaleAspectFill; image.clipsToBounds = true
        item.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: item.leadingAnchor), image.trailingAnchor.constraint(equalTo: item.trailingAnchor), image.topAnchor.constraint(equalTo: item.topAnchor), image.bottomAnchor.constraint(equalTo: item.bottomAnchor)])
        if isVideoAsset(asset) {
            let play = UIImageView(image: UIImage(systemName: "play.fill")); play.tintColor = .white; play.backgroundColor = UIColor.black.withAlphaComponent(0.38); play.layer.cornerRadius = 27; play.clipsToBounds = true; play.contentMode = .center
            item.addSubview(play); play.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([play.centerXAnchor.constraint(equalTo: item.centerXAnchor), play.centerYAnchor.constraint(equalTo: item.centerYAnchor), play.widthAnchor.constraint(equalToConstant: 54), play.heightAnchor.constraint(equalToConstant: 54)])
        }
        item.addAction(UIAction { [weak self] _ in self?.presentMedia(asset) }, for: .touchUpInside)
        return item
    }
    private func presentMedia(_ asset: String) { let viewer = MediaPreviewViewController(asset: asset); viewer.modalPresentationStyle = .fullScreen; present(viewer, animated: true) }
    private func chip(_ text: String) -> UILabel { let l = label(text, size: 11, color: QTheme.secondaryText); l.backgroundColor = QTheme.surface; l.layer.cornerRadius = 12; l.clipsToBounds = true; l.textAlignment = .center; l.heightAnchor.constraint(equalToConstant: 26).isActive = true; return l }
    private func actionButton(_ title: String) -> UIButton { let b = UIButton(type: .system); b.setTitle(title, for: .normal); b.setTitleColor(QTheme.secondaryText, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 13); return b }
    private func commentRow(_ comment: QComment) -> UIView {
        let identity = stack(2)
        identity.addArrangedSubview(label(QRepository.shared.user(comment.authorID)?.name ?? "User", size: 13, weight: .semibold))
        identity.addArrangedSubview(label(comment.text, size: 13, color: QTheme.secondaryText))
        let row = UIStackView(arrangedSubviews: [avatar(comment.authorID, size: 32), identity, UIView()])
        row.spacing = 8
        row.alignment = .top
        if comment.authorID != QRepository.shared.currentUserID {
            let more = UIButton(type: .system)
            more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
            more.tintColor = QTheme.secondaryText
            more.widthAnchor.constraint(equalToConstant: 28).isActive = true
            more.heightAnchor.constraint(equalToConstant: 28).isActive = true
            more.addAction(UIAction { [weak self] _ in
                self?.showMoreSheet(for: comment.authorID,
                    report: { [weak self] in self?.push(ReportViewController(userID: comment.authorID)) },
                    block: { [weak self] in QRepository.shared.block(userID: comment.authorID); self?.rebuild() })
            }, for: .touchUpInside)
            row.addArrangedSubview(more)
        }
        return row
    }
    private func showMore() { guard let post = QRepository.shared.post(postID), post.authorID != QRepository.shared.currentUserID else { return }; showMoreSheet(for: post.authorID, report: { [weak self] in guard let self else { return }; self.push(ReportViewController(userID: post.authorID)) }, block: { [weak self] in guard let self else { return }; QRepository.shared.block(userID: post.authorID); self.navigationController?.popViewController(animated: true) }) }
    #if DEBUG
    func visualScrollToBottom() {
        view.layoutIfNeeded()
        if let contentView = scroll.subviews.first(where: { $0 is UIStackView }) {
            let maxOffset = max(0, contentView.frame.height - scroll.bounds.height)
            scroll.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
        }
    }
    #endif
}

final class ChatViewController: QViewController, AVAudioPlayerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let userID: String
    private let messageScroll = UIScrollView()
    private let stackView = UIStackView()
    private let field = UITextField()
    private let composer = UIView()
    private let micButton = UIButton(type: .system)
    private let recordingBanner = UILabel()
    private var isRecording = false
    private var isMicPressed = false
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var player: AVAudioPlayer?
    private var playingMessageID: String?
    private var playbackTimer: Timer?

    init(userID: String) { self.userID = userID; super.init(nibName: nil, bundle: nil); NotificationCenter.default.addObserver(self, selector: #selector(repositoryChanged), name: QRepository.didChange, object: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        let cameFromInbox = navigationController?.viewControllers.dropLast().last is InboxViewController
        if !cameFromInbox && !QRepository.shared.canMessage(userID: userID) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.showMessage("Connect to Chat", "Follow each other to unlock messages.") { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            return
        }
        let header = chatHeader()
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 3),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            header.heightAnchor.constraint(equalToConstant: 52)
        ])

        messageScroll.alwaysBounceVertical = true
        messageScroll.keyboardDismissMode = .interactive
        view.addSubview(messageScroll)
        messageScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageScroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 4),
            messageScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            messageScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .fill
        messageScroll.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: messageScroll.contentLayoutGuide.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: messageScroll.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: messageScroll.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: messageScroll.contentLayoutGuide.bottomAnchor, constant: -18),
            stackView.widthAnchor.constraint(equalTo: messageScroll.frameLayoutGuide.widthAnchor)
        ])
        setupComposer()
        NSLayoutConstraint.activate([messageScroll.bottomAnchor.constraint(equalTo: composer.topAnchor)])
        rebuildMessages()
        QRepository.shared.markConversationRead(userID: userID)
    }

    private func chatHeader() -> UIView {
        let header = UIView()
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "arrow.left"), for: .normal)
        back.tintColor = .white
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let user = QRepository.shared.user(userID)
        let av = avatar(userID, size: 34)
        let name = label(user?.name ?? "Chat", size: 15, weight: .semibold)
        let online = label("●  Online", size: 10, color: QTheme.secondaryText)
        let onlineText = NSMutableAttributedString(string: "●", attributes: [.foregroundColor: UIColor.systemGreen])
        onlineText.append(NSAttributedString(string: "  Online", attributes: [.foregroundColor: QTheme.secondaryText]))
        online.attributedText = onlineText
        let identityText = stack(1)
        identityText.addArrangedSubview(name)
        identityText.addArrangedSubview(online)
        let identity = UIStackView(arrangedSubviews: [av, identityText])
        identity.spacing = 9
        identity.alignment = .center
        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        more.tintColor = .white
        more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        [back, identity, more].forEach { header.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor), back.centerYAnchor.constraint(equalTo: header.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 34), back.heightAnchor.constraint(equalToConstant: 42),
            identity.centerXAnchor.constraint(equalTo: header.centerXAnchor), identity.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            more.trailingAnchor.constraint(equalTo: header.trailingAnchor), more.centerYAnchor.constraint(equalTo: header.centerYAnchor), more.widthAnchor.constraint(equalToConstant: 34), more.heightAnchor.constraint(equalToConstant: 42)
        ])
        return header
    }

    private func setupComposer() {
        composer.backgroundColor = UIColor(hex: "0F1114")
        composer.layer.borderWidth = 1
        composer.layer.borderColor = QTheme.divider.cgColor
        view.addSubview(composer)
        composer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor), composer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composer.bottomAnchor.constraint(equalTo: view.bottomAnchor), composer.heightAnchor.constraint(equalToConstant: 83)
        ])

        let photo = UIButton(type: .system)
        photo.setImage(UIImage(systemName: "photo"), for: .normal)
        photo.tintColor = .white
        photo.addAction(UIAction { [weak self] _ in self?.choosePhoto() }, for: .touchUpInside)
        micButton.setImage(UIImage(systemName: "mic"), for: .normal)
        micButton.tintColor = .white
        micButton.layer.cornerRadius = 12
        micButton.addTarget(self, action: #selector(beginRecording), for: .touchDown)
        micButton.addTarget(self, action: #selector(endRecording), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        field.placeholder = "Message \(QRepository.shared.user(userID)?.name.components(separatedBy: " ").first ?? "user")..."
        field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "Message...", attributes: [.foregroundColor: QTheme.mutedText])
        field.textColor = .white
        field.tintColor = QTheme.highlight
        field.font = .systemFont(ofSize: 14)
        field.backgroundColor = QTheme.surface
        field.layer.cornerRadius = 15
        field.layer.borderWidth = 1
        field.layer.borderColor = QTheme.divider.cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        field.leftViewMode = .always

        let send = UIButton(type: .system)
        send.setImage(UIImage(systemName: "paperplane"), for: .normal)
        send.tintColor = .white
        send.backgroundColor = QTheme.surfaceSecondary
        send.layer.cornerRadius = 22
        send.addAction(UIAction { [weak self] _ in self?.send() }, for: .touchUpInside)
        [photo, micButton, field, send].forEach { composer.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            photo.leadingAnchor.constraint(equalTo: composer.leadingAnchor, constant: 18), photo.topAnchor.constraint(equalTo: composer.topAnchor, constant: 12), photo.widthAnchor.constraint(equalToConstant: 28), photo.heightAnchor.constraint(equalToConstant: 44),
            micButton.leadingAnchor.constraint(equalTo: photo.trailingAnchor, constant: 8), micButton.centerYAnchor.constraint(equalTo: photo.centerYAnchor), micButton.widthAnchor.constraint(equalToConstant: 42), micButton.heightAnchor.constraint(equalToConstant: 44),
            field.leadingAnchor.constraint(equalTo: micButton.trailingAnchor, constant: 4), field.centerYAnchor.constraint(equalTo: photo.centerYAnchor), field.heightAnchor.constraint(equalToConstant: 44),
            send.leadingAnchor.constraint(equalTo: field.trailingAnchor, constant: 6), send.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -13), send.centerYAnchor.constraint(equalTo: photo.centerYAnchor), send.widthAnchor.constraint(equalToConstant: 44), send.heightAnchor.constraint(equalToConstant: 44)
        ])

        recordingBanner.text = "\"Recording in progress, release to send\""
        recordingBanner.textColor = .white
        recordingBanner.textAlignment = .center
        recordingBanner.font = .systemFont(ofSize: 13)
        recordingBanner.backgroundColor = QTheme.surface
        recordingBanner.layer.cornerRadius = 17
        recordingBanner.layer.borderWidth = 1
        recordingBanner.layer.borderColor = UIColor(hex: "8E4A2E").cgColor
        recordingBanner.clipsToBounds = true
        recordingBanner.isHidden = true
        view.addSubview(recordingBanner)
        recordingBanner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordingBanner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingBanner.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -19),
            recordingBanner.widthAnchor.constraint(equalToConstant: 292),
            recordingBanner.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    @objc private func repositoryChanged() { guard isViewLoaded else { return }; rebuildMessages() }

    private func rebuildMessages() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let messages = QRepository.shared.conversation(with: userID)?.messages.filter({ !QRepository.shared.blockedUserIDs.contains($0.authorID) }) else { return }
        if let first = messages.first { stackView.addArrangedSubview(dayMarker(first.createdAt)) }
        messages.forEach { message in
            switch message.kind {
            case .text: stackView.addArrangedSubview(textMessage(message))
            case .image: stackView.addArrangedSubview(imageMessage(message))
            case .voice: stackView.addArrangedSubview(voiceMessage(message))
            }
        }
        DispatchQueue.main.async { [weak self] in self?.scrollToBottom() }
    }

    private func dayMarker(_ date: Date) -> UIView {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let text = label("Today · \(formatter.string(from: date))", size: 10, color: QTheme.secondaryText)
        text.textAlignment = .center
        text.backgroundColor = QTheme.surface
        text.layer.cornerRadius = 12
        text.clipsToBounds = true
        text.widthAnchor.constraint(equalToConstant: 92).isActive = true
        text.heightAnchor.constraint(equalToConstant: 24).isActive = true
        let row = UIStackView(arrangedSubviews: [UIView(), text, UIView()])
        return row
    }

    private func textMessage(_ message: QMessage) -> UIView {
        let mine = message.authorID == QRepository.shared.currentUserID
        let bubble = UIView()
        bubble.backgroundColor = mine ? QTheme.purple : QTheme.surface
        bubble.layer.cornerRadius = 17
        bubble.layer.maskedCorners = mine ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner] : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        let content = label(message.text, size: 14)
        bubble.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14), content.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
            content.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10), content.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 260), bubble.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
        ])
        let row = UIStackView(arrangedSubviews: mine ? [UIView(), bubble] : [avatar(message.authorID, size: 26), bubble, UIView()])
        row.spacing = 8
        row.alignment = .bottom
        return messageGroup(row: row, date: message.createdAt, mine: mine)
    }

    private func imageMessage(_ message: QMessage) -> UIView {
        let mine = message.authorID == QRepository.shared.currentUserID
        let image = UIImageView(image: assetImage(message.mediaAsset ?? "default_photo"))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 16
        image.widthAnchor.constraint(equalToConstant: 282).isActive = true
        let aspectRatio = (image.image?.size.height ?? 144) / max(image.image?.size.width ?? 282, 1)
        image.heightAnchor.constraint(equalTo: image.widthAnchor, multiplier: aspectRatio).isActive = true
        let row = UIStackView(arrangedSubviews: mine ? [UIView(), image] : [avatar(message.authorID, size: 26), image, UIView()])
        row.spacing = 8
        row.alignment = .bottom
        return messageGroup(row: row, date: message.createdAt, mine: mine)
    }

    private func voiceMessage(_ message: QMessage) -> UIView {
        let mine = message.authorID == QRepository.shared.currentUserID
        let bubble = UIControl()
        bubble.backgroundColor = mine ? QTheme.purple : QTheme.surface
        bubble.layer.cornerRadius = 16
        bubble.widthAnchor.constraint(equalToConstant: 182).isActive = true
        bubble.heightAnchor.constraint(equalToConstant: 52).isActive = true

        let isSelected = playingMessageID == message.id
        let isPlaying = isSelected && player?.isPlaying == true
        let totalDuration = voiceDuration(for: message)
        let currentTime = isSelected ? min(player?.currentTime ?? 0, totalDuration) : 0

        let play = UIButton(type: .system)
        play.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"), for: .normal)
        play.tintColor = .white
        play.accessibilityLabel = isPlaying ? "Pause voice message" : "Play voice message"
        play.addAction(UIAction { [weak self] _ in self?.toggleVoicePlayback(message) }, for: .touchUpInside)
        bubble.addAction(UIAction { [weak self] _ in self?.toggleVoicePlayback(message) }, for: .touchUpInside)

        let progress = UIProgressView(progressViewStyle: .default)
        progress.progress = totalDuration > 0 ? Float(currentTime / totalDuration) : 0
        progress.progressTintColor = isSelected ? QTheme.highlight : QTheme.secondaryText
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.18)
        progress.layer.cornerRadius = 2
        progress.clipsToBounds = true

        let duration = label(formatDuration(totalDuration), size: 9, color: isSelected ? QTheme.highlight : QTheme.secondaryText)
        [play, progress, duration].forEach { bubble.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            play.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 11),
            play.centerYAnchor.constraint(equalTo: bubble.centerYAnchor),
            play.widthAnchor.constraint(equalToConstant: 28),
            play.heightAnchor.constraint(equalToConstant: 32),
            progress.leadingAnchor.constraint(equalTo: play.trailingAnchor, constant: 7),
            progress.trailingAnchor.constraint(equalTo: duration.leadingAnchor, constant: -8),
            progress.centerYAnchor.constraint(equalTo: bubble.centerYAnchor),
            progress.heightAnchor.constraint(equalToConstant: 4),
            duration.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -10),
            duration.centerYAnchor.constraint(equalTo: bubble.centerYAnchor),
            duration.widthAnchor.constraint(equalToConstant: 28)
        ])

        let row = UIStackView(arrangedSubviews: mine ? [UIView(), bubble] : [avatar(message.authorID, size: 26), bubble, UIView()])
        row.spacing = 8
        row.alignment = .bottom
        return messageGroup(row: row, date: message.createdAt, mine: mine)
    }

    private func voiceDuration(for message: QMessage) -> TimeInterval {
        if let path = message.mediaAsset, FileManager.default.fileExists(atPath: path),
           let audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)), audioPlayer.duration > 0 {
            return audioPlayer.duration
        }
        return durationFromText(message.text)
    }

    private func durationFromText(_ text: String) -> TimeInterval {
        let parts = text.split(separator: ":")
        guard parts.count == 2, let minutes = Double(parts[0]), let seconds = Double(parts[1]) else { return 0 }
        return max(0, minutes * 60 + seconds)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    private func messageGroup(row: UIView, date: Date, mine: Bool) -> UIView {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let time = label(formatter.string(from: date), size: 8, color: QTheme.secondaryText)
        let timeRow = UIStackView(arrangedSubviews: mine ? [UIView(), time] : [time, UIView()])
        let group = UIStackView(arrangedSubviews: [row, timeRow])
        group.axis = .vertical
        group.spacing = 4
        return group
    }

    private func scrollToBottom() {
        view.layoutIfNeeded()
        let offset = max(0, messageScroll.contentSize.height - messageScroll.bounds.height)
        messageScroll.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
    }

    private func send() {
        guard let text = field.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        QRepository.shared.appendMessage(userID: userID, text: text)
        field.text = ""
    }

    private func choosePhoto() { let sheet = QMediaActionSheet { [weak self] source in guard UIImagePickerController.isSourceTypeAvailable(source) else { return }; let picker = UIImagePickerController(); picker.sourceType = source; picker.mediaTypes = ["public.image"]; picker.delegate = self; self?.present(picker, animated: true) }; sheet.modalPresentationStyle = .overFullScreen; present(sheet, animated: true) }
    private func saveChatImage(_ image: UIImage) -> String? { guard let data = image.jpegData(compressionQuality: 0.88) else { return nil }; let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QrovoChatImages", isDirectory: true); do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true); let url = folder.appendingPathComponent("chat-\(UUID().uuidString).jpg"); try data.write(to: url, options: .atomic); return url.path } catch { return nil } }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { if let image = info[.originalImage] as? UIImage, let path = saveChatImage(image) { QRepository.shared.appendMessage(userID: userID, text: "", kind: .image, mediaAsset: path) }; picker.dismiss(animated: true) }

    @objc private func beginRecording() {
        guard !isRecording else { return }
        isMicPressed = true
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                guard let self, granted, self.isMicPressed else {
                    if !granted { self?.showMessage("Microphone unavailable", "Allow microphone access to send a voice message.") }
                    return
                }
                self.startRecording(session: session)
            }
        }
    }
    private func startRecording(session: AVAudioSession) {
        do {
            try session.setCategory(.record, mode: .default, options: [.allowBluetoothHFP])
            try session.setActive(true)
            let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QrovoChatAudio", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("voice-\(UUID().uuidString).m4a")
            let settings: [String: Any] = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC), AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            let activeRecorder = try AVAudioRecorder(url: url, settings: settings)
            guard activeRecorder.prepareToRecord(), activeRecorder.record() else {
                throw VoiceRecordingError.cannotStart
            }
            recorder = activeRecorder
            recordingURL = url
            isRecording = true
            recordingBanner.isHidden = false
            micButton.layer.borderWidth = 1
            micButton.layer.borderColor = QTheme.brightPurple.cgColor
            micButton.tintColor = QTheme.highlight
        } catch {
            isMicPressed = false
            showMessage("Recording unavailable", "Please try again.")
        }
    }
    @objc private func endRecording() {
        isMicPressed = false
        guard isRecording else { return }
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        isRecording = false
        recordingBanner.isHidden = true
        micButton.layer.borderWidth = 0
        micButton.tintColor = .white
        let url = recordingURL
        let isValidFile: Bool = {
            guard let url, FileManager.default.fileExists(atPath: url.path),
                  let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let fileSize = attributes[.size] as? NSNumber else { return false }
            return fileSize.intValue > 0 && duration > 0
        }()
        if let url, isValidFile {
            QRepository.shared.appendMessage(userID: userID, text: formatDuration(max(1, duration.rounded())), kind: .voice, mediaAsset: url.path)
        } else {
            showMessage("Recording unavailable", "No audio was captured. Please try again.")
        }
        recorder = nil
        recordingURL = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    private func toggleVoicePlayback(_ message: QMessage) {
        guard let path = message.mediaAsset, FileManager.default.fileExists(atPath: path) else {
            showMessage("Playback unavailable", "This voice message is no longer available.")
            return
        }

        if playingMessageID == message.id, let currentPlayer = player {
            if currentPlayer.isPlaying {
                currentPlayer.pause()
                playbackTimer?.invalidate()
            } else {
                do {
                    try activatePlaybackSession()
                    guard currentPlayer.play() else { throw VoicePlaybackError.cannotStart }
                    startPlaybackTimer()
                } catch {
                    showMessage("Playback unavailable", "This voice message cannot be played.")
                }
            }
            rebuildMessages()
            return
        }

        do {
            try activatePlaybackSession()
            player?.stop()
            playbackTimer?.invalidate()
            let newPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            newPlayer.delegate = self
            guard newPlayer.duration > 0, newPlayer.prepareToPlay(), newPlayer.play() else {
                throw VoicePlaybackError.cannotStart
            }
            player = newPlayer
            playingMessageID = message.id
            rebuildMessages()
            startPlaybackTimer()
        } catch {
            player = nil
            playingMessageID = nil
            playbackTimer?.invalidate()
            showMessage("Playback unavailable", "This voice message cannot be played.")
        }
    }

    private func activatePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio, options: [])
        try session.setActive(true)
    }
    private func startPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] timer in
            guard let self, let player = self.player, player.isPlaying else { timer.invalidate(); return }
            self.rebuildMessages()
        }
    }

    private func showMore() { showMoreSheet(for: userID, report: { [weak self] in guard let self else { return }; let report = ReportViewController(userID: userID); report.hidesBottomBarWhenPushed = true; self.navigationController?.pushViewController(report, animated: true) }, block: { [weak self] in guard let self else { return }; QRepository.shared.block(userID: userID); self.navigationController?.popViewController(animated: true) }) }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackTimer?.invalidate()
        playingMessageID = nil
        self.player = nil
        rebuildMessages()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

private enum VoicePlaybackError: Error {
    case cannotStart
}

private enum VoiceRecordingError: Error {
    case cannotStart
}

final class OtherProfileViewController: RootPageViewController {
    let userID: String
    init(userID: String) { self.userID = userID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() {
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        more.tintColor = .white
        more.addAction(UIAction { [weak self] _ in self?.more() }, for: .touchUpInside)
        body.addArrangedSubview(navHeader("", right: more))
        guard let user = QRepository.shared.user(userID) else { body.addArrangedSubview(emptyState("Profile unavailable")); return }

        let identity = UIView()
        identity.heightAnchor.constraint(equalToConstant: 128).isActive = true
        let image = avatar(userID, size: 128)
        identity.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: identity.leadingAnchor), image.topAnchor.constraint(equalTo: identity.topAnchor)])
        let name = label(user.name, size: 21, weight: .bold)
        let handle = label("@\(user.handle)", size: 11, color: QTheme.secondaryText)
        let info = stack(5)
        [name, handle].forEach { info.addArrangedSubview($0) }
        identity.addSubview(info)
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([info.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 16), info.topAnchor.constraint(equalTo: identity.topAnchor, constant: 3), info.trailingAnchor.constraint(equalTo: identity.trailingAnchor)])
        body.addArrangedSubview(identity)
        body.setCustomSpacing(18, after: identity)

        let followers = relationshipStat(value: QRepository.shared.followerCount(for: user.id), title: "Followers")
        let following = relationshipStat(value: QRepository.shared.followingCount(for: user.id), title: "Following")
        let stats = UIStackView(arrangedSubviews: [followers, following])
        stats.distribution = .fillEqually
        stats.heightAnchor.constraint(equalToConstant: 56).isActive = true
        body.addArrangedSubview(stats)
        body.setCustomSpacing(18, after: stats)

        let follow = button(QRepository.shared.followedUserIDs.contains(userID) ? "Following" : "Follow", height: 52)
        let message = button("Message", height: 52, filled: false)
        follow.addAction(UIAction { [weak self] _ in guard let self else { return }; QRepository.shared.toggleFollow(userID: userID); self.rebuild() }, for: .touchUpInside)
        message.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            guard QRepository.shared.canMessage(userID: userID) else {
                self.showMessage("Connect to Chat", "Follow each other to unlock messages.")
                return
            }
            self.push(ChatViewController(userID: userID))
        }, for: .touchUpInside)
        let actions = UIStackView(arrangedSubviews: [follow, message])
        actions.distribution = .fillEqually
        actions.spacing = 8
        body.addArrangedSubview(actions)
        body.setCustomSpacing(20, after: actions)
        body.addArrangedSubview(label("Mission Trail", size: 20, weight: .bold))
        body.setCustomSpacing(16, after: body.arrangedSubviews.last!)
        let posts = QRepository.shared.visiblePosts.filter { $0.authorID == userID }
        if posts.isEmpty { body.addArrangedSubview(emptyState("No check-ins yet")) }
        else { posts.prefix(3).forEach { body.addArrangedSubview(profilePost($0)) } }
    }
    private func relationshipStat(value: Int, title: String) -> UIView {
        let number = label(compactCount(value), size: 15, weight: .semibold)
        number.textAlignment = .center
        let caption = label(title, size: 11, color: QTheme.mutedText)
        caption.textAlignment = .center
        let column = stack(5)
        column.alignment = .center
        column.isUserInteractionEnabled = false
        column.addArrangedSubview(number)
        column.addArrangedSubview(caption)
        return column
    }
    private func compactCount(_ value: Int) -> String { value >= 1000 ? String(format: "%.1fk", Double(value) / 1000.0) : "\(value)" }
    private func profilePost(_ post: QPost) -> UIView {
        let card = UIView()
        card.backgroundColor = QTheme.surface
        card.layer.cornerRadius = 15
        card.clipsToBounds = true
        let image = UIImageView(image: safeImage(post.mediaAssets))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        card.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: card.topAnchor), image.leadingAnchor.constraint(equalTo: card.leadingAnchor), image.trailingAnchor.constraint(equalTo: card.trailingAnchor), image.heightAnchor.constraint(equalToConstant: 383)])
        let fade = CAGradientLayer()
        fade.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.78).cgColor]
        fade.locations = [0.52, 1]
        image.layer.addSublayer(fade)
        let authorAvatar = avatar(post.authorID, size: 40)
        card.addSubview(authorAvatar)
        authorAvatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([authorAvatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), authorAvatar.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -12)])
        let more = UIButton(type: .system)
        more.setTitle("···", for: .normal)
        more.setTitleColor(.white, for: .normal)
        more.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        more.layer.cornerRadius = 11
        more.addAction(UIAction { [weak self] _ in self?.openPostMore(post) }, for: .touchUpInside)
        card.addSubview(more)
        more.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([more.topAnchor.constraint(equalTo: card.topAnchor, constant: 8), more.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8), more.widthAnchor.constraint(equalToConstant: 42), more.heightAnchor.constraint(equalToConstant: 42)])
        let author = label("\(QRepository.shared.user(post.authorID)?.name ?? userID)\n\(relativeTime(post.createdAt))", size: 12, weight: .semibold)
        card.addSubview(author)
        author.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([author.leadingAnchor.constraint(equalTo: authorAvatar.trailingAnchor, constant: 10), author.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -14), author.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -100)])
        let follow = button(QRepository.shared.followedUserIDs.contains(post.authorID) ? "Following" : "Follow", height: 40, filled: false)
        follow.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        follow.addAction(UIAction { [weak self] _ in QRepository.shared.toggleFollow(userID: post.authorID); self?.rebuild() }, for: .touchUpInside)
        card.addSubview(follow)
        follow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([follow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14), follow.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -12), follow.widthAnchor.constraint(equalToConstant: 70)])
        let title = label(post.title, size: 16, weight: .semibold, color: QTheme.highlight)
        title.numberOfLines = 2
        card.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14), title.topAnchor.constraint(equalTo: image.bottomAnchor, constant: 14)])
        let detail = label(post.body, size: 14, color: QTheme.secondaryText)
        card.addSubview(detail)
        detail.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([detail.leadingAnchor.constraint(equalTo: title.leadingAnchor), detail.trailingAnchor.constraint(equalTo: title.trailingAnchor), detail.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10), detail.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)])
        card.heightAnchor.constraint(equalToConstant: 500).isActive = true
        card.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openPost(_:))))
        card.accessibilityIdentifier = post.id
        return card
    }
    @objc private func openPost(_ gesture: UITapGestureRecognizer) { guard let id = gesture.view?.accessibilityIdentifier, let post = QRepository.shared.post(id) else { return }; push(FieldNoteViewController(post: post)) }
    private func openPostMore(_ post: QPost) { showMoreSheet(for: post.authorID, report: { [weak self] in self?.push(ReportViewController(userID: post.authorID)) }, block: { [weak self] in QRepository.shared.block(userID: post.authorID); self?.navigationController?.popViewController(animated: true) }) }
    private func more() { showMoreSheet(for: userID, report: { [weak self] in guard let self else { return }; self.push(ReportViewController(userID: userID)) }, block: { [weak self] in guard let self else { return }; QRepository.shared.block(userID: userID); self.navigationController?.popViewController(animated: true) }) }
}

final class MediaPreviewViewController: UIViewController {
    private let asset: String
    init(asset: String) { self.asset = asset; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if isVideo(asset), let url = resolvedMediaURL(asset) {
            let player = AVPlayer(url: url)
            let controller = AVPlayerViewController(); controller.player = player; controller.view.backgroundColor = .black
            addChild(controller); view.addSubview(controller.view); controller.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor), controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor), controller.view.topAnchor.constraint(equalTo: view.topAnchor), controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
            controller.didMove(toParent: self); player.play()
        } else {
            let image = UIImageView(image: UIImage.qAsset(asset) ?? UIImage(contentsOfFile: asset) ?? thumbnail(at: asset) ?? placeholder())
            image.contentMode = .scaleAspectFit; image.isUserInteractionEnabled = true
            view.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: view.leadingAnchor), image.trailingAnchor.constraint(equalTo: view.trailingAnchor), image.topAnchor.constraint(equalTo: view.topAnchor), image.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
            image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        }
        let close = UIButton(type: .system); close.setImage(UIImage(systemName: "xmark"), for: .normal); close.tintColor = .white; close.backgroundColor = UIColor.black.withAlphaComponent(0.45); close.layer.cornerRadius = 20; close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close); close.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12), close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), close.widthAnchor.constraint(equalToConstant: 40), close.heightAnchor.constraint(equalToConstant: 40)])
    }
    private func isVideo(_ value: String) -> Bool { ["mov", "mp4", "m4v", "avi"].contains(URL(fileURLWithPath: value).pathExtension.lowercased()) }
    private func thumbnail(at path: String) -> UIImage? { guard isVideo(path), let url = resolvedMediaURL(path) else { return nil }; let asset = AVAsset(url: url); let generator = AVAssetImageGenerator(asset: asset); generator.appliesPreferredTrackTransform = true; return try? UIImage(cgImage: generator.copyCGImage(at: .zero, actualTime: nil)) }
    private func placeholder() -> UIImage { let icon = UIImage.qAsset("default_photo") ?? UIImage(systemName: "photo") ?? UIImage(); return UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400)).image { UIColor(hex: "15171A").setFill(); $0.fill(CGRect(x: 0, y: 0, width: 400, height: 400)); icon.draw(in: CGRect(x: 145, y: 145, width: 110, height: 110)) } }
    @objc private func close() { dismiss(animated: true) }
}

final class AIGuideViewController: RootPageViewController {
    private struct ReplyRule {
        let keywords: [String]
        let response: String
    }

    private let promptField = UITextField()
    private let composer = UIView()
    private var conversation: [(text: String, mine: Bool)] = []
    private var recommendedTask: QDrawTask?

    private let replyRules: [ReplyRule] = [
        ReplyRule(keywords: ["hello", "hi", "help"], response: "I can help you choose a small moment to notice, capture, or share."),
        ReplyRule(keywords: ["what can", "what do", "how does"], response: "Choose a task that fits your time, complete it, and share your proof."),
        ReplyRule(keywords: ["photo", "picture", "photograph"], response: "Try a visual task and focus on one detail that changes the scene."),
        ReplyRule(keywords: ["video", "film", "record"], response: "A short, steady clip works best. Keep the subject and its surroundings in frame."),
        ReplyRule(keywords: ["time", "long", "duration", "minutes", "hours"], response: "Pick a time limit you can finish comfortably; shorter tasks are easier to complete today."),
        ReplyRule(keywords: ["follow", "following"], response: "Following keeps the people and check-ins you care about close to your feed."),
        ReplyRule(keywords: ["publish", "post", "share"], response: "After you finish a task, add your proof and a field note before publishing."),
        ReplyRule(keywords: ["save", "saved", "bookmark"], response: "Save a check-in to revisit it from your Saved tab."),
        ReplyRule(keywords: ["message", "chat", "talk"], response: "You can message someone after you both follow each other."),
        ReplyRule(keywords: ["like", "likes", "heart"], response: "A like is a quick way to let the author know a check-in stood out."),
        ReplyRule(keywords: ["location", "where"], response: "Add a location manually or use the location button when you publish."),
        ReplyRule(keywords: ["profile", "account", "name"], response: "Your profile keeps your identity, stats, check-ins, and saved discoveries together."),
        ReplyRule(keywords: ["coins", "recharge", "balance"], response: "Coins unlock additional Draw tasks when the free draw is unavailable."),
        ReplyRule(keywords: ["report", "block", "safety"], response: "Use the menu on a user or check-in to report or block unwanted activity.")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        scroll.contentInset.bottom = 88
        scroll.verticalScrollIndicatorInsets.bottom = 88
        setupComposer()
        rebuild()
    }

    override func rebuild() {
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        body.addArrangedSubview(aiHeader())
        body.setCustomSpacing(28, after: body.arrangedSubviews.last!)

        conversation.enumerated().forEach { index, message in
            body.addArrangedSubview(chatBubble(message.text, mine: message.mine))
            if index < conversation.count - 1 { body.setCustomSpacing(12, after: body.arrangedSubviews.last!) }
        }

        if let recommendedTask {
            body.setCustomSpacing(11, after: body.arrangedSubviews.last!)
            body.addArrangedSubview(taskCard(recommendedTask))
        }
    }

    private func setupComposer() {
        composer.backgroundColor = QTheme.surface
        composer.layer.cornerRadius = 16
        composer.layer.borderWidth = 1
        composer.layer.borderColor = QTheme.divider.cgColor
        view.addSubview(composer)
        composer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            composer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            composer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            composer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            composer.heightAnchor.constraint(equalToConstant: 60)
        ])

        promptField.attributedPlaceholder = NSAttributedString(string: "Ask about a task or reply", attributes: [.foregroundColor: QTheme.secondaryText])
        promptField.textColor = .white
        promptField.tintColor = QTheme.highlight
        promptField.font = .systemFont(ofSize: 13)
        promptField.borderStyle = .none
        composer.addSubview(promptField)
        promptField.translatesAutoresizingMaskIntoConstraints = false

        let recommend = UIButton(type: .system)
        recommend.setTitle("Recommend", for: .normal)
        recommend.setTitleColor(QTheme.highlight, for: .normal)
        recommend.titleLabel?.font = .systemFont(ofSize: 11, weight: .semibold)
        recommend.addAction(UIAction { [weak self] _ in self?.recommendTask() }, for: .touchUpInside)
        view.addSubview(recommend)
        recommend.translatesAutoresizingMaskIntoConstraints = false

        let send = UIButton(type: .system)
        send.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        send.tintColor = .white
        send.backgroundColor = QTheme.brightPurple
        send.layer.cornerRadius = 22
        send.addAction(UIAction { [weak self] _ in self?.sendPrompt() }, for: .touchUpInside)
        composer.addSubview(send)
        send.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            promptField.leadingAnchor.constraint(equalTo: composer.leadingAnchor, constant: 14),
            promptField.centerYAnchor.constraint(equalTo: composer.centerYAnchor),
            promptField.trailingAnchor.constraint(equalTo: send.leadingAnchor, constant: -10),
            promptField.heightAnchor.constraint(equalToConstant: 28),
            recommend.bottomAnchor.constraint(equalTo: composer.topAnchor, constant: -4),
            recommend.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -2),
            recommend.widthAnchor.constraint(equalToConstant: 82),
            recommend.heightAnchor.constraint(equalToConstant: 24),
            send.trailingAnchor.constraint(equalTo: composer.trailingAnchor, constant: -8),
            send.centerYAnchor.constraint(equalTo: composer.centerYAnchor),
            send.widthAnchor.constraint(equalToConstant: 44),
            send.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func recommendTask() {
        let request = promptField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        submit(request?.isEmpty == false ? request! : "Recommend a task for me.")
        promptField.text = ""
        promptField.resignFirstResponder()
    }

    private func sendPrompt() {
        guard let text = promptField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        submit(text)
        promptField.text = ""
        promptField.resignFirstResponder()
    }

    private func submit(_ text: String) {
        let result = response(for: text)
        conversation.append((text, true))
        conversation.append((result.text, false))
        recommendedTask = result.task
        rebuild()
    }

    private func response(for text: String) -> (text: String, task: QDrawTask?) {
        if let task = taskRecommendation(for: text) {
            let nearby = containsAny(text.lowercased(), words: ["near", "nearby", "around", "close", "tonight", "today"])
            let prefix = nearby ? "Try this nearby idea" : "This task fits what you described"
            return ("\(prefix): \(task.title). \(task.body)", task)
        }

        let lower = text.lowercased()
        if let rule = replyRules.first(where: { rule in rule.keywords.contains(where: { lower.contains($0) }) }) {
            return (rule.response, nil)
        }
        return ("I can help with tasks, check-ins, photos, locations, profiles, and conversations. Tell me what you want to do, and I’ll point you in the right direction.", nil)
    }

    private func taskRecommendation(for text: String) -> QDrawTask? {
        let tasks = QRepository.shared.drawTasks
        guard !tasks.isEmpty else { return nil }
        let lower = text.lowercased()
        let taskIntentWords = ["task", "try", "find", "recommend", "near", "nearby", "around", "close", "street", "walk", "tonight", "today"]
        let taskIntent = containsAny(lower, words: taskIntentWords) || tasks.contains { task in
            lower.contains(task.title.lowercased()) || lower.contains(task.body.lowercased())
        }
        guard taskIntent else { return nil }

        let inputWords = Set(lower.split { !$0.isLetter && !$0.isNumber }.map(String.init).filter { $0.count > 2 })
        var ranked: [(task: QDrawTask, score: Int)] = tasks.map { task in
            let taskWords = "\(task.title) \(task.body)".lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
            var score = inputWords.reduce(0) { total, word in
                total + (taskWords.contains(where: { $0 == word || $0.hasPrefix(word) || word.hasPrefix($0) }) ? 3 : 0)
            }
            if containsAny(lower, words: ["short", "quick", "brief"]) && task.durationHours <= 30 { score += 2 }
            if containsAny(lower, words: ["long", "slow", "spend more time"]) && task.durationHours >= 60 { score += 2 }
            return (task, score)
        }
        ranked.sort { left, right in
            left.score == right.score ? left.task.id < right.task.id : left.score > right.score
        }
        return ranked.first?.task
    }

    private func containsAny(_ text: String, words: [String]) -> Bool {
        words.contains { text.contains($0) }
    }

    private func aiHeader() -> UIView { let v = UIView(); v.heightAnchor.constraint(equalToConstant: 48).isActive = true; let back = UIButton(type: .system); back.setImage(UIImage(systemName: "arrow.left"), for: .normal); back.tintColor = .white; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); v.addSubview(back); back.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: v.leadingAnchor), back.centerYAnchor.constraint(equalTo: v.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 32), back.heightAnchor.constraint(equalToConstant: 40)]); let title = label("AI Guide", size: 20, weight: .semibold); let subtitle = label("Your city companion", size: 12, color: QTheme.secondaryText); let info = stack(2); info.addArrangedSubview(title); info.addArrangedSubview(subtitle); v.addSubview(info); info.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([info.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 10), info.centerYAnchor.constraint(equalTo: v.centerYAnchor)]); return v }

    private func taskCard(_ task: QDrawTask) -> UIView {
        let card = UIView()
        card.backgroundColor = QTheme.surface
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = QTheme.divider.cgColor
        card.heightAnchor.constraint(equalToConstant: 159).isActive = true

        let image = UIImageView(image: safeImage([task.mediaAsset, "default_photo"]))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 10
        card.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 11), image.topAnchor.constraint(equalTo: card.topAnchor, constant: 11), image.widthAnchor.constraint(equalToConstant: 88), image.heightAnchor.constraint(equalToConstant: 82)])

        let title = label(task.title, size: 16, weight: .semibold)
        title.numberOfLines = 2
        let duration = label("\(task.durationHours) h\n\nLow effort", size: 11, color: QTheme.secondaryText)
        let info = stack(8)
        info.addArrangedSubview(title)
        info.addArrangedSubview(duration)
        card.addSubview(info)
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([info.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 12), info.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10), info.topAnchor.constraint(equalTo: card.topAnchor, constant: 17)])

        let use = button("Use this task", height: 44, filled: false)
        use.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        use.layer.borderColor = QTheme.highlight.cgColor
        use.addAction(UIAction { [weak self] _ in self?.useTask(task) }, for: .touchUpInside)
        card.addSubview(use)
        use.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([use.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 11), use.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -11), use.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)])
        return card
    }

    private func useTask(_ task: QDrawTask) {
        if let tabs = tabBarController as? MainTabBarController { tabs.presentPublish(for: task) }
        else { push(PublishViewController(task: task)) }
    }

    private func chatBubble(_ text: String, mine: Bool) -> UIView {
        let row = UIView()
        let bubble = UIView()
        bubble.backgroundColor = mine ? UIColor(hex: "3B2A59") : QTheme.surface
        bubble.layer.cornerRadius = 16
        bubble.clipsToBounds = true
        row.addSubview(bubble)
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let message = label(text, size: 14)
        message.numberOfLines = 0
        bubble.addSubview(message)
        message.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([message.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14), message.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14), message.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10), message.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10)])

        if mine {
            NSLayoutConstraint.activate([bubble.trailingAnchor.constraint(equalTo: row.trailingAnchor), bubble.leadingAnchor.constraint(greaterThanOrEqualTo: row.leadingAnchor, constant: 58), bubble.topAnchor.constraint(equalTo: row.topAnchor), bubble.bottomAnchor.constraint(equalTo: row.bottomAnchor)])
        } else {
            let assistant = UIImageView(image: UIImage.qAsset("mask") ?? UIImage(systemName: "person.crop.circle.fill"))
            assistant.contentMode = .scaleAspectFill
            assistant.clipsToBounds = true
            assistant.layer.cornerRadius = 18
            assistant.layer.borderWidth = 1
            assistant.layer.borderColor = QTheme.highlight.withAlphaComponent(0.65).cgColor
            row.addSubview(assistant)
            assistant.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([assistant.leadingAnchor.constraint(equalTo: row.leadingAnchor), assistant.topAnchor.constraint(equalTo: row.topAnchor, constant: 9), assistant.widthAnchor.constraint(equalToConstant: 36), assistant.heightAnchor.constraint(equalToConstant: 36), bubble.leadingAnchor.constraint(equalTo: assistant.trailingAnchor, constant: 8), bubble.trailingAnchor.constraint(equalTo: row.trailingAnchor), bubble.topAnchor.constraint(equalTo: row.topAnchor), bubble.bottomAnchor.constraint(equalTo: row.bottomAnchor)])
        }
        return row
    }
}

private final class RechargeViewControllerLegacy: RootPageViewController {
    private var selected = 3
    override func viewDidLoad() { super.viewDidLoad(); QStoreKitManager.shared.onProductsChanged = { [weak self] in self?.rebuild() }; QStoreKitManager.shared.onPurchase = { [weak self] _, success in guard let self else { return }; rebuild(); showMessage(success ? "Purchase complete" : "Purchase failed", success ? "Your balance has been updated." : "Please try again.") }; QStoreKitManager.shared.loadProducts(); rebuild() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Recharge")); body.addArrangedSubview(label("💎  \(QRepository.shared.walletCoins)", size: 32, weight: .bold, color: QTheme.highlight)); body.addArrangedSubview(label("Qrovo BALANCE", size: 13, color: QTheme.highlight)); body.addArrangedSubview(label("Pick an amount", size: 23, weight: .bold)); let products = QStoreKitManager.shared.catalogProducts(); if products.isEmpty { body.addArrangedSubview(emptyState("Recharge options unavailable", detail: "Try again later.")); let retry = button("Try again", height: 44, filled: false); retry.addAction(UIAction { _ in QStoreKitManager.shared.loadProducts() }, for: .touchUpInside); body.addArrangedSubview(retry) } else { selected = min(selected, products.count - 1); products.enumerated().forEach { index, product in let b = productRow(product, selected: index == selected); b.addAction(UIAction { [weak self] _ in self?.selected = index; self?.rebuild() }, for: .touchUpInside); body.addArrangedSubview(b) }; let spacer = UIView(); spacer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true; body.addArrangedSubview(spacer); let continueButton = button("Continue   ›", height: 52); continueButton.addAction(UIAction { [weak self] _ in self?.purchase() }, for: .touchUpInside); body.addArrangedSubview(continueButton) } }
    private func productRow(_ product: QProduct, selected: Bool) -> UIButton { let b = UIButton(type: .system); b.backgroundColor = selected ? UIColor(hex: "302060") : QTheme.surface; b.layer.cornerRadius = 0; b.layer.borderWidth = 1; b.layer.borderColor = QTheme.divider.cgColor; b.setTitle("   \(product.index)       \(product.reward)                         \(product.price)   ◯", for: .normal); b.setTitleColor(.white, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium); b.contentHorizontalAlignment = .left; b.heightAnchor.constraint(equalToConstant: 85).isActive = true; return b }
    private func purchase() { let products = QStoreKitManager.shared.catalogProducts(); guard products.indices.contains(selected) else { return }; let product = products[selected]; let alert = UIAlertController(title: "Confirm purchase", message: "Receive \(product.reward) coins for \(product.price).", preferredStyle: .alert); alert.addAction(UIAlertAction(title: "Cancel", style: .cancel)); alert.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in if let storeProduct = QStoreKitManager.shared.products.first(where: { $0.productIdentifier == product.id }) { QStoreKitManager.shared.buy(product: storeProduct) } else { QRepository.shared.addCoins(product.reward); self.showMessage("Purchase complete", "Your balance has been updated.") } }); present(alert, animated: true) }
}

final class EditProfileViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let name = UITextField()
    private let bio = UITextView()
    private let avatarView = UIImageView()
    private var selectedAvatar: UIImage?
    override func viewDidLoad() {
        super.viewDidLoad()
        formStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let user = QRepository.shared.currentUser
        formStack.addArrangedSubview(editHeader())
        formStack.setCustomSpacing(12, after: formStack.arrangedSubviews.last!)

        avatarView.image = user.map { QRepository.shared.avatar(for: $0.id, size: 120) }
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 14
        avatarView.clipsToBounds = true
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        avatarView.widthAnchor.constraint(equalToConstant: 114).isActive = true
        avatarView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        name.text = user?.name
        name.textColor = .white
        name.font = .systemFont(ofSize: 15)
        name.backgroundColor = QTheme.surface
        name.layer.cornerRadius = 10
        name.layer.borderWidth = 1
        name.layer.borderColor = QTheme.divider.cgColor
        name.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        name.leftViewMode = .always
        name.heightAnchor.constraint(equalToConstant: 42).isActive = true

        let nameCaption = label("Name", size: 14, color: QTheme.secondaryText)
        let helper = label("This is how people will find you.", size: 12, color: QTheme.secondaryText)
        let nameColumn = stack(6)
        nameColumn.addArrangedSubview(nameCaption)
        nameColumn.addArrangedSubview(name)
        nameColumn.addArrangedSubview(helper)
        let profileRow = UIView()
        profileRow.heightAnchor.constraint(equalToConstant: 127).isActive = true
        profileRow.addSubview(avatarView)
        profileRow.addSubview(nameColumn)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        nameColumn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: profileRow.leadingAnchor),
            avatarView.topAnchor.constraint(equalTo: profileRow.topAnchor),
            nameColumn.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 17),
            nameColumn.trailingAnchor.constraint(equalTo: profileRow.trailingAnchor),
            nameColumn.topAnchor.constraint(equalTo: profileRow.topAnchor, constant: 17),
            nameColumn.bottomAnchor.constraint(lessThanOrEqualTo: profileRow.bottomAnchor, constant: -4)
        ])
        let separator = UIView()
        separator.backgroundColor = QTheme.secondaryText
        profileRow.addSubview(separator)
        separator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: profileRow.leadingAnchor, constant: 72),
            separator.trailingAnchor.constraint(equalTo: profileRow.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: profileRow.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])
        formStack.addArrangedSubview(profileRow)
        formStack.setCustomSpacing(6, after: profileRow)

        bio.text = user?.bio.isEmpty == false ? user?.bio : "Tell the community a little about yourself..."
        bio.textColor = QTheme.text
        bio.font = .systemFont(ofSize: 15)
        bio.backgroundColor = QTheme.surface
        bio.layer.cornerRadius = 10
        bio.layer.borderWidth = 1
        bio.layer.borderColor = QTheme.divider.cgColor
        bio.textContainerInset = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        bio.heightAnchor.constraint(equalToConstant: 113).isActive = true
        formStack.addArrangedSubview(label("Bio", size: 14, color: QTheme.secondaryText))
        formStack.setCustomSpacing(6, after: formStack.arrangedSubviews.last!)
        formStack.addArrangedSubview(bio)
        addBottomButton("Confirm profile") { [weak self] in self?.save() }
    }
    private func editHeader() -> UIView { let v = UIView(); v.heightAnchor.constraint(equalToConstant: 40).isActive = true; let back = UIButton(type: .system); back.setImage(UIImage(systemName: "arrow.left"), for: .normal); back.tintColor = .white; back.contentHorizontalAlignment = .left; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); let title = label("Edit Profile", size: 20, weight: .semibold); [back, title].forEach { v.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }; NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: v.leadingAnchor), back.centerYAnchor.constraint(equalTo: v.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 32), back.heightAnchor.constraint(equalToConstant: 40), title.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 10), title.centerYAnchor.constraint(equalTo: v.centerYAnchor)]); return v }
    @objc private func avatarTapped() { chooseAvatar() }
    private func chooseAvatar() { let sheet = QPublishMediaSheet(isVideo: false) { [weak self] source in self?.presentAvatarPicker(source: source) }; sheet.modalPresentationStyle = .overFullScreen; present(sheet, animated: true) }
    private func presentAvatarPicker(source: UIImagePickerController.SourceType) { guard UIImagePickerController.isSourceTypeAvailable(source) else { showMessage("Unavailable", "This media source is not available on this device."); return }; let picker = UIImagePickerController(); picker.sourceType = source; picker.mediaTypes = ["public.image"]; picker.delegate = self; present(picker, animated: true) }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) { if let image = info[.originalImage] as? UIImage { selectedAvatar = image; avatarView.image = image }; picker.dismiss(animated: true) }
    private func save() { let value = name.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; guard !value.isEmpty else { showMessage("Name required", "Add your name to continue."); return }; QRepository.shared.updateCurrentUser(name: value, bio: bio.text); if let selectedAvatar { _ = QRepository.shared.saveCurrentAvatar(selectedAvatar) }; navigationController?.popViewController(animated: true) }
}

final class SettingsViewController: QViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let header = settingsHeader()
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8), header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26), header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26), header.heightAnchor.constraint(equalToConstant: 40)])

        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 0
        view.addSubview(rows)
        rows.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([rows.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12), rows.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26), rows.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26)])
        let timeline = UIView()
        timeline.backgroundColor = QTheme.secondaryText
        view.insertSubview(timeline, belowSubview: rows)
        timeline.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([timeline.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40), timeline.topAnchor.constraint(equalTo: rows.topAnchor, constant: 39), timeline.bottomAnchor.constraint(equalTo: rows.bottomAnchor, constant: -39), timeline.widthAnchor.constraint(equalToConstant: 1)])
        rows.addArrangedSubview(settingRow("me5", fallback: "nosign", "Block List", BlockedUsersViewController()))
        rows.addArrangedSubview(settingRow("me2", fallback: "checkmark.shield", "Privacy Policy", PolicyViewController(title: "Privacy Policy", urlString: "https://sites.google.com/view/qrovo/privacy")))
        rows.addArrangedSubview(settingRow("me3", fallback: "doc.text", "Terms of Service", PolicyViewController(title: "Terms of Service", urlString: "https://sites.google.com/view/qrovo/users")))

        let account = label("ACCOUNT", size: 12, weight: .semibold, color: QTheme.mutedText)
        account.layer.opacity = 0.95
        view.addSubview(account)
        account.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([account.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26), account.topAnchor.constraint(equalTo: rows.bottomAnchor, constant: 21)])
        let logout = button("  Log Out", height: 52, filled: false)
        logout.setImage(UIImage.qAsset("me1")?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logout.tintColor = .white
        logout.imageView?.contentMode = .scaleAspectFit
        logout.layer.cornerRadius = 12
        logout.addAction(UIAction { [weak self] _ in self?.confirmLogout() }, for: .touchUpInside)
        view.addSubview(logout)
        logout.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([logout.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26), logout.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26), logout.topAnchor.constraint(equalTo: account.bottomAnchor, constant: 10)])
        let delete = UIButton(type: .system)
        delete.setImage(UIImage(systemName: "trash"), for: .normal)
        delete.setTitle("  Delete Account", for: .normal)
        delete.tintColor = QTheme.danger
        delete.setTitleColor(QTheme.danger, for: .normal)
        delete.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        delete.addAction(UIAction { [weak self] _ in self?.confirmDelete() }, for: .touchUpInside)
        view.addSubview(delete)
        delete.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([delete.centerXAnchor.constraint(equalTo: view.centerXAnchor), delete.topAnchor.constraint(equalTo: logout.bottomAnchor, constant: 16), delete.heightAnchor.constraint(equalToConstant: 40)])
    }
    private func settingsHeader() -> UIView { let v = UIView(); let back = UIButton(type: .system); back.setImage(UIImage(systemName: "arrow.left"), for: .normal); back.tintColor = .white; back.contentHorizontalAlignment = .left; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); let title = label("Settings", size: 20, weight: .semibold); [back, title].forEach { v.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }; NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: v.leadingAnchor), back.centerYAnchor.constraint(equalTo: v.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 32), back.heightAnchor.constraint(equalToConstant: 40), title.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 10), title.centerYAnchor.constraint(equalTo: v.centerYAnchor)]); return v }
    private func settingRow(_ asset: String, fallback: String, _ title: String, _ destination: UIViewController) -> UIView {
        let row = UIButton(type: .system)
        row.heightAnchor.constraint(equalToConstant: 79).isActive = true
        row.addAction(UIAction { [weak self] _ in destination.hidesBottomBarWhenPushed = true; self?.navigationController?.pushViewController(destination, animated: true) }, for: .touchUpInside)
        let node = UIView(); node.layer.borderWidth = 1; node.layer.borderColor = QTheme.secondaryText.cgColor; node.layer.cornerRadius = 6; node.backgroundColor = QTheme.background
        let inner = UIView(); inner.layer.borderWidth = 1; inner.layer.borderColor = QTheme.secondaryText.cgColor; inner.layer.cornerRadius = 2; node.addSubview(inner); inner.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([inner.centerXAnchor.constraint(equalTo: node.centerXAnchor), inner.centerYAnchor.constraint(equalTo: node.centerYAnchor), inner.widthAnchor.constraint(equalToConstant: 7), inner.heightAnchor.constraint(equalToConstant: 7)])
        let icon = UIImageView(image: UIImage.qAsset(asset)?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: fallback)); icon.contentMode = .scaleAspectFit; icon.tintColor = .white
        let text = label(title, size: 16, weight: .semibold); let chevron = UIImageView(image: UIImage(systemName: "chevron.right")); chevron.tintColor = .white; chevron.contentMode = .scaleAspectFit
        [node, icon, text, chevron].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([node.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 4), node.centerYAnchor.constraint(equalTo: row.centerYAnchor), node.widthAnchor.constraint(equalToConstant: 20), node.heightAnchor.constraint(equalToConstant: 20), icon.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 52), icon.centerYAnchor.constraint(equalTo: row.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 24), icon.heightAnchor.constraint(equalToConstant: 24), text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 19), text.centerYAnchor.constraint(equalTo: row.centerYAnchor), chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -3), chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor), chevron.widthAnchor.constraint(equalToConstant: 12), chevron.heightAnchor.constraint(equalToConstant: 18)])
        return row
    }
    private func confirmLogout() { showConfirm("Sign Out", "Are you sure you want to sign out?", confirm: "Sure") { QRepository.shared.signOut(); AppCoordinator.shared.showAuth() } }
    private func confirmDelete() { showConfirm("Delete Account", "Are you sure you want to delete this account? All data will be cleared after deletion and cannot be recovered.", confirm: "Delete") { QRepository.shared.deleteAccount(); AppCoordinator.shared.showAuth() } }
}

private final class ReportViewControllerLegacy: RootPageViewController {
    let userID: String; private var selected = -1
    let reasons = ["Spam or scam", "Harassment or bullying", "Hate speech", "Nudity or sexual content", "Dangerous activity", "False water or safety information", "Other"]
    init(userID: String) { self.userID = userID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Report")); body.addArrangedSubview(label("Why are you reporting this?", size: 20, weight: .bold)); body.addArrangedSubview(label("Your report helps keep the community safe.", size: 13, color: QTheme.secondaryText)); reasons.enumerated().forEach { index, reason in let b = button("\(selected == index ? "◉" : "○")   \(reason)", height: 46, filled: false); b.contentHorizontalAlignment = .left; b.addAction(UIAction { [weak self] _ in self?.selected = index; self?.rebuild() }, for: .touchUpInside); body.addArrangedSubview(b) }; let submit = button("Confirm report", height: 52); submit.isEnabled = selected >= 0; submit.alpha = selected >= 0 ? 1 : 0.45; submit.addAction(UIAction { [weak self] _ in guard let self, selected >= 0 else { return }; QRepository.shared.report(userID: userID, reason: reasons[selected]); showMessage("Report submitted", "Thanks for helping keep the community safe.") { self.navigationController?.popViewController(animated: true) } }, for: .touchUpInside); body.addArrangedSubview(submit) }
}

private final class BlockedUsersViewControllerLegacy: RootPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Blocked Users")); let ids = Array(QRepository.shared.blockedUserIDs); if ids.isEmpty { body.addArrangedSubview(emptyState("No blocked users", detail: "Users you block will appear here.")) } else { ids.forEach { id in let user = QRepository.shared.user(id); let b = button("\(user?.name ?? "User")                                      Unblock", height: 58, filled: false); b.contentHorizontalAlignment = .left; b.addAction(UIAction { _ in QRepository.shared.unblock(userID: id) }, for: .touchUpInside); body.addArrangedSubview(b) } } }
}

final class RechargeViewController: RootPageViewController {
    private var selected = 3
    private var loading = false
    private var loader: UIActivityIndicatorView!
    private var continueButton: UIButton!
    override func viewDidLoad() { super.viewDidLoad(); loader = UIActivityIndicatorView(style: .medium); loader.color = .white; view.addSubview(loader); loader.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([loader.centerXAnchor.constraint(equalTo: view.centerXAnchor), loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)]); continueButton = button("Recharge", height: 52); continueButton.addAction(UIAction { [weak self] _ in self?.purchase(products: QStoreKitManager.shared.catalogProducts()) }, for: .touchUpInside); view.addSubview(continueButton); continueButton.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)]); QStoreKitManager.shared.onProductsChanged = { [weak self] in self?.loading = false; self?.updateLoading(); self?.rebuild() }; QStoreKitManager.shared.onPurchase = { [weak self] _, success in self?.loading = false; self?.updateLoading(); self?.rebuild(); self?.showMessage(success ? "Purchase complete" : "Purchase failed", success ? "Your balance has been updated." : "Please try again.") }; loading = true; QStoreKitManager.shared.loadProducts(); rebuild(); updateLoading() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Recharge")); body.setCustomSpacing(18, after: body.arrangedSubviews.last!); let balance = UIStackView(); balance.axis = .horizontal; balance.alignment = .center; let gem = UIImageView(image: UIImage.qAsset("21f21 1")); gem.contentMode = .scaleAspectFit; gem.widthAnchor.constraint(equalToConstant: 58).isActive = true; gem.heightAnchor.constraint(equalToConstant: 58).isActive = true; let amount = stack(1); amount.addArrangedSubview(label(QRepository.shared.walletCoins.formatted(), size: 32, weight: .bold, color: QTheme.highlight)); amount.addArrangedSubview(label("Qrovo BALANCE", size: 13, color: QTheme.highlight)); balance.addArrangedSubview(gem); balance.addArrangedSubview(amount); balance.spacing = 10; body.addArrangedSubview(balance); body.setCustomSpacing(18, after: balance); body.addArrangedSubview(label("Pick an amount", size: 23, weight: .bold)); body.setCustomSpacing(18, after: body.arrangedSubviews.last!); let products = QStoreKitManager.shared.catalogProducts(); if products.isEmpty { body.addArrangedSubview(emptyState("Recharge options unavailable", detail: "Try again later.")); let retry = button("Try again", height: 44, filled: false); retry.addAction(UIAction { [weak self] _ in self?.loading = true; self?.updateLoading(); QStoreKitManager.shared.loadProducts() }, for: .touchUpInside); body.addArrangedSubview(retry) } else { selected = min(selected, products.count - 1); let list = UIStackView(); list.axis = .vertical; list.spacing = 0; list.backgroundColor = QTheme.surface; list.layer.cornerRadius = 16; list.clipsToBounds = true; products.enumerated().forEach { index, product in let row = productRow(product, selected: index == selected); row.addAction(UIAction { [weak self] _ in self?.selected = index; self?.rebuild() }, for: .touchUpInside); list.addArrangedSubview(row) }; body.addArrangedSubview(list); let spacer = UIView(); spacer.heightAnchor.constraint(equalToConstant: 110).isActive = true; body.addArrangedSubview(spacer) } }
    private func productRow(_ product: QProduct, selected: Bool) -> UIButton { let row = UIButton(type: .system); row.backgroundColor = QTheme.surface; row.clipsToBounds = true; row.heightAnchor.constraint(equalToConstant: 85).isActive = true; row.layer.borderWidth = 1; row.layer.borderColor = QTheme.divider.cgColor; if selected { let fill = QGradientView(colors: [UIColor(hex: "7C3AED").withAlphaComponent(0.34), UIColor(hex: "7C3AED").withAlphaComponent(0.11)]); row.addSubview(fill); fill.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([fill.leadingAnchor.constraint(equalTo: row.leadingAnchor), fill.trailingAnchor.constraint(equalTo: row.trailingAnchor), fill.topAnchor.constraint(equalTo: row.topAnchor), fill.bottomAnchor.constraint(equalTo: row.bottomAnchor)]); let numberFill = QGradientView(colors: [UIColor(hex: "5B21B6"), UIColor(hex: "7C3AED")]); row.addSubview(numberFill); numberFill.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([numberFill.leadingAnchor.constraint(equalTo: row.leadingAnchor), numberFill.topAnchor.constraint(equalTo: row.topAnchor), numberFill.bottomAnchor.constraint(equalTo: row.bottomAnchor), numberFill.widthAnchor.constraint(equalToConstant: 62)]) }; let number = label(product.index, size: 16, color: selected ? .white : QTheme.secondaryText); let reward = label("\(product.reward)", size: 26, weight: .medium); let price = label(product.price, size: 16, weight: .medium); let radio = UIView(); radio.layer.borderWidth = 1.5; radio.layer.borderColor = selected ? UIColor.white.cgColor : QTheme.secondaryText.cgColor; radio.layer.cornerRadius = 12; if selected { let dot = UIView(); dot.backgroundColor = QTheme.highlight; dot.layer.cornerRadius = 6; radio.addSubview(dot); dot.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([dot.centerXAnchor.constraint(equalTo: radio.centerXAnchor), dot.centerYAnchor.constraint(equalTo: radio.centerYAnchor), dot.widthAnchor.constraint(equalToConstant: 12), dot.heightAnchor.constraint(equalToConstant: 12)]) }; [number, reward, price, radio].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }; NSLayoutConstraint.activate([number.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 25), number.centerYAnchor.constraint(equalTo: row.centerYAnchor), reward.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 87), reward.centerYAnchor.constraint(equalTo: row.centerYAnchor), price.trailingAnchor.constraint(equalTo: radio.leadingAnchor, constant: -9), price.centerYAnchor.constraint(equalTo: row.centerYAnchor), radio.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10), radio.centerYAnchor.constraint(equalTo: row.centerYAnchor), radio.widthAnchor.constraint(equalToConstant: 24), radio.heightAnchor.constraint(equalToConstant: 24)]); return row }
    private func purchase(products: [QProduct]) { guard products.indices.contains(selected) else { return }; let product = products[selected]; guard let storeProduct = QStoreKitManager.shared.products.first(where: { $0.productIdentifier == product.id }) else { showMessage("Unavailable", "This purchase is not available right now."); return }; loading = true; updateLoading(); QStoreKitManager.shared.buy(product: storeProduct) }
    private func updateLoading() { guard let loader else { return }; loading ? loader.startAnimating() : loader.stopAnimating(); let hasProducts = !QStoreKitManager.shared.catalogProducts().isEmpty; continueButton.isEnabled = !loading && hasProducts && SKPaymentQueue.canMakePayments(); continueButton.alpha = continueButton.isEnabled ? 1 : 0.45 }
}

final class ReportViewController: RootPageViewController {
    let userID: String
    private var selected = 4
    private var submitButton: UIButton!
    private let reasons = ["Spam or scam", "Harassment or bullying", "Hate speech", "Nudity or sexual content", "Dangerous activity", "False water or safety information", "Other"]
    init(userID: String) { self.userID = userID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func viewDidLoad() { super.viewDidLoad(); rebuild(); submitButton = button("Confirm report", height: 52); submitButton.addAction(UIAction { [weak self] _ in self?.submitReport() }, for: .touchUpInside); view.addSubview(submitButton); submitButton.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)]); updateSubmitButton() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Report")); body.setCustomSpacing(10, after: body.arrangedSubviews.last!); body.addArrangedSubview(label("What happened?", size: 16, color: QTheme.secondaryText)); body.setCustomSpacing(25, after: body.arrangedSubviews.last!); let list = UIView(); list.heightAnchor.constraint(equalToConstant: 420).isActive = true; let line = UIView(); line.isHidden = true; line.backgroundColor = QTheme.secondaryText.withAlphaComponent(0.65); list.addSubview(line); line.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([line.leadingAnchor.constraint(equalTo: list.leadingAnchor, constant: 14), line.topAnchor.constraint(equalTo: list.topAnchor, constant: 18), line.bottomAnchor.constraint(equalTo: list.bottomAnchor, constant: -18), line.widthAnchor.constraint(equalToConstant: 1)]); reasons.enumerated().forEach { index, reason in let row = reportRow(reason, index: index); list.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: list.leadingAnchor), row.trailingAnchor.constraint(equalTo: list.trailingAnchor), row.topAnchor.constraint(equalTo: list.topAnchor, constant: CGFloat(index) * 66), row.heightAnchor.constraint(equalToConstant: 66)]) }; body.addArrangedSubview(list); updateSubmitButton() }
    private func reportRow(_ reason: String, index: Int) -> UIView { let row = UIView(); let radio = UIView(); radio.layer.borderWidth = 1.5; radio.layer.borderColor = selected == index ? QTheme.brightPurple.cgColor : QTheme.secondaryText.cgColor; radio.layer.cornerRadius = 11; row.addSubview(radio); radio.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([radio.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -4), radio.centerYAnchor.constraint(equalTo: row.centerYAnchor), radio.widthAnchor.constraint(equalToConstant: 22), radio.heightAnchor.constraint(equalToConstant: 22)]); if selected == index { let dot = UIView(); dot.backgroundColor = QTheme.brightPurple; dot.layer.cornerRadius = 5; radio.addSubview(dot); dot.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([dot.centerXAnchor.constraint(equalTo: radio.centerXAnchor), dot.centerYAnchor.constraint(equalTo: radio.centerYAnchor), dot.widthAnchor.constraint(equalToConstant: 10), dot.heightAnchor.constraint(equalToConstant: 10)]) }; let text = label(reason, size: 15); row.addSubview(text); text.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([text.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 40), text.centerYAnchor.constraint(equalTo: row.centerYAnchor), text.trailingAnchor.constraint(equalTo: radio.leadingAnchor, constant: -12)]); let tap = UIButton(type: .system); tap.addAction(UIAction { [weak self] _ in self?.selected = index; self?.rebuild() }, for: .touchUpInside); row.addSubview(tap); tap.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([tap.leadingAnchor.constraint(equalTo: row.leadingAnchor), tap.trailingAnchor.constraint(equalTo: row.trailingAnchor), tap.topAnchor.constraint(equalTo: row.topAnchor), tap.bottomAnchor.constraint(equalTo: row.bottomAnchor)]); return row }
    private func updateSubmitButton() { guard let submitButton else { return }; submitButton.isEnabled = selected >= 0; submitButton.alpha = selected >= 0 ? 1 : 0.45 }
    private func submitReport() { guard selected >= 0 else { return }; QRepository.shared.report(userID: userID, reason: reasons[selected]); showMessage("Report submitted", "Thanks for helping keep the community safe.") { self.navigationController?.popViewController(animated: true) } }
}

final class BlockedUsersViewController: RootPageViewController {
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; body.addArrangedSubview(navHeader("Blocked Users")); body.setCustomSpacing(18, after: body.arrangedSubviews.last!); let ids = Array(QRepository.shared.blockedUserIDs); if ids.isEmpty { body.addArrangedSubview(emptyState("No blocked users", detail: "Users you block will appear here.")) } else { ids.forEach { body.addArrangedSubview(blockedUserRow($0)) } } }
    private func blockedUserRow(_ id: String) -> UIView { let row = UIView(); row.heightAnchor.constraint(equalToConstant: 64).isActive = true; let avatarView = avatar(id, size: 54); row.addSubview(avatarView); avatarView.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([avatarView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 4), avatarView.centerYAnchor.constraint(equalTo: row.centerYAnchor), avatarView.widthAnchor.constraint(equalToConstant: 54), avatarView.heightAnchor.constraint(equalToConstant: 54)]); let name = label(QRepository.shared.user(id)?.name ?? "User", size: 18, weight: .semibold); row.addSubview(name); name.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([name.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16), name.centerYAnchor.constraint(equalTo: row.centerYAnchor)]); let unblock = button("Unblock", height: 38, filled: false); unblock.widthAnchor.constraint(equalToConstant: 84).isActive = true; unblock.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium); unblock.layer.cornerRadius = 19; unblock.layer.borderColor = UIColor.white.cgColor; row.addSubview(unblock); unblock.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([unblock.trailingAnchor.constraint(equalTo: row.trailingAnchor), unblock.centerYAnchor.constraint(equalTo: row.centerYAnchor)]); unblock.addAction(UIAction { [weak self] _ in QRepository.shared.unblock(userID: id); self?.rebuild() }, for: .touchUpInside); return row }
}

class RelationshipViewController: RootPageViewController {
    let following: Bool
    init(following: Bool) { self.following = following; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError() }
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() {
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let header = navHeader(following ? "Following" : "Followers")
        body.addArrangedSubview(header)
        body.setCustomSpacing(10, after: header)
        let users = following ? QRepository.shared.followingUsers.map(\.id) : QRepository.shared.followerUsers.map(\.id)
        users.forEach { id in
            let row = UIView()
            let av = avatar(id, size: 54)
            let name = label(QRepository.shared.user(id)?.name ?? "User", size: 18, weight: .semibold)
            let follow = button(QRepository.shared.followedUserIDs.contains(id) ? "Following" : "Follow", height: 36, filled: !QRepository.shared.followedUserIDs.contains(id))
            follow.layer.cornerRadius = 18; follow.layer.borderColor = UIColor.white.cgColor
            follow.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            follow.widthAnchor.constraint(equalToConstant: 84).isActive = true
            follow.addAction(UIAction { [weak self] _ in QRepository.shared.toggleFollow(userID: id); self?.rebuild() }, for: .touchUpInside)
            [av, name, follow].forEach { row.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([row.heightAnchor.constraint(equalToConstant: 76), av.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 3), av.centerYAnchor.constraint(equalTo: row.centerYAnchor), name.leadingAnchor.constraint(equalTo: av.trailingAnchor, constant: 16), name.centerYAnchor.constraint(equalTo: row.centerYAnchor), follow.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -2), follow.centerYAnchor.constraint(equalTo: row.centerYAnchor)])
            let tap = UITapGestureRecognizer(target: self, action: #selector(openUser(_:))); row.addGestureRecognizer(tap); row.accessibilityIdentifier = id
            body.addArrangedSubview(row)
        }
    }
    @objc private func openUser(_ gesture: UITapGestureRecognizer) { guard let id = gesture.view?.accessibilityIdentifier else { return }; push(OtherProfileViewController(userID: id)) }
}
final class FollowersViewController: RelationshipViewController { init() { super.init(following: false) }; required init?(coder: NSCoder) { super.init(coder: coder) } }
final class FollowingViewController: RelationshipViewController { init() { super.init(following: true) }; required init?(coder: NSCoder) { super.init(coder: coder) } }

extension RootPageViewController {
    func emptyState(_ title: String, detail: String = "") -> UIView { let v = UIStackView(); v.axis = .vertical; v.alignment = .center; v.spacing = 8; v.addArrangedSubview(label("◌", size: 34, color: QTheme.mutedText)); v.addArrangedSubview(label(title, size: 17, weight: .semibold)); if !detail.isEmpty { v.addArrangedSubview(label(detail, size: 13, color: QTheme.secondaryText)) }; v.heightAnchor.constraint(equalToConstant: 180).isActive = true; return v }
}
