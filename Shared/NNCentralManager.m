//
//  NNCentralManager.m
//  Client
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "NNCentralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEIDs.h"

NS_ENUM(NSInteger, NNCentralManagerState) {
    NNCentralManagerStateIdle,
    NNCentralManagerStateDiscovery,
    NNCentralManagerStateConnection,
    NNCentralManagerStateDisconnecting
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
    NSMutableArray *_discoveredServices;
    
}

- (id) init {
    if (self = [super init]) {
        _delegateQueue = dispatch_queue_create("com.darvin.navigationNotifier.Client.DelegateDispatchQueue", DISPATCH_QUEUE_SERIAL);
        _state = NNCentralManagerStateIdle;
        _peripheralsForDiscovery = [[NSMutableArray alloc] init];
        _discoveredServices = [[NSMutableArray alloc] init];
        _pairedClientNamesForDiscovery = [[NSMutableDictionary alloc] init];
        _serverNamesForDiscovery = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) connect {
    if (_state!=NNCentralManagerStateIdle) {
        NSLog(@"Trying to connect not from idle, error");
        return;
    }
    NSDictionary *options =@{CBCentralManagerOptionShowPowerAlertKey : @YES,
                             //fixme no backgrounding for now
//                             CBCentralManagerOptionRestoreIdentifierKey: @"NavigationNotifierClientCentral"
                             } ;
    _state = NNCentralManagerStateDiscovery;

    _manager = [[CBCentralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];

}

- (void)disconnect {
    if (_connectedPeripheral!=nil) {

        _state = NNCentralManagerStateDisconnecting;
        CBCharacteristic *pairedClientCharacteristic = [self pairedClientNameCharacteristicForPeripheral:_connectedPeripheral];
        if (pairedClientCharacteristic!=nil)
            [_connectedPeripheral setNotifyValue:NO forCharacteristic:pairedClientCharacteristic];
    } else {
        _state = NNCentralManagerStateIdle;

    }
}
- (void) unpair {
    if (_connectedPeripheral!=nil) {
        CBCharacteristic *pairedClientCharacteristic = [self pairedClientNameCharacteristicForPeripheral:_connectedPeripheral];
        [_connectedPeripheral writeValue:[IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:pairedClientCharacteristic type:CBCharacteristicWriteWithResponse];
    }

    [self disconnect];
    [self wasUnpaired];
}

- (CBCharacteristic *)pairedClientNameCharacteristicForPeripheral:(CBPeripheral *)peripheral {
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:IND_NN_SERVICE_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
                    return characteristic;
                }
            }
        }
    }
    return nil;
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
    CBCharacteristic *pairedClientCharacteristic = [self pairedClientNameCharacteristicForPeripheral:_connectedPeripheral];
    [peripheral writeValue:[[self localName] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:pairedClientCharacteristic type:CBCharacteristicWriteWithResponse];
    [peripheral setNotifyValue:YES forCharacteristic:pairedClientCharacteristic];

    NSString *serverName = _serverNamesForDiscovery[peripheral];
    [self setPairedRemoteName:serverName];
    [self wasConnectedToRemote:serverName];
    
    [self subscribeANCS:peripheral];
}

- (void) subscribeANCS:(CBPeripheral *) peripheral {
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:IND_ANCS_SV_UUID]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([characteristic.UUID isEqual:IND_ANCS_NS_UUID]||[characteristic.UUID isEqual:IND_ANCS_DS_UUID]) {
                    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
                }
            }
        }
    }
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

- (void)discoveryPairedClientNameReceived:(NSString *)pairedClientName forPeripheral:(CBPeripheral *)peripheral {
    [_pairedClientNamesForDiscovery setObject:pairedClientName forKey:peripheral];
    [self checkPeripheralIsEligible:peripheral];
}

- (void)discoveryServerNameReceived:(NSString *)serverName forPeripheral:(CBPeripheral *)peripheral {
    [_serverNamesForDiscovery setObject:serverName forKey:peripheral];
    [self checkPeripheralIsEligible:peripheral];

}

- (void)connectionPairedClientNameReceived:(NSString *)pairedClientName {
    if (![pairedClientName isEqualToString:[self localName]]) {
        //server just unpaired us
        [self unpair];
    }
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
            [central scanForPeripheralsWithServices:@[IND_NN_SERVICE_UUID, IND_ANCS_SV_UUID] options:@{
                                                                  CBCentralManagerScanOptionSolicitedServiceUUIDsKey:
                                                                                         @[IND_NN_SERVICE_UUID, IND_ANCS_SV_UUID],
                                                                  CBCentralManagerScanOptionAllowDuplicatesKey: @NO}];
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
    NSLog(@"Discovered %@", peripheral);

    if (_state==NNCentralManagerStateDiscovery) {
        [_peripheralsForDiscovery addObject:peripheral];
        peripheral.delegate = self;
        [central connectPeripheral:peripheral options:nil];
    }
}
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    NSLog(@"Connected to %@", peripheral);
    if (_state==NNCentralManagerStateDiscovery) {
        [peripheral discoverServices:@[IND_NN_SERVICE_UUID, IND_ANCS_SV_UUID]];
    }
    
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@", peripheral);
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnected %@", peripheral);

    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
}

- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral NS_AVAILABLE(NA, 6_0) {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices NS_AVAILABLE(NA, 7_0) {
    
}
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error NS_AVAILABLE(NA, 8_0) {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@"Discovered services %@ : %@", peripheral, peripheral.services);

    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    if (_state==NNCentralManagerStateDiscovery) {
        for (CBService *service in peripheral.services) {
            if ([service.UUID isEqual:IND_NN_SERVICE_UUID]) {
                NSLog(@"Discovered NavNotify service");
                [peripheral discoverCharacteristics:@[IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID, IND_NN_SERVER_NAME_CHAR_UUID] forService:service];
                [_discoveredServices addObject:service];
            } else if ([service.UUID isEqual:IND_ANCS_SV_UUID]) {
                NSLog(@"Discovered Apple Notification Center service");
                [peripheral discoverCharacteristics:@[IND_ANCS_CP_UUID, IND_ANCS_DS_UUID, IND_ANCS_NS_UUID] forService:service];
                [_discoveredServices addObject:service];

            }
        }
       
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
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
            [self discoveryPairedClientNameReceived:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] forPeripheral:peripheral];
        } else  if ([characteristic.UUID isEqual:IND_NN_SERVER_NAME_CHAR_UUID]) {
            [self discoveryServerNameReceived:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] forPeripheral:peripheral];
        }

    } else if (_state==NNCentralManagerStateConnection) {
        if ([characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
            [self connectionPairedClientNameReceived:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]];
        }

    }

}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    if (_state==NNCentralManagerStateDisconnecting) {
        _state = NNCentralManagerStateIdle;
        _connectedPeripheral.delegate = nil;
        [_manager cancelPeripheralConnection:_connectedPeripheral];
        _connectedPeripheral = nil;

        _manager.delegate = nil;
        _manager = nil;
        [self wasDisconnected];

    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    
}
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    
}
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    
}



@end
