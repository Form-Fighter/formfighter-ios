import SwiftUI
import Combine

struct DALLEView: View {
    @StateObject var vm: DALLEVM
    
    var body: some View {
        
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(vm.messages, id: \.self) { message in
                            if let imageUrl = message.imageUrl {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .cornerRadius(16)
                                        .padding()
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                MessageView(currentMessage: message)
                                    .id(message)
                            }
                        }
                    }
                    .onReceive(Just(vm.messages)) { _ in
                        withAnimation {
                            proxy.scrollTo(vm.messages.last, anchor: .bottom)
                        }
                        
                    }.onAppear {
                        withAnimation {
                            proxy.scrollTo(vm.messages.last, anchor: .bottom)
                        }
                    }
                }
                
                HStack {
                    TextField("Request image to DALL·E...", text: $vm.newMessage)
                        .textFieldStyle(.roundedBorder)
                    Button{
                        vm.sendMessage()
                    } label: {
                        if vm.isRequesting {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane")
                        }
                    }
                    .frame(width: 40)
                    .disabled(vm.isRequesting)
                }
                .padding()
            }
        }
        .background(.customBackground)
    }
}

#Preview {
    DALLEView(vm: DALLEVM())
}
