//
//  ViewController.h
//  Blue_teeth
//
//  Created by yaoln on 2017/5/16.
//  Copyright © 2017年 zhangze. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController
+ (NSString*)byteToString:(NSData*)data;
+ (NSData*)stringToByte:(NSString*)string;

@end

