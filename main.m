#import <TargetConditionals.h>
#import "include/420.h"

NSMutableDictionary *MutDiction;

#define prefs @"/var/mobile/Library/Preferences/com.randy420.fttprefs.plist"

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
	NSString *ret;
	@autoreleasepool {
		NSMutableString *xm = [NSMutableString stringWithString:@"#import <UIKit/UIKit.h>\n\n"];
		if (!logos) {
			[xm appendString:@"#include <substrate.h>\n\n"];
		}
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

			for (int displayId = 1; displayId < displayName.count-1; displayId++) {
				NSArray<NSString *> *typeBreakup = [displayName[displayId] componentsSeparatedByString:@"("];
				NSString *argType = typeBreakup.lastObject;
				[implArgList appendFormat:@", %@ arg%d", argType, displayId];
				[justArgCall appendFormat:@", arg%d", displayId];
				[justArgType appendFormat:@", %@", argType];

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
					[implBody appendFormat:@"    // %@\n", smartComment];
				}
			}
			
			NSArray *allOverrides = unit[@"overrides"];
			for (NSDictionary *override in allOverrides) {
				if (override.count == 0) {
					continue;
				}

				NSString *origValue = override[@"value"][@"value"];

				if ([origValue isKindOfClass:NSString.class]) {
					NSString *subToEight = origValue.length >= 8 ? [origValue substringToIndex:8] : NULL;
  
					if ([subToEight isEqualToString:@"(FLNULL)"]) {
						origValue = @"NULL";
					} else if ([subToEight isEqualToString:@"FLcolor:"]){
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
											[implBody appendFormat:@"    return %@;\n", origValue];
											break;
										} else {
											[implBody appendFormat:@"    arg%i = %@;\n", argument, origValue];
										}
									}

									NSUInteger overrideCount = allOverrides.count;
									if (overrideCount == 0 || [allOverrides.firstObject[@"argument"] intValue] > 0) {
										if ([bashedMethodTypeValue isEqualToString:@"-(void"]) {
											if (overrideCount > 0) {
												if (logos) {
													[implBody appendString:@"    %orig;\n"];
													} else {
														callsOrig = YES;
														[implBody appendFormat:@"    %@%@;\n", origImplName, justArgCall];
													}
												}
											} else {
												if (logos) {
													[implBody appendString:@"    return %orig;\n"];
											} else {
												callsOrig = YES;
												[implBody appendFormat:@"    return %@%@;\n", origImplName, justArgCall];
											}
										}
									}

									if (callsOrig) {
										[xm appendFormat:@"static %@ (*%@)%@;\n", returnType, origImplName, justArgType];
									}

									if (logos) {
										[xm appendFormat:@"%%hook %@\n%@ {\n%@}\n%%end\n\n", cleanClassName, realMethodName, implBody];
									} else {
										[xm appendFormat:@"static %@ %@%@ {\n%@}\n\n", returnType, patchImplName, implArgList, implBody];
									}

									NSString *internalClassName = [NSString stringWithFormat:@"_ftt_class_%@", cleanClassName];

									if (logos) {
										if ([className containsString:@"."]) {
											if (![usedSwiftClasses containsObject:className]) {
												[usedSwiftClasses addObject:className];
											}
										}
									} else {
										if (![usedClasses containsObject:className]) {
											[constructor appendFormat:@"    Class %@ = objc_getClass(\"%@\");\n", internalClassName, className];
											[usedClasses addObject:className];
										}

										if (isClassMethod) {
											NSString *metaClassName = [@"_ftt_metaClass" stringByAppendingString:internalClassName];
											if (![usedMetaClasses containsObject:metaClassName]) {
												[constructor appendFormat:@"    Class %@ = object_getClass(%@);\n", metaClassName, internalClassName];
												[usedMetaClasses addObject:metaClassName];
											}
											internalClassName = metaClassName;
										}

										[constructor appendFormat:@"    MSHookMessageEx(%@, @selector(%@), (IMP)%@, ", internalClassName, selectorName, patchImplName];
  
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
										[xm appendString:@"%ctor {\n    %init("];
										NSString *lastClass = usedSwiftClasses.lastObject;

								for (NSString *className in usedSwiftClasses) {
									NSString *comma = [className isEqualToString:lastClass] ? @");\n" : @",\n";
									NSString *patchedClassName = [className stringByReplacingOccurrencesOfString:@"." withString:swiftPatchStr];
									[xm appendFormat:@"%@ = objc_getClass(\"%@\")%@", patchedClassName, className, comma];
								}
								[xm appendString:@"\n}\n"];
							}
						} else {
							[constructor appendString:@"}\n"];
							[xm appendString:constructor];
						}

						ret = [NSString stringWithString:xm];
					}
    
					return ret;
				}


