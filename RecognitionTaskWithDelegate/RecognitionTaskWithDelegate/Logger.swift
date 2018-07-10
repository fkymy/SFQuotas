//
//  Logger.swift
//  RecognitionTaskWithDelegate
//
//  Created by Yuske Fukuyama on 2018/07/10.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import Foundation
import os.log

public struct Logger {
  fileprivate init() {}
  
  private enum Level: CustomStringConvertible {
    case debug, info, error, fatal
    
    var description: String {
      switch self {
      case .debug: return "[debug]"
      case .info: return "[info]"
      case .error: return "[ERROR]"
      case .fatal: return "[FATAL]"
      }
    }
  }
  
  public func debug(message: String) {
    writeLog(message: message, level: .debug)
  }
  
  public func info(message: String) {
    writeLog(message: message, level: .info)
  }
  
  public func error(message: String) {
    writeLog(message: message, level: .error)
  }
  
  public func error(error: Error) {
    let message = String(error.localizedDescription)
    writeLog(message: message, level: .error)
  }
  
  public func fatal(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    writeLog(message: message, level: .fatal)
    assertionFailure(message)
  }
  
  private func writeLog(message: String, level: Level) {
    os_log("%@ %@", log: .default, type: .debug, level.description, message)
  }
  
}

public let logger = Logger()
