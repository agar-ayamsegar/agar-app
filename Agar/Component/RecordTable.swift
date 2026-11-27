//
//  RecordTable.swift
//  Agar
//

import SwiftUI

/// The Waktu / Ayam / Kondisi table.
///
/// A white card with a grey block set inside it, so the white reads as a border all the way
/// around: above, below and on both sides. The grey takes whatever height is left whether or
/// not there are rows yet, rather than collapsing onto the header and leaving the card half
/// empty. Shared by the recap detail screen and the riwayat sheet; the sheet passes no
/// filter, so the segmented control is only built when there is one.
struct RecordTable: View {
    let records: [ScanRecord]
    var filter: Binding<Freshness?>?
    /// Long press a row to drop a scan that should not have been recorded.
    var onDelete: (ScanRecord) -> Void

    /// Keeps the column titles lined up under the segmented control above them rather than
    /// sitting further in than it.
    private let columnInset: CGFloat = 12

    var body: some View {
        VStack(spacing: 10) {
            if let filter {
                Picker("Filter", selection: filter) {
                    Text("Semua").tag(Freshness?.none)
                    ForEach(Freshness.allCases, id: \.self) { freshness in
                        Text(freshness.title).tag(Optional(freshness))
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(spacing: 0) {
                columnHeader

                if records.isEmpty {
                    Text("Belum ada ayam diperiksa")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(records) { record in
                                row(record)
                                    .contentShape(.rect)
                                    .contextMenu {
                                        Button("Hapus", systemImage: "trash", role: .destructive) {
                                            onDelete(record)
                                        }
                                    }

                                if record.id != records.last?.id {
                                    Divider().padding(.horizontal, columnInset)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.cardGray, in: .rect(cornerRadius: 14))
            .clipShape(.rect(cornerRadius: 14))
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.white, in: .rect(cornerRadius: 20))
    }

    private var columnHeader: some View {
        columns(
            waktu: Text("Waktu"),
            ayam: Text("Ayam"),
            kondisi: Text("Kondisi")
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.vertical, 10)
    }

    private func row(_ record: ScanRecord) -> some View {
        columns(
            waktu: Text(record.scannedAt, format: .dateTime.hour().minute().second()),
            ayam: Text("#\(record.chickenNumber)"),
            kondisi: Text(record.freshness.title).foregroundStyle(record.freshness.tint)
        )
        .font(.subheadline.weight(.semibold))
        .padding(.vertical, 13)
    }

    private func columns(waktu: Text, ayam: Text, kondisi: Text) -> some View {
        HStack(spacing: 0) {
            waktu.frame(maxWidth: .infinity, alignment: .leading)
            ayam.frame(maxWidth: .infinity, alignment: .leading)
            kondisi.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, columnInset)
    }
}


#Preview("with rows") {
    @Previewable @State var filter: Freshness?

    RecordTable(
        records: (1...12).map {
            ScanRecord(chickenNumber: $0, scannedAt: .now.addingTimeInterval(Double($0) * 18),
                       freshness: $0.isMultiple(of: 4) ? .notFresh : .fresh)
        },
        filter: $filter,
        onDelete: { _ in }
    )
    .padding()
    .background(Color.surfaceCream)
}

#Preview("empty") {
    RecordTable(records: []) { _ in }
        .padding()
        .background(Color.surfaceCream)
}
