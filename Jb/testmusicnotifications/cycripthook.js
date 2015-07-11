
@import com.saurik.substrate.MS

var oldm1 = {};
var notificationCollection = [];
MS.hookMessage(MPNowPlayingInfoCenter, @selector(setNowPlayingInfo:), function(dict) {
	notificationCollection.push(dict);
	system.print(dict); 
	oldm1->call(this, dict) ;
}, oldm1);