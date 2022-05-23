#include <spawn.h>
#include "420.h"

#define _POSIX_SPAWN_DISABLE_ASLR 0x0100
#define _POSIX_SPAWN_ALLOW_DATA_EXEC 0x2000
extern char **environ;
@implementation HookSorter
@end

@implementation _420Manager
-(NSString *)cleanUp:(NSString *)cleanUp{
	NSString *input = cleanUp;

	NSMutableArray <HookSorter *> *hooks = [NSMutableArray new];

	NSString *pattern = @"(^%hook)(.*?)(?=%end$)";

	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionDotMatchesLineSeparators | NSRegularExpressionAnchorsMatchLines error:NULL];

	NSArray *myArray = [regex matchesInString:input options:0 range:NSMakeRange(0, [input length])];
	NSMutableArray *getCtor = [[input componentsSeparatedByString:@"\n"] mutableCopy];

	NSMutableArray *addCtor = [[NSMutableArray alloc] init];

	BOOL ctorFound = NO;

	for (NSString *s in getCtor){
		if (ctorFound || [s isEqualToString:@"%ctor {"]){
			ctorFound = YES;
			[addCtor addObject:s];
		}
	}

	for (NSTextCheckingResult *match in myArray) {
//get the range starting after "%hook"
		NSRange matchRange = [match rangeAtIndex:2];
//add 1 for the space
		matchRange.location += 1;
		matchRange.length -= 1;
//get the "block" string
		NSString *s = [input substringWithRange:matchRange];
//split it by newLines
		NSArray <NSString *> *a = [s componentsSeparatedByString:@"\n"];
//we want the "body" to skip the first line
		NSRange r;
		r.location = 1;
		r.length = [a count] - 1;
//get the lines excluding the first line
		NSArray <NSString *> *a2 = [a subarrayWithRange:r];
//new HookSorter object
		HookSorter *b = [HookSorter new];
		b.hookName = [a firstObject];
		b.hookBody = [a2 componentsJoinedByString:@"\n"];
		[hooks addObject:b];
	}

//sort the array of hooks by hookName
	NSArray <HookSorter *> *hookSorter;
	hookSorter = [hooks sortedArrayUsingComparator:^NSComparisonResult(HookSorter *a, HookSorter *b) {
		return [a.hookName compare:b.hookName];
	}];

	NSMutableString *output = [NSMutableString new];

	BOOL importChecked = NO;

	NSString *currentHook = @"";

//loop through the array of hooks
	for (int i = 0; i < [hookSorter count]; i++) {
		HookSorter *b = hookSorter[i];
//if we're at a "new" hookName
		if (![currentHook isEqualToString:b.hookName]) {
			currentHook = b.hookName;
//add %end if output is not ""
			if ([output length] != 0) {
				[output appendString:@"%end\n"];
			}
			NSMutableArray *getInc = [[input componentsSeparatedByString:@"\n"] mutableCopy];
			//make sure to grab the #imports && #includes
			if (!importChecked){
				for (NSString *inc in getInc){
					if ([inc hasPrefix:@"#import"] || [inc hasPrefix:@"#include"]) {
						[output appendFormat:@"%@\n", inc];
					}
				}
				importChecked = YES;
			}
//add a new line - %hook hookName
			[output appendFormat:@"\n%%hook %@", currentHook];
		}
//add the hook body
		[output appendFormat:@"\n%@", b.hookBody];
	}
//"close" the last hook
		[output appendString:@"%end"];
	if (!(addCtor.count == 0))
		[output appendString:@"\n\n"];
//add the ctor if it exists
	for (NSString *s in addCtor){
			[output appendFormat:@"%@", s];
		if (![s isEqualToString:@"}"])
			[output appendFormat:@"\n"];
	}

	return output;
}

-(void) RunCMD:(NSString *)RunCMD WaitUntilExit:(BOOL)WaitUntilExit {
	NSString *SSHGetFlex = [NSString stringWithFormat:@"%@",RunCMD];

	NSTask *task = [[NSTask alloc] init];
	NSMutableArray *args = [NSMutableArray array];
	[args addObject:@"-c"];
	[args addObject:SSHGetFlex];
	[task setLaunchPath:@"/bin/sh"];
	[task setArguments:args];
	[task launch];
	if (WaitUntilExit)
		[task waitUntilExit];
}
@end