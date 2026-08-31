import UIKit
import StoreKit

#if canImport(SnapKit)
import SnapKit
#endif

#if canImport(IQKeyboardManagerSwift)
import IQKeyboardManagerSwift
#endif

enum QTheme {
    static let background = UIColor(hex: "0B0B0C")
    static let surface = UIColor(hex: "15171A")
    static let surfaceSecondary = UIColor(hex: "1B1D21")
    static let purple = UIColor(hex: "7F2BE8")
    static let brightPurple = UIColor(hex: "A134EF")
    static let highlight = UIColor(hex: "B778FF")
    static let text = UIColor.white
    static let secondaryText = UIColor(hex: "B6B4BC")
    static let mutedText = UIColor(hex: "85838D")
    static let divider = UIColor(hex: "2C2D33")
    static let danger = UIColor(hex: "FF5263")

    static func gradient(on view: UIView, colors: [UIColor] = [purple, brightPurple]) {
        let layer = CAGradientLayer()
        layer.colors = colors.map(\.cgColor)
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.frame = view.bounds
        layer.cornerRadius = view.layer.cornerRadius
        view.layer.insertSublayer(layer, at: 0)
    }
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1) {
        var value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if value.count == 3 { value = value.map { "\($0)\($0)" }.joined() }
        var number: UInt64 = 0
        Scanner(string: value).scanHexInt64(&number)
        self.init(red: CGFloat((number >> 16) & 0xff) / 255,
                  green: CGFloat((number >> 8) & 0xff) / 255,
                  blue: CGFloat(number & 0xff) / 255,
                  alpha: alpha)
    }
}

extension UIImage {
    static func qAsset(_ name: String) -> UIImage? { UIImage(named: name) }
}

struct QUser: Codable, Equatable {
    let id: String
    var name: String
    var handle: String
    var bio: String
    var avatarAsset: String?
    var followerCount: Int
    var followingCount: Int
    var birthday: String = ""
    var gender: String = ""
    var location: String = "London"
}

struct QComment: Codable {
    let id: String
    let authorID: String
    var text: String
    let createdAt: Date
}

struct QPost: Codable {
    let id: String
    let authorID: String
    var title: String
    var body: String
    var location: String
    var mediaAssets: [String]
    var likes: Int
    var comments: [QComment]
    var isLiked: Bool
    var isSaved: Bool
    var completed: Bool
    var createdAt: Date
    var taskID: String? = nil
}

struct QDrawTask: Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let mediaAsset: String
    let durationHours: Int
    let distanceMiles: Int?
}

enum QMessageKind: String, Codable, Equatable {
    case text
    case image
    case voice
}

struct QMessage: Codable {
    let id: String
    let authorID: String
    var text: String
    let createdAt: Date
    var kind: QMessageKind
    var mediaAsset: String?

    init(id: String, authorID: String, text: String, createdAt: Date, kind: QMessageKind = .text, mediaAsset: String? = nil) {
        self.id = id
        self.authorID = authorID
        self.text = text
        self.createdAt = createdAt
        self.kind = kind
        self.mediaAsset = mediaAsset
    }

    private enum CodingKeys: String, CodingKey { case id, authorID, text, createdAt, kind, mediaAsset }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        authorID = try values.decode(String.self, forKey: .authorID)
        text = try values.decode(String.self, forKey: .text)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        kind = try values.decodeIfPresent(QMessageKind.self, forKey: .kind) ?? .text
        mediaAsset = try values.decodeIfPresent(String.self, forKey: .mediaAsset)
    }
}

struct QConversation: Codable {
    let id: String
    let userID: String
    var ownerID: String?
    var messages: [QMessage]
    var unreadCount: Int
}

enum QActivityKind: String, Codable, Equatable {
    case like
    case comment
    case follow
}

struct QActivity: Codable {
    let id: String
    let kind: QActivityKind
    let actorID: String
    let postID: String?
    var ownerID: String?
    let createdAt: Date
}

struct QProduct {
    let id: String
    let reward: Int
    let price: String
    let index: String
}

struct QReportRecord: Codable {
    let id: String
    let targetID: String
    let reason: String
    let createdAt: Date
}

struct QAccount: Codable {
    let userID: String
    var email: String
    var password: String
}

final class QRepository {
    static let shared = QRepository()
    static let didChange = Notification.Name("QRepository.didChange")

    private let defaults = UserDefaults.standard
    private(set) var users: [QUser] = []
    private(set) var posts: [QPost] = []
    private(set) var conversations: [QConversation] = []
    private(set) var reports: [QReportRecord] = []
    private(set) var activities: [QActivity] = []
    private(set) var blockedUserIDs: Set<String> = []
    private(set) var followedUserIDs: Set<String> = []
    private var followingIDsByUserID: [String: Set<String>] = [:]
    private(set) var walletCoins: Int = 0
    private(set) var walletDiamonds: Int = 0
    private(set) var lastDrawDate: Date?
    private(set) var currentUserID: String?
    private(set) var deletedAccountIDs: Set<String> = []
    private(set) var accounts: [QAccount] = []
    private var hasSeeded = false

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() { seed() }

    var currentUser: QUser? { users.first { $0.id == currentUserID } }
    var isSignedIn: Bool { currentUserID != nil && currentUser != nil }
    var currentUserConversations: [QConversation] {
        guard let currentUserID else { return [] }
        return conversations.filter { $0.ownerID == currentUserID && !blockedUserIDs.contains($0.userID) }
    }
    var currentUserActivities: [QActivity] {
        guard let currentUserID else { return [] }
        return activities.filter { activity in
            activity.ownerID == currentUserID && users.contains(where: { $0.id == activity.actorID })
        }
    }
    var visiblePosts: [QPost] { posts.filter { !blockedUserIDs.contains($0.authorID) } }
    var followingPosts: [QPost] { visiblePosts.filter { followingIDs(for: currentUserID).contains($0.authorID) || $0.authorID == currentUserID } }
    var savedPosts: [QPost] { visiblePosts.filter { $0.isSaved && $0.authorID != currentUserID } }
    func followerCount(for userID: String) -> Int { users.reduce(into: 0) { if followingIDs(for: $1.id).contains(userID) { $0 += 1 } } }
    func followingCount(for userID: String) -> Int { followingIDs(for: userID).count }
    private func followingIDs(for userID: String?) -> Set<String> {
        guard let userID else { return [] }
        return followingIDsByUserID[userID] ?? (userID == currentUserID ? followedUserIDs : [])
    }
    var hasDrawnToday: Bool { guard let lastDrawDate else { return false }; return Date().timeIntervalSince(lastDrawDate) < 24 * 60 * 60 }
    var drawTasks: [QDrawTask] = []
    func drawTasks(durationHours: Int) -> [QDrawTask] {
        let matching = drawTasks.filter { task in
            task.durationHours <= durationHours
        }
        let fallback = drawTasks.filter { $0.durationHours <= durationHours }
        var result: [QDrawTask] = []
        for task in matching + fallback + drawTasks where !result.contains(where: { $0.id == task.id }) { result.append(task) }
        return Array(result.prefix(3))
    }
    func drawTask(id: String) -> QDrawTask? { drawTasks.first { $0.id == id } }

