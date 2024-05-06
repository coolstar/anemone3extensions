#import "core/ANEMSettingsManager.h"
#import "core/Bundle.h"
#import "UIColor+HTMLColors.h"
#import <dlfcn.h>

static NSMutableDictionary *badgeSettings = nil;
static BOOL badgeSettingsLoaded = NO;

static NSString *badgeFont = nil;
static CGFloat badgeFontSize = 16.0f;
static CGFloat badgeHeightChange = 0.0f; //0.0f for classic
static CGFloat badgeWidthChange = 0.0f; //2.0f for classic
static CGFloat badgeXoffset = 0.0f; //2.0f for classic
static CGFloat badgeYoffset = 0.0f; //-2.0f for classic
static CGFloat badgeTextShadowXoffset = 0.0f;
static CGFloat badgeTextShadowYoffset = 0.0f;
static CGFloat badgeTextShadowBlurRadius = 0.0f;
static UIColor *badgeTextColor = nil;
static UIColor *badgeTextShadowColor = nil;
static NSString *badgeTextCase = nil;

static UIImage *badgeImage = nil;

static void getBadgeImage(){
	NSString *path = [[NSBundle mainBundle] themedPathForImage:@"SBBadgeBG"];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	if (image)
		badgeImage = image;
}

static void getBadgeSettings()
{
	badgeSettingsLoaded = YES;
	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];
	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];

	for (NSString *theme in themes)
	{
		NSString *path = [NSString stringWithFormat:@"%@/%@/Info.plist",themesDir,theme];
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
		if (themeDict[@"BadgeSettings"] != nil)
		{
			badgeSettings = [themeDict[@"BadgeSettings"] mutableCopy];
			return;
		}
		if (themeDict[@"ThemeLib-BadgeSettings"] != nil)
		{
			badgeSettings = [themeDict[@"ThemeLib-BadgeSettings"] mutableCopy];
			return;
		}
	}
}

static void loadBadgeSettings(){
	if (badgeSettingsLoaded)
		return;

	badgeTextCase = nil;

	badgeFont = @".SFUIText";

	badgeTextColor = [UIColor whiteColor];
	badgeTextShadowColor = [UIColor clearColor];

	getBadgeSettings();
	getBadgeImage();
	if ([[badgeSettings objectForKey:@"FontName"] isKindOfClass:[NSString class]])
		badgeFont = [badgeSettings objectForKey:@"FontName"];
	if ([[badgeSettings objectForKey:@"FontSize"] isKindOfClass:[NSNumber class]])
		badgeFontSize = [[badgeSettings objectForKey:@"FontSize"] floatValue];
	if ([[badgeSettings objectForKey:@"HeightChange"] isKindOfClass:[NSNumber class]])
		badgeHeightChange = [[badgeSettings objectForKey:@"HeightChange"] floatValue];
	if ([[badgeSettings objectForKey:@"WidthChange"] isKindOfClass:[NSNumber class]])
		badgeWidthChange = [[badgeSettings objectForKey:@"WidthChange"] floatValue];
	if ([[badgeSettings objectForKey:@"TextXoffset"] isKindOfClass:[NSNumber class]])
		badgeXoffset = [[badgeSettings objectForKey:@"TextXoffset"] floatValue];
	if ([[badgeSettings objectForKey:@"TextYoffset"] isKindOfClass:[NSNumber class]])
		badgeYoffset = [[badgeSettings objectForKey:@"TextYoffset"] floatValue];
	if ([[badgeSettings objectForKey:@"RawTextColor"] isKindOfClass:[UIColor class]])
		badgeTextColor = [badgeSettings objectForKey:@"RawTextColor"];
	else if ([[badgeSettings objectForKey:@"TextColor"] isKindOfClass:[NSString class]]){
		badgeTextColor = [UIColor anem_colorWithCSS:[badgeSettings objectForKey:@"TextColor"]];
		[badgeSettings setObject:badgeTextColor forKey:@"RawTextColor"];
	}
	if ([[badgeSettings objectForKey:@"TextCase"] isKindOfClass:[NSString class]])
		badgeTextCase = [[badgeSettings objectForKey:@"TextCase"] lowercaseString];
	if ([[badgeSettings objectForKey:@"ShadowXoffset"] isKindOfClass:[NSNumber class]])
		badgeTextShadowXoffset = [[badgeSettings objectForKey:@"ShadowXoffset"] floatValue];
	if ([[badgeSettings objectForKey:@"ShadowYoffset"] isKindOfClass:[NSNumber class]])
		badgeTextShadowYoffset = [[badgeSettings objectForKey:@"ShadowYoffset"] floatValue];
	if ([[badgeSettings objectForKey:@"ShadowBlurRadius"] isKindOfClass:[NSNumber class]])
		badgeTextShadowBlurRadius = [[badgeSettings objectForKey:@"ShadowBlurRadius"] floatValue];
	if ([[badgeSettings objectForKey:@"RawShadowColor"] isKindOfClass:[UIColor class]])
		badgeTextShadowColor = [badgeSettings objectForKey:@"RawShadowColor"];
	else if ([[badgeSettings objectForKey:@"ShadowColor"] isKindOfClass:[NSString class]]){
		badgeTextShadowColor = [UIColor anem_colorWithCSS:[badgeSettings objectForKey:@"ShadowColor"]];
		[badgeSettings setObject:badgeTextShadowColor forKey:@"RawShadowColor"];
	}
}

