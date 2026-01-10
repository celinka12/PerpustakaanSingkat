//
//  SupabaseConfig.swift
//  LibraryAppFinal
//
//  Created by Celinka E on 09/01/26.
//

import Foundation
import Supabase

enum SupabaseConfig {
    static let supabaseURL = URL(string: "https://dpcxjwihdfgrgobvhxlq.supabase.co")!
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwY3hqd2loZGZncmdvYnZoeGxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgwMTAzMjgsImV4cCI6MjA4MzU4NjMyOH0.wNdgMJgwEeOcSfx26Ws20QGCZ2lwvNjUMC2uInIxeYc"
    

    static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }()
}

