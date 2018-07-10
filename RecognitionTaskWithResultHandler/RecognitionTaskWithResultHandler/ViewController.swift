//
//  ViewController.swift
//  SFQuota
//
//  Created by Yuske Fukuyama on 2018/07/10.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
  
  var session = AVAudioSession.sharedInstance()
  var engine = AVAudioEngine()
  var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
  var recognizerRequest: SFSpeechAudioBufferRecognitionRequest!
  var task: SFSpeechRecognitionTask?
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
      
      isListening = true
      stopButton.isEnabled = true
    }
    catch let error {
      logger.error(error: error)
    }
    
    task = recognizer?.recognitionTask(with: recognizerRequest) { [unowned self] (result, error) in
      if let error = error {
        logger.error(error: error)
      }
      
      guard let result = result else {
        logger.debug(message: "no result from recognition task result handler")
        return
      }
      
      logger.debug(message: result.description)
      logger.debug(message: result.bestTranscription.formattedString)
      
      if result.isFinal {
        logger.debug(message: "result.isFinal")
      }

      if let task = self.task {
        logger.debug(message: "RecognitionTask State \(task.state.rawValue)")
        
        if task.isFinishing {
          logger.debug(message: "task.isFinishing")
        }
        if task.isCancelled {
          logger.debug(message: "task.isCancelled")
        }
      }
    }
    
    logger.debug(message: "RecognitionTask State [initial]:\(task!.state.rawValue)")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
      logger.debug(message: "RecognitionTask State [+15.0]:\(self.task!.state.rawValue)")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 55.0) {
      logger.debug(message: "RecognitionTask State [+55.0]:\(self.task!.state.rawValue)")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 65.0) {
      logger.debug(message: "RecognitionTask State [+65.0]:\(self.task!.state.rawValue)")
    }
  }
  
  func stopListening() {
    // request = nil
    // task = nil
    isListening = false
    logger.info(message: "stopListening")
    engine.stop()
    recognizerRequest.endAudio()
    engine.inputNode.removeTap(onBus: inputNodeBus)
    task?.cancel()
    deactivateAudio()
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
}


