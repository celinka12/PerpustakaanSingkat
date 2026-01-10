//
//  StaffHomeView.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//
import SwiftUI

struct StaffHomeView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LoansSectionView()
                    .navigationTitle("Loans")
            }
            .tabItem { Label("Loans", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                BooksSectionView()
                    .navigationTitle("Books")
            }
            .tabItem { Label("Books", systemImage: "books.vertical") }

            NavigationStack {
                AccountSectionView()
                    .navigationTitle("Account")
            }
            .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}

// MARK: - LOANS
private struct LoansSectionView: View {
    @StateObject private var vm = LoansViewModel()

    var body: some View {
        List {
            if vm.isLoading && vm.loans.isEmpty {
                HStack { Spacer(); ProgressView("Loading loans..."); Spacer() }
            } else {
                ForEach(vm.loans) { loan in
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        Text(loan.memberName).font(.headline)
                        Spacer()
                        StatusChip(status: loan.status)
                    }

                    Text("Loan: \(loan.loanDate) → Due: \(loan.dueDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // DETAIL (langsung muncul)
                    Text("Buku dipinjam:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if vm.loadingLoanIds.contains(loan.id) && vm.itemsByLoan[loan.id] == nil {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading buku...")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)

                    } else if let items = vm.itemsByLoan[loan.id], !items.isEmpty {
                        ForEach(items) { it in
                            HStack {
                                Text(it.book_title ?? "Unknown title")
                                    .font(.subheadline)
                                Spacer()
                                Text("x\(it.qty)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                    } else {
                        Text("Tidak ada item buku.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
                .task {
                    await vm.loadItemsIfNeeded(for: loan.id)
                }
            }
}
        }
        .listStyle(.insetGrouped)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { Task { await vm.loadLoans() } } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { vm.openCreateLoan() } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await vm.loadLoans() }
        .refreshable {
            await vm.loadLoans()
            vm.resetCache()
        }
        .sheet(isPresented: $vm.showCreateLoan, onDismiss: {
            Task { await vm.loadLoans() }
        }) {
            CreateLoanView(vm: vm, onSaved: {
                vm.closeCreateLoan()
            })
        }
        .overlay(alignment: .bottom) {
            if let msg = vm.errorMessage {
                Text(msg)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct StatusChip: View {
    let status: String
    
    var body: some View {
        let s = status.lowercased()
        
        Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(s == "overdue" ? .red :
                            s == "returned" ? .gray :
                            s == "on_loan" ? .green :
                    .blue )
                .clipShape(Capsule())
    }
}


// MARK: - BOOKS (view-only + cover)
private struct BooksSectionView: View {
    @StateObject private var vm = StaffBooksViewModel()
    @State private var query = ""

    private var filtered: [Book] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return vm.books }
        return vm.books.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            ($0.author?.localizedCaseInsensitiveContains(q) ?? false) ||
            ($0.isbn?.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    var body: some View {
        List {
            if vm.isLoading && vm.books.isEmpty {
                HStack { Spacer(); ProgressView("Loading books..."); Spacer() }

            } else if filtered.isEmpty {
                Text("Tidak ada buku yang cocok.")
                    .foregroundStyle(.secondary)

            } else {
                ForEach(filtered) { b in
                    BookRowView(book: b, onTrash: {
                        Task { await vm.trash(book: b) }
                    })
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, prompt: "Cari judul / author / ISBN")
        .task { await vm.load() }
        .refreshable { await vm.load() }
        .overlay(alignment: .bottom) {
            if let msg = vm.errorMessage {
                Text(msg)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct BookRowView: View {
    let book: Book
    var onTrash: (() -> Void)? = nil

    @State private var showDeleteAlert = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: book.cover_url ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(.thinMaterial)
                        ProgressView()
                    }
                    .frame(width: 48, height: 70)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 70)
                        .clipped()
                        .cornerRadius(10)
                default:
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(.thinMaterial)
                        Image(systemName: "book.closed").foregroundStyle(.secondary)
                    }
                    .frame(width: 48, height: 70)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)

                    Spacer()

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .padding(.leading, 6)
                    .alert("Hapus buku ini?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            onTrash?()
                        }
                    } message: {
                        Text("\"\(book.title)\" akan dipindahkan ke Trash.")
                    }
                }

                Text(book.author ?? "Unknown author")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Text(book.category ?? "Uncategorized").lineLimit(1)
                    Spacer()
                    Text("Avail: \(book.available_copies)/\(book.total_copies)")
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}



// MARK: - ACCOUNT
private struct AccountSectionView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("Staff Account")
                .font(.title3).bold()

            Button(role: .destructive) {
                Task { await auth.signOut() }
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .padding()
    }
}

#Preview {
    StaffHomeView()
        .environmentObject(AuthViewModel())
}
