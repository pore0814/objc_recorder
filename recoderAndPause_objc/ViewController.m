//
//  ViewController.m
//  recoderAndPause_objc
//
//  Created by 002563 on 2018/10/2.
//  Copyright © 2018年 002563. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#define kRecordAudioFile @"myRecord.caf"

@interface ViewController ()<AVAudioRecorderDelegate>

@property(nonatomic,strong) AVAudioRecorder *audioRecorder; //音頻錄音機
@property(nonatomic,strong) AVAudioPlayer *audioPlayer; //音頻播放器，用於播放錄音文件
@property(nonatomic,strong) NSTimer *timer; // 錄音聲波監控


@property (weak, nonatomic) IBOutlet UIButton *record;
@property (weak, nonatomic) IBOutlet UIButton *pause;
@property (weak, nonatomic) IBOutlet UIButton *resume;
@property (weak, nonatomic) IBOutlet UIButton *stop;
@property (weak, nonatomic) IBOutlet UIProgressView *audioPower;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAudioSession];
}

//設置音頻會話
-(void) setAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    // 設置為播放和錄音狀態，以便可以在錄制完之後播放錄音
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive:YES error:nil];
}

//取得錄音文件保存路徑  @return錄音文件路徑
-(NSURL *) getSavePath {
    NSString *urlStr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr = [urlStr stringByAppendingPathComponent:kRecordAudioFile];
    NSLog(@"file Path: %@",urlStr);
    NSURL *url = [NSURL fileURLWithPath:urlStr];
    return url;
}

// 取得錄音文件設置 @return錄音設置
-(NSDictionary *) getAudioSetting {
    NSMutableDictionary *dicM = [NSMutableDictionary dictionary];
    //設置錄音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    // 設置錄音采樣率，8000是電話採樣率
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //設置通道，這里采用單聲道
    [dicM setObject:@(2) forKey:AVLinearPCMBitDepthKey];
    // 每個采權點位數，分為8,16,24,32
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    
    return dicM;
}

// 取得錄音對象
- (AVAudioRecorder *) audioRecorder {
    if (!_audioRecorder) {
        //創建錄音文件保存路徑
        NSURL *url =  [self getSavePath];
        //創建錄音格式設置
        NSDictionary *setting = [self getAudioSetting];
        // 創建錄音機
        NSError *error = nil;
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:setting error:&error];
        
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES; // 如果要監控聲波則必須設置為YES
        
        if (error) {
            NSLog(@"創建錄音機對象時發生錯誤，錯誤訊息 %@",error.localizedDescription);
            return nil;
        }
    }
    return  _audioRecorder;
}

// 播放器
-(AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSURL *url = [self getSavePath];
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        //设置音乐播放次数  -1为一直循环
        _audioPlayer.numberOfLoops = 0;
        [_audioPlayer prepareToPlay];
        if (error) {
            NSLog(@"播放過程出錯，錯誤訊息：%@",error.localizedDescription);
            return nil;
        }
    }
    return _audioPlayer;
}

// 錄音聲波監控制定制器 @retun定時器
-(NSTimer *) timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(audioPowerChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

//錄音聲波狀態設置
-(void)audioPowerChange {
    [self.audioRecorder updateMeters]; // 更新測量值
    //取得第一个通道的音频，注意音频强度范围时-160到0
    float power = [self.audioRecorder averagePowerForChannel:0]; // 均值
    CGFloat progress = (1.0/160.0) * (power + 160.0);
    [self.audioPower setProgress:progress];
}

- (IBAction)recordClick:(id)sender {
    if (![self.audioRecorder isRecording]) {
        [self.audioRecorder record];
        //获取古代的时间
        self.timer.fireDate = [NSDate distantPast];
    }
}

- (IBAction)pauseClick:(id)sender {
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder pause];
        self.timer.fireDate = [NSDate distantFuture];
    }
}

- (IBAction)resumeClick:(id)sender {
    //恢复录音只需要再次调用record，AVAudioSession会帮助你记录上次录音位置并追加录音
    [self recordClick:sender];
}

- (IBAction)stop:(id)sender {
    [self.audioRecorder stop];
    self.timer.fireDate = [NSDate distantFuture];
    self.audioPower.progress = 0.0;
}



@end
