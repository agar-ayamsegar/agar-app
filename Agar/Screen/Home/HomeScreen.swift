//
//  HomeScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI
import SwiftData

struct HomeScreen: View {
    @Query(sort: \ScanSession.startedAt, order: .reverse) private var sessions: [ScanSession]
        @Environment(\.modelContext) private var modelContext
    
    @Bindable var viewModel: RecapViewModel
    var onStartScan: () -> Void
    @State private var bidingstatus = false

    @State private var showsReference = false
    @State private var showsDatePicker = false
    var filteredSessions: [ScanSession] {
        sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: viewModel.selectedDate) }
    }

    var selectedSession: ScanSession? {
        filteredSessions.first { $0.id == viewModel.selectedSessionID } ?? filteredSessions.first
    }

    // takes the session it is given: this used to read selectedSession, so opening any card
    // showed the first session's rows rather than the one that was tapped
    func records(for session: ScanSession) -> [ScanRecord] {
        let ordered = session.records.sorted { $0.scannedAt < $1.scannedAt }
        guard let filter = viewModel.recordFilter else { return ordered }
        return ordered.filter { $0.freshness == filter }
    }

    var body: some View {
        if let session = selectedSession {
            recap(session)
        } else {
            emptyState
        }
    }
}


// MARK: - shared
private extension HomeScreen {
    // same size as the blue button; the native calendar opens in a popover
    var datePicker: some View {
        Button {
            showsDatePicker = true
        } label: {
            Label {
                if Calendar.current.isDateInToday(viewModel.selectedDate) {
                    Text("Today")
                } else {
                    Text(viewModel.selectedDate, format: .dateTime.day().month(.abbreviated).year())
                }
            } icon: {
                Image(systemName: "calendar")
            }
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(.primary)
        .popover(isPresented: $showsDatePicker) {
            DatePicker("Tanggal", selection: $viewModel.selectedDate, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .frame(width: 320)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
        // close the calendar once a day is picked
        .onChange(of: viewModel.selectedDate) {
            showsDatePicker = false
        }
    }
}


// MARK: - empty state: no session on the picked day
private extension HomeScreen {
    var header: some View {
        HStack(alignment: .center) {
            Text("Rekap Sesi")
                .font(.largeTitle.bold())

            Spacer()

            datePicker
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            header

            DetailPanel {
                ContentUnavailableView {
                    ChickenIllustration(pose: .searching, height: 200)
                } description: {
                    Text(sessions.isEmpty ? "Mulai Tambahkan Sesi" : "Tidak ada sesi di tanggal ini")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCream.ignoresSafeArea())
        .bottomAction {
            Button("Mulai Scan Ayam", action: onStartScan)
                .buttonStyle(.primaryAction)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}



private struct DetailBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.headline)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .tint(.primary)
    }
}


// MARK: - recap: session list + selected session detail
private extension HomeScreen {
    func recap(_ session: ScanSession) -> some View {
        VStack(spacing: 16) {
            // the list runs full width so its scroll bar rides the screen edge, so only the
            // header is inset here; everything else keeps the same 16
            header
                .padding(.horizontal, 16)

            sessionList(selected: session)
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCream.ignoresSafeArea())
        .bottomAction {
            Button("Mulai Pemeriksaan", action: onStartScan)
                .buttonStyle(.primaryAction)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    func sessionList(selected: ScanSession) -> some View {
        ZStack(alignment: .top) {
            // the panel sits behind and does not scroll, so the indicator lands on the
            // screen edge rather than inside the white card
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .padding(.horizontal, 16)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(filteredSessions) { session in
                        NavigationLink {
                            sessionDetail(session)
                        } label: {
                            SessionCard(session: session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func sessionDetail(_ session: ScanSession) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                DetailBackButton()

                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                        .font(.title2)
                        .bold()

                    Text("Sesi Mulai : \(session.startedAt, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            SessionTotalsCard(session: session)

            RecordTable(
                records: records(for: session),
                filter: $viewModel.recordFilter,
                onInfo: { showsReference = true }
            )
            .popover(isPresented: $showsReference) {
                referencePopover
                    .presentationCompactAdaptation(.popover)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surfaceCream.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    func columnTitle(_ title: String) -> Text {
        Text(title).foregroundStyle(.secondary)
    }

    var referencePopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Freshness.allCases, id: \.self) { freshness in
                VStack(alignment: .leading, spacing: 4) {
                    Text(freshness.title)
                        .foregroundStyle(freshness.tint)

                    Grid(alignment: .leading, verticalSpacing: 2) {
                        ForEach(freshness.referenceRanges, id: \.label) { reference in
                            GridRow {
                                Text(reference.label)
                                Text(":  \(reference.range)")
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(24)
    }
}


@MainActor
private func previewContainer() -> ModelContainer {
    let container = try! ModelContainer(
        for: ScanSession.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    for number in 134...137 {
        let startedAt = Date.now.addingTimeInterval(Double(number - 138) * 15 * 60)
        let session = ScanSession(
            number: number,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(12 * 60)
        )
        session.records = (1...20).map { index in
            ScanRecord(
                chickenNumber: index,
                scannedAt: startedAt.addingTimeInterval(Double(index) * 20),
                freshness: index.isMultiple(of: 4) ? .notFresh : .fresh
            )
        }
        container.mainContext.insert(session)
    }

    return container
}

#Preview("Empty") {
    HomeScreen(viewModel: RecapViewModel()) { }
        .modelContainer(for: ScanSession.self, inMemory: true)
}

#Preview("With Sessions") {
    NavigationStack {
        HomeScreen(viewModel: RecapViewModel()) { }
    }
    .modelContainer(previewContainer())
}
