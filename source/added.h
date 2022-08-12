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

void setNSStringForKey(NSString *value, NSString *pkey){
	NSMutableDictionary *preferences;
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"]) {
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"];
	} else {
		preferences = [[NSMutableDictionary alloc] init];
	}
	[preferences setObject:value forKey: pkey];
	[preferences writeToFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist" atomically:YES];
}

void setBoolForKey(BOOL value, NSString *pkey){
	NSMutableDictionary *preferences;
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"]) {
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"];
	} else {
		preferences = [[NSMutableDictionary alloc] init];
	}
	[preferences setObject:[NSNumber numberWithBool:value] forKey: pkey];
	[preferences writeToFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist" atomically:YES];
}

void setObjectForKey(id value, NSString *pkey){
	NSMutableDictionary *preferences;
	if ([[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"]) {
		preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"];
	} else {
		preferences = [[NSMutableDictionary alloc] init];
	}
	[preferences setObject:value forKey: pkey];
	[preferences writeToFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist" atomically:YES];
}