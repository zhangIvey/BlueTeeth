//
//  ViewController.m
//  Blue_teeth
//
//  Created by yaoln on 2017/5/16.
//  Copyright © 2017年 zhangze. All rights reserved.
//

#import "ViewController.h"


@interface ViewController () <CBCentralManagerDelegate,CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) CBCentralManager *centralManager;
@property(nonatomic, strong) CBPeripheral *peripheral;

@property(nonatomic, strong) NSMutableArray *deviceArray;

@property(nonatomic, strong) UITableView *tableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _deviceArray = [[NSMutableArray alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    _tableView.backgroundView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    // Do any additional setup after loading the view, typically from a nib.
    dispatch_queue_t queue = dispatch_queue_create("blueTeethQueue", DISPATCH_QUEUE_CONCURRENT); //创建一个并行队列；
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey,@"zStrapRestoreIdentifier",CBCentralManagerOptionRestoreIdentifierKey ,nil];
    
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil]; //先使用主队列进行开发
    /*
    CBCentralManagerOptionShowPowerAlertKey
    布尔值，表示的是在central manager初始化时，如果当前蓝牙没打开，是否弹出alert框。
    CBCentralManagerOptionRestoreIdentifierKey
    CBCentralManagerOptionRestoreIdentifierKey，字符串，一个唯一的标示符，用来蓝牙的恢复连接的。在后台的长连接中可能会用到。
    就是说，如果蓝牙程序进入后台，程序会被挂起，可能由于memory pressure，程序被系统kill了，那么代理方法就不会执行了。这时候可以使用State Preservation & Restoration，这样程序会重新加载进入后台。
    调试iOS蓝牙的时候，可以下个LightBlue，非常方便，网上也有仿写LightBlue的Demo，参考这两处：
https://github.com/chenee/DarkBlue
http://boxertan.github.io/blog/2014/07/07/xue-xi-ioslan-ya-ji-zhu-%2Cfang-xie-lightblue/
    使用scanForPeripheralsWithServices:options: 来扫描外设
     */
    
}
\

#pragma mark - tableView's delegate method 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentify = @"cellForDevice";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    CBPeripheral *peripheral = (CBPeripheral *)[_deviceArray objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    NSLog(@"peripheral.name = %@",peripheral.name);
    NSLog(@"peripheral.identifier = %@",peripheral.identifier);
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [_centralManager stopScan];
    CBPeripheral *peripheral = (CBPeripheral *)[_deviceArray objectAtIndex:indexPath.row];
    peripheral.delegate = self;
    //进行链接
    [_centralManager connectPeripheral:peripheral options:nil];
}

#pragma mark - centralManager's delegate method

//中心蓝牙控制前的状态监听方法
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"设备开启状态 -- 可用状态");
        
        //开始进行扫描
        NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
       // CBCentralManagerScanOptionAllowDuplicatesKey，bool值，为NO，表示不会重复扫描已经发现的设备。
        
        [central scanForPeripheralsWithServices:nil options:option];
    }else if (central.state == CBCentralManagerStatePoweredOff){
        NSLog(@"关闭状态");
    }else if (central.state == CBCentralManagerStateUnknown){
        NSLog(@"无法识别,初始的时候是未知的（刚刚创建的时候）");
    }else if (central.state == CBCentralManagerStateResetting){
        NSLog(@"正在重置状态");
    }else if (central.state == CBCentralManagerStateUnsupported){
        NSLog(@"不支持");
    }else if (central.state == CBCentralManagerStateUnauthorized){
        NSLog(@"未授权");
    }
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"发现外部设备");
    NSLog(@"接收到的广播信息：%@",advertisementData);
    NSLog(@"打印设备信息：设备名称：%@ 信号强度：%@",peripheral.name, RSSI);
    _peripheral = peripheral;
    _peripheral.delegate = self;
    
    [_deviceArray addObject:_peripheral];
    [_tableView beginUpdates];
     [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [_tableView endUpdates];


//    [central stopScan];
    //发起链接
//    NSLog(@"发起链接");
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:CBConnectPeripheralOptionNotifyOnConnectionKey,YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey,YES,nil];
    
//    [central connectPeripheral:peripheral options:nil];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"和外设链接成功");
//    CBUUID *uuid = [CBUUID UUIDWithString:<#(nonnull NSString *)#>]
//    
//    [_peripheral discoverCharacteristics:<#(nullable NSArray<CBUUID *> *)#> forService:<#(nonnull CBService *)#>]
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"和外设链接失败");
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error
{
    NSLog(@"和外设断开连接");
}

#pragma mark - CBPeripheral's delegate

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral
{
    NSLog(@"");
}


- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices
{

}


- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error
{

}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{

}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"发现外设的特征");
    
//    NSLog(@"======打印外设的特征：characteristic = %@",)
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{

}



@end
