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
   
    var selectedDate: Date = .now
    var selectedSessionID: ScanSession.ID?

    var recordFilter: Freshness?

    init(sessions: [ScanSession] = []) {
        self.sessions = sessions
    }

    var filteredSessions: [ScanSession] {
        sessions.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: selectedDate) }
    }


    var selectedSession: ScanSession? {
        filteredSessions.first { $0.id == selectedSessionID } ?? filteredSessions.first
    }

    var filteredRecords: [ScanRecord] {
        guard let records = selectedSession?.records else { return [] }
        guard let recordFilter else { return records }

        return records.filter { $0.freshness == recordFilter }
    }

    func makeSession() -> ScanSession {
        let nextNumber = (sessions.map(\.number).max() ?? 0) + 1
        return ScanSession(number: nextNumber)
    }

    func add(_ session: ScanSession) {
        sessions.append(session)
        selectedDate = session.startedAt
        selectedSessionID = session.id
        recordFilter = nil
    }
}
