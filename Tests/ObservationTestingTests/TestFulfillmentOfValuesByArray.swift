//
//  TestFulfillmentOfValuesByArray.swift
//  ObservationTestingTests
//
//  Copyright (c) 2026 Jacob Fielding
//

import Foundation
import Numerics
import Testing

@testable import ObservationTesting

struct TestFulfillmentOfValuesByArray {

  @Test("A value is emitted from the stream")
  func basic() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("cats")
    }

    try await stream.fulfillment(values: ["cats"])
  }

  @Test("A value is not emitted from the stream")
  func failure() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("cats")
    }

    let executionStart = Date()

    do {
      try await stream.fulfillment(values: ["dogs"], timeout: .seconds(1))
      Issue.record("Function should fail with a throw")
    } catch let error as FulfillmentError<String> {
      #expect(error == .timedOut(remaining: ["dogs"]))
      #expect(error.localizedDescription == "Timed out before `dogs` was fulfilled.")

      let duration = Date().timeIntervalSince(executionStart)
      #expect(
        duration.isApproximatelyEqual(to: 1.0, relativeTolerance: 0.2),
        "timeout is close to expected runtime")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("A value is emitted in the stream in strict order")
  func strict() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("dogs")
      continuation.yield("cats")
    }

    try await stream.fulfillment(values: ["dogs", "cats"], strict: true, timeout: .seconds(1))
  }

  @Test("Strictly checked fails when order out of alignment")
  func strictlyOutOfOrder() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("dogs")
      continuation.yield("cats")
    }

    let executionStart = Date()

    do {
      try await stream.fulfillment(values: ["cats", "dogs"], strict: true, timeout: .seconds(1))
      Issue.record("Function should fail with a throw")
    } catch let error as FulfillmentError<String> {
      #expect(error == .timedOutStrict(remaining: ["dogs"]))
      #expect(
        error.localizedDescription
          == "Timed out before `dogs` was not fulfilled strictly at expected order.")

      let duration = Date().timeIntervalSince(executionStart)
      #expect(
        duration.isApproximatelyEqual(to: 1.0, relativeTolerance: 0.2),
        "timeout is close to expected runtime")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
