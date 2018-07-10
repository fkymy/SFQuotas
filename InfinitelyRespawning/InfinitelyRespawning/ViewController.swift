//
//  ViewController.swift
//  InfinitelyRespawning
//
//  Created by Yuske Fukuyama on 2018/07/11.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController {
  
  var session = AVAudioSession.sharedInstance()
  var engine = AVAudioEngine()
  var recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
  var recognizerRequest: SFSpeechAudioBufferRecognitionRequest!
  var recognitionTask: SFSpeechRecognitionTask?
  let inputNodeBus: AVAudioNodeBus = 0
  let bufferSize: AVAudioFrameCount = 1024
  
  var counter = 0
  let secondsPerTask = 2.0
  let dispatchGroup = DispatchGroup()
  let dispatchQueue = DispatchQueue(label: "queue") // not .concurrent
  lazy var statusLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.white
    label.text = "Hello"
    return label
  }()
  
  let startButton: BorderedButton = {
    let button = BorderedButton()
    button.setTitle("Buffer", for: .normal)
    button.addTarget(self, action: #selector(onStart), for: .touchUpInside)
    button.isEnabled = true
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
  
  override func didReceiveMemoryWarning() {
    stopListening()
    logger.fatal(message: "didReceiveMemoryWarning")
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
    
    activateAudio()
    startListening()
    startButton.isEnabled = false
    stopButton.isEnabled = true
  }
  
  @objc func onStop() {
    stopListening()
  }
  
  func startListening() {
    counter = counter + 1
    logger.debug(message: "# [START Recognition Task \(counter)]")
    
    recognizerRequest = SFSpeechAudioBufferRecognitionRequest()
    
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
    
    recognitionTask = recognizer?.recognitionTask(with: recognizerRequest, delegate: self)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + secondsPerTask) {
      self.recognizerRequest.endAudio()
      self.recognitionTask?.finish()
      self.engine.stop()
      self.engine.inputNode.removeTap(onBus: self.inputNodeBus)
      
      // hmm...
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
        self.startListening()
      })
    }
  }
  
  func stopListening() {
    logger.info(message: "stopListening")
    recognizerRequest.endAudio()
    recognitionTask?.finish()
    engine.stop()
    engine.inputNode.removeTap(onBus: self.inputNodeBus)
    self.recognitionTask = nil
    self.recognizerRequest = nil
    deactivateAudio()
    
    stopButton.isEnabled = false
    startButton.isEnabled = true
  }
}

// MARK: - Utils
extension ViewController {
  
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

// MARK: - SFSpeechRecognitionTaskDelegate
extension ViewController: SFSpeechRecognitionTaskDelegate {
  
  // finishing a task
  func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
    logger.info(message: "didFinishRecognition")
    logger.debug(message: recognitionResult.description)
  }
  
  func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
    logger.info(message: "didFinishSuccessfully")
    if successfully == true {
      logger.info(message: "successfully == true")
    }
    else {
      logger.info(message: "successfully == false")
    }
  }
  
  func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
    logger.info(message: "speechRecognitionTaskFinishedReadingAudio")
    if task.isFinishing {
      logger.debug(message: "task isFinishing")
    }
    if task.isCancelled {
      logger.debug(message: "task isCancelled")
    }
  }
  
  func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
    logger.info(message: "speechRecognitionTaskWasCancelled")
  }
}
