//
//  ThrottleTests.swift
//  Gather BibleTests
//
//  Tests for Throttle utility
//

import Testing
import Foundation

@testable import Gather_Bible

struct ThrottleTests {

    @Test func testImmediateExecution() async throws {
        let throttle = Throttle(interval: 0.1)
        var executed = false

        throttle.run {
            executed = true
        }

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(executed == true)
    }

    @Test func testThrottlesRapidCalls() async throws {
        let throttle = Throttle(interval: 0.1)
        var executionCount = 0

        for _ in 0..<5 {
            throttle.run {
                executionCount += 1
            }
        }

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(executionCount == 1)
    }

    @Test func testExecutesPendingWorkAfterInterval() async throws {
        let throttle = Throttle(interval: 0.05)
        var values: [Int] = []
        let lock = NSLock()

        throttle.run {
            lock.lock()
            values.append(1)
            lock.unlock()
        }

        throttle.run {
            lock.lock()
            values.append(2)
            lock.unlock()
        }

        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        lock.lock()
        let finalValues = values
        lock.unlock()

        #expect(finalValues.count == 2)
        #expect(finalValues.first == 1)
        #expect(finalValues.last == 2)
    }

    @Test func testCancelPendingWork() async throws {
        let throttle = Throttle(interval: 0.1)
        var executionCount = 0

        throttle.run {
            executionCount += 1
        }

        throttle.run {
            executionCount += 1
        }

        throttle.cancel()

        try await Task.sleep(nanoseconds: 150_000_000) // 150ms
        #expect(executionCount == 1)
    }

    @Test func testAllowsExecutionAfterInterval() async throws {
        let throttle = Throttle(interval: 0.05)
        var executionCount = 0

        throttle.run {
            executionCount += 1
        }

        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        throttle.run {
            executionCount += 1
        }

        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        #expect(executionCount == 2)
    }
}
