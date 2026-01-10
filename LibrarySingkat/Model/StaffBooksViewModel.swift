//
//  StaffBooksViewModel.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//


import Foundation
import Combine

@MainActor
final class StaffBooksViewModel: ObservableObject {
    private let service: LibraryService

    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(service: LibraryService = LibraryService()) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil
            books = try await service.fetchAllBooks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func trashAllBooks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil
            try await service.softDeleteAllBooks()
            books = []             
            books = try await service.fetchAllBooks() // reload (yang is_deleted=false)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func trash(book: Book) async {
        do {
            errorMessage = nil
            try await service.softDeleteBook(id: book.id)
            books.removeAll { $0.id == book.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    
}
