#import "../core/ANEMSettingsManager.h"
#import "../core/Bundle.h"
#import <dlfcn.h>
#include "Headers.h"

static const char *kCSBlurMaskViewIdentifier;
static const char *kCSBlurOverlayViewIdentifier;

static UIImage *getMask(NSBundle *bundle){
	UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	BOOL isNotch = (mainWindow.safeAreaInsets.top > 24.0);

	BOOL isiPhone6 = ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) && ([[UIScreen mainScreen] bounds].size.width > 350);
	BOOL isiPhone6Plus = ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) && ([[UIScreen mainScreen] bounds].size.width > 400);

	UIImage *mask = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockMask"]];
	if (isNotch){
		if (isiPhone6Plus)
			mask = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockMask-896h"]];
		else if (isiPhone6)
			mask = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockMask-812h"]];
	} else {
		if (isiPhone6Plus)
			mask = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockMask-736h"]];
		else if (isiPhone6)
			mask = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockMask-667h"]];
	}
	return mask;
}

static UIImage *getOverlay(NSBundle *bundle){
	UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	BOOL isNotch = (mainWindow.safeAreaInsets.top > 24.0);

	BOOL isiPhone6 = ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) && ([[UIScreen mainScreen] bounds].size.width > 350);
	BOOL isiPhone6Plus = ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) && ([[UIScreen mainScreen] bounds].size.width > 400);

	UIImage *overlay = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockOverlay"]];
	if (isNotch){
		if (isiPhone6Plus)
			overlay = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockOverlay-896h"]];
		else if (isiPhone6)
			overlay = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockOverlay-812h"]];
	} else {
		if (isiPhone6Plus)
			overlay = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockOverlay-736h"]];
		else if (isiPhone6)
			overlay = [UIImage imageWithContentsOfFile:[bundle themedPathForImage:@"ModernDockOverlay-667h"]];
	}
	return overlay;
}

%group AnemonePreview
%hook AnemoneDockBackgroundView
- (instancetype) initWithFrame:(CGRect)frame autosizesToFitSuperview:(BOOL)autosizesToFitSuperview settings:(_UIBackdropViewSettings *)settings {
	UIImage *maskImage = getMask([NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"]);

	[settings setFilterMaskImage:maskImage];
	[settings setColorTintMaskImage:maskImage];
	[settings setGrayscaleTintMaskImage:maskImage];
	[settings setDarkeningTintMaskImage:maskImage];

	return %orig();
}
%end

%hook AnemoneDockOverlayView
- (void)configureForDisplay {
	%orig;

	UIImage *mask = getMask([NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"]);
	UIImageView *maskView = [[UIImageView alloc] initWithImage:mask];
	maskView.frame = self.bounds;
	self.layer.mask = maskView.layer;

	UIImage *overlay = getOverlay([NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"]);
	UIImageView *overlayView = [[UIImageView alloc] initWithImage:overlay];
	overlayView.frame = self.frame;
	[self.superview insertSubview:overlayView aboveSubview:self];
}
%end
%end

%group AnemoneDock
%hook SBDockView
- (id)initWithDockListView:(id)dockListView forSnapshot:(BOOL)snapshot {
	%orig;
	if (self){
		UIImageView *maskImageView = [[UIImageView alloc] init];
		[maskImageView.layer setValue:maskImageView forKey:@"view"];

		UIImageView *modernOverlayView = [[UIImageView alloc] init];
		modernOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		modernOverlayView.frame = CGRectMake(0,0,self.bounds.size.width,96);
		modernOverlayView.contentMode = UIViewContentModeScaleToFill;
		objc_setAssociatedObject(self, &kCSBlurOverlayViewIdentifier, modernOverlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		objc_setAssociatedObject(self, &kCSBlurMaskViewIdentifier, maskImageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutSubviews) name:@"AnemoneReloadNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_updateCornerRadii) name:@"AnemoneReloadNotification" object:nil];
	}
	return self;
}

- (void)layoutSubviews {
	%orig;

	UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	BOOL isNotch = (mainWindow.safeAreaInsets.top > 24.0);

	UIImageView *maskImageView = objc_getAssociatedObject(self, &kCSBlurMaskViewIdentifier);
	maskImageView.image = getMask([NSBundle mainBundle]);

	if (self.bounds.size.width < self.bounds.size.height){
		maskImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -(M_PI/2.0));
	} else {
		maskImageView.transform = CGAffineTransformIdentity;
	}
	maskImageView.frame = self.bounds;

	UIImageView *modernOverlayView = objc_getAssociatedObject(self, &kCSBlurOverlayViewIdentifier);
	modernOverlayView.contentMode = UIViewContentModeScaleToFill;

	[modernOverlayView removeFromSuperview];
	UIImageView *_backgroundView = [self valueForKey:@"_backgroundView"]; //A5 and higher
	if (!_backgroundView){
		_backgroundView = [self valueForKey:@"_backgroundImageView"]; //iPhone 4
		if (!_backgroundView){
			_backgroundView = [self valueForKey:@"_accessibilityBackgroundView"]; //A5 and higher
		}
	}

	if (_backgroundView){
		if (maskImageView.image){
			CGRect frame = maskImageView.frame;
			if (isNotch)
				frame.size.width = _backgroundView.bounds.size.width;
			else
				frame.size.width = self.bounds.size.width;
			frame.origin.x = (_backgroundView.bounds.size.width - frame.size.width) / 2.0;
			maskImageView.frame = frame;
			_backgroundView.layer.mask = maskImageView.layer;
		} else {
			_backgroundView.layer.mask = nil;
		}
		[_backgroundView addSubview:modernOverlayView];
	}

	modernOverlayView.image = getOverlay([NSBundle mainBundle]);

	if (self.bounds.size.width < self.bounds.size.height){
		modernOverlayView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -(M_PI/2.0));
	} else {
		modernOverlayView.transform = CGAffineTransformIdentity;
	}
	modernOverlayView.frame = maskImageView.frame;
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
	if (objc_getClass("ANEMSettingsManager") == nil){
		dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
	}

	if (objc_getClass("SBIconView")){
		%init(AnemoneDock);
	} else {
		%init(AnemonePreview);
	}
}