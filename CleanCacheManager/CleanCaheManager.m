//
//  CleanCaheManager.m
//  CleanCacheManager
//
//  Created by Mac on 2016/11/25.
//  Copyright © 2016年 REDEME. All rights reserved.
//

#import "CleanCaheManager.h"

@implementation CleanCaheManager
+(instancetype)shareManager
{
    static CleanCaheManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CleanCaheManager alloc]init];
    });
    
    return manager;
}
#pragma 计算缓存文件的大小
- (CGFloat)fileSizeAtPath:(NSString*)path
{
    if ([kFileManager fileExistsAtPath:path]) {
        float size = [kFileManager attributesOfItemAtPath:path error:NULL].fileSize;
        return size / 1024.0 / 1024.0;
    }
    return 0;
}
- (CGFloat)cacheSize
{
    /* 先将属性 cacheSize 的大小置为0,这样每次计算的文件夹大小的时候就不会重复累加 */
    self.cacheSize = 0;
    NSDirectoryEnumerator *enumrator = [kFileManager enumeratorAtPath:kCachePath];
    __weak typeof(self)weakSelf = self;
    /* 遍历 cache 文件夹路径中的子路径,然后计算每单个文件的大小,累加后返回 */
    [enumrator.allObjects enumerateObjectsUsingBlock:^(NSString *subPath, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = [kCachePath stringByAppendingPathComponent:subPath];
        weakSelf.cacheSize += [self fileSizeAtPath:path];
    }];
    return self.cacheSize;
}
#pragma mark - 计算其他文件夹的大小
/* 方法同计算 cache 文件夹大小 */
- (CGFloat)yf_folderSizeAtPath:(NSString *)path {
    CGFloat folderSize = 0;
    __block CGFloat blockFolderSize = folderSize;
    if ([kFileManager fileExistsAtPath:path]) {
        NSDirectoryEnumerator *enumerator = [kFileManager enumeratorAtPath:path];
        [enumerator.allObjects enumerateObjectsUsingBlock:^(NSString *subPath, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *absolutePath = [path stringByAppendingPathComponent:subPath];
            blockFolderSize += [self fileSizeAtPath:absolutePath];
        }];
        return folderSize;
    }
    return 0;
}

#pragma mark - 清除缓存文件
- (void)yf_wipeCacheAction {
    /* 清除缓存文件是一个耗时操作, 我们开启一个异步操作 */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        /* 在这个 block 中, 方法跟计算 cache 文件夹的大小一样, 只不过最后是清除文件 */
        NSDirectoryEnumerator *enumerator = [kFileManager enumeratorAtPath:kCachePath];
        [enumerator.allObjects enumerateObjectsUsingBlock:^(NSString *subPath, NSUInteger idx, BOOL * _Nonnull stop) {
            /* 错误处理 */
            NSError *error = nil;
            NSString *path = [kCachePath stringByAppendingPathComponent:subPath];
            if ([kFileManager fileExistsAtPath:path]) {
                [kFileManager removeItemAtPath:path error:&error];
                if (error) {
                    NSLog(@"文件删除失败");
                }else {
                    NSLog(@"文件删除成功");
                }
            }
        }];
    });
}

#pragma mark - 最后暴露一个类方法, 只要调用这个,自动弹出清除缓存提示框, 需要同 MBProgressHud 配合使用

+ (void)yf_wipeCacheWithDefaultStyle {
    MBProgressHUD *hud = [MBProgressHUD showHudTo:kTopStackController.view image:nil text:@"正在计算缓存大小" animated:YES];
    /* 由于计算缓存大小也是一个耗时操作. 我们做一个延时. 来确保获取到数据 */
    __weak typeof(self)weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIAlertController *alterVC = [UIAlertController alertControllerWithTitle:@"清除缓存" message:[NSString stringWithFormat:@"APP当前的缓存为:%.2fM",[[weakSelf shareManager] cacheSize]] preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [kTopStackController dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[weakSelf shareManager] yf_wipeCacheAction];
            MBProgressHUD *clearHud = [MBProgressHUD showHudTo:kTopStackController.view image:nil text:@"清除成功" animated: YES];
            clearHud.mode = MBProgressHUDModeText;
            [clearHud hide:YES afterDelay:2.0];
        }];
        [alterVC addAction:cancelAction];
        [alterVC addAction:confirmAction];
        [kTopStackController presentViewController:alterVC animated:YES completion:nil];
    });
    [hud hide:YES afterDelay:1.0];
}

@end
