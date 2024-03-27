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
    /// __Serially__ loops over a `Collection` to perform an async task on each element.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// - Parameters:
    ///   - task: The operation to be applied to the `Element` of the collection
    func asyncForEach(
        task: @escaping @Sendable (_ element: Element) async throws -> Void
    ) async rethrows {
        try await concurrentForEach(customConcurrency: 1, task: task)
    }
}
