//
//  FilesPicker.m
//  ImagePickerMC
//
//  Created by Matan Cohen on 1/13/16.
//  Copyright © 2016 Matan Cohen. All rights reserved.
//

#import "JVTImageFilePicker.h"
#import "UIImagePickerController+Block.h"
#import "JVTWorker.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "JVTRecentImagesProvider.h"
#import "JVTRecetImagesCollection.h"
#import "EXTScope.h"
#import <AVFoundation/AVFoundation.h>
#import "JVTActionSheetAction.h"
#import "JVTActionSheetView.h"
#import "EXTScope.h"
#import "JVTCameraAccesebility.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#define DEFAULT_IMAGE_SIZE CGSizeMake(600, 600)

/*@implementation NonRotatingUIImagePickerController
// Disable Landscape mode.
- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationLandscapeLeft;
}

@end*/

@interface JVTImageFilePicker () <JVTRecetImagesCollectionDelegate, JVTActionSheetActionDelegate>
@property (nonatomic, strong) JVTActionSheetView *actionSheet;
@property (nonatomic, weak) UIViewController *presentedFromController;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) JVTRecetImagesCollection *recetImagesCollection;
@property (nonatomic, strong) UIView *backgroundDimmedView;
@end

@implementation JVTImageFilePicker

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isFilePickerEnabled = YES;
        self.isCameraEnabled = YES;
        self.backgroundDimmedView = [[UIView alloc] init];
        self.backgroundDimmedView.backgroundColor = [UIColor blackColor];
        self.imageResizeSize = DEFAULT_IMAGE_SIZE;
    }
    return self;
}

/*-(void)alertMessage:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}*/

- (void)presentFilesPickerOnController:(UIViewController *)presentFromController
  withAddingCustomActionsToActionSheet:(NSArray *)customAlertActions {
    //[self alertMessage:@"0"];
    if (self.actionSheet && [self.actionSheet isPresented]) {
        //[self alertMessage:@"1"];
        NSLog(@"Trying to present ImagePicker when already presented");
        return;
    }
    
    self.presentedFromController = presentFromController;
    //[self.presentedFromController.view endEditing:YES];

    //[self alertMessage:@"2"];

    [self addBackgroundDimmed];
    [self showBackgroundDimmed];
    
    //[self alertMessage:@"3"];

    NSString *photoLibraryTxt = @"Photo Library";
    NSString *takePhotoOrVideoTxt = @"Take Photo";
    NSString *uploadFileTxt = @"Upload File";
    NSString *cancelTxt = @"Cancel";
    self.actionSheet = [[JVTActionSheetView alloc] init];
    self.actionSheet.delegate = self;
    
    //[self alertMessage:@"4"];

    /*JVTActionSheetAction *uploadFile = [JVTActionSheetAction actionWithTitle:uploadFileTxt
                                                                  actionType:kActionType_default
                                                                     handler:^(JVTActionSheetAction *action) {
                                                                         [self uploadFilePress];
                                                                     }];*/
    
    JVTActionSheetAction *cancel = [JVTActionSheetAction actionWithTitle:cancelTxt
                                                              actionType:kActionType_cancel
                                                                 handler:^(JVTActionSheetAction *action) {
                                                                     [self dismissPresentedControllerAndInformDelegate:nil];
                                                                 }];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        JVTActionSheetAction *photoLibrary = [JVTActionSheetAction actionWithTitle:photoLibraryTxt
                                                                        actionType:kActionType_default
                                                                           handler:^(JVTActionSheetAction *action) {
                                                                               [self photoLibraryPress];
                                                                           }];
        [self.actionSheet addAction:photoLibrary];
    }
    /*if (self.isCameraEnabled && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        JVTActionSheetAction *takePhotoOrVideo = [JVTActionSheetAction actionWithTitle:takePhotoOrVideoTxt
                                                                            actionType:kActionType_default
                                                                               handler:^(JVTActionSheetAction *action) {
                                                                                   [self takePhotoOrVideoPress];
                                                                               }];
        [self.actionSheet addAction:takePhotoOrVideo];
    }*/
    
    //[self alertMessage:@"5"];

    /*if (self.isFilePickerEnabled) {
        [self.actionSheet addAction:uploadFile];
    }*/
    [self.actionSheet addAction:cancel];
    
    if (customAlertActions) {
        for (JVTActionSheetAction *alertAction in customAlertActions) {
            [self.actionSheet addAction:alertAction];
        }
    }
    
    //[self alertMessage:@"6"];
    
    [self addCollectionImagesPreviewToSheetAndPresent:self.actionSheet];
    
    //[self alertMessage:@"7"];
}

