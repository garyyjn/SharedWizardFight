//
//  ImmersiveView.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
struct ImmersiveView: View {
    @Environment(CommonSpaceViewModel.self) var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    
    
    @State private var handTracker = HandTracking()
    @Binding var fireballModel:FireViewModel
    
    @State var worldAnchor: Entity = AnchorEntity(.image(group: "CardDeck20", name: "IMG_4107 2"), trackingMode: .once)
    
    
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
            
            fireballModel.root = worldAnchor
            worldAnchor.addChild(fireballModel.myball)
            worldAnchor.addChild(fireballModel.yourball)
            
            handTracker.fireballModel = fireballModel
            Task {
                await handTracker.runARKitSession()
            }
        }.task {
            await handTracker.processHandAnchorUpdates()
        }
        .task {
            do {
                if model.dataProvidersAreSupported && model.isReadyToRun {
                    try await model.runSession()
                } else {
                    await dismissImmersiveSpace()
                }
            } catch {
                logger.error("Failed to start session: \(error)")
                await dismissImmersiveSpace()
                openWindow(id: "error")
            }
        }
        .task {
            await model.processUpdates()
        }
        .task {
            await model.monitorSessionEvents()
        }
        .task(priority: .low) {
            await model.processLowUpdates()
        }
        .onChange(of: model.errorState) {
            openWindow(id: "error")
        }
    }
}