    func seed() {
        guard !hasSeeded else { return }
        hasSeeded = true
        let now = Date()
        users = [
            QUser(id: "me", name: "Elena Rostova", handle: "elenarostova", bio: "High-five a shadow on the wall.", avatarAsset: "72bda1ec4e72db33ba53f233656b68d6.jpg", followerCount: 3, followingCount: 1),
            QUser(id: "lucas-weber", name: "Lucas Weber", handle: "lucasweber", bio: "Show your shoes with a unique pavement texture.", avatarAsset: "2ce3699bccacbcdc4834aafb339b31ee.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "sophie-laurent", name: "Sophie Laurent", handle: "sophielaurent", bio: "Hold a warm mug in front of a view.", avatarAsset: "30fba94d9ce1e1a07ed7244eb7fbf330.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "joan-rossi", name: "Joan Rossi", handle: "joanrossi", bio: "Make a heart frame with your hands.", avatarAsset: "96a7a77524fc36b9d5deeeb6d65bd0c9.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "freja-lindqvist", name: "Freja Lindqvist", handle: "frejalindqvist", bio: "Capture your reflection in a shop window.", avatarAsset: "7f0e33781fa0c5788a69b311dff89aaa.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "arthur-pendelton", name: "Arthur Pendelton", handle: "arthurpendelton", bio: "Hold a fallen leaf against the sky.", avatarAsset: "55adb92d2f8ee8bed59851c26e6ef874.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "julian-schmidt", name: "Julian Schmidt", handle: "julianschmidt", bio: "Record a 5-second POV of walking.", avatarAsset: "c12963f850318d6f0dee91154be96297.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "nina-dupont", name: "Nina Dupont", handle: "ninadupont", bio: "Wave at the sun with your shadow.", avatarAsset: "0d01d935e3b4e116f57bace527e0d67c.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "oliver-smith", name: "Oliver Smith", handle: "oliversmith", bio: "Showcase today's outfit with city background.", avatarAsset: "d23caf1f0276f63f22bae2206d9045fe.jpg", followerCount: 0, followingCount: 0),
            QUser(id: "amelie-martin", name: "Amelie Martin", handle: "ameliemartin", bio: "Toast your drink to the sunset.", avatarAsset: nil, followerCount: 0, followingCount: 0)
        ]
        drawTasks = [
            QDrawTask(id: "TASK-001", title: "High-five a shadow on the wall", body: "Record a short video of your hand or silhouette high-fiving a cool shadow.", mediaAsset: "download (4).png", durationHours: 30, distanceMiles: nil),
            QDrawTask(id: "TASK-002", title: "Show your shoes with a unique pavement texture", body: "Step onto an interesting tile, leaf, or puddle and film your feet/shoes.", mediaAsset: "download (2).png", durationHours: 15, distanceMiles: nil),
            QDrawTask(id: "TASK-003", title: "Hold a warm mug or coffee cup in front of a view", body: "Show your hand holding a plain cup with a beautiful street or sky behind it.", mediaAsset: "download (11).png", durationHours: 30, distanceMiles: nil),
            QDrawTask(id: "TASK-004", title: "Make a heart frame with your hands around a spot", body: "Use your hands to frame a cool building corner or flower, with yourself in frame.", mediaAsset: "download (10).png", durationHours: 60, distanceMiles: nil),
            QDrawTask(id: "TASK-005", title: "Capture your reflection in a shop window or mirror", body: "Show your outfit or reflection in a clean glass window or street mirror.", mediaAsset: "download (3).png", durationHours: 90, distanceMiles: nil),
            QDrawTask(id: "TASK-006", title: "Hold a fallen leaf against the autumn sky", body: "Show your hand holding a bright maple leaf up towards the open sky.", mediaAsset: "a8336c57-d8a6-45a8-a042-0a3dcace31ec.jpg", durationHours: 30, distanceMiles: nil),
            QDrawTask(id: "TASK-007", title: "Record a 5-second POV of your feet walking", body: "Film a smooth first-person perspective (POV) of your legs/shoes walking down a street.", mediaAsset: "download (5).png", durationHours: 15, distanceMiles: nil),
            QDrawTask(id: "TASK-008", title: "Wave at the sun with your shadow on cobblestones", body: "Record your full-body shadow waving or jumping on a sunny street.", mediaAsset: "download (6).png", durationHours: 120, distanceMiles: nil),
            QDrawTask(id: "TASK-009", title: "Showcase today's outfit matching a city background", body: "Show your full body or outfit (OOTD) standing near a plain color wall or alley.", mediaAsset: "download (7).png", durationHours: 30, distanceMiles: nil),
            QDrawTask(id: "TASK-010", title: "Toast your drink to the sunset", body: "Hold up your beverage/water bottle against a glowing sunset street view.", mediaAsset: "download (8).png", durationHours: 60, distanceMiles: nil)
        ]
        posts = [
            QPost(id: "post-001", authorID: "me", title: "High-five a shadow on the wall", body: "High-fived my 5 PM shadow on the brick wall. We're both ready for the weekend.", location: "London", mediaAssets: ["0316748052e217c050d4b79ed9cb0880.jpg", "a8d4cbb2e651c735cfe8a780dcbd38e3.jpg"], likes: 0, comments: [QComment(id: "comment-001", authorID: "lucas-weber", text: "Spot on!", createdAt: now.addingTimeInterval(-3600))], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-24 * 3600), taskID: "TASK-001"),
            QPost(id: "post-002", authorID: "lucas-weber", title: "Show your shoes with a unique pavement texture", body: "Sneakers, wet cobblestones, and gold leaves. Autumn sounds like this.", location: "London", mediaAssets: ["300682874217c12dceea4e1a5b5b6c13.jpg", "7cd521c3afd09eb12af9ea179090f2f0.jpg"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-24 * 3600), taskID: "TASK-002"),
            QPost(id: "post-003", authorID: "sophie-laurent", title: "Hold a warm mug in front of a view", body: "Rainy streets, steaming mug, zero rush. My favorite 10-minute escape.", location: "London", mediaAssets: ["b0594573e6bd3f302e37944f582149d8.mp4"], likes: 0, comments: [QComment(id: "comment-003", authorID: "joan-rossi", text: "Cozy escape!", createdAt: now.addingTimeInterval(-3 * 3600))], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-18 * 3600), taskID: "TASK-003"),
            QPost(id: "post-004", authorID: "joan-rossi", title: "Make a heart frame with your hands", body: "Framed this quiet spire before the city woke up. A tiny heart for a big view.", location: "London", mediaAssets: ["ebe4d780a773078e1d8da61949f77778.mp4"], likes: 0, comments: [QComment(id: "comment-004", authorID: "freja-lindqvist", text: "Peaceful moment!", createdAt: now.addingTimeInterval(-4 * 3600))], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-12 * 3600), taskID: "TASK-004"),
            QPost(id: "post-005", authorID: "freja-lindqvist", title: "Capture your reflection in a shop window", body: "Window reflection check: trench coat on, warm lights inside, zero plans.", location: "London", mediaAssets: ["5caa4667a533bc2ccb72c4b2b623cdc7.jpg"], likes: 0, comments: [QComment(id: "comment-005", authorID: "arthur-pendelton", text: "Love this photo!", createdAt: now.addingTimeInterval(-5 * 3600))], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-24 * 3600), taskID: "TASK-005"),
            QPost(id: "post-006", authorID: "arthur-pendelton", title: "Hold a fallen leaf against the sky", body: "Holding a piece of November up to the noon sky. Still dripping with rain", location: "London", mediaAssets: ["1080964a93d071a84708d463b9fb4817.jpg"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-18 * 3600), taskID: "TASK-006"),
            QPost(id: "post-007", authorID: "julian-schmidt", title: "Record a 5-second POV of walking", body: "5 seconds of just stepping on crunchy leaves. Mute the noise for a second.", location: "London", mediaAssets: ["d8a4c64544f0daf163ca0c519454d59e.mp4"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-12 * 3600), taskID: "TASK-007"),
            QPost(id: "post-008", authorID: "nina-dupont", title: "Wave at the sun with your shadow", body: "My shadow dances way better than I do on cobblestones.", location: "London", mediaAssets: ["cbad3a7a94f4b28f2c31e9d438b36819.mp4"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-24 * 3600), taskID: "TASK-008"),
            QPost(id: "post-009", authorID: "oliver-smith", title: "Showcase today's outfit with city background", body: "Coat color matched with a 100-year-old stone wall. City coordinated.", location: "London", mediaAssets: ["0db874e32891920fdc061fea66f0491b.jpg"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-24 * 3600), taskID: "TASK-009"),
            QPost(id: "post-010", authorID: "amelie-martin", title: "Toast your drink to the sunset", body: "Clinking my water bottle to the 8 PM golden hour. Cheers to surviving today.", location: "London", mediaAssets: ["45a8e735bbc3eb643c4e18c455707078.jpg"], likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: now.addingTimeInterval(-18 * 3600), taskID: "TASK-010")
        ]
        conversations = []
        activities = []
        accounts = [QAccount(userID: "me", email: "123@gmail.com", password: "12345678")]
        if defaults.integer(forKey: "qrovoSeedVersion") < 2 {
            ["qUsers", "qPosts", "qConversations", "qActivities"].forEach { defaults.removeObject(forKey: $0) }
            defaults.set(2, forKey: "qrovoSeedVersion")
        }
        restorePersistedState()
        // Restore the wallet before migration persists the complete repository.
        // Otherwise migrateSeedContent() can write the initial in-memory zero over
        // the balance that was saved after a successful purchase.
        walletCoins = defaults.integer(forKey: "walletCoins")
        walletDiamonds = defaults.integer(forKey: "walletDiamonds")
        migrateSeedContent()
        lastDrawDate = defaults.object(forKey: "lastDrawDate") as? Date
        if lastDrawDate == nil, defaults.bool(forKey: "hasDrawnToday") { lastDrawDate = Date(); if let lastDrawDate { defaults.set(lastDrawDate, forKey: "lastDrawDate") }; defaults.removeObject(forKey: "hasDrawnToday") }
        blockedUserIDs = Set(defaults.stringArray(forKey: "blockedUserIDs") ?? [])
        deletedAccountIDs = Set(defaults.stringArray(forKey: "deletedAccountIDs") ?? [])
        if let ids = defaults.stringArray(forKey: "followedUserIDs") { followedUserIDs = Set(ids) }
        else if defaults.bool(forKey: "seedFollowed"), let followedID = defaults.string(forKey: "seedFollowedUserID") { followedUserIDs = [followedID] }
        let validUserIDs = Set(users.map(\.id))
        blockedUserIDs = blockedUserIDs.intersection(validUserIDs)
        followedUserIDs = followedUserIDs.intersection(validUserIDs)
        if let savedUserID = defaults.string(forKey: "currentUserID"), !deletedAccountIDs.contains(savedUserID), users.contains(where: { $0.id == savedUserID }) { currentUserID = savedUserID }
        else if defaults.bool(forKey: "signedIn"), !deletedAccountIDs.contains("me") { currentUserID = "me" }
        if let currentUserID {
            if followingIDsByUserID[currentUserID] == nil { followingIDsByUserID[currentUserID] = followedUserIDs }
            followedUserIDs = followingIDs(for: currentUserID)
            if accounts.first(where: { $0.userID == currentUserID })?.email.caseInsensitiveCompare("123@gmail.com") == .orderedSame {
                seedDemoRelationships(for: currentUserID)
            }
            syncRelationshipCounts()
        }
    }

    func authenticate(email: String, password: String) -> Bool {
        guard let account = accounts.first(where: { $0.email.caseInsensitiveCompare(email.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame && $0.password == password }), !deletedAccountIDs.contains(account.userID) else { return false }
        currentUserID = account.userID
        defaults.set(true, forKey: "signedIn")
        defaults.set(account.userID, forKey: "currentUserID")
        if account.email.caseInsensitiveCompare("123@gmail.com") == .orderedSame { seedDemoRelationships(for: account.userID) }
        persistAndNotify()
        return true
    }

    @discardableResult
    func register(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, !accounts.contains(where: { $0.email.lowercased() == normalized }) else { return false }
        let id = UUID().uuidString
        let handle = normalized.split(separator: "@").first.map(String.init) ?? "newuser"
        users.append(QUser(id: id, name: handle, handle: handle, bio: "", avatarAsset: nil, followerCount: 0, followingCount: 0))
        accounts.append(QAccount(userID: id, email: normalized, password: password))
        followingIDsByUserID[id] = []
        currentUserID = id
        walletCoins = 0
        followedUserIDs.removeAll()
        blockedUserIDs.removeAll()
        defaults.set(true, forKey: "signedIn")
        defaults.set(id, forKey: "currentUserID")
        defaults.set([], forKey: "followedUserIDs")
        defaults.set([], forKey: "blockedUserIDs")
        persistAndNotify()
        return true
    }

    @discardableResult
    func resetPassword(email: String, password: String) -> Bool {
        guard let index = accounts.firstIndex(where: { $0.email.caseInsensitiveCompare(email.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame }), !deletedAccountIDs.contains(accounts[index].userID) else { return false }
        accounts[index].password = password
        persistAndNotify()
        return true
    }

    func updateCurrentUser(name: String, bio: String? = nil, birthday: String? = nil, gender: String? = nil, location: String? = nil, avatarAsset: String? = nil) {
        guard let id = currentUserID, let index = users.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanName.isEmpty { users[index].name = cleanName; users[index].handle = uniqueHandle(from: cleanName, excluding: id) }
        if let bio { users[index].bio = bio.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let birthday { users[index].birthday = birthday.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let gender { users[index].gender = gender.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let location { users[index].location = location.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let avatarAsset { users[index].avatarAsset = avatarAsset }
        persistAndNotify()
    }

    func signOut() { currentUserID = nil; defaults.set(false, forKey: "signedIn"); defaults.removeObject(forKey: "currentUserID"); notify() }
    func deleteAccount() { if let id = currentUserID { deletedAccountIDs.insert(id); defaults.set(Array(deletedAccountIDs), forKey: "deletedAccountIDs") }; currentUserID = nil; defaults.set(false, forKey: "signedIn"); defaults.removeObject(forKey: "currentUserID"); persistAndNotify() }
    func setEULAAccepted() { defaults.set(true, forKey: "eulaAccepted") }
    var eulaAccepted: Bool { defaults.bool(forKey: "eulaAccepted") }

    func avatar(for userID: String, size: CGFloat) -> UIImage {
        if let asset = users.first(where: { $0.id == userID })?.avatarAsset {
            if let image = UIImage.qAsset(asset) { return image }
            if let image = UIImage(contentsOfFile: asset) { return image }
        }
        return UIImage(systemName: "person.crop.circle.fill")?.withTintColor(QTheme.mutedText, renderingMode: .alwaysOriginal) ?? UIImage()
    }

    @discardableResult
    func saveCurrentAvatar(_ image: UIImage) -> Bool {
        guard let id = currentUserID, let data = image.jpegData(compressionQuality: 0.86) else { return false }
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("QrovoAvatars", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent("\(id).jpg")
            try data.write(to: url, options: .atomic)
            updateCurrentUser(name: currentUser?.name ?? "User", avatarAsset: url.path)
            return true
        } catch { return false }
    }

    func user(_ id: String) -> QUser? { users.first { $0.id == id } }
    func post(_ id: String) -> QPost? { visiblePosts.first { $0.id == id } }
    func toggleLike(postID: String) { guard let i = posts.firstIndex(where: { $0.id == postID }) else { return }; posts[i].isLiked.toggle(); posts[i].likes = max(0, posts[i].likes + (posts[i].isLiked ? 1 : -1)); if posts[i].isLiked, let me = currentUserID, posts[i].authorID != me { recordActivity(kind: .like, actorID: me, postID: postID, recipientID: posts[i].authorID) } else { removeActivity(kind: .like, actorID: currentUserID, postID: postID, ownerID: posts[i].authorID) }; persistAndNotify() }
    func toggleSave(postID: String) { guard let i = posts.firstIndex(where: { $0.id == postID }) else { return }; posts[i].isSaved.toggle(); persistAndNotify() }
    func toggleFollow(userID: String) {
        guard let me = currentUserID, userID != me else { return }
        var following = followingIDs(for: me)
        let isFollowing = following.contains(userID)
        if isFollowing { following.remove(userID) } else { following.insert(userID) }
        followingIDsByUserID[me] = following
        followedUserIDs = following
        if let me = currentUserID {
            if isFollowing { removeActivity(kind: .follow, actorID: me, postID: nil, ownerID: userID) }
            else { recordActivity(kind: .follow, actorID: me, recipientID: userID) }
        }
        syncRelationshipCounts()
        persistAndNotify()
    }
    func canMessage(userID: String) -> Bool {
        guard let me = currentUserID, userID != me, !blockedUserIDs.contains(userID) else { return false }
        let followsUser = followingIDs(for: me).contains(userID)
        let followsMe = followingIDs(for: userID).contains(me)
        return followsUser && followsMe
    }
    func addComment(postID: String, text: String) { guard let i = posts.firstIndex(where: { $0.id == postID }), let me = currentUserID else { return }; let clean = text.trimmingCharacters(in: .whitespacesAndNewlines); guard !clean.isEmpty else { return }; posts[i].comments.append(QComment(id: UUID().uuidString, authorID: me, text: clean, createdAt: Date())); if posts[i].authorID != me { recordActivity(kind: .comment, actorID: me, postID: postID, recipientID: posts[i].authorID) }; persistAndNotify() }
    func block(userID: String) { guard let me = currentUserID, userID != me else { return }; blockedUserIDs.insert(userID); var following = followingIDs(for: me); following.remove(userID); followingIDsByUserID[me] = following; followedUserIDs = following; syncRelationshipCounts(); persistAndNotify() }
    func unblock(userID: String) { blockedUserIDs.remove(userID); persistAndNotify() }
    func report(userID: String, reason: String) {
        let record = QReportRecord(id: UUID().uuidString, targetID: userID, reason: reason, createdAt: Date())
        reports.append(record)
        persistAndNotify()
    }
    func conversation(with userID: String) -> QConversation? { conversations.first { $0.userID == userID && $0.ownerID == currentUserID && !blockedUserIDs.contains($0.userID) } }
    func appendMessage(userID: String, text: String, kind: QMessageKind = .text, mediaAsset: String? = nil) {
        guard let me = currentUserID, !blockedUserIDs.contains(userID) else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard kind != .text || !clean.isEmpty else { return }
        let message = QMessage(id: UUID().uuidString, authorID: me, text: clean, createdAt: Date(), kind: kind, mediaAsset: mediaAsset)
        if let index = conversations.firstIndex(where: { $0.userID == userID && $0.ownerID == me }) {
            conversations[index].messages.append(message)
            conversations[index].unreadCount = 0
        } else {
            conversations.insert(QConversation(id: UUID().uuidString, userID: userID, ownerID: me, messages: [message], unreadCount: 0), at: 0)
        }
        persistAndNotify()
    }
    func markConversationRead(userID: String) {
        guard let index = conversations.firstIndex(where: { $0.userID == userID && $0.ownerID == currentUserID }), conversations[index].unreadCount > 0 else { return }
        conversations[index].unreadCount = 0
        persistAndNotify()
    }
    func recordActivity(kind: QActivityKind, actorID: String, postID: String? = nil, recipientID: String? = nil) {
        guard actorID != recipientID, users.contains(where: { $0.id == actorID }), let ownerID = recipientID ?? currentUserID else { return }
        activities.insert(QActivity(id: UUID().uuidString, kind: kind, actorID: actorID, postID: postID, ownerID: ownerID, createdAt: Date()), at: 0)
        persistAndNotify()
    }
    private func removeActivity(kind: QActivityKind, actorID: String?, postID: String?, ownerID: String) {
        activities.removeAll { $0.kind == kind && $0.actorID == actorID && $0.postID == postID && $0.ownerID == ownerID }
    }
    @discardableResult
    func spendCoins(_ amount: Int) -> Bool { guard walletCoins >= amount else { return false }; walletCoins -= amount; persistWallet(); notify(); return true }
    func addCoins(_ amount: Int) { walletCoins += amount; persistWallet(); notify() }
    func addDiamonds(_ amount: Int) { walletDiamonds += amount; persistWallet(); notify() }
    func markDrawnToday() { lastDrawDate = Date(); if let lastDrawDate { defaults.set(lastDrawDate, forKey: "lastDrawDate") }; defaults.removeObject(forKey: "hasDrawnToday"); notify() }
    private func persistWallet() { defaults.set(walletCoins, forKey: "walletCoins"); defaults.set(walletDiamonds, forKey: "walletDiamonds") }
    func publish(title: String, body: String, location: String, assets: [String]) { guard let me = currentUserID else { return }; posts.insert(QPost(id: UUID().uuidString, authorID: me, title: title.trimmingCharacters(in: .whitespacesAndNewlines), body: body.trimmingCharacters(in: .whitespacesAndNewlines), location: location.trimmingCharacters(in: .whitespacesAndNewlines), mediaAssets: assets, likes: 0, comments: [], isLiked: false, isSaved: false, completed: true, createdAt: Date()), at: 0); persistAndNotify() }
    var followerUsers: [QUser] { guard let me = currentUserID else { return [] }; return users.filter { $0.id != me && followingIDs(for: $0.id).contains(me) && !blockedUserIDs.contains($0.id) } }
    var followingUsers: [QUser] { guard let me = currentUserID else { return [] }; return users.filter { followingIDs(for: me).contains($0.id) && !blockedUserIDs.contains($0.id) } }

    private func syncRelationshipCounts() {
        for index in users.indices {
            users[index].followerCount = followerCount(for: users[index].id)
            users[index].followingCount = followingCount(for: users[index].id)
        }
    }

    private func seedDemoRelationships(for userID: String) {
        guard defaults.integer(forKey: "seedRelationshipsVersion") < 2 else { return }
        let otherIDs = users.map(\.id).filter { $0 != userID }
        for otherID in otherIDs {
            followingIDsByUserID[otherID]?.remove(userID)
            activities.removeAll { $0.id == "seed-follow-\(otherID)-\(userID)" }
        }
        for otherID in otherIDs.prefix(3) {
            followingIDsByUserID[otherID, default: []].insert(userID)
            activities.append(QActivity(id: "seed-follow-\(otherID)-\(userID)", kind: .follow, actorID: otherID, postID: nil, ownerID: userID, createdAt: Date()))
        }
        var currentFollowing = followingIDs(for: userID)
        if currentFollowing.isEmpty, let firstOtherID = otherIDs.first { currentFollowing.insert(firstOtherID) }
        followingIDsByUserID[userID] = currentFollowing
        followedUserIDs = currentFollowing
        defaults.set(2, forKey: "seedRelationshipsVersion")
        syncRelationshipCounts()
        persistState()
    }

    private func uniqueHandle(from name: String, excluding userID: String) -> String {
        let base = name.lowercased().filter { $0.isLetter || $0.isNumber }
        let candidate = base.isEmpty ? "user" : base
        if !users.contains(where: { $0.id != userID && $0.handle == candidate }) { return candidate }
        return "\(candidate)\(abs(userID.hashValue) % 1000)"
    }

    private func restorePersistedState() {
        if let data = defaults.data(forKey: "qUsers"), let value = try? decoder.decode([QUser].self, from: data) { users = value }
        if let data = defaults.data(forKey: "qPosts"), let value = try? decoder.decode([QPost].self, from: data) { posts = value }
        if let data = defaults.data(forKey: "qConversations"), let value = try? decoder.decode([QConversation].self, from: data) { conversations = value }
        if let data = defaults.data(forKey: "qActivities"), let value = try? decoder.decode([QActivity].self, from: data) { activities = value }
        if let data = defaults.data(forKey: "qReports"), let value = try? decoder.decode([QReportRecord].self, from: data) { reports = value }
        if let data = defaults.data(forKey: "qAccounts"), let value = try? decoder.decode([QAccount].self, from: data) { accounts = value }
        if let value = defaults.dictionary(forKey: "followingIDsByUserID") as? [String: [String]] {
            followingIDsByUserID = value.mapValues(Set.init)
        }
    }

    private func migrateSeedContent() {
        let obsoleteUserIDs = Set(["maya", "mina-kim", "noah", "sofia"])
        users.removeAll { obsoleteUserIDs.contains($0.id) }
        posts.removeAll { ["p1", "p2", "p3"].contains($0.id) }
        conversations.removeAll { ["chat1", "chat2", "chat3"].contains($0.id) }
        activities.removeAll { ["a1", "a2", "a3"].contains($0.id) }
        followedUserIDs.subtract(obsoleteUserIDs)
        blockedUserIDs.subtract(obsoleteUserIDs)
        followingIDsByUserID = followingIDsByUserID.reduce(into: [:]) { result, pair in
            let validIDs = pair.value.subtracting(obsoleteUserIDs)
            if !obsoleteUserIDs.contains(pair.key) { result[pair.key] = validIDs }
        }
        persistState()
    }

    private func persistState() {
        if let data = try? encoder.encode(users) { defaults.set(data, forKey: "qUsers") }
        if let data = try? encoder.encode(posts) { defaults.set(data, forKey: "qPosts") }
        if let data = try? encoder.encode(conversations) { defaults.set(data, forKey: "qConversations") }
        if let data = try? encoder.encode(activities) { defaults.set(data, forKey: "qActivities") }
        if let data = try? encoder.encode(reports) { defaults.set(data, forKey: "qReports") }
        if let data = try? encoder.encode(accounts) { defaults.set(data, forKey: "qAccounts") }
        defaults.set(Array(followedUserIDs), forKey: "followedUserIDs")
        defaults.set(Array(blockedUserIDs), forKey: "blockedUserIDs")
        defaults.set(followingIDsByUserID.mapValues(Array.init), forKey: "followingIDsByUserID")
        persistWallet()
    }
    private func persistAndNotify() { persistState(); notify() }
    private func notify() { NotificationCenter.default.post(name: Self.didChange, object: nil) }
}

final class QStoreKitManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    static let shared = QStoreKitManager()
    static let testProductIDs = ["lvbsvhxcgcrvesor", "dxismgcwewhrtezo", "khtxlcejaxmqcsra", "yadwwvxspgxwlnd", "qnrcuelbtiuflyky", "ymohxnvpkqxutvab"]
    private(set) var products: [SKProduct] = []
    var onProductsChanged: (() -> Void)?
    var onPurchase: ((String, Bool) -> Void)?
    private var request: SKProductsRequest?
    private override init() { super.init(); SKPaymentQueue.default().add(self) }

    private var configuredProductIDs: [String] {
        if let ids = Bundle.main.object(forInfoDictionaryKey: "QrovoProductIDs") as? [String], !ids.isEmpty { return ids }
        return Self.testProductIDs
    }

    private let rewards = [400, 800, 2450, 5150, 6400, 10800, 14900, 29400, 39500, 63700]
    private let prices = ["US$0.99", "US$1.99", "US$4.99", "US$9.99", "US$12.99", "US$19.99", "US$24.99", "US$49.99", "US$79.99", "US$99.99"]

    func loadProducts() {
        request?.cancel()
        request = SKProductsRequest(productIdentifiers: Set(configuredProductIDs))
        request?.delegate = self
        request?.start()
    }
    func productsRequest(_ request: SKProductsRequest, didFailWithError error: Error) { products = []; DispatchQueue.main.async { self.onProductsChanged?() } }
    func catalogProducts() -> [QProduct] {
        let returnedIDs = Set(products.map(\.productIdentifier))
        return configuredProductIDs.enumerated().compactMap { index, id in
            guard returnedIDs.contains(id) else { return nil }
            guard rewards.indices.contains(index), prices.indices.contains(index) else { return nil }
            return QProduct(id: id, reward: rewards[index], price: prices[index], index: String(format: "%02d", index + 1))
        }
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) { products = response.products.sorted { $0.productIdentifier < $1.productIdentifier }; DispatchQueue.main.async { self.onProductsChanged?() } }
    func buy(product: SKProduct) { guard SKPaymentQueue.canMakePayments() else { onPurchase?(product.productIdentifier, false); return }; SKPaymentQueue.default().add(SKPayment(product: product)) }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                queue.finishTransaction(transaction)
                if let index = configuredProductIDs.firstIndex(of: transaction.payment.productIdentifier), rewards.indices.contains(index) { QRepository.shared.addCoins(rewards[index]) }
                onPurchase?(transaction.payment.productIdentifier, true)
            case .failed:
                queue.finishTransaction(transaction); onPurchase?(transaction.payment.productIdentifier, false)
            case .restored:
                queue.finishTransaction(transaction)
            default: break
            }
        }
    }
}

extension CALayer {
    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
        let border = CALayer(); border.backgroundColor = color.cgColor
        switch edge {
        case .top: border.frame = CGRect(x: 0, y: 0, width: bounds.width, height: thickness)
        case .bottom: border.frame = CGRect(x: 0, y: bounds.height - thickness, width: bounds.width, height: thickness)
        case .left: border.frame = CGRect(x: 0, y: 0, width: thickness, height: bounds.height)
        case .right: border.frame = CGRect(x: bounds.width - thickness, y: 0, width: thickness, height: bounds.height)
        default: return
        }
        addSublayer(border)
    }
}

