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

#if canImport(OSLog)
import OSLog
#endif

/// Simple heuristic to decide on degree of parallelism.
struct ConcurrencyHeuristic {
    /// Parallelism is between 4 and the number of __active__ cores for a given power state.
    var optimalConcurrency: Int {
        let optimalConcurrency = Swift.max(4, ProcessInfo.processInfo.activeProcessorCount)

        #if canImport(OSLog)
        if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
            /// Logs the concurrency, each time this heuristic is used
            Logger.concurrency.info("Using a parallelism of \(optimalConcurrency)")
        }
        #endif

        return optimalConcurrency
    }
}

/// Get a concurrency value to use
/// - Parameter customConcurrency: Input concurrency to be sanitised
/// - Returns: A parallelism value that reflects customConcurrency sanitised, or an optimised value if `customConcurrency` in nil.
func bestConcurrency(given customConcurrency: Int?) -> Int {
    let optimalConcurrency: Int
    if let customConcurrency {
        assert(customConcurrency > 0, "zero concurrency locks execution. Defaults to serial in production")
        optimalConcurrency = (customConcurrency > 0) ? customConcurrency : 1
    } else {
        optimalConcurrency = ConcurrencyHeuristic().optimalConcurrency
    }

    return optimalConcurrency
}
