#import "../core/ANEMSettingsManager.h"
#import <dlfcn.h>

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
    
    if (objc_getClass("ANEMSettingsManager") == nil){
        dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
    }

    [[%c(ANEMSettingsManager) sharedManager] setCGImageHookEnabled:YES];
}