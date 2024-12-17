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

public extension Collection {
    /// __Serially__ reduce a collection with an async closure
    ///
    /// Requires `Result` to be sendable
    ///
    /// - Parameters:
    ///   - initialResult: first value to begin the reduce operation
    ///   - nextPartialResult: partial reduce closure
    /// - Returns: A generic Result post reduce operation
    func asyncReduce<Result: Sendable>(
        _ initialResult: Result,
        _ nextPartialResult: (_ partialResult: Result, Self.Element) async throws -> Result
    ) async rethrows -> Result {
        var result: Result = initialResult
        for element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }

    /// __Serially__ reduce a collection with an async accumulating closure
    ///
    /// Requires `Result` to be sendable
    ///
    /// - Parameters:
    ///   - initialResult: first value to begin the reduce operation
    ///   - updateAccumulatingResult: accumulating closure
    /// - Returns: A generic Result post reduce operation
    func asyncReduce<Result: Sendable>(
        into initialResult: Result,
        _ updateAccumulatingResult: (_ partialResult: inout Result, Self.Element) async throws -> Void
    ) async rethrows -> Result {
        var result: Result = initialResult
        for element in self {
            try await updateAccumulatingResult(&result, element)
        }
        return result
    }
}
