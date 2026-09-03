import Foundation

struct GarmentSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let metadata: String
    let imagePath: String?
    let category: YISUCategory
}
