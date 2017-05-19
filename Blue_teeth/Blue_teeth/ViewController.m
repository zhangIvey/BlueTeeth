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

#define WholeHeight [UIScreen mainScreen].bounds.size.height
#define WholeWidth [UIScreen mainScreen].bounds.size.width

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _deviceArray = [[NSMutableArray alloc] init];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.frame];
    _tableView.backgroundView.backgroundColor = [UIColor whiteColor];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];

    

    UIButton *scanButton = [[UIButton alloc] initWithFrame:CGRectMake(10, WholeHeight - 60, 100, 40)];
    [scanButton setTitle:@"点击扫描" forState:UIControlStateNormal];
    [scanButton setBackgroundColor:[UIColor blueColor]];
    [scanButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [scanButton addTarget:self action:@selector(doScan) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:scanButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(scanButton.frame.origin.x + scanButton.frame.size.width + 60, WholeHeight - 60, 100, 40)];
    [cancelButton setTitle:@"取消链接" forState:UIControlStateNormal];
    [cancelButton setBackgroundColor:[UIColor redColor]];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelConnection) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cancelButton];
    
    
    // Do any additional setup after loading the view, typically from a nib.
//    dispatch_queue_t queue = dispatch_queue_create("blueTeethQueue", DISPATCH_QUEUE_CONCURRENT); //创建一个并行队列；
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],CBCentralManagerOptionShowPowerAlertKey,@"zStrapRestoreIdentifier",CBCentralManagerOptionRestoreIdentifierKey ,nil];
    
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
    
    //创建一个中心蓝牙的管理器
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:nil]; //先使用主队列进行开发


}
- (void)doScan {
    NSLog(@"开始扫描蓝夜外设");
    if ([_centralManager isScanning]) {
        [_centralManager stopScan];
    }
    NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
    [_centralManager scanForPeripheralsWithServices:nil options:option];
}

- (void)cancelConnection {
    NSLog(@"断开已经建立的蓝牙连接");
   
    if ( [_centralManager isScanning]) {
        return;
    }
    if (_peripheral != nil) {
        [_centralManager cancelPeripheralConnection:_peripheral];
        _peripheral = nil;
    }
    
}

#pragma mark - tableView's delegate method 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentify = @"cellForDevice";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
    }
    NSDictionary *peripheralDic = (NSDictionary *)[_deviceArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = (CBPeripheral *)[peripheralDic objectForKey:@"peripheral"];
    cell.textLabel.text = peripheral.name;
    NSLog(@"peripheral.name = %@",peripheral.name);
    NSLog(@"RSSI = %@",[peripheralDic objectForKey:@"RSSI"]);
    NSLog(@"peripheral.identifier = %@",peripheral.identifier);
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _deviceArray.count;
}

//点击某个cell，进行外设的连接
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    NSDictionary *peripheralDic = (NSDictionary *)[_deviceArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = (CBPeripheral *)[peripheralDic objectForKey:@"peripheral"];
    
    //连接某个蓝牙外设
    [_centralManager connectPeripheral:peripheral options:nil];
    //设置蓝牙外设的代理；
    peripheral.delegate = self;
    //停止中心蓝牙的扫描动作
    [_centralManager stopScan];
}

