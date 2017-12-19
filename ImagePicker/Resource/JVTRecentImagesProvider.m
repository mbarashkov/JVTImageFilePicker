//
//  JVTRecentImagesProvider.m
//  ImagePicker
//
//  Created by Matan Cohen on 4/5/16.
//  Copyright © 2016 Matan Cohen. All rights reserved.
//

#import "JVTRecentImagesProvider.h"
@import Photos;
@import AssetsLibrary;
#import "JVTCameraAccesebility.h"

static NSInteger maxResults = 30;

@implementation JVTRecentImagesProvider

+ (void)getRecentImagesWithSize:(CGSize) size return:(void (^)(NSArray<UIImage *> *images))callback {
    [JVTCameraAccesebility getPhotoRollAccessibilityAndRequestIfNeeded:^(BOOL allowedToUseCamera) {
        if (!allowedToUseCamera) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil);
            });
        }
        /*PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        
        [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop){
            
        }];*/
        
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        fetchOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];
        PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        
        if (allPhotosResult.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil);
            });
            return;
        }
        
        __block NSMutableArray *allImages = [NSMutableArray array];
        __block NSDate* current = [NSDate date];
        
        //   Get assets from the PHFetchResult object
        [allPhotosResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            /*options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                NSLog(@"%f", progress); //follow progress + update progress bar
            };*/
            __block int nilImageCount = 0;
            
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; //I only want the highest possible quality
            //options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; //I only want the highest possible quality
            options.synchronous = true;
            options.networkAccessAllowed = false;
            
            __block PHImageRequestID reqId = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                NSLog(@"image loaded");
                UIImage* image = [UIImage imageWithData:imageData];
                if(image != nil)
                {
                    [allImages addObject:image];
                    nilImageCount++;
                }
                
                if (allImages.count + nilImageCount == allPhotosResult.count || allImages.count >= maxResults) {
                    *stop = YES;
                    [[PHImageManager defaultManager] cancelImageRequest:reqId];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSTimeInterval elapsed = [current timeIntervalSinceNow];
                        callback(allImages);
                    });
                }
            }];
            
            
            /*__block PHImageRequestID reqId = [[PHImageManager defaultManager] requestImageForAsset:asset
                                                                                        targetSize:size
                                                                                       contentMode:PHImageContentModeAspectFill
                                                                                           options:options
                                                                                     resultHandler:^(UIImage *image, NSDictionary *info) {
                                                                                         if(image != nil)
                                                                                         {
                                                                                             [allImages addObject:image];
                                                                                             nilImageCount++;
                                                                                         }
                                                                                         
                                                                                         if (allImages.count + nilImageCount == allPhotosResult.count || allImages.count >= maxResults) {
                                                                                             *stop = YES;
                                                                                             [[PHImageManager defaultManager] cancelImageRequest:reqId];
                                                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                 NSTimeInterval elapsed = [current timeIntervalSinceNow];
                                                                                                 callback(allImages);
                                                                                             });
                                                                                         }
                                                                                     }];*/
        }];
    }];
}

@end
