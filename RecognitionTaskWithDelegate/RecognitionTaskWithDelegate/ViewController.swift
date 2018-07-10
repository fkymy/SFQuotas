//
//  ViewController.swift
//  RecognitionTaskWithDelegate
//
//  Created by Yuske Fukuyama on 2018/07/10.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//
import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
  
  var session = AVAudioSession.sharedInstance()
  var engine = AVAudioEngine()
  var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
  var recognizerRequest: SFSpeechAudioBufferRecognitionRequest!
  var recognitionTask: SFSpeechRecognitionTask?
  let inputNodeBus: AVAudioNodeBus = 0
  let bufferSize: AVAudioFrameCount = 1024
  var isListening = false {
    didSet {
      statusLabel.text = isListening ? "is Listening" : "not listening"
    }
  }
  
  lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.white
    return label
  }()
  
  let startButton: BorderedButton = {
    let button = BorderedButton()
    button.setTitle("Buffer", for: .normal)
    button.addTarget(self, action: #selector(onStart), for: .touchUpInside)
    return button
  }()
  
  let stopButton: BorderedButton = {
    let button = BorderedButton()
    button.setTitle("Stop", for: .normal)
    button.addTarget(self, action: #selector(onStop), for: .touchUpInside)
    return button
  }()
  
  func setupViews() {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = UILayoutConstraintAxis.vertical
    stackView.distribution = UIStackViewDistribution.fill
    stackView.alignment = UIStackViewAlignment.center
    stackView.spacing = 16.0
    
    stackView.addArrangedSubview(statusLabel)
    stackView.addArrangedSubview(startButton)
    stackView.addArrangedSubview(stopButton)
    view.addSubview(stackView)
    
    let stackViewCenterX = stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    let stackViewCenterY = stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    NSLayoutConstraint.activate([
      stackViewCenterX,
      stackViewCenterY,
      ])
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    logger.info(message: "viewDidLoad")
    recognizer?.delegate = self
    setupViews()
    authorizeSpeech()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopListening()
  }
  
  deinit {
    stopListening()
  }
  
  @objc func onStart() {
    guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
      logger.debug(message: "SFSpeechRecognizer authorizationStatus is not authorized")
      return
    }
    guard !engine.isRunning else {
      logger.debug(message: "AudioEngine is already running")
      return
    }
    
    activateAudio()
    startListening()
  }
  
  @objc func onStop() {
    stopListening()
  }
  
  func startListening() {
    recognizerRequest = SFSpeechAudioBufferRecognitionRequest()
    recognizerRequest.shouldReportPartialResults = true
    
    let node = engine.inputNode
    let format = node.outputFormat(forBus: 0)
    node.installTap(onBus: inputNodeBus, bufferSize: bufferSize, format: format) { (buffer, time) in
      self.recognizerRequest.append(buffer)
    }
    
    engine.prepare()
    
    do {
      try engine.start()
    }
    catch let error {
      logger.error(error: error)
    }
    
    isListening = true
    startButton.isEnabled = false
    stopButton.isEnabled = true
    
    recognitionTask = recognizer?.recognitionTask(with: recognizerRequest, delegate: self)
    writeLogForMinute()
  }
  
  func stopListening() {
    logger.info(message: "stopListening")
    recognizerRequest.endAudio()
    recognitionTask?.finish()
    engine.stop()
    engine.inputNode.removeTap(onBus: self.inputNodeBus)
    deactivateAudio()
    
    startButton.isEnabled = true
    stopButton.isEnabled = false
    isListening = false
  }
  
  func activateAudio() {
    do {
      logger.info(message: "activating audio")
      try session.setCategory(AVAudioSessionCategoryRecord)
      try session.setActive(true)
    }
    catch let error {
      logger.error(error: error)
    }
  }
  
  func deactivateAudio() {
    do {
      logger.info(message: "deactivating audio")
      try session.setActive(false)
    }
    catch let error {
      logger.error(error: error)
    }
  }
  
  func authorizeSpeech() {
    SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
      var isAuthorized = false
      
      switch authStatus {
      case .authorized:
        logger.info(message: "Speech Authorized")
        isAuthorized = true
      case .denied:
        logger.info(message: "Speech Denied Authorization")
        isAuthorized = false
      case .restricted:
        logger.info(message: "Speech Not Available")
        isAuthorized = false
      case .notDetermined:
        logger.info(message: "Speech Not Determined")
        isAuthorized = false
      }
      
      DispatchQueue.main.async {
        self.startButton.isEnabled = isAuthorized
      }
    }
  }
  
  func writeLogForMinute() {
    logger.debug(message: "RecognitionTask State [initial]:\(recognitionTask!.state.rawValue)")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
      logger.debug(message: "RecognitionTask State [+15.0]:\(self.recognitionTask!.state.rawValue)")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 55.0) {
      logger.debug(message: "RecognitionTask State [+55.0]:\(self.recognitionTask!.state.rawValue)")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 65.0) {
      logger.debug(message: "RecognitionTask State [+65.0]:\(self.recognitionTask!.state.rawValue)")
    }
  }
}

extension ViewController: SFSpeechRecognitionTaskDelegate {
  // beginning a task
  func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
    logger.info(message: "# [speechRecognitionDidDetectSpeech]")
  }
  
  // finishing a task
  func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
    logger.info(message: "# [didFinishRecognition]")
    logger.debug(message: recognitionResult.description)
  }
  
  func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
    logger.info(message: "# [didFinishSuccessfully]")
    if successfully == true {
      logger.debug(message: "successfully == true")
    }
    else {
      logger.debug(message: "successfully == false")
    }
  }
  
  func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
    logger.info(message: "# [speechRecognitionTaskFinishedReadingAudio]")
    if task.isFinishing {
      logger.debug(message: "task isFinishing")
    }
    if task.isCancelled {
      logger.debug(message: "task isCancelled")
    }
  }
  
  func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
    logger.info(message: "# [speechRecognitionTaskWasCancelled]")
  }
  
  // getting a transcript
  func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
    logger.info(message: "# [didHypothesizeTranscript]")
    logger.debug(message: transcription.description)
    
    if task.isFinishing {
      logger.debug(message: "task isFinishing")
    }
    if task.isCancelled {
      logger.debug(message: "task isCancelled")
    }
  }
}
