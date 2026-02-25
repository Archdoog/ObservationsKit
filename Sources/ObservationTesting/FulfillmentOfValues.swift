//
//  FulfillmentOfValues.swift
//  ObservationTesting
//
//  Copyright (c) 2026 Jacob Fielding
//

public extension AsyncSequence where Self: Sendable, Element: Sendable & Equatable {

    /// Fulfill one or more values.
    ///
    /// - Parameters:
    ///   - values: One or values that must be emitted by the stream to succeed.
    ///   - strict: If true, values must emitted in order.
    ///   - timeout: An optional timeout that will kill the function if fulfillment is unsuccessful by then.
    ///   - testBehavior: A test behavior to execute. Use this to execute state updates _after_ the stream is being listened to.
    func fulfillment(
        of values: Element...,
        strict: Bool = false,
        timeout: Duration? = nil,
        execute testBehavior: @Sendable @isolated(any) @escaping () async throws -> Void = {}
    ) async throws {
        let worker = FulfillmentWorker(
            timeout: timeout,
            check: {
                try await processFulfillment(values: values, strict: strict)
            },
            testBehavior: testBehavior
        )

        try await worker.run()
    }

    /// Fulfill an array of values.
    ///
    /// - Parameters:
    ///   - values: One or values that must be emitted by the stream to succeed.
    ///   - strict: If true, values must emitted in order.
    ///   - timeout: An optional timeout that will kill the function if fulfillment is unsuccessful by then.
    ///   - testBehavior: A test behavior to execute. Use this to execute state updates _after_ the stream is being listened to.
    func fulfillment(
        values: [Element],
        strict: Bool = false,
        timeout: Duration? = nil,
        execute testBehavior: @Sendable @isolated(any) @escaping () async throws -> Void = {}
    ) async throws {
        let worker = FulfillmentWorker(
            timeout: timeout,
            check: {
                try await processFulfillment(values: values, strict: strict)
            },
            testBehavior: testBehavior
        )

        try await worker.run()
    }
}

extension AsyncSequence where Self: Sendable, Element: Sendable & Equatable {

    func processFulfillment(values: [Element], strict: Bool) async throws {
        var remainingValues = values
        var iterator = self.makeAsyncIterator()

        while !Task.isCancelled, !remainingValues.isEmpty {
            let value = try await iterator.next()

            if strict && remainingValues.first == value {
                remainingValues.remove(at: 0)
            } else if !strict, let index = remainingValues.firstIndex(where: { $0 == value }) {
                remainingValues.remove(at: index)
            }
        }

        do {
            try Task.checkCancellation()
        } catch {
            if strict {
                throw FulfillmentError.timedOutStrict(remaining: remainingValues)
            } else {
                throw FulfillmentError.timedOut(remaining: remainingValues)
            }
        }
    }
}