final class QGradientButton: UIButton {
    private let gradient = CAGradientLayer()
    override init(frame: CGRect) { super.init(frame: frame); gradient.colors = [QTheme.purple.cgColor, QTheme.brightPurple.cgColor]; gradient.startPoint = CGPoint(x: 0, y: 0.5); gradient.endPoint = CGPoint(x: 1, y: 0.5); layer.insertSublayer(gradient, at: 0) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override func layoutSubviews() { super.layoutSubviews(); gradient.frame = bounds; gradient.cornerRadius = layer.cornerRadius }
}

final class QGradientView: UIView {
    let gradient = CAGradientLayer()
    init(colors: [UIColor]) { super.init(frame: .zero); gradient.colors = colors.map(\.cgColor); gradient.startPoint = CGPoint(x: 0, y: 0.5); gradient.endPoint = CGPoint(x: 1, y: 0.5); layer.insertSublayer(gradient, at: 0) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override func layoutSubviews() { super.layoutSubviews(); gradient.frame = bounds; gradient.cornerRadius = layer.cornerRadius }
}

class QViewController: UIViewController {
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = QTheme.background; navigationController?.setNavigationBarHidden(true, animated: false) }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    func label(_ text: String = "", size: CGFloat = 16, weight: UIFont.Weight = .regular, color: UIColor = QTheme.text) -> UILabel { let v = UILabel(); v.text = text; v.textColor = color; v.font = .systemFont(ofSize: size, weight: weight); v.numberOfLines = 0; return v }
    func button(_ title: String, height: CGFloat = 52, filled: Bool = true) -> UIButton { let b = QGradientButton(frame: .zero); b.setTitle(title, for: .normal); b.setTitleColor(filled ? .white : QTheme.text, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold); b.backgroundColor = .clear; b.layer.cornerRadius = 12; b.layer.borderWidth = filled ? 0 : 1; b.layer.borderColor = QTheme.divider.cgColor; b.heightAnchor.constraint(equalToConstant: height).isActive = true; if !filled { b.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() } }; return b }
    func navHeader(_ title: String, right: UIButton? = nil) -> UIView { let v = UIView(); let back = UIButton(type: .system); back.setImage(UIImage(systemName: "chevron.left"), for: .normal); back.tintColor = .white; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); v.addSubview(back); back.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([back.leadingAnchor.constraint(equalTo: v.leadingAnchor), back.centerYAnchor.constraint(equalTo: v.centerYAnchor), back.widthAnchor.constraint(equalToConstant: 32), back.heightAnchor.constraint(equalToConstant: 40)]); let t = label(title, size: 18, weight: .semibold); v.addSubview(t); t.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([t.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 10), t.centerYAnchor.constraint(equalTo: v.centerYAnchor)]); if let right { v.addSubview(right); right.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([right.trailingAnchor.constraint(equalTo: v.trailingAnchor), right.centerYAnchor.constraint(equalTo: v.centerYAnchor)]) }; v.heightAnchor.constraint(equalToConstant: 48).isActive = true; return v }
    func scrollView() -> (UIScrollView, UIView) { let s = UIScrollView(); s.alwaysBounceVertical = true; s.keyboardDismissMode = .interactive; let c = UIView(); s.addSubview(c); s.translatesAutoresizingMaskIntoConstraints = false; c.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([c.leadingAnchor.constraint(equalTo: s.contentLayoutGuide.leadingAnchor), c.trailingAnchor.constraint(equalTo: s.contentLayoutGuide.trailingAnchor), c.topAnchor.constraint(equalTo: s.contentLayoutGuide.topAnchor), c.bottomAnchor.constraint(equalTo: s.contentLayoutGuide.bottomAnchor), c.widthAnchor.constraint(equalTo: s.frameLayoutGuide.widthAnchor)]); return (s, c) }
    func add(_ subviews: [UIView], to stack: UIStackView) { subviews.forEach { stack.addArrangedSubview($0) } }
    func stack(_ spacing: CGFloat = 16) -> UIStackView { let s = UIStackView(); s.axis = .vertical; s.spacing = spacing; s.alignment = .fill; return s }
    func textField(_ placeholder: String, secure: Bool = false) -> UITextField { let f = UITextField(); f.placeholder = placeholder; f.textColor = .white; f.tintColor = QTheme.highlight; f.font = .systemFont(ofSize: 15); f.backgroundColor = QTheme.surface; f.layer.cornerRadius = 10; f.layer.borderWidth = 1; f.layer.borderColor = QTheme.divider.cgColor; f.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1)); f.leftViewMode = .always; f.heightAnchor.constraint(equalToConstant: 42).isActive = true; f.isSecureTextEntry = secure; return f }
    func avatar(_ userID: String, size: CGFloat = 44) -> UIImageView { let v = UIImageView(image: QRepository.shared.avatar(for: userID, size: size)); v.contentMode = .scaleAspectFill; v.layer.cornerRadius = size / 2; v.clipsToBounds = true; v.layer.borderWidth = 1; v.layer.borderColor = QTheme.highlight.withAlphaComponent(0.6).cgColor; v.translatesAutoresizingMaskIntoConstraints = false; v.widthAnchor.constraint(equalToConstant: size).isActive = true; v.heightAnchor.constraint(equalToConstant: size).isActive = true; return v }
    func assetImage(_ name: String) -> UIImage? { UIImage.qAsset(name) ?? UIImage(contentsOfFile: name) ?? UIImage.qAsset("default_photo") }
    func relativeTime(_ date: Date) -> String { let seconds = max(0, Int(Date().timeIntervalSince(date))); if seconds < 60 { return "now" }; if seconds < 3600 { return "\(seconds / 60)m ago" }; if seconds < 86400 { return "\(seconds / 3600)h ago" }; return "\(seconds / 86400)d ago" }
    func formattedDate(_ date: Date) -> String { let formatter = DateFormatter(); formatter.dateFormat = "d MMM yyyy 'at' HH:mm"; return formatter.string(from: date) }
    func showMessage(_ title: String, _ message: String, action: String = "OK", handler: (() -> Void)? = nil) { let alert = QAlertViewController(titleText: title, messageText: message, cancelTitle: nil, confirmTitle: action) { handler?() }; alert.modalPresentationStyle = .overFullScreen; alert.modalTransitionStyle = .crossDissolve; present(alert, animated: true) }
    func showConfirm(_ title: String, _ message: String, confirm: String = "Confirm", handler: @escaping () -> Void) { let alert = QAlertViewController(titleText: title, messageText: message, cancelTitle: "Cancel", confirmTitle: confirm, onConfirm: handler); alert.modalPresentationStyle = .overFullScreen; alert.modalTransitionStyle = .crossDissolve; present(alert, animated: true) }
    func showMoreSheet(for userID: String, report: @escaping () -> Void, block: @escaping () -> Void) {
        guard userID != QRepository.shared.currentUserID else { return }
        let sheet = QMoreSheetViewController(onReport: report, onBlock: block)
        sheet.modalPresentationStyle = .overFullScreen
        sheet.modalTransitionStyle = .crossDissolve
        present(sheet, animated: true)
    }
}

