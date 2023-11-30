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
    /// __Concurrently__ loops over a `Collection` to perform a task on each element.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// Work will be executed out of order.
    ///
    /// - Parameters:
    ///   - task: The operation to be applied to the `Element` of the collection
    func concurrentForEach(
        task: @escaping @Sendable (_ element: Element) async throws -> Void
    ) async rethrows {
        try await concurrentForEach(customConcurrency: nil, task: task)
    }

    /// __Concurrently__ loops over a `Collection` to perform a task on each element.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// Work will be executed out of order.
    ///
    /// - Parameters:
    ///   - customConcurrency: Set a custom parallelism, 1 is serial.
    ///   - task: The operation to be applied to the `Element` of the collection
    func concurrentForEach(
        customConcurrency: Int?,
        task: @escaping @Sendable (_ element: Element) async throws -> Void
    ) async rethrows {
        // Level of concurrency making use of all the cores available
        let optimalConcurrency = customConcurrency ?? ConcurrencyHeuristic().optimalConcurrency

        // Using a TaskQueue to maintain level of concurrency.
        let taskQueue = TaskQueue(concurrency: optimalConcurrency)

        // Using a TaskGroup to track completion only.
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for element in self {
                taskGroup.addTask {
                    try await taskQueue.enqueue {
                        try await task(element)
                    }
                }
            }

            // await completion of all tasks.
            try await taskGroup.waitForAll()
        }
    }
}
