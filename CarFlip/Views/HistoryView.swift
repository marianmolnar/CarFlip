import SwiftUI

struct HistoryView: View {
    @ObservedObject var carManager: CarManager
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: Date())!.start
    @State private var monthStep = 0
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthHeader

                    MonthGrid(
                        month: displayedMonth,
                        selectedDate: $selectedDate,
                        carManager: carManager
                    )
                    .id(displayedMonth)
                    .transition(.asymmetric(
                        insertion: .move(edge: monthStep >= 0 ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: monthStep >= 0 ? .leading : .trailing).combined(with: .opacity)
                    ))
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .gesture(
                        DragGesture(minimumDistance: 30).onEnded { value in
                            if value.translation.width < -60 { changeMonth(by: 1) }
                            if value.translation.width > 60 { changeMonth(by: -1) }
                        }
                    )

                    MonthBreakdown(records: recordsInDisplayedMonth, carManager: carManager)

                    dayDetail
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecordView(carManager: carManager, date: selectedDate)
                .presentationDetents([.medium, .large])
        }
        .alert("Remove this day?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                withAnimation(.snappy) { carManager.deleteFlipRecord(for: selectedDate) }
            }
        } message: {
            Text("The car picked for this day will be cleared.")
        }
        .sensoryFeedback(.selection, trigger: selectedDate)
    }

    // MARK: - Sections

    private var monthHeader: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                Eyebrow(displayedMonth.formatted(.dateTime.year()))
                Text(displayedMonth.formatted(.dateTime.month(.wide)))
                    .font(.badge(34))
                    .contentTransition(.numericText(countsDown: monthStep < 0))
            }

            Spacer()

            HStack(spacing: 8) {
                monthButton("chevron.left", step: -1)
                monthButton("chevron.right", step: 1)
            }
        }
    }

    private func monthButton(_ symbol: String, step: Int) -> some View {
        Button {
            changeMonth(by: step)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .bold))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(step < 0 ? "Previous month" : "Next month")
    }

    @ViewBuilder
    private var dayDetail: some View {
        let record = carManager.getRecordForDate(selectedDate)
        let car = record.flatMap { carManager.car(withId: $0.carId) }

        VStack(alignment: .leading, spacing: 0) {
            if let record {
                CarArtwork(car: car, symbolScale: 0.3)
                    .frame(height: 170)
                    .clipped()
            }

            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text(record?.carName ?? "Nothing logged")
                        .font(.badge(24))
                        .foregroundStyle(record == nil ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                }

                HStack(spacing: 10) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(record == nil ? "Pick a car" : "Change", systemImage: record == nil ? "plus" : "arrow.left.arrow.right")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(carManager.cars.isEmpty)

                    if record != nil {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Remove")
                    }
                }
                .buttonBorderShape(.capsule)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .animation(.snappy, value: record?.carId)
    }

    // MARK: - Helpers

    private var recordsInDisplayedMonth: [FlipRecord] {
        carManager.flipRecords.filter { calendar.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    private func changeMonth(by step: Int) {
        guard let month = calendar.date(byAdding: .month, value: step, to: displayedMonth) else { return }
        monthStep = step
        withAnimation(.snappy(duration: 0.35)) {
            displayedMonth = month
        }
    }
}

// MARK: - Calendar grid

private struct MonthGrid: View {
    let month: Date
    @Binding var selectedDate: Date
    @ObservedObject var carManager: CarManager

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .semibold).width(.expanded))
                    .foregroundStyle(.secondary)
                    .frame(height: 20)
            }

            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                if let day {
                    DayCell(
                        date: day,
                        record: carManager.getRecordForDate(day),
                        car: carManager.getRecordForDate(day).flatMap { carManager.car(withId: $0.carId) },
                        isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                        isToday: calendar.isDateInToday(day)
                    )
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.25)) { selectedDate = day }
                    }
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Days of the month, padded with leading `nil`s so the first day lands in its weekday column.
    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let dates = range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return Array(repeating: nil, count: leading) + dates
    }
}

