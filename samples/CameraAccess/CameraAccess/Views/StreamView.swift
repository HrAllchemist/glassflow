/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the
 * LICENSE file in the root directory of this source tree.
 */

//
// StreamView.swift
//
// Main UI for GlassFlow real-time transcription.
// White background with transcript as the primary content area.
//

import MWDATCore
import SwiftUI

struct StreamView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var wearablesVM: WearablesViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel
  @ObservedObject var transcriptionVM: TranscriptionViewModel

  var body: some View {
    ZStack {
      Color(hex: "F8F7F5")
        .edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
        // Top bar with status
        TopBar(
          transcriptionVM: transcriptionVM,
          geminiVM: geminiVM,
          webrtcVM: webrtcVM
        )

        // Main transcript area
        TranscriptionContentView(viewModel: transcriptionVM)

        // Bottom controls
        ControlsView(
          viewModel: viewModel,
          geminiVM: geminiVM,
          webrtcVM: webrtcVM,
          transcriptionVM: transcriptionVM
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
      }
    }
    .onDisappear {
      Task {
        if viewModel.streamingStatus != .stopped {
          await viewModel.stopSession()
        }
        if geminiVM.isGeminiActive {
          geminiVM.stopSession()
        }
        if webrtcVM.isActive {
          webrtcVM.stopSession()
        }
        if transcriptionVM.isActive {
          transcriptionVM.stopSession()
        }
      }
    }
    .sheet(isPresented: $viewModel.showPhotoPreview) {
      if let photo = viewModel.capturedPhoto {
        PhotoPreviewView(
          photo: photo,
          onDismiss: {
            viewModel.dismissPhotoPreview()
          }
        )
      }
    }
    .alert("AI Assistant", isPresented: Binding(
      get: { geminiVM.errorMessage != nil },
      set: { if !$0 { geminiVM.errorMessage = nil } }
    )) {
      Button("OK") { geminiVM.errorMessage = nil }
    } message: {
      Text(geminiVM.errorMessage ?? "")
    }
    .alert("Live Stream", isPresented: Binding(
      get: { webrtcVM.errorMessage != nil },
      set: { if !$0 { webrtcVM.errorMessage = nil } }
    )) {
      Button("OK") { webrtcVM.errorMessage = nil }
    } message: {
      Text(webrtcVM.errorMessage ?? "")
    }
    .alert("Transcription", isPresented: Binding(
      get: { transcriptionVM.errorMessage != nil },
      set: { if !$0 { transcriptionVM.errorMessage = nil } }
    )) {
      Button("OK") { transcriptionVM.errorMessage = nil }
    } message: {
      Text(transcriptionVM.errorMessage ?? "")
    }
  }
}

// MARK: - Top Bar

struct TopBar: View {
  @ObservedObject var transcriptionVM: TranscriptionViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel

  var body: some View {
    HStack {
      Text("GlassFlow")
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.primary)

      Spacer()

      if transcriptionVM.isActive {
        StatusDot(color: statusColor, text: statusText)
      }
      if geminiVM.isGeminiActive {
        StatusDot(color: .green, text: "AI")
      }
      if webrtcVM.isActive {
        StatusDot(color: .blue, text: "Live")
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
  }

  private var statusColor: Color {
    switch transcriptionVM.connectionState {
    case .connected: return .green
    case .connecting: return .yellow
    case .disconnected: return .gray
    case .error: return .red
    }
  }

  private var statusText: String {
    switch transcriptionVM.connectionState {
    case .connected: return "Transcribing"
    case .connecting: return "Connecting..."
    case .disconnected: return "Off"
    case .error: return "Error"
    }
  }
}

struct StatusDot: View {
  let color: Color
  let text: String

  var body: some View {
    HStack(spacing: 5) {
      Circle()
        .fill(color)
        .frame(width: 7, height: 7)
      Text(text)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 5)
    .background(Color(hex: "FCFBF9"))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(hex: "E2E2E0"), lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

// MARK: - Controls

struct ControlsView: View {
  @ObservedObject var viewModel: StreamSessionViewModel
  @ObservedObject var geminiVM: GeminiSessionViewModel
  @ObservedObject var webrtcVM: WebRTCSessionViewModel
  @ObservedObject var transcriptionVM: TranscriptionViewModel

  var body: some View {
    HStack(spacing: 12) {
      // Stop streaming
      Button {
        Task { await viewModel.stopSession() }
      } label: {
        Image(systemName: "stop.fill")
          .font(.system(size: 14))
          .foregroundColor(.red)
          .frame(width: 48, height: 48)
          .background(Color.red.opacity(0.1))
          .cornerRadius(24)
      }

      Spacer()

      // Transcription toggle
      ControlPill(
        icon: transcriptionVM.isActive ? "text.bubble.fill" : "text.bubble",
        label: "Scribe",
        isActive: transcriptionVM.isActive,
        isDisabled: geminiVM.isGeminiActive || webrtcVM.isActive
      ) {
        Task {
          if transcriptionVM.isActive {
            transcriptionVM.stopSession()
          } else {
            await transcriptionVM.startSession()
          }
        }
      }

      // Gemini AI toggle
      ControlPill(
        icon: geminiVM.isGeminiActive ? "waveform.circle.fill" : "waveform.circle",
        label: "AI",
        isActive: geminiVM.isGeminiActive,
        isDisabled: webrtcVM.isActive || transcriptionVM.isActive
      ) {
        Task {
          if geminiVM.isGeminiActive {
            geminiVM.stopSession()
          } else {
            await geminiVM.startSession()
          }
        }
      }

      // WebRTC Live toggle
      ControlPill(
        icon: webrtcVM.isActive
          ? "antenna.radiowaves.left.and.right.circle.fill"
          : "antenna.radiowaves.left.and.right.circle",
        label: "Live",
        isActive: webrtcVM.isActive,
        isDisabled: geminiVM.isGeminiActive || transcriptionVM.isActive
      ) {
        Task {
          if webrtcVM.isActive {
            webrtcVM.stopSession()
          } else {
            await webrtcVM.startSession()
          }
        }
      }
    }
  }
}

struct ControlPill: View {
  let icon: String
  let label: String
  let isActive: Bool
  let isDisabled: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.system(size: 16))
        Text(label)
          .font(.system(size: 13, weight: .medium))
      }
      .foregroundColor(isActive ? .white : .primary)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(isActive ? Color.black : Color(hex: "FCFBF9"))
      .overlay(
        RoundedRectangle(cornerRadius: 24)
          .stroke(Color(hex: "E2E2E0"), lineWidth: isActive ? 0 : 1)
      )
      .cornerRadius(24)
    }
    .opacity(isDisabled ? 0.35 : 1.0)
    .disabled(isDisabled)
  }
}

// MARK: - Color Extension

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r = Double((int >> 16) & 0xFF) / 255.0
    let g = Double((int >> 8) & 0xFF) / 255.0
    let b = Double(int & 0xFF) / 255.0
    self.init(red: r, green: g, blue: b)
  }
}
