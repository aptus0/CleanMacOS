import Combine
import Foundation

enum CleanerTab: Hashable {
    case dashboard
    case categories
    case preview
    case settings
}

@MainActor
final class CleanerViewModel: ObservableObject {
    @Published var settings: CleanerSettings {
        didSet {
            preferences.saveSettings(settings)
            if settings.onlySafeAreas {
                selectedCategories = selectedCategories.filter { $0.risk == .safe }
            }
        }
    }

    @Published var selectedCategories: Set<CleanupCategory>
    @Published var excludedPaths: [String] {
        didSet {
            preferences.saveExcludedPaths(excludedPaths)
        }
    }

    @Published var currentPlan: CleanupPlan = .empty
    @Published var lastResult: CleanupExecutionResult?
    @Published var lastCleanupDate: Date?
    @Published var dashboardEstimateBytes: Int64 = 0
    @Published var terminalOutput: [String] = []

    @Published var isScanning: Bool = false
    @Published var isExecuting: Bool = false
    @Published var statusMessage: String?

    private let engine: CleanupEngine
    private let preferences: CleanerPreferencesStore

    init(
        engine: CleanupEngine = CleanupEngine(),
        preferences: CleanerPreferencesStore? = nil
    ) {
        self.engine = engine
        self.preferences = preferences ?? CleanerPreferencesStore()

        let storedSettings = self.preferences.loadSettings()
        self.settings = storedSettings

        self.selectedCategories = CleanupCategory.safePreset

        self.excludedPaths = self.preferences.loadExcludedPaths()
        self.lastCleanupDate = self.preferences.loadLastCleanupDate()

        Task {
            await refreshDashboardEstimate()
        }
    }

    var categories: [CleanupCategory] {
        CleanupCategory.allCases.sorted { $0.title < $1.title }
    }

    var effectiveSelectedCategories: Set<CleanupCategory> {
        if settings.onlySafeAreas {
            return selectedCategories.filter { $0.risk == .safe }
        }
        return selectedCategories
    }

    func setCategory(_ category: CleanupCategory, selected: Bool) {
        guard !settings.onlySafeAreas || category.risk == .safe else { return }

        if selected {
            selectedCategories.insert(category)
        } else {
            selectedCategories.remove(category)
        }
    }

    func addExcludedPath(_ path: String) {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !excludedPaths.contains(trimmed) else { return }
        excludedPaths.append(trimmed)
    }

    func removeExcludedPath(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            excludedPaths.remove(at: index)
        }
    }

    func runSafeOneTap() async {
        statusMessage = "Güvenli temizlik taranıyor..."
        let plan = await buildPlan(for: CleanupCategory.safePreset)
        currentPlan = plan
        terminalOutput = makePlanPreviewLog(for: plan, title: "Güvenli Temizlik Önizlemesi")
        await execute(plan: plan)
        await refreshDashboardEstimate()
    }

    func previewSelectedCategories() async {
        statusMessage = "Temizlik önizlemesi hazırlanıyor..."
        let plan = await buildPlan(for: effectiveSelectedCategories)
        currentPlan = plan
        lastResult = nil
        terminalOutput = makePlanPreviewLog(for: plan, title: "Önizleme")
        statusMessage = "Önizleme güncellendi."
    }

    func executeSelectedCategories() async {
        currentPlan = await buildPlan(for: effectiveSelectedCategories)
        terminalOutput = makePlanPreviewLog(for: currentPlan, title: "Çalıştırma Öncesi Plan")
        await execute(plan: currentPlan)
        await refreshDashboardEstimate()
    }

    func clearTerminalOutput() {
        terminalOutput.removeAll()
    }

    func refreshDashboardEstimate() async {
        let safePlan = await buildPlan(for: CleanupCategory.safePreset)
        dashboardEstimateBytes = safePlan.totalBytes
    }

    private func buildPlan(for categories: Set<CleanupCategory>) async -> CleanupPlan {
        isScanning = true
        defer { isScanning = false }

        let filtered = settings.onlySafeAreas ? categories.filter { $0.risk == .safe } : categories
        return await engine.buildPlan(
            for: filtered,
            excludedPaths: excludedPaths,
            safeOnly: settings.onlySafeAreas
        )
    }

    private func execute(plan: CleanupPlan) async {
        isExecuting = true
        statusMessage = "Temizlik çalıştırılıyor..."

        let result = await engine.execute(
            plan: plan,
            settings: settings,
            excludedPaths: excludedPaths
        )

        isExecuting = false
        lastResult = result
        mergeTerminalOutput(with: result.logLines)
        lastCleanupDate = result.finishedAt
        preferences.saveLastCleanupDate(result.finishedAt)

        if result.failures.isEmpty {
            statusMessage = "Temizlik tamamlandı."
        } else {
            statusMessage = "Temizlik tamamlandı, bazı hedefler atlandı."
        }
    }

    private func mergeTerminalOutput(with newLines: [String]) {
        guard !newLines.isEmpty else { return }

        if settings.keepRunLog && !terminalOutput.isEmpty {
            terminalOutput.append("[\(timestamp())] [INFO] ----------------")
            terminalOutput.append(contentsOf: newLines)
        } else {
            terminalOutput = newLines
        }

        let maxLineCount = 800
        if terminalOutput.count > maxLineCount {
            terminalOutput = Array(terminalOutput.suffix(maxLineCount))
        }
    }

    private func makePlanPreviewLog(for plan: CleanupPlan, title: String) -> [String] {
        var lines: [String] = []
        lines.append("[\(timestamp())] [PLAN] \(title)")
        lines.append("[\(timestamp())] [PLAN] Hedef sayısı: \(plan.targets.count), toplam: \(Self.byteFormatter.string(fromByteCount: plan.totalBytes))")

        let maxTargetLines = 150
        for target in plan.sortedTargets.prefix(maxTargetLines) {
            let size = Self.byteFormatter.string(fromByteCount: target.sizeBytes)
            lines.append("[\(timestamp())] [PLAN] \(target.displayPath) (\(size), \(target.fileCount) dosya)")
        }

        if plan.targets.count > maxTargetLines {
            let extra = plan.targets.count - maxTargetLines
            lines.append("[\(timestamp())] [PLAN] ... \(extra) hedef daha listelenmedi")
        }

        for note in plan.notes {
            lines.append("[\(timestamp())] [NOTE] \(note)")
        }

        return lines
    }

    private func timestamp() -> String {
        Self.timeFormatter.string(from: Date())
    }

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.isAdaptive = true
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