final class QAlertViewController: UIViewController {
    private let titleText: String; private let messageText: String; private let cancelTitle: String?; private let confirmTitle: String; private let onConfirm: () -> Void
    init(titleText: String, messageText: String, cancelTitle: String?, confirmTitle: String, onConfirm: @escaping () -> Void) { self.titleText = titleText; self.messageText = messageText; self.cancelTitle = cancelTitle; self.confirmTitle = confirmTitle; self.onConfirm = onConfirm; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.64); let card = UIView(); card.backgroundColor = UIColor(hex: "1A1740"); card.layer.cornerRadius = 24; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; card.clipsToBounds = true; view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)]); let bg = UIImageView(image: UIImage.qAsset("alert_bg")); bg.contentMode = .scaleAspectFill; bg.alpha = 0.8; card.addSubview(bg); bg.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([bg.leadingAnchor.constraint(equalTo: card.leadingAnchor), bg.trailingAnchor.constraint(equalTo: card.trailingAnchor), bg.topAnchor.constraint(equalTo: card.topAnchor), bg.bottomAnchor.constraint(equalTo: card.bottomAnchor)]); let grab = UIView(); grab.backgroundColor = UIColor.white.withAlphaComponent(0.35); grab.layer.cornerRadius = 2; card.addSubview(grab); grab.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([grab.topAnchor.constraint(equalTo: card.topAnchor, constant: 9), grab.centerXAnchor.constraint(equalTo: card.centerXAnchor), grab.widthAnchor.constraint(equalToConstant: 36), grab.heightAnchor.constraint(equalToConstant: 5)]); let title = UILabel(); title.text = titleText; title.textColor = .white; title.font = .systemFont(ofSize: 22, weight: .bold); title.textAlignment = .center; title.numberOfLines = 0; title.setContentHuggingPriority(.required, for: .vertical); title.setContentCompressionResistancePriority(.required, for: .vertical); let message = UILabel(); message.text = messageText; message.textColor = UIColor(hex: "B8B4C2"); message.font = .systemFont(ofSize: 16); message.textAlignment = .center; message.numberOfLines = 0; message.setContentHuggingPriority(.required, for: .vertical); message.setContentCompressionResistancePriority(.required, for: .vertical); let buttons = UIStackView(); buttons.axis = .horizontal; buttons.spacing = 8; buttons.distribution = .fillEqually; if let cancelTitle { let cancel = alertButton(cancelTitle, filled: false); cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside); buttons.addArrangedSubview(cancel) }; let confirm = alertButton(confirmTitle, filled: true); confirm.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true, completion: self?.onConfirm) }, for: .touchUpInside); buttons.addArrangedSubview(confirm); let stack = UIStackView(arrangedSubviews: [title, message, buttons]); stack.axis = .vertical; stack.spacing = 0; stack.setCustomSpacing(16, after: title); stack.setCustomSpacing(20, after: message); card.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20), stack.topAnchor.constraint(equalTo: grab.bottomAnchor, constant: 22), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -18)]); buttons.heightAnchor.constraint(equalToConstant: 44).isActive = true }
    private func alertButton(_ title: String, filled: Bool) -> UIButton { let b = QGradientButton(frame: .zero); b.setTitle(title, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium); b.setTitleColor(.white, for: .normal); b.layer.cornerRadius = 8; b.layer.borderWidth = filled ? 0 : 1; b.layer.borderColor = UIColor.white.cgColor; if !filled { b.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }; b.backgroundColor = .clear }; return b }
}

