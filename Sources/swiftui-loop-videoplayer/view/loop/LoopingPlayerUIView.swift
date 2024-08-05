//
//  LoopingPlayerProtocol.swift
//
//
//  Created by Igor  on 05.08.24.
//

import SwiftUI

#if canImport(AVKit)
import AVKit
#endif

#if canImport(UIKit)
import UIKit

@available(iOS 14.0, tvOS 14.0, *)
@MainActor
class LoopingPlayerUIView: UIView, LoopingPlayerProtocol {
    
    /// The AVPlayerLayer that displays the video content.
    private let playerLayer = AVPlayerLayer()
    
    /// The looper responsible for continuous video playback.
    internal var playerLooper: AVPlayerLooper?
    
    /// The queue player that plays the video items.
    internal var player: AVQueuePlayer?
    
    /// Observer for the status of the AVPlayerItem.
    internal var statusObserver: NSKeyValueObservation?
    
    /// Observer for errors from the AVQueuePlayer.
    internal var errorObserver: NSKeyValueObservation?
    
    /// The delegate to be notified about errors encountered by the player.
    weak var delegate: PlayerErrorDelegate?

    /// Initializes a new looping video player view with the specified asset and gravity.
    ///
    /// - Parameters:
    ///   - asset: The AVURLAsset to be played.
    ///   - gravity: The AVLayerVideoGravity to be applied to the video layer.
    init(asset: AVURLAsset, gravity: AVLayerVideoGravity) {
        super.init(frame: .zero)
        setupPlayerComponents(asset: asset, gravity: gravity)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configures the provided AVQueuePlayer with specific properties for video playback.
    ///
    /// This method sets the video gravity and muted state of the player, and assigns it to a player layer.
    /// It is intended to set up the player with the necessary configuration for video presentation based on the given gravity.
    /// - Parameters:
    ///   - player: The AVQueuePlayer to be configured.
    ///   - gravity: The AVLayerVideoGravity determining how the video content should be scaled or fit within the player layer.
    func configurePlayer(_ player: AVQueuePlayer, gravity: AVLayerVideoGravity) {
        player.isMuted = true
        playerLayer.player = player
        playerLayer.videoGravity = gravity
        playerLayer.backgroundColor = UIColor.clear.cgColor
        layer.addSublayer(playerLayer)
        
        playerLooper = AVPlayerLooper(player: player, templateItem: player.items().first!)
        player.play()
    }

    /// Lays out subviews and adjusts the frame of the player layer to match the view's bounds.
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }

    /// Cleans up resources and observers associated with the player.
    ///
    /// This method invalidates the status and error observers to prevent memory leaks,
    /// pauses the player, and clears out player-related references to assist in clean deinitialization.
    /// It also conditionally logs the cleanup process during debug mode.
    deinit {
        cleanUp(player: &player, playerLooper: &playerLooper, statusObserver: &statusObserver, errorObserver: &errorObserver)
    }
}
#endif



