//
//  ViewController.m
//  demo004
//
//  Created by 张凯 on 2020/2/28.
//  Copyright © 2020 张凯. All rights reserved.
//

#import "ViewController.h"
#import <NIMSDK/NIMSDK.h>
#import <NIMAVChat/NIMAVChat.h>

#import <ReplayKit/ReplayKit.h>
#import "NTESI420Frame.h"
#import "NTESTPCircularBuffer.h"
#import "NTESYUVConverter.h"
#import "GCDAsyncSocket.h"
#import "NTESSocketPacket.h"
#import "NTESTPCircularBuffer.h"
#import "NTESGLView.h"


@interface ViewController ()<NIMNetCallManagerDelegate,NIMLoginManagerDelegate>
//@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, assign) NSUInteger frameCount;
//@property (nonatomic, assign) CGFloat cropRate;
//@property (nonatomic, assign) CGSize  targetSize;
//@property (nonatomic, assign) NTESVideoPackOrientation orientation;
@property (weak, nonatomic) IBOutlet UITextField *roomIdField;

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, copy) NSString *compressVideoPath;
@property (nonatomic, strong)AVAssetWriter *assetWriter;
@property (nonatomic, strong)AVAssetWriterInput *assetWriterInput;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    [[[NIMSDK sharedSDK] loginManager] addDelegate:self];
    
}

#pragma mark -  ***********登陆***********
- (IBAction)joinMetting:(UIButton *)sender {
    
    
    [[[NIMSDK sharedSDK] loginManager] login:@"test1" token:@"1501133a1a6d70d08a8e484a7fd2328d" completion:^(NSError * _Nullable error) {
        
        if (!error) NSLog(@"......登陆成功了......");
    }];


}
- (IBAction)loginOut:(UIButton *)sender {
    
    [[[NIMSDK sharedSDK] loginManager] logout:^(NSError * _Nullable error) {
        
        if (!error) NSLog(@".....退出成功了......");
    }];
    
}

#pragma mark -  ***********登陆代理***********
- (void)onLogin:(NIMLoginStep)step{
    
    NSString *string;
    if (step == NIMLoginStepLinking) {
        string = @"连接服务器";
    }else if (step == NIMLoginStepLinkOK){
        string = @"连接服务器成功";
    }else if (step == NIMLoginStepLinkFailed){
        string = @"连接服务器失败";
    }else if (step == NIMLoginStepLogining){
        string = @"登录";
    }else if (step == NIMLoginStepLoginOK){
        string = @"登录成功";
    }else if (step == NIMLoginStepLoginFailed){
        string = @"登录失败";
    }else if (step == NIMLoginStepSyncing){
        string = @"开始同步";
    }else if (step == NIMLoginStepSyncOK){
        string = @"同步完成";
    }else if (step == NIMLoginStepLoseConnection){
        string = @"连接断开";
    }else {
        string = @"网络切换";
    }
    
    NSLog(@"******%@********",string);
}

#pragma mark -  ***********发起通话***********
- (IBAction)call:(id)sender {
    [[[NIMSDK sharedSDK] loginManager] login:@"ydaj1" token:@"3ccd02e6865105c1d0f9f034916f7d75" completion:^(NSError * _Nullable error) {
      
         if (!error) NSLog(@"...登陆成功并开始网络通话....");
        
        NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
        option.extendMessage = @"音视频请求扩展信息";
        option.apnsContent = @"通话请求";
        option.apnsSound = @"video_chat_tip_receiver.aac";

        //指定 option 中的 videoCaptureParam 参数
        NIMNetCallVideoCaptureParam *param = [[NIMNetCallVideoCaptureParam alloc] init];
        //清晰度480P
        param.preferredVideoQuality = NIMNetCallVideoQuality480pLevel;
        //裁剪类型 16:9
        param.videoCrop  = NIMNetCallVideoCrop16x9;
        //打开初始为前置摄像头
        param.startWithBackCamera = NO;
        param.startWithCameraOn = NO;


        //若需要开启前处理指定 videoProcessorParam
        NIMNetCallVideoProcessorParam *videoProcessorParam = [[NIMNetCallVideoProcessorParam alloc] init];
        //若需要通话开始时就带有前处理效果（如美颜自然模式）
        videoProcessorParam.filterType = NIMNetCallFilterTypeZiran;
        param.videoProcessorParam = videoProcessorParam;
        option.videoCaptureParam = param;
       
        
        //开始通话
        [[NIMAVChatSDK sharedSDK].netCallManager start:@[@"test1"] type:NIMNetCallMediaTypeVideo option:option completion:^(NSError *error, UInt64 callID) {
              NSLog(@"通话是否错误%@",error);
    }];
    
    }];
}


#pragma mark -  被叫方收到呼叫
- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallMediaType)type message:(NSString *)extendMessage {

         NSLog(@"....收到呼叫通知....");

        
         NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
        
         option.videoCaptureParam = nil;
          // 创建自定义采集
         option.customVideoParam = [[NIMNetCallCustomVideoParam alloc] init];
         option.customVideoParam.videoFrameRate = 15;
         [[NIMAVChatSDK sharedSDK].netCallManager startCustomVideo:option.customVideoParam];
    
        //被叫响应通话
        [[NIMAVChatSDK sharedSDK].netCallManager response:callID accept:YES option: option completion:^(NSError *error, UInt64 callID) {
             //链接成功
            
            if (!error) NSLog(@".....接听成功了.....");
            
            if (@available(iOS 11.0, *)) {
                
                [[RPScreenRecorder sharedRecorder] startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
                    
                    
                    [self sendVideoBufferToHostApp:sampleBuffer];
                    
                } completionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"录制错误:%@",error);
                    } else {
                        NSLog(@"....录制屏幕中....");
                    }
                }];
            } else {
                // Fallback on earlier versions
            }
            
            
        }];
        
    
}


#pragma mark - *********远端渲染**********
- (void)onRemoteDisplayviewReady:(UIView *)displayView user:(NSString *)user{
    NSLog(@"远端渲染就绪");
    [self.view addSubview:displayView];
    displayView.frame =CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 240);
}
- (void)onRemoteYUVReady:(NSData *)yuvData width:(NSUInteger)width height:(NSUInteger)height from:(NSString *)user{
    NTESGLView *vie = [[NTESGLView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 240)];
    [self.view addSubview:vie];
    [vie render:yuvData width:width height:height];
    NSLog(@"远端渲染就绪");
}

- (void)sendVideoBufferToHostApp:(CMSampleBufferRef)sampleBuffer {
    CFRetain(sampleBuffer);

    if (self.frameCount > 1000)
    {
        CFRelease(sampleBuffer);
        return;
    }
    self.frameCount ++ ;
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // To data
    NTESI420Frame *videoFrame = nil;
    videoFrame = [NTESYUVConverter pixelBufferToI420:pixelBuffer
                                            withCrop:9.0/16
                                          targetSize:CGSizeMake(540, 960)
                                      andOrientation:NTESVideoPackOrientationPortrait];
    CFRelease(sampleBuffer);

    // To Host App
    if (videoFrame){
       
        CMSampleBufferRef sampleBuff = [videoFrame convertToSampleBuffer];
        // SDK自定义视频数据发送接口
        NSError *err =  [[NIMAVChatSDK sharedSDK].netCallManager sendVideoSampleBuffer:sampleBuff];
        NSLog(@"发送录屏的错误%@",err);

        CFRelease(sampleBuff);

    }
    self.frameCount --;

}
    
@end
