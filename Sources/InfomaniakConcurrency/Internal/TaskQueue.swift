//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

import Foundation

/// A queue of `AsyncAwait` tasks. Serial by default.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
actor TaskQueue {
    private let concurrency: Int
    private var running = 0
    private var queue = [CheckedContinuation<Void, Error>]()

    /// Init function
    /// - Parameter concurrency: execution depth
    public init(concurrency: Int = 1 /* serial by default */ ) {
        assert(concurrency > 0, "zero concurrency locks execution")
        self.concurrency = concurrency
    }

    deinit {
        for continuation in queue {
            continuation.resume(throwing: CancellationError())
        }
    }

    /// Enqueue some work.
    /// - Parameters:
    ///   - asap: if `true`, the task will be added on top of the execution stack
    ///   - operation: an async await task to be scheduled in the queue
    public func enqueue<T>(asap: Bool = false, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try Task.checkCancellation()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            if asap {
                queue.insert(continuation, at: 0)
            } else {
                queue.append(continuation)
            }
            tryRunEnqueued()
        }

        defer {
            running -= 1
            tryRunEnqueued()
        }
        try Task.checkCancellation()
        return try await operation()
    }

    private func tryRunEnqueued() {
        guard !queue.isEmpty else { return }
        guard running < concurrency else { return }

        running += 1
        let continuation = queue.removeFirst()
        continuation.resume()
    }
}