int main(int argc, char *argv[]) {
#if TARGET_OS_IPHONE
	int choice = -1;
	BOOL dump = NO;
    
    // should be used for testing only, not documented
	BOOL getPlist = NO;
#endif
	NSString *version = @"0.0.1";
	NSString *cversion =@"0.3.0";
	NSString *sandbox = @"Randy420";
	NSString *name;
	NSString *patchID;
	NSString *remote;
	NSString *cemail;
	NSString *durl;
	NSString *nversion;
	NSString *myweb = @"https://theemeraldisle.family";
    
	const char *cyanColor = "\x1B[36m";
	const char *redColor = "\x1B[31m";
	const char *greenColor = "\x1B[32m";
	const char *resetColor = "\x1B[0m";

	BOOL tweak = YES;
	BOOL logos = YES;
	BOOL smart = NO;
	BOOL output = YES;
	BOOL color = YES;
    //by me 
	BOOL rename = NO;
	BOOL trigF = NO;
	BOOL update =NO;
	BOOL MakeTheos=NO;
    
	//char* myName="make";

	_420Manager* _420 = [[_420Manager alloc] init];

	FILE *hidesLog;

	NSDictionary *ufile;
    
	MutDiction = [[NSMutableDictionary alloc] initWithContentsOfFile:prefs];
    
	UIPasteboard *pastedboard;
    
	NSFileManager *fileManager = NSFileManager.defaultManager;
    
	NSString *helpme = [NSString stringWithFormat:@ "%sUsage: %sftt [OPTIONS]%s\n"
	" [Updates]\n"
	"  %s-u%s   Check for an update to ftt (can't be used with other options)\n\n%s"
	" [Naming]:\n"
	"  %s-f%s   Set name of folder created for project (default is %@)\n"
	"  %s-a%s   Set name of folder created for project to the flex package name\n"
	"  %s-n%s   Override the tweak name\n"
	"  %s-v%s   Set version (default is  %@)%s \n\n"
	" [Output]\n"

#if TARGET_OS_IPHONE
	"  %s-d%s   Only print available local patches, don't do anything (cannot be used with any other options)\n"
#endif

	"  %s-t%s   Only print Tweak.xm to console\n"
	"  %s-s%s   Enable smart comments\n"
	"  %s-o%s   Disable output, except errors\n"
	"  %s-b%s   Disable colors in output\n\n%s"
	" [Source]\n"

#if TARGET_OS_IPHONE
	"  %s-p%s   Directly plug in number ex. -p 1\n"
	"  %s-c%s   Get patches directly from the cloud. Downloads use your Flex downloads. - Free accounts still have limits. Patch IDs are the last digits in share links\n"
#endif
	"  %s-g%s   Downloads Randy420's flex3 plist.\n"
	"  %s-r%s   Get remote patch from 3rd party (generally used to fetch from Sinfool repo)\n\n"
	" %s[ADVANCED]\n"
	"  %s-m%s   After creating the output folder, it'll create a deb file automatically\n\n", greenColor, cyanColor, greenColor, cyanColor, resetColor, greenColor, cyanColor, resetColor, sandbox, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, version, greenColor, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, greenColor, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, cyanColor, resetColor, greenColor, cyanColor, resetColor];

	printf("\n\n%sFlex to Theos by iPad_Kid & updated by Randy420\n\n%s", greenColor, resetColor);
    const char *switchOpts;
#if TARGET_OS_IPHONE
	switchOpts = ":c:f:n:r:v:p:umadtlsbog";
#else  
	switchOpts = ":f:n:r:v:umatlsbo";
#endif 
	int c;
	while ((c = getopt(argc, argv, switchOpts)) != -1) {
		switch (c) {
			case 'f': {
				trigF = YES;
				sandbox = [NSString stringWithUTF8String:optarg];
				if ([[sandbox componentsSeparatedByString:@" "] count] > 1) {
					printf("%sInvalid folder name, spaces are not allowed, becuase they break make%s\n",redColor,resetColor);
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
			case 'm':
				MakeTheos=YES;
				break;
			case 'u':
				update = YES;
				break;
			case 'a':
				if (!trigF) {
					rename = YES;
				}
				break;
			case 'v':
				version = [NSString stringWithUTF8String:optarg];
				break;
#if TARGET_OS_IPHONE
			case 'c': {
				patchID = [NSString stringWithUTF8String:optarg];
				unsigned int smallValidPatch = 6106;
				if (patchID.intValue < smallValidPatch) {
					printf("%sSorry, this is an older patch, and not yet supported\n"
					"Please use a patch number greater than %d\n"
					"Patch numbers are the last digits in share links%s\n",
					redColor, smallValidPatch, resetColor);
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
				printf("%s",[helpme UTF8String]);
				return 1;
			}
		}
	}
    
	if (!color) {
		cyanColor = "\x1B[0m";
		redColor = "\x1B[0m";
		greenColor = "\x1B[0m";
		resetColor = "\x1B[0m";
	}

	if (update) {
		printf("%sChecking for update...%s\n", greenColor, resetColor);

		ufile = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"https://theemeraldisle.family/s/ftt.plist"]];

		durl = ufile[@"address"];
		nversion = ufile[@"version"];
 
		if ([cversion isEqualToString:nversion]){
			printf("%sYou're using the newest version of ftt! Version: '%s%s%s'\n\n",greenColor, cyanColor, [cversion UTF8String], resetColor);
			return 1;
		} else {
			printf("%sYou're running an older version of ftt:\n%sCurrent Version: '%s%s%s' \nNewest Version: '%s%s%s'\nYou can download the newest version from:\n%s%s%s\n\n",redColor, resetColor, redColor, [cversion UTF8String], resetColor, greenColor, [nversion UTF8String], resetColor, cyanColor,[durl UTF8String],resetColor);
			hidesLog = freopen("/dev/null", "w", stderr);
			pastedboard = [UIPasteboard generalPasteboard];
			pastedboard.string = durl;
			fclose(hidesLog);
			printf("%sDownload link copied to %sClipBoard%s \n\n", greenColor, cyanColor, resetColor);
			return 1;
		}
	}

	NSDictionary *patch;
	NSString *titleKey;
	NSString *appBundleKey;
	NSString *descriptionKey;
	if (patchID || remote) {
		if (patchID && remote) {
			puts("Cannot select multiple sources");
			return 1;
		}

#if TARGET_OS_IPHONE
		if (patchID) {
			NSDictionary *flexPrefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.johncoates.Flex.plist"];
			NSString *udid = [UIDevice.currentDevice _deviceInfoForKey:@"UniqueDeviceID"];
			if (!udid) {
				puts("Failed to get UDID, required to fetch patches from the cloud");
				return 1;
			}
			NSString *sessionToken = flexPrefs[@"session"];
			if (!sessionToken) {
				puts("Failed to get Flex session token, please open the app and make sure you're signed in");
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
				NSLog(@"Error creating JSON: %@", jsonError);
				return 1;
			}

			if (output) {
				printf("%sGetting patch %s from Flex servers%s\n", cyanColor, patchID.UTF8String, resetColor);
			}

			CFRunLoopRef runLoop = CFRunLoopGetCurrent();
			__block NSDictionary *getPatch;
			__block BOOL blockError = NO;
			[[NSURLSession.sharedSession dataTaskWithRequest:req completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
				if (data == nil || error != nil) {
					printf("Error getting patch\n");
					if (error) {
						NSLog(@"%@", error);
					}
					blockError = YES;
				} else {
					getPatch = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
					if (!getPatch[@"units"]) {
						printf("Error getting patch\n");
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
			if (blockError) {
				return 1;
			}

			patch = getPatch;
		}
#endif
		if (remote) {
			patch = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:remote]];
			if (!patch) {
				printf("Bad remote patch\n");
				return 1;
			}
		}

		titleKey = @"title";  

		appBundleKey = @"applicationIdentifier";
		descriptionKey = @"description";
	} else {
#if TARGET_OS_IPHONE
		NSDictionary *file;  
		NSString *firstPath = @"/var/mobile/Library/Application Support/Flex3/patches.plist";
		NSString *secondPath = @"/var/mobile/Library/UserConfigurationProfiles/PublicInfo/Flex3Patches.plist";
		if (getPlist) {
			printf("%sUsing Randy420's patches.plist file from:\n%s%s%s\n",greenColor, cyanColor, [myweb UTF8String], resetColor);
			file = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"https://theemeraldisle.family/s/patches.plist"]];
		} else if ([fileManager fileExistsAtPath:firstPath]) {
			file = [NSDictionary dictionaryWithContentsOfFile:firstPath];
		} else if ([fileManager fileExistsAtPath:secondPath]) {
			file = [NSDictionary dictionaryWithContentsOfFile:secondPath];
		} else {
			puts("File not found, please ensure Flex 3 is installed\n"
			"If you're using an older version of Flex, please contact me at https://ipadkid.cf/contact");
			return 1;
		}

		NSArray *allPatches = file[@"patches"];
		unsigned long allPatchesCount = allPatches.count;
  
		if (choice < 0) {
			for (unsigned int choose = 0;
			choose < allPatchesCount; choose++) {
				printf("  %s%d%s: %s\n", greenColor, choose, resetColor, [allPatches[choose][@"name"] UTF8String]);
			}
			if (dump) {
				return 0;
			}

			printf("%sEnter corresponding number: %s", greenColor, resetColor);
			scanf("%d", &choice);
		}

		if (allPatchesCount <= choice) {
			printf("%sInvalid selection received.\n %sPlease input a valid number between %s0%s and %s%lu\n%s", redColor,resetColor,greenColor,resetColor,greenColor,allPatchesCount-1,resetColor);
			return 1;
		}

		patch = allPatches[choice];
		titleKey = @"name";
		appBundleKey = @"appIdentifier";
		descriptionKey = @"cloudDescription";
#else
		puts("An external source is required");
		return 1;
#endif
	}
    
	BOOL uikit = NO;
    
	NSString *genedCode = codeFromFlexPatch(patch, smart, &uikit, logos);
	NSString *tweakFileExt = logos ? @"xm" : @"mm";
    
	if (tweak) {
		NSCharacterSet *charsOnly = NSCharacterSet.alphanumericCharacterSet.invertedSet;
// Creating sandbox

		if (rename && (!trigF)) {
			sandbox=[[[patch[titleKey] lowercaseString] componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""];
		}

		if ([fileManager fileExistsAtPath:sandbox]) {
			printf("%s%s%s already exists\n", redColor, sandbox.UTF8String, resetColor);
			return 1;
		}

		NSError *createSandboxError;
		[fileManager createDirectoryAtPath:sandbox withIntermediateDirectories:NO attributes:NULL error:&createSandboxError];

		if (createSandboxError) {
			NSLog(@"%@", createSandboxError);
			return 1;
		}

// Makefile handling
		if (!name) {
			name = patch[titleKey];
		}

		NSString *Archs =@"";
		int added = 0;
		static bool armv7, armv7s, arm64, arm64e;
		armv7 = [MutDiction objectForKey:@"armv7"] ? [[MutDiction objectForKey:@"armv7"]boolValue] : YES;
		armv7s = [MutDiction objectForKey:@"armv7s"] ? [[MutDiction objectForKey:@"armv7s"]boolValue] : YES;
		arm64 = [MutDiction objectForKey:@"arm64"]	? [[MutDiction objectForKey:@"arm64"]boolValue] : YES;
		arm64e = [MutDiction objectForKey:@"arm64e"] ? [[MutDiction objectForKey:@"arm64e"]boolValue] : YES;

		if(armv7) {
			Archs = [NSString stringWithFormat:@"%@ armv7", Archs];
			added = 1;
		}
		if(armv7s) {
			Archs = [NSString stringWithFormat:@"%@ armv7s", Archs];
			added = 1;
		}
		if(arm64) {
			Archs = [NSString stringWithFormat:@"%@ arm64", Archs];
			added = 1;
		}
		if(arm64e) {
			Archs = [NSString stringWithFormat:@"%@ arm64e", Archs];
			added = 1;
		}
		if (added == 0) { 
			Archs = @" arm64 arm64e";
		} 

		NSString *title = [[name componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""];
		NSMutableString *makefile = [NSMutableString stringWithFormat:@""
		"DEBUG=0\n"
		"FINALPACKAGE=1\n"
		"include $(THEOS)/makefiles/common.mk\n\n"
		"export ARCHS =%@\n"
		"TWEAK_NAME = %@\n"
		"%@_FILES = Tweak.%@\n", Archs, title, title, tweakFileExt];

		if (uikit) {
			[makefile appendFormat:@"%@_FRAMEWORKS = UIKit\n", title];
		}

		[makefile appendString:@"\ninclude $(THEOS_MAKE_PATH)/tweak.mk\n"];
		[makefile writeToFile:[sandbox stringByAppendingPathComponent:@"Makefile"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];

// plist handling
		NSString *executable = patch[appBundleKey];
		if ([executable isEqualToString:@"com.flex.systemwide"]) {
			executable = @"com.apple.UIKit";
		}

		NSDictionary *plist = @{
			@"Filter":@{
				@"Bundles":@[executable]
			}
		};
		NSString *plistPath = [[sandbox stringByAppendingPathComponent:title] stringByAppendingPathExtension:@"plist"];
		[plist writeToFile:plistPath atomically:YES];


// Control file handling

		NSString *author = patch[@"author"];

		if (!author) {
			author = [MutDiction objectForKey:@"prefName"] ? [MutDiction objectForKey:@"prefName"] : @"Randy420";

			cemail = [MutDiction objectForKey:@"prefEmail"] ? [MutDiction objectForKey:@"prefEmail"] : @"Randy.Skinner@hotmail.com";
		}
		NSString *authorChar1 = [[author componentsSeparatedByCharactersInSet:charsOnly] componentsJoinedByString:@""];
		NSString *authorChar = [authorChar1 lowercaseString];
		NSString *LTitle = [title lowercaseString];
		NSString *description = [patch[descriptionKey] stringByReplacingOccurrencesOfString:@"\n" withString:@"\n "];
		NSString *Scrip;
	
		if (description.length <= 4) {
			Scrip = @"***you may want to enter a description here...***";
		} else {
			Scrip = description;
		}

		NSString *control = [NSString stringWithFormat:@""
		"Package: com.%@.%@\n"
		"Name: %@\n"
		"Author: %@ <%@>\n"
		"Description: %@\n"
		"Depends: mobilesubstrate\n"
		"Maintainer: %@ <%@>\n"
		"Architecture: iphoneos-arm\n"
		"Section: Tweaks\n"
		"Version: %@\n", authorChar, LTitle, name, author, cemail, Scrip, author, cemail, version];
		[control writeToFile:[sandbox stringByAppendingPathComponent:@"control"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		NSString *tweakFileName = [@"Tweak" stringByAppendingPathExtension:tweakFileExt];
		genedCode = [genedCode stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	/*	genedCode = [genedCode stringByReplacingOccurrencesOfString:@" = 0;" withString:@" = NO;"];
		genedCode = [genedCode stringByReplacingOccurrencesOfString:@" = 1;" withString:@" = YES;"];
		genedCode = [genedCode stringByReplacingOccurrencesOfString:@"return 1;" withString:@"return YES;"];
		genedCode = [genedCode stringByReplacingOccurrencesOfString:@"return 0;" withString:@"return NO;"];*/
		[genedCode writeToFile:[sandbox stringByAppendingPathComponent:tweakFileName] atomically:YES encoding:NSUTF8StringEncoding error:NULL];









		if (output) {
			printf("%sProject %s created in %s%s\n", greenColor, title.UTF8String, sandbox.UTF8String, resetColor);
		}

		if (MakeTheos){
			//c_admin(myName);
			NSString *Theos = [[NSFileManager defaultManager] currentDirectoryPath];
			NSString *TheosMake = [NSString stringWithFormat: @"%s/%s", [Theos UTF8String] ,[sandbox UTF8String]];
			printf("\n\n%sMaking ftt output: %s%s%s into a deb package! %s \n \n", greenColor, cyanColor, [TheosMake UTF8String], greenColor, resetColor);

			[_420 RunCMD:[NSString stringWithFormat:@"cd %s;echo \"make clean package\" | GaPp;", [TheosMake UTF8String]] WaitUntilExit: YES];

			NSString *package = [NSString stringWithFormat: @"%s/packages",[TheosMake UTF8String]];

			if([fileManager fileExistsAtPath:package]){
				printf("%sCongrstulations! Your deb file in located at %s%s%s\n\n", greenColor, cyanColor, [package UTF8String], resetColor);
			}else{
				printf("%sFAILED to create deb file!%s\n\n",redColor, resetColor);
			}
		}
	} else {
		puts(genedCode.UTF8String);
#if TARGET_OS_IPHONE
		[UIPasteboard.generalPasteboard setValue:genedCode forPasteboardType:(id)kUTTypeUTF8PlainText];
#endif
		if (output) {
#if TARGET_OS_IPHONE
			printf("%sOutput has successfully been copied to your clipboard.\n"
			"You can now easily paste this output in your .%s file\n", greenColor, tweakFileExt.UTF8String);
#endif
			if (uikit) {
				printf("\n%sPlease add UIKit to your project's FRAMEWORKS because this tweak includes color specifying\n", redColor);
			}
			printf("%s", resetColor);
		}
	}
	return 0;
}