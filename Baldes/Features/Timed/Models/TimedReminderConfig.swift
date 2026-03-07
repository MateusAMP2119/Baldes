import Foundation

/// Configuration for the four independent timed-habit reminder types.
struct TimedReminderConfig: Codable, Equatable {
    // Pre-Trigger: "Your session starts in X minutes"
    var preTriggerEnabled: Bool = false
    var preTriggerLeadMinutes: Int = 10

    // Nag: "You missed your session. Start now?" — repeats
    var nagEnabled: Bool = false
    var nagIntervalMinutes: Int = 5
    var nagMaxAttempts: Int = 3

    // Progress Alerts: mid-session chimes
    var progressAlertsEnabled: Bool = false
    var progressHalfway: Bool = true
    var progressOneMinuteLeft: Bool = true

    // Post-Completion: "Session finished! Log your notes now."
    var postCompletionEnabled: Bool = false
}
