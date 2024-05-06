#include "Headers.h"
#include <objc/runtime.h>
#include <dlfcn.h>
#import "UIImage+GaussianBlur.h"

@implementation CSReflectionView

@end

static const char *kCSReflectionViewIdentifier;
static const char *kCSReflectionOverlayViewIdentifier;
static BOOL CSReflectionEnabled = YES;
static BOOL CSBlurReflections = NO;
static BOOL CSReflectionHeightLoaded = NO;
static CGFloat CSReflectionHeight = 0.0;
static CGFloat CSReflectionYOffset = 0.0;

static CGFloat CSFloatyDockBackgroundRadius = -1.0;

static void loadDockSettings(){
	CSReflectionEnabled = NO;
	CSBlurReflections = NO;
	CSReflectionHeightLoaded = NO;
	CSReflectionHeight = 0.0;
	CSReflectionYOffset = 0.0;
	CSFloatyDockBackgroundRadius = -1.0;

	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];
	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];

	NSNumber *reflectionEnabled = nil, *blurReflections = nil, *reflectionYoffset = nil, *floatyDockBackgroundRadius = nil;
	for (NSString *theme in themes)
	{
		NSString *path = [NSString stringWithFormat:@"%@/%@/Info.plist",themesDir,theme];
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
		if (reflectionEnabled == nil){
			reflectionEnabled = [themeDict objectForKey:@"DockReflectIcons"];
			if (reflectionEnabled)
				CSReflectionEnabled = [reflectionEnabled boolValue];
		}
		if (blurReflections == nil){
			blurReflections = [themeDict objectForKey:@"DockBlurReflections"];
			if (blurReflections)
				CSBlurReflections = [blurReflections boolValue];
		}
		if (reflectionYoffset == nil){
			reflectionYoffset = [themeDict objectForKey:@"DockReflectionOffset"];
			if (reflectionYoffset)
				CSReflectionYOffset = [reflectionYoffset floatValue];
		}
		if (floatyDockBackgroundRadius == nil){
			floatyDockBackgroundRadius = [themeDict objectForKey:@"FloatyDockBackgroundRadius"];
			if (floatyDockBackgroundRadius)
				CSFloatyDockBackgroundRadius = [floatyDockBackgroundRadius floatValue];
		}
	}
}

%group AnemonePreview
%hook ANEMSettingsManager
- (void)forceReloadNow {
	%orig;

	loadDockSettings();

	NSString *path = [[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] themedPathForImage:@"SBDockReflectionHeight"];
	CSReflectionHeight = [UIImage imageWithContentsOfFile:path].size.height;
	CSReflectionHeightLoaded = YES;

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
		if (CSReflectionHeight > 41.0f)
			CSReflectionHeight = 41.0f;
	}
	UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	BOOL isNotch = (mainWindow.safeAreaInsets.top > 24.0);
	if (isNotch){
		if (CSReflectionHeight > 19.0f)
			CSReflectionHeight = 19.0f;
	}
}
%end

%hook AnemoneIconView
- (void)configureForDisplay {
	%orig;

	if (CSReflectionEnabled && self.inDock){
		CGRect iconImageViewFrame = self.imageView.frame;

		UIImageView *reflectedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(iconImageViewFrame.origin.x, iconImageViewFrame.origin.y + iconImageViewFrame.size.height + CSReflectionYOffset, iconImageViewFrame.size.width, CSReflectionHeight)];
	    reflectedImageView.transform = CGAffineTransformMakeScale(1, -1);
	    if (CSBlurReflections)
	    	[reflectedImageView setImage:[self.imageView.image anem_imageWithGaussianBlur]];
	    else
	    	[reflectedImageView setImage:self.imageView.image];
	    reflectedImageView.contentMode = UIViewContentModeBottom;
	    reflectedImageView.clipsToBounds = YES;
	    reflectedImageView.alpha = 0.4;
	    [self addSubview:reflectedImageView];
	}
}
%end

%hook AnemoneDockBackgroundView
- (void)configureForDisplay {
	%orig;

	if (self.layer.cornerRadius != 0){
		if (CSFloatyDockBackgroundRadius >= 0){
			self.layer.cornerRadius = CSFloatyDockBackgroundRadius;
		}
	}
}
%end

%hook AnemoneDockOverlayView
- (void)configureForDisplay {
	%orig;

	if (self.layer.cornerRadius != 0){
		if (CSFloatyDockBackgroundRadius >= 0){
			self.layer.cornerRadius = CSFloatyDockBackgroundRadius;
		}
	}
}
%end
%end

