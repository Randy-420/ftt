#import <TargetConditionals.h>
#import "include/420.h"//Randy420 add
#import "added.h"//Randy420 add

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface UIDevice (PrivateBlackJacket)
/**
 @brief Get specific device information from MobileGestalt

 @param key The key to lookup

 @return The value returned by MGCopyAnswer
 */
- (NSString *)_deviceInfoForKey:(NSString *)key;
@end

#elif TARGET_OS_MAC
#import <Foundation/Foundation.h>
#else
#error Unknown target, please make sure you're compiling for iOS or macOS
#endif

/**
 @brief Convert a Flex patch to code

 @param patch The Flex patch
 @param comments Add comments
 @param uikit Pointer to a BOOL which will indicate if UIKit needs to be linked against
 @param logos If the output should be logos (otherwise plain Obj-C)

 @return a UTF8 encoded string of the code
 */
NSString *codeFromFlexPatch(NSDictionary *patch, BOOL comments, BOOL *uikit, BOOL logos) {
	BOOL finishVoid = GetBool(@"finishVoid", YES, PREFS);//Randy420 add
	BOOL askVoid = GetBool(@"askVoid", NO, PREFS);//Randy420 add

	NSString *ret;
	NSMutableArray *methodTypez = [[NSMutableArray alloc] init];//Randy420 add
	@autoreleasepool {
		NSMutableString *xm = [NSMutableString stringWithString:@"#import <UIKit/UIKit.h>\n\n"];

		if (!logos)
			[xm appendString:@"#include <substrate.h>\n\n"];

		NSString *swiftPatchStr = @"PatchedSwiftClassName";

		NSMutableString *constructor = [NSMutableString stringWithString:@"static __attribute__((constructor)) void _fttLocalInit() {\n"];
		NSMutableArray<NSString *> *usedClasses = [NSMutableArray array];
		NSMutableArray<NSString *> *usedMetaClasses = [NSMutableArray array];
		NSMutableArray<NSString *> *usedSwiftClasses = [NSMutableArray array];

		for (NSDictionary *unit in patch[@"units"]) {
			NSDictionary *objcInfo = unit[@"methodObjc"];
			NSString *className = objcInfo[@"className"];
			NSString *selectorName = objcInfo[@"selector"];

			NSString *logosConvention = [selectorName stringByReplacingOccurrencesOfString:@":" withString:@"$"];
			NSString *cleanClassName = [className stringByReplacingOccurrencesOfString:@"." withString:swiftPatchStr];

			NSString *implMainName = [NSString stringWithFormat:@"_ftt_meth_$%@$%@", cleanClassName, logosConvention];
			NSString *origImplName = [NSString stringWithFormat:@"_orig%@", implMainName];
			NSString *patchImplName = [NSString stringWithFormat:@"_patched%@", implMainName];

			NSString *flexDisplayName = objcInfo[@"displayName"];
			NSArray<NSString *> *displayName = [flexDisplayName componentsSeparatedByString:@")"];
			NSString *bashedMethodTypeValue = displayName.firstObject;
			NSString *returnType = [bashedMethodTypeValue substringFromIndex:2];

			BOOL isClassMethod = [[bashedMethodTypeValue substringToIndex:1] isEqualToString:@"+"];

			NSMutableString *implArgList = [NSMutableString stringWithString:@"(id self, SEL _cmd"];
			NSMutableString *justArgCall = [NSMutableString stringWithString:@"(self, _cmd"];
			NSMutableString *justArgType = [NSMutableString stringWithString:@"(id, SEL"];

			NSMutableString *realMethodName = [NSMutableString string];
			[realMethodName appendString:[bashedMethodTypeValue stringByReplacingOccurrencesOfString:@"(" withString:@" ("]];
			[realMethodName appendFormat:@")%@", [displayName[1] substringFromIndex:1]];
			[methodTypez removeAllObjects];//Randy420 add
			for (int displayId = 1; displayId < displayName.count-1; displayId++) {
				NSArray<NSString *> *typeBreakup = [displayName[displayId] componentsSeparatedByString:@"("];
				NSString *argType = typeBreakup.lastObject;

				[implArgList appendFormat:@", %@ arg%d", argType, displayId];
				[justArgCall appendFormat:@", arg%d", displayId];
				[justArgType appendFormat:@", %@", argType];

				[methodTypez addObject:argType];//Randy420 add

				[realMethodName appendFormat:@")arg%d%@", displayId, displayName[displayId+1]];
			}

			[implArgList appendString:@")"];
			[justArgCall appendString:@")"];
			[justArgType appendString:@")"];

			BOOL callsOrig = NO;

			NSMutableString *implBody = [NSMutableString string];
			if (comments) {
				NSString *smartComment = unit[@"name"];
				NSString *defaultComment = [NSString stringWithFormat:@"Unit for %@", flexDisplayName];
				if (smartComment.length > 0 && ![smartComment isEqualToString:defaultComment]) {
					[implBody appendFormat:@"	// %@\n", smartComment];
				}
			}

			NSArray *allOverrides = unit[@"overrides"];
			for (NSDictionary *override in allOverrides) {
				//if (override.count == 0)
					//continue;

				int retType = [override[@"type"][@"type"] intValue];//Randy420 add
				int retSubType = [override[@"type"][@"subtype"] intValue];//Randy420 add

				NSString *origValue = override[@"value"][@"value"];

				if ([origValue isKindOfClass:NSString.class]) {
					NSString *subToEight = origValue.length >= 8 ? [origValue substringToIndex:8] : NULL;

					if ([subToEight isEqualToString:@"(FLNULL)"]) {
						origValue = @"NULL";
					} else if ([subToEight isEqualToString:@"FLcolor:"]) {
						NSArray *color = [[origValue substringFromIndex:8] componentsSeparatedByString:@","];
						NSString *restrict colorBase = @"[UIColor colorWithRed:%@/255.0 green:%@/255.0 blue:%@/255.0 alpha:%@/255.0]";
						origValue = [NSString stringWithFormat:colorBase, color[0], color[1], color[2], color[3]];
						*uikit = YES;
					} else {
						origValue = [NSString stringWithFormat:@"@\"%@\"", origValue];
					}
				}

				int argument = [override[@"argument"] intValue];

				if (argument == 0) {
/*Randy420 start add*/
					if ([returnType rangeOfString:@"bool"].location != NSNotFound){
						if ([origValue intValue] == 0)
							origValue = @"NO";
						if ([origValue intValue] == 1)
							origValue = @"YES";
					}

					if (retType == 1 && retSubType == 2) {
						origValue = [NSString stringWithFormat:@"[NSNumber numberWithInteger:%@]", origValue];
					}
/*Randy420 finish add*/
					[implBody appendFormat:@"	return %@;\n", origValue];
					break;
				} else {
/*Randy420 start add*/
					if ([[methodTypez objectAtIndex:argument-1] isEqualToString:@"id"]){
						if (retType == 1 && retSubType == 2) {
							origValue = [NSString stringWithFormat:@"[NSNumber numberWithInteger:%@]", origValue];
						}
					}
					if ([[methodTypez objectAtIndex:argument-1] isEqualToString:@"bool"]){
						if ([origValue intValue] == 0){
							origValue = @"NO";
						} else if ([origValue intValue] == 1){
							origValue = @"YES";
						}
					}
/*Randy420 finish add*/
					[implBody appendFormat:@"	arg%i = %@;\n", argument, origValue];
				}
			}
			NSUInteger overrideCount = allOverrides.count;
			if (overrideCount == 0 || [allOverrides.firstObject[@"argument"] intValue] > 0) {
				if ([bashedMethodTypeValue containsString:@"void"]) {//Randy420 edit
					if (overrideCount > 0) {
						if (logos) {
							[implBody appendString:@"	//%orig;\n"];
						} else {
							callsOrig = YES;
							[implBody appendFormat:@"	%@%@;\n", origImplName, justArgCall];
						}
/*Randy420 start add*/
					} else {
							BOOL addToVoid = NO;
							char override[2];
							if (!finishVoid && askVoid){
								while (1) {
									printf("\n\n\n%s{\n	//orig;???\n}\nWould you like to add \"%%orig\" to this method? y/n:", realMethodName.UTF8String);
									scanf("%1s", override);
									if (strcmp(override,"y") == 0){
										addToVoid = YES;
										break;
									} else if (strcmp(override,"n") == 0) {
										break;
									} else {
										printf("---------------------\n|PLEASE ENTER Y or N|\n---------------------");
									}
								}
									
							}
							if (finishVoid || addToVoid){
								[implBody appendString:@"	%orig;\n"];
							}else{
								[implBody appendString:@"	//%orig;\n"];
							}
/*Randy420 add finish*/
					}
				} else {
					[implBody appendString:@"	return %orig;\n"];
				}
			}

			if (callsOrig)
				[xm appendFormat:@"static %@ (*%@)%@;\n", returnType, origImplName, justArgType];

			if (logos) {
				[xm appendFormat:@"%%hook %@\n%@ {\n%@}\n%%end\n\n", cleanClassName, realMethodName, implBody];
			} else {
				[xm appendFormat:@"static %@ %@%@ {\n%@}\n\n", returnType, patchImplName, implArgList, implBody];
			}

			NSString *internalClassName = [NSString stringWithFormat:@"_ftt_class_%@", cleanClassName];
			if (logos) {
				if ([className containsString:@"."])
					if (![usedSwiftClasses containsObject:className])
						[usedSwiftClasses addObject:className];
			} else {
				if (![usedClasses containsObject:className]) {
					[constructor appendFormat:@"	Class %@ = objc_getClass(\"%@\");\n", internalClassName, className];
					[usedClasses addObject:className];
				}

				if (isClassMethod) {
					NSString *metaClassName = [@"_ftt_metaClass" stringByAppendingString:internalClassName];
					if (![usedMetaClasses containsObject:metaClassName]) {
						[constructor appendFormat:@"	Class %@ = object_getClass(%@);\n", metaClassName, internalClassName];
						[usedMetaClasses addObject:metaClassName];
					}
					internalClassName = metaClassName;
				}

				[constructor appendFormat:@"	MSHookMessageEx(%@, @selector(%@), (IMP)%@, ", internalClassName, selectorName, patchImplName];
				if (callsOrig) {
					[constructor appendFormat:@"(IMP *)%@", origImplName];
				} else {
					[constructor appendString:@"NULL"];
				}
				[constructor appendString:@");\n"];
			}
		}

		if (logos) {
			if (usedSwiftClasses.count) {
				[xm appendString:@"%ctor {\n	%init("];
				NSString *lastClass = usedSwiftClasses.lastObject;
				for (NSString *className in usedSwiftClasses) {
					NSString *comma = [className isEqualToString:lastClass] ? @");\n" : @",\n		";
					NSString *patchedClassName = [className stringByReplacingOccurrencesOfString:@"." withString:swiftPatchStr];
					[xm appendFormat:@"%@ = objc_getClass(\"%@\")%@", patchedClassName, className, comma];
				}
				[xm appendString:@"\n}"];
			}
		} else {
			[constructor appendString:@"}"];
			[xm appendString:constructor];
		}
		ret = [NSString stringWithString:xm];
	}
	return ret;
}
/*Randy420 start add*/
static NSString *local(NSString *local, NSString *def){
	NSString *path = @"/Library/Application Support/Flex to Theos";
	NSString *tPath;
	NSArray *languages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	NSArray *preferredLanguages = [NSLocale preferredLanguages];

	for (NSString *preferredLanguage in preferredLanguages){
		for (NSString *language in languages){
			if ([preferredLanguage hasPrefix:[language stringByReplacingOccurrencesOfString:@".lproj" withString:@""]]){
				tPath = [path stringByAppendingPathComponent:language];
				if ([[NSFileManager defaultManager] fileExistsAtPath:tPath]){
					path = tPath;
					return [[NSBundle bundleWithPath:path] localizedStringForKey:local value:def table:@"fttTweak"];
				}
			}
		}
	}

	return def;//[[NSBundle bundleWithPath:path] localizedStringForKey:local value:def table:@"fttTweak"];
}
/*Randy420 finish add*/
int main(int argc, char *argv[]) {
	setuid(0);
	seteuid(0);
	setgid(0);
	int sandBox = GetInt(@"folderSuffix", 420, PREFS);//Randy420 add

#if TARGET_OS_IPHONE
	int choice = -1;
	BOOL dump = NO;
	BOOL getPlist = NO;
#endif
	NSString *version = @PACKAGE_VERSION;//Randy420 add
	NSString *sandbox = GetNSString(@"folderPrefix", @"Randy", PREFS);//Randy420 edit
	NSString *dumpFolder = GetNSString(@"dumpFolder", @"/var/mobile/tweaks/myFlex", PREFS);//Randy420 add

	if (![[dumpFolder substringToIndex:1] isEqualToString:@"/"])//Randy420 add
		dumpFolder = [NSString stringWithFormat:@"/%@", dumpFolder];//Randy420 add

	NSString *dumpAll = @"";//Randy420 add
	NSString *name;
	NSString *patchID;
	NSString *remote;
	NSString *cversion = @"0.8";//Randy420 add
	NSString *email;//Randy420 add
	NSString *runCode;//Randy420 add
	NSString *durl;//Randy420 add
	NSString *nversion;//Randy420 add
	NSString *myweb = @"https://Randy-420.GitHub.io";//Randy420 add

	NSScanner *scanner;//Randy420 add
	NSMutableString *strippedString;//Randy420 add
	NSCharacterSet *keep;//Randy420 add
	NSString *buffer;//Randy420 add
	__block NSString *text;//Randy420 add
	NSString *text1;//Randy420 add
	NSString *helpme;//Randy420 add

	BOOL adjustDescription = YES;//Randy420 add
	BOOL tweak = YES;
	BOOL logos = YES;
	BOOL smart = NO;
	BOOL output = YES;
	BOOL color = YES;
	BOOL rename = NO;//Randy420 add
	BOOL trigF = NO;//Randy420 add
	BOOL update = NO;//Randy420 add
	BOOL MakeTheos = NO;//Randy420 add
	BOOL askedCredentials = NO;//Randy420 add
	BOOL totalDump = NO;//Randy420 add
	BOOL useDumpFolder = GetBool(@"useDumpFolder", YES, PREFS);//Randy420 add
	BOOL showAll = GetBool(@"showAll", YES, PREFS);//Randy420 add

	const char *cyanColor = "\x1B[36m";//Randy420 edit
	const char *redColor = "\x1B[31m";//Randy420 edit
	const char *greenColor = "\x1B[32m";//Randy420 edit
	const char *resetColor = "\x1B[0m";//Randy420 edit
	char userDescription[400];//Randy420 add
	char userName[40];//Randy420 add
	char userEmail[50];//Randy420 add
	char credentials[2];//Randy420 add

	_420Manager* _420 = [[_420Manager alloc] init];//Randy420 add

	FILE *hidesLog;//Randy420 add

	NSDictionary *ufile;//Randy420 add

	NSFileManager *FM = NSFileManager.defaultManager;//Randy420 add

	text = local(@"USAGE", @"USAGE");
	helpme = [NSString stringWithFormat:@"%s%@: %s ftt", greenColor, text, cyanColor];

	text = local(@"OPTIONS", @"OPTIONS");
	helpme = [NSString stringWithFormat:@"%@ -[%@]\n", helpme, text];

	text = local(@"UPDATES", @"UPDATES");
	helpme = [NSString stringWithFormat:@"%@ %s[%s%@%s]\n", helpme, resetColor, greenColor, text, resetColor];

	text = local(@"-u", @"Check for an update to ftt (can't be used with other options)");
	helpme = [NSString stringWithFormat:@"%@  %s-u%s   %@\n\n", helpme, cyanColor, resetColor, text];

	text = local(@"NAMING", @"NAMING");
	helpme = [NSString stringWithFormat:@"%@ [%s%@%s]:\n", helpme, greenColor, text, resetColor];

	text = local(@"-f", @"Set name of folder created for project");
	helpme = [NSString stringWithFormat:@"%@  %s-f%s   %@", helpme, cyanColor, resetColor, text];

	text = local(@"DEFAULT_IS", @"default is");
	helpme = [NSString stringWithFormat:@"%@ (%@: %@)\n", helpme, text, sandbox];

	text = local(@"-a", @"Set name of the folder created for project to the flex package name");
	helpme = [NSString stringWithFormat:@"%@  %s-a%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-n", @"Override the tweak's name (com.yourname.xxxx)");
	helpme = [NSString stringWithFormat:@"%@  %s-n%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-v", @"Set version");
	helpme = [NSString stringWithFormat:@"%@  %s-v%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"DEFAULT_IS", @"default is");
	helpme = [NSString stringWithFormat:@"%@ (%@: %@)\n\n", helpme, text, version];

	text = local(@"OUTPUT", @"OUTPUT");
	helpme = [NSString stringWithFormat:@"%@ %s[%s%@%s]\n", helpme, resetColor, greenColor, text, resetColor];

#if TARGET_OS_IPHONE
	text = local(@"-d", @"Only print available local patches, don't do anything (cannot be used with any other options)");
	helpme = [NSString stringWithFormat:@"%@  %s-d%s   %@\n", helpme, cyanColor, resetColor, text];
#endif

	text = local(@"-z", @"Automatically dump all flex patches to current directory");
	helpme = [NSString stringWithFormat:@"%@  %s-z%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-t", @"Only print Tweak.xm to console");
	helpme = [NSString stringWithFormat:@"%@  %s-t%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-s", @"Enable smart comments");
	helpme = [NSString stringWithFormat:@"%@  %s-s%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-o", @"Disable output, except errors");
	helpme = [NSString stringWithFormat:@"%@  %s-o%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-b", @"Disable colors in output");
	helpme = [NSString stringWithFormat:@"%@  %s-b%s   %@\n\n", helpme, cyanColor, resetColor, text];

	text = local(@"SOURCE", @"SOURCE");
	helpme = [NSString stringWithFormat:@"%@ %s[%s%@%s]\n", helpme, resetColor, greenColor, text, resetColor];

#if TARGET_OS_IPHONE
	text = local(@"-p", @"Directly plug in number ex. -p 1");
	helpme = [NSString stringWithFormat:@"%@  %s-p%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-c", @"Get patches directly from the cloud. Downloads use your Flex downloads. - Free accounts still have limits. Patch IDs are the last digits in share links");
	helpme = [NSString stringWithFormat:@"%@  %s-c%s   %@\n", helpme, cyanColor, resetColor, text];
#endif

	text = local(@"-g", @"Downloads Randy420's flex3 plist.");
	helpme = [NSString stringWithFormat:@"%@  %s-g%s   %@\n", helpme, cyanColor, resetColor, text];

	text = local(@"-r", @"Get remote patch from 3rd party (generally used to fetch from Sinfool repo)");
	helpme = [NSString stringWithFormat:@"%@  %s-r%s   %@\n\n", helpme, cyanColor, resetColor, text];

	text = local(@"ADVANCED", @"ADVANCED");
	helpme = [NSString stringWithFormat:@"%@ %s[%s%@%s]\n", helpme, resetColor, greenColor, text, resetColor];

	text = local(@"-m", @"After creating the output folder, it'll create a deb file automatically");
	helpme = [NSString stringWithFormat:@"%@  %s-m%s   %@\n\n", helpme, cyanColor, resetColor, text];

#pragma mark switchOpts
	const char *switchOpts;
	#if TARGET_OS_IPHONE
		switchOpts = ":c:f:n:r:v:p:umadtlsbogz~";//Randy420 edit
	#else
		switchOpts = ":f:n:r:v:umatlsboz~";
	#endif //e h i j k q w x y
	int i;
	int c;

	while ((c = getopt(argc, argv, switchOpts)) != -1) {
		switch (c) {
			case '~'://Randy420 add
				adjustDescription = NO;
				break;
			case 'z'://Randy420 add
				for(i = 1; i < argc; i++){
					dumpAll = [dumpAll stringByAppendingString:[NSString stringWithFormat:@"%s", argv[i]]];
				}
				strippedString = [NSMutableString stringWithCapacity:dumpAll.length];
				scanner = [NSScanner scannerWithString:dumpAll];
				keep = [NSCharacterSet characterSetWithCharactersInString:@"bfglmnorst"];
				while (![scanner isAtEnd]) {
					if ([scanner scanCharactersFromSet:keep intoString:&buffer]) {
						[strippedString appendString:buffer];
					} else {
						[scanner setScanLocation:([scanner scanLocation] + 1)];
					}
				}
				totalDump = YES;
				dumpAll = [NSString stringWithFormat:@"ftt -a%@~p",strippedString];
				break;
			case 'f': {
				trigF = YES;
				sandbox = [NSString stringWithUTF8String:optarg];
				if ([[sandbox componentsSeparatedByString:@" "] count] > 1) {
					text = local(@"INVALID_FOLDER_NAME", @"Invalid folder name, spaces are not allowed, becuase they break make");
					printf("%s%s%s\n",redColor, text.UTF8String, resetColor);//Randy420 edit
						return 1;
					}
				}
				break;
			case 'r':
				remote = [NSString stringWithUTF8String:optarg];
				break;
			case 'g':
				getPlist = YES;
				break;
			case 'n':
				name = [NSString stringWithUTF8String:optarg];
				break;
			case 'm'://Randy420 add
				MakeTheos=YES;
				break;
			case 'u'://Randy420 add
				update = YES;
				break;
			case 'a'://Randy420 add
				if (!trigF)
					rename = YES;
				break;
			case 'v':
				version = [NSString stringWithUTF8String:optarg];
				break;
#if TARGET_OS_IPHONE
			case 'c': {
				patchID = [NSString stringWithUTF8String:optarg];
				unsigned int smallValidPatch = 6106;
				if (patchID.intValue < smallValidPatch) {
					text = local(@"OLD_PATCH", @"Sorry, this is an older patch, and not yet supported");
					text1 = [NSString stringWithFormat:@"%s%@\n", redColor, text];

					text = local(@"OLD_PATCH1", @"Please use a patch number greater than");
					text1 = [NSString stringWithFormat:@"%@%@ %d\n", text1, text, smallValidPatch];

					text = local(@"OLD_PATCH2", @"Patch numbers are the last digits in share links");
					text1 = [NSString stringWithFormat:@"%@%@%s\n", text1, text, resetColor];

					printf("%s", text1.UTF8String);
					return 1;
				}
			}
				break;
			case 'p':
					choice = [[NSString stringWithUTF8String:optarg] intValue];
				break;
			case 'd':
				dump = YES;
				break;
#endif
			case 't':
				tweak = NO;
				break;
			case 'l':
				logos = NO;
				break;
			case 's':
				smart = YES;
				break;
			case 'o':
				output = NO;
				break;
			case 'b':
				color = NO;
				break;
			case '?': {
				text = local(@"CREDIT", @"Flex to Theos by iPadKid358 & updated by Randy420");
				printf("\n\n%s%s\n\n%s", greenColor, text.UTF8String, resetColor);//Randy420 add
				printf("%s",[helpme UTF8String]);//Randy420 edit
				return 1;
			}
		}
	}
/*Randy420 start add*/
	if (adjustDescription){
	text = local(@"CREDIT", @"Flex to Theos by iPadKid358 & updated by Randy420");
		printf("\n\n%s%s\n\n%s", greenColor, text.UTF8String, resetColor);
	}
/*Randy420 finish add*/

/*Randy420 start edit*/
	if (!color) {
		cyanColor = "\x1B[0m";
		redColor = "\x1B[0m";
		greenColor = "\x1B[0m";
		resetColor = "\x1B[0m";
	}
/*Randy420 finish edit*/

#pragma mark UPDATE
/*Randy420 start add*/
	if (update) {
		text = local(@"UPDATE_CHECK", @"Checking for update...");
		printf("%s%s%s\n", greenColor, text.UTF8String, resetColor);
		NSString *updatePath = [NSString stringWithFormat:@"%@/ftt/ftt.plist", myweb];
		ufile = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:updatePath]];

		durl = ufile[@"address"];
		nversion = ufile[@"version"];

		if ([cversion isEqualToString:nversion]){
			text = local(@"NEWEST", @"You're using the newest version of ftt! Version");
			printf("%s%s: '%s%s%s'\n\n",greenColor, text.UTF8String, cyanColor, [cversion UTF8String], resetColor);
			return 1;
		} else {
			text = local(@"OLD_RUN", @"You're running an older version of ftt");
			text1 = [NSString stringWithFormat:@"%s%@:%s\n", redColor, text, resetColor];

			text = local(@"CURRENT", @"Current Version");
			text1 = [NSString stringWithFormat:@"%@%@: '%s%@%s'\n", text1, text, redColor, cversion, resetColor];

			text = local(@"NEWEST_VERSION", @"Newest Version");
			text1 = [NSString stringWithFormat:@"%@%@: '%s%@%s'\n", text1, text, cyanColor, nversion, resetColor];

			text = local(@"DOWNLOAD_FROM", @"You can download the newest version from");
			text1 = [NSString stringWithFormat:@"%@%@: '%s%@%s'\n", text1, text, cyanColor, durl, resetColor];

			printf("%s", text1.UTF8String);

			hidesLog = freopen("/dev/null", "w", stderr);
			fclose(hidesLog);
/*Randy420 start add*/
#if TARGET_OS_IPHONE
			[UIPasteboard.generalPasteboard setValue:durl forPasteboardType:(id)kUTTypeUTF8PlainText];
			text = local(@"DOWNLOAD_FROM", @"Repo link copied to ClipBoard");

			printf("%s%s%s\n\n", greenColor, text.UTF8String, resetColor);
#endif
			return 1;
		}
	}
