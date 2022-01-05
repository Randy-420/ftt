#define PREFS @"com.randy420.fttprefs"

static NSString *GetNSString(NSString *pkey, NSString *defaultValue, NSString *plst){
	NSMutableDictionary *Dict = [NSMutableDictionary dictionaryWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist",plst]]];

	return [Dict objectForKey:pkey] ? [Dict objectForKey:pkey] : defaultValue;
}

static BOOL GetBool(NSString *pkey, BOOL defaultValue, NSString *plst) {
	NSMutableDictionary *Dict = [NSMutableDictionary dictionaryWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist",plst]]];

	return [Dict objectForKey:pkey] ? [[Dict objectForKey:pkey] boolValue] : defaultValue;
}

static int GetInt(NSString *pkey, int defaultValue, NSString *plst) {
	NSMutableDictionary *Dict = [NSMutableDictionary dictionaryWithDictionary:[NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist",plst]]];

	return [Dict objectForKey:pkey] ? [[Dict objectForKey:pkey] intValue] : defaultValue;
}