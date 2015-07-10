//
//  ANCS.h
//  Server
//
//  Created by Sergey Klimov on 7/10/15.
//  Copyright (c) 2015 Sergey Klimov. All rights reserved.
//

#ifndef ANCS_h
#define ANCS_h

typedef enum {
	ANCSCategoryIDOther= 0,
	ANCSCategoryIDIncomingCall= 1,
	ANCSCategoryIDMissedCall= 2,
	ANCSCategoryIDVoicemail= 3,
	ANCSCategoryIDSocial= 4,
	ANCSCategoryIDSchedule= 5,
	ANCSCategoryIDEmail= 6,
	ANCSCategoryIDNews= 7,
	ANCSCategoryIDHealthAndFitness= 8,
	ANCSCategoryIDBusinessAndFinance= 9,
	ANCSCategoryIDLocation= 10,
	ANCSCategoryIDEntertainment= 11,
};
typedef uint8_t ANCSCategoryID;

typedef enum {
	ANCSEventIDNotificationAdded= 0,
	ANCSEventIDNotificationModified= 1,
	ANCSEventIDNotificationRemoved= 2,
};
typedef uint8_t ANCSEventID;

typedef enum {
	ANCSEventFlagSilent= (1 << 0),
	ANCSEventFlagImportant= (1 << 1),
	ANCSEventFlagPreExisting= (1 << 2),
	ANCSEventFlagPositiveAction= (1 << 3),
	ANCSEventFlagNegativeAction= (1 << 4),
};
typedef uint8_t ANCSEventFlag;

typedef enum {
	ANCSCommandIDGetNotificationAttributes= 0,
	ANCSCommandIDGetAppAttributes= 1,
	ANCSCommandIDPerformNotificationAction= 2,
};
typedef uint8_t ANCSCommandID;

typedef enum {
	ANCSNotificationAttributeIDAppIdentifier= 0,
	ANCSNotificationAttributeIDTitle= 1,// (Needs to be followed by a 2-bytes max length parameter)
	ANCSNotificationAttributeIDSubtitle= 2, //(Needs to be followed by a 2-bytes max length parameter)
	ANCSNotificationAttributeIDMessage= 3, //(Needs to be followed by a 2-bytes max length parameter)
	ANCSNotificationAttributeIDMessageSize= 4,
	ANCSNotificationAttributeIDDate= 5,
	ANCSNotificationAttributeIDPositiveActionLabel= 6,
	ANCSNotificationAttributeIDNegativeActionLabel= 7,
};
typedef uint8_t ANCSNotificationAttributeID;

typedef enum {
	ANCSActionIDPositive= 0,
	ANCSActionIDNegative= 1,
};
typedef uint8_t ANCSActionID;

typedef enum {
	ANCSAppAttributeIDDisplayName= 0,
};
typedef uint8_t ANCSAppAttributeID;


typedef uint8_t ANCSNotificationUID[4];
typedef uint8_t ANCSCommandGetAttributeMaxSizeArg[2];

typedef struct {
    ANCSEventID eventID;
    ANCSEventFlag eventFlag;
    ANCSCategoryID categoryID;
    uint8_t categoryCount;
    ANCSNotificationUID notificationUID;
} ANCSNotification;

static inline uint8_t* ANCSGetNotificationAttributesCommand(ANCSNotificationUID notificationUID, size_t *resultSize) {
    ANCSNotificationAttributeID attributesToFetch[] = {
        ANCSNotificationAttributeIDAppIdentifier,
//        ANCSNotificationAttributeIDTitle,
//        ANCSNotificationAttributeIDSubtitle,
//        ANCSNotificationAttributeIDMessage,
        ANCSNotificationAttributeIDMessageSize,
        ANCSNotificationAttributeIDDate
    };
    int attributesToFetchAmount = 6;
    size_t size = 0;
    size += sizeof(ANCSCommandID);
    size += sizeof(ANCSNotificationUID);
    
    for (int i=0; i<attributesToFetchAmount; i++) {
        size += sizeof(ANCSNotificationAttributeID);
        ANCSNotificationAttributeID attr = attributesToFetch[i];
        if (attr==ANCSNotificationAttributeIDMessage||
            attr==ANCSNotificationAttributeIDSubtitle||
            attr==ANCSNotificationAttributeIDTitle
            ) {
            size += sizeof(ANCSCommandGetAttributeMaxSizeArg);
        }
    }
    
    *resultSize = size;
    uint8_t* result = malloc(size);
    uint8_t* p = result;
    *p = ANCSCommandIDGetNotificationAttributes;
    p += sizeof(ANCSCommandID);
    memcpy(p, notificationUID, sizeof(ANCSNotificationUID));
    p += sizeof(ANCSNotificationUID);
    
    for (int i=0; i<attributesToFetchAmount; i++) {
        ANCSNotificationAttributeID attr = attributesToFetch[i];
        *p = attr;
        p += sizeof(ANCSNotificationAttributeID);

        if (attr==ANCSNotificationAttributeIDMessage||
            attr==ANCSNotificationAttributeIDSubtitle||
            attr==ANCSNotificationAttributeIDTitle
            ) {
            //
            p += sizeof(ANCSCommandGetAttributeMaxSizeArg);
        }
    }

    
    return result;
}

#endif
