import SwiftUI

struct WardrobeFilterBar: View {
    let filter: WardrobeFilter
    let onOpen: () -> Void
    let onRemove: (WardrobeFilterDimension, String) -> Void

    var body: some View {
        HStack(spacing: YISUTheme.Spacing.sm) {
            Button(action: onOpen) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(YISUTheme.Color.textPrimary)
                    .frame(width: YISUTheme.Size.minimumTouchTarget, height: YISUTheme.Size.minimumTouchTarget)
                    .background(YISUTheme.Color.surface, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(YISUTheme.Color.border, lineWidth: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        if filter.hasNonCategoryConditions {
                            Circle()
                                .fill(YISUTheme.Color.brandEmphasis)
                                .frame(width: 10, height: 10)
                                .overlay {
                                    Circle().stroke(YISUTheme.Color.surface, lineWidth: 2)
                                }
                                .offset(x: -2, y: 2)
                                .accessibilityHidden(true)
                                .accessibilityIdentifier("wardrobe.filter.active")
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("筛选")
            .accessibilityValue(filter.hasNonCategoryConditions ? "已有条件" : "无附加条件")
            .accessibilityIdentifier("wardrobe.filter.open")

            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: YISUTheme.Spacing.sm) {
                        ForEach(chips, id: \.identifier) { chip in
                            Button {
                                onRemove(chip.dimension, chip.value)
                            } label: {
                                HStack(spacing: YISUTheme.Spacing.xs) {
                                    Text(chip.value)
                                        .lineLimit(1)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .accessibilityHidden(true)
                                }
                                .font(YISUTheme.Typography.callout.weight(.medium))
                                .foregroundStyle(YISUTheme.Color.textPrimary)
                                .padding(.horizontal, YISUTheme.Spacing.md)
                                .frame(minHeight: YISUTheme.Size.minimumTouchTarget)
                                .background(YISUTheme.Color.lavender, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("移除筛选，\(chip.value)")
                            .accessibilityIdentifier(chip.identifier)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private var chips: [Chip] {
        nonCategorySelections.flatMap { dimension, values in
            values.sorted { $0.localizedStandardCompare($1) == .orderedAscending }.map {
                Chip(dimension: dimension, value: $0)
            }
        }
    }

    private var nonCategorySelections: [(WardrobeFilterDimension, Set<String>)] {
        [
            (.season, filter.seasons),
            (.color, filter.colors),
            (.material, filter.materials),
            (.style, filter.styles),
            (.size, filter.sizes),
            (.storageLocation, filter.storageLocations)
        ]
    }

    private struct Chip {
        let dimension: WardrobeFilterDimension
        let value: String

        var identifier: String {
            "wardrobe.filterChip.\(WardrobeFilterPolicy.normalized(value))"
        }
    }
}

#Preview("Applied filters") {
    WardrobeFilterBar(
        filter: WardrobeFilter(seasons: ["秋季"], colors: ["黑色"]),
        onOpen: {},
        onRemove: { _, _ in }
    )
    .padding()
    .background(YISUTheme.Color.background)
}
