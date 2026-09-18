import Foundation

struct WardrobeFilter: Equatable, Sendable {
    var categories: Set<YISUCategory> = []
    var seasons: Set<String> = []
    var colors: Set<String> = []
    var materials: Set<String> = []
    var styles: Set<String> = []
    var sizes: Set<String> = []
    var storageLocations: Set<String> = []

    var hasNonCategoryConditions: Bool {
        !seasons.isEmpty || !colors.isEmpty || !materials.isEmpty ||
        !styles.isEmpty || !sizes.isEmpty || !storageLocations.isEmpty
    }

    var activeNonCategoryCount: Int {
        [seasons, colors, materials, styles, sizes, storageLocations]
            .reduce(0) { $0 + $1.count }
    }

    var isEmpty: Bool { categories.isEmpty && !hasNonCategoryConditions }
}

enum WardrobeFilterDimension: String, CaseIterable, Identifiable, Sendable {
    case category, season, color, material, style, size, storageLocation

    var id: Self { self }
}

struct WardrobeFilterOption: Identifiable, Equatable, Sendable {
    let value: String
    let count: Int

    var id: String { value }
}

enum WardrobeFilterPolicy {
    static func filteredGarments(_ garments: [Garment], by filter: WardrobeFilter) -> [Garment] {
        garments.filter { garment in
            (filter.categories.isEmpty || filter.categories.contains(garment.category)) &&
            matches(garment.seasons, selected: filter.seasons) &&
            matches(garment.colors, selected: filter.colors) &&
            matches(garment.materials, selected: filter.materials) &&
            matches(garment.styles, selected: filter.styles) &&
            matches(garment.size, selected: filter.sizes) &&
            matches(garment.storageLocation, selected: filter.storageLocations)
        }
    }

    static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func options(for dimension: WardrobeFilterDimension, in garments: [Garment]) -> [WardrobeFilterOption] {
        switch dimension {
        case .category:
            let counts = categoryCounts(in: garments)
            return YISUCategory.browseableCases.map {
                WardrobeFilterOption(value: $0.title, count: counts[$0, default: 0])
            }
        case .season:
            return GarmentFieldOptions.seasons.map { season in
                WardrobeFilterOption(
                    value: season,
                    count: garments.count { normalizedValues($0.seasons).contains(normalized(season)) }
                )
            }
        case .color:
            return dynamicOptions(garments.map(\.colors))
        case .material:
            return dynamicOptions(garments.map(\.materials))
        case .style:
            return dynamicOptions(garments.map(\.styles))
        case .size:
            return dynamicOptions(garments.map { $0.size.map { [$0] } ?? [] })
        case .storageLocation:
            return dynamicOptions(garments.map { $0.storageLocation.map { [$0] } ?? [] })
        }
    }

    static func categoryCounts(in garments: [Garment]) -> [YISUCategory: Int] {
        var counts = Dictionary(uniqueKeysWithValues: YISUCategory.browseableCases.map { ($0, 0) })
        for garment in garments where counts[garment.category] != nil {
            counts[garment.category, default: 0] += 1
        }
        return counts
    }

    private static func matches(_ values: [String], selected: Set<String>) -> Bool {
        selected.isEmpty || !normalizedValues(values).isDisjoint(with: normalizedValues(selected))
    }

    private static func matches(_ value: String?, selected: Set<String>) -> Bool {
        guard !selected.isEmpty else { return true }
        guard let value else { return false }
        return normalizedValues(selected).contains(normalized(value))
    }

    private static func normalizedValues<S: Sequence>(_ values: S) -> Set<String> where S.Element == String {
        Set(values.map(normalized))
    }

    private static func dynamicOptions(_ valuesByGarment: [[String]]) -> [WardrobeFilterOption] {
        var counts: [String: Int] = [:]
        var displays: [String: String] = [:]

        for values in valuesByGarment {
            var seen = Set<String>()
            for value in values {
                let display = value.trimmingCharacters(in: .whitespacesAndNewlines)
                let key = normalized(display)
                guard !key.isEmpty, seen.insert(key).inserted else { continue }
                displays[key] = displays[key] ?? display
                counts[key, default: 0] += 1
            }
        }

        return counts.compactMap { key, count in
            displays[key].map { WardrobeFilterOption(value: $0, count: count) }
        }
        .sorted { $0.value.localizedStandardCompare($1.value) == .orderedAscending }
    }
}
