# InfomaniakConcurrency

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FInfomaniak%2Fswift-concurrency%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Infomaniak/swift-concurrency) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FInfomaniak%2Fswift-concurrency%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Infomaniak/swift-concurrency)

## Abstract

With Swift's structured concurrency, we can elegantly and seamlessly express correct asynchronous code.

Yet it is still non trivial to _parallelise_ code execution in a way that is easy enough to be used by anyone, and that can scale relatively well between workloads and platforms. From a watch to a Linux server with 128 cores.

This library does __not__ aim at bringing an asynchronous version of `map`, `forEach` and so forth. This aims at parallelising code execution in an asynchronous version of `map`, `forEach` ….
 
It is Minimalist by essence, it only provides top level functions like `map` and `forEach`. 

This package supports any first party Swift platform, from swift 5.6 and up. This is actually useful on Linux.

Well tested. Used in production across Infomaniak's apps written in Swift.

## Features

- `concurrentForEach`
    - __Concurrently__ loops over a `Collection` to perform a task on each element.
    - Enumeration will stop if any error is thrown.
    - Work will be executed out of order.
    
- `concurrentMap` 
    - __Concurrently__ Maps a task with nullable result.
    - Stops and throws at first error encountered.
    - Work will be executed out of order.
    - Input order __preserved__ in the output result.

- `concurrentCompactMap`
    - __Concurrently__ Maps a task to a collection of items, returning only non nil values.
    - Stops and throws at first error encountered.
    - Work will be executed out of order.
    - Input order __preserved__ in the output result.

## Behaviour

An heuristic determines a degree of __parallelism__ for you, but can be customised. We recommend sticking to a fixed parallelism (1-4ish) when working with network calls.

This runs right now in production code but will be refactored to be more in line with Swift 5.9 paradigms.

This do not use `Task.yield()`. Implement yielding at your own discretion depending on your own workload. 

## Roadmap

This library is looking forward. 
Right now the internals are not exposed, as they will be replaced at some point.

I'd like to support [Custom Actor Executors](https://github.com/apple/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md) to replace current internals.

I'll try to provide some backward compatibility and continue to work with Swift older than `5.9`. A situation where `Custom Actor Executors` are not available.
