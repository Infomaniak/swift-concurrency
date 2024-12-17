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
public extension Collection where Element: Sendable {
    /// __Concurrently__ loops over a `Collection` to perform an async task on each element.
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

    /// __Concurrently__ loops over a `Collection` to perform an async task on each element.
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
        let optimalConcurrency = bestConcurrency(given: customConcurrency)
        var iterator = makeIterator()

        // Keep only a defined number of Tasks running in parallel with a TaskGroup
        try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in

            // Start to enqueue the proper number of Tasks
            for _ in 0 ..< optimalConcurrency {
                guard let nextElement = iterator.next() else {
                    continue
                }

                taskGroup.addTask {
                    try await task(nextElement)
                }
            }

            // Enqueue a Task as soon as one finishes
            while let _ = try await taskGroup.next(),
                  let nextElement = iterator.next() {
                taskGroup.addTask {
                    try await task(nextElement)
                }
            }

            // await completion of all tasks.
            try await taskGroup.waitForAll()
        }
    }
}