#pragma mark - Str转NSData
+ (NSData*)stringToByte:(NSString*)string {
    NSString *hexString=[[string uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([hexString length]%2!=0) {
        return nil;
    }
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    return bytes;
}
#pragma mark - NSData转Str
+ (NSString*)byteToString:(NSData*)data {
    Byte *plainTextByte = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",plainTextByte[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}

#pragma mark - centralManager's delegate method

/*
 中心蓝牙控制前的状态监听方法。在中心蓝牙管理器创建完成之后，会调用该方法，进行对中心蓝牙状态的监听。每当蓝牙模块的状态发生改变时，该方法就会被调用和执行
 */

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        NSLog(@"设备开启状态 -- 可用状态");
        
        
        
        // CBCentralManagerScanOptionAllowDuplicatesKey，bool值，为NO，表示不会重复扫描已经发现的设备。
        NSDictionary *option = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO],CBCentralManagerScanOptionAllowDuplicatesKey, nil];
        
        //在确定蓝牙模块可用的情况下，开启进行扫描
        /*
         1：第一个参数：服务的CBUUID的数组，我们可以根据数组中的CBUUID检索某一类服务的蓝牙设备；
         2：第二个参数：
         */
        [central scanForPeripheralsWithServices:nil options:option];
        
    }else if (central.state == CBCentralManagerStatePoweredOff){
        NSLog(@"关闭状态");
    }else if (central.state == CBCentralManagerStateUnknown){
        NSLog(@"无法识别,初始的时候是未知的（刚刚创建的时候）");
    }else if (central.state == CBCentralManagerStateResetting){
        NSLog(@"正在重置状态");
    }else if (central.state == CBCentralManagerStateUnsupported){
        NSLog(@"SDK不支持");
    }else if (central.state == CBCentralManagerStateUnauthorized){
        NSLog(@"未授权");
    }
}

/*
 在中心蓝牙扫描到外设蓝牙后调用该方法。
 该方法每次只返回一个蓝牙外设的信息
 第一个参数：中心蓝牙对象
 第二个参数：本次扫描到的蓝牙外设
 第三个参数：蓝牙外设中的额外信息，——蓝牙外设的广播包中的信息。
 第四个参数：代表信号强度的参数，RSSI:（要做详细介绍）
 
 注意：扫描的蓝牙设备有以下几种情况：
 1：扫描的蓝牙是无用的蓝牙。
 2：扫描的蓝牙是重复扫描到的蓝牙。（存在一种可能就是重复扫描到的蓝牙有变化，这种变化不是指蓝牙外设携带的数据发生变化，是指蓝牙外设本身的参数发生变化）
 
 所有针对上述的两种情况，我们需要一段代码进行逻辑上的处理：
 1：剔除无用的蓝牙。
 2：替换到的旧信息蓝牙外设，插入新的蓝牙外设信息。
 */

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    /*
     思考：所有的蓝牙外设都必须要有 name 吗？
     */
    if (peripheral.name.length <= 0) {
        return;
    }
    
    //打印参数信息
    NSLog(@"发现外部设备");
    NSLog(@"接收到的广播信息：%@",advertisementData);
    NSLog(@"蓝牙外设信息：设备identifier ： %@ 设备名称：%@ 信号强度：%@", peripheral.identifier,peripheral.name, RSSI);
    
    
    if (_deviceArray.count <= 0) {
        
        NSDictionary *peripheralDic = [NSDictionary dictionaryWithObjectsAndKeys:peripheral,@"peripheral",RSSI,@"RSSI", nil];
        [_deviceArray addObject:peripheralDic];
        
    }else{
        bool isExist = NO;
        for (int i = 0; i < _deviceArray.count ; i ++) {
            NSDictionary *peripheralDic = [_deviceArray objectAtIndex:i];
            CBPeripheral *peripheralFromArray = [peripheralDic objectForKey:@"peripheral"];
            if ([peripheralFromArray.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
                isExist = YES;
                NSDictionary *newPeripheralDic = [NSDictionary dictionaryWithObjectsAndKeys:peripheral,@"peripheral",RSSI,@"RSSI", nil];
                [_deviceArray replaceObjectAtIndex:i withObject:newPeripheralDic];
            }
        }
        if (!isExist) {
            NSDictionary *newPeripheralDic = [NSDictionary dictionaryWithObjectsAndKeys:peripheral,@"peripheral",RSSI,@"RSSI", nil];
            [_deviceArray addObject:newPeripheralDic];
        }
        
    }
    
    [_tableView reloadData];
}

/**
 中心蓝牙和某个外设连接成功。
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"和外设链接成功");
    //设备连接成功，开始查找建立连接的蓝牙外设的服务；此处要注意，在建立连接之后，是通过蓝牙外设的对象去发现服务而非中心蓝牙。
    [peripheral discoverServices:nil];
}

/**
 中心蓝牙和某个外设连接失败。
 */
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

