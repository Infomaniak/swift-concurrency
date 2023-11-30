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

/// Top level `Collection` extension for a more native look and feel.
public extension Collection {
    /// Maps a task with nullable result __concurrently__, returning only non nil values. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
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
    ///   - customConcurrency: Set a custom parallelism, 1 is serial.
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input, Output>(
        customConcurrency: Int?,
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        // Level of concurrency making use of all the cores available
        let optimalConcurrency = customConcurrency ?? ConcurrencyHeuristic().optimalConcurrency

        // Using a TaskQueue to maintain level of concurrency.
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
