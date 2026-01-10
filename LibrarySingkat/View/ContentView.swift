//
//  ContentView.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 09/01/26.
//

import SwiftUI
import Auth

struct ContentView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.session == nil {
            CatalogView()
        } else {
            StaffHomeView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())

}