%group AnemoneDock

%hook ANEMSettingsManager
- (void)forceReloadNow {
	%orig;

	loadDockSettings();
}
%end

%hook SBDockView
- (void)_updateCornerRadii {
	if (CSFloatyDockBackgroundRadius < 0) {
		%orig;
	} else {
		UICornerRadiusView *_backgroundView = [self valueForKey:@"_backgroundView"]; //A5 and higher
		[_backgroundView _setContinuousCornerRadius:0];

		_backgroundView = [self valueForKey:@"_backgroundImageView"]; //iPhone 4
		[_backgroundView _setContinuousCornerRadius:0];

		_backgroundView = [self valueForKey:@"_accessibilityBackgroundView"]; //iPhone 4
		[_backgroundView _setContinuousCornerRadius:0];
	}
}
%end

%hook SBIconView
%new;
- (void)anemoneInit {
	self.clipsToBounds = NO;

	CGRect frame = CGRectMake(2, 59, 62, 62);
	CSReflectionView *reflectionView = [[CSReflectionView alloc] initWithFrame:frame];
	reflectionView.clipsToBounds = YES;
	objc_setAssociatedObject(self, &kCSReflectionViewIdentifier, reflectionView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self addSubview:reflectionView];

	CSReflectionView *reflectionOverlayView = [[CSReflectionView alloc] initWithFrame:frame];
	reflectionOverlayView.clipsToBounds = YES;
	objc_setAssociatedObject(self, &kCSReflectionOverlayViewIdentifier, reflectionOverlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self addSubview:reflectionOverlayView];

	[self updateReflection];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateReflection) name:@"AnemoneReloadNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceUpdateReflection) name:@"AnemoneReloadNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOverlayReflection) name:@"AnemoneReloadNotification" object:nil];
}

- (id)initWithContentType:(NSUInteger)type {
	self = %orig;
	if (self){
		[self anemoneInit];
	}
	return self;
}

- (id)initWithConfigurationOptions:(NSUInteger)options listLayoutProvider:(id)arg2 {
	self = %orig;
	if (self){
		[self anemoneInit];
	}
	return self;
}

- (void)layoutSubviews {
	%orig;
	[self updateReflection];
}

%new;
-(void)forceUpdateReflection {
	CSReflectionView *reflectionView = objc_getAssociatedObject(self, &kCSReflectionViewIdentifier);
	if (!CSReflectionEnabled){
		reflectionView.image = nil;
		return;
	}
	if ([self isInDock]){
		reflectionView.image = [[self _iconImageView] contentsImage];
		if (CSBlurReflections) {
			reflectionView.image = [reflectionView.image anem_imageWithGaussianBlur];
		}
	} else {
		reflectionView.image = nil;
	}
}

%new;
- (void)updateOverlayReflection {
	if (!CSReflectionEnabled)
		return;
	if ([self isInDock]){
		CSReflectionView *reflectionOverlayView = objc_getAssociatedObject(self, &kCSReflectionOverlayViewIdentifier);
		reflectionOverlayView.image = [[self _iconImageView] _currentOverlayImage];
	}
}

- (void)setHighlighted:(BOOL)highlighted {
	%orig;
	if ([self isInDock]){
		CSReflectionView *reflectionOverlayView = objc_getAssociatedObject(self, &kCSReflectionOverlayViewIdentifier);
		if (highlighted)
			reflectionOverlayView.alpha = 0.3;
		else
			reflectionOverlayView.alpha = 0;
	}
}

