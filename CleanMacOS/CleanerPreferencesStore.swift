import Foundation

final class CleanerPreferencesStore {
    private enum Keys {
        static let settings = "cleaner.settings"
        static let excludedPaths = "cleaner.excludedPaths"
        static let lastCleanupDate = "cleaner.lastCleanupDate"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSettings() -> CleanerSettings {
        guard
            let data = defaults.data(forKey: Keys.settings),
            let settings = try? JSONDecoder().decode(CleanerSettings.self, from: data)
        else {
            return CleanerSettings()
        }
        return settings
    }

    func saveSettings(_ settings: CleanerSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }

    func loadExcludedPaths() -> [String] {
        defaults.stringArray(forKey: Keys.excludedPaths) ?? []
    }

    func saveExcludedPaths(_ paths: [String]) {
        defaults.set(paths, forKey: Keys.excludedPaths)
    }

    func loadLastCleanupDate() -> Date? {
        defaults.object(forKey: Keys.lastCleanupDate) as? Date
    }

    func saveLastCleanupDate(_ date: Date?) {
        if let date {
            defaults.set(date, forKey: Keys.lastCleanupDate)
        } else {
            defaults.removeObject(forKey: Keys.lastCleanupDate)
        }
    }
}
