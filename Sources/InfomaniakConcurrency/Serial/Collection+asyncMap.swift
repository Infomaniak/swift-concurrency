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
    /// __Serially__ Maps an async task with nullable result.
    ///
    /// Stops and throws at first error encountered.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type.
    func asyncMap<Input: Sendable, Output: Sendable>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output
    ) async rethrows -> [Output] where Element == Input {
        try await concurrentMap(customConcurrency: 1, transform: transform)
    }
}
