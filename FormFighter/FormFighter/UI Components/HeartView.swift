import SwiftUI

struct HeartView: View {
    @State var heartBeat = 85
    @State var heartColor: Color
    @State var beatAnimation = false
    @State var showPulses = false
    @State var pulsedHearts = [HeartParticle]()
    var heartRate: Double = 1
    var heartRatePulse: Double = 0.7
    
    var body: some View {
        ZStack {
            if showPulses {
                TimelineView(.animation(minimumInterval: heartRatePulse, paused: false)) { timeline in
                    Canvas { context, size in
                        for heart in pulsedHearts {
                            if let resolvedView = context.resolveSymbol(id: heart.id) {
                                let centerX = size.width / 2
                                let centerY = size.height / 2
                                
                                context.draw(resolvedView, at: CGPoint(x: centerX, y: centerY))
                            }
                        }
                    } symbols: {
                        ForEach(pulsedHearts) {
                            PulseHeartView(heartColor: heartColor)
                                .id($0.id)
                        }
                    }
                    .onChange(of: timeline.date, perform: { value in
                        if beatAnimation {
                            addPulseHeart()
                        }
                    })
                }
            }
            
            if #available(iOS 17.0, *) {
                heartBouncing
            } else {
                heartNormal
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            beatAnimation = true
            showPulses = true
        }
    }
    
    private func addPulseHeart() {
        let pulsedHeart = HeartParticle()
        pulsedHearts.append(pulsedHeart)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            pulsedHearts.removeAll(where: {$0.id == pulsedHeart.id})
            
            if pulsedHearts.isEmpty {
                showPulses = false
            }
        }
    }
    
    @available(iOS 17.0, *)
    var heartBouncing: some View {
        Image(systemName: "suit.heart.fill")
            .font(.system(size: 100))
            .foregroundStyle(heartColor.gradient)
            .symbolEffect(.bounce, options: !beatAnimation ? .default : .repeating.speed(heartRate), value: beatAnimation)
    }
    
    var heartNormal: some View {
        Image(systemName: "suit.heart.fill")
            .font(.system(size: 100))
            .foregroundStyle(heartColor.gradient)
    }
}

struct PulseHeartView: View {
    @State private var startAnimation = false
    @State var heartColor: Color
    
    var body: some View {
        Image(systemName: "suit.heart.fill")
            .font(.system(size: 100))
            .foregroundStyle(heartColor)
            .background(content: {
                Image(systemName: "suit.heart.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.black.opacity(0.5))
                    .blur(radius: 5, opaque: false)
                    .animation(.linear(duration: 1.5), value: startAnimation)
                
            })
            .scaleEffect(startAnimation ? 4: 1)
            .opacity(startAnimation ? 0 : 0.7)
            .onAppear {
                DispatchQueue.main.async {
                    withAnimation(.linear(duration: 3)) {
                        startAnimation = true
                    }
                }
            }
    }
}

struct HeartParticle: Identifiable {
    var id = UUID()
}

#Preview {
    ZStack {
        HeartView(heartColor: .ruby)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.customBackground)
    
}
