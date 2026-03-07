import SwiftUI

// MARK: - Main Transcript Content (fills the screen)

struct TranscriptionContentView: View {
  @ObservedObject var viewModel: TranscriptionViewModel

  var body: some View {
    Group {
      if !viewModel.isActive && viewModel.segments.isEmpty {
        emptyState
      } else if viewModel.segments.isEmpty && viewModel.isActive {
        listeningState
      } else {
        transcriptList
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      Image(systemName: "text.bubble")
        .font(.system(size: 40))
        .foregroundColor(.gray)
      Text("Tap Scribe to start transcribing")
        .font(.system(size: 16))
        .foregroundColor(.gray)
    }
  }

  private var listeningState: some View {
    VStack(spacing: 12) {
      Image(systemName: "waveform")
        .font(.system(size: 32))
        .foregroundColor(.black.opacity(0.4))
      Text("Listening...")
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(.black.opacity(0.5))
    }
  }

  private var transcriptList: some View {
    ScrollViewReader { proxy in
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(alignment: .leading, spacing: 16) {
          ForEach(viewModel.segments) { segment in
            SegmentRow(segment: segment)
              .id(segment.id)
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
      }
      .onChange(of: viewModel.segments.count) { _ in
        scrollToBottom(proxy)
      }
      .onChange(of: viewModel.currentPartialText) { _ in
        scrollToBottom(proxy)
      }
    }
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy) {
    if let lastId = viewModel.segments.last?.id {
      withAnimation(.easeOut(duration: 0.2)) {
        proxy.scrollTo(lastId, anchor: .bottom)
      }
    }
  }
}

// MARK: - Segment Row

struct SegmentRow: View {
  let segment: TranscriptSegment

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Speaker label + timestamp
      HStack(spacing: 6) {
        if let speaker = segment.speaker {
          Text("Speaker \(speaker + 1)")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(speakerColor(speaker))
        }
        Text(timeString(segment.timestamp))
          .font(.system(size: 11, design: .monospaced))
          .foregroundColor(.gray)
      }

      // Transcript text
      Text(segment.text)
        .font(.system(size: 17))
        .foregroundColor(segment.isFinal ? .black : .black.opacity(0.4))
        .fixedSize(horizontal: false, vertical: true)
        .lineSpacing(3)
    }
    .padding(.vertical, 4)
  }

  private func speakerColor(_ speaker: Int) -> Color {
    let colors: [Color] = [
      Color(hex: "3478F6"),  // blue
      Color(hex: "E67E22"),  // orange
      Color(hex: "27AE60"),  // green
      Color(hex: "8E44AD"),  // purple
      Color(hex: "E74C8B"),  // pink
      Color(hex: "16A8A8"),  // teal
    ]
    return colors[speaker % colors.count]
  }

  private func timeString(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }
}

// MARK: - Legacy overlay (kept for Gemini transcript)

struct TranscriptionOverlayView: View {
  @ObservedObject var viewModel: TranscriptionViewModel

  var body: some View {
    TranscriptionContentView(viewModel: viewModel)
  }
}
