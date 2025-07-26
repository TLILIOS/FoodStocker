//
//  Debouncer.swift
//  FoodStocker
//
//  Helper pour éviter les appels multiples rapprochés
//

import Foundation

/// Utility class to debounce function calls
/// Prevents multiple rapid executions by canceling previous calls
final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    private let queue: DispatchQueue
    
    /// Initialize a new Debouncer
    /// - Parameters:
    ///   - delay: Time to wait before executing the action
    ///   - queue: DispatchQueue to execute the action on (default: main)
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    /// Run an action with debouncing
    /// - Parameter action: The action to execute after the delay
    func run(action: @escaping () -> Void) {
        // Cancel any existing work item
        workItem?.cancel()
        
        // Create new work item
        workItem = DispatchWorkItem(block: action)
        
        // Schedule execution after delay
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    /// Run an async action with debouncing
    /// - Parameter action: The async action to execute after the delay
    func runAsync(action: @escaping () async -> Void) {
        // Cancel any existing work item
        workItem?.cancel()
        
        // Create new work item with async Task
        workItem = DispatchWorkItem {
            Task {
                await action()
            }
        }
        
        // Schedule execution after delay
        if let workItem = workItem {
            queue.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }
    
    /// Cancel any pending action
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
    
    deinit {
        cancel()
    }
}