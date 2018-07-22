//
//  ViewController.swift
//  SoundWave
//
//  Created by Bastien Falcou on 12/06/2016.
//  Copyright (c) 2016 Bastien Falcou. All rights reserved.
//

import UIKit
import SoundWave
import AVFoundation
import Speech

class ViewController: UIViewController {
	enum AudioRecodingState {
		case ready
		case recording
		case recorded
		case playing
		case paused
		
		var buttonImage: UIImage {
			switch self {
			case .ready, .recording:
				return UIImage(named: "Record-Button")!
			case .recorded, .paused:
				return UIImage(named: "Play-Button")!
			case .playing:
				return UIImage(named: "Pause-Button")!
			}
		}
		
		var audioVisualizationMode: AudioVisualizationView.AudioVisualizationMode {
			switch self {
			case .ready, .recording:
				return .write
			case .paused, .playing, .recorded:
				return .read
			}
		}
	}
	
	@IBOutlet var recordButton: UIButton!
	@IBOutlet var clearButton: UIButton!
	@IBOutlet var audioVisualizationView: AudioVisualizationView!
	
	@IBOutlet var optionsView: UIView!
	@IBOutlet var optionsViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet var audioVisualizationTimeIntervalLabel: UILabel!
	@IBOutlet var meteringLevelBarWidthLabel: UILabel!
	@IBOutlet var meteringLevelSpaceInterBarLabel: UILabel!
	
    @IBOutlet weak var SpeakingRecog: UILabel!
    
    let viewModel = ViewModel()

	var currentState: AudioRecodingState = .ready {
		didSet {
			self.recordButton.setImage(self.currentState.buttonImage, for: UIControlState())
			self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
			self.clearButton.isHidden = self.currentState == .ready || self.currentState == .playing || self.currentState == .recording
		}
	}
	
	private var chronometer: Chronometer?
    
    let  audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    let path = Bundle.main.url(forResource: "Bach", withExtension: "mp3")
    var audioPlayer : AVAudioPlayer!
    var dangerSign = false
    
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.viewModel.askAudioRecordingPermission()
		
		self.viewModel.audioMeteringLevelUpdate = { [weak self] meteringLevel in
			guard let this = self, this.audioVisualizationView.audioVisualizationMode == .write else {
				return
			}
			this.audioVisualizationView.addMeteringLevel(meteringLevel)
		}
        
