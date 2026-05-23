import WidgetKit
import SwiftUI
import AppIntents

private let kAppGroup   = "group.com.texapp.atensia"
private let kValenceKey = "widget_valence"
private let kArousalKey = "widget_arousal"
private let kDateKey    = "widget_date"

// MARK: - Intent

struct SetMoodIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Mood"

    @Parameter(title: "Key")   var key:   String
    @Parameter(title: "Value") var value: Double

    init() { key = ""; value = 0 }
    init(key: String, value: Double) { self.key = key; self.value = value }

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: kAppGroup)
        defaults?.set(value,         forKey: key)
        defaults?.set(todayString(), forKey: kDateKey)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

// MARK: - Timeline entry

struct MoodEntry: TimelineEntry {
    let date:    Date
    let valence: Double?
    let arousal: Double?
}

// MARK: - Provider

struct MoodProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoodEntry {
        MoodEntry(date: Date(), valence: nil, arousal: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MoodEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoodEntry>) -> Void) {
        let entry        = readEntry()
        let nextMidnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }

    private func readEntry() -> MoodEntry {
        let defaults = UserDefaults(suiteName: kAppGroup)
        let today = todayString()
        if defaults?.string(forKey: kDateKey) != today {
            defaults?.removeObject(forKey: kValenceKey)
            defaults?.removeObject(forKey: kArousalKey)
            defaults?.set(today, forKey: kDateKey)
        }
        return MoodEntry(
            date:    Date(),
            valence: defaults?.object(forKey: kValenceKey) as? Double,
            arousal: defaults?.object(forKey: kArousalKey) as? Double
        )
    }
}

// MARK: - Views

struct MoodWidgetView: View {
    let entry: MoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Як почуваєшся?")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))

            MoodSelectorRow(
                label:    "НАСТРІЙ",
                options:  ["Погано", "Нормально", "Чудово"],
                values:   [-1.0, 0.0, 1.0],
                selected: entry.valence,
                key:      kValenceKey
            )

            Spacer(minLength: 2)

            MoodSelectorRow(
                label:    "ЕНЕРГІЯ",
                options:  ["Виснажено", "Нормально", "Бадьоро"],
                values:   [-1.0, 0.0, 1.0],
                selected: entry.arousal,
                key:      kArousalKey
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(Color.white, for: .widget)
    }
}

struct MoodSelectorRow: View {
    let label:    String
    let options:  [String]
    let values:   [Double]
    let selected: Double?
    let key:      String

    private var selectedIndex: Int? {
        guard let s = selected else { return nil }
        if s <= -0.34 { return 0 }
        if s >=  0.34 { return 2 }
        return 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .kerning(1.0)
                .foregroundStyle(Color.black.opacity(0.5))

            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    let isSelected = selectedIndex == i
                    Button(intent: SetMoodIntent(key: key, value: values[i])) {
                        Text(options[i])
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(isSelected ? Color.white : Color.black)
                            .frame(maxWidth: .infinity, minHeight: 30, maxHeight: .infinity)
                            .background(isSelected ? Color.black : Color.clear)
                    }
                    .buttonStyle(.plain)
                    .invalidatableContent()

                    if i < 2 {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1.5)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.black, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Widget

struct MoodWidget: Widget {
    let kind = "MoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MoodProvider()) { entry in
            MoodWidgetView(entry: entry)
        }
        .configurationDisplayName("Настрій")
        .description("Відстежуй настрій та енергію.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - Helpers

private func todayString() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: Date())
}