/*Randy420 finish add*/

	NSDictionary *patch;
	NSString *titleKey;
	NSString *appBundleKey;
	NSString *descriptionKey;
	if (patchID || remote) {
		if (patchID && remote) {
			text = local(@"MULTI_SOURCE", @"Cannot select multiple sources");

			printf("%s%s%s\n", redColor, text.UTF8String, resetColor);
			return 1;
		}

#if TARGET_OS_IPHONE
		if (patchID) {
			NSDictionary *flexPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.johncoates.Flex.plist"];
			NSString *udid = [UIDevice.currentDevice _deviceInfoForKey:@"UniqueDeviceID"];
			if (!udid) {
				text = local(@"FAILED_UDID", @"Failed to get UDID, required to fetch patches from the cloud");
				printf("%s%s%s\n", redColor, text.UTF8String, resetColor);
				return 1;
			}

			NSString *sessionToken = flexPrefs[@"session"];
			if (!sessionToken) {
				text = local(@"FAILED_TOKEN", @"Failed to get Flex session token, please open the app and make sure you're signed in");
				printf("%s%s%s\n", redColor, text.UTF8String, resetColor);
				return 1;
			}

			// Flex sends a few more things, but these are the only required parameters
			NSDictionary *bodyDict = @{
									   @"patchID":patchID,
									   @"deviceID":udid,
									   @"sessionID":sessionToken
									   };

			NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api2.getflex.co/patch/download"]];
			req.HTTPMethod = @"POST";
			NSError *jsonError;
			req.HTTPBody = [NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:&jsonError];
			if (jsonError) {
				text = local(@"ERROR_JSON", @"Error creating JSON");
				text1 = [NSString stringWithFormat:@"%s%@: %@%s", redColor, text, jsonError, resetColor];
				printf("%s\n", text1.UTF8String);
				return 1;
			}

			if (output){
				text = local(@"GETTING_PATCH", @"Getting patch");
				text1 = [NSString stringWithFormat:@"%s%@'%s", cyanColor, text, greenColor];

				text = local(@"FROM_FLEX", @"from Flex servers.");
				text1 = [NSString stringWithFormat:@"%@%@'%s%@%s\n", text1, text, cyanColor, patchID, resetColor];

				printf("%s", text1.UTF8String);
			}

			CFRunLoopRef runLoop = CFRunLoopGetCurrent();
			__block NSDictionary *getPatch;
			__block BOOL blockError = NO;
			[[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
				if (data == nil || error != nil) {
					text = local(@"PATCH_ERROR", @"Error getting patch");
					printf("%s%s%s\n", redColor, text.UTF8String, resetColor);

					if (error)
						NSLog(@"%@", error);
					blockError = YES;
				} else {

					getPatch = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
					if (!getPatch[@"units"]) {
						text = local(@"PATCH_ERROR", @"Error getting patch");
						printf("%s%s%s\n", redColor, text.UTF8String, resetColor);
						if (getPatch) {
							NSLog(@"%@", getPatch);
						} else {
							NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
						}
						blockError = YES;
					}
				}
				CFRunLoopStop(runLoop);
			}] resume];

			CFRunLoopRun();
			if (blockError)
				return 1;

			patch = getPatch;
		}
