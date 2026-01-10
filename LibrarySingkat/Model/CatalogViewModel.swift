//
//  CatalogViewModel.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//


import Foundation
import Combine

@MainActor
final class CatalogViewModel: ObservableObject {
    private let service: LibraryService

    @Published var books: [Book] = []
    @Published var query: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    init(service: LibraryService = LibraryService()) {
        self.service = service
    }

    var filtered: [Book] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(q)
            || ($0.author?.localizedCaseInsensitiveContains(q) ?? false)
            || ($0.category?.localizedCaseInsensitiveContains(q) ?? false)
            || ($0.isbn?.localizedCaseInsensitiveContains(q) ?? false)
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil
            // ini perlu function service untuk semua buku
            books = try await service.fetchAvailableBooks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
