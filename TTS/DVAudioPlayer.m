#import "DVAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation DVAudioPlayer {
    AVAudioEngine *_engine;
    AVAudioPlayerNode *_node;
    AVAudioFormat *_format;
    BOOL _started;
}

- (instancetype)initWithSampleRate:(double)rate {
    if ((self = [super init])) {
        @try {
            double sr = (rate > 0) ? rate : 24000.0;
            _format = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatFloat32
                                                       sampleRate:sr
                                                         channels:1
                                                      interleaved:NO];
            if (!_format) {
                NSLog(@"[豆包语音] AVAudioFormat 创建失败 sr=%.0f", sr);
                return nil;
            }
            _engine = [AVAudioEngine new];
            _node = [AVAudioPlayerNode new];
            [_engine attachNode:_node];
            [_engine connect:_node to:_engine.mainMixerNode format:_format];
            NSLog(@"[豆包语音] 音频管道建好 sr=%.0f fmt=%@", sr, _format);
        } @catch (NSException *e) {
            NSLog(@"[豆包语音] 音频管道异常: %@", e.reason);
            return nil;
        }
    }
    return self;
}

- (void)start {
    if (_started) return;
    _started = YES;

    @try {
        NSError *err = nil;
        AVAudioSession *as = [AVAudioSession sharedInstance];
        [as setCategory:AVAudioSessionCategoryPlayback
            withOptions:AVAudioSessionCategoryOptionDuckOthers
                  error:&err];
        if (err) NSLog(@"[豆包语音] setCategory: %@", err);

        err = nil;
        BOOL ok = [as setActive:YES error:&err];
        NSLog(@"[豆包语音] setActive=%d err=%@", ok, err);

        err = nil;
        ok = [_engine startAndReturnError:&err];
        if (!ok) {
            NSLog(@"[豆包语音] engine start 失败: %@，重试", err);
            [as setActive:NO
                withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                      error:nil];
            [as setActive:YES error:nil];
            err = nil;
            ok = [_engine startAndReturnError:&err];
            NSLog(@"[豆包语音] 重试 start=%d err=%@", ok, err);
        }
        [_node play];
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] start 异常: %@", e.reason);
    }
}

- (void)appendPCM:(NSData *)pcm {
    if (pcm.length < 2 || !_format) return;

    NSUInteger frames = pcm.length / 2;
    if (frames == 0) return;

    AVAudioPCMBuffer *buf = [[AVAudioPCMBuffer alloc] initWithPCMFormat:_format
                                                         frameCapacity:(AVAudioFrameCount)frames];
    if (!buf || !buf.floatChannelData) return;
    buf.frameLength = (AVAudioFrameCount)frames;

    const int16_t *src = (const int16_t *)pcm.bytes;
    float *dst = buf.floatChannelData[0];
    for (NSUInteger i = 0; i < frames; i++) {
        dst[i] = (float)src[i] / 32768.0f;
    }

    @try {
        [_node scheduleBuffer:buf completionHandler:nil];
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] schedule 异常: %@", e.reason);
    }
}

- (void)finish {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self && self.onDrained) self.onDrained();
    });
}

- (void)stop {
    _started = NO;
    @try {
        [_node stop];
        [_engine stop];
        [[AVAudioSession sharedInstance] setActive:NO
            withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation
                  error:nil];
    } @catch (NSException *e) {
        NSLog(@"[豆包语音] stop 异常: %@", e.reason);
    }
}

@end
