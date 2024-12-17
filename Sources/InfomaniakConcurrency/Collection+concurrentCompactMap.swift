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

public extension Collection where Element: Sendable {
    /// __Concurrently__ Maps an async task with nullable result, returning only non nil values.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// Work will be executed out of order.
    ///
    /// Input order __preserved__ in the output result.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input: Sendable, Output: Sendable>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        try await concurrentCompactMap(customConcurrency: nil, transform: transform)
    }

    /// __Concurrently__ Maps an async task with nullable result, returning only non nil values.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// Work will be executed out of order.
    ///
    /// Input order __preserved__ in the output result.
    ///
    /// - Parameters:
    ///   - customConcurrency: Set a custom parallelism, 1 is serial.
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input: Sendable, Output: Sendable>(
        customConcurrency: Int?,
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        let optimalConcurrency = bestConcurrency(given: customConcurrency)

        // Using an ArrayAccumulator to preserve original collection order.
        let accumulator = ArrayAccumulator(count: count, wrapping: Output.self)

        var enumeratedIterator = enumerated().makeIterator()

        // Keep only a defined number of Tasks running in parallel with a TaskGroup
        try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in

            // Start to enqueue the proper number of Tasks
            for _ in 0 ..< optimalConcurrency {
                guard let nextEnumeration = enumeratedIterator.next() else {
                    continue
                }

                taskGroup.addTask {
                    let result = try await transform(nextEnumeration.1)
                    try await accumulator.set(item: result, atIndex: nextEnumeration.0)
                }
            }

            // Enqueue a Task as soon as one finishes
            while let _ = try await taskGroup.next(),
                  let nextEnumeration = enumeratedIterator.next() {
                taskGroup.addTask {
                    let result = try await transform(nextEnumeration.1)
                    try await accumulator.set(item: result, atIndex: nextEnumeration.0)
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
