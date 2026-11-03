//
//  HomeScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


struct HomeScreen: View {
    @Bindable var viewModel: RecapViewModel
    var onStartScan: () -> Void

    @State private var showsReference = false
    @State private var showsDatePicker = false

    var body: some View {
        if let session = viewModel.selectedSession {
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
        .buttonStyle(.bordered)
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
    var emptyState: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            Text(viewModel.sessions.isEmpty ? "Mulai Tambahkan Sesi" : "Tidak ada sesi di tanggal ini")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .top) {
                    datePicker
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }
                .safeAreaInset(edge: .bottom) {
                    Button(action: onStartScan) {
                        Text("Mulai Scan Ayam")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.actionBlue)
                    .padding()
                }
                .navigationTitle("Rekap Sesi")
                .navigationSplitViewColumnWidth(340)
                .containerBackground(.white, for: .navigation)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            DetailPanel {
                ContentUnavailableView {
                    ChickenIllustration(pose: .searching, height: 200)
                } description: {
                    Text("Belum ada data")
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .navigationSplitViewStyle(.balanced)
    }
}


// MARK: - recap: session list + selected session detail
private extension HomeScreen {
    func recap(_ session: ScanSession) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Rekap Sesi")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                datePicker

                Button("Mulai Pemeriksaan", action: onStartScan)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(.actionBlue)
            }

            HStack(alignment: .top, spacing: 12) {
                sessionList(selected: session)
                    .frame(width: 300)

                sessionDetail(session)
            }
        }
        .padding()
        .background(Color.surfaceCream.ignoresSafeArea())
    }

    func sessionList(selected: ScanSession) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.filteredSessions) { session in
                    Button {
                        viewModel.selectedSessionID = session.id
                    } label: {
                        sessionCard(session, isSelected: session.id == selected.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(maxHeight: .infinity)
        .background(.white, in: .rect(cornerRadius: 24))
    }

    func sessionCard(_ session: ScanSession, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sesi #\(session.number)")
                    .font(.headline)

                Spacer()

                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline) {
                Text("\(session.totalCount)")
                    .font(.system(size: 36, weight: .bold))
                Text("Ayam")
                    .font(.headline)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Segar : \(session.freshCount)")
                    Text("Tidak Segar : \(session.notFreshCount)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color.cardGray : .clear, in: .rect(cornerRadius: 16))
        .contentShape(.rect)
    }

    func sessionDetail(_ session: ScanSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                    .font(.title3)
                    .bold()

                Text("Sesi Mulai : \(session.startedAt, format: .dateTime.hour().minute())")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline) {
                    Text("\(session.totalCount)")
                        .font(.system(size: 72, weight: .bold))
                    Text("Ayam")
                        .font(.title3)
                        .bold()
                }

                HStack(spacing: 8) {
                    StatCard(freshness: .fresh, value: session.freshCount)
                    StatCard(freshness: .notFresh, value: session.notFreshCount)
                    StatCard(
                        title: "Waktu/Ayam",
                        value: Text(session.durationPerChicken, format: .units(allowed: [.seconds], width: .abbreviated))
                    )
                    StatCard(
                        title: "Total Waktu",
                        value: Text(session.duration, format: .units(allowed: [.hours, .minutes], width: .abbreviated))
                    )
                }
                .frame(maxWidth: 520)
            }

            recordTable
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
       
        .background(alignment: .topTrailing) {
            ChickenIllustration(pose: .searching, height: 300)
                .padding(.top, 16)
                .padding(.trailing, 24)
        }
        .background(.white, in: .rect(cornerRadius: 24))
        .clipShape(.rect(cornerRadius: 24))
    }

    var recordTable: some View {
        VStack(spacing: 8) {
            ZStack {
                Picker("Filter", selection: $viewModel.recordFilter) {
                    Text("Semua").tag(Freshness?.none)
                    ForEach(Freshness.allCases, id: \.self) { freshness in
                        Text(freshness.title).tag(Optional(freshness))
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)

                Button {
                    showsReference = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .popover(isPresented: $showsReference) {
                    referencePopover
                        .presentationCompactAdaptation(.popover)
                }
            }

            Table(viewModel.filteredRecords) {
                TableColumn(columnTitle("Waktu")) { record in
                    Text(record.scannedAt, format: .dateTime.hour().minute().second())
                }
                TableColumn(columnTitle("Ayam")) { record in
                    Text("#\(record.chickenNumber)")
                        .foregroundStyle(.primary)
                }
                TableColumn(columnTitle("Kondisi")) { record in
                    Text(record.freshness.title)
                        .foregroundStyle(record.freshness.tint)
                }
                TableColumn(columnTitle("Lembap %RH")) { record in
                    Text(record.humidity, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(.primary)
                }
                TableColumn(columnTitle("Gas%")) { record in
                    // lower gas % means worse, colored the same as its result
                    Text(record.gas, format: .number.precision(.fractionLength(0)))
                        .foregroundStyle(record.freshness == .notFresh ? Freshness.notFresh.tint : .primary)
                }
                TableColumn(columnTitle("Suhu°C")) { record in
                    Text(record.temperature, format: .number.precision(.fractionLength(1)))
                        .foregroundStyle(.primary)
                }
            }
            .scrollContentBackground(.hidden)
            // headers follow the tint, not foregroundStyle (tested on iPadOS 27);
            // Table also greys every column after the first, so cells set .primary themselves
            .tint(.secondary)
        }
        .padding(12)
        .background(Color.cardGray, in: .rect(cornerRadius: 16))
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


#Preview("Empty", traits: .landscapeLeft) {
    HomeScreen(viewModel: RecapViewModel()) {

    }
}

#Preview("With Sessions", traits: .landscapeLeft) {
    let sessions = (134...137).map { number in
        let startedAt = Date.now.addingTimeInterval(Double(number - 138) * 15 * 60)
        return ScanSession(
            number: number,
            startedAt: startedAt,
            endedAt: startedAt.addingTimeInterval(12 * 60),
            records: (1...20).map {
                let notFresh = $0.isMultiple(of: 4)
                return ScanRecord(
                    chickenNumber: $0,
                    scannedAt: startedAt.addingTimeInterval(Double($0) * 20),
                    freshness: notFresh ? .notFresh : .fresh,
                    humidity: 80 + Float($0 % 12),
                    gas: notFresh ? 18 + Float($0 % 5) : 30 + Float($0 * 7 % 40),
                    temperature: 26.4 + Float($0 % 6) * 0.9
                )
            }
        )
    }

    HomeScreen(viewModel: RecapViewModel(sessions: sessions)) {

    }
}