final class QMoreSheetViewController: UIViewController {
    private let onReport: () -> Void
    private let onBlock: () -> Void
    init(onReport: @escaping () -> Void, onBlock: @escaping () -> Void) { self.onReport = onReport; self.onBlock = onBlock; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.64)
        let card = UIView(); card.backgroundColor = UIColor(hex: "1A1740"); card.layer.cornerRadius = 18; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; card.clipsToBounds = true
        view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
        let background = UIImageView(image: UIImage.qAsset("alert_bg")); background.contentMode = .scaleAspectFill; background.alpha = 0.8; card.addSubview(background); background.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([background.leadingAnchor.constraint(equalTo: card.leadingAnchor), background.trailingAnchor.constraint(equalTo: card.trailingAnchor), background.topAnchor.constraint(equalTo: card.topAnchor), background.bottomAnchor.constraint(equalTo: card.bottomAnchor)])
        let grab = UIView(); grab.backgroundColor = UIColor.white.withAlphaComponent(0.35); grab.layer.cornerRadius = 2; card.addSubview(grab); grab.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([grab.topAnchor.constraint(equalTo: card.topAnchor, constant: 8), grab.centerXAnchor.constraint(equalTo: card.centerXAnchor), grab.widthAnchor.constraint(equalToConstant: 38), grab.heightAnchor.constraint(equalToConstant: 4)])
        let buttons = UIStackView(); buttons.axis = .vertical; buttons.spacing = 8
        let report = sheetButton("Report", color: .white); report.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true, completion: self?.onReport) }, for: .touchUpInside)
        let block = sheetButton("Block", color: QTheme.danger); block.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true, completion: self?.onBlock) }, for: .touchUpInside)
        let cancel = sheetButton("Cancel", color: QTheme.secondaryText); cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        [report, block, cancel].forEach { buttons.addArrangedSubview($0) }
        card.addSubview(buttons); buttons.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([buttons.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16), buttons.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16), buttons.topAnchor.constraint(equalTo: grab.bottomAnchor, constant: 20), buttons.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16)])
    }
    private func sheetButton(_ title: String, color: UIColor) -> UIButton { let b = UIButton(type: .system); b.setTitle(title, for: .normal); b.setTitleColor(color, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold); b.backgroundColor = UIColor.white.withAlphaComponent(0.05); b.layer.cornerRadius = 12; b.layer.borderWidth = 1; b.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor; b.heightAnchor.constraint(equalToConstant: 48).isActive = true; return b }
}