		self.viewModel.audioDidFinish = { [weak self] in
			self?.currentState = .recorded
			self?.audioVisualizationView.stop()
            
		}
    
	}
    
    fileprivate func startRecording() throws {
        // 1
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        
        // 2
        node.installTap(onBus: 0, bufferSize: 1024,
                        format: recordingFormat) { [unowned self]
                            (buffer, _) in
                            self.request.append(buffer)
        }
        
        // 3
        audioEngine.prepare()
        try audioEngine.start()
        
        audioPlayer = try? AVAudioPlayer(contentsOf: path!)
        audioPlayer.stop()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request) {
            (result, _) in
            if let transcription = result?.bestTranscription {
                self.SpeakingRecog.text = transcription.formattedString
                if (transcription.formattedString.contains("fine")) {
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer.play()
                    self.SpeakingRecog.text = "Enjoy your shower time 😊"
                    self.stopRecording()
                } else {
                    self.warnToUser()
                }
            }
        }
    }
    
    fileprivate func stopRecording() {
        audioEngine.stop()
        request.endAudio()
        recognitionTask?.cancel()
    }
    
    func warnToUser() {
        // to play sound
        AudioServicesPlaySystemSound (1005)
        
        let string = "Tony Stark, Are you OK?"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    func warnToOthers() {
        let alert = UIAlertController(title: "警报", message: "xxx在浴室遇到危险！", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "马上去查看", style: UIAlertActionStyle.default, handler: nil))
        alert.addAction(UIAlertAction(title: "已处理，警报解除", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
	// MARK: - Actions
	
	@IBAction func recordButtonDidTouchDown(_ sender: AnyObject) {
		if self.currentState == .ready {
			self.viewModel.startRecording { [weak self] soundRecord, error in
				if let error = error {
					self?.showAlert(with: error)
					return
				}
				
				self?.currentState = .recording
				
				self?.chronometer = Chronometer()
				self?.chronometer?.start()
			}
		}
	}
	
	@IBAction func recordButtonDidTouchUpInside(_ sender: AnyObject) {
		switch self.currentState {
		case .recording:
			self.chronometer?.stop()
			self.chronometer = nil
			
			self.viewModel.currentAudioRecord!.meteringLevels = self.audioVisualizationView.scaleSoundDataToFitScreen()
			self.audioVisualizationView.audioVisualizationMode = .read
		
			do {
				try self.viewModel.stopRecording()
				self.currentState = .recorded
                
//                if (self.dangerSign) {
                    
                    SFSpeechRecognizer.requestAuthorization {
                        (authStatus) in
                        switch authStatus {
                        case .authorized:
                            do {
                                try self.startRecording()
                            } catch let error {
                                print("There was a problem starting recording: \(error.localizedDescription)")
                            }
                        case .denied:
                            print("Speech recognition authorization denied")
                        case .restricted:
                            print("Not available on this device")
                        case .notDetermined:
                            print("Not determined")
                        }
                    }
//                }
			} catch {
				self.currentState = .ready
				self.showAlert(with: error)
			}
		case .recorded, .paused:
			do {
				let duration = try self.viewModel.startPlaying()
				self.currentState = .playing
				self.audioVisualizationView.meteringLevels = self.viewModel.currentAudioRecord!.meteringLevels
				self.audioVisualizationView.play(for: duration)
                print(duration.advanced(by: 0))
                if (duration.isLessThanOrEqualTo(30)) {
                    self.dangerSign = true
                }
			} catch {
				self.showAlert(with: error)
			}
		case .playing:
			do {
				try self.viewModel.pausePlaying()
				self.currentState = .paused
				self.audioVisualizationView.pause()
			} catch {
				self.showAlert(with: error)
			}
		default:
			break
		}
	}
	
	@IBAction func clearButtonTapped(_ sender: AnyObject) {
		do {
			try self.viewModel.resetRecording()
            
			self.audioVisualizationView.reset()
			self.currentState = .ready
		} catch {
			self.showAlert(with: error)
		}
	}
	
	@IBAction func switchValueChanged(_ sender: AnyObject) {
		let theSwitch = sender as! UISwitch
		if theSwitch.isOn {
			self.view.backgroundColor = UIColor.mainBackgroundPurple
			self.audioVisualizationView.gradientStartColor = UIColor.audioVisualizationPurpleGradientStart
			self.audioVisualizationView.gradientEndColor = UIColor.audioVisualizationPurpleGradientEnd
		} else {
			self.view.backgroundColor = UIColor.mainBackgroundGray
			self.audioVisualizationView.gradientStartColor = UIColor.audioVisualizationGrayGradientStart
			self.audioVisualizationView.gradientEndColor = UIColor.audioVisualizationGrayGradientEnd
		}
	}

	@IBAction func audioVisualizationTimeIntervalSliderValueDidChange(_ sender: AnyObject) {
		let audioVisualizationTimeIntervalSlider = sender as! UISlider
		self.viewModel.audioVisualizationTimeInterval = TimeInterval(audioVisualizationTimeIntervalSlider.value)
        
		self.audioVisualizationTimeIntervalLabel.text = String(format: "%.2f", self.viewModel.audioVisualizationTimeInterval)
	}

	@IBAction func meteringLevelBarWidthSliderValueChanged(_ sender: AnyObject) {
		let meteringLevelBarWidthSlider = sender as! UISlider
		self.audioVisualizationView.meteringLevelBarWidth = CGFloat(meteringLevelBarWidthSlider.value)
        
		self.meteringLevelBarWidthLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
	}
	
	@IBAction func meteringLevelSpaceInterBarSliderValueChanged(_ sender: AnyObject) {
		let meteringLevelSpaceInterBarSlider = sender as! UISlider
		self.audioVisualizationView.meteringLevelBarInterItem = CGFloat(meteringLevelSpaceInterBarSlider.value)
        
		self.meteringLevelSpaceInterBarLabel.text = String(format: "%.2f", self.audioVisualizationView.meteringLevelBarWidth)
	}
	
	@IBAction func optionsButtonTapped(_ sender: AnyObject) {
		let shouldExpand = self.optionsViewHeightConstraint.constant == 0
		self.optionsViewHeightConstraint.constant = shouldExpand ? 165.0 : 0.0
		UIView.animate(withDuration: 0.2) {
			self.optionsView.subviews.forEach { $0.alpha = shouldExpand ? 1.0 : 0.0 }
			self.view.layoutIfNeeded()
		}
	}
}
