//
//  Throttle.swift
//  Gather Bible
//
//  Throttle utility for limiting update frequency
//

import Foundation

/// Throttle utility for limiting update frequency
/// Ensures that a given action is executed at most once per specified time interval
final class Throttle: @unchecked Sendable {
    private let interval: TimeInterval
    private let scheduler: DispatchQueue
    private var lastExecution: Date?
    private var pendingWork: (() -> Void)?
    private let lock = NSLock()

    init(interval: TimeInterval, scheduler: DispatchQueue = .global(qos: .userInitiated)) {
        self.interval = interval
        self.scheduler = scheduler
    }

    func run(work: @escaping () -> Void) {
        scheduler.async { [weak self] in
            guard let self = self else { return }

            self.lock.lock()
            let now = Date()

            if let lastExecution = self.lastExecution,
               now.timeIntervalSince(lastExecution) < self.interval
            {
                if self.pendingWork == nil {
                    self.pendingWork = work
                    let delay = self.interval - now.timeIntervalSince(lastExecution)
                    self.lock.unlock()

                    self.scheduler.asyncAfter(deadline: .now() + delay) { [weak self] in
                        guard let self = self else { return }
                        self.lock.lock()
                        self.pendingWork?()
                        self.pendingWork = nil
                        self.lastExecution = Date()
                        self.lock.unlock()
                    }
                } else {
                    self.lock.unlock()
                }
            } else {
                self.lastExecution = now
                self.lock.unlock()
                work()
            }
        }
    }

    func cancel() {
        lock.lock()
        pendingWork = nil
        lock.unlock()
    }
}
