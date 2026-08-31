import UIKit
import AVFoundation
import CoreLocation
import PhotosUI

func resolvedMediaURL(_ path: String) -> URL? {
    if path.hasPrefix("/"), FileManager.default.fileExists(atPath: path) { return URL(fileURLWithPath: path) }
    if let url = Bundle.main.url(forResource: path, withExtension: nil) { return url }
    let filePath = path as NSString
    let name = filePath.deletingPathExtension
    let ext = filePath.pathExtension
    return Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? nil : ext, subdirectory: "file")
}

class RootPageViewController: QViewController {
    let scroll = UIScrollView(); let content = UIView(); let body = UIStackView()
    var titleText: String = ""
    override func viewDidLoad() { super.viewDidLoad(); scroll.alwaysBounceVertical = true; view.addSubview(scroll); scroll.translatesAutoresizingMaskIntoConstraints = false; content.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(content); NSLayoutConstraint.activate([scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor), scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor), content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 16), content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -16), content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor), content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -32)]); body.axis = .vertical; body.spacing = 16; content.addSubview(body); body.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([body.topAnchor.constraint(equalTo: content.topAnchor, constant: 10), body.leadingAnchor.constraint(equalTo: content.leadingAnchor), body.trailingAnchor.constraint(equalTo: content.trailingAnchor), body.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24)]); NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: QRepository.didChange, object: nil) }
    @objc func refreshData() { if isViewLoaded { rebuild() } }
    func rebuild() {}
    func heading(_ text: String) { let h = label(text, size: 27, weight: .bold); h.heightAnchor.constraint(equalToConstant: 36).isActive = true; body.addArrangedSubview(h) }
    func segmented(_ titles: [String], selected: Int, action: @escaping (Int) -> Void) -> UISegmentedControl { let s = UISegmentedControl(items: titles); s.selectedSegmentIndex = selected; s.selectedSegmentTintColor = QTheme.purple; s.backgroundColor = QTheme.surface; s.setTitleTextAttributes([.foregroundColor: QTheme.secondaryText, .font: UIFont.systemFont(ofSize: 14)], for: .normal); s.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected); s.heightAnchor.constraint(equalToConstant: 48).isActive = true; s.addAction(UIAction { controlAction in guard let control = controlAction.sender as? UISegmentedControl else { return }; action(control.selectedSegmentIndex) }, for: .valueChanged); return s }
    func placeholderImage() -> UIImage { let icon = UIImage.qAsset("default_photo") ?? UIImage(systemName: "photo") ?? UIImage(); return UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400)).image { context in UIColor(hex: "15171A").setFill(); context.fill(CGRect(x: 0, y: 0, width: 400, height: 400)); icon.draw(in: CGRect(x: 145, y: 145, width: 110, height: 110)) } }
    func safeImage(_ assets: [String], index: Int = 0) -> UIImage {
        guard let item = assets.dropFirst(index).first else { return placeholderImage() }
        if item != "default_photo", let image = UIImage.qAsset(item) { return image }
        if let image = UIImage(contentsOfFile: item) { return image }
        if isVideoAsset(item), let image = videoThumbnail(at: item) { return image }
        return placeholderImage()
    }
    func isVideoAsset(_ asset: String) -> Bool { ["mov", "mp4", "m4v", "avi"].contains(URL(fileURLWithPath: asset).pathExtension.lowercased()) }
    func videoThumbnail(at path: String) -> UIImage? { guard isVideoAsset(path), let url = resolvedMediaURL(path) else { return nil }; let asset = AVAsset(url: url); let generator = AVAssetImageGenerator(asset: asset); generator.appliesPreferredTrackTransform = true; return try? UIImage(cgImage: generator.copyCGImage(at: .zero, actualTime: nil)) }
    func push(_ viewController: UIViewController) { viewController.hidesBottomBarWhenPushed = true; navigationController?.pushViewController(viewController, animated: true) }
}

