//
//  NNPeripheralManager.m
//  Server
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#import "NNPeripheralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIDevice.h>
#import "../../Shared/BLEIDs.h"

@interface NNPeripheralManager() <CBPeripheralManagerDelegate>
- (NSData *)pairedClientNameData;
- (NSData *)serverNameData;

@end

@implementation NNPeripheralManager {
    CBPeripheralManager *_manager;
    dispatch_queue_t _delegateQueue;
    CBPeripheralManagerState _state;
    CBMutableService *_service;

}

- (id) init {
    if (self = [super init]) {
        _delegateQueue = dispatch_queue_create("com.darvin.navigationNotifier.Server.DelegateDispatchQueue", DISPATCH_QUEUE_SERIAL);
        

    }
    return self;
}



- (void) unpair {
    [self wasUnpaired];
    [self notifyCentralsWithPairedRemoteNameSender:nil];
}
- (void) connect {

    NSDictionary *options =@{CBPeripheralManagerOptionShowPowerAlertKey : @YES,
                             CBPeripheralManagerOptionRestoreIdentifierKey: @"NavigationNotifierServerPeripheral"} ;
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];

}


- (NSData *)pairedClientNameData {
    NSString *pairedClientName = [self pairedRemoteName];
    if (pairedClientName==nil) {
        pairedClientName = IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA;
    }
    return [pairedClientName dataUsingEncoding:NSUTF8StringEncoding];
}
- (NSData *)serverNameData {
    return [[self localName] dataUsingEncoding:NSUTF8StringEncoding];
}


- (void)startAdvertising
{
    if (_manager.state == CBCentralManagerStatePoweredOn && !_manager.isAdvertising) {

        NSDictionary *advertisementData = @{CBAdvertisementDataServiceUUIDsKey : @[IND_ANCS_SV_UUID, IND_NN_SERVICE_UUID], CBAdvertisementDataLocalNameKey : UIDevice.currentDevice.name};
        [_manager startAdvertising:advertisementData];
    }
}

- (void)stopAdvertising
{
    if (_manager.isAdvertising) {
        [_manager stopAdvertising];
    }
}



-(CBMutableCharacteristic *)pairedClientCharacteristic {
    for (CBMutableCharacteristic *characteristic in _service.characteristics) {
        if ([characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
            return characteristic;
        }
    }
    return nil;
}
- (void)notifyCentralsWithPairedRemoteNameSender:(CBCentral *)sender {
    CBMutableCharacteristic *pairedClientCharacteristic = [self pairedClientCharacteristic];
    NSMutableArray *centralsToNotify = [pairedClientCharacteristic.subscribedCentrals mutableCopy];
    if (sender!=nil) {
        [centralsToNotify removeObject:sender];
    }
    if (centralsToNotify.count>0) {
        pairedClientCharacteristic.value = [self pairedClientNameData];
        [_manager updateValue:pairedClientCharacteristic.value forCharacteristic:pairedClientCharacteristic onSubscribedCentrals:centralsToNotify];

    }
}


- (NSString *)localName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *serverName = [defaults stringForKey:@"serverName"];
    if (serverName==nil) {
        serverName = [NSString stringWithFormat:@"NavServer_%d", arc4random()%999]; //not so great, better randomazity would be prefered
        [defaults setObject:serverName forKey:@"serverName"];
    }
    return serverName;

}


- (CBMutableService *)createService {
    CBMutableService *service = [[CBMutableService alloc] initWithType:IND_NN_SERVICE_UUID primary:YES];
    
    CBMutableCharacteristic *pairedClientName = [[CBMutableCharacteristic alloc] initWithType:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite|CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    CBMutableCharacteristic *serverName = [[CBMutableCharacteristic alloc] initWithType:IND_NN_SERVER_NAME_CHAR_UUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];

    service.characteristics = @[pairedClientName, serverName];
    return service;

}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {

        if (_service == nil) {
            _service = [self createService];
            [_manager addService:_service];
        }
    } else {
        [self stopAdvertising];
    }

}
- (void)peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    
}
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error!=nil) {
        NSLog(@"Error! %@",error);
        return;
    }
    [self startAdvertising];

}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    NSLog(@"subscribed");
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    [self wasDisconnected];
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    //fixme: only 0 offsets
    if (request.offset!=0) {
        [peripheral respondToRequest:request withResult: CBATTErrorInvalidOffset];
        return;
    }
    
    if ([request.characteristic.UUID isEqual:IND_NN_SERVER_NAME_CHAR_UUID]) {
        request.value = [self serverNameData];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else if ([request.characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
        request.value = [self pairedClientNameData];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];

    }
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    for (CBATTRequest* request in requests) {
        if ([request.characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
            NSString *remoteName = [[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding];
            if ([remoteName isEqualToString:IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA]) {
                [self wasUnpaired];
            } else {
                [self wasConnectedToRemote:remoteName];

            }
            [self notifyCentralsWithPairedRemoteNameSender:request.central];

            
        }

    }
    [peripheral respondToRequest:requests[0] withResult:CBATTErrorSuccess];

}
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
}


@end
