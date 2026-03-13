//
//  SupabaseClient.swift
//  PhotoMap
//
//  Created on 3/13/26.
//
import Foundation
import Supabase

private let secrets: [String: String] = {
    guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
          let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
        fatalError("Secrets.plist not found")
    }
    return dict
}()

let supabase = SupabaseClient(
    supabaseURL: URL(string: secrets["SUPABASE_URL"]!)!,
    supabaseKey: secrets["SUPABASE_ANON_KEY"]!
)
