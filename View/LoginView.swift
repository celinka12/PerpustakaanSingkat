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
                    TextField("Email", text: $vm.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("login_email")
                    
                    SecureField("Password", text: $vm.password)
                        .textContentType(.password)
                        .accessibilityIdentifier("login_password")

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
                    .accessibilityIdentifier("login_submit")
            
                if let msg = auth.errorMessage {
                    Section {
                        Text(msg).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Login Petugas")
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