final class ExploreViewController: RootPageViewController {
    private var segmentIndex = 0
    private var forYouPostOrder: [String] = []
    private var suppressRepositoryRefresh = false
    override func viewDidLoad() { titleText = "Explore"; super.viewDidLoad(); rebuild() }
    override func refreshData() { if !suppressRepositoryRefresh { rebuild() } }
    override func rebuild() { body.arrangedSubviews.forEach { $0.removeFromSuperview() }; heading("Explore"); body.addArrangedSubview(guideCard()); body.addArrangedSubview(exploreSegmented()); body.addArrangedSubview(label("People near you tried", size: 18, weight: .semibold)); let posts = postsForSegment(); if posts.isEmpty { body.addArrangedSubview(emptyState("No field notes here yet", detail: "Try another view to find a new story.")) } else { posts.forEach { body.addArrangedSubview(postCard($0)) } } }
    private func postsForSegment() -> [QPost] { let posts = QRepository.shared.visiblePosts; switch segmentIndex { case 0: let currentIDs = Set(posts.map(\.id)); let ordered = forYouPostOrder.compactMap { id in posts.first { $0.id == id } }; let newPosts = posts.filter { !forYouPostOrder.contains($0.id) }; forYouPostOrder = ordered.map(\.id) + newPosts.map(\.id); return (ordered + newPosts).filter { currentIDs.contains($0.id) }; case 1: return posts.sorted { let left = nearbyRank($0); let right = nearbyRank($1); return left.0 == right.0 ? left.1 > right.1 : left.0 < right.0 }; default: return QRepository.shared.followingPosts } }
    private func nearbyRank(_ post: QPost) -> (Int, Date) { let current = QRepository.shared.currentUser?.location.lowercased() ?? ""; let location = post.location.lowercased(); if !current.isEmpty && location == current { return (0, post.createdAt) }; if !current.isEmpty && (location.contains(current) || current.contains(location)) { return (1, post.createdAt) }; if location.contains("london") { return (2, post.createdAt) }; return (3, post.createdAt) }
    private func guideCard() -> UIView { let image = UIImageView(image: safeImage(["Group 1"])); image.tag = 501; image.contentMode = .scaleAspectFill; image.clipsToBounds = true; image.layer.cornerRadius = 14; image.heightAnchor.constraint(equalToConstant: 105).isActive = true; let tap = UITapGestureRecognizer(target: self, action: #selector(openGuide)); image.addGestureRecognizer(tap); image.isUserInteractionEnabled = true; return image }
    @objc private func openGuide() { guard QRepository.shared.isSignedIn else { showMessage("Sign In Required", "Please sign in to continue.", action: "Sign In") { AppCoordinator.shared.showAuth() }; return }; push(AIGuideViewController()) }
    private func exploreSegmented() -> UIView { let container = UIView(); container.tag = 502; container.backgroundColor = QTheme.surface; container.layer.cornerRadius = 14; container.heightAnchor.constraint(equalToConstant: 52).isActive = true; let stack = UIStackView(); stack.axis = .horizontal; stack.distribution = .fillEqually; stack.spacing = 0; ["For You", "Nearby", "Following"].enumerated().forEach { index, title in let b = UIButton(type: .system); b.setTitle(title, for: .normal); b.setTitleColor(index == segmentIndex ? .white : QTheme.secondaryText, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 14, weight: index == segmentIndex ? .medium : .regular); b.backgroundColor = index == segmentIndex ? QTheme.purple : .clear; b.layer.cornerRadius = 13; b.addAction(UIAction { [weak self] _ in self?.segmentIndex = index; self?.rebuild() }, for: .touchUpInside); stack.addArrangedSubview(b) }; container.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: container.leadingAnchor), stack.trailingAnchor.constraint(equalTo: container.trailingAnchor), stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 5), stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -5)]); return container }
    private func postCard(_ post: QPost) -> UIView { let v = UIView(); v.backgroundColor = QTheme.surface; v.layer.cornerRadius = 15; v.clipsToBounds = true; let image = UIImageView(image: safeImage(post.mediaAssets)); image.contentMode = .scaleAspectFill; image.clipsToBounds = true; image.heightAnchor.constraint(equalToConstant: 383).isActive = true; v.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: v.topAnchor), image.leadingAnchor.constraint(equalTo: v.leadingAnchor), image.trailingAnchor.constraint(equalTo: v.trailingAnchor)]); let fade = CAGradientLayer(); fade.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.72).cgColor]; fade.locations = [0.55, 1]; image.layer.addSublayer(fade); let more = UIButton(type: .system); more.setTitle("···", for: .normal); more.setTitleColor(.white, for: .normal); more.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold); more.backgroundColor = UIColor.white.withAlphaComponent(0.27); more.layer.cornerRadius = 11; more.isHidden = post.authorID == QRepository.shared.currentUserID; v.addSubview(more); more.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([more.topAnchor.constraint(equalTo: v.topAnchor, constant: 8), more.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -8), more.widthAnchor.constraint(equalToConstant: 42), more.heightAnchor.constraint(equalToConstant: 42)]); more.addAction(UIAction { [weak self] _ in self?.openMore(for: post) }, for: .touchUpInside); let user = QRepository.shared.user(post.authorID); let av = avatar(post.authorID, size: 40); let name = label(user?.name ?? "Unknown", size: 14, weight: .semibold); let meta = label("\(relativeTime(post.createdAt))", size: 11, color: QTheme.secondaryText); let info = stack(2); info.addArrangedSubview(name); info.addArrangedSubview(meta); let follow = button(QRepository.shared.followedUserIDs.contains(post.authorID) ? "Following" : "Follow", height: 42, filled: false); follow.widthAnchor.constraint(equalToConstant: 78).isActive = true; follow.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium); follow.layer.cornerRadius = 12; follow.isHidden = post.authorID == QRepository.shared.currentUserID; follow.addAction(UIAction { [weak self] _ in guard let self else { return }; suppressRepositoryRefresh = true; QRepository.shared.toggleFollow(userID: post.authorID); suppressRepositoryRefresh = false; follow.setTitle(QRepository.shared.followedUserIDs.contains(post.authorID) ? "Following" : "Follow", for: .normal) }, for: .touchUpInside); let overlay = UIStackView(arrangedSubviews: [av, info, UIView(), follow]); overlay.spacing = 9; overlay.alignment = .center; v.addSubview(overlay); overlay.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([overlay.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 14), overlay.trailingAnchor.constraint(equalTo: v.trailingAnchor, constant: -14), overlay.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -14)]); let details = UIView(); details.backgroundColor = QTheme.surface; details.heightAnchor.constraint(equalToConstant: 178).isActive = true; v.addSubview(details); details.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([details.topAnchor.constraint(equalTo: image.bottomAnchor), details.leadingAnchor.constraint(equalTo: v.leadingAnchor), details.trailingAnchor.constraint(equalTo: v.trailingAnchor), details.bottomAnchor.constraint(equalTo: v.bottomAnchor)]); let icon = UIImageView(image: UIImage.qAsset("Text")); icon.contentMode = .scaleAspectFit; icon.backgroundColor = QTheme.purple.withAlphaComponent(0.18); icon.layer.cornerRadius = 17; icon.clipsToBounds = true; icon.widthAnchor.constraint(equalToConstant: 34).isActive = true; icon.heightAnchor.constraint(equalToConstant: 34).isActive = true; let title = label(post.title, size: 16, weight: .semibold, color: QTheme.highlight); let titleRow = UIStackView(arrangedSubviews: [icon, title]); titleRow.spacing = 10; details.addSubview(titleRow); titleRow.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([titleRow.leadingAnchor.constraint(equalTo: details.leadingAnchor, constant: 14), titleRow.trailingAnchor.constraint(equalTo: details.trailingAnchor, constant: -14), titleRow.topAnchor.constraint(equalTo: details.topAnchor, constant: 14)]); let desc = label(post.body, size: 14, color: QTheme.secondaryText); details.addSubview(desc); desc.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([desc.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor), desc.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor), desc.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 12)]); let actions = postActionBar(post); details.addSubview(actions); actions.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([actions.leadingAnchor.constraint(equalTo: details.leadingAnchor, constant: 12), actions.bottomAnchor.constraint(equalTo: details.bottomAnchor, constant: -12), actions.heightAnchor.constraint(equalToConstant: 44)]); let tryButton = button("Try this task", height: 44, filled: false); tryButton.widthAnchor.constraint(equalToConstant: 112).isActive = true; tryButton.layer.cornerRadius = 13; tryButton.layer.borderColor = QTheme.highlight.cgColor; tryButton.titleLabel?.font = .systemFont(ofSize: 13); tryButton.addAction(UIAction { [weak self] _ in self?.openTaskInDraw(post) }, for: .touchUpInside); details.addSubview(tryButton); tryButton.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([tryButton.trailingAnchor.constraint(equalTo: details.trailingAnchor, constant: -14), tryButton.bottomAnchor.constraint(equalTo: details.bottomAnchor, constant: -12)]); let tap = UITapGestureRecognizer(target: self, action: #selector(openFirstPost(_:))); v.addGestureRecognizer(tap); v.accessibilityIdentifier = post.id; return v }
    private func postActionBar(_ post: QPost) -> UIStackView { let bar = UIStackView(); bar.axis = .horizontal; bar.alignment = .center; bar.distribution = .fill; bar.spacing = 18; let like = postActionButton(post.isLiked ? "♥  \(post.likes)" : "♡  \(post.likes)"); let comment = postActionButton("◯  \(post.comments.count)"); let save = postActionButton(post.isSaved ? "▣  Saved" : "▢  Save"); like.addAction(UIAction { [weak self] _ in QRepository.shared.toggleLike(postID: post.id); self?.rebuild() }, for: .touchUpInside); comment.addAction(UIAction { [weak self] _ in self?.openFirstPostByID(post.id) }, for: .touchUpInside); save.addAction(UIAction { [weak self] _ in QRepository.shared.toggleSave(postID: post.id); self?.rebuild() }, for: .touchUpInside); [like, comment, save].forEach { bar.addArrangedSubview($0) }; return bar }
    private func postActionButton(_ title: String) -> UIButton { let b = UIButton(type: .system); b.setTitle(title, for: .normal); b.setTitleColor(QTheme.secondaryText, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 13); b.contentHorizontalAlignment = .left; return b }
    private func openFirstPostByID(_ id: String) { guard let post = QRepository.shared.post(id) else { return }; push(FieldNoteViewController(post: post)) }
    private func openMore(for post: QPost) { showMoreSheet(for: post.authorID, report: { [weak self] in guard let self else { return }; self.push(ReportViewController(userID: post.authorID)) }, block: { [weak self] in guard let self else { return }; QRepository.shared.block(userID: post.authorID); self.rebuild() }) }
    private func openTaskInDraw(_ post: QPost) { guard let tabs = tabBarController as? MainTabBarController else { return }; tabs.presentPublish(for: post) }
    @objc private func openFirstPost(_ sender: UITapGestureRecognizer) { guard let id = sender.view?.accessibilityIdentifier, let post = QRepository.shared.post(id) else { return }; if !QRepository.shared.isSignedIn { showMessage("Sign In Required", "Please sign in to view this field note.", action: "Sign In") { AppCoordinator.shared.showAuth() }; return }; push(FieldNoteViewController(post: post)) }
    #if DEBUG
    func visualSetSegment(_ index: Int) { segmentIndex = max(0, min(index, 2)); rebuild() }
    #endif
}

final class DrawViewController: RootPageViewController {
    private let durationOptions = [12, 18, 24, 30, 60, 90, 120]
    private var selectedDuration = 24
    private var cardIndex = 0
    private var importedTask: QDrawTask?
    private var deck: [QDrawTask] = []
    private weak var draggingCard: UIView?
    private var dragStartX: CGFloat = 0

    override func viewDidLoad() { reloadDeck(); super.viewDidLoad(); rebuild() }

    func setTask(_ post: QPost) {
        importedTask = post.taskID.flatMap { QRepository.shared.drawTask(id: $0) } ?? QDrawTask(id: "post-\(post.id)", title: post.title, body: "Complete the task and share your proof.", mediaAsset: post.mediaAssets.first ?? "default_photo", durationHours: 24, distanceMiles: nil)
        selectedDuration = 24
        reloadDeck()
        if isViewLoaded { rebuild() }
    }

    private var tasks: [QDrawTask] { deck }

    private func reloadDeck() {
        var values = QRepository.shared.drawTasks(durationHours: selectedDuration).shuffled()
        if let importedTask {
            values.removeAll { $0.id == importedTask.id }
            values.insert(importedTask, at: 0)
        }
        deck = Array(values.prefix(3)); cardIndex = 0
    }

    private var currentTask: QDrawTask? {
        let values = tasks
        guard !values.isEmpty else { return nil }
        return values[cardIndex % values.count]
    }

    override func rebuild() {
        cardIndex = tasks.isEmpty ? 0 : cardIndex % tasks.count
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        heading("Draw")
        body.addArrangedSubview(drawCardStack())

        let timeFilter = filterButton()
        body.addArrangedSubview(timeFilter)
        body.setCustomSpacing(8, after: timeFilter)

        let isFreeDraw = !QRepository.shared.hasDrawnToday
        let notice = UILabel()
        notice.numberOfLines = 1
        notice.textAlignment = .center
        let noticeText = isFreeDraw ? "Your first draw today is free · Task lasts 24 hours" : "Each draw task costs 120 coins · Task lasts 24 hours"
        let noticeAttributedText = NSMutableAttributedString(string: "✓", attributes: [.foregroundColor: UIColor.systemGreen, .font: UIFont.systemFont(ofSize: 11, weight: .medium)])
        noticeAttributedText.append(NSAttributedString(string: "   \(noticeText)", attributes: [.foregroundColor: QTheme.secondaryText, .font: UIFont.systemFont(ofSize: 11)]))
        notice.attributedText = noticeAttributedText
        notice.textAlignment = .center; notice.heightAnchor.constraint(equalToConstant: 16).isActive = true
        body.addArrangedSubview(notice); body.setCustomSpacing(12, after: notice)

        let draw = button(isFreeDraw ? "Draw a task" : "120 coins Draw a task", height: 52)
        draw.setImage(UIImage.qAsset("Icon2")?.withRenderingMode(.alwaysOriginal), for: .normal)
        draw.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
        draw.addAction(UIAction { [weak self] _ in self?.drawTask() }, for: .touchUpInside)
        body.addArrangedSubview(draw)
    }

