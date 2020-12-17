#import <UIKit/UIKit.h>

bool c_admin(char name[]) {

    const char *cyanColor = "\x1B[36m";
    const char *redColor = "\x1B[31m";
//    const char *greenColor = "\x1B[32m";
    const char *resetColor = "\x1B[0m";

    NSString *adminhelp= [NSString stringWithFormat: @"%s%s requires root access to run.\nenter:\n%ssu \npassword%s (default:'%salpine%s')\n", redColor, name, cyanColor, resetColor, cyanColor, resetColor];

/////////////////////////////////////////////
////         Admin handling              ////
/////////////////////////////////////////////

   if (getuid()){
      printf("%s",[adminhelp UTF8String]);
      exit(1);
   }
return true;
}