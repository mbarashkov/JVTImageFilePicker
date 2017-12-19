//
//  JVTRecentImagesCollectionViewCell.m
//  ImagePicker
//
//  Created by Matan Cohen on 4/5/16.
//  Copyright © 2016 Matan Cohen. All rights reserved.
//

#import "JVTRecentImagesCollectionViewCell.h"

@interface JVTRecentImagesCollectionViewCell ()
@end

@implementation JVTRecentImagesCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame))];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        self.imageView.clipsToBounds = YES;
        [self addSubview:self.imageView];
    }
    return self;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)setImage:(UIImage *)image {
    [self.imageView setImage:[self imageWithImage:image scaledToFillSize:self.imageView.bounds.size]];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
}

+ (NSString *)cellIdentifer {
    return NSStringFromClass([self class]);
}
@end
