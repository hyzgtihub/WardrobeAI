import Foundation
import Observation

@MainActor
@Observable
final class AddGarmentStore {
    private(set) var state: AddGarmentState
    private(set) var issue: AddGarmentIssue?
    var draft: AddGarmentDraft

    private let garmentRepository: any GarmentRepository
    private let imageRepository: any GarmentImageRepository
    private let imageProcessor: GarmentImageProcessor
    private let makeID: () -> UUID

    init(
        garmentRepository: any GarmentRepository,
        imageRepository: any GarmentImageRepository,
        imageProcessor: GarmentImageProcessor = GarmentImageProcessor(),
        draft: AddGarmentDraft = AddGarmentDraft(),
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.garmentRepository = garmentRepository
        self.imageRepository = imageRepository
        self.imageProcessor = imageProcessor
        self.draft = draft
        self.makeID = makeID
        state = draft.photo == nil ? .idle : .editing
    }

    func processPhoto(_ data: Data) {
        guard !isSubmitting else { return }
        state = .processingPhoto
        issue = nil
        do {
            draft.photo = try imageProcessor.process(data)
            state = .editing
        } catch {
            state = .photoProcessingFailed
        }
    }

    func submit(account: UserAccount) async -> Garment? {
        guard !isSubmitting else { return nil }
        state = .validating
        issue = nil

        guard let validated = validate(account: account) else {
            state = .editing
            return nil
        }

        let garmentID = makeID()
        let path = GarmentImage.objectPath(userID: account.user.id, garmentID: garmentID)
        state = .uploadingPhoto

        do {
            try await imageRepository.uploadJPEG(validated.photo.data, path: path)
        } catch {
            state = .uploadFailed
            return nil
        }

        state = .creatingGarment
        let input = NewGarment(
            id: garmentID,
            userID: account.user.id,
            wardrobeID: account.defaultWardrobe.id,
            imagePath: path,
            name: validated.name,
            category: validated.category,
            seasons: draft.seasons,
            colors: draft.colors,
            brand: trimmedOptional(draft.brand),
            price: validated.price,
            size: trimmedOptional(draft.size),
            purchaseDate: draft.purchaseDate,
            materials: trimmedOptional(draft.material).map { [$0] } ?? [],
            styles: trimmedOptional(draft.style).map { [$0] } ?? [],
            storageLocation: trimmedOptional(draft.storageLocation),
            notes: trimmedOptional(draft.notes)
        )

        do {
            let garment = try await garmentRepository.createGarment(input)
            state = .succeeded
            return garment
        } catch {
            try? await imageRepository.deleteImage(path: path)
            state = .createFailed
            return nil
        }
    }

    private var isSubmitting: Bool {
        switch state {
        case .validating, .uploadingPhoto, .creatingGarment:
            true
        default:
            false
        }
    }

    private func validate(account: UserAccount) -> ValidatedDraft? {
        guard let photo = draft.photo else {
            issue = .photoRequired
            return nil
        }

        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            issue = .nameRequired
            return nil
        }
        guard let category = draft.category else {
            issue = .categoryRequired
            return nil
        }
        guard !draft.seasons.isEmpty else {
            issue = .seasonRequired
            return nil
        }
        guard let price = Self.parsePrice(draft.price) else {
            issue = .invalidPrice
            return nil
        }

        return ValidatedDraft(photo: photo, name: name, category: category, price: price)
    }

    private static func parsePrice(_ input: String) -> Decimal?? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .some(nil) }
        guard value.range(of: #"^(?:\d{1,3}(?:,\d{3})*|\d+)(?:\.\d{1,2})?$"#, options: .regularExpression) != nil else {
            return nil
        }

        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        guard let number = formatter.number(from: value), number.decimalValue >= .zero else { return nil }
        return .some(number.decimalValue)
    }

    private func trimmedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct ValidatedDraft {
    let photo: GarmentImage
    let name: String
    let category: YISUCategory
    let price: Decimal?
}