#endif
		if (remote) {
			patch = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:remote]];
			if (!patch) {
				text = local(@"REMOTE_ERROR", @"Bad remote patch");
				printf("%s%s%s\n", redColor, text.UTF8String, resetColor);
				return 1;
			}
		}

		titleKey = @"title";
		appBundleKey = @"applicationIdentifier";
		descriptionKey = @"description";
	} else {
#if TARGET_OS_IPHONE
		NSDictionary *file;
		NSString *properPath;//Randy420 add
		NSString *firstPath = @"/var/mobile/Library/Application Support/Flex3/patches.plist";
		NSString *secondPath = @"/var/mobile/Library/UserConfigurationProfiles/PublicInfo/Flex3Patches.plist";
		NSString *remotePath = [NSString stringWithFormat:@"%@/ftt/patches.plist", myweb];//Randy420 add
		if (getPlist) {
			text = local(@"MY_PLIST", @"Using Randy420's patches.plist file from");
			printf("%s%s:\n%s%s%s\n",greenColor, text.UTF8String, cyanColor, [myweb UTF8String], resetColor);//Randy420 add

			file = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:remotePath]];//Randy420 edit
		} else if ([FM fileExistsAtPath:firstPath]) {
			file = [NSDictionary dictionaryWithContentsOfFile:firstPath];
			properPath = firstPath;
		} else if ([FM fileExistsAtPath:secondPath]) {
			file = [NSDictionary dictionaryWithContentsOfFile:secondPath];
			properPath = secondPath;
		} else {
			text = local(@"NO_PLIST", @"File not found, please ensure Flex 3 is installed. If you're using an older version of Flex, please contact me at https://ipadkid.cf/contact");
			printf("File not found, please ensure Flex 3 is installed\n"
				 "If you're using an older version of Flex, please contact me at https://ipadkid.cf/contact");
			return 1;
		}
