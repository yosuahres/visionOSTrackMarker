//
//  HomeView.swift
//  VisionOSTracking
//
//  Created by HARES on 5/14/26.
//

import SwiftUI
import RealityKit

struct HomeView: View {
    @Bindable var appState: AppState
    let immersiveSpaceIdentifier: String

    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    @State private var selectedFragmentGroupId: UUID?
    @State private var searchText: String = ""

    var filteredFragmentGroups: [FragmentGroup] {
        if searchText.isEmpty {
            return appState.fragmentGroups
        }
        return appState.fragmentGroups.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if appState.canEnterImmersiveSpace {
                NavigationSplitView {
                    List(selection: $selectedFragmentGroupId) {
                        ForEach(filteredFragmentGroups, id: \.id) { fragmentGroup in
                            HStack(spacing: 8) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)
                                    .foregroundStyle(.tint)

                                VStack(alignment: .leading) {
                                    Text(fragmentGroup.name)
                                    Text(fragmentGroup.description)
                                        .lineLimit(1)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle("Session")
                    .searchable(text: $searchText, prompt: "Search groups")
                } detail: {
                    if let selected = appState.fragmentGroups.first(where: { $0.id == selectedFragmentGroupId }) {
                        Model3D(named: selected.usdzModelName) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(0.8)
                                .offset(y: -50)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Text("No object selected")
                    }
                }
                .frame(minWidth: 400, minHeight: 300)
            } else {
                VStack(spacing: 12) {
                    Text("Image Tracking unavailable")
                        .font(.headline)
                    Text("This device must support ARKit image tracking and you must grant world sensing access.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
        }
        .glassBackgroundEffect()
        .toolbar {
            ToolbarItem(placement: .bottomOrnament) {
                if appState.canEnterImmersiveSpace {
                    if !appState.isImmersiveSpaceOpened {
                        if let selected = appState.fragmentGroups.first(where: { $0.id == selectedFragmentGroupId }) {
                            Button("Start tracking") {
                                appState.selectedFragmentGroup = selected
                                Task {
                                    switch await openImmersiveSpace(id: immersiveSpaceIdentifier) {
                                    case .opened:
                                        break
                                    case .error:
                                        print("Error opening immersive space \(immersiveSpaceIdentifier)")
                                    case .userCancelled:
                                        print("User cancelled opening immersive space \(immersiveSpaceIdentifier)")
                                    @unknown default:
                                        break
                                    }
                                }
                            }
                        }
                    } else {
                        Button("Stop tracking") {
                            Task {
                                await dismissImmersiveSpace()
                                appState.didLeaveImmersiveSpace()
                            }
                        }
                    }
                }
            }
        }
        .task {
            if appState.allRequiredProvidersAreSupported {
                await appState.requestWorldSensingAuthorization()
            }
        }
    }
}
