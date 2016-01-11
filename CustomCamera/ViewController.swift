import UIKit
import AVFoundation
import Photos

/// Manages the session and devices
class VideoCaptureManager: NSObject {
    /// The camera
    let captureDevice: AVCaptureDevice
    /// The microphone
    let captureAudioDevice: AVCaptureDevice
    /// Where is what we are captureing going? (heres a hint, the session)
    var captureOutput: AVCaptureMovieFileOutput?
    /// Manages the coordination between our two (for now) devices.
    let captureSession: AVCaptureSession
    /// Who cares?
    var delegate: VideoCaptureDelegate?
    
    // Little helper to check if we are recording. do we need this?
    var isRecording: Bool {
        guard let _ = captureOutput else { return false }
        return true
    }
    
    override init() {
        // Device
        captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        captureAudioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        // TODO: safely try
        try! captureDevice.lockForConfiguration()
        captureDevice.focusMode = .ContinuousAutoFocus
        captureDevice.unlockForConfiguration()
        
        // Session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        // TODO: safely try
        try! captureSession.addInput(AVCaptureDeviceInput(device: captureDevice))
        try! captureSession.addInput(AVCaptureDeviceInput(device: captureAudioDevice))
        
        super.init()
    }
    
    /// Routes the capture session to a temporary file on disk.
    func startRecording() {
        let url = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())\(NSDate().timeIntervalSince1970).mov")
        let output = AVCaptureMovieFileOutput()
        captureOutput = output
        captureSession.addOutput(output)
        if let delegate = delegate { delegate.willStartRecording(output, session: captureSession, url: url) }
        output.startRecordingToOutputFileURL(url, recordingDelegate: self)
        if let delegate = delegate { delegate.didStartRecording(output, session: captureSession, url: url) }
    }
    
    /// Stops the current capture output. If no capture output exists, we fail silently.
    /// TODO: maybe not fail silently?
    func stopRecording() {
        guard let captureOutput = captureOutput else { return }
        let url = captureOutput.outputFileURL
        
        if let delegate = delegate {
            delegate.willStopRecording(captureOutput, session: captureSession, url: url)
        }
        captureOutput.stopRecording()
        
        captureSession.removeOutput(captureOutput)
        self.captureOutput = nil
    }
}

extension VideoCaptureManager: AVCaptureFileOutputRecordingDelegate {
    /// Funnels the handler through to our own interface/delegate
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        if let delegate = delegate, captureOutput = captureOutput as? AVCaptureMovieFileOutput {
            delegate.didStopRecording(captureOutput, session: captureSession, url: outputFileURL, error: error)
        }
    }
}

/// Simple view that knows how to fill itself with some kind of capture preview layer
class VideoCapturePreview: UIView {
    private var _avPreviewLayer: AVCaptureVideoPreviewLayer?
    var avPreviewLayer: AVCaptureVideoPreviewLayer? {
        get { return _avPreviewLayer }
        set {
            _avPreviewLayer = newValue
            layer.addSublayer(_avPreviewLayer!)
        }
    }
}

/// Where we're going, we don't need NSNotificationCenter
protocol VideoCaptureDelegate {
    func willStartRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL)
    func didStartRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL)
    func willStopRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL)
    func didStopRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL, error: NSError)
}


class CameraViewController: UIViewController {
    var previewView = VideoCapturePreview()
    var videoCaptureManager = VideoCaptureManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoCaptureManager.delegate = self
        previewView.avPreviewLayer = AVCaptureVideoPreviewLayer(session: videoCaptureManager.captureSession)
    }
}

extension CameraViewController: VideoCaptureDelegate {
    func willStartRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL) {
    }
    
    func didStartRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL) {
    }
    
    func willStopRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL) {
    }
    
    func didStopRecording(output: AVCaptureMovieFileOutput, session: AVCaptureSession, url: NSURL, error: NSError) {
    }
}