//
//  PageStateViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 24/10/26.
//

import SwiftUI


enum PageState {
    // TODO: add more on page
    case home
    case session(ScanSession)
    case connect
}

@Observable
class PageStateViewModel {
    private(set) var state: PageState = .home

    func setState(_ state: PageState) {
        self.state = state
    }
}
