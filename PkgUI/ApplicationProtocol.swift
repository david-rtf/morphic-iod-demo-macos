import Foundation

@objc(AppProtocol)
protocol AppProtocol {
    func log(stdOut: String) -> Void
    func log(stdErr: String) -> Void
    
    func installStarted() -> Void
    func installFinished() -> Void
    func installPhase(phase: String) -> Void
    func reportProgress(progress: Double) -> Void
}
