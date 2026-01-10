//
//  LoginViewModel.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false

    var canSubmit: Bool {
        !isLoading &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    func login(auth: AuthViewModel) async {
        isLoading = true
        defer { isLoading = false }

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        await auth.signIn(email: e, password: password)
    }
}

