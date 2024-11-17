import AVFoundation

class VideoPlayerObserver: NSObject {
    let originalPlayer: AVPlayer?
    let overlayPlayer: AVPlayer?
    
    init(originalPlayer: AVPlayer?, overlayPlayer: AVPlayer?) {
        self.originalPlayer = originalPlayer
        self.overlayPlayer = overlayPlayer
        super.init()
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                             of object: Any?, 
                             change: [NSKeyValueChangeKey : Any]?, 
                             context: UnsafeMutableRawPointer?) {
        guard keyPath == #keyPath(AVPlayerItem.status),
              let item = object as? AVPlayerItem else { return }
        
        if item.status == .readyToPlay {
            DispatchQueue.main.async { [weak self] in
                self?.originalPlayer?.play()
                self?.overlayPlayer?.play()
            }
        }
    }
} 