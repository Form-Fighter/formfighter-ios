//
//  ProfileVM.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import os.log
import Combine

class ProfileVM: ObservableObject {
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var feedbacks: [FeedbackListItem] = []
    private let feedbackManager: FeedbackManager
    private var cancellables = Set<AnyCancellable>()
    
    init(feedbackManager: FeedbackManager = .shared) {
        self.feedbackManager = feedbackManager
        
        // Observe changes to FeedbackManager's properties
        feedbackManager.$isLoading
            .assign(to: \.isLoading, on: self)
            .store(in: &cancellables)
            
        feedbackManager.$feedbacks
            .assign(to: \.feedbacks, on: self)
            .store(in: &cancellables)
    }
}
