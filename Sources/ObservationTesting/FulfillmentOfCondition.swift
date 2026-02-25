//
//  FulfillmentOfCondition.swift
//  ObservationTesting
//
//  Copyright (c) 2026 Jacob Fielding
//

extension AsyncSequence where Self: Sendable, Element: Sendable & Equatable {

  /// Fulfill a specific condition.
  ///
  /// - Parameters:
  ///   - condition:
  ///   - timeout: An optional timeout that will kill the function if fulfillment is unsuccessful by then.
  ///   - testBehavior: A test behavior to execute. Use this to execute state updates _after_ the stream is being listened to.
  public func fulfillment(
    condition: @Sendable @isolated(any) @escaping (Element?) async throws -> Bool,
    timeout: Duration? = nil,
    execute testBehavior: @Sendable @isolated(any) @escaping () async throws -> Void = {},
    file: StaticString = #file,
    line: UInt = #line
  ) async throws {
    let worker = FulfillmentWorker(
      timeout: timeout,
      check: {
        try await processCondition(condition: condition, file: file, line: line)
      },
      testBehavior: testBehavior
    )

    try await worker.run()
  }
}

extension AsyncSequence where Self: Sendable, Element: Sendable & Equatable {

  func processCondition(
    condition: @Sendable @isolated(any) @escaping (Element?) async throws -> Bool,
    file: StaticString = #file,
    line: UInt = #line
  ) async throws {
    var iterator = self.makeAsyncIterator()

    while !Task.isCancelled {
      let value = try await iterator.next()

      if try await condition(value) {
        return
      }
    }

    do {
      try Task.checkCancellation()
    } catch {
      throw FulfillmentError<String>.timedOutWith(condition: "\(file):\(line)")
    }
  }
}
