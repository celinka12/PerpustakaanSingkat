//
//  LoginView.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = LoginViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Login Petugas") {
                    TextField("Email", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $vm.password)
                        .textContentType(.password)

                    Button {
                        Task { await vm.login(auth: auth) }
                    } label: {
                        if vm.isLoading {
                            HStack { ProgressView(); Text("Loading...") }
                        } else {
                            Text("Login")
                        }
                    }
                    .disabled(!vm.canSubmit)
                }

                if let msg = auth.errorMessage {
                    Section {
                        Text(msg).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Library Login")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
