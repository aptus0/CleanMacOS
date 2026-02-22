import Foundation

actor CleanupEngine {
    private let fileManager: FileManager
    private let largeFileThresholdBytes: Int64

    init(
        fileManager: FileManager = .default,
        largeFileThresholdBytes: Int64 = 500 * 1024 * 1024
    ) {
        self.fileManager = fileManager
        self.largeFileThresholdBytes = largeFileThresholdBytes
    }

    func buildPlan(
        for categories: Set<CleanupCategory>,
        excludedPaths: [String],
        safeOnly: Bool
    ) -> CleanupPlan {
        let effectiveCategories = categories
            .filter { !safeOnly || $0.risk == .safe }
            .sorted { $0.title < $1.title }

        let excludedURLs = excludedPaths
            .map(Self.expandPath)
            .map(Self.normalize)

        var targets: [CleanupTarget] = []
        var notes: [String] = []

        for category in effectiveCategories {
            let roots = category.roots.filter { fileManager.fileExists(atPath: $0.path) }

            if roots.isEmpty {
                if category == .trash {
                    notes.append("Çöp Kutusu: temizlenecek öğe bulunamadı")
                } else {
                    notes.append("\(category.title): uygun klasör bulunamadı")
                }
                continue
            }

            if category.isPreviewOnly {
                let files = scanLargeFiles(in: roots, excludedURLs: excludedURLs)
                targets.append(contentsOf: files)
                continue
            }

            for root in roots {
                guard !isProtected(root) else {
                    notes.append("\(category.title): korumalı kök atlandı -> \(root.path)")
                    continue
                }

                do {
                    let items = try fileManager.contentsOfDirectory(
                        at: root,
                        includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
                        options: []
                    )

                    for item in items {
                        guard isCandidateSafe(item, for: category, excludedURLs: excludedURLs) else {
                            continue
                        }

                        let metrics = measure(at: item)
                        guard metrics.byteSize > 0 else { continue }

                        targets.append(
                            CleanupTarget(
                                category: category,
                                url: item,
                                sizeBytes: metrics.byteSize,
                                fileCount: metrics.fileCount
                            )
                        )
                    }
                } catch {
                    notes.append("\(category.title): \(root.path) okunamadı (\(error.localizedDescription))")
                }
            }
        }

        return CleanupPlan(generatedAt: .now, targets: targets, notes: notes)
    }

    func execute(
        plan: CleanupPlan,
        settings: CleanerSettings,
        excludedPaths: [String]
    ) -> CleanupExecutionResult {
        let excludedURLs = excludedPaths
            .map(Self.expandPath)
            .map(Self.normalize)

        let start = Date()
        let deletableTargets = plan.targets.filter { !$0.category.isPreviewOnly }
        let previewOnlySkipped = plan.targets.count - deletableTargets.count

        var deletedTargetCount = 0
        var deletedFileCount = 0
        var actualFreedBytes: Int64 = 0
        var failures: [CleanupFailure] = []
        var logLines: [String] = []

        func log(_ level: String, _ message: String) {
            logLines.append("[\(Self.timestamp())] [\(level)] \(message)")
        }

        log("INFO", "Temizlik başlatıldı. Mod: KALICI SILME, hedef: \(deletableTargets.count)")
        if previewOnlySkipped > 0 {
            log("INFO", "Sadece raporlanan (silinmeyen) hedef sayısı: \(previewOnlySkipped)")
        }

        for target in deletableTargets {
            guard isCandidateSafe(target.url, for: target.category, excludedURLs: excludedURLs) else {
                failures.append(
                    CleanupFailure(
                        path: target.displayPath,
                        reason: "Güvensiz veya hariç tutma listesindeki hedef"
                    )
                )
                log("SKIP", "\(target.displayPath) güvenlik filtresi nedeniyle atlandı.")
                continue
            }

            guard fileManager.fileExists(atPath: target.url.path) else {
                log("SKIP", "\(target.displayPath) bulunamadı.")
                continue
            }

            do {
                try fileManager.removeItem(at: target.url)

                deletedTargetCount += 1
                deletedFileCount += max(target.fileCount, 1)
                actualFreedBytes += target.sizeBytes
                log("OK", "Silindi: \(target.displayPath) (\(Self.readableBytes(target.sizeBytes)))")
            } catch {
                failures.append(
                    CleanupFailure(
                        path: target.displayPath,
                        reason: error.localizedDescription
                    )
                )
                log("ERR", "Silinemedi: \(target.displayPath) -> \(error.localizedDescription)")
            }
        }

        let estimatedFreed = deletableTargets.reduce(0) { $0 + $1.sizeBytes }
        log(
            "INFO",
            "Tamamlandı. Hedef: \(deletedTargetCount), dosya: \(deletedFileCount), alan: \(Self.readableBytes(actualFreedBytes))"
        )
        if !failures.isEmpty {
            log("WARN", "Hata/atlanan hedef sayısı: \(failures.count)")
        }

        return CleanupExecutionResult(
            startedAt: start,
            finishedAt: .now,
            deletedTargetCount: deletedTargetCount,
            deletedFileCount: deletedFileCount,
            estimatedFreedBytes: estimatedFreed,
            actualFreedBytes: actualFreedBytes,
            previewOnlySkipped: previewOnlySkipped,
            failures: failures,
            logLines: logLines
        )
    }

    private func scanLargeFiles(in roots: [URL], excludedURLs: [URL]) -> [CleanupTarget] {
        var targets: [CleanupTarget] = []

        for root in roots {
            guard !isProtected(root) else { continue }

            let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey],
                options: [.skipsPackageDescendants],
                errorHandler: { _, _ in true }
            )

            guard let enumerator else { continue }

            for case let fileURL as URL in enumerator {
                guard isCandidateSafe(fileURL, for: .largeFiles, excludedURLs: excludedURLs) else {
                    continue
                }

                let size = fileSize(of: fileURL)
                guard size >= largeFileThresholdBytes else { continue }

                targets.append(
                    CleanupTarget(
                        category: .largeFiles,
                        url: fileURL,
                        sizeBytes: size,
                        fileCount: 1
                    )
                )
            }
        }

        return targets
    }

    private func isCandidateSafe(_ url: URL, for category: CleanupCategory, excludedURLs: [URL]) -> Bool {
        let normalizedURL = Self.normalize(url)

        guard !isProtected(normalizedURL) else { return false }
        guard category.roots.contains(where: { Self.isDescendant(normalizedURL, of: Self.normalize($0)) }) else {
            return false
        }
        guard !excludedURLs.contains(where: { Self.isDescendant(normalizedURL, of: $0) }) else {
            return false
        }

        return true
    }

    private func isProtected(_ url: URL) -> Bool {
        let protectedRoots = Self.protectedRoots
        let normalizedURL = Self.normalize(url)
        return protectedRoots.contains(where: { Self.isDescendant(normalizedURL, of: $0) })
    }

    private func measure(at url: URL) -> (byteSize: Int64, fileCount: Int) {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return (0, 0)
        }

        if !isDirectory.boolValue {
            let size = fileSize(of: url)
            return (size, 1)
        }

        var totalBytes: Int64 = 0
        var totalFiles = 0

        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        )

        guard let enumerator else { return (0, 0) }

        for case let child as URL in enumerator {
            let values = try? child.resourceValues(forKeys: [.isRegularFileKey])
            guard values?.isRegularFile == true else { continue }

            totalBytes += fileSize(of: child)
            totalFiles += 1
        }

        return (totalBytes, totalFiles)
    }

    private func fileSize(of url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .fileSizeKey])
        let size = values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? values?.fileSize ?? 0
        return Int64(size)
    }

    private static var protectedRoots: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            URL(fileURLWithPath: "/System", isDirectory: true),
            URL(fileURLWithPath: "/Library", isDirectory: true),
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/private/var/db", isDirectory: true),
            URL(fileURLWithPath: "/private/var/vm", isDirectory: true),
            home.appendingPathComponent("Library/Application Support", isDirectory: true),
            home.appendingPathComponent("Library/Keychains", isDirectory: true),
            home.appendingPathComponent("Library/Mobile Documents", isDirectory: true),
            home.appendingPathComponent("Library/Containers/com.apple.CloudDocs", isDirectory: true)
        ].map(normalize)
    }

    private static func expandPath(_ value: String) -> URL {
        let expanded = NSString(string: value).expandingTildeInPath
        return URL(fileURLWithPath: expanded)
    }

    private static func normalize(_ url: URL) -> URL {
        url.resolvingSymlinksInPath().standardizedFileURL
    }

    private static func isDescendant(_ child: URL, of parent: URL) -> Bool {
        let childPath = child.path
        let parentPath = parent.path

        if childPath == parentPath { return true }
        return childPath.hasPrefix(parentPath.hasSuffix("/") ? parentPath : parentPath + "/")
    }

    private static func readableBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
