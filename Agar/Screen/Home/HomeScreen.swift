//
//  HomeScreen.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


// "Rekap Sesi" — list of past sessions
struct HomeScreen: View {
    @Bindable var viewModel: RecapViewModel
    var onStartScan: () -> Void

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
                .navigationTitle("Rekap Sesi")
                .searchable(text: $viewModel.searchQuery, placement: .sidebar, prompt: "Cari Tanggal")
                .navigationSplitViewColumnWidth(340)
                .containerBackground(.white, for: .navigation)
                .toolbar(removing: .sidebarToggle)
        } detail: {
            // TODO: show selected session detail once the design is ready
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


// MARK: - sidebar
private extension HomeScreen {
    var sidebar: some View {
        Group {
            if viewModel.filteredSessions.isEmpty && !viewModel.searchQuery.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchQuery)
            } else if viewModel.filteredSessions.isEmpty {
                Text("Mulai Tambahkan Sesi")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredSessions) { session in
                    sessionRow(session)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
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
    }

    func sessionRow(_ session: ScanSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sesi Scan Ayam #\(session.number)")
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)

            Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                .font(.headline)

            Text("\(session.totalCount) ayam · \(session.freshCount) segar · \(session.notFreshCount) tidak segar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}


#Preview("Empty", traits: .landscapeLeft) {
    HomeScreen(viewModel: RecapViewModel()) {

    }
}

#Preview("With Sessions", traits: .landscapeLeft) {
    let sessions = [
        ScanSession(number: 137, records: [
            ScanRecord(chickenNumber: 1, freshness: .fresh),
            ScanRecord(chickenNumber: 2, freshness: .notFresh),
        ]),
    ]

    HomeScreen(viewModel: RecapViewModel(sessions: sessions)) {

    }
}