    private func filterButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(selectedDuration) h   ⌄", for: .normal)
        button.setTitleColor(QTheme.secondaryText, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12)
        button.backgroundColor = UIColor(hex: "181022")
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(hex: "34204C").cgColor
        button.layer.cornerRadius = 12
        button.heightAnchor.constraint(equalToConstant: 42).isActive = true
        button.addAction(UIAction { [weak self] _ in self?.presentTimeFilterSheet() }, for: .touchUpInside)
        return button
    }

    private func presentTimeFilterSheet() {
        let options = durationOptions.map { "\($0) h" }
        let selected = durationOptions.firstIndex(of: selectedDuration) ?? 2
        let sheet = QDrawFilterSheet(title: "Time", options: options, selectedIndex: selected) { [weak self] index in
            guard let self else { return }
            self.selectedDuration = self.durationOptions[index]
            self.importedTask = nil
            self.reloadDeck()
            self.rebuild()
        }
        sheet.modalPresentationStyle = .overFullScreen
        sheet.modalTransitionStyle = .coverVertical
        present(sheet, animated: true)
    }

    private func drawCardStack() -> UIView {
        let wrapper = UIView(); wrapper.heightAnchor.constraint(equalToConstant: 470).isActive = true
        let values = tasks
        guard !values.isEmpty else { wrapper.addSubview(emptyState("No tasks available")); return wrapper }

        for offset in stride(from: min(2, values.count - 1), through: 1, by: -1) {
            let task = values[(cardIndex + offset) % values.count]
            let back = taskCard(task, interactive: false)
            back.alpha = offset == 2 ? 0.55 : 0.78
            wrapper.addSubview(back); back.translatesAutoresizingMaskIntoConstraints = false
            let sideInset = CGFloat(offset * 11)
            NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: sideInset), back.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -sideInset), back.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: CGFloat((2 - offset) * 17)), back.heightAnchor.constraint(equalToConstant: 425)])
        }

        let front = taskCard(values[cardIndex % values.count], interactive: true)
        wrapper.addSubview(front); front.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([front.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), front.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), front.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 35), front.heightAnchor.constraint(equalToConstant: 431)])
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pannedCard(_:)))
        front.addGestureRecognizer(pan); front.isUserInteractionEnabled = true
        return wrapper
    }

    private func taskCard(_ task: QDrawTask, interactive: Bool) -> UIView {
        let card = UIView(); card.backgroundColor = QTheme.surface; card.layer.cornerRadius = 16; card.clipsToBounds = true
        card.layer.borderWidth = interactive ? 1 : 0.75; card.layer.borderColor = QTheme.divider.withAlphaComponent(interactive ? 1 : 0.72).cgColor
        let image = UIImageView(image: safeImage([task.mediaAsset, "default_photo"])); image.contentMode = .scaleAspectFill; image.clipsToBounds = true
        card.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: card.topAnchor), image.leadingAnchor.constraint(equalTo: card.leadingAnchor), image.trailingAnchor.constraint(equalTo: card.trailingAnchor), image.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let shade = UIView(); shade.backgroundColor = UIColor.black.withAlphaComponent(interactive ? 0.28 : 0.45)
        card.addSubview(shade); shade.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([shade.leadingAnchor.constraint(equalTo: card.leadingAnchor), shade.trailingAnchor.constraint(equalTo: card.trailingAnchor), shade.topAnchor.constraint(equalTo: card.topAnchor), shade.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let sparkle = UIImageView(image: UIImage.qAsset("star")?.withRenderingMode(.alwaysOriginal))
        sparkle.contentMode = .scaleAspectFit
        card.addSubview(sparkle); sparkle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([sparkle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 29), sparkle.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -128), sparkle.widthAnchor.constraint(equalToConstant: 28), sparkle.heightAnchor.constraint(equalToConstant: 28)])
        let title = label(task.title, size: 27, weight: .bold); title.numberOfLines = 2
        let distance = task.distanceMiles.map { " · within \($0) mi" } ?? " · anywhere"
        let desc = label("\(task.body)\n\(task.durationHours) h\(distance)", size: 13, color: .white); desc.numberOfLines = 3
        let text = stack(8); text.addArrangedSubview(title); text.addArrangedSubview(desc)
        card.addSubview(text); text.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([text.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22), text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), text.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)])
        return card
    }

    @objc private func pannedCard(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view else { return }
        let translation = gesture.translation(in: card.superview)
        switch gesture.state {
        case .began:
            draggingCard = card; dragStartX = card.center.x
        case .changed:
            let progress = min(1, abs(translation.x) / max(card.bounds.width, 1))
            card.center.x = dragStartX + translation.x
            card.transform = CGAffineTransform(rotationAngle: (translation.x / max(card.bounds.width, 1)) * 0.22)
            card.alpha = 1 - progress * 0.18
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: card.superview).x
            let shouldAdvance = abs(translation.x) > 70 || abs(velocity) > 600
            guard shouldAdvance, tasks.count > 1 else {
                UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0) { card.center.x = self.dragStartX; card.transform = .identity; card.alpha = 1 }
                draggingCard = nil
                return
            }
            let direction: CGFloat = translation.x < 0 ? -1 : 1
            cardIndex = direction < 0 ? (cardIndex + 1) % tasks.count : (cardIndex - 1 + tasks.count) % tasks.count
            UIView.animate(withDuration: 0.2, animations: { card.center.x = self.dragStartX + direction * (card.bounds.width + 80); card.alpha = 0 }) { _ in
                self.draggingCard = nil
                self.rebuild()
            }
        default: break
        }
    }

    private func openPublish(_ task: QDrawTask) {
        if let tabs = tabBarController as? MainTabBarController { tabs.presentPublish(for: task) }
        else { push(PublishViewController(task: task)) }
    }

    private func drawTask() {
        guard let task = currentTask else { return }
        guard QRepository.shared.isSignedIn else { showMessage("Sign In Required", "Please sign in to publish this task.", action: "Sign In") { AppCoordinator.shared.showAuth() }; return }
        openPublish(task)
    }
}

