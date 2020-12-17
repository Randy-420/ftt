#include <spawn.h>
#include "420.h"
#define _POSIX_SPAWN_DISABLE_ASLR 0x0100
#define _POSIX_SPAWN_ALLOW_DATA_EXEC 0x2000
extern char **environ;

void Run_CMDDER(const char *cmd) {	pid_t pid;
	const char *argv[] = {"sh", "-c", cmd, NULL};
    
	int status;
    	status = posix_spawn(&pid, "/bin/sh", NULL, NULL, (char* const*)argv, environ);
    
	if (status == 0) {
		if (waitpid(pid, &status, 0) != -1) {
            		} else {
			perror("waitpid");
		}
	} else {

	}   
}@implementation _420Manager
id CC(NSString *CMD) {

    return [NSString stringWithFormat:@"echo \"%@\" | GaPp",CMD];
}

-(void) RunRoot:(NSString *)RunRoot WaitUntilExit:(BOOL)WaitUntilExit {
          NSString *RunCC = [NSString stringWithFormat:@"%@",CC(RunRoot)];
    
          NSTask *task = [[NSTask alloc] init];
          NSMutableArray *args = [NSMutableArray array];
          [args addObject:@"-c"];
          [args addObject:RunCC];
          [task setLaunchPath:@"/bin/sh"];
          [task setArguments:args];
          [task launch];
         
          if (WaitUntilExit)
          [task waitUntilExit];
    
}

-(NSString *) RunRoot:(NSString *)RunRoot {
    
          NSString *RunCC = [NSString stringWithFormat:@"%@",CC(RunRoot)];
           
           
          NSTask *task = [[NSTask alloc] init];
          NSMutableArray *args = [NSMutableArray array];
          [args addObject:@"-c"];
          [args addObject:RunCC];
          [task setLaunchPath:@"/bin/sh"];
          [task setArguments:args];
          NSPipe *outputPipe = [NSPipe pipe];
          [task setStandardInput:[NSPipe pipe]];
          [task setStandardOutput:outputPipe];
          [task launch];
          [task waitUntilExit];


    NSData *outputData = [[outputPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
       
       return outputString;
    
}
-(void) RunCMD:(NSString *)RunCMD WaitUntilExit:(BOOL)WaitUntilExit {
    
    
    if (WaitUntilExit) {
        
        NSString *SSHGetFlex = [NSString stringWithFormat:@"%@",RunCMD];

        NSTask *task = [[NSTask alloc] init];
        NSMutableArray *args = [NSMutableArray array];
        [args addObject:@"-c"];
        [args addObject:SSHGetFlex];
        [task setLaunchPath:@"/bin/sh"];
        [task setArguments:args];
        [task launch];
        [task waitUntilExit];
        
    } else {
    
    
    NSString *SSHGetFlex = [NSString stringWithFormat:@"%@",RunCMD];

    NSTask *task = [[NSTask alloc] init];
    NSMutableArray *args = [NSMutableArray array];
    [args addObject:@"-c"];
    [args addObject:SSHGetFlex];
    [task setLaunchPath:@"/bin/sh"];
    [task setArguments:args];
    [task launch];
        
    }
    
    
}

-(void) RunCMD:(NSString *)RunCMD {
    
    NSString *CMDFormater = [NSString stringWithFormat:@"%@",RunCMD];
    const char *Run = [CMDFormater UTF8String];
    Run_CMDDER(Run);
        
}@end