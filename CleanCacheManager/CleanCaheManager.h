//
//  CleanCaheManager.h
//  CleanCacheManager
//
//  Created by Mac on 2016/11/25.
//  Copyright © 2016年 REDEME. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define kFileManager [NSFileManager defaultManager]
#define kCachePath NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
#define kTopStackController [UIApplication sharedApplication].keyWindow.rootViewController
@interface CleanCaheManager : NSObject

/**
 缓存文件的大小
 */
@property (nonatomic,assign)CGFloat cacheSize;

/**
 清楚缓存的单利

 @return 返回的是清除缓存的单利
 */
+(instancetype)shareManager;

/**
 一键清除缓存
 */
+(void)CleanCacheWithDefualt;

/**
 计算文件的大小

 @param Path 文件的路劲
 @return 文件的大小 返回的已经转换为MB单位
 */
-(CGFloat)fileSizeAtPath:(NSString*)Path;
@end
