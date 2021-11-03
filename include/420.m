#include <spawn.h>
#include "420.h"
#define _POSIX_SPAWN_DISABLE_ASLR 0x0100
#define _POSIX_SPAWN_ALLOW_DATA_EXEC 0x2000
extern char **environ;

@implementation _420Manager
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