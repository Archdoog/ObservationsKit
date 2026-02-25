//
//  TestObservationShim.swift
//  ObservationShimTests
//
//  Copyright (c) 2026 Jacob Fielding
//

import Observation
import ObservationTesting
import Testing

@testable import ObservationShim

@MainActor
@Observable
final class Foo {
  var bar: String?
  var baz: Int?

  func set(bar: String) {
    self.bar = bar
  }

  func set(baz: Int) {
    self.baz = baz
  }
}

struct TestObservationShim {

  @MainActor
  @Test("A basic legacy stream on iOS 17")
  func basic() async throws {
    let foo = Foo()

    let stream = ObservationsShim {
      foo.bar
    }

    Task.detached {
      await foo.set(bar: "cats")
      try await Task.sleep(for: .microseconds(500))
      await foo.set(bar: "dogs")
      try await Task.sleep(for: .milliseconds(500))
      await foo.set(bar: "lizards")
    }

    try await stream.fulfillment(of: "cats", "dogs", "lizards")
  }
}
