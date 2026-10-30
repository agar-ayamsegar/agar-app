//
//  RecapViewModel.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI


@Observable
class RecapViewModel {
    // MARK: - state variable
    private(set) var sessions: [ScanSession]
    var searchQuery: String = ""

    init(sessions: [ScanSession] = []) {
        self.sessions = sessions
    }

    // "16 Oktober 2026" format
    var filteredSessions: [ScanSession] {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sessions }

        let dateStyle = Date.FormatStyle.dateTime.day().month(.wide).year().locale(Locale(identifier: "id_ID"))
        return sessions.filter { $0.startedAt.formatted(dateStyle).localizedCaseInsensitiveContains(query) }
    }

    func makeSession() -> ScanSession {
        let nextNumber = (sessions.map(\.number).max() ?? 0) + 1
        return ScanSession(number: nextNumber)
    }

    func add(_ session: ScanSession) {
        sessions.insert(session, at: 0)
    }
}
