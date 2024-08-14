import Foundation

struct MultiplePagesOnboardingFeatureModel: Identifiable, Hashable {
    var id: UUID = UUID()
    let imageName: String
    let title: String
    let description: String
}

extension MultiplePagesOnboardingFeatureModel {
    static let dummy = MultiplePagesOnboardingFeatureModel(imageName: "onboarding1", title: "Title", description: "Description")
}
