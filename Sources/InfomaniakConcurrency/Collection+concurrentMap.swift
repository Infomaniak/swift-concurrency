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

/// Top level `Collection` extension is arguably more swifty, has a more native look and feel.
public extension Collection {
    /// Maps a task to a collection of items concurrently. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
    ///
    /// This is using an underlying `TaskQueue`, with an optimized queue depth.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type.
    func concurrentMap<Input, Output>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output
    ) async rethrows -> [Output] where Element == Input {
        try await concurrentMap(customConcurrency: nil, transform: transform)
    }

    /// Maps a task to a collection of items concurrently. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
    ///
    /// This is using an underlying `TaskQueue`, with an optimized queue depth.
    ///
    /// - Parameters:
    ///   - customConcurrency: set a custom depth to override behaviour, useful for network calls.
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type.
    func concurrentMap<Input, Output>(
        customConcurrency: Int?,
        transform: @escaping @Sendable (_ item: Input) async throws -> Output
    ) async rethrows -> [Output] where Element == Input {
        // Our `concurrentMap` is a subset of what does `concurrentCompactMap`
        // Wrapping a closure that cannot return nil, in a closure that can, does the job.
        let results = try await concurrentCompactMap(customConcurrency: customConcurrency) { item in
            try await transform(item)
        }

        // Sanity check, should never append
        guard results.count == count else {
            fatalError("Internal consistency error. Got:\(results.count) Expecting:\(count)")
        }

        return results
    }

    /// Maps a task with nullable result __concurrently__, returning only non nil values. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
    ///
    /// This is using an underlying `TaskQueue`, with an optimized queue depth.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input, Output>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        try await concurrentCompactMap(customConcurrency: nil, transform: transform)
    }

    /// Maps a task with nullable result __concurrently__, returning only non nil values. Input order __preserved__.
    ///
    /// Set a `customConcurrency` value to override the optimised behaviour. You might want to set a fixed depth for network
    /// calls.
    ///
    /// - Parameters:
    ///   - customConcurrency: set a custom depth to override behaviour, useful for network calls.
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input, Output>(
        customConcurrency: Int?,
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        // Concurrency making use of all the cores available
        let optimalConcurrency = customConcurrency ?? Swift.max(4, ProcessInfo.processInfo.activeProcessorCount)

        // Dispatch work on a TaskQueue for concurrency.
        let taskQueue = TaskQueue(concurrency: optimalConcurrency)

        // Using an ArrayAccumulator to preserve original collection order.
        let accumulator = ArrayAccumulator(count: count, wrapping: Output.self)

        // Using a TaskGroup to track completion only.
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for (index, item) in self.enumerated() {
                taskGroup.addTask {
                    let result = try await taskQueue.enqueue {
                        try await transform(item)
                    }

                    try await accumulator.set(item: result, atIndex: index)
                }
            }

            // await completion of all tasks.
            try await taskGroup.waitForAll()
        }

        // Get the accumulated results.
        let accumulated = await accumulator.compactAccumulation
        return accumulated
    }
}
