import Foundation
import Combine

/// Bridges MLXReadingService's model-loading state into the UI-friendly DownloadState enum.
///
/// MLX Swift downloads the Qwen2.5-1.5B model directly from HuggingFace Hub the first time
/// `LLMModelFactory.loadContainer()` is called — no separate GGUF download is needed.
/// This class observes MLXReadingService and translates its ModelState for the download
/// banner in ReadingScene.
@MainActor
final class ModelDownloadManager: ObservableObject {

    static let shared = ModelDownloadManager()

    // MARK: - Published state

    enum DownloadState: Equatable {
        case notStarted
        case downloading(progress: Double)   // indeterminate while HF download is in progress
        case completed
        case failed(String)
    }

    @Published var state: DownloadState = .notStarted

    var isModelReady: Bool { state == .completed }

    // MARK: - Private

    private var cancellable: AnyCancellable?

    private var progressCancellable: AnyCancellable?

    private init() {
        // Mirror MLXReadingService state → DownloadState for the UI banner.
        cancellable = MLXReadingService.shared.$modelState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] modelState in
                switch modelState {
                case .idle:
                    self?.state = .notStarted
                case .loading:
                    // Real progress comes via the separate downloadProgress publisher.
                    if case .downloading = self?.state { /* keep updating */ } else {
                        self?.state = .downloading(progress: 0)
                    }
                case .ready:
                    self?.state = .completed
                case .failed(let message):
                    self?.state = .failed(message)
                }
            }

        // Forward real download fraction from Hub into the banner progress bar.
        progressCancellable = MLXReadingService.shared.$downloadProgress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fraction in
                if case .downloading = self?.state {
                    self?.state = .downloading(progress: fraction)
                }
            }
    }

    // MARK: - Public API

    /// Trigger model download + load. Safe to call multiple times.
    func startDownload() {
        guard state != .completed else { return }
        Task { await MLXReadingService.shared.loadModel() }
    }

    /// Retry after a failure.
    func retryDownload() {
        state = .notStarted
        Task { await MLXReadingService.shared.loadModel() }
    }
}
