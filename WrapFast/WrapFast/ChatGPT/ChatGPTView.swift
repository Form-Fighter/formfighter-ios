import SwiftUI
import Combine

struct ChatGPTView: View {
    @StateObject var vm: ChatGPTVM
    
    var body: some View {
        
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack {
                        ForEach(vm.messages, id: \.self) { message in
                            MessageView(currentMessage: message)
                                .id(message)
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
                    TextField("Message ChatGPT...", text: $vm.newMessage)
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
    ChatGPTView(vm: ChatGPTVM())
}