final class PublishViewController: RootPageViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, PHPickerViewControllerDelegate, UITextViewDelegate {
    private enum PublishMode { case photos, video }
    private enum MediaKind { case photo, video }
    private let note = UITextView(); private let notePlaceholder = UILabel(); private let noteCountLabel = UILabel(); private let locationField = UITextField(); private let locationManager = CLLocationManager(); private var locationToast: UILabel?; private var assets: [String] = []; private var selectedTask: QDrawTask?; private var mode: PublishMode = .photos; private var taskClaimedAt: Date?; private var taskTimer: Timer?
    private var pickerKind: MediaKind = .photo
    init(task: QDrawTask? = nil, claimedAt: Date? = nil) { selectedTask = task; taskClaimedAt = claimedAt ?? (task == nil ? nil : Date()); super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override func viewDidLoad() { super.viewDidLoad(); locationManager.delegate = self; locationField.text = nil; rebuild(); taskTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.rebuild() } }
    func setTask(_ task: QDrawTask) { selectedTask = task; mode = .photos; assets.removeAll(); note.text = nil; if isViewLoaded { rebuild() } }
    override func rebuild() {
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        heading("Publish")
        body.setCustomSpacing(29, after: body.arrangedSubviews.last!)
        let activeTask = taskCard(); body.addArrangedSubview(activeTask); body.setCustomSpacing(12, after: activeTask)
        let proofTitle = UIStackView(arrangedSubviews: [label("Proof", size: 14, weight: .semibold), UIView(), label(mode == .video ? "\(assets.isEmpty ? 0 : 1)/1 video" : "\(assets.count)/3 photos", size: 10, color: QTheme.secondaryText)])
        proofTitle.alignment = .center; body.addArrangedSubview(proofTitle); body.setCustomSpacing(10, after: proofTitle)
        let proof = proofGrid(); body.addArrangedSubview(proof); body.setCustomSpacing(9, after: proof)
        let addPhoto = button("＋  Add photo", height: 42, filled: false); let addVideo = UIButton(type: .system); addVideo.setTitle("  Add video", for: .normal); addVideo.setImage(UIImage.qAsset("Icon4")?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "video"), for: .normal); addVideo.setTitleColor(.white, for: .normal); addVideo.tintColor = .white; addVideo.backgroundColor = QTheme.surface; addVideo.layer.borderWidth = 1; addVideo.layer.borderColor = QTheme.divider.cgColor; addVideo.layer.cornerRadius = 11; addVideo.heightAnchor.constraint(equalToConstant: 42).isActive = true; [addPhoto, addVideo].forEach { $0.titleLabel?.font = .systemFont(ofSize: 13); $0.layer.cornerRadius = 11 }
        addPhoto.isEnabled = mode == .video || assets.count < 3; addPhoto.alpha = addPhoto.isEnabled ? 1 : 0.55
        addPhoto.addAction(UIAction { [weak self] _ in self?.presentMediaSheet(for: .photo) }, for: .touchUpInside)
        addVideo.addAction(UIAction { [weak self] _ in self?.presentMediaSheet(for: .video) }, for: .touchUpInside)
        let addRow = UIStackView(arrangedSubviews: [addPhoto, addVideo]); addRow.spacing = 8; addRow.distribution = .fillEqually; body.addArrangedSubview(addRow)
        body.setCustomSpacing(16, after: addRow)
        let location = locationSection(); body.addArrangedSubview(location); body.setCustomSpacing(18, after: location)
        let fieldNote = fieldNoteSection(); body.addArrangedSubview(fieldNote); body.setCustomSpacing(25, after: fieldNote)
        let publish = button("⊕  Publish check-in", height: 52); publish.addAction(UIAction { [weak self] _ in self?.publishPost() }, for: .touchUpInside); body.addArrangedSubview(publish)
    }
    private func presentMediaSheet(for kind: MediaKind) {
        if kind == .photo && assets.count >= 3 { return }
        pickerKind = kind
        let sheet = QPublishMediaSheet(isVideo: kind == .video) { [weak self] source in self?.presentPicker(source: source, kind: kind) }
        sheet.modalPresentationStyle = .overFullScreen
        present(sheet, animated: true)
    }
    private func presentPicker(source: UIImagePickerController.SourceType, kind: MediaKind) {
        if kind == .photo && source == .photoLibrary {
            var configuration = PHPickerConfiguration(photoLibrary: .shared())
            configuration.filter = .images
            configuration.selectionLimit = mode == .video ? 3 : max(1, 3 - assets.count)
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            present(picker, animated: true)
            return
        }
        guard UIImagePickerController.isSourceTypeAvailable(source) else { showMessage("Unavailable", "This media source is not available on this device."); return }
        let picker = UIImagePickerController()
        picker.sourceType = source
        picker.delegate = self
        picker.mediaTypes = [kind == .photo ? "public.image" : "public.movie"]
        if kind == .video { picker.videoQuality = .typeMedium; picker.videoMaximumDuration = 60 }
        present(picker, animated: true)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if pickerKind == .photo, let image = info[.originalImage] as? UIImage, let path = saveImage(image) {
            if mode == .video { assets.removeAll() }
            mode = .photos
            assets.append(path)
            assets = Array(assets.prefix(3))
        } else if pickerKind == .video, let url = info[.mediaURL] as? URL, let path = saveVideo(url) {
            mode = .video
            assets = [path]
        }
        picker.dismiss(animated: true) { [weak self] in self?.rebuild() }
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let replacingVideo = mode == .video
        let remaining = replacingVideo ? 3 : max(0, 3 - assets.count)
        for result in results.prefix(remaining) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let self, let image = object as? UIImage, let path = self.saveImage(image) else { return }
                DispatchQueue.main.async {
                    if replacingVideo && self.mode == .video {
                        self.assets.removeAll()
                    }
                    self.mode = .photos
                    self.assets.append(path)
                    self.assets = Array(self.assets.prefix(3))
                    self.rebuild()
                }
            }
        }
    }
    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.88) else { return nil }
        return saveMediaData(data, extension: "jpg")
    }
    private func saveVideo(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return saveMediaData(data, extension: "mov")
    }
    private func saveMediaData(_ data: Data, extension fileExtension: String) -> String? {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QrovoPublish", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("\(UUID().uuidString).\(fileExtension)")
            try data.write(to: url, options: .atomic)
            return url.path
        } catch { return nil }
    }
    private func cancelPublish() { if presentingViewController != nil { dismiss(animated: true) } else { navigationController?.popViewController(animated: true) } }
    private func taskCard() -> UIView { let card = UIView(); card.backgroundColor = QTheme.surface; card.layer.cornerRadius = 15; card.clipsToBounds = true; card.heightAnchor.constraint(equalToConstant: 87).isActive = true; let rail = UIView(); rail.backgroundColor = UIColor(hex: "25183E"); card.addSubview(rail); rail.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([rail.leadingAnchor.constraint(equalTo: card.leadingAnchor), rail.topAnchor.constraint(equalTo: card.topAnchor), rail.bottomAnchor.constraint(equalTo: card.bottomAnchor), rail.widthAnchor.constraint(equalToConstant: 35)]); let dots = UIStackView(arrangedSubviews: [label("◦", size: 16, color: QTheme.highlight), label("◦", size: 16, color: QTheme.highlight)]); dots.axis = .vertical; dots.alignment = .center; dots.distribution = .fillEqually; card.addSubview(dots); dots.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([dots.leadingAnchor.constraint(equalTo: rail.leadingAnchor), dots.trailingAnchor.constraint(equalTo: rail.trailingAnchor), dots.topAnchor.constraint(equalTo: rail.topAnchor, constant: 8), dots.bottomAnchor.constraint(equalTo: rail.bottomAnchor, constant: -8)]); let remaining = remainingTaskTime(); let eyebrow = label("ACTIVE TASK · \(remaining) LEFT", size: 9, weight: .semibold, color: QTheme.highlight); let title = label(selectedTask?.title ?? "Find a color in the night almost hid", size: 16, weight: .semibold); let detail = label(selectedTask?.body ?? "Photograph it without changing the light around\nyou.", size: 11, color: QTheme.secondaryText); let text = stack(5); [eyebrow, title, detail].forEach { text.addArrangedSubview($0) }; card.addSubview(text); text.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([text.leadingAnchor.constraint(equalTo: rail.trailingAnchor, constant: 10), text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -32), text.centerYAnchor.constraint(equalTo: card.centerYAnchor)]); let trash = UIButton(type: .system); trash.setImage(UIImage(systemName: "trash"), for: .normal); trash.tintColor = QTheme.mutedText; trash.addAction(UIAction { [weak self] _ in self?.cancelPublish() }, for: .touchUpInside); card.addSubview(trash); trash.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([trash.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12), trash.topAnchor.constraint(equalTo: card.topAnchor, constant: 12), trash.widthAnchor.constraint(equalToConstant: 28), trash.heightAnchor.constraint(equalToConstant: 28)]); return card }
    private func remainingTaskTime() -> String { let durationHours = selectedTask?.durationHours ?? 24; guard let taskClaimedAt else { return "\(durationHours)H" }; let seconds = max(0, durationHours * 60 * 60 - Int(Date().timeIntervalSince(taskClaimedAt))); let hours = seconds / 3600; let minutes = (seconds % 3600) / 60; return hours > 0 ? "\(hours)H" : "\(minutes)M" }
    private func proofGrid() -> UIView { let container = UIView(); container.heightAnchor.constraint(equalToConstant: 277).isActive = true; if mode == .video { let item = mediaView(assets.first ?? "empty", large: true); container.addSubview(item); item.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([item.leadingAnchor.constraint(equalTo: container.leadingAnchor), item.trailingAnchor.constraint(equalTo: container.trailingAnchor), item.topAnchor.constraint(equalTo: container.topAnchor), item.bottomAnchor.constraint(equalTo: container.bottomAnchor)]); if assets.indices.contains(0) { addClose(to: item, index: 0) }; let play = label("▶", size: 34, color: .white); play.textAlignment = .center; play.backgroundColor = UIColor.white.withAlphaComponent(0.78); play.layer.cornerRadius = 18; play.clipsToBounds = true; container.addSubview(play); play.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([play.centerXAnchor.constraint(equalTo: container.centerXAnchor), play.centerYAnchor.constraint(equalTo: container.centerYAnchor), play.widthAnchor.constraint(equalToConstant: 58), play.heightAnchor.constraint(equalToConstant: 58)]); return container }; let main = mediaView(assets.indices.contains(0) ? assets[0] : "empty", large: true); let top = mediaView(assets.indices.contains(1) ? assets[1] : "empty", large: false); let bottom = mediaView(assets.indices.contains(2) ? assets[2] : "empty", large: false); let side = UIStackView(arrangedSubviews: [top, bottom]); side.axis = .vertical; side.spacing = 8; side.distribution = .fillEqually; top.heightAnchor.constraint(equalTo: bottom.heightAnchor).isActive = true; container.addSubview(main); container.addSubview(side); main.translatesAutoresizingMaskIntoConstraints = false; side.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([main.leadingAnchor.constraint(equalTo: container.leadingAnchor), main.topAnchor.constraint(equalTo: container.topAnchor), main.bottomAnchor.constraint(equalTo: container.bottomAnchor), main.widthAnchor.constraint(equalTo: container.widthAnchor, multiplier: 0.654), side.leadingAnchor.constraint(equalTo: main.trailingAnchor, constant: 8), side.trailingAnchor.constraint(equalTo: container.trailingAnchor), side.topAnchor.constraint(equalTo: container.topAnchor), side.bottomAnchor.constraint(equalTo: container.bottomAnchor)]); if assets.indices.contains(0) { addClose(to: main, index: 0) }; if assets.indices.contains(1) { addClose(to: top, index: 1) }; if assets.indices.contains(2) { addClose(to: bottom, index: 2) }; return container }
    private func mediaView(_ name: String, large: Bool) -> UIView { let image = UIImage.qAsset(name) ?? UIImage(contentsOfFile: name) ?? videoThumbnail(at: name); let view: UIView; if let image { let imageView = UIImageView(image: image); imageView.contentMode = .scaleAspectFill; imageView.clipsToBounds = true; view = imageView } else { view = placeholderMedia(isVideo: name.hasSuffix(".mov") || name.hasSuffix(".mp4")) }; view.isUserInteractionEnabled = true; view.layer.cornerRadius = 14; view.clipsToBounds = true; return view }
    private func placeholderMedia(isVideo: Bool = false) -> UIView { let v = UIView(); v.backgroundColor = QTheme.surfaceSecondary; v.layer.borderWidth = 2; v.layer.borderColor = QTheme.mutedText.withAlphaComponent(0.7).cgColor; v.layer.cornerRadius = 14; let icon = UIImageView(image: UIImage(systemName: isVideo ? "video" : "photo")); icon.tintColor = QTheme.mutedText; icon.contentMode = .scaleAspectFit; v.addSubview(icon); icon.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([icon.centerXAnchor.constraint(equalTo: v.centerXAnchor), icon.centerYAnchor.constraint(equalTo: v.centerYAnchor), icon.widthAnchor.constraint(equalToConstant: 38), icon.heightAnchor.constraint(equalToConstant: 32)]); return v }
    private func addClose(to view: UIView, index: Int) { let close = button("×", height: 42, filled: false); close.widthAnchor.constraint(equalToConstant: 42).isActive = true; close.layer.cornerRadius = 11; close.backgroundColor = UIColor.black.withAlphaComponent(0.38); close.addAction(UIAction { [weak self] _ in guard let self, assets.indices.contains(index) else { return }; assets.remove(at: index); rebuild() }, for: .touchUpInside); view.addSubview(close); close.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8), close.topAnchor.constraint(equalTo: view.topAnchor, constant: 8)]) }
    private func fieldNoteSection() -> UIView { let wrapper = UIView(); wrapper.heightAnchor.constraint(equalToConstant: 109).isActive = true; let title = label("Field note", size: 14, weight: .semibold); wrapper.addSubview(title); title.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([title.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), title.topAnchor.constraint(equalTo: wrapper.topAnchor)]); if note.text?.isEmpty != false { note.text = nil }; note.textColor = .white; note.font = .systemFont(ofSize: 14); note.backgroundColor = .clear; note.layer.borderColor = QTheme.divider.cgColor; note.layer.borderWidth = 1; note.layer.cornerRadius = 0; wrapper.addSubview(note); note.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([note.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), note.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), note.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 9), note.heightAnchor.constraint(equalToConstant: 71)]); note.delegate = self; note.textContainerInset = UIEdgeInsets(top: 9, left: 4, bottom: 4, right: 4); notePlaceholder.text = "Write a thoughtful field note..."; notePlaceholder.textColor = QTheme.mutedText; notePlaceholder.font = .systemFont(ofSize: 14); notePlaceholder.isUserInteractionEnabled = false; notePlaceholder.isHidden = !(note.text?.isEmpty ?? true); wrapper.addSubview(notePlaceholder); notePlaceholder.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([notePlaceholder.leadingAnchor.constraint(equalTo: note.leadingAnchor, constant: 8), notePlaceholder.topAnchor.constraint(equalTo: note.topAnchor, constant: 9)]); noteCountLabel.text = "0/300"; noteCountLabel.font = .systemFont(ofSize: 10); noteCountLabel.textColor = QTheme.mutedText; let count = noteCountLabel; wrapper.addSubview(count); count.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([count.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), count.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)]); return wrapper }
    func textViewDidChange(_ textView: UITextView) { notePlaceholder.isHidden = !textView.text.isEmpty; noteCountLabel.text = "\(min(textView.text.count, 300))/300" }
    private func publishPost() { guard let text = note.text?.trimmingCharacters(in: .whitespacesAndNewlines), text.count > 1 else { showMessage("Add a field note", "Tell the community what you found."); return }; let location = locationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""; guard !location.isEmpty else { showMessage("Add a location", "Enter a location or use the location button."); return }; QRepository.shared.publish(title: selectedTask?.title ?? text.split(separator: ".").first.map(String.init) ?? text, body: text, location: location, assets: assets); QRepository.shared.markDrawnToday(); showMessage("Published", "Your field note is ready to share.") { if let tabs = self.presentingViewController as? MainTabBarController { tabs.clearClaimedPublishTask(); self.dismiss(animated: true) { tabs.showExplore() } } else { self.tabBarController?.selectedIndex = 0 } } }
    private func locationSection() -> UIView { let wrapper = UIView(); wrapper.heightAnchor.constraint(equalToConstant: 78).isActive = true; let title = label("Location", size: 14, color: QTheme.secondaryText); wrapper.addSubview(title); title.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([title.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), title.topAnchor.constraint(equalTo: wrapper.topAnchor)]); locationField.placeholder = "Add a location"; locationField.textColor = .white; locationField.font = .systemFont(ofSize: 14); locationField.isEnabled = true; locationField.isUserInteractionEnabled = true; locationField.clearButtonMode = .whileEditing; locationField.returnKeyType = .done; locationField.backgroundColor = .clear; locationField.layer.cornerRadius = 0; locationField.layer.borderWidth = 1; locationField.layer.borderColor = QTheme.divider.cgColor; locationField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 1)); locationField.leftViewMode = .always; wrapper.addSubview(locationField); locationField.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([locationField.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), locationField.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -44), locationField.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8), locationField.heightAnchor.constraint(equalToConstant: 52)]); let locationButton = UIButton(type: .custom); locationButton.setImage(UIImage(systemName: "location.fill"), for: .normal); locationButton.tintColor = .white; locationButton.backgroundColor = .clear; locationButton.contentHorizontalAlignment = .center; locationButton.contentVerticalAlignment = .center; locationButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8); locationButton.addAction(UIAction { [weak self] _ in self?.showLocationToast("Locating..."); self?.locateCurrentPosition() }, for: .touchUpInside); wrapper.addSubview(locationButton); locationButton.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([locationButton.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -4), locationButton.centerYAnchor.constraint(equalTo: locationField.centerYAnchor), locationButton.widthAnchor.constraint(equalToConstant: 40), locationButton.heightAnchor.constraint(equalToConstant: 48)]); return wrapper }
    private func showLocationToast(_ text: String) { locationToast?.removeFromSuperview(); let toast = UILabel(); toast.text = text; toast.textColor = .white; toast.font = .systemFont(ofSize: 13, weight: .medium); toast.textAlignment = .center; toast.backgroundColor = UIColor(hex: "242033").withAlphaComponent(0.96); toast.layer.cornerRadius = 12; toast.clipsToBounds = true; view.addSubview(toast); toast.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([toast.centerXAnchor.constraint(equalTo: view.centerXAnchor), toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -92), toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 108), toast.heightAnchor.constraint(equalToConstant: 40)]); locationToast = toast }
    private func hideLocationToast() { locationToast?.removeFromSuperview(); locationToast = nil }
    private func locateCurrentPosition() { switch locationManager.authorizationStatus { case .authorizedAlways, .authorizedWhenInUse: locationManager.requestLocation(); case .notDetermined: locationManager.requestWhenInUseAuthorization(); default: hideLocationToast(); showMessage("Location Unavailable", "Allow location access in Settings to fill this field automatically.") } }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways { manager.requestLocation() } }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { guard let location = locations.last else { showLocationToast("Location unavailable"); return }; CLGeocoder().reverseGeocodeLocation(location) { [weak self] places, _ in guard let self else { return }; let place = places?.first; let parts = [place?.locality, place?.administrativeArea, place?.country].compactMap { $0 }.filter { !$0.isEmpty }; let address = parts.isEmpty ? (place?.name ?? "") : parts.joined(separator: ", "); DispatchQueue.main.async { if address.isEmpty { self.showLocationToast("Location unavailable") } else { self.hideLocationToast(); self.locationField.text = address } } } }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { showLocationToast("Location unavailable"); DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in self?.hideLocationToast() } }
    #if DEBUG
    func visualSetAssetCount(_ count: Int) {
        let safeCount = max(0, min(count, 3))
        if safeCount == 0 {
            assets.removeAll()
        } else {
            let base = ["publish_photo_0", "publish_photo_1", "publish_photo_2"]
            assets = Array(base.prefix(safeCount))
        }
        rebuild()
    }
    #endif
}

