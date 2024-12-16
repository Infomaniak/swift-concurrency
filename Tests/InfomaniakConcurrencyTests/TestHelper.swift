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
import XCTest

public extension XCTestCase {
    /// Something to make async tests work on linux
    func asyncTestWrapper(_ closure: @escaping @Sendable () async throws -> Void, function: String = #function) {
        let expectation = XCTestExpectation(description: "The async test should terminate")
        Task {
            do {
                try await closure()
            } catch {
                XCTFail("error thrown by test: \(function) error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    /// Something to randomise the parallelism used in tests
    var randomConcurrencyDepth: Int {
        Int.random(in: 1 ..< 1024)
    }
}