final class AppCoordinator {
    static let shared = AppCoordinator()
    weak var window: UIWindow?
    func start(window: UIWindow) {
        self.window = window
        let root: UIViewController = QRepository.shared.isSignedIn ? MainTabBarController() : UINavigationController(rootViewController: LandingViewController())
        window.rootViewController = root
        window.makeKeyAndVisible()
        if !QRepository.shared.eulaAccepted { DispatchQueue.main.async { self.presentEULA() } }
    }
    func presentEULA() { guard let root = window?.rootViewController else { return }; let eula = EULAViewController(); eula.modalPresentationStyle = .overFullScreen; root.present(eula, animated: false) }
    func showAuth() { window?.rootViewController = UINavigationController(rootViewController: LandingViewController()) }
    func showMain() { window?.rootViewController = MainTabBarController() }
}

#if DEBUG
extension QRepository {
    func visualResetState() {
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "app.myfy.test")
        hasSeeded = false
        seed()
        blockedUserIDs.removeAll()
        followedUserIDs.removeAll()
        followingIDsByUserID.removeAll()
        reports.removeAll()
        deletedAccountIDs.removeAll()
        walletCoins = 0
        walletDiamonds = 0
        defaults.set(0, forKey: "walletCoins")
        defaults.set(0, forKey: "walletDiamonds")
        defaults.set(false, forKey: "eulaAccepted")
        defaults.set(false, forKey: "signedIn")
        defaults.removeObject(forKey: "seedFollowed")
        defaults.removeObject(forKey: "seedFollowedUserID")
        defaults.removeObject(forKey: "seedRelationshipsV1")
        ["qUsers", "qPosts", "qConversations", "qActivities", "qReports", "qAccounts", "currentUserID", "followedUserIDs", "followingIDsByUserID"].forEach { defaults.removeObject(forKey: $0) }
        if let myIndex = users.firstIndex(where: { $0.id == "me" }) {
            users[myIndex].followerCount = 1800
            users[myIndex].followingCount = 318
        }
    }

    func visualSetSignedIn(_ value: Bool) {
        if value {
            currentUserID = "me"
            defaults.set(true, forKey: "signedIn")
            notify()
        } else {
            currentUserID = nil
            defaults.set(false, forKey: "signedIn")
            notify()
        }
    }

    func visualSetEULAAccepted(_ value: Bool) {
        defaults.set(value, forKey: "eulaAccepted")
    }

    func visualSetCoins(_ value: Int) {
        walletCoins = value
        defaults.set(value, forKey: "walletCoins")
        notify()
    }

    func visualSetBlocked(_ ids: [String]) {
        blockedUserIDs = Set(ids)
        defaults.set(Array(blockedUserIDs), forKey: "blockedUserIDs")
        notify()
    }

    func visualSetFollowed(_ ids: [String]) {
        followedUserIDs = Set(ids)
        if let currentUserID { followingIDsByUserID[currentUserID] = followedUserIDs }
        defaults.set(!ids.isEmpty, forKey: "seedFollowed")
        defaults.set(ids.first, forKey: "seedFollowedUserID")
        notify()
    }

    func visualSetConversationMessages(_ userID: String, messages: [QMessage]) {
        guard let ownerID = currentUserID else { return }
        if let index = conversations.firstIndex(where: { $0.userID == userID && $0.ownerID == ownerID }) {
            conversations[index].messages = messages
        } else {
            conversations.append(QConversation(id: UUID().uuidString, userID: userID, ownerID: ownerID, messages: messages, unreadCount: 0))
        }
        notify()
    }
}
#endif

