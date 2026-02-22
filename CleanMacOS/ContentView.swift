import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CleanerViewModel()
    @State private var selectedTab: CleanerTab = .dashboard
    @State private var excludeInput: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Self.backgroundTop, Self.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                dashboardTab
                    .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent") }
                    .tag(CleanerTab.dashboard)

                categoriesTab
                    .tabItem { Label("Kategoriler", systemImage: "checklist") }
                    .tag(CleanerTab.categories)

                previewTab
                    .tabItem { Label("Önizleme", systemImage: "doc.text.magnifyingglass") }
                    .tag(CleanerTab.preview)

                settingsTab
                    .tabItem { Label("Ayarlar", systemImage: "slider.horizontal.3") }
                    .tag(CleanerTab.settings)
            }
            .padding(14)
            .tint(Self.accentColor)
        }
        .frame(minWidth: 1100, minHeight: 760)
    }

    private var dashboardTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("CleanMacOS")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                HStack(spacing: 16) {
                    metricCard(
                        title: "Tahmini Boşaltılabilir Alan",
                        value: Self.byteFormatter.string(fromByteCount: viewModel.dashboardEstimateBytes),
                        caption: "Güvenli ön ayar"
                    )

                    metricCard(
                        title: "Son Temizlik",
                        value: formattedDate(viewModel.lastCleanupDate),
                        caption: "Kalıcı silme sonrası güncellenir"
                    )
                }

                HStack(spacing: 12) {
                    Button {
                        Task {
                            await viewModel.runSafeOneTap()
                            selectedTab = .preview
                        }
                    } label: {
                        Label("Güvenli Temizle", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isScanning || viewModel.isExecuting)

                    Button {
                        selectedTab = .categories
                    } label: {
                        Label("Detaylı Temizlik", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.bordered)
                }

                if let message = viewModel.statusMessage {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let lastResult = viewModel.lastResult {
                    resultSummaryCard(result: lastResult)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }

    private var categoriesTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Kategori Seçimi")
                    .font(.title2.bold())

                Text("Güvenli ve opsiyonel alanları ayrı seç. 'Sadece güvenli alanlar' açıksa opsiyonel kategoriler kilitlenir.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.categories) { category in
                        categoryRow(category)
                    }
                }
                .padding(14)
                .background(Self.cardColor, in: RoundedRectangle(cornerRadius: 14))

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await viewModel.previewSelectedCategories()
                            selectedTab = .preview
                        }
                    } label: {
                        Label("Önizlemeyi Yenile", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isScanning || viewModel.isExecuting)

                    Button {
                        Task {
                            await viewModel.executeSelectedCategories()
                            selectedTab = .preview
                        }
                    } label: {
                        Label("Seçilenleri Çalıştır", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isScanning || viewModel.isExecuting)
                }

                if viewModel.isScanning || viewModel.isExecuting {
                    ProgressView()
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }

    private var previewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Önizleme ve Kalıcı Silme")
                    .font(.title2.bold())

                HStack(spacing: 16) {
                    metricCard(
                        title: "Toplam Boyut",
                        value: Self.byteFormatter.string(fromByteCount: viewModel.currentPlan.totalBytes),
                        caption: "Seçili kategoriler"
                    )

                    metricCard(
                        title: "Hedef Sayısı",
                        value: "\(viewModel.currentPlan.targets.count)",
                        caption: "Silinebilir öğe"
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await viewModel.previewSelectedCategories()
                            }
                        } label: {
                            Label("Önizleme Tara", systemImage: "doc.text.magnifyingglass")
                        }
                        .buttonStyle(.bordered)

                        Button {
                            Task {
                                await viewModel.executeSelectedCategories()
                            }
                        } label: {
                            Label("Kalıcı Olarak Sil", systemImage: "trash")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Text("Uyarı: Bu işlem seçili hedefleri geri dönüşsüz şekilde kalıcı olarak siler.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Silinecek Hedefler")
                        .font(.headline)

                    if viewModel.currentPlan.sortedTargets.isEmpty {
                        Text("Hedef bulunamadı. Kategori seçimi veya izinleri kontrol et.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.currentPlan.sortedTargets) { target in
                            HStack(alignment: .top, spacing: 10) {
                                riskBadge(target.category.risk)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(target.category.title)
                                        .font(.subheadline.weight(.semibold))

                                    Text(target.displayPath)
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(Self.byteFormatter.string(fromByteCount: target.sizeBytes))
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(target.fileCount) dosya")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(10)
                            .background(Self.cardColor, in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                if !viewModel.currentPlan.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notlar")
                            .font(.headline)

                        ForEach(viewModel.currentPlan.notes, id: \.self) { note in
                            Text("- \(note)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Self.softCardColor, in: RoundedRectangle(cornerRadius: 10))
                }

                excludeSection

                if let result = viewModel.lastResult {
                    resultSummaryCard(result: result)
                }

                terminalOutputSection
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }

    private var settingsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Ayarlar")
                    .font(.title2.bold())

                Toggle("Sadece güvenli alanlar", isOn: binding(\.onlySafeAreas))
                Toggle("Root izin isteme (kapalı önerilir)", isOn: binding(\.requestRootAccess))
                Toggle("Temizlik logu tut", isOn: binding(\.keepRunLog))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Kilitli Klasörler")
                        .font(.headline)
                    Text("/System, /Library, ~/Library/Application Support, Keychains ve iCloud ile ilişkili alanlar kilitlidir.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Self.softCardColor, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
    }

    private var excludeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hariç Tutma Listesi")
                .font(.headline)

            HStack {
                TextField("Örnek: ~/Library/Caches/com.vendor.app", text: $excludeInput)
                    .textFieldStyle(.roundedBorder)

                Button("Ekle") {
                    viewModel.addExcludedPath(excludeInput)
                    excludeInput = ""
                }
                .buttonStyle(.bordered)
            }

            if viewModel.excludedPaths.isEmpty {
                Text("Hariç tutma listesi boş.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.excludedPaths, id: \.self) { path in
                    HStack {
                        Text(path)
                            .font(.caption.monospaced())
                        Spacer()
                        Button(role: .destructive) {
                            if let index = viewModel.excludedPaths.firstIndex(of: path) {
                                viewModel.excludedPaths.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "xmark.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(12)
        .background(Self.softCardColor, in: RoundedRectangle(cornerRadius: 10))
    }

    private func categoryRow(_ category: CleanupCategory) -> some View {
        let isDisabled = viewModel.settings.onlySafeAreas && category.risk == .optional
        let isSelected = viewModel.effectiveSelectedCategories.contains(category)

        return HStack(alignment: .top, spacing: 10) {
            Toggle(
                isOn: Binding(
                    get: { isSelected },
                    set: { newValue in
                        viewModel.setCategory(category, selected: newValue)
                    }
                )
            ) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(category.title)
                            .font(.subheadline.weight(.semibold))
                        riskBadge(category.risk)
                    }

                    Text(category.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !category.warning.isEmpty {
                        Text(category.warning)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .toggleStyle(.checkbox)
            .disabled(isDisabled)

            if category.isPreviewOnly {
                Text("Rapor")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Self.reportBadgeColor, in: Capsule())
            }
        }
        .padding(8)
        .background(Self.softCardColor, in: RoundedRectangle(cornerRadius: 10))
    }

    private var terminalOutputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Terminal Çıktısı")
                    .font(.headline)
                Spacer()
                Button("Temizle") {
                    viewModel.clearTerminalOutput()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.terminalOutput.isEmpty)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Self.terminalBackground)

                if viewModel.terminalOutput.isEmpty {
                    Text("Henüz çıktı yok. Temizlik çalıştırdığında burada satır satır görünecek.")
                        .font(.caption.monospaced())
                        .foregroundStyle(Self.terminalText.opacity(0.75))
                        .padding(10)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(viewModel.terminalOutput.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Self.terminalText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(10)
                    }
                }
            }
            .frame(minHeight: 170, maxHeight: 280)
        }
        .padding(12)
        .background(Self.softCardColor, in: RoundedRectangle(cornerRadius: 10))
    }

    private func resultSummaryCard(result: CleanupExecutionResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Temizlik Sonucu")
                .font(.headline)

            Text("Mod: Kalıcı silme")
            Text("Silinen hedef: \(result.deletedTargetCount)")
            Text("Silinen dosya: \(result.deletedFileCount)")
            Text("Tahmini boşalan: \(Self.byteFormatter.string(fromByteCount: result.estimatedFreedBytes))")
            Text("Gerçek boşalan: \(Self.byteFormatter.string(fromByteCount: result.actualFreedBytes))")

            if result.previewOnlySkipped > 0 {
                Text("Sadece raporlanan (atlanan) kategori adedi: \(result.previewOnlySkipped)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !result.failures.isEmpty {
                Text("Hata / İzin raporu")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)

                ForEach(result.failures.prefix(10)) { failure in
                    Text("- \(failure.path): \(failure.reason)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Self.cardColor, in: RoundedRectangle(cornerRadius: 12))
    }

    private func riskBadge(_ risk: CleanupRiskLevel) -> some View {
        Text(risk.title)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                risk == .safe ? Self.safeBadgeColor : Self.optionalBadgeColor,
                in: Capsule()
            )
    }

    private func metricCard(title: String, value: String, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Self.cardColor, in: RoundedRectangle(cornerRadius: 14))
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<CleanerSettings, Value>) -> Binding<Value> {
        Binding(
            get: { viewModel.settings[keyPath: keyPath] },
            set: { viewModel.settings[keyPath: keyPath] = $0 }
        )
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "Henüz çalışmadı" }
        return Self.dateFormatter.string(from: date)
    }

    private static let accentColor = Color(red: 0.10, green: 0.44, blue: 0.77)
    private static let backgroundTop = Color(red: 0.93, green: 0.96, blue: 0.99)
    private static let backgroundBottom = Color(red: 0.90, green: 0.94, blue: 0.98)
    private static let cardColor = Color.white.opacity(0.84)
    private static let softCardColor = Color.white.opacity(0.74)
    private static let safeBadgeColor = Color(red: 0.78, green: 0.91, blue: 0.81)
    private static let optionalBadgeColor = Color(red: 0.99, green: 0.90, blue: 0.75)
    private static let reportBadgeColor = Color(red: 0.77, green: 0.87, blue: 0.99)
    private static let terminalBackground = Color(red: 0.06, green: 0.10, blue: 0.13)
    private static let terminalText = Color(red: 0.71, green: 0.96, blue: 0.79)

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
