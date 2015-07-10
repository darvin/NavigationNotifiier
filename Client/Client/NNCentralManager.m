//
//  NNCentralManager.m
//  Client
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "NNCentralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIDevice.h>
#import "../../Shared/BLEIDs.h"

NS_ENUM(NSInteger, NNCentralManagerState) {
    NNCentralManagerStateIdle,
    NNCentralManagerStateDiscovery,
    NNCentralManagerStateConnection
};

@interface NNCentralManager ()  <CBCentralManagerDelegate, CBPeripheralDelegate>;
@end

@implementation NNCentralManager

{
    CBCentralManager *_manager;
    dispatch_queue_t _delegateQueue;
    enum NNCentralManagerState _state;
    
    CBPeripheral *_connectedPeripheral;
    
    
    NSMutableArray *_peripheralsForDiscovery;
    NSMutableDictionary *_pairedClientNamesForDiscovery;
    NSMutableDictionary *_serverNamesForDiscovery;
    
}

- (id) init {
    if (self = [super init]) {
        _delegateQueue = dispatch_queue_create("com.darvin.navigationNotifier.Client.DelegateDispatchQueue", DISPATCH_QUEUE_SERIAL);
        _state = NNCentralManagerStateIdle;
        _peripheralsForDiscovery = [[NSMutableArray alloc] init];
        _pairedClientNamesForDiscovery = [[NSMutableDictionary alloc] init];
        _serverNamesForDiscovery = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) connect {
    NSDictionary *options =@{CBCentralManagerOptionShowPowerAlertKey : @YES,
                             //fixme no backgrounding for now
//                             CBCentralManagerOptionRestoreIdentifierKey: @"NavigationNotifierClientCentral"
                             } ;
    _state = NNCentralManagerStateDiscovery;

    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];

}

- (void)disconnect {
    _state = NNCentralManagerStateIdle;
    _connectedPeripheral.delegate = nil;
    [_manager cancelPeripheralConnection:_connectedPeripheral];
    _manager.delegate = nil;
    _manager = nil;
    [self wasDisconnected];
    
}
- (void) unpair {
    [self disconnect];
    [self wasUnpaired];
}

- (void)estabilishConnectionWithEligiblePeripheral:(CBPeripheral *) peripheral {
    [_manager stopScan];
    _state = NNCentralManagerStateConnection;
    for (CBPeripheral *eachPeripheral in [_peripheralsForDiscovery copy]) {
        if (![eachPeripheral isEqual:peripheral]) {
            eachPeripheral.delegate = nil;
            [_manager cancelPeripheralConnection:eachPeripheral];
        }
        [_peripheralsForDiscovery removeObject:eachPeripheral];

    }
    _connectedPeripheral = peripheral;
    for (CBService *service in _connectedPeripheral.services) {
        if ([service.UUID isEqual:IND_NN_SERVICE_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
                    [peripheral writeValue:[[self localName] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
                }
            }
        }
    }
    NSString *serverName = _serverNamesForDiscovery[peripheral];
    [self setPairedRemoteName:serverName];
    [self wasConnectedToRemote:serverName];
}


- (void)checkPeripheralIsEligible:(CBPeripheral *) peripheral {
    NSString *pairedClientName = _pairedClientNamesForDiscovery[peripheral];
    NSString *serverName = _serverNamesForDiscovery[peripheral];
    if (pairedClientName==nil || serverName == nil) {
        //not fetched yet
        return;
    }
    
    if ([self pairedRemoteName]!=nil && ![[self pairedRemoteName] isEqual:serverName]) {
        //we are paired to other server
        return;
    }
    
    if (![pairedClientName isEqual:IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA] && ![pairedClientName isEqual:[self localName]]) {
        //they are paired to other client
        return;
    }
    //well, now we are good to go
    [self estabilishConnectionWithEligiblePeripheral:peripheral];
}

- (void)pairedClientNameReceived:(NSString *)pairedServerName forPeripheral:(CBPeripheral *)peripheral {
    [_pairedClientNamesForDiscovery setObject:pairedServerName forKey:peripheral];
    [self checkPeripheralIsEligible:peripheral];
}

- (void)serverNameReceived:(NSString *)serverName forPeripheral:(CBPeripheral *)peripheral {
    [_serverNamesForDiscovery setObject:serverName forKey:peripheral];
    [self checkPeripheralIsEligible:peripheral];

}


- (NSString *)localName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *serverName = [defaults stringForKey:@"clientName"];
    if (serverName==nil) {
        serverName = [NSString stringWithFormat:@"NavClient_%d", arc4random()%999]; //not so great, better randomazity would be prefered
        [defaults setObject:serverName forKey:@"clientName"];
    }
    return serverName;
    
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state==CBCentralManagerStatePoweredOn) {
        if (_state==NNCentralManagerStateDiscovery) {
            [central scanForPeripheralsWithServices:@[IND_NN_SERVICE_UUID] options:@{CBCentralManagerScanOptionSolicitedServiceUUIDsKey:
                                                                                         @[IND_NN_SERVICE_UUID, IND_ANCS_SV_UUID]}];
        }
    } else {
        _state = NNCentralManagerStateIdle;
    }
    
}
- (void)centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    
}
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    
}
- (void)centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals {
    
}
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    if (_state==NNCentralManagerStateDiscovery) {
        [_peripheralsForDiscovery addObject:peripheral];
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
    }
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    if (_state==NNCentralManagerStateDiscovery) {
        [peripheral discoverServices:@[IND_NN_SERVICE_UUID]];
    }
    
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@", peripheral);
    
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral NS_AVAILABLE(NA, 6_0) {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices NS_AVAILABLE(NA, 7_0) {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error NS_AVAILABLE(NA, 8_0) {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (_state==NNCentralManagerStateDiscovery) {
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:IND_NN_SERVICE_UUID]) {
                [peripheral discoverCharacteristics:@[IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID, IND_NN_SERVER_NAME_CHAR_UUID] forService:service];
                break;
            }
        }
       
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    if (_state==NNCentralManagerStateDiscovery) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ([characteristic.UUID isEqual:IND_NN_SERVER_NAME_CHAR_UUID]||[characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
                [peripheral readValueForCharacteristic:characteristic];
            }
        }
    }
    
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    if (_state==NNCentralManagerStateDiscovery) {
        if ([characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
            [self pairedClientNameReceived:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] forPeripheral:peripheral];
        } else  if ([characteristic.UUID isEqual:IND_NN_SERVER_NAME_CHAR_UUID]) {
            [self serverNameReceived:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] forPeripheral:peripheral];
        }

    }
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    
}



@end
