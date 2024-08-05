//
//  LoopPlayerViewRepresentableMacOS.swift
//
//
//  Created by Igor  on 05.08.24.
//

import SwiftUI
#if canImport(AVKit)
import AVKit
#endif

#if os(macOS)
import AppKit

/// A view representable for macOS to display a looping video player.
@available(macOS 11.0, *)
@MainActor
struct LoopPlayerViewRepresentableMacOS: NSViewRepresentable {
    
    /// Settings for the player view
    private let settings: Settings
    
    /// The video asset to be played.
    private let asset: AVURLAsset?
    
    /// State to store any error that occurs
    @State private var error: VPErrors?

    /// Initializes the player view with settings
    /// - Parameter settings: The settings to configure the player view
    init(settings: Settings) {
        let name = settings.name
        let e: VPErrors?
        
        self.asset = assetForName(name: name, ext: settings.ext)
        self.settings = settings
        
        if !settings.areUnique{
            e = .settingsNotUnique
        }else if asset == nil{
             e = .sourceNotFound(name)
        }else{
            e = nil
        }

        self._error = State(initialValue: e)
    }
    
    func makeNSView(context: Context) -> NSView {
        let container = NSView()
        
        if let asset{
            let player = createPlayerView(context: context, asset: asset)
            container.addSubview(player)
            activateFullScreenConstraints(for: player, in: containerView)
        }
        
        if let error = error {
            let errorView = errorTplmacOS(error, settings.errorColor, settings.errorFontSize)
            container.addSubview(errorView)
            activateFullScreenConstraints(for: errorView, in: containerView)
        }
        
        return container
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.subviews.filter { $0 is ErrorMsgTextViewMacOS }.forEach { $0.removeFromSuperview() }
        
        if let error = error {
            let errorView = errorTplmacOS(error, settings.errorColor, settings.errorFontSize)
            nsView.addSubview(errorView)
            activateFullScreenConstraints(for: errorView, in: nsView)
        }
    }
    
    private func createPlayerView(context: Context, asset: AVURLAsset) -> LoopingPlayerNSView {
        let player = LoopingPlayerNSView(asset: asset, gravity: settings.gravity)
        player.delegate = context.coordinator
        
        return player
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    @MainActor
    class Coordinator: NSObject, PlayerErrorDelegate {
        let parent: LoopPlayerViewRepresentableMacOS
        
        init(_ parent: LoopPlayerViewRepresentableMacOS) {
            self.parent = parent
        }
        
        deinit {
            print("deinit Coordinator")
        }
        
        func didReceiveError(_ error: VPErrors) {
                self.parent.error = error
        }
    }
}

/// A custom NSTextView for displaying error messages on macOS.
fileprivate class ErrorMsgTextViewMacOS: NSTextView {
    
    /// Overrides the intrinsic content size to allow flexible width and height.
    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }
    
    /// Called when the view is added to a superview. Sets up the constraints for the view.
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let superview = superview else { return }
        
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 10),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -10),
            topAnchor.constraint(equalTo: superview.topAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
    }
    
    /// Adjusts the layout to center the text vertically within the view.
    override func layout() {
        super.layout()
        
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return
        }
        
        let textHeight = layoutManager.usedRect(for: textContainer).size.height
        let containerHeight = bounds.size.height
        let verticalInset = max(0, (containerHeight - textHeight) / 2)
        
        textContainerInset = NSSize(width: 0, height: verticalInset)
    }
}

/// Creates a custom error view for macOS displaying an error message.
/// - Parameters:
///   - error: The error object containing the error description.
///   - color: The color to be used for the error text.
///   - fontSize: The font size to be used for the error text.
/// - Returns: An `NSView` containing the error message text view centered with padding.
fileprivate func errorTplmacOS(_ error: VPErrors, _ color: Color, _ fontSize: CGFloat) -> NSView {
    let textView = ErrorMsgTextViewMacOS()
    textView.isEditable = false
    textView.isSelectable = false
    textView.drawsBackground = false
    textView.string = error.description
    textView.alignment = .center
    textView.font = NSFont.systemFont(ofSize: fontSize)
    textView.textColor = NSColor(color)
    
    let containerView = NSView()
    containerView.addSubview(textView)
    
    textView.translatesAutoresizingMaskIntoConstraints = false
    
    // Center textView in containerView with padding
    NSLayoutConstraint.activate([
        textView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        textView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
        textView.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 10),
        textView.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -10)
    ])
    
    return containerView
}

func activateFullScreenConstraints(for view: NSView, in containerView: NSView) {
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        view.topAnchor.constraint(equalTo: containerView.topAnchor),
        view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
    ])
}

#endif
