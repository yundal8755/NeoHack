import Foundation
import HackertonCore

@MainActor
final class RoutineDraftSaver {
    private let images: any ImageRepository
    private let routines: any RoutineRepository
    private var uploadedIDs: [UUID: String] = [:]

    init(images: any ImageRepository, routines: any RoutineRepository) {
        self.images = images
        self.routines = routines
    }

    func save(_ draft: RoutineDraft) async throws -> RoutineDetailEntity {
        try await routines.create(input: input(draft))
    }

    func saveParticipation(_ draft: RoutineDraft, routineID: String, expectedSteps: Int) async throws -> RoutineInteractions {
        guard draft.steps.count == expectedSteps, !draft.steps.isEmpty,
              draft.steps.allSatisfy({ step in
                  if case let .local(image) = step.photo { return !image.data.isEmpty }
                  return false
              }) else {
            throw DataContractError.invalidValue("participation.cards")
        }
        let input = try await input(draft)
        return try await routines.completeParticipation(id: routineID, input: input)
    }

    enum EditTarget {
        case routine(id: String)
        case participation(routineID: String, participantID: String)
    }

    func update(_ draft: RoutineDraft, target: EditTarget) async throws {
        let input = try await input(draft)
        switch target {
        case let .routine(id):
            _ = try await routines.update(id: id, input: input)
        case let .participation(routineID, participantID):
            _ = try await routines.updateParticipationResult(routineID: routineID, participantID: participantID, input: input)
        }
    }

    private func input(_ draft: RoutineDraft) async throws -> RoutineSaveInput {
        var cards: [RoutineCardEntity] = []
        for step in draft.steps {
            try Task.checkCancellation()
            let id: String
            switch step.photo {
            case let .stored(imageID, _):
                id = imageID
            case let .local(photo):
                if let uploadedID = uploadedIDs[photo.id] {
                    id = uploadedID
                } else {
                    let image = try await images.uploadStep(
                        input: .init(data: photo.data, fileName: "card.jpg", mimeType: "image/jpeg"))
                    id = image.id
                    uploadedIDs[photo.id] = id
                }
            case .reference:
                throw DataContractError.invalidValue("card.imageId")
            }
            cards.append(.init(imageID: id, title: step.title, content: step.content, time: step.time.formatted))
        }
        try Task.checkCancellation()
        return .init(title: draft.title, content: draft.introduction, cards: cards)
    }
}
