//
//  RecordTable.swift
//  Agar
//

import SwiftUI

/// The Waktu / Ayam / Kondisi table.
///
/// One white card with the column header as a grey strip inside it, rather than a grey card
/// wrapped around a white one. Shared by the recap detail screen and the riwayat sheet; the
/// sheet passes no filter, so the segmented control is only built when there is one.
struct RecordTable: View {
    let records: [ScanRecord]
    var filter: Binding<Freshness?>?
    var onInfo: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let filter {
                HStack(spacing: 10) {
                    Picker("Filter", selection: filter) {
                        Text("Semua").tag(Freshness?.none)
                        ForEach(Freshness.allCases, id: \.self) { freshness in
                            Text(freshness.title).tag(Optional(freshness))
                        }
                    }
                    .pickerStyle(.segmented)

                    if let onInfo {
                        Button(action: onInfo) {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.tint)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }

            columnHeader

            if records.isEmpty {
                Text("Belum ada ayam diperiksa")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(records) { record in
                            row(record)

                            if record.id != records.last?.id {
                                Divider().padding(.leading, 16)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.white, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.cardGray, lineWidth: 1.5)
        }
        // the grey header strip squares off against the card corners without this
        .clipShape(.rect(cornerRadius: 20))
    }

    private var columnHeader: some View {
        HStack {
            Text("Waktu").frame(maxWidth: .infinity, alignment: .leading)
            Text("Ayam").frame(maxWidth: .infinity, alignment: .leading)
            Text("Kondisi").frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.cardGray)
    }

    private func row(_ record: ScanRecord) -> some View {
        HStack {
            Text(record.scannedAt, format: .dateTime.hour().minute().second())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("#\(record.chickenNumber)")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.freshness.title)
                .foregroundStyle(record.freshness.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}


#Preview {
    @Previewable @State var filter: Freshness?

    RecordTable(
        records: (1...12).map {
            ScanRecord(chickenNumber: $0, scannedAt: .now.addingTimeInterval(Double($0) * 18),
                       freshness: $0.isMultiple(of: 4) ? .notFresh : .fresh)
        },
        filter: $filter,
        onInfo: {}
    )
    .padding()
    .background(Color.surfaceCream)
}
