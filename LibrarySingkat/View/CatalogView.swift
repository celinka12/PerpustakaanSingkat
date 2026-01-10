//
//  CatalogView.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//

import SwiftUI

struct CatalogView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var vm = CatalogViewModel()

    @State private var showLogin = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.books.isEmpty {
                    ProgressView("Loading katalog...")
                } else {
                    List(vm.filtered) { b in
                        HStack(alignment: .top, spacing: 12) {

                            BookCoverView(urlString: b.cover_url)
                                .frame(width: 52, height: 72)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(b.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(b.author ?? "Unknown author")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)

                                HStack {
                                    Text(b.category ?? "Uncategorized")
                                    Spacer()
                                    Text("Avail: \(b.available_copies)/\(b.total_copies)")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Katalog")
            .searchable(text: $vm.query, prompt: "Cari judul / author / ISBN")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // kalau belum login, baru munculin login
                        if auth.session == nil {
                            showLogin = true
                        }
                       
                    } label: {
                        Label("Petugas", systemImage: "person.badge.key")
                    }
                    .accessibilityIdentifier("open_staff_login")
                }
            }
            .sheet(isPresented: $showLogin) {
                LoginView()
                    .environmentObject(auth)
            }
            .task { await vm.load() }
            .refreshable { await vm.load() }
            .overlay {
                if let msg = vm.errorMessage {
                    ContentUnavailableView(
                        "Gagal load katalog",
                        systemImage: "exclamationmark.triangle",
                        description: Text(msg)
                    )
                }
            }
        }
    }
}

// MARK: - Cover Component
private struct BookCoverView: View {
    let urlString: String?

    var body: some View {
        let url = URL(string: urlString ?? "")

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Image(systemName: "book.closed")
                            .imageScale(.large)
                            .foregroundStyle(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "book.closed")
                    .imageScale(.large)
                    .foregroundStyle(.secondary)
            }
        }
        .clipped()
    }
}

#Preview {
    CatalogView()
        .environmentObject(AuthViewModel())
}