final class EULAViewController: QViewController {
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.68); let card = UIView(); card.backgroundColor = QTheme.surface; card.layer.cornerRadius = 24; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; card.clipsToBounds = true; view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor)]); let background = UIImageView(image: UIImage.qAsset("alert_bg")); background.contentMode = .scaleAspectFill; background.alpha = 0.42; card.addSubview(background); background.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([background.leadingAnchor.constraint(equalTo: card.leadingAnchor), background.trailingAnchor.constraint(equalTo: card.trailingAnchor), background.topAnchor.constraint(equalTo: card.topAnchor), background.bottomAnchor.constraint(equalTo: card.bottomAnchor)]); let grabber = UIView(); grabber.backgroundColor = QTheme.mutedText; grabber.layer.cornerRadius = 3; card.addSubview(grabber); grabber.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([grabber.topAnchor.constraint(equalTo: card.topAnchor, constant: 9), grabber.centerXAnchor.constraint(equalTo: card.centerXAnchor), grabber.widthAnchor.constraint(equalToConstant: 36), grabber.heightAnchor.constraint(equalToConstant: 5)]); let title = label("EULA", size: 26, weight: .bold); title.textAlignment = .center; let text = label("Welcome to Qrovo! To create a positive, safe and standardized space for beauty and makeup sharing, the following content is strictly prohibited on the app:\n\n1. Any content involving child harm, pornography and other materials detrimental to minors’ physical and mental health, including but not limited to texts, images, videos or comments that insult, defame or improperly use minors’ portraits and information.\n\n2. False and harmful public information, including false content generated by AI or other means that disrupts public order, especially fake beauty tutorials, misleading skincare and makeup guidance, and false public opinion content.\n\n3. Violent content, cyber bullying, and any content that promotes pornography, illegal acts or disrupts the network ecological environment.", size: 12, color: QTheme.secondaryText); text.textAlignment = .center; text.numberOfLines = 0; let cancel = button("Cancel", height: 48, filled: false); let publish = button("Publish", height: 48); let buttons = UIStackView(arrangedSubviews: [cancel, publish]); buttons.axis = .horizontal; buttons.spacing = 8; buttons.distribution = .fillEqually; let stack = UIStackView(arrangedSubviews: [title, text, buttons]); stack.axis = .vertical; stack.spacing = 14; card.addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24), stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24), stack.topAnchor.constraint(equalTo: grabber.bottomAnchor, constant: 22), stack.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -18)]); cancel.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside); publish.addAction(UIAction { [weak self] _ in QRepository.shared.setEULAAccepted(); self?.dismiss(animated: false) }, for: .touchUpInside) }
}

