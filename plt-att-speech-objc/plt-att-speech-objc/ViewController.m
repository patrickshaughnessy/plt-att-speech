//
//  ViewController.m
//  plt-att-speech-objc
//
//  Created by Morgan Davis on 11/2/15.
//  Copyright © 2015 Plantronics. All rights reserved.
//

#import "ViewController.h"
@import AVFoundation;


#define DOCUMENTS_PATH  [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]
#define RECORDING_PATH  [DOCUMENTS_PATH stringByAppendingPathComponent:@"recording.caf"]
#define RECORDING_URL   [NSURL fileURLWithPath:RECORDING_PATH]


@interface ViewController () <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

- (IBAction)listenStopButton:(UIButton *)sender;
- (void)setupAudioSession;
- (void)startRecording;
- (void)stopRecording;
- (void)playAudioData:(NSData *)audioData;

@property (nonatomic, retain) AVAudioRecorder       *recorder;
@property (nonatomic, retain) AVAudioPlayer         *player;

@end


@implementation ViewController

#pragma mark - Public

- (IBAction)listenStopButton:(UIButton *)sender
{
    NSLog(@"listenStopButton:");
    
    if (!self.recorder || !self.recorder.isRecording) {
        // start recording
        [self setupAudioSession];
        [self startRecording];
        [sender setTitle:@"Stop Listening" forState:UIControlStateNormal];
    }
    else {
        // stop recording
        [self stopRecording];
        [sender setTitle:@"Start Listening" forState:UIControlStateNormal];
    }
}

#pragma mark - Private

- (void)setupAudioSession
{
    NSLog(@"setupAudioSession");
    
    NSError *err = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // setup audio session
    
    [audioSession setMode:AVAudioSessionModeDefault error:&err];
    if (err) { NSLog(@"Error configuring audio session: %@", audioSession); }
    
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:&err];
    if (err) { NSLog(@"Error configuring audio session: %@", audioSession); }
    
    [audioSession setActive:YES error:&err];
    if (err) {  NSLog(@"Error activiting audio session: %@", audioSession); }

    // set BT headset as input (also sets output)
    
    for (AVAudioSessionPortDescription *route in audioSession.availableInputs) {
        if ([route.portType isEqualToString:AVAudioSessionPortBluetoothHFP] ) {
            NSLog(@"Setting input route to: %@", route.portType);
            err = nil;
            [audioSession setPreferredInput:route error:&err];
            if (err) { NSLog(@"Error setting input audio route: %@", err); }
            break;
        }
    }
}

- (void)startRecording
{
    NSLog(@"startRecording");
    
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:RECORDING_PATH error:&err];
    if (err) { NSLog(@"Error removing previous recording: %@", err); }

    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
    settings[AVFormatIDKey] = @(kAudioFormatLinearPCM);
    settings[AVSampleRateKey] = @(44100.0);
    settings[AVNumberOfChannelsKey] = @(1);
    settings[AVLinearPCMBitDepthKey] = @(16);
    settings[AVLinearPCMIsBigEndianKey] = @(NO);
    settings[AVLinearPCMIsFloatKey] = @(NO);
    
    NSURL *url = [NSURL fileURLWithPath:RECORDING_PATH];
    err = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&err];
    if (err) {
        NSLog(@"Error initializing audio recorder: %@", err);
    }
    else {
        self.recorder.delegate = self;
        [self.recorder prepareToRecord];
        [self.recorder record];
    }
}

- (void)stopRecording
{
    NSLog(@"stopRecording");
    
    [self.recorder stop];
}

- (void)playAudioData:(NSData *)audioData
{
    NSLog(@"playAudioData: %lu", (unsigned long)audioData.length);
    
    if (self.player) {
        NSLog(@"Killing old player");
        [self.player stop];
        self.player = nil;
    }
    
    NSError *err = nil;
    self.player = [[AVAudioPlayer alloc] initWithData:audioData error:&err];
    if (err) {
        NSLog(@"Error initializing audio player: %@ %ld %@", err.domain, (long)err.code, err.userInfo);
    }
    else {
        NSLog(@"audioData: %ld", audioData.length);
        self.player.delegate = self;
        self.player.volume = 1.0;
        [self.player prepareToPlay];
        [self.player play];
    }
}

#pragma mark - AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSLog (@"audioRecorderDidFinishRecording: %@ successfully: %@", recorder, (flag ? @"YES" : @"NO"));
    
    NSError *err = nil;
    NSData *audioData = [NSData dataWithContentsOfURL:RECORDING_URL options:0 error:&err];
    if (!audioData) {
        NSLog(@"Error getting audio data from file: %@", err);
    }
    else {
        [self playAudioData:audioData];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"audioPlayerDidFinishPlaying: %@ successfully: %@", player, (flag ? @"YES" : @"NO"));
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error
{
    NSLog(@"audioPlayerDecodeErrorDidOccur: %@ error: %@", player, error);
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player
{
    NSLog(@"audioPlayerBeginInterruption: %@", player);
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags
{
    NSLog(@"audioPlayerEndInterruption: %@ withOptions: %lu", player, (unsigned long)flags);
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withFlags:(NSUInteger)flags
{
    NSLog(@"audioPlayerEndInterruption: %@ withFlags: %lu", player, (unsigned long)flags);
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    NSLog(@"audioPlayerEndInterruption: %@", player);
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
