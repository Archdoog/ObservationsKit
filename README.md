# ObservationKit

A small library that aims to make it possible for me to adopt the Observation framework now, instead of years in the future.

## ObservationShim

This is a copy of SwiftLang's [`Observations.swift`](https://github.com/phausler/ObservationSequence/blob/main/Sources/ObservationSequence/Observations.swift)
with some small tweaks to enable iOS 17+ compatibility. There are endless online discussions and dozens of projects that aim to enable the use of `AsyncSequence` 
and modern concurrency based streaming tools in favor of `Combine`. This one clicked thanks to this Swift Forums post 
[iOS 18 support for the Observations struct is being dropped before release?](https://forums.swift.org/t/ios-18-support-for-the-observations-struct-is-being-dropped-before-release/81942/5).

> [!IMPORTANT]  
> This is not aimed at replacing `Observations`. It's simply a shim you can use to start making real 
> use of the Apple Observations framework in favor of a bunch of bridges to other data sources like `Combine`

This example shows how you'd effectively erase the official and shimmed backport into an
`AsyncStream` to use outside of SwiftUI. Note Pointfree Co's [`ConcurrencyExtras`](https://github.com/pointfreeco/swift-concurrency-extras) 
was used to allow erasure into a clean `AsyncStream<Element>`.

```swift
func observableStream(
    _ emit: @escaping @isolated(any) @Sendable () -> Element
) -> AsyncStream<Element> {
    if #available(iOS 26.0, *) {
        let official = Observations(emit)
        return AsyncStream(official)
    } else {
        let backport = ObservationsShim(emit)
        return AsyncStream(backport)
    }
}
```

### References

- @vanvoorden [iOS 18 support for the Observations struct is being dropped before release?](https://forums.swift.org/t/ios-18-support-for-the-observations-struct-is-being-dropped-before-release/81942/5)
- @phausler [iOS 18 support for the Observations struct is being dropped before release?](https://forums.swift.org/t/ios-18-support-for-the-observations-struct-is-being-dropped-before-release/81942/6)
- [`Observations.swift`](https://github.com/phausler/ObservationSequence/blob/main/Sources/ObservationSequence/Observations.swift)

## ObservationTesting

Swift Testing introduced a new paradigm for async confirmation in [Testing asyncronous code](https://developer.apple.com/documentation/testing/testing-asynchronous-code). 
The swift tools are totally acceptable, but can be quite verbose and a bit tricky, especially testing outputs from `AsyncSequences`. 
The `ObservationTesting` library enables concise unit tests for `AsyncSequences`. This also works really well with `Observations` and `ObservationsShim`.

This includes verifying `Equatable` elements over time.

```swift
@Test("A value is emitted from the stream")
func basic() async throws {
    let stream = AsyncStream { continuation in
        continuation.yield("cats")
        continuation.yield("dogs")
        continuation.yield("lizards")
    }
    
    try await stream.fulfillment(of: "cats", "dogs", "lizards")
}
```

Or complex conditions that can't easily be represented as expected value(s).

```swift
@Test("A condition is verified on the stream")
func conditionMet() async throws {
    let stream = AsyncStream { continuation in
        continuation.yield("cats")
    }
    
    try await stream.fulfillment { value in
        value == "cats"
    }
}
```
