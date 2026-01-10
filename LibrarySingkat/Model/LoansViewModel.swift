
//
//  LoansViewModel.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//

import Foundation
import Combine

@MainActor
final class LoansViewModel: ObservableObject {
    private let service: LibraryService

    // MARK: - Loans List State
    @Published var loans: [LoanListItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showCreateLoan = false

    // items per loan
    @Published var itemsByLoan: [UUID: [LoanItemWithBook]] = [:]
    @Published var loadingLoanIds: Set<UUID> = []
    @Published var expandedLoanIds: Set<UUID> = []

    // MARK: - Create Loan Form State (gabung dari CreateLoanViewModel)
    @Published var memberName: String = ""
    @Published var pickedMember: Member? = nil

    @Published var books: [Book] = []
    @Published var loanDate: Date = Date()
    @Published var notes: String = ""

    @Published var bookQuery: String = ""
    @Published var selectedBookIDs: Set<UUID> = []

    @Published var isSaving: Bool = false
    @Published var createErrorMessage: String? = nil

    init(service: LibraryService = LibraryService()) {
        self.service = service
    }

    // MARK: - Load Loans
    func loadLoans() async {
        isLoading = true
        defer { isLoading = false }

        do {
            errorMessage = nil

            let rows = try await service.fetchLoansWithOverdue()
            let members = try await service.fetchMembers()
            let memberMap = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })

            loans = rows.map { r in
                let m = memberMap[r.member_id]
                return LoanListItem(
                    id: r.id,
                    memberName: m?.name ?? "-",
                    memberCode: m?.member_code ?? "-",
                    loanDate: r.loan_date,
                    dueDate: r.due_date,
                    status: (r.computed_status ?? r.status),
                    itemCount: 0
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Expand / Collapse
    func toggleExpand(_ loanId: UUID, isExpanded: Bool) {
        if isExpanded {
            expandedLoanIds.insert(loanId)
            Task { await loadItemsIfNeeded(for: loanId) }
        } else {
            expandedLoanIds.remove(loanId)
        }
    }

    // MARK: - Load items per loan (lazy + cache)
    func loadItemsIfNeeded(for loanId: UUID) async {
        if itemsByLoan[loanId] != nil { return }
        if loadingLoanIds.contains(loanId) { return }

        loadingLoanIds.insert(loanId)
        defer { loadingLoanIds.remove(loanId) }

        do {
            let items = try await service.fetchLoanItemsWithBookTitle(loanId: loanId)
            itemsByLoan[loanId] = items
        } catch {
            itemsByLoan[loanId] = []
        }
    }

    func resetCache() {
        itemsByLoan.removeAll()
        loadingLoanIds.removeAll()
        expandedLoanIds.removeAll()
    }

    // MARK: - Sheet
    func openCreateLoan() {
        showCreateLoan = true
        // optional: reset form tiap buka
        resetCreateForm()
        Task { await loadCreateDataIfNeeded() }
    }

    func closeCreateLoan() {
        showCreateLoan = false
    }

    // MARK: - Create Loan (Derived)
    var dueDateISO: String {
        let due = Calendar.current.date(byAdding: .day, value: 7, to: loanDate) ?? loanDate
        return isoDate(due)
    }

    var canSaveCreateLoan: Bool {
        let nameOk = !memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pickedMember != nil
        return nameOk && !selectedBookIDs.isEmpty && !isSaving
    }

    var filteredBooks: [Book] {
        let q = bookQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        return books
            .filter { $0.available_copies > 0 }
            .filter { !selectedBookIDs.contains($0.id) }
            .filter {
                $0.title.localizedCaseInsensitiveContains(q)
                || ($0.author?.localizedCaseInsensitiveContains(q) ?? false)
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var selectedBooks: [Book] {
        books
            .filter { selectedBookIDs.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    // MARK: - Create Loan Actions
    func loadCreateDataIfNeeded() async {
        // biar ga refetch terus tiap buka sheet
        if !books.isEmpty { return }
        await loadCreateData()
    }

    func loadCreateData() async {
        isSaving = true
        defer { isSaving = false }

        do {
            createErrorMessage = nil
            books = try await service.fetchAvailableBooks()
        } catch {
            createErrorMessage = error.localizedDescription
        }
    }

    func pickBook(_ book: Book) {
        guard book.available_copies > 0 else { return }
        selectedBookIDs.insert(book.id)
        bookQuery = ""
    }
//
    func removeBook(_ book: Book) {
        selectedBookIDs.remove(book.id)
    }

    func resetCreateForm() {
        memberName = ""
        pickedMember = nil
        loanDate = Date()
        notes = ""
        bookQuery = ""
        selectedBookIDs.removeAll()
        createErrorMessage = nil
    }

    func saveNewLoan() async throws {
        isSaving = true
        defer { isSaving = false }

        createErrorMessage = nil

        // 1) validasi
        let name = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        if pickedMember == nil && name.isEmpty {
            createErrorMessage = "Nama anggota harus diisi."
            throw NSError(domain: "CreateLoan", code: 1)
        }
        if selectedBookIDs.isEmpty {
            createErrorMessage = "Pilih minimal 1 buku."
            throw NSError(domain: "CreateLoan", code: 2)
        }

        // 2)  member
        let member: Member
        do {
            if let existing = pickedMember {
                member = existing
            } else if let found = try await service.findMemberByName(name) {
                member = found
                pickedMember = found
            } else {
                member = try await service.createMemberQuick(name: name)
                pickedMember = member
            }
        } catch {
            createErrorMessage = "Gagal memproses anggota: \(error.localizedDescription)"
            throw error
        }

        // 3) items qty = 1 per book
        let loanDateISO = isoDate(loanDate)
        let items: [(bookId: UUID, qty: Int)] = selectedBookIDs.map { ($0, 1) }

        // 4) create loan
        do {
            try await service.createLoan(
                memberId: member.id,
                loanDateISO: loanDateISO,
                items: items,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
            )
        } catch {
            createErrorMessage = "Gagal menyimpan peminjaman: \(error.localizedDescription)"
            throw error
        }
    }

    // MARK: - Helpers
    private func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