- (void)addCollectionImagesPreviewToSheetAndPresent:(JVTActionSheetView *)alertController {
    //[self alertMessage:@"a0"];
    __weak JVTImageFilePicker *weakSelf = self;
    [JVTRecentImagesProvider getRecentImagesWithSize:self.imageResizeSize return:^(NSArray<UIImage *> *images, NSString* report) {
        //[self alertMessage:@"a1"];

        if (images.count > 0) {
            //[self alertMessage:@"a2"];
            CGFloat width = self.presentedFromController.view.bounds.size.width;
            CGRect frame = CGRectMake(0, 0, width, 163.0F);
            //[self alertMessage:@"a3"];
            weakSelf.recetImagesCollection = [[JVTRecetImagesCollection alloc] initWithFrame:frame withImagesToDisplay:images];
            weakSelf.recetImagesCollection.delegate = self;
            weakSelf.recetImagesCollection.presentingViewController = self.presentedFromController;
            //[self alertMessage:@"a4"];
            [alertController addHeaderView:weakSelf.recetImagesCollection];
            //[self alertMessage:@"a5"];
            
            // From within your active view controller
            /*if([MFMailComposeViewController canSendMail]) {
                MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
                mailCont.mailComposeDelegate = self;
                
                [mailCont setSubject:@"debug timings"];
                [mailCont setToRecipients:[NSArray arrayWithObject:@"mbarashkov@gmail.com"]];
                [mailCont setMessageBody:report isHTML:NO];
                
                [self.presentedFromController presentModalViewController:mailCont animated:YES];
            }*/
        }
        //[self alertMessage:@"a6"];

        [weakSelf.actionSheet presentOnTopOfView:weakSelf.presentedFromController.view];
        //[self alertMessage:@"a7"];
    }];
}

- (void)presentFilesPickerOnController:(UIViewController *)presentFromController {
    [self presentFilesPickerOnController:presentFromController withAddingCustomActionsToActionSheet:nil];
}

#pragma mark - type of action presses

- (void)photoLibraryPress {
    __weak JVTImageFilePicker *weakSelf = self;
    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self.imagePickerController setModalPresentationStyle: UIModalPresentationOverCurrentContext];
    [self.presentedFromController presentViewController:self.imagePickerController animated:YES completion:nil];
    
    self.imagePickerController.finalizationBlock = ^(UIImagePickerController *picker, NSDictionary *info) {
        UIImage *image = (UIImage *)[info valueForKey:UIImagePickerControllerOriginalImage];
        [self didPressSendOnImage:image];
        //[weakSelf showPreviewForImage:image];
    };
    self.imagePickerController.cancellationBlock = ^(UIImagePickerController *picker) {
        [picker dismissViewControllerAnimated:YES
                                   completion:^{
                                   }];
    };
}

- (void)takePhotoOrVideoPress {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized || authStatus == AVAuthorizationStatusNotDetermined) {
        __weak JVTImageFilePicker *weakSelf = self;
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self.imagePickerController setModalPresentationStyle: UIModalPresentationOverCurrentContext];
        
        self.imagePickerController.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        self.imagePickerController.allowsEditing = NO;
        [self.presentedFromController presentViewController:self.imagePickerController animated:YES completion:nil];
        
        self.imagePickerController.finalizationBlock = ^(UIImagePickerController *picker, NSDictionary *info) {
            UIImage *image = (UIImage *)[info valueForKey:UIImagePickerControllerOriginalImage];
            
            [weakSelf didPressSendOnImage:image];
            
        };
        self.imagePickerController.cancellationBlock = ^(UIImagePickerController *picker) {
            [picker dismissViewControllerAnimated:YES
                                       completion:^{
                                       }];
        };
        
    } else if (authStatus == AVAuthorizationStatusDenied) {
        [self presentPermissionDenied];
    } else if (authStatus == AVAuthorizationStatusRestricted) {
        // restricted, normally won't happen
        [self presentPermissionDenied];
    }
}

- (void)uploadFilePress {
    UIDocumentMenuViewController *documentMenuViewController = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[ (__bridge NSString *)kUTTypeItem ] inMode:UIDocumentPickerModeImport];
    documentMenuViewController.delegate = self;
    
    [self.presentedFromController presentViewController:documentMenuViewController animated:YES completion:nil];
}

#pragma mark - documents picker

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [self.presentedFromController presentViewController:documentPicker
                                               animated:YES
                                             completion:^{
                                                 NSLog(@"Document menu dismissed");
                                             }];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    __weak JVTImageFilePicker *weakSelf = self;
    [[JVTWorker shared] addOperationWithBlock:^{
        NSLog(@"Document picker picked %@", url);
        NSData *file = [weakSelf fileFromFileURL:url];
        NSString *fileName = [url lastPathComponent];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([weakSelf isFileOfTypeImage:[url absoluteString]]) {
                UIImage *image = [UIImage imageWithData:file];
                if (!image) {
                    [weakSelf presentFileNotSupportedAlert];
                } else {
                    [weakSelf.delegate didPickImage:image withImageName:fileName];
                }
                
            } else {
                [weakSelf.delegate didPickFile:file fileName:fileName];
            }
            
        });
        
    }];
}

