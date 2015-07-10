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
-(NSString *)pairedClientName;
-(NSString *)serverName;

-(void)unpaired;

@end

@implementation NNPeripheralManager {
    CBPeripheralManager *_manager;
    dispatch_queue_t _delegateQueue;
    CBPeripheralManagerState _state;
    CBMutableService *_service;

}
@synthesize delegate = _delegate;

- (id) init {
    if (self = [super init]) {
        _delegateQueue = dispatch_queue_create("com.darvin.navigationNotifier.Server.DelegateDispatchQueue", DISPATCH_QUEUE_SERIAL);
        

    }
    return self;
}


- (BOOL)isPaired {
    return [self pairedClientName]!=nil;
}
- (NSString *)pairedRemoteName {
    return [self pairedClientName];
}

- (void) unpair {
    [self unpaired];
}
- (void) connect {
    if (![[self pairedClientName] isEqualToString:IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA]) {
        //already paired lets call delegate
        if ([self.delegate respondsToSelector:@selector(connectionManager:pairedWith:)]) {
            [self.delegate connectionManager:self pairedWith:[self pairedClientName]];
        }
    }
    NSDictionary *options =@{CBPeripheralManagerOptionShowPowerAlertKey : @YES,
                             CBPeripheralManagerOptionRestoreIdentifierKey: @"NavigationNotifierServerPeripheral"} ;
    _manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:_delegateQueue options:options];

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

- (void)unpaired {
    [self setPairedClientName:nil];
    if ([self.delegate respondsToSelector:@selector(connectionManagerUnpaired:)]) {
        //fixme proper queue in case of client-side unpairing
        [self.delegate connectionManagerUnpaired:self];
    }
}

- (void)connectedToClientName:(NSString *)clientName {
    if ([clientName isEqualToString:[self pairedClientName]]) {
        //paired already, reconnection
      
    } else {
        //new pairing, refresh pairing
        [self setPairedClientName:clientName];
        [self notifyCentralsWithPairedClientName];
        if ([self.delegate respondsToSelector:@selector(connectionManager:pairedWith:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate connectionManager:self pairedWith:clientName];
            });
            
        }

    }
    
    if ([self.delegate respondsToSelector:@selector(connectionManager:connectedWith:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate connectionManager:self connectedWith:clientName];
        });
        
    }
}

- (void)notifyCentralsWithPairedClientName {
    //fixme in order to implement unpairing on already connected clients
}

- (NSString *)pairedClientName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *pairedClientName = [defaults stringForKey:@"pairedClientName"];

    return pairedClientName;
    
}
- (void)setPairedClientName:(NSString *)pairedClientName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:pairedClientName forKey:@"pairedClientName"];
}

- (NSString *)serverName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *serverName = [defaults stringForKey:@"serverName"];
    if (serverName==nil) {
        serverName = [NSString stringWithFormat:@"NavServer_%d", arc4random()%999]; //not so great, better randomazity would be prefered
        [defaults setObject:serverName forKey:serverName];
    }
    return serverName;

}


- (CBMutableService *)createService {
    CBMutableService *service = [[CBMutableService alloc] initWithType:IND_NN_SERVICE_UUID primary:YES];
    
    CBMutableCharacteristic *pairedClientName = [[CBMutableCharacteristic alloc] initWithType:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID properties:CBCharacteristicPropertyRead|CBCharacteristicPropertyWrite value:nil permissions:CBAttributePermissionsReadable|CBAttributePermissionsWriteable];
    CBMutableCharacteristic *serverName = [[CBMutableCharacteristic alloc] initWithType:IND_NN_SERVER_NAME_CHAR_UUID properties:CBCharacteristicPropertyRead value:[[self serverName] dataUsingEncoding:NSUTF8StringEncoding] permissions:CBAttributePermissionsReadable];

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
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    [self startAdvertising];

}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    //fixme: only 0 offsets
    if (request.offset!=0) {
        [peripheral respondToRequest:request withResult: CBATTErrorInvalidOffset];
        return;
    }
    
    if ([request.characteristic.UUID isEqual:IND_NN_SERVER_NAME_CHAR_UUID]) {
        request.value = [[self serverName] dataUsingEncoding:NSUTF8StringEncoding];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else if ([request.characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
        NSString *pairedClientName = [self pairedClientName];
        request.value = [pairedClientName?pairedClientName:IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA dataUsingEncoding:NSUTF8StringEncoding];
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];

    }
    
}
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    for (CBATTRequest* request in requests) {
        if ([request.characteristic.UUID isEqual:IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID]) {
            [self connectedToClientName:[[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]];
            
        }

    }
    [peripheral respondToRequest:requests[0] withResult:CBATTErrorSuccess];

}
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    
}


@end
