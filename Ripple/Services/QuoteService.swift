//
//  QuoteService.swift
//  Ripple
//
//  Created by Brendon Young on 10/26/26.
//

import Foundation

final class QuoteService {

    static let shared = QuoteService()

    private let quoteURL: URL
    private let session: URLSession
    private let defaults: UserDefaults

    private let quoteKey = "cachedDailyQuote"
    private let dateKey = "cachedQuoteDate"

    private let fallbackQuote = Quote(
        text: "Every day is a new opportunity to improve.",
        author: "Ripple"
    )

    init(
        quoteURL: URL = URL(string: "https://zenquotes.io/api/today")!,
        session: URLSession = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.quoteURL = quoteURL
        self.session = session
        self.defaults = defaults
    }

    // Get today's quote
    func getDailyQuote() async -> Quote {

        // Return today's cached quote if available
        if let cachedQuote = loadCachedQuote() {
            return cachedQuote
        }

        do {
            let (data, response) = try await session.data(
                from: quoteURL
            )

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return fallbackQuote
            }

            let quotes = try JSONDecoder().decode(
                [Quote].self,
                from: data
            )

            guard let quote = quotes.first else {
                return fallbackQuote
            }

            saveQuote(quote)
            return quote

        } catch {
            print("Quote API error: \(error.localizedDescription)")
            return fallbackQuote
        }
    }

    // Save today's quote
    private func saveQuote(_ quote: Quote) {
        guard let data = try? JSONEncoder().encode(quote) else {
            return
        }

        defaults.set(data, forKey: quoteKey)
        defaults.set(Date(), forKey: dateKey)
    }

    // Load a quote saved today
    private func loadCachedQuote() -> Quote? {
        guard let savedDate = defaults.object(
            forKey: dateKey
        ) as? Date,
        Calendar.current.isDateInToday(savedDate),
        let data = defaults.data(forKey: quoteKey),
        let quote = try? JSONDecoder().decode(
            Quote.self,
            from: data
        ) else {
            return nil
        }

        return quote
    }
}

