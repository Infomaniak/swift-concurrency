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
            /// Logs the concurrency, each time this lib is performing concurrent work
            Logger.concurrency.info("Using a parallelism of \(optimalConcurrency)")
        }
        #endif

        return optimalConcurrency
    }
}
