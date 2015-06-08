//
//  QRScanViewController.m
//  TripMan
//
//  Created by taq on 6/3/15.
//  Copyright (c) 2015 Location. All rights reserved.
//

#import "QRScanViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface QRScanViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *                session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *      previewLayer;

@end

@implementation QRScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"车票扫码";
    
    if ([self avInit]) {
        [self.session startRunning];
    }
}

- (BOOL)avInit
{
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    if (input) {
        AVCaptureMetadataOutput * output = [AVCaptureMetadataOutput new];
        [output setMetadataObjectsDelegate:self queue:dispatch_queue_create("QRCodeQueue", DISPATCH_QUEUE_SERIAL)];
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
        
        AVCaptureSession * session = [AVCaptureSession new];
        [session addInput:input];
        [session addOutput:output];
        
        AVCaptureVideoPreviewLayer * previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        previewLayer.frame = self.backView.bounds;
        [self.backView.layer addSublayer:previewLayer];
        self.previewLayer = previewLayer;
        
        self.session = session;
        
        return YES;
    }
    
    return NO;
}

- (void)dealloc {
    [self.session stopRunning];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject * obj = metadataObjects[0];
        if ([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]] && [obj.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"qrcode = %@", obj.stringValue);
                [self.session stopRunning];
            });
        }
    }
}

@end