private final class EULAViewControllerLegacy: QViewController {
    override func viewDidLoad() { super.viewDidLoad(); view.backgroundColor = UIColor.black.withAlphaComponent(0.74); let card = UIView(); card.backgroundColor = QTheme.surface; card.layer.cornerRadius = 24; card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]; view.addSubview(card); card.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([card.leadingAnchor.constraint(equalTo: view.leadingAnchor), card.trailingAnchor.constraint(equalTo: view.trailingAnchor), card.bottomAnchor.constraint(equalTo: view.bottomAnchor), card.heightAnchor.constraint(equalToConstant: 488)]); let grab = UIView(); grab.backgroundColor = QTheme.mutedText; grab.layer.cornerRadius = 3; card.addSubview(grab); grab.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([grab.topAnchor.constraint(equalTo: card.topAnchor, constant: 9), grab.centerXAnchor.constraint(equalTo: card.centerXAnchor), grab.widthAnchor.constraint(equalToConstant: 36), grab.heightAnchor.constraint(equalToConstant: 5)]); let title = label("EULA", size: 26, weight: .bold); title.textAlignment = .center; let text = label("Welcome to Zislia! To create a positive, safe and standardized space for beauty and makeup sharing, the following content is strictly prohibited on the app:\n\n1. Any content involving child harm, pornography and other materials detrimental to minors’ physical and mental health, including but not limited to texts, images, videos or comments that insult, defame or improperly use minors’ portraits and information.\n\n2. False and harmful public information, including false content generated by AI or other means that disrupts public order, especially fake beauty tutorials, misleading skincare and makeup guidance, and false public opinion content.\n\n3. Violent content, cyber bullying, and any content that promotes pornography, illegal acts or disrupts the network ecological environment.", size: 12, color: QTheme.secondaryText); text.text = text.text?.replacingOccurrences(of: "Zislia", with: "Qrovo"); text.textAlignment = .center; let buttons = UIStackView(); buttons.axis = .horizontal; buttons.spacing = 8; let cancel = button("Cancel", height: 44, filled: false); let publish = button("Publish", height: 44); buttons.addArrangedSubview(cancel); buttons.addArrangedSubview(publish); let s = stack(14); s.alignment = .fill; [title, text, buttons].forEach { s.addArrangedSubview($0) }; card.addSubview(s); s.translatesAutoresizingMaskIntoConstraints = false; NSLayoutConstraint.activate([s.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20), s.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20), s.topAnchor.constraint(equalTo: grab.bottomAnchor, constant: 20), s.bottomAnchor.constraint(lessThanOrEqualTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -14)]); cancel.addAction(UIAction { _ in exit(0) }, for: .touchUpInside); publish.addAction(UIAction { [weak self] _ in QRepository.shared.setEULAAccepted(); self?.dismiss(animated: false) }, for: .touchUpInside) }
}
