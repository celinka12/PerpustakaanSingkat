//
//  LoansView.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//


import SwiftUI

// MARK: - CreateLoanView

struct CreateLoanView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: LoansViewModel

    var onSaved: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Peminjam") {
                    TextField("Ketik nama peminjam", text: $vm.memberName)
                        .textInputAutocapitalization(.words)
                        .accessibilityIdentifier("createLoan_memberName")

                    if let picked = vm.pickedMember {
                        Text("Dipilih: \(picked.member_code) • \(picked.name)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Tanggal") {
                    DatePicker("Tanggal Pinjam", selection: $vm.loanDate, displayedComponents: .date)

                    HStack {
                        Text("Tanggal Harus Kembali")
                        Spacer()
                        Text(vm.dueDateISO)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Pilih Buku") {
                    TextField("Ketik judul buku", text: $vm.bookQuery)
                        .textInputAutocapitalization(.words)

                    if !vm.bookQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        if vm.filteredBooks.isEmpty {
                            Text("Tidak ada buku yang cocok")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(vm.filteredBooks.prefix(8)) { b in
                                Button { vm.pickBook(b) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(b.title)
                                            Text(b.author ?? "")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("Avail: \(b.available_copies)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if vm.selectedBooks.isEmpty {
                        Text("Belum ada buku dipilih")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(vm.selectedBooks) { b in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.title).font(.headline)
                                    Text(b.author ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button { vm.removeBook(b) } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.red)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                Section("Notes (opsional)") {
                    TextField("Notes", text: $vm.notes)
                }

                if let msg = vm.errorMessage {
                    Section { Text(msg).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Peminjaman Buku")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(vm.isSaving ? "Saving..." : "Save") {
                        Task {
                            do {
                                try await vm.saveNewLoan()
                                onSaved?()
                                dismiss()
                            } catch { }
                        }
                    }
                    .disabled(!vm.canSaveCreateLoan)
                    .accessibilityIdentifier("createLoan_save")
                }
               
            }
            .task {
                await vm.loadCreateDataIfNeeded()
            }
        }
    }
}

