//
//  Logger.swift
//  FoodStocker
//
//  Système de logging centralisé
//

import Foundation
import os.log

// MARK: - Log Categories
enum LogCategory: String {
    case viewModel = "ViewModel"
    case repository = "Repository"
    case service = "Service"
    case ui = "UI"
    case coreData = "CoreData"
    case notification = "Notification"
    case network = "Network"
}

// MARK: - FoodStockerLogger
struct FoodStockerLogger {
    private static let subsystem = "com.foodstocker"
    
    static func log(_ category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }
    
    // MARK: - Convenience Methods
    static func logError(_ error: Error, category: LogCategory, context: String? = nil) {
        let logger = log(category)
        let contextInfo = context ?? ""
        logger.error("🔴 \(contextInfo) Error: \(error.localizedDescription, privacy: .public)")
    }
    
    static func logInfo(_ message: String, category: LogCategory) {
        let logger = log(category)
        logger.info("ℹ️ \(message, privacy: .public)")
    }
    
    static func logDebug(_ message: String, category: LogCategory) {
        let logger = log(category)
        logger.debug("🔍 \(message, privacy: .public)")
    }
    
    static func logWarning(_ message: String, category: LogCategory) {
        let logger = log(category)
        logger.warning("⚠️ \(message, privacy: .public)")
    }
    
    static func logSuccess(_ message: String, category: LogCategory) {
        let logger = log(category)
        logger.info("✅ \(message, privacy: .public)")
    }
}