//
//  LibraryAppFinalApp.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 09/01/26.
//

import SwiftUI

@main
struct LibraryAppApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
        }

    }
}
