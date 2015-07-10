//
//  BLEIDs.h
//  Server
//
//  Created by Sergey Klimov on 7/9/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#ifndef BLEIDs_h
#define BLEIDs_h


NS_INLINE CBUUID * ind_CBUUID(NSString *str) {
    return [CBUUID UUIDWithString:str];
}

#define IND_ANCS_SV_UUID ind_CBUUID(@"7905F431-B5CE-4E99-A40F-4B1E122D00D0") // ANCS service
#define IND_ANCS_NS_UUID ind_CBUUID(@"9FBF120D-6301-42D9-8C58-25E699A21DBD") // ANCS Notification Source
#define IND_ANCS_CP_UUID ind_CBUUID(@"69D1D8F3-45E1-49A8-9821-9BBDFDAAD9D9") // ANCS Control Point
#define IND_ANCS_DS_UUID ind_CBUUID(@"22EAC6E9-24D6-4BB5-BE44-B36ACE7C7BFB") // ANCS Data Source

#define IND_NN_SERVICE_UUID ind_CBUUID(@"EE193598-6D50-4631-9672-B05BBCEC3591")
#define IND_NN_SERVER_NAME_CHAR_UUID ind_CBUUID(@"E1450996-0DDB-4986-B3E4-A3E49B3CA923")
#define IND_NN_PAIRED_CLIENT_NAME_CHAR_UUID ind_CBUUID(@"98C038A9-A58F-4F3D-A4B2-CEB1250100DE")

#define IND_NN_PAIRED_CLIENT_NAME_EMPTY_DATA @"<none>"
#endif