final class InboxViewController: RootPageViewController {
    private var activity = false
    private var recommendedUserID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        chooseRecommendedUserIfNeeded()
        rebuild()
    }

    override func rebuild() {
        chooseRecommendedUserIfNeeded()
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        heading("Inbox")
        let tabs = inboxTabs()
        body.setCustomSpacing(19, after: body.arrangedSubviews.last!)
        body.addArrangedSubview(tabs)
        body.setCustomSpacing(25, after: tabs)
        body.addArrangedSubview(guideCard())
        body.setCustomSpacing(20, after: body.arrangedSubviews.last!)
        if let recommendation = recommendationCard() {
            body.addArrangedSubview(recommendation)
            body.setCustomSpacing(15, after: recommendation)
        }
        body.addArrangedSubview(label("All conversations", size: 14, weight: .semibold))
        if activity {
            QRepository.shared.currentUserActivities.sorted { $0.createdAt > $1.createdAt }.forEach { body.addArrangedSubview(activityRow($0)) }
        } else {
            QRepository.shared.currentUserConversations
                .sorted { ($0.messages.last?.createdAt ?? .distantPast) > ($1.messages.last?.createdAt ?? .distantPast) }
                .forEach { body.addArrangedSubview(conversation($0)) }
        }
    }

    private func chooseRecommendedUserIfNeeded() {
        let candidates = QRepository.shared.users.filter {
            $0.id != QRepository.shared.currentUserID && !QRepository.shared.blockedUserIDs.contains($0.id)
        }
        if let recommendedUserID, candidates.contains(where: { $0.id == recommendedUserID }) { return }
        recommendedUserID = candidates.randomElement()?.id
    }

    private func inboxTabs() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(hex: "0E1114")
        view.heightAnchor.constraint(equalToConstant: 42).isActive = true
        let messages = UIButton(type: .system)
        let activityButton = UIButton(type: .system)
        messages.setTitle("Messages", for: .normal)
        activityButton.setTitle("Activity", for: .normal)
        [messages, activityButton].forEach {
            $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            $0.setTitleColor(.white, for: .normal)
        }
        messages.setTitleColor(activity ? QTheme.secondaryText : .white, for: .normal)
        activityButton.setTitleColor(activity ? .white : QTheme.secondaryText, for: .normal)
        messages.addAction(UIAction { [weak self] _ in self?.activity = false; self?.rebuild() }, for: .touchUpInside)
        activityButton.addAction(UIAction { [weak self] _ in self?.activity = true; self?.rebuild() }, for: .touchUpInside)
        let tabs = UIStackView(arrangedSubviews: [messages, activityButton])
        tabs.distribution = .fillEqually
        view.addSubview(tabs)
        tabs.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabs.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabs.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabs.topAnchor.constraint(equalTo: view.topAnchor),
            tabs.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let activityCount = QRepository.shared.currentUserActivities.count
        if activityCount > 0 {
            let badge = label("\(activityCount)", size: 9, weight: .semibold, color: QTheme.secondaryText)
            badge.backgroundColor = QTheme.divider
            badge.textAlignment = .center
            badge.layer.cornerRadius = 9
            badge.clipsToBounds = true
            view.addSubview(badge)
            badge.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                badge.leadingAnchor.constraint(equalTo: activityButton.centerXAnchor, constant: 33),
                badge.centerYAnchor.constraint(equalTo: activityButton.centerYAnchor),
                badge.widthAnchor.constraint(equalToConstant: 18),
                badge.heightAnchor.constraint(equalToConstant: 18)
            ])
        }
        let line = UIView()
        line.backgroundColor = QTheme.brightPurple
        view.addSubview(line)
        line.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            line.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            line.heightAnchor.constraint(equalToConstant: 2),
            line.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activity ? line.trailingAnchor.constraint(equalTo: view.trailingAnchor) : line.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        return view
    }
    private func guideCard() -> UIView { let image = UIImageView(image: UIImage.qAsset("Group 1")); image.contentMode = .scaleAspectFill; image.clipsToBounds = true; image.layer.cornerRadius = 14; image.heightAnchor.constraint(equalToConstant: 105).isActive = true; image.isUserInteractionEnabled = true; image.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openGuide))); return image }
    @objc private func openGuide() { push(AIGuideViewController()) }
    private func recommendationCard() -> UIView? {
        guard let userID = recommendedUserID, let user = QRepository.shared.user(userID) else { return nil }
        let post = QRepository.shared.visiblePosts.first { $0.authorID == userID }
        let imageNames = post?.mediaAssets ?? [user.avatarAsset ?? "default_photo"]
        let card = UIView()
        card.backgroundColor = QTheme.surface
        card.layer.cornerRadius = 15
        card.layer.borderWidth = 1
        card.layer.borderColor = QTheme.divider.cgColor
        card.clipsToBounds = true
        card.heightAnchor.constraint(equalToConstant: 220).isActive = true
        let image = UIImageView(image: safeImage(imageNames))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        card.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            image.topAnchor.constraint(equalTo: card.topAnchor),
            image.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            image.widthAnchor.constraint(equalTo: card.widthAnchor, multiplier: 0.48)
        ])
        let online = label("●  Online now", size: 9, color: .white)
        online.textColor = UIColor(hex: "F4F4F6")
        image.addSubview(online)
        online.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([online.leadingAnchor.constraint(equalTo: image.leadingAnchor, constant: 11), online.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -11)])
        let panel = UIView()
        panel.backgroundColor = QTheme.surface
        card.addSubview(panel)
        panel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([panel.leadingAnchor.constraint(equalTo: image.trailingAnchor), panel.trailingAnchor.constraint(equalTo: card.trailingAnchor), panel.topAnchor.constraint(equalTo: card.topAnchor), panel.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let eyebrow = label("●  Recommendation", size: 9, weight: .semibold, color: QTheme.highlight)
        let name = label(user.name, size: 17, weight: .semibold)
        let detail = label(post?.body ?? user.bio, size: 13, color: QTheme.secondaryText)
        detail.numberOfLines = 3
        let info = stack(12)
        [eyebrow, name, detail].forEach { info.addArrangedSubview($0) }
        panel.addSubview(info)
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([info.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 14), info.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -10), info.topAnchor.constraint(equalTo: panel.topAnchor, constant: 17)])
        let sayHi = button("◯  Say Hi", height: 38)
        sayHi.widthAnchor.constraint(equalToConstant: 84).isActive = true
        sayHi.layer.cornerRadius = 10
        sayHi.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        sayHi.addAction(UIAction { [weak self] _ in self?.push(ChatViewController(userID: userID)) }, for: .touchUpInside)
        panel.addSubview(sayHi)
        sayHi.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([sayHi.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 14), sayHi.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -15)])
        return card
    }

    private func activityRow(_ item: QActivity) -> UIView {
        let row = UIButton(type: .system)
        row.backgroundColor = .clear
        row.heightAnchor.constraint(equalToConstant: 66).isActive = true
        let actor = QRepository.shared.user(item.actorID)
        let post = item.postID.flatMap { QRepository.shared.post($0) }
        let actionText: String
        switch item.kind {
        case .like: actionText = "\(actor?.name ?? "Someone") liked your field note"
        case .comment: actionText = "\(actor?.name ?? "Someone") commented on your field note"
        case .follow: actionText = "\(actor?.name ?? "Someone") followed you"
        }
        let av = avatar(item.actorID, size: 42)
        let title = label(actionText, size: 12, weight: .medium)
        let subtitle = label(post?.title ?? "View profile", size: 10, color: QTheme.secondaryText)
        let info = stack(5)
        info.addArrangedSubview(title)
        info.addArrangedSubview(subtitle)
        row.addSubview(av)
        row.addSubview(info)
        av.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            av.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 2), av.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            info.leadingAnchor.constraint(equalTo: av.trailingAnchor, constant: 12), info.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -32), info.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        let time = label(shortTime(item.createdAt), size: 9, color: QTheme.secondaryText)
        row.addSubview(time)
        time.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([time.trailingAnchor.constraint(equalTo: row.trailingAnchor), time.topAnchor.constraint(equalTo: row.topAnchor, constant: 5)])
        let hitArea = UIButton(type: .system)
        hitArea.backgroundColor = .clear
        row.addSubview(hitArea)
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([hitArea.leadingAnchor.constraint(equalTo: row.leadingAnchor), hitArea.trailingAnchor.constraint(equalTo: row.trailingAnchor), hitArea.topAnchor.constraint(equalTo: row.topAnchor), hitArea.bottomAnchor.constraint(equalTo: row.bottomAnchor)])
        hitArea.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            if item.kind == .follow { push(OtherProfileViewController(userID: item.actorID)) }
            else if let post { push(FieldNoteViewController(post: post)) }
        }, for: .touchUpInside)
        return row
    }

    private func conversation(_ conversation: QConversation) -> UIView {
        let user = QRepository.shared.user(conversation.userID)
        let row = UIButton(type: .system)
        row.backgroundColor = .clear
        row.contentHorizontalAlignment = .left
        row.heightAnchor.constraint(equalToConstant: 67).isActive = true
        let av = avatar(conversation.userID, size: 42)
        let title = label(user?.name ?? "Conversation", size: 15, weight: .semibold)
        let last = conversation.messages.last
        let preview: String
        switch last?.kind {
        case .image: preview = "Photo"
        case .voice: preview = "Voice message"
        default: preview = last?.text ?? "Start a conversation"
        }
        let message = label(preview, size: 12, color: QTheme.secondaryText)
        message.numberOfLines = 1
        let info = stack(5)
        info.addArrangedSubview(title)
        info.addArrangedSubview(message)
        row.addSubview(av)
        row.addSubview(info)
        av.translatesAutoresizingMaskIntoConstraints = false
        info.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            av.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 2), av.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            info.leadingAnchor.constraint(equalTo: av.trailingAnchor, constant: 12), info.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -52), info.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        if let date = last?.createdAt {
            let time = label(shortTime(date), size: 9, color: QTheme.secondaryText)
            row.addSubview(time)
            time.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([time.trailingAnchor.constraint(equalTo: row.trailingAnchor), time.topAnchor.constraint(equalTo: row.topAnchor, constant: 11)])
        }
        let divider = UIView()
        divider.backgroundColor = QTheme.divider.withAlphaComponent(0.55)
        row.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([divider.leadingAnchor.constraint(equalTo: info.leadingAnchor), divider.trailingAnchor.constraint(equalTo: row.trailingAnchor), divider.bottomAnchor.constraint(equalTo: row.bottomAnchor), divider.heightAnchor.constraint(equalToConstant: 1)])
        let hitArea = UIButton(type: .system)
        hitArea.backgroundColor = .clear
        row.addSubview(hitArea)
        hitArea.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([hitArea.leadingAnchor.constraint(equalTo: row.leadingAnchor), hitArea.trailingAnchor.constraint(equalTo: row.trailingAnchor), hitArea.topAnchor.constraint(equalTo: row.topAnchor), hitArea.bottomAnchor.constraint(equalTo: row.bottomAnchor)])
        hitArea.addAction(UIAction { [weak self] _ in self?.push(ChatViewController(userID: conversation.userID)) }, for: .touchUpInside)
        return row
    }

    private func shortTime(_ date: Date) -> String {
        let interval = max(0, Int(Date().timeIntervalSince(date)))
        if interval < 3600 { return "\(max(1, interval / 60))m" }
        if interval < 86400 { return "\(interval / 3600)h" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    #if DEBUG
    func visualSetActivity(_ value: Bool) { activity = value; rebuild() }
    #endif
}

final class ProfileViewController: RootPageViewController {
    private var saved = false
    override func viewDidLoad() { super.viewDidLoad(); rebuild() }
    override func rebuild() { guard let me = QRepository.shared.currentUser else { return }; body.arrangedSubviews.forEach { $0.removeFromSuperview() }; let header = profileHeader(); body.addArrangedSubview(header); body.setCustomSpacing(18, after: header); body.addArrangedSubview(profileIdentity(me)); body.setCustomSpacing(17, after: body.arrangedSubviews.last!); body.addArrangedSubview(profileStats(me)); body.setCustomSpacing(18, after: body.arrangedSubviews.last!); body.addArrangedSubview(balanceBanner()); body.setCustomSpacing(12, after: body.arrangedSubviews.last!); body.addArrangedSubview(profileTabs()); body.setCustomSpacing(19, after: body.arrangedSubviews.last!); let checkIns = QRepository.shared.visiblePosts.filter { $0.authorID == me.id }; let posts = saved ? QRepository.shared.savedPosts : checkIns; if posts.isEmpty { body.addArrangedSubview(emptyState(saved ? "No saved check-ins yet" : "No check-ins yet")) } else { posts.prefix(3).forEach { body.addArrangedSubview(profilePost($0)) } } }
    private func profileHeader() -> UIView { let row = UIView(); row.heightAnchor.constraint(equalToConstant: 36).isActive = true; let title = label("Profile", size: 27, weight: .bold); row.addSubview(title); title.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([title.leadingAnchor.constraint(equalTo: row.leadingAnchor), title.centerYAnchor.constraint(equalTo: row.centerYAnchor)]); let gear = UIButton(type: .system); gear.setImage(UIImage(systemName: "gearshape"), for: .normal); gear.tintColor = .white; gear.addAction(UIAction { [weak self] _ in self?.push(SettingsViewController()) }, for: .touchUpInside); row.addSubview(gear); gear.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([gear.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10), gear.centerYAnchor.constraint(equalTo: row.centerYAnchor), gear.widthAnchor.constraint(equalToConstant: 24), gear.heightAnchor.constraint(equalToConstant: 24)]); return row }
    private func profileIdentity(_ me: QUser) -> UIView { let row = UIView(); row.heightAnchor.constraint(equalToConstant: 98).isActive = true; let av = avatar(me.id, size: 72); row.addSubview(av); av.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([av.leadingAnchor.constraint(equalTo: row.leadingAnchor), av.topAnchor.constraint(equalTo: row.topAnchor)]); let name = label(me.name, size: 21, weight: .bold); let handle = label("@\(me.handle)", size: 11, color: QTheme.secondaryText); let bio = label(me.bio, size: 13, color: QTheme.secondaryText); let info = stack(7); [name, handle, bio].forEach { info.addArrangedSubview($0) }; row.addSubview(info); info.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([info.leadingAnchor.constraint(equalTo: av.trailingAnchor, constant: 16), info.topAnchor.constraint(equalTo: row.topAnchor, constant: 1), info.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -88)]); let edit = button("Edit profile", height: 42, filled: false); edit.layer.cornerRadius = 12; edit.titleLabel?.font = .systemFont(ofSize: 12); edit.addAction(UIAction { [weak self] _ in self?.push(EditProfileViewController()) }, for: .touchUpInside); row.addSubview(edit); edit.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([edit.trailingAnchor.constraint(equalTo: row.trailingAnchor), edit.topAnchor.constraint(equalTo: row.topAnchor), edit.widthAnchor.constraint(equalToConstant: 86)]); return row }
    private func profileStats(_ me: QUser) -> UIView {
        let wrapper = UIView()
        wrapper.heightAnchor.constraint(equalToConstant: 70).isActive = true
        let completed = QRepository.shared.visiblePosts.filter { $0.authorID == me.id }.count
        let values = [(compactCount(completed), "Completed"), (compactCount(QRepository.shared.followerCount(for: me.id)), "Followers"), (compactCount(QRepository.shared.followingCount(for: me.id)), "Following")]
        let stats = UIStackView()
        stats.axis = .horizontal
        stats.alignment = .fill
        stats.distribution = .fillEqually
        for (index, value) in values.enumerated() {
            let number = label(value.0, size: 17, weight: .semibold)
            number.textAlignment = .center
            let caption = label(value.1, size: 12, color: QTheme.mutedText)
            caption.textAlignment = .center
            let column = stack(7)
            column.alignment = .center
            column.isUserInteractionEnabled = false
            column.addArrangedSubview(number)
            column.addArrangedSubview(caption)
            let hit = UIButton(type: .system)
            hit.addSubview(column)
            column.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([column.leadingAnchor.constraint(equalTo: hit.leadingAnchor), column.trailingAnchor.constraint(equalTo: hit.trailingAnchor), column.topAnchor.constraint(equalTo: hit.topAnchor), column.bottomAnchor.constraint(equalTo: hit.bottomAnchor)])
            hit.tag = index
            if index > 0 { hit.addTarget(self, action: #selector(openRelationshipList(_:)), for: .touchUpInside) }
            let item = UIView()
            item.addSubview(hit)
            hit.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([hit.leadingAnchor.constraint(equalTo: item.leadingAnchor), hit.trailingAnchor.constraint(equalTo: item.trailingAnchor), hit.topAnchor.constraint(equalTo: item.topAnchor), hit.bottomAnchor.constraint(equalTo: item.bottomAnchor)])
            stats.addArrangedSubview(item)
            if index < values.count - 1 {
                let divider = UIView()
                divider.backgroundColor = QTheme.divider
                item.addSubview(divider)
                divider.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([divider.trailingAnchor.constraint(equalTo: item.trailingAnchor), divider.centerYAnchor.constraint(equalTo: item.centerYAnchor), divider.widthAnchor.constraint(equalToConstant: 1), divider.heightAnchor.constraint(equalToConstant: 31)])
            }
        }
        wrapper.addSubview(stats)
        stats.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([stats.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), stats.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), stats.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 11), stats.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -11)])
        let top = UIView(); top.backgroundColor = QTheme.divider; wrapper.addSubview(top); top.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([top.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), top.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), top.topAnchor.constraint(equalTo: wrapper.topAnchor), top.heightAnchor.constraint(equalToConstant: 1)])
        let bottom = UIView(); bottom.backgroundColor = QTheme.divider; wrapper.addSubview(bottom); bottom.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([bottom.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor), bottom.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor), bottom.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor), bottom.heightAnchor.constraint(equalToConstant: 1)])
        return wrapper
    }
    @objc private func openRelationshipList(_ sender: UIButton) {
        if sender.tag == 1 { push(FollowersViewController()) }
        else if sender.tag == 2 { push(FollowingViewController()) }
    }
    private func compactCount(_ value: Int) -> String { if value >= 1000 { return String(format: "%.1fk", Double(value) / 1000.0) }; return "\(value)" }
    private func balanceBanner() -> UIView { let banner = UIView(); banner.heightAnchor.constraint(equalToConstant: 90).isActive = true; banner.layer.cornerRadius = 15; banner.clipsToBounds = true; banner.isUserInteractionEnabled = true; let image = UIImageView(image: UIImage.qAsset("212e 1")); image.contentMode = .scaleAspectFill; banner.addSubview(image); image.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([image.leadingAnchor.constraint(equalTo: banner.leadingAnchor), image.trailingAnchor.constraint(equalTo: banner.trailingAnchor), image.topAnchor.constraint(equalTo: banner.topAnchor), image.bottomAnchor.constraint(equalTo: banner.bottomAnchor)]); let eyebrow = label("FAYRO BALANCE", size: 10, weight: .semibold, color: QTheme.highlight); let coins = label(QRepository.shared.walletCoins.formatted(), size: 26, weight: .bold, color: QTheme.highlight); let text = stack(2); text.addArrangedSubview(eyebrow); text.addArrangedSubview(coins); banner.addSubview(text); text.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([text.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 78), text.centerYAnchor.constraint(equalTo: banner.centerYAnchor)]); let recharge = UIButton(type: .system); recharge.setImage(UIImage.qAsset("21f12 1")?.withRenderingMode(.alwaysOriginal), for: .normal); recharge.tintColor = .clear; recharge.imageView?.contentMode = .scaleAspectFit; recharge.addAction(UIAction { [weak self] _ in self?.push(RechargeViewController()) }, for: .touchUpInside); banner.addSubview(recharge); recharge.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([recharge.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -9), recharge.centerYAnchor.constraint(equalTo: banner.centerYAnchor, constant: 17), recharge.widthAnchor.constraint(equalToConstant: 101), recharge.heightAnchor.constraint(equalToConstant: 34)]); banner.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openRecharge))); return banner }
    @objc private func openRecharge() { push(RechargeViewController()) }
    private func profileTabs() -> UIView { let tabs = UIView(); tabs.heightAnchor.constraint(equalToConstant: 46).isActive = true; let check = UIButton(type: .system); let savedButton = UIButton(type: .system); check.setTitle("Check-ins", for: .normal); savedButton.setTitle("Saved", for: .normal); [check, savedButton].forEach { $0.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold); $0.setTitleColor(QTheme.secondaryText, for: .normal) }; (saved ? savedButton : check).setTitleColor(.white, for: .normal); check.addAction(UIAction { [weak self] _ in self?.saved = false; self?.rebuild() }, for: .touchUpInside); savedButton.addAction(UIAction { [weak self] _ in self?.saved = true; self?.rebuild() }, for: .touchUpInside); let row = UIStackView(arrangedSubviews: [check, savedButton]); row.distribution = .fillEqually; tabs.addSubview(row); row.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([row.leadingAnchor.constraint(equalTo: tabs.leadingAnchor), row.trailingAnchor.constraint(equalTo: tabs.trailingAnchor), row.topAnchor.constraint(equalTo: tabs.topAnchor), row.bottomAnchor.constraint(equalTo: tabs.bottomAnchor)]); let line = UIView(); line.backgroundColor = QTheme.divider; tabs.addSubview(line); line.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([line.leadingAnchor.constraint(equalTo: tabs.leadingAnchor), line.trailingAnchor.constraint(equalTo: tabs.trailingAnchor), line.bottomAnchor.constraint(equalTo: tabs.bottomAnchor), line.heightAnchor.constraint(equalToConstant: 1)]); let selectedLine = UIView(); selectedLine.backgroundColor = QTheme.brightPurple; tabs.addSubview(selectedLine); selectedLine.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([selectedLine.widthAnchor.constraint(equalTo: tabs.widthAnchor, multiplier: 0.5), selectedLine.heightAnchor.constraint(equalToConstant: 2), selectedLine.bottomAnchor.constraint(equalTo: tabs.bottomAnchor), saved ? selectedLine.trailingAnchor.constraint(equalTo: tabs.trailingAnchor) : selectedLine.leadingAnchor.constraint(equalTo: tabs.leadingAnchor)]); return tabs }
    private func profilePost(_ post: QPost) -> UIView {
        let card = UIView()
        card.backgroundColor = QTheme.surface
        card.layer.cornerRadius = 15
        card.clipsToBounds = true
        let image = UIImageView(image: safeImage(post.mediaAssets))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.heightAnchor.constraint(equalToConstant: 383).isActive = true
        card.addSubview(image)
        image.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([image.topAnchor.constraint(equalTo: card.topAnchor), image.leadingAnchor.constraint(equalTo: card.leadingAnchor), image.trailingAnchor.constraint(equalTo: card.trailingAnchor)])
        let fade = CAGradientLayer()
        fade.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.72).cgColor]
        fade.locations = [0.55, 1]
        image.layer.addSublayer(fade)
        let more = UIButton(type: .system)
        more.setTitle("···", for: .normal)
        more.setTitleColor(.white, for: .normal)
        more.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        more.backgroundColor = UIColor.white.withAlphaComponent(0.27)
        more.layer.cornerRadius = 11
        card.addSubview(more)
        more.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([more.topAnchor.constraint(equalTo: card.topAnchor, constant: 8), more.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8), more.widthAnchor.constraint(equalToConstant: 42), more.heightAnchor.constraint(equalToConstant: 42)])
        more.isHidden = post.authorID == QRepository.shared.currentUserID
        more.addAction(UIAction { [weak self] _ in self?.openProfileMore(for: post) }, for: .touchUpInside)
        let user = QRepository.shared.user(post.authorID)
        let av = avatar(post.authorID, size: 40)
        let name = label(user?.name ?? "Unknown", size: 14, weight: .semibold)
        let meta = label("\(relativeTime(post.createdAt))", size: 11, color: QTheme.secondaryText)
        let info = stack(2); info.addArrangedSubview(name); info.addArrangedSubview(meta)
        let follow = button(QRepository.shared.followedUserIDs.contains(post.authorID) ? "Following" : "Follow", height: 42, filled: false)
        follow.widthAnchor.constraint(equalToConstant: 78).isActive = true
        follow.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        follow.layer.cornerRadius = 12
        follow.isHidden = !saved || post.authorID == QRepository.shared.currentUserID
        follow.addAction(UIAction { [weak self] _ in QRepository.shared.toggleFollow(userID: post.authorID); self?.rebuild() }, for: .touchUpInside)
        let overlay = UIStackView(arrangedSubviews: [av, info, UIView(), follow])
        overlay.spacing = 9; overlay.alignment = .center
        card.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([overlay.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14), overlay.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14), overlay.bottomAnchor.constraint(equalTo: image.bottomAnchor, constant: -14)])
        let details = UIView()
        details.backgroundColor = QTheme.surface
        details.heightAnchor.constraint(equalToConstant: 178).isActive = true
        card.addSubview(details)
        details.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([details.topAnchor.constraint(equalTo: image.bottomAnchor), details.leadingAnchor.constraint(equalTo: card.leadingAnchor), details.trailingAnchor.constraint(equalTo: card.trailingAnchor), details.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let icon = UIImageView(image: UIImage.qAsset("Text"))
        icon.contentMode = .scaleAspectFit; icon.backgroundColor = QTheme.purple.withAlphaComponent(0.18); icon.layer.cornerRadius = 17; icon.clipsToBounds = true
        icon.widthAnchor.constraint(equalToConstant: 34).isActive = true; icon.heightAnchor.constraint(equalToConstant: 34).isActive = true
        let title = label(post.title, size: 16, weight: .semibold, color: QTheme.highlight)
        let titleRow = UIStackView(arrangedSubviews: [icon, title]); titleRow.spacing = 10
        details.addSubview(titleRow); titleRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([titleRow.leadingAnchor.constraint(equalTo: details.leadingAnchor, constant: 14), titleRow.trailingAnchor.constraint(equalTo: details.trailingAnchor, constant: -14), titleRow.topAnchor.constraint(equalTo: details.topAnchor, constant: 14)])
        let desc = label(post.body, size: 14, color: QTheme.secondaryText)
        details.addSubview(desc); desc.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([desc.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor), desc.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor), desc.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 12)])
        let actions = label("♡  \(post.likes)     ◯  \(post.comments.count)     ▢  \(post.isSaved ? "Saved" : "Save")", size: 13, color: QTheme.secondaryText)
        details.addSubview(actions); actions.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([actions.leadingAnchor.constraint(equalTo: details.leadingAnchor, constant: 20), actions.bottomAnchor.constraint(equalTo: details.bottomAnchor, constant: -22)])
        let tryButton = button("Try this task", height: 44, filled: false)
        tryButton.widthAnchor.constraint(equalToConstant: 112).isActive = true; tryButton.layer.cornerRadius = 13; tryButton.layer.borderColor = QTheme.highlight.cgColor; tryButton.titleLabel?.font = .systemFont(ofSize: 13)
        tryButton.addAction(UIAction { [weak self] _ in guard let tabs = self?.tabBarController as? MainTabBarController else { return }; tabs.presentPublish(for: post) }, for: .touchUpInside)
        details.addSubview(tryButton); tryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([tryButton.trailingAnchor.constraint(equalTo: details.trailingAnchor, constant: -14), tryButton.bottomAnchor.constraint(equalTo: details.bottomAnchor, constant: -12)])
        let tap = UITapGestureRecognizer(target: self, action: #selector(openProfilePost(_:)))
        card.addGestureRecognizer(tap); card.accessibilityIdentifier = post.id
        return card
    }
    @objc private func openProfilePost(_ gesture: UITapGestureRecognizer) { guard let id = gesture.view?.accessibilityIdentifier, let post = QRepository.shared.post(id) else { return }; push(FieldNoteViewController(post: post)) }
    private func openProfileMore(for post: QPost) { showMoreSheet(for: post.authorID, report: { [weak self] in guard let self else { return }; self.push(ReportViewController(userID: post.authorID)) }, block: { [weak self] in guard let self else { return }; QRepository.shared.block(userID: post.authorID); self.rebuild() }) }
}