@interface SBIconAccessoryImage : UIImage
- (id)initWithImage:(UIImage *)image;
@end

@interface SBDarkeningImageView
@property (nonatomic, retain) UIImage *image;
@end

@interface SBIconBadgeView : UIView
+ (SBIconAccessoryImage *)_checkoutBackgroundImage;
- (SBIconAccessoryImage *)_checkoutBackgroundImage;
- (void)resetBadge;
@end

@interface SBIconView : UIView
- (void)reloadBadge;
- (void)_updateAccessoryViewWithAnimation:(BOOL)animation;
@end

%group SpringBoard
%hook ANEMSettingsManager
- (void)forceReloadNow {
	badgeSettings = nil;
	badgeSettingsLoaded = NO;

	badgeFont = nil;
	badgeFontSize = 16.0f;
	badgeHeightChange = 0.0f; //0.0f for classic
	badgeWidthChange = 0.0f; //2.0f for classic
	badgeXoffset = 0.0f; //2.0f for classic
	badgeYoffset = 0.0f; //-2.0f for classic
	badgeTextShadowXoffset = 0.0f;
	badgeTextShadowYoffset = 0.0f;
	badgeTextShadowBlurRadius = 0.0f;
	badgeTextColor = nil;
	badgeTextShadowColor = nil;
	badgeTextCase = nil;

	badgeImage = nil;

	%orig;

	loadBadgeSettings();
}
%end

%hook SBIconView
- (id)initWithContentType:(NSUInteger)type {
	self = %orig;
	if (self){
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadBadge) name:@"AnemoneReloadNotification" object:nil];
	}
	return self;
}

%new;
- (void)reloadBadge {
	[self _updateAccessoryViewWithAnimation:NO];
}
%end

%hook SBIconBadgeView

+ (SBIconAccessoryImage *)_checkoutBackgroundImage {
	if (badgeImage)
		return [[%c(SBIconAccessoryImage) alloc] initWithImage:badgeImage];
	else
		return %orig;
}

- (SBIconAccessoryImage *)_checkoutBackgroundImage {
	if (badgeImage)
		return [[%c(SBIconAccessoryImage) alloc] initWithImage:badgeImage];
	else
		return %orig;
}

+ (SBIconAccessoryImage *)_checkoutImageForText:(NSString *)text highlighted:(BOOL)highlighted {
	loadBadgeSettings();

	UIFont *font = [UIFont fontWithName:badgeFont size:badgeFontSize];
	CGSize size = [text sizeWithAttributes:@{NSFontAttributeName:font}];
	if (size.height != 0)
		size.height += badgeHeightChange;
	if (size.width != 0)
		size.width += badgeWidthChange;
	if (size.width == 0 || size.height == 0)
		return %orig;
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetShadowWithColor(ctx, CGSizeMake(badgeTextShadowXoffset,badgeTextShadowYoffset), badgeTextShadowBlurRadius, badgeTextShadowColor.CGColor);
	
	if ([badgeTextCase isEqualToString:@"lowercase"])
		text = [text lowercaseString];
	else if ([badgeTextCase isEqualToString:@"uppercase"])
		text = [text uppercaseString];

	[text drawAtPoint:CGPointMake(badgeXoffset,badgeYoffset) withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:badgeTextColor}];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [[%c(SBIconAccessoryImage) alloc] initWithImage:image];
}

- (void)configureForIcon:(id)arg2 infoProvider:(id)arg3 {
	SBDarkeningImageView *backgroundView = [self valueForKey:@"_backgroundView"];

	SBIconAccessoryImage *backgroundImage = nil;
	if ([self respondsToSelector:@selector(_checkoutBackgroundImage)])
		backgroundImage = [self _checkoutBackgroundImage]; //iOS 13
	else
		backgroundImage = [%c(SBIconBadgeView) _checkoutBackgroundImage];
	
	UIImage *currentBackgroundImage = backgroundView.image;
	currentBackgroundImage = backgroundView.image;

	[self setValue:backgroundImage forKey:@"_backgroundImage"];

	UIEdgeInsets capInsets = currentBackgroundImage.capInsets;
	backgroundView.image = [backgroundImage resizableImageWithCapInsets:capInsets];

	%orig;
}

%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return;
	if (objc_getClass("SBIconBadgeView") != nil){
		dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);
		
		%init(SpringBoard);
	}
}