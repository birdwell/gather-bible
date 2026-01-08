//
//  Gather_BibleApp.swift
//  Gather Bible
//
//  Created by Josh Birdwell on 12/20/25.
//

import SwiftUI
import Sentry

import YouVersionPlatform
import FirebaseCore
import FirebaseDatabase

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        SentrySDK.start { options in
            options.dsn = "https://22c49af32701c5e5c0f50867a887bde9@o201915.ingest.us.sentry.io/4510660910055424"

            // Adds IP for users.
            // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
            options.sendDefaultPii = true

            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0

            // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
            options.configureProfiling = {
                $0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
                $0.lifecycle = .trace
            }

            // Uncomment the following lines to add more data to your events
            // options.attachScreenshot = true // This adds a screenshot to the error events
            // options.attachViewHierarchy = true // This adds the view hierarchy to the error events
            
            // Enable experimental logging features
            options.experimental.enableLogs = true
        }

    FirebaseApp.configure()
    
    // Configure Firebase persistence for offline support
    Database.database().isPersistenceEnabled = true
    
    return true
  }
}

@main
struct Gather_BibleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        YouVersionConfig.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
