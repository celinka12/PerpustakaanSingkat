//
//  Models.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 10/01/26.
//

import Foundation

// MARK: - Members
struct Member: Codable, Identifiable, Hashable {
    let id: UUID
    let member_code: String
    let name: String
    let email: String?
    let phone: String?
    let address: String?
}

// MARK: - Books
struct Book: Codable, Identifiable, Hashable {
    let id: UUID
    let title: String
    let author: String?
    let category: String?
    let isbn: String?
    let published_year: Int?
    let total_copies: Int
    let available_copies: Int
    let cover_url: String?
    let is_deleted: Bool?
}


// MARK: - Loans (for list)
struct LoanRow: Codable, Identifiable, Hashable {
    let id: UUID
    let member_id: UUID
    let loan_date: String   // "YYYY-MM-DD"
    let due_date: String    // "YYYY-MM-DD"
    let status: String
    let computed_status: String?
    let notes: String?
}

// Join result: loan + member name (for UI)
struct LoanListItem: Identifiable, Hashable {
    let id: UUID
    let memberName: String
    let memberCode: String
    let loanDate: String
    let dueDate: String
    let status: String
    let itemCount: Int
}

// MARK: - Loan items + book title (for detail)
struct LoanItemWithBook: Codable, Identifiable, Hashable {
    let id: UUID
    let loan_id: UUID
    let book_id: UUID
    let qty: Int
    let returned_qty: Int
    // from join/books select alias
    let book_title: String?
}

// MARK: - Member current loans view
struct MemberCurrentLoanRow: Codable, Identifiable, Hashable {
    var id: String { "\(loan_id.uuidString)-\(book_id.uuidString)" }

    let member_id: UUID
    let member_code: String
    let member_name: String

    let loan_id: UUID
    let loan_date: String
    let due_date: String
    let status: String

    let book_id: UUID
    let book_title: String
    let qty: Int
}
