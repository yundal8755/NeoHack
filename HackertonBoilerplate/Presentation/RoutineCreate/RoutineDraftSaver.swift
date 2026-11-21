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
              draft.steps.allSatisfy({ !$0.image.data.isEmpty }) else {
            throw DataContractError.invalidValue("participation.cards")
        }
        let input = try await input(draft)
        return try await routines.completeParticipation(id: routineID, input: input)
    }

    private func input(_ draft: RoutineDraft) async throws -> RoutineSaveInput {
        var cards: [RoutineCardEntity] = []
        for step in draft.steps {
            try Task.checkCancellation()
            let id: String
            if let uploadedID = uploadedIDs[step.image.id] {
                id = uploadedID
            } else {
                let image = try await images.upload(
                    input: .init(
                        data: step.image.data, fileName: "card.jpg", mimeType: "image/jpeg"))
                id = image.id
                uploadedIDs[step.image.id] = id
            }
            cards.append(.init(imageID: id, title: step.title, content: step.content, time: step.time.formatted))
        }
        try Task.checkCancellation()
        return .init(title: draft.title, content: draft.introduction, cards: cards)
    }
}