- (BOOL)isFileOfTypeImage:(NSString *)filePath {
    NSString *file = filePath;
    CFStringRef fileExtension = (__bridge CFStringRef)[file pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        CFRelease(fileUTI);
        return YES;
    } else {
        CFRelease(fileUTI);
        return NO;
    }
}

- (NSData *)fileFromFileURL:(NSURL *)fileURL {
    NSString *stringURL = [fileURL absoluteString];
    NSURL *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if (urlData) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *fileName = [NSString stringWithFormat:@"filename%@", [fileURL lastPathComponent]];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, fileName];
        [urlData writeToFile:filePath atomically:YES];
    }
    
    return urlData;
}

#pragma mark - delegate updates

- (void)dismissPresentedControllerAndInformDelegate:(UIViewController *)presentedController {
    [self updateDelegateOnDissmiss];
    [presentedController dismissViewControllerAnimated:YES
                                            completion:nil];//^(void) {
    //                                            [self updateDelegateOnDissmiss];
                                            //}];
}

- (void)updateDelegateOnDissmiss {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didDismissFilesPicker)]) {
        [self.delegate didDismissFilesPicker];
    }
}

#pragma mark - Action sheet delegate

- (void)actionSheetDidDismiss {
    [self hideBackgroundDimmed];
    [self.recetImagesCollection removeFromSuperview];
    self.recetImagesCollection = nil;
    self.presentedFromController = nil;
    self.recetImagesCollection = nil;
    self.actionSheet.delegate = nil;
    self.actionSheet = nil;
    
    NSLog(@"JVTImageFilesPicker dismissed");
}

#pragma mark - Alerts

- (void)presentFileNotSupportedAlert {
    __weak JVTImageFilePicker *weakSelf = self;
    NSString *title = @"Unable to Upload";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okBtn = [UIAlertAction actionWithTitle:@"Ok"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *_Nonnull action){
                                                  }];
    [alert addAction:okBtn];
    [self.presentedFromController presentViewController:alert
                                               animated:YES
                                             completion:^{
                                                 [weakSelf updateDelegateOnDissmiss];
                                             }];
}

- (void)presentPermissionDenied {
    __weak JVTImageFilePicker *weakSelf = self;
    NSString *title = @"Permission Denied";
    NSString *subtitle = @"App isn't allowed to access to the camera. You can change this from Settings > Privacy > Camera";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:subtitle preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okBtn = [UIAlertAction actionWithTitle:@"Ok"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction *_Nonnull action){
                                                  }];
    [alert addAction:okBtn];
    [self.presentedFromController presentViewController:alert
                                               animated:YES
                                             completion:^{
                                                 [weakSelf updateDelegateOnDissmiss];
                                             }];
}

#pragma mark - CollectionView picker delegat

- (void)didChooseImagesFromCollection:(UIImage *)image {
    [self.actionSheet dismiss];
    [self.delegate didPickImage:image withImageName:@"asset"];
}

#pragma mark - ImagePreview delegate

- (void)didPressSendOnImage:(UIImage *)image {
    [self.presentedFromController dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didPickImage:image withImageName:@"asset"];
    if (self.imagePickerController != nil) {
        [self.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - image preview

- (void)showPreviewForImage:(UIImage *)image {
    if (self.presentedFromController.presentedViewController) {
        self.presentedFromController = self.presentedFromController.presentedViewController;
    }
    JVTImagePreviewVC *imagePreviewViewController = [[JVTImagePreviewVC alloc] initWithImage:image];
    imagePreviewViewController.delegate = self;
    if (self.presentedFromController.navigationController) {
        [self.presentedFromController.navigationController pushViewController:imagePreviewViewController animated:YES];
    } else {
        [self.presentedFromController presentViewController:imagePreviewViewController animated:YES completion:nil];
    }
}

#pragma mark - Background dimmed view

- (void)addBackgroundDimmed {
    [self.backgroundDimmedView removeFromSuperview];
    [self.presentedFromController.view addSubview:self.backgroundDimmedView];
    self.backgroundDimmedView.frame = CGRectMake(0, 0, CGRectGetWidth(self.presentedFromController.view.frame), CGRectGetHeight(self.presentedFromController.view.frame));
    self.backgroundDimmedView.alpha = 0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnDimmedBackground)];
    [self.backgroundDimmedView addGestureRecognizer:tap];
}

- (void)didTapOnDimmedBackground {
    [self.actionSheet dismiss];
}

- (void)showBackgroundDimmed {
    [UIView animateWithDuration:0.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.backgroundDimmedView.alpha = 0.6;
                     }
                     completion:^(BOOL finished){
                     }];
}

- (void)hideBackgroundDimmed {
    __weak JVTImageFilePicker *weakSelf = self;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         weakSelf.backgroundDimmedView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [weakSelf.backgroundDimmedView removeFromSuperview];
                         weakSelf.backgroundDimmedView = nil;
                     }];
}
@end