#pragma mark Create Dump Folder
/*Randy420 start add*/
		if (useDumpFolder){
			if (![FM fileExistsAtPath:dumpFolder]){
				runCode = [NSString stringWithFormat:@"echo \"mkdir -p %@\" | gap", dumpFolder];
				[_420 RunCMD:runCode WaitUntilExit:YES];
			}
			[FM changeCurrentDirectoryPath:dumpFolder];
		}

		NSArray *allPatches = file[@"patches"];
		BOOL switchedOn;//Rand420 add

		unsigned long allPatchesCount = allPatches.count;
		if (choice < 0 || totalDump) {
			for (unsigned int choose = 0; choose < allPatchesCount; choose++) {
				switchedOn = [allPatches[choose][@"switchedOn"] boolValue];//Randy420 add
				if (totalDump) {//Randy420 add
					runCode = [NSString stringWithFormat:@"%@ %i", dumpAll, choose];//Randy420 add
					[_420 RunCMD:runCode WaitUntilExit: YES];//Randy420 add
				} else {
					if (switchedOn || showAll)//Randy420 add
						printf("  %s%d%s: %s\n", switchedOn ? greenColor : redColor, choose, resetColor, [allPatches[choose][@"name"] UTF8String]);//Randy420 edit
				}
			}
			if (dump || totalDump)//Randy420 edit
				return 0;

			text = local(@"CHOICE", @"Enter corresponding number");
			printf("%s%s: %s", greenColor, text.UTF8String, resetColor);//Randy420 edit
			scanf("%d", &choice);
		}

		if (allPatchesCount <= choice) {
			text = local(@"INVALID_SELECTION", @"Invalid selection received. Please input a valid number between");
			printf("%s%s %s0%s and %s%lu\n%s", redColor, text.UTF8String, greenColor, resetColor, greenColor, allPatchesCount-1, resetColor);//Randy420 edit
			return 1;
		}

		patch = allPatches[choice];
		titleKey = @"name";
		appBundleKey = @"appIdentifier";
		descriptionKey = @"cloudDescription";
