//
//  ViewController.swift
//  plt-att-speech-swift
//
//  Created by Morgan Davis on 11/2/15.
//  Copyright © 2015 Plantronics. All rights reserved.
//

import UIKit
import AVFoundation


public class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    /******************************************************************************************************
    MARK:   Constants
    ******************************************************************************************************/
    
    private let RECORDING_URL =     NSFileManager.defaultManager()
        .URLsForDirectory(.DocumentDirectory, inDomains: [.UserDomainMask])[0]
        .URLByAppendingPathComponent("recording.caf")
    
    /******************************************************************************************************
    MARK:   Properties
    ******************************************************************************************************/
    
    private var recorder:           AVAudioRecorder?
    private var player:             AVAudioPlayer?
    
    /******************************************************************************************************
    MARK:   Public
    ******************************************************************************************************/
    
    @IBAction func listenStopButton(sender: UIButton) {
        NSLog("listenStopButton(%@)", sender)
        
        if recorder == nil || !recorder!.recording {
            // start recording
            setupAudioSession()
            startRecording()
            sender.setTitle("Stop Listening", forState: .Normal)
        }
        else {
            // stop recording
            stopRecording()
            sender.setTitle("Start Listening", forState: .Normal)
        }
    }
    
    /******************************************************************************************************
    MARK:   Private
    ******************************************************************************************************/
    
    private func setupAudioSession() {
        NSLog("setupAudioSession()")
        
        // setup audio session
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setMode(AVAudioSessionModeDefault)
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: [.AllowBluetooth])
            try audioSession.setActive(true)
        }
        catch {
            NSLog("Error setting up audio session.")
        }
        
        // set BT headset as input (also sets output)
        
        if let inputRoutes = audioSession.availableInputs {
            for route in inputRoutes {
                if route.portType == AVAudioSessionPortBluetoothHFP {
                    NSLog("Setting input route to: %@", route.portType)
                    do {
                        try audioSession.setPreferredInput(route)
                    }
                    catch {
                        NSLog("Error setting audio input route.")
                    }
                }
            }
        }
        else {
            NSLog("No input audio routes found.")
        }
    }
    
    private func startRecording() {
        NSLog("startRecording()")
        
        let fileManager = NSFileManager.defaultManager()
        try? fileManager.removeItemAtURL(RECORDING_URL)
        
        var settings = [String : AnyObject]()
        settings[AVFormatIDKey] = NSNumber(unsignedInt: kAudioFormatLinearPCM)
        settings[AVSampleRateKey] = 44100.0
        settings[AVNumberOfChannelsKey] = 1
        settings[AVLinearPCMBitDepthKey] = 16
        settings[AVLinearPCMIsBigEndianKey] = false
        settings[AVLinearPCMIsFloatKey] = false
        
        do {
            try recorder = AVAudioRecorder(URL: RECORDING_URL, settings: settings)
            recorder?.delegate = self
            recorder?.prepareToRecord()
            recorder?.record()
        }
        catch {
            NSLog("Error creating audio recorder.")
        }
    }
    
    private func stopRecording() {
        NSLog("stopRecording()")
        
        recorder?.stop()
    }
    
    private func playAudioData(audioData: NSData) {
        NSLog("playAudioData(%d)", audioData.length)
        
        if player != nil {
            NSLog("Killing old player")
            player?.stop()
            player = nil
        }
        
        do {
            try player = AVAudioPlayer(data: audioData)
            player?.delegate = self
            player?.volume = 1.0
            player?.prepareToPlay()
            player?.play()
        }
        catch {
            NSLog("Exceptioon initializing AVAudioPlayer.")
        }
    }
    
    /******************************************************************************************************
    MARK:   AVAudioRecorderDelegate
    ******************************************************************************************************/
    
    public func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        NSLog("audioRecorderDidFinishRecording(%@, successfully: %@)", recorder, (flag ? "true" : "false"))
        
        if flag {
            if let audioData = NSData(contentsOfURL: RECORDING_URL) {
                playAudioData(audioData)
            }
            else {
                NSLog("Error getting audio data.")
            }
        }
        else {
            NSLog("Error recording audio.")
        }
    }
    
    /******************************************************************************************************
    MARK:   AVAudioPlayerDelegate
    ******************************************************************************************************/
    
    public func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        NSLog("audioPlayerDidFinishPlaying(%@, successfully: %@)", player, (flag ? "true" : "false"))
    }
    
    public func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        NSLog("audioPlayerDecodeErrorDidOccur(%@, error: %@)", player, (error == nil ? "nil" : error!))
    }
    
    public func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        NSLog("audioPlayerBeginInterruption(%@)", player)
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer) {
        NSLog("audioPlayerEndInterruption(%@)", player)
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withFlags flags: Int) {
        NSLog("audioPlayerEndInterruption(%@, withFlags: %X)", player, flags)
    }
    
    public func audioPlayerEndInterruption(player: AVAudioPlayer, withOptions flags: Int) {
        NSLog("audioPlayerEndInterruption(%@, withFlags: %X)", player, flags)
    }
    
    /******************************************************************************************************
    MARK:   UIViewController
    ******************************************************************************************************/
    
    override public func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
