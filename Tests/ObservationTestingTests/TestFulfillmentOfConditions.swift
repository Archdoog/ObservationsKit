//
//  TestFulfillmentOfConditions.swift
//  ObservationTestingTests
//
//  Copyright (c) 2026 Jacob Fielding
//

import Foundation
import Numerics
import Testing

@testable import ObservationTesting

struct TestFillmentOfConditions {

  @Test("A condition is verified on the stream")
  func conditionMet() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("cats")
    }

    try await stream.fulfillment { value in
      value == "cats"
    }
  }

  @Test("A value is not emitted from the stream")
  func conditionNotMet() async throws {
    let stream = AsyncStream { continuation in
      continuation.yield("cats")
    }

    let executionStart = Date()

    do {
      try await stream.fulfillment(
        condition: { value in
          value == "dogs"
        },
        timeout: .seconds(1)
      )

      Issue.record("Function should fail with a throw")
    } catch let error as FulfillmentError<String> {
      #expect(
        error
          == .timedOutWith(
            condition: "ObservationTestingTests/TestFulfillmentOfConditions.swift:28"))
      #expect(
        error.localizedDescription
          == "Timed out because condition at ObservationTestingTests/TestFulfillmentOfConditions.swift:28 unmet"
      )

      let duration = Date().timeIntervalSince(executionStart)
      #expect(
        duration.isApproximatelyEqual(to: 1.0, relativeTolerance: 0.2),
        "timeout is close to expected runtime")
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
