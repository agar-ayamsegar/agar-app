//
//  RecapViewModel.swift
//  Agar
//
//  Created by fikrahdamars on 29/10/26.
//

import SwiftUI


@Observable
class RecapViewModel {
    var selectedDate: Date = .now
    var selectedSessionID: ScanSession.ID?
    var recordFilter: Freshness?
}