/**
 在发现服务时，进行调用
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error
{
    NSString *UUID = [peripheral.identifier UUIDString];
    NSLog(@"在didDiscoverServices方法中，peripheral.identifier = %@",UUID);
    
    //遍历所提供的服务
    for (CBService *service in peripheral.services) {
        CBUUID *serviceUUID = service.UUID;
        NSLog(@"serviceUUID = %@",[serviceUUID UUIDString]);
        
        
        /**
         如果我们知道要查询的特性的 CBUUID，可以在第一个参数中传入 CBUUID 的数组
         发现在服务下的特征
         */
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error
{

}

/**
 在发现服务中的特征后，调用该方法
 
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"在检索服务中的特征时出错");
        return;
    }
    
    NSLog(@"在 didDiscoverCharacteristicsForService 方法中遍历服务 %@ 中的特征",[service.UUID UUIDString]);
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        NSLog(@"特征 UUID = %@",[characteristic.UUID UUIDString]);
       
        /**
         在这里要注意，很多同学看到是枚举类型就是用的 == ，这是不对的，
         学习链接：http://lecason.com/2015/08/19/Objective-C-Find-Conbine/
         */
//#define BLUE_READ_UUID  @"1526" //蓝牙数据读取
//#define BLUE_WRITE_UUID @"1527" //蓝牙数据写入
//#define BLUE_CFGRD_UUID @"1528" //配置数据读取
//#define BLUE_CFGWR_UUID @"1529" //配置数据写入
        if (characteristic.properties & CBCharacteristicPropertyExtendedProperties) {
            NSLog(@"具备可拓展特性。");
        }
        if (characteristic.properties & CBCharacteristicPropertyRead) {
            NSLog(@"具备可读特性，即可以读取特征的 value 值");
            //对该特征进行读取
            [peripheral readValueForCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyWrite) {
            NSLog(@"具备可写特征，会有响应");
        
            NSString *stringD = @"要写入的数据";
            [peripheral writeValue:[ViewController stringToByte:stringD] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        }
        if (characteristic.properties & CBCharacteristicPropertyNotify) {
            NSLog(@"具备通知特性，无响应");
            //对该特征设置通知的监听
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            [peripheral readValueForCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyIndicate) {
            NSLog(@"具备指示特性");
        }
        if (characteristic.properties & CBCharacteristicPropertyBroadcast) {
            NSLog(@"具备广播特性");
            //对该特征设置通知的监听
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
            [peripheral readValueForCharacteristic:characteristic];
        }
        if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse) {
            NSLog(@"具备可写，又不会有响应的特性");
        }
    }
}


/**
 获取特征的值后调用的方法
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"didUpdateValueForCharacteristic : characteristic.uuid = %@",[characteristic.UUID UUIDString]);
    if (error) {
        NSLog(@"读取特征失败！");
    }
    NSData *data = characteristic.value;
    if (data.length <= 0) {
        return;
    }
    
    Byte *plainTextByte = (Byte *)[data bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",plainTextByte[i]&0xff];///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
//    NSString *info = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"hexStr = %@",hexStr);
}
/**
    在向蓝牙设备中写完指令后，调用的回调方法。
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error) {
        NSLog(@"didWriteValueForCharacteristic，在写入指令时发生错误");
        return;
    }
    NSLog(@"对蓝牙的指令写入成功！");
}

/**
 在对具备通知特性的特征设置监听之后，当特征有变化，接收到通知，执行下面方法。
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"didUpdateNotificationStateForCharacteristic : characteristic.uuid = %@",[characteristic.UUID UUIDString]);
    if (error) {
        NSLog(@"在监听通知后发生错误");
        return;
    }
    [peripheral readValueForCharacteristic:characteristic];
//    if (characteristic.properties & CBCharacteristicPropertyRead) {
//        //如果该特征同时具备可读特性，我们可以直接对特征进行读取
//        [peripheral readValueForCharacteristic:characteristic];
//    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    NSLog(@"发现外设的特征");
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{

}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error
{

}



@end
