//
//  AuthViewModel.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 09/01/26.
//


import Foundation
import Combine
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var session: Session?
    @Published var errorMessage: String?

    private let client = SupabaseConfig.client
    private var authTask: Task<Void, Never>?

    init() {
        // Listen semua perubahan auth (signedIn / signedOut / token refresh / initial)
        authTask = Task {
            for await state in await client.auth.authStateChanges {
                self.session = state.session
            }
        }
    }

    deinit { authTask?.cancel() }

    func signIn(email: String, password: String) async {
        do {
            errorMessage = nil
            _ = try await client.auth.signIn(email: email, password: password)
            // session akan ke-update otomatis dari authStateChanges
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            errorMessage = nil
            try await client.auth.signOut()
            // session akan ke-update jadi nil otomatis
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
