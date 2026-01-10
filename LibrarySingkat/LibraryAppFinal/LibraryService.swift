//
//  LibraryService.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//


import Foundation
import Supabase

final class LibraryService {
    private let client = SupabaseConfig.client

    // MARK: Members
    func fetchMembers() async throws -> [Member] {
        try await client
            .from("members")
            .select("id, member_code, name, email, phone, address")
            .order("member_code", ascending: true)
            .execute()
            .value
    }

    // MARK: Books
    func fetchAvailableBooks() async throws -> [Book] {
        try await client
            .from("books")
            .select("id, title, author, category, isbn, published_year, total_copies, available_copies, cover_url, is_deleted")
            .eq("is_deleted", value: false)
            .gt("available_copies", value: 0)
            .order("title", ascending: true)
            .execute()
            .value
    }

    // MARK: Staff - Books (all)
    func fetchAllBooks() async throws -> [Book] {
        try await client
            .from("books")
            .select("id, title, author, category, isbn, published_year, total_copies, available_copies, cover_url, is_deleted")
            .eq("is_deleted", value: false)
            .order("title", ascending: true)
            .execute()
            .value
    }
    
    // MARK: Staff - Soft delete books
    func softDeleteAllBooks() async throws {
        struct Patch: Codable { let is_deleted: Bool }
        _ = try await client
            .from("books")
            .update(Patch(is_deleted: true))
            .eq("is_deleted", value: false)   
            .execute()
    }
    

    // Optional: soft delete per book
    func softDeleteBook(id: UUID) async throws {
        struct Patch: Codable { let is_deleted: Bool }
        _ = try await client
            .from("books")
            .update(Patch(is_deleted: true))
            .eq("id", value: id.uuidString)
            .execute()
    }

    

    
    // MARK: Loans list (use view)
    func fetchLoansWithOverdue() async throws -> [LoanRow] {
        try await client
            .from("v_loans_with_overdue")
            .select("id, member_id, loan_date, due_date, status, computed_status, notes")
            .order("loan_date", ascending: false)
            .execute()
            .value
    }

    func fetchLoanItemsWithBookTitle(loanId: UUID) async throws -> [LoanItemWithBook] {
        
        struct Row: Codable {
            let id: UUID
            let loan_id: UUID
            let book_id: UUID
            let qty: Int
            let returned_qty: Int
            let books: BookTitle?
            struct BookTitle: Codable { let title: String }
        }

        let rows: [Row] = try await client
            .from("loan_items")
            .select("id, loan_id, book_id, qty, returned_qty, books(title)")
            .eq("loan_id", value: loanId.uuidString)
            .execute()
            .value

        return rows.map {
            LoanItemWithBook(
                id: $0.id,
                loan_id: $0.loan_id,
                book_id: $0.book_id,
                qty: $0.qty,
                returned_qty: $0.returned_qty,
                book_title: $0.books?.title
            )
        }
    }

    // MARK: Create Loan (insert loans + loan_items)
    func createLoan(memberId: UUID, loanDateISO: String, items: [(bookId: UUID, qty: Int)], notes: String?) async throws {
        // 1) insert into loans and return id
        struct LoanInsert: Codable {
            let member_id: UUID
            let loan_date: String
            let notes: String?
            // due_date will be set by trigger
            // status default ON_LOAN
        }

        struct LoanInserted: Codable {
            let id: UUID
        }

        let inserted: LoanInserted = try await client
            .from("loans")
            .insert(LoanInsert(member_id: memberId, loan_date: loanDateISO, notes: notes))
            .select("id")
            .single()
            .execute()
            .value

        // 2) insert loan_items (batch)
        struct LoanItemInsert: Codable {
            let loan_id: UUID
            let book_id: UUID
            let qty: Int
        }

        let payload = items.map { LoanItemInsert(loan_id: inserted.id, book_id: $0.bookId, qty: $0.qty) }

        _ = try await client
            .from("loan_items")
            .insert(payload)
            .execute()
    }

    // MARK: Member current loans (needs view v_member_current_loans)
    func fetchMemberCurrentLoans(memberId: UUID) async throws -> [MemberCurrentLoanRow] {
        try await client
            .from("v_member_current_loans")
            .select("member_id, member_code, member_name, loan_id, loan_date, due_date, status, book_id, book_title, qty")
            .eq("member_id", value: memberId.uuidString)
            .order("loan_date", ascending: false)
            .execute()
            .value
    }
    
    
    // Cari member by name (case-insensitive) dan ambil 1 yang pertama
    func findMemberByName(_ name: String) async throws -> Member? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }

        // PostgREST ilike pattern
        let members: [Member] = try await client
            .from("members")
            .select("id, member_code, name, email, phone, address")
            .ilike("name", pattern: trimmed)
            .limit(1)
            .execute()
            .value

        return members.first
    }
    
    func createMemberQuick(name: String) async throws -> Member {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { throw NSError(domain: "MemberNameEmpty", code: 0) }

            // member_code auto (simple): M + 4 digit random
            let code = "M" + String(Int.random(in: 1000...9999))

            struct Insert: Codable {
                let member_code: String
                let name: String
            }

            // return inserted row
            let inserted: Member = try await client
                .from("members")
                .insert(Insert(member_code: code, name: trimmed))
                .select("id, member_code, name, email, phone, address")
                .single()
                .execute()
                .value

            return inserted
        }
}