private struct DayCell: View {
    let date: Date
    let record: FlipRecord?
    let car: Car?
    let isSelected: Bool
    let isToday: Bool

    var body: some View {
        let number = Calendar.current.component(.day, from: date)

        ZStack {
            if record != nil {
                CarArtwork(car: car, symbolScale: 0.4)
                    .overlay(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }

            Text("\(number)")
                .font(.system(size: 15, weight: record != nil || isToday ? .bold : .medium, design: .rounded))
                .foregroundStyle(record != nil ? AnyShapeStyle(.white) : (isToday ? AnyShapeStyle(Theme.blue) : AnyShapeStyle(.primary)))
                .opacity(date > Date() && record == nil ? 0.35 : 1)
        }
        .frame(width: 40, height: 40)
        .overlay {
            if isSelected {
                Circle()
                    .strokeBorder(Theme.brandGradient, lineWidth: 2.5)
                    .padding(-4)
            } else if isToday {
                Circle()
                    .strokeBorder(Theme.blue.opacity(0.4), lineWidth: 1.5)
                    .padding(-2)
            }
        }
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(date.formatted(date: .complete, time: .omitted) + (record.map { ", \($0.carName)" } ?? ""))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Monthly breakdown

private struct MonthBreakdown: View {
    let records: [FlipRecord]
    let carManager: CarManager

    private static let palette: [Color] = [
        Theme.blue, Theme.violet, Theme.gold,
        Color(red: 0.2, green: 0.75, blue: 0.65), Color(red: 0.95, green: 0.4, blue: 0.5),
    ]

    private var tallies: [(name: String, count: Int)] {
        Dictionary(grouping: records, by: \.carId)
            .map { id, records in (carManager.car(withId: id)?.name ?? records[0].carName, records.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        if !records.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(records.count == 1 ? "1 day logged" : "\(records.count) days logged")

                GeometryReader { proxy in
                    HStack(spacing: 3) {
                        ForEach(Array(tallies.enumerated()), id: \.offset) { index, tally in
                            Capsule()
                                .fill(color(at: index))
                                .frame(width: max(8, (proxy.size.width - CGFloat(tallies.count - 1) * 3) * CGFloat(tally.count) / CGFloat(records.count)))
                        }
                    }
                }
                .frame(height: 10)

                FlowingLegend(items: tallies.enumerated().map { index, tally in
                    (color(at: index), "\(tally.name) · \(tally.count)")
                })
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func color(at index: Int) -> Color {
        Self.palette[index % Self.palette.count]
    }
}

private struct FlowingLegend: View {
    let items: [(Color, String)]

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) { entries }
            VStack(alignment: .leading, spacing: 8) { entries }
        }
    }

    private var entries: some View {
        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            HStack(spacing: 6) {
                Circle().fill(item.0).frame(width: 8, height: 8)
                Text(item.1)
                    .font(.footnote.weight(.medium))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Picker sheet

struct EditRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var carManager: CarManager
    let date: Date
    @State private var selectedCarId: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(carManager.cars) { car in
                        let isSelected = selectedCarId == car.id
                        Button {
                            withAnimation(.snappy(duration: 0.2)) { selectedCarId = car.id }
                        } label: {
                            HStack(spacing: 14) {
                                CarArtwork(car: car, symbolScale: 0.4)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                Text(car.name)
                                    .font(.badge(16, weight: .bold))
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(.tertiary))
                            }
                            .padding(10)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(isSelected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(.clear), lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle(date.formatted(.dateTime.day().month(.abbreviated)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let carId = selectedCarId, let car = carManager.car(withId: carId) {
                            carManager.updateFlipRecord(for: date, with: car)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedCarId == nil)
                }
            }
            .onAppear {
                selectedCarId = carManager.getRecordForDate(date)?.carId
            }
        }
    }
}
