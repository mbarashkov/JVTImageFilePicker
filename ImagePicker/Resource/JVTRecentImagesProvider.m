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
static NSString* photoCacheFolder = @"personalPhotosCache";
@implementation JVTRecentImagesProvider

+ (BOOL) clearCache
{
    NSURL *cacheURL = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask][0];
    cacheURL = [cacheURL URLByAppendingPathComponent:photoCacheFolder isDirectory:true];
    
    return [NSFileManager.defaultManager removeItemAtURL:cacheURL error: nil];
}

+ (void)getRecentImagesWithSize:(CGSize) size return:(void (^)(NSArray<NSData *> *images, NSString* report))callback {
    [JVTCameraAccesebility getPhotoRollAccessibilityAndRequestIfNeeded:^(BOOL allowedToUseCamera) {
        if (!allowedToUseCamera) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil, @"");
            });
        }
        //[self clearCache];
        PHFetchOptions *fetchOptions = [PHFetchOptions new];
        fetchOptions.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO] ];
        PHFetchResult *allPhotosResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        
        if (allPhotosResult.count == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(nil, @"");
            });
            return;
        }
        
        __block NSMutableArray<NSURL*> *allImages = [NSMutableArray<NSURL*> array];
        __block NSDate* current = [NSDate date];
        __block NSString* report = [NSString new];
        //__block int imageIndex = 0;
        NSURL *documentsURL = [NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask][0];
        documentsURL = [documentsURL URLByAppendingPathComponent:photoCacheFolder isDirectory:true];
        [NSFileManager.defaultManager createDirectoryAtPath:documentsURL.path withIntermediateDirectories:true attributes:nil error:nil];
        
        [allPhotosResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            __block int nilImageCount = 0;
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat; //I only want the highest possible quality
            options.synchronous = true;
            options.networkAccessAllowed = false;
            @autoreleasepool {
                __block PHImageRequestID reqId = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                if(imageData != nil) {
                    /*NSString* fileName = [NSString stringWithFormat:@"%i", imageIndex];
                    NSURL* imageURL = [documentsURL URLByAppendingPathComponent:fileName isDirectory:false];
                    [imageData writeToURL:imageURL atomically:true];*/
                    [allImages addObject:imageData];
                    //imageIndex ++;
                }
                else {
                    nilImageCount++;
                }
                
                if (allImages.count + nilImageCount >= allPhotosResult.count || idx + 1 >= MIN(maxResults * 5, allPhotosResult.count)) {
                    *stop = YES;
                    [[PHImageManager defaultManager] cancelImageRequest:reqId];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        callback(allImages, report);
                    });
                }
                }];
            }
        }];
    }];
}

@end
