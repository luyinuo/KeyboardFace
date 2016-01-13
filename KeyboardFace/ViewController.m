//
//  ViewController.m
//  KeyboardFace
//
//  Created by Maiziedu on 15/12/30.
//  Copyright (c) 2015年 com.lyn.TestTimer. All rights reserved.
//

#import "ViewController.h"
#import "DeviceInfo.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSMutableArray *discoverdPeriparals;
@property (nonatomic, strong) CBCharacteristic *characteristic;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (weak, nonatomic) IBOutlet UILabel *showLabel;

@end


@implementation ViewController
- (NSMutableArray *) discoverdPeriparals
{
    if (!_discoverdPeriparals) {
        _discoverdPeriparals = [NSMutableArray array];
    }
    return _discoverdPeriparals;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}
/*
 Invoked whenever the central manager's state is updated.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSString * state = nil;
    
    switch ([central state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            state = @"work";
            self.showLabel.text = @"服务开启成功";
            break;
        case CBCentralManagerStateUnknown:
        default:
            ;
    }
    
    NSLog(@"Central manager state: %@", state);
}
#pragma mark - action method
- (IBAction)scan:(UIButton *)sender {
    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
}
- (IBAction)connect:(UIButton *)sender {
    [self.centralManager connectPeripheral:[self.discoverdPeriparals firstObject]  options:nil];
}
- (IBAction)highLightLED:(id)sender {
//    unsigned char buffer[] = {0x06, 0x00, 0x05, 0x00, 0x00};
    char buffer[] = {0xAB,0x00,0x00,0x09,0x49,0x25,0x00,0x03,0x02, 0x00, 0x26, 0x00, 0x04, 0x4B, 0x32, 0x50, 0x00};
    NSData *data = [NSData dataWithBytes:&buffer length:17];
    [self.peripheral writeValue:data forCharacteristic:self.characteristic type:CBCharacteristicWriteWithResponse];
}

#pragma mark - central delegate
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSString *str = [NSString stringWithFormat:@"Did discover peripheral. peripheral: %@ rssi: %@, name: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.name, advertisementData];
    NSLog(@"%@",str);
    if([peripheral.name isEqualToString:@"du-Band"]){
        [self.discoverdPeriparals addObject:peripheral];
        self.showLabel.text = [NSString stringWithFormat:@"发现设备，设备名：%@",peripheral.name];
        
    }
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect to peripheral: %@", peripheral);
    peripheral.delegate = self;
    [central stopScan];
    [peripheral discoverServices:nil];
}

#pragma mark - peripheral delegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]);
        return;
    }
    
    for (CBService *service in peripheral.services)
    {
        NSLog(@"Service found with UUID: %@", service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"6E400001-B5A3-F393-E0A9-E50E24DCCA9E"]])
        {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    for (CBCharacteristic * characteristic in service.characteristics)
    {
        NSLog(@"characteristic - %@",characteristic);
        if( [characteristic.UUID isEqual:[CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"]])
        {
            self.peripheral = peripheral;
            self.characteristic = characteristic;
            self.showLabel.text = @"成功连接设备的服务特征";
            NSLog(@"Found a Device Manufacturer Name Characteristic - Read manufacturer name");
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
    }
    NSLog(@"%@",peripheral);
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@",error);
    }
    self.showLabel.text = @"点亮成功";
    NSLog(@"%@",peripheral);
}
/**
 service === <CBService: 0x15e597fd0, isPrimary = YES, UUID = 1804>
 service === <CBService: 0x15e515630, isPrimary = YES, UUID = Battery>
 service === <CBService: 0x15e597930, isPrimary = YES, UUID = 6E400001-B5A3-F393-E0A9-E50E24DCCA9E>
 service === <CBService: 0x15e508b70, isPrimary = YES, UUID = Device Information>
 
 characteristic - <CBCharacteristic: 0x15e656a00, UUID = 2A07, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e671860, UUID = Battery Level, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e502510, UUID = 6E400003-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0x10, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e51cad0, UUID = 6E400002-B5A3-F393-E0A9-E50E24DCCA9E, properties = 0x8, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e5166d0, UUID = Manufacturer Name String, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e51d3b0, UUID = Model Number String, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e5922d0, UUID = Serial Number String, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e5269f0, UUID = Hardware Revision String, properties = 0x2, value = (null), notifying = NO>
 characteristic - <CBCharacteristic: 0x15e50eb40, UUID = Firmware Revision String, properties = 0x2, value = (null), notifying = NO>
 */



@end