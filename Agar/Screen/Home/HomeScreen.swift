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
    @State private var bidingstatus = false

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
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                Text("Rekap Sesi")
                    .font(.largeTitle.bold())
                Spacer()
                    datePicker

            }
            .padding(.horizontal)

            DetailPanel {
                ContentUnavailableView {
                    ChickenIllustration(pose: .searching, height: 200)
                } description: {
                    Text(viewModel.sessions.isEmpty ? "Mulai Tambahkan Sesi" : "Tidak ada sesi di tanggal ini")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            
            .padding(.horizontal)
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
        .padding(.top, 8)
    
            
        
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
            HStack {
                Text("Rekap Sesi")
                    .font(.largeTitle)
                    .bold()

                Spacer()

                datePicker

               
            }
            HStack(alignment: .top, spacing: 12) {
                
                sessionList(selected: session)
            }
           

            Button("Mulai Pemeriksaan", action: onStartScan)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(.actionBlue)
                .buttonSizing(.flexible)
    
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color.surfaceCream.ignoresSafeArea())
    }

    func sessionList(selected: ScanSession) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(viewModel.filteredSessions) { session in
                    NavigationLink {
                        sessionDetail(session)
                    } label: {
                        SessionCard(session: session, isSelected: session.id == selected.id)    
                    }
                 
                    .buttonStyle(.plain)
                    
                }
                .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.cardGray, lineWidth: 2)
                )
                .padding(5)
            }
            .padding(8)
            
        }
        .frame(maxHeight: .infinity)
        .background(.white, in: .rect(cornerRadius: 24))
        
    }

    func sessionDetail(_ session: ScanSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
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

            VStack(alignment: .leading, spacing: 4) {
                
                VStack(alignment: .leading, spacing: 4){
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(session.totalCount)")
                            .font(.system(size: 72, weight: .bold))
                        Text("Ayam")
                            .font(.title3)
                            .bold()
                        
                        
                    }
                    HStack{
                        StatCard(freshness: .fresh, value: session.freshCount)
                        StatCard(freshness: .notFresh, value: session.notFreshCount)
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.white)))
                .frame(maxWidth: 520)
            }

            recordTable
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.surfaceCream)
        .toolbar(.hidden, for: .navigationBar)
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

            HStack {
                Text("Waktu").frame(maxWidth: .infinity, alignment: .leading)
                Text("Ayam").frame(maxWidth: .infinity, alignment: .leading)
                Text("Kondisi").frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredRecords) { record in
                        HStack {
                            Text(record.scannedAt, format: .dateTime.hour().minute().second())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("#\(record.chickenNumber)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(record.freshness.title)
                                .foregroundStyle(record.freshness.tint)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(.white, in: .rect(cornerRadius: 12))
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
    NavigationStack{
        HomeScreen(viewModel: RecapViewModel(sessions: sessions)) {
            
        }
    }
}
