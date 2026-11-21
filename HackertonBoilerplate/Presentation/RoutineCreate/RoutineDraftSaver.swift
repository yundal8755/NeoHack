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

    func saveParticipationDraft(_ state: RoutineCreateReducer.State, routineID: String) async throws {
        var cards: [RoutineParticipationDraft.Card?] = []
        for step in state.steps {
            try Task.checkCancellation()
            let id = step.requiresImageUpload ? nil : try await uploadedID(for: step.image)
            cards.append(.init(imageID: id, title: step.title, content: step.content, time: step.time.formatted))
        }
        try Task.checkCancellation()
        _ = try await routines.saveParticipationDraft(
            routineID: routineID, draft: .init(title: state.routineTitle, content: state.routineIntroduction, cards: cards))
    }

    func restoreParticipationDraft(routineID: String, steps: [RoutineCreateReducer.Step]) async throws
        -> RoutineCreateReducer.State? {
        guard let draft = try await routines.participationDraft(routineID: routineID) else { return nil }
        let cards = draft.cards ?? []
        guard cards.count <= steps.count else { throw DataContractError.invalidValue("draft.cards") }
        var restored = steps
        for (index, value) in cards.enumerated() {
            guard let card = value else { continue }
            restored[index].title = card.title ?? ""
            restored[index].content = card.content ?? ""
            if let time = card.time {
                let parts = time.split(separator: ":").compactMap { Int($0) }
                guard parts.count == 2, (0...23).contains(parts[0]), (0...59).contains(parts[1]) else {
                    throw DataContractError.invalidValue("draft.time")
                }
                restored[index].time = TimeOfDay(hour: parts[0], minute: parts[1])
            }
            if let id = card.imageID {
                let data = try await images.data(id: id)
                guard !data.isEmpty else { throw DataContractError.invalidValue("draft.image") }
                let image = RoutineImage(data: data)
                restored[index].image = image
                restored[index].requiresImageUpload = false
                uploadedIDs[image.id] = id
            }
        }
        try Task.checkCancellation()
        return .init(steps: restored, routineTitle: draft.title ?? "", routineIntroduction: draft.content ?? "")
    }

    private func uploadedID(for image: RoutineImage) async throws -> String {
        if let id = uploadedIDs[image.id] { return id }
        guard !image.data.isEmpty else { throw DataContractError.invalidValue("image") }
        let result = try await images.upload(input: .init(data: image.data, fileName: "card.jpg", mimeType: "image/jpeg"))
        uploadedIDs[image.id] = result.id
        return result.id
    }

    private func input(_ draft: RoutineDraft) async throws -> RoutineSaveInput {
        var cards: [RoutineCardEntity] = []
        for step in draft.steps {
            try Task.checkCancellation()
            let id = try await uploadedID(for: step.image)
            cards.append(.init(imageID: id, title: step.title, content: step.content, time: step.time.formatted))
        }
        try Task.checkCancellation()
        return .init(title: draft.title, content: draft.introduction, cards: cards)
    }
}