#else
		text = local(@"EXTERNAL_SOURCE", @"An external source is required");
		printf("%s\n", text.UTF8String);
		return 1;
#endif
	}

	BOOL uikit = NO;

	NSString *genedCode = codeFromFlexPatch(patch, smart, &uikit, logos);
	NSString *tweakFileExt = logos ? @"xm" : @"mm";

	if (tweak) {
		NSCharacterSet *charsOnly = NSCharacterSet.alphanumericCharacterSet.invertedSet;
#pragma mark Creating sandbox
/*Randy420 start add*/
		if (rename && (!trigF))
			sandbox=[[[patch[titleKey] lowercaseString] componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""];

		NSString *tempSB;
		do {
			tempSB = [NSString stringWithFormat:@"%@%i", sandbox, sandBox++];
		} while ([FM fileExistsAtPath:tempSB]);
		sandbox = tempSB;
/*Randy420 finish add*/

		NSError *createSandboxError;
		[FM createDirectoryAtPath:sandbox withIntermediateDirectories:NO attributes:NULL error:&createSandboxError];
		if (createSandboxError) {
			NSLog(@"%@", createSandboxError);
			return 1;
		}

#pragma mark Makefile handling
/*Randy420 start add*/
		if (!name)
			name = patch[titleKey];
		NSString *Archs =@"";
		int added = 0;
		static bool armv7, armv7s, arm64, arm64e;
		armv7 = GetBool(@"armv7", YES, PREFS);
		armv7s = GetBool(@"armv7s", YES, PREFS);
		arm64 = GetBool(@"arm64", YES, PREFS);
		arm64e = GetBool(@"arm64e", YES, PREFS);

		if(armv7) {
			Archs = [NSString stringWithFormat:@"%@ armv7", Archs];
			added++;
		}
		if(armv7s) {
			Archs = [NSString stringWithFormat:@"%@ armv7s", Archs];
			added++;
		}
		if(arm64) {
			Archs = [NSString stringWithFormat:@"%@ arm64", Archs];
			added++;
		}
		if(arm64e) {
			Archs = [NSString stringWithFormat:@"%@ arm64e", Archs];
			added++;
		}
		if (added == 0)
			Archs = @" arm64 arm64e";

		NSString *isDebug = GetNSString(@"debug", @"0", PREFS);
		NSString *finalPackage = GetNSString(@"finalPackage", @"1", PREFS);
/*Randy420 finish add*/
		NSString *title = [[name componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""];
		NSMutableString *makefile = [NSMutableString stringWithFormat:@""
		"DEBUG=%@\n"//Randy420 add
		"FINALPACKAGE=%@\n"//Randy420 add
		"include $(THEOS)/makefiles/common.mk\n\n"
		"export ARCHS=%@\n"//Randy420 add
		"TWEAK_NAME=%@\n"
		"%@_FILES=Tweak.%@\n", isDebug, finalPackage, Archs, title, title, tweakFileExt];//Randy420 edit

		if (uikit)
			[makefile appendFormat:@"%@_FRAMEWORKS = UIKit\n", title];

		[makefile appendString:@"\ninclude $(THEOS_MAKE_PATH)/tweak.mk\n"];
		[makefile writeToFile:[sandbox stringByAppendingPathComponent:@"Makefile"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];

#pragma mark plist handling
		NSString *executable = patch[appBundleKey];
		if ([executable isEqualToString:@"com.flex.systemwide"])
			executable = @"com.apple.UIKit";

		NSDictionary *plist = @{
								@"Filter":@{
										@"Bundles":@[
												executable
												]
										}
								};
		NSString *plistPath = [[sandbox stringByAppendingPathComponent:title] stringByAppendingPathExtension:@"plist"];
		[plist writeToFile:plistPath atomically:YES];

#pragma mark Control file handling
		NSString *author = patch[@"author"];
/*Randy420 start add*/
			if (!author) {
			author = GetNSString(@"prefName", @"default", PREFS);

			email = GetNSString(@"prefEmail", @"default@default.com", PREFS);
		}

		if ([author isEqualToString:@"default"]) {
			text = local(@"DEV_NAME", @"please enter your dev name");
			printf("%s%s%s\n", redColor, text.UTF8String, resetColor);

			scanf("%39s", userName);

			author = [NSString stringWithCString:userName encoding:1];
			askedCredentials = YES;
		}
		if ([email isEqualToString:@"default@default.com"]) {
			text = local(@"DEV_EMAIL", @"please enter your email so people can contact you about issues");
			printf("%s%s%s\n", redColor, text.UTF8String, resetColor);

			scanf(" %49s", userEmail);

			email = [NSString stringWithCString:userEmail encoding:1];
			askedCredentials = YES;
		}
		if (askedCredentials) {
			text = local(@"SAVE", @"Do you want to save this information? You can edit this info in the Settings app.");
			text1 = [NSString stringWithFormat:@"%s%@%s\n", cyanColor, text, resetColor];

			text = local(@"DEV", @"Dev");
			text1 = [NSString stringWithFormat:@"%@%@:%s%@%s\n", text1, text, cyanColor, author, resetColor];

			text = local(@"EMAIL", @"Email");
			text1 = [NSString stringWithFormat:@"%@%@:%s%@%s\n", text1, text, cyanColor, email, resetColor];

			printf("%s\n%sY%s/%sN%s: ", text1.UTF8String, greenColor, resetColor, redColor, resetColor);
			scanf(" %1s", credentials);
			if ([[NSString stringWithCString:credentials encoding:1] isEqualToString:@"y"]) {
				NSMutableDictionary *preferences;
				if ([FM fileExistsAtPath:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"]) {
					preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"];
				} else {
					preferences = [[NSMutableDictionary alloc] init];
				}
				[preferences setObject:author forKey: @"prefName"];
				[preferences setObject:email forKey: @"prefEmail"];
				[preferences writeToFile:@"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist" atomically:YES];

				text = local(@"SAVED_CREDENTIALS", @"Credentials saved");
				printf("%s!%s\n\n", greenColor, resetColor);
			} else {
				text = local(@"NOTSAVED_CREDENTIALS", @"Credentials not saved");
				printf("%s%s!%s\n\n", redColor, text.UTF8String, resetColor);
			}
		}
		title = [title lowercaseString];
/*Randy420 finish add*/
		NSString *lauthor = [[[author componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""] lowercaseString];//Randy420 edit
		NSString *description = [patch[descriptionKey] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n "];
/*Randy420 start add*/
		if (description.length <= 4) {
			if (!adjustDescription){
				text = local(@"COMPLETE_DUMP", @"Flex to theos complete resource dump");
				description = [NSString stringWithFormat:@"%@ - Randy420", text];
			} else {
				text = local(@"PATCH_DESCRIPTION", @"Please enter a description for your patch");
				printf("%s%s: %s", redColor, text.UTF8String, resetColor);
				scanf(" %399[^\n]s", userDescription);
				description = [NSString stringWithCString:userDescription encoding:1];
				if (description.length <= 4){
					text = local(@"MADE_USING", @"Made using Flex To Theos updated by");
					description = [NSString stringWithFormat:@"***%@: Randy420***", text];
				}
			}
		}
/*Randy420 add end*/
		NSString *control = [NSString stringWithFormat:@
		"Package: com.%@.%@\n"
		"Name: %@\n"
		"Author: %@ <%@>\n"
		"Description: %@\n"
		"Depends: mobilesubstrate\n"
		"Maintainer: %@ <%@>\n"
		"Architecture: iphoneos-arm\n"
		"Section: Tweaks\n"
		"Version: %@\n", lauthor, title, name, author, email, description, author, email, version];//Randy420 edit
		[control writeToFile:[sandbox stringByAppendingPathComponent:@"control"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		NSString *tweakFileName = [@"Tweak" stringByAppendingPathExtension:tweakFileExt];

		genedCode = [[_420 cleanUp:[genedCode stringByReplacingOccurrencesOfString:@" " withString:@""]] stringByReplacingOccurrencesOfString:@"(null);" withString:@"%orig;"];//Randy420 add - removes weird random character that looks like a space but isnt. also sorts and cleans up the hooks etc

		[genedCode writeToFile:[sandbox stringByAppendingPathComponent:tweakFileName] atomically:YES encoding:NSUTF8StringEncoding error:NULL];

		if (output){
			text = local(@"PROJECT_FOR", @"Project for");
			text1 = [NSString stringWithFormat:@"%s%@: %s%@%s\n", greenColor, text, cyanColor, title, greenColor];

			text = local(@"CREATED_IN", @"created in folder");
			text1 = [NSString stringWithFormat:@"%@%@: %s%@%s\n", text1, text, cyanColor, [[FM currentDirectoryPath] stringByAppendingPathComponent:sandbox], resetColor];
			printf("%s\n", text1.UTF8String);
		}
/*Randy420 start add*/
#pragma mark Make Deb
		if (MakeTheos){
			NSString *TheosMake = [[FM currentDirectoryPath] stringByAppendingPathComponent:sandbox];

			text = local(@"MAKING_DEB", @"Making ftt output into a deb package");
			printf("\n\n%s%s%s\n\n", greenColor, text.UTF8String, resetColor);

			[_420 RunCMD:[NSString stringWithFormat:@"cd %s;echo \"make clean package\" | gap;", [TheosMake UTF8String]]	WaitUntilExit: YES];

			NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:TheosMake error:NULL];

			__block BOOL debSuccess;
			__block NSString *package;
			[dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSString *filename = (NSString *)obj;
				BOOL exists;
				[FM fileExistsAtPath:[TheosMake stringByAppendingPathComponent:filename] isDirectory:&exists];

				if (!exists || [filename isEqualToString:@".theos"])
					return;

				package = [TheosMake stringByAppendingPathComponent:filename];

				NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:package error:NULL];

				[dirs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
					NSString *filename = (NSString *)obj;
					NSString *extension = [filename pathExtension];

					if ([extension isEqualToString:@"deb"])
						debSuccess = YES;
				}];
			}];
			if (debSuccess){
				text = local(@"DEB_MADE", @"Congratulations! Your deb file is located at");
				printf("\n%s%s: %s%s%s\n\n", greenColor, text.UTF8String, cyanColor, [package UTF8String], resetColor);
			}else{
				text = local(@"DEB_FAILED", @"FAILED to create deb file");
				printf("\n%s%s!%s\n\n",redColor, text.UTF8String, resetColor);
			}
		}
/*Randy420 add end*/
	} else {
		puts(genedCode.UTF8String);
#if TARGET_OS_IPHONE
		[UIPasteboard.generalPasteboard setValue:genedCode forPasteboardType:(id)kUTTypeUTF8PlainText];
#endif
		if (output) {
#if TARGET_OS_IPHONE
			text = local(@"OUTPUT_SUCCESS", @"Output has successfully been copied to your clipboard. You can now easily paste this output in your");
			text1 = [NSString stringWithFormat:@"%s%@", greenColor, text];

			text = local(@"FILE", @"file");
			text1 = [NSString stringWithFormat:@"%@ .%@ %@%s\n", text1, tweakFileExt, text, resetColor];

			printf("%s", text1.UTF8String);
#endif
			if (uikit) {
				text = local(@"UIKIT", @"Please add UIKit to your project's FRAMEWORKS because this tweak includes color specifying");
				printf("\n%s%s%s\n", redColor, text.UTF8String, resetColor);
			}
		}
	}
	printf("%s", resetColor);//Randy420 add
	return 0;
}