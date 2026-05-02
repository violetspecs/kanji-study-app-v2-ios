import CoreData

@objc(KanjiEntity)
public class KanjiEntity: NSManagedObject {
    @NSManaged public var character: String?
    @NSManaged public var meanings: NSArray?
    @NSManaged public var onyomi: NSArray?
    @NSManaged public var kunyomi: NSArray?
    @NSManaged public var jlptLevel: Int16
    @NSManaged public var gradeLevel: Int16
    @NSManaged public var strokeCount: Int16
    @NSManaged public var srsInterval: Int32
    @NSManaged public var srsEaseFactor: Double
    @NSManaged public var nextReviewDate: Date?
    @NSManaged public var lastReviewedAt: Date?
}

extension KanjiEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<KanjiEntity> {
        NSFetchRequest<KanjiEntity>(entityName: "KanjiEntity")
    }
}

@objc(StudySessionEntity)
public class StudySessionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var kanjiReviewed: NSArray?
    @NSManaged public var correctCount: Int32
    @NSManaged public var totalCount: Int32
}

extension StudySessionEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudySessionEntity> {
        NSFetchRequest<StudySessionEntity>(entityName: "StudySessionEntity")
    }
}
