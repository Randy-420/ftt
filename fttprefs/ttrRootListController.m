#include "ttrRootListController.h"

@implementation ttrRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end

@implementation fttControl

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"fttControl" target:self];
	}

	return _specifiers;
}

-(void)Save
{
    [self.view endEditing:YES];
}

@end

@implementation fttMakefile

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"fttMakefile" target:self];
	}

	return _specifiers;
}

@end
