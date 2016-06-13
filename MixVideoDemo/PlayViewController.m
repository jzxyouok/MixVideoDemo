//
//  PlayViewController.m
//  MediaHandleDemo
//
//  Created by Shelin on 15/11/25.
//  Copyright © 2015年 GreatGate. All rights reserved.
//

#import "PlayViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <GPUImage.h>
#import <MBProgressHUD.h>
#import "FilterChooseView.h"

@interface PlayViewController ()
{
    MPMoviePlayerController *_moviePlayer;
    NSString * pathToMovie;
    GPUImageMovie * movieFile ;
    GPUImageFilter * pixellateFilter;
    GPUImageMovieWriter * movieWriter;
    GPUImageView *filterView;//预览层 view
}
@end

@implementation PlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString* videoName = @"MixedVideo.mov";
    
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:videoName];
//
//    _moviePlayer = [[MPMoviePlayerController alloc] init];
//    _moviePlayer.view.frame = CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+64, self.view.bounds.size.width, self.view.bounds.size.height/2);
//    _moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
//    _moviePlayer.controlStyle   =   MPMovieControlStyleEmbedded;
//    [self.view addSubview:_moviePlayer.view];
//    _moviePlayer.contentURL = [NSURL fileURLWithPath:exportPath];
//    [_moviePlayer play];
    
    //play video view
    filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x,self.view.bounds.origin.y+64, self.view.bounds.size.width, self.view.bounds.size.height/2)];
    filterView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:filterView];
    movieFile = [[GPUImageMovie alloc] initWithURL:[NSURL fileURLWithPath:exportPath]];
    //alloc fitler add fitler
    GPUImageFilter* fitler = [[GPUImageSepiaFilter alloc] init];
    [self setupFitler:fitler];
    
    //navgationRightitem saveitem to write video to phone ablum
    UIBarButtonItem *rightItem  =   [[UIBarButtonItem alloc]initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(fitlerBegain_click)];
    self.navigationItem.rightBarButtonItem  =   rightItem;
    
    
    FilterChooseView * chooseView = [[FilterChooseView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(filterView.frame), self.view.frame.size.width, 100)];
    chooseView.backback = ^(GPUImageFilter * filter){
        [self choose_callBack:filter];
    };
    [self.view addSubview:chooseView];
}

#pragma mark 选择滤镜
-(void)choose_callBack:(GPUImageFilter *)filter
{
    pixellateFilter = filter;
    [movieFile cancelProcessing];
    [movieFile removeAllTargets];
    [movieFile addTarget:pixellateFilter];
    [pixellateFilter addTarget:filterView];
    [movieFile startProcessing];
}
#pragma mark set fitler and movieFile
- (void)setupFitler:(GPUImageFilter*)fitler{
    pixellateFilter =   fitler;
    [movieFile cancelProcessing];
    [movieFile removeAllTargets];
    [movieFile addTarget:pixellateFilter];
    [pixellateFilter addTarget:filterView];
//    movieFile.playAtActualSpeed = YES;
    movieFile.shouldRepeat = YES;
    [movieFile startProcessing];
}


#pragma mark 开始合成视频
-(void)fitlerBegain_click
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *outPutPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"Movie.mov"];
        pathToMovie =   outPutPath;
        //混合后的视频输出路径
        NSURL *outPutUrl = [NSURL fileURLWithPath:outPutPath];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:outPutPath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:outPutPath error:nil];
        }

        AVURLAsset * asss = [AVURLAsset URLAssetWithURL:[movieFile url] options:nil];
        CGSize videoSize2 = asss.naturalSize;
        NSLog(@"%f    %f",videoSize2.width,videoSize2.height);
        
        movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:outPutUrl size:videoSize2];
        [pixellateFilter addTarget:movieWriter];
        
        movieWriter.shouldPassthroughAudio = YES;
//        movieWriter.hasAudioTrack   =   YES;
//        movieFile.audioEncodingTarget = movieWriter;
        [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
        [movieWriter startRecording];
        
        __weak PlayViewController * weakSelf = self;
        __weak GPUImageOutput<GPUImageInput> * weakpixellateFilter = pixellateFilter;
        __weak GPUImageMovieWriter * weakmovieWriter = movieWriter;
        __weak NSURL    *waakOutputurl  =   outPutUrl;
        [movieWriter setCompletionBlock:^{
            NSLog(@"视频合成结束");
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
                [weakSelf writeVideoToPhotoLibrary:waakOutputurl];
                
            });
            [weakpixellateFilter removeTarget:weakmovieWriter];
            [weakmovieWriter finishRecording];
        }];
        
    });
}
-(void)writeVideoToPhotoLibrary:(NSURL*)url{
    
    ALAssetsLibrary *libary =   [[ALAssetsLibrary alloc]init];
    
    [libary writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetUrl,NSError *error){
        if (error) {
            NSLog(@"error=%@",error);
            
        }else{
            
            NSLog(@"保存视频到相册成功");
        }
    }];
    
}




@end
