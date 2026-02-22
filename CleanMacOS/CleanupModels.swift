import Foundation

enum CleanupRiskLevel: String, Codable, CaseIterable, Identifiable {
    case safe
    case optional

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .safe: "Güvenli"
        case .optional: "Opsiyonel"
        }
    }
}

enum CleanupCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case userCaches
    case userLogs
    case trash
    case xcodeDerivedData
    case iosSimulators
    case homebrewCache
    case browserCaches
    case largeFiles

    nonisolated var id: String { rawValue }

    nonisolated var title: String {
        switch self {
        case .userCaches: "Kullanıcı Önbellekleri"
        case .userLogs: "Günlükler"
        case .trash: "Çöp Kutusu"
        case .xcodeDerivedData: "Xcode DerivedData"
        case .iosSimulators: "iOS Simülatörleri"
        case .homebrewCache: "Homebrew Önbelleği"
        case .browserCaches: "Tarayıcı Önbelleği"
        case .largeFiles: "Büyük Dosya Taraması"
        }
    }

    nonisolated var details: String {
        switch self {
        case .userCaches: "~/Library/Caches altındaki kullanıcı önbellek dosyaları"
        case .userLogs: "~/Library/Logs altındaki günlük dosyaları"
        case .trash: "~/.Trash içeriği"
        case .xcodeDerivedData: "Xcode derleme artifaktları"
        case .iosSimulators: "CoreSimulator cihaz verileri"
        case .homebrewCache: "Homebrew indirme önbelleği"
        case .browserCaches: "Safari / Chrome / Edge önbellek klasörleri"
        case .largeFiles: "Desktop/Documents/Downloads altında büyük dosya raporu"
        }
    }

    nonisolated var risk: CleanupRiskLevel {
        switch self {
        case .userCaches, .userLogs, .trash, .xcodeDerivedData, .iosSimulators, .homebrewCache:
            .safe
        case .browserCaches, .largeFiles:
            .optional
        }
    }

    nonisolated var warning: String {
        switch self {
        case .browserCaches:
            "Tarayıcı oturumları ve ilk açılış süresi etkilenebilir."
        case .iosSimulators:
            "Simülatör cihazları sıfırlanır, yeniden oluşturma gerekir."
        case .largeFiles:
            "Bu kategori silme yapmaz, sadece raporlar."
        default:
            ""
        }
    }

    nonisolated var isPreviewOnly: Bool {
        self == .largeFiles
    }

    nonisolated var defaultSelected: Bool {
        risk == .safe
    }

    nonisolated var roots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .userCaches:
            return [home.appendingPathComponent("Library/Caches", isDirectory: true)]
        case .userLogs:
            return [home.appendingPathComponent("Library/Logs", isDirectory: true)]
        case .trash:
            return [home.appendingPathComponent(".Trash", isDirectory: true)]
        case .xcodeDerivedData:
            return [home.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true)]
        case .iosSimulators:
            return [home.appendingPathComponent("Library/Developer/CoreSimulator/Devices", isDirectory: true)]
        case .homebrewCache:
            return [home.appendingPathComponent("Library/Caches/Homebrew", isDirectory: true)]
        case .browserCaches:
            return [
                home.appendingPathComponent("Library/Caches/Google/Chrome", isDirectory: true),
                home.appendingPathComponent("Library/Caches/com.apple.Safari", isDirectory: true),
                home.appendingPathComponent("Library/Caches/Microsoft Edge", isDirectory: true)
            ]
        case .largeFiles:
            return [
                home.appendingPathComponent("Desktop", isDirectory: true),
                home.appendingPathComponent("Documents", isDirectory: true),
                home.appendingPathComponent("Downloads", isDirectory: true)
            ]
        }
    }

    nonisolated static var safePreset: Set<CleanupCategory> {
        Set(allCases.filter(\.defaultSelected))
    }
}

struct CleanupTarget: Identifiable, Hashable {
    let id = UUID()
    let category: CleanupCategory
    let url: URL
    let sizeBytes: Int64
    let fileCount: Int

    nonisolated var displayPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if url.path.hasPrefix(home) {
            return "~" + String(url.path.dropFirst(home.count))
        }
        return url.path
    }
}

struct CleanupPlan {
    var generatedAt: Date
    var targets: [CleanupTarget]
    var notes: [String]

    static let empty = CleanupPlan(generatedAt: .now, targets: [], notes: [])

    nonisolated var totalBytes: Int64 {
        targets.reduce(0) { $0 + $1.sizeBytes }
    }

    nonisolated var categoryTotals: [CleanupCategory: Int64] {
        targets.reduce(into: [CleanupCategory: Int64]()) { result, target in
            result[target.category, default: 0] += target.sizeBytes
        }
    }

    nonisolated var sortedTargets: [CleanupTarget] {
        targets.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}

struct CleanupFailure: Identifiable {
    let id = UUID()
    let path: String
    let reason: String
}

struct CleanupExecutionResult {
    var startedAt: Date
    var finishedAt: Date
    var deletedTargetCount: Int
    var deletedFileCount: Int
    var estimatedFreedBytes: Int64
    var actualFreedBytes: Int64
    var previewOnlySkipped: Int
    var failures: [CleanupFailure]
    var logLines: [String]

    static let empty = CleanupExecutionResult(
        startedAt: .now,
        finishedAt: .now,
        deletedTargetCount: 0,
        deletedFileCount: 0,
        estimatedFreedBytes: 0,
        actualFreedBytes: 0,
        previewOnlySkipped: 0,
        failures: [],
        logLines: []
    )
}

struct CleanerSettings: Codable {
    var onlySafeAreas: Bool = true
    var requestRootAccess: Bool = false
    var keepRunLog: Bool = true
}
