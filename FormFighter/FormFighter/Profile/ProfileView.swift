//
//  ProfileView.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject var vm: ProfileVM
    
    var body: some View {
        Text("Profile View")
    }
}

#Preview {
    ProfileView(vm: ProfileVM())
}
