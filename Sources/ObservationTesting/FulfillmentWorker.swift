//
//  FulfillmentWorker.swift
//  ObservationTesting
//
//  Copyright (c) 2026 Jacob Fielding
//

struct FulfillmentWorker {
    
    private let timeout: Duration?
    private let check: @Sendable () async throws -> Void
    private let testBehavior: @Sendable () async throws -> Void
    
    init(
        timeout: Duration?,
        check: @Sendable @escaping () async throws -> Void,
        testBehavior: @Sendable @escaping () async throws -> Void
    ) {
        self.timeout = timeout
        self.check = check
        self.testBehavior = testBehavior
    }
    
    func run() async throws {
        let checkTask = Task {
            try await check()
        }
        
        if let timeout {
            Task.detached(priority: .high) {
                try await Task.sleep(for: timeout)
                checkTask.cancel()
            }
        }
        
        let behaviorTask = Task.detached(priority: .high) {
            try await Task.sleep(for: .nanoseconds(50))
            try await self.testBehavior()
        }
        
        try await behaviorTask.value
        try await checkTask.value
    }
}