%new;
- (void)updateReflection {
	CSReflectionView *reflectionView = objc_getAssociatedObject(self, &kCSReflectionViewIdentifier);
	CSReflectionView *reflectionOverlayView = objc_getAssociatedObject(self, &kCSReflectionOverlayViewIdentifier);
	if (!CSReflectionEnabled){
		reflectionView.image = nil;
		reflectionView.alpha = 0;
		reflectionOverlayView.alpha = 0;
		return;
	}
	if ([self isInDock]){
		if (!reflectionView.image){
			reflectionView.image = [[self _iconImageView] contentsImage];
			if (CSBlurReflections) {
				reflectionView.image = [reflectionView.image anem_imageWithGaussianBlur];
			}
			reflectionOverlayView.image = [[self _iconImageView] _currentOverlayImage];
		}
		reflectionView.alpha = 0.4;
		reflectionOverlayView.alpha = 0.4;

		BOOL useiPhoneLandscapeTransform = NO;
		if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad){
			if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])){
				useiPhoneLandscapeTransform = YES;
			}
		}

		if (!useiPhoneLandscapeTransform){
			if (reflectionView.contentMode != UIViewContentModeBottom){
				reflectionView.transform = CGAffineTransformMakeScale(1, -1);
				reflectionView.contentMode = UIViewContentModeBottom;
				reflectionOverlayView.transform = CGAffineTransformMakeScale(1, -1);
				reflectionOverlayView.contentMode = UIViewContentModeBottom;
			}
		} else {
			if (reflectionView.contentMode != UIViewContentModeRight){
				reflectionView.transform = CGAffineTransformMakeScale(-1, 1);
				reflectionView.contentMode = UIViewContentModeRight;
				reflectionOverlayView.transform = CGAffineTransformMakeScale(-1, 1);
				reflectionOverlayView.contentMode = UIViewContentModeRight;
			}
		}

		if ([self isHighlighted])
			reflectionOverlayView.alpha = 0.3;
		else
			reflectionOverlayView.alpha = 0;
		CGRect frame = reflectionView.frame;
		if (!CSReflectionHeightLoaded){
			NSString *path = [[NSBundle mainBundle] themedPathForImage:@"SBDockReflectionHeight"];
			CSReflectionHeight = [UIImage imageWithContentsOfFile:path].size.height;
			CSReflectionHeightLoaded = YES;

			if ([%c(SBFloatingDockController) isFloatingDockSupported]){
				if (CSReflectionHeight > 41.0f)
					CSReflectionHeight = 41.0f;
			}
			UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
			BOOL isNotch = (mainWindow.safeAreaInsets.top > 24.0);
			if (isNotch){
				if (CSReflectionHeight > 39.0f)
					CSReflectionHeight = 39.0f;
			}
		}
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
			frame.origin.x = [self _iconImageView].frame.origin.x;
			frame.origin.y = [self _iconImageView].frame.size.height + 1.0f + CSReflectionYOffset;
			frame.size.height = CSReflectionHeight - 21.f - (76.0 - [self _iconImageView].frame.size.height)/3.f;
			frame.size.width = reflectionView.image.size.width;
		} else {
			if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])){
				frame.origin.x = [self _iconImageView].frame.origin.x;
				frame.origin.y = 59.0f + CSReflectionYOffset;
				frame.size.height = CSReflectionHeight-21;
				frame.size.width = reflectionView.image.size.width;
			} else {
				frame.origin.x = 59.0f + CSReflectionYOffset;
				frame.origin.y = [self _iconImageView].frame.origin.y;
				frame.size.height = reflectionView.image.size.height;
				frame.size.width = CSReflectionHeight-21;
			}
		}
		reflectionView.frame = frame;
		reflectionOverlayView.frame = frame;
	} else {
		reflectionView.image = nil;
		reflectionView.alpha = 0;
		reflectionOverlayView.alpha = 0;
	}
}

%new
- (void)setReflectionVisible:(BOOL)visible {
	if (!visible || !CSReflectionEnabled){
		CSReflectionView *reflectionView = objc_getAssociatedObject(self, &kCSReflectionViewIdentifier);
		CSReflectionView *reflectionOverlayView = objc_getAssociatedObject(self, &kCSReflectionOverlayViewIdentifier);
		reflectionView.alpha = 0;
		reflectionOverlayView.alpha = 0;
	} else {
		if (!CSReflectionEnabled)
			return;
		[self updateReflection];
	}
}

%end

%hook SBIconImageView
- (void)layoutSubviews {
	%orig;
	if ([self.superview isKindOfClass:[%c(SBIconView) class]])
		[(SBIconView *)self.superview updateReflection];
}

- (void)setIcon:(id)icon location:(int)location animated:(BOOL)animated {
	%orig;
	if ([self.superview isKindOfClass:[%c(SBIconView) class]]){
		[(SBIconView *)self.superview forceUpdateReflection];
		[(SBIconView *)self.superview updateOverlayReflection];
	}
}
%end

%hook SBHighlightView
-(id)initWithFrame:(CGRect)frame highlightAlpha:(float)alpha highlightHeight:(float)alpha2 {
	self = %orig;
	self.alpha=0;
	return self;
}

- (void)setAlpha:(float)alpha {
	%orig(0);
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
