import Foundation

/// SM-2 spaced repetition algorithm
struct SRSEngine {
    struct Result {
        let interval: Int       // days until next review
        let easeFactor: Double
    }

    /// quality: 0 = wrong, 1 = correct
    static func update(interval: Int, easeFactor: Double, correct: Bool) -> Result {
        let quality: Double = correct ? 4 : 1
        let newEF = max(1.3, easeFactor + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))

        let newInterval: Int
        if !correct {
            newInterval = 1
        } else if interval == 0 {
            newInterval = 1
        } else if interval == 1 {
            newInterval = 6
        } else {
            newInterval = Int((Double(interval) * newEF).rounded())
        }

        return Result(interval: newInterval, easeFactor: newEF)
    }
}
