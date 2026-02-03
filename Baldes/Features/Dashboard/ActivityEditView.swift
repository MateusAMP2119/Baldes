import SwiftUI
import SwiftData

struct ActivityEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var activity: Activity
    
    // Local state for editing
    @State private var name: String
    @State private var symbol: String
    @State private var color: Color
    @State private var motivation: String
    @State private var motivationAuthor: String
    @State private var goalTimeSeconds: TimeInterval
    @State private var targetCount: Int
    @State private var metricUnit: String
    @State private var selectedDays: Set<Weekday>
    @State private var scheduledHour: Int
    @State private var scheduledMinute: Int
    @State private var hasEndDate: Bool
    @State private var endDate: Date
    @State private var reminderEnabled: Bool
    
    @State private var emojiInput: String = ""
    @State private var showValidationError: Bool = false
    @State private var currentQuote: PhilosopherQuote?
    
    private let philosopherQuotes: [PhilosopherQuote] = [
        PhilosopherQuote(
            quote: "A vida não examinada não vale a pena ser vivida.", author: "Sócrates"),
        PhilosopherQuote(
            quote: "Somos o que repetidamente fazemos. A excelência, portanto, não é um ato, mas um hábito.",
            author: "Aristóteles"),
        PhilosopherQuote(
            quote: "Aquele que tem um porquê para viver pode suportar quase qualquer como.",
            author: "Friedrich Nietzsche"),
        PhilosopherQuote(
            quote: "A felicidade não é algo pronto. Ela vem das suas próprias ações.",
            author: "Dalai Lama"),
        PhilosopherQuote(quote: "Conhece-te a ti mesmo.", author: "Sócrates"),
    ]
    
    init(activity: Activity) {
        _activity = Bindable(wrappedValue: activity)
        _name = State(initialValue: activity.name)
        _symbol = State(initialValue: activity.symbol)
        _color = State(initialValue: Color(hex: activity.colorHex))
        _motivation = State(initialValue: activity.motivation)
        _motivationAuthor = State(initialValue: activity.motivationAuthor ?? "")
        _goalTimeSeconds = State(initialValue: activity.goalTimeSeconds ?? 30 * 60)
        _targetCount = State(initialValue: activity.targetCount ?? 0)
        _metricUnit = State(initialValue: activity.metricUnit ?? "Repetições")
        
        // Convert recurring days from [Int] to Set<Weekday>
        let weekdays: Set<Weekday> = Set(
            (activity.recurringDays ?? []).compactMap { Weekday(rawValue: $0) }
        )
        _selectedDays = State(initialValue: weekdays.isEmpty ? Set(Weekday.allCases) : weekdays)
        
        _scheduledHour = State(initialValue: activity.scheduledHour ?? 9)
        _scheduledMinute = State(initialValue: activity.scheduledMinute ?? 0)
        _hasEndDate = State(initialValue: activity.endDate != nil)
        _endDate = State(initialValue: activity.endDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60))
        _reminderEnabled = State(initialValue: activity.reminderEnabled)
    }
    
    private var scheduledTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = scheduledHour
        components.minute = scheduledMinute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !motivation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedDays.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info Section
                Section("Objetivo") {
                    // Name with emoji
                    HStack {
                        TextField("Nome", text: $name)
                        
                        if showValidationError && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14))
                        }
                        
                        Circle()
                            .foregroundColor(Color.gray.opacity(0.2))
                            .frame(width: 34, height: 34)
                            .overlay(
                                EmojiTextField(text: $emojiInput)
                                    .onChange(of: emojiInput) { _, newValue in
                                        handleEmojiInput(newValue)
                                    }
                            )
                            .offset(x: -5)
                    }
                    .frame(height: 18)
                    
                    // Motivation
                    HStack(alignment: .top) {
                        TextField("Motivação", text: $motivation, axis: .vertical)
                            .lineLimit(1...5)
                        
                        if showValidationError && motivation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 14))
                        }
                        
                        Circle()
                            .foregroundColor(Color.gray.opacity(0.2))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Button {
                                    currentQuote = philosopherQuotes.randomElement()
                                } label: {
                                    Image(systemName: "lightbulb.min")
                                        .foregroundStyle(.gray)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .popover(item: $currentQuote) { quote in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("\"\(quote.quote)\"")
                                            .font(.body)
                                            .italic()
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("— \(quote.author)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Button("Usar esta citação") {
                                            motivation = quote.quote
                                            motivationAuthor = quote.author
                                            currentQuote = nil
                                        }
                                        .font(.caption)
                                        .padding(.top, 4)
                                    }
                                    .padding()
                                    .frame(minWidth: 200, idealWidth: 300)
                                    .presentationCompactAdaptation(.popover)
                                }
                            )
                            .offset(x: -5)
                            .frame(height: 18)
                    }
                    
                    // Motivation Author (optional)
                    TextField("Autor da citação (opcional)", text: $motivationAuthor)
                    
                    // Color Picker
                    HStack {
                        Text("Cor")
                        Spacer()
                        ColorPicker("", selection: $color, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 34, height: 34)
                            .offset(x: -5)
                    }
                    .frame(height: 18)
                }
                
                // MARK: - Goal Section (if applicable)
                if activity.goalTimeSeconds != nil {
                    Section("Meta de Tempo") {
                        HStack {
                            Text("Meta Diária")
                            Spacer()
                            TimerPickerView(totalSeconds: $goalTimeSeconds)
                        }
                        .frame(height: 18)
                    }
                }
                
                if activity.targetCount != nil {
                    Section("Meta Numérica") {
                        HStack {
                            Text("Objetivo")
                            Spacer()
                            TextField("Quantidade", value: $targetCount, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                        
                        HStack {
                            Text("Unidade")
                            Spacer()
                            TextField("Ex: Repetições", text: $metricUnit)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                        }
                    }
                }
                
                // MARK: - Schedule Section
                Section("Horário") {
                    DatePicker(
                        "Hora",
                        selection: Binding(
                            get: { scheduledTime },
                            set: { newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                scheduledHour = components.hour ?? scheduledHour
                                scheduledMinute = components.minute ?? scheduledMinute
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }
                
                // MARK: - Frequency Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Dias da Semana")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            if showValidationError && selectedDays.isEmpty {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        HStack(spacing: 8) {
                            ForEach(Weekday.allCases) { day in
                                DayButton(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    color: color
                                ) {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Frequência")
                }
                
                // MARK: - End Date Section
                Section("Duração") {
                    Toggle("Definir data de fim", isOn: $hasEndDate)
                    
                    if hasEndDate {
                        DatePicker(
                            "Data de fim",
                            selection: $endDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
                }
                
                // MARK: - Notifications Section
                Section("Notificações") {
                    Toggle("Lembrete ativo", isOn: $reminderEnabled)
                }
                
                // MARK: - Danger Zone
                Section {
                    Button(role: .destructive) {
                        deleteActivity()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Eliminar Atividade")
                        }
                    }
                }
            }
            .navigationTitle("Editar Atividade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        if isValid {
                            saveChanges()
                            dismiss()
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                emojiInput = symbol
            }
        }
    }
    
    private func handleEmojiInput(_ newValue: String) {
        let emoji = newValue.last { char in
            char.unicodeScalars.first.map {
                $0.properties.isEmoji && !$0.isASCII
            } ?? false
        }
        if let emoji {
            emojiInput = String(emoji)
            symbol = String(emoji)
        } else if !newValue.isEmpty {
            emojiInput = symbol
        }
    }
    
    private func saveChanges() {
        // Update activity properties
        activity.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        activity.symbol = symbol
        activity.colorHex = color.toHex() ?? activity.colorHex
        activity.motivation = motivation.trimmingCharacters(in: .whitespacesAndNewlines)
        activity.motivationAuthor = motivationAuthor.isEmpty ? nil : motivationAuthor
        
        // Update goal if applicable
        if activity.goalTimeSeconds != nil {
            activity.goalTimeSeconds = goalTimeSeconds
        }
        
        if activity.targetCount != nil {
            activity.targetCount = targetCount
            activity.metricTarget = Double(targetCount)
            activity.metricUnit = metricUnit
        }
        
        // Update schedule
        activity.scheduledHour = scheduledHour
        activity.scheduledMinute = scheduledMinute
        
        // Update recurring days
        activity.recurringDays = selectedDays.map { $0.rawValue }
        activity.recurringPlanSummary = selectedDays.isEmpty ? nil : selectedDays.sorted { $0.rawValue < $1.rawValue }.map { $0.shortName }.joined(separator: ", ")
        
        // Update end date
        activity.endDate = hasEndDate ? endDate : nil
        
        // Update notifications
        activity.reminderEnabled = reminderEnabled
        
        // Save context
        do {
            try modelContext.save()
            
            // Reschedule notifications
            NotificationManager.shared.cancelNotifications(for: activity)
            if reminderEnabled {
                NotificationManager.shared.scheduleNotifications(for: activity)
            }
        } catch {
            print("Failed to save activity changes: \(error.localizedDescription)")
        }
    }
    
    private func deleteActivity() {
        // Cancel notifications first
        NotificationManager.shared.cancelNotifications(for: activity)
        
        // Delete the activity
        modelContext.delete(activity)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete activity: \(error.localizedDescription)")
        }
        
        dismiss()
    }
}

// MARK: - Day Button Component

private struct DayButton: View {
    let day: Weekday
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    private var initial: String {
        String(day.shortName.prefix(1))
    }
    
    var body: some View {
        Button(action: action) {
            Text(initial)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color("TextPrimary"))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? color : Color.gray.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActivityEditView(
        activity: Activity(
            name: "Leitura",
            symbol: "📚",
            colorHex: "#FF6B6B",
            motivation: "Ler 30 minutos todos os dias para expandir a mente",
            goalTimeSeconds: 30 * 60
        )
    )
}
