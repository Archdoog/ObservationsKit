//
//  FulfillmentError.swift
//  ObservationTesting
//
//  Copyright (c) 2026 Jacob Fielding
//

import Foundation

public enum FulfillmentError<Value>: Error & Equatable where Value: Sendable & Equatable {
    case timedOut(remaining: [Value])
    case timedOutStrict(remaining: [Value])
    case timedOutWith(condition: String)
}

extension FulfillmentError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .timedOut(remaining):
            let remainingStr = remaining.map({ "\($0)" }).joined(separator: ", ")
            return "Timed out before `\(remainingStr)` was fulfilled."
        case let .timedOutStrict(remaining):
            let remainingStr = remaining.map({ "\($0)" }).joined(separator: ", ")
            return "Timed out before `\(remainingStr)` was not fulfilled strictly at expected order."
        case let .timedOutWith(condition):
            return "Timed out because condition at \(condition) unmet"
        }
    }
}
