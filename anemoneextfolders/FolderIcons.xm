#import "../core/ANEMSettingsManager.h"
#import "../core/Bundle.h"
#import "../core/AnemoneExtensionParameters.h"
static BOOL enableFolderIcons = NO;

@interface UIImage (Bundle)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

@interface SBFolderIcon : NSObject
- (id)displayName;
- (id)displayNameForLocation:(int)location;
@end

@interface SBFolderIconImageView : UIView
- (SBFolderIcon *)_folderIcon;
- (UIView *)backgroundView;
- (void)setIconGridImageAlpha:(CGFloat)alpha;
- (UIImage *)squareDarkeningOverlayImage;
- (void)ANEMresetIcon;
@end

static char *FolderIconBG;
static char *FolderIconOverlay;
static char *FolderIconMask;

static BOOL FolderIconsLoaded = NO;
static UIImage *FolderOverlayImage = nil;
static UIImage *FolderMaskImage = nil;
static float FolderMaskRadius = 0.0;
static BOOL FolderMaskRadiusSet = NO;
static CGFloat FolderGridImageAlpha = 1.0;

static CGFloat DefaultFolderRadius = 0.0;

static void LoadFolderIcons(){
	if (FolderIconsLoaded)
		return;

	UIImage *overlayImage = nil;
	NSNumber *maskRadius = nil;
	NSNumber *gridImageAlpha = nil;

	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];
	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];
	for (NSString *theme in themes)
	{
		NSString *deviceName = @"iPhone";
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			deviceName = @"iPad";

		if (!overlayImage){
			NSString *overlayPath = [NSString stringWithFormat:@"%@/%@/AnemoneEffects/%@Overlay.png",themesDir,theme,deviceName];
			overlayImage = [UIImage imageWithContentsOfFile:overlayPath];
		}

		if (!maskRadius){
			NSString *path = [NSString stringWithFormat:@"%@/%@/Info.plist",themesDir,theme];
			NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
			if (themeDict[@"FolderIconMaskRadius"] != nil)
			{
				maskRadius = themeDict[@"FolderIconMaskRadius"];
			}
			if (themeDict[@"FolderIconMaskRadius~ipad"] != nil && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			{
				maskRadius = themeDict[@"FolderIconMaskRadius~ipad"];
			}
			if (themeDict[@"FolderIconMaskRadius~ipadpro"] != nil &&
			 [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad &&
			  MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) == 1366)
			{
				maskRadius = themeDict[@"FolderIconMaskRadius~ipadpro"];
			}
			if (themeDict[@"FolderGridImageAlpha"] != nil)
			{
				gridImageAlpha = themeDict[@"FolderGridImageAlpha"];
			}
		}

		if (overlayImage && maskRadius && gridImageAlpha)
			break;
	}

	UIImage *mask = nil;
	NSBundle *mobileIconsBundle = [NSBundle bundleWithIdentifier:@"com.apple.mobileicons.framework"];
	if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
		mask = [UIImage imageNamed:@"AppIconMask~iphone" inBundle:mobileIconsBundle];
	else {
		mask = [UIImage imageNamed:@"AppIconMask~ipad" inBundle:mobileIconsBundle];
		if (MAX([[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height) == 1366)
			mask = [UIImage imageNamed:@"AppIconMask-RFB~ipad" inBundle:mobileIconsBundle];
	}

	FolderOverlayImage = overlayImage;
	FolderMaskImage = mask;
	FolderIconsLoaded = YES;
	if (maskRadius){
		FolderMaskRadius = [maskRadius floatValue];
		FolderMaskRadiusSet = YES;
	}
	if (gridImageAlpha)
		FolderGridImageAlpha = [gridImageAlpha floatValue];
}

%group AnemonePreview
%hook ANEMSettingsManager
- (void)forceReloadNow {
	FolderIconsLoaded = NO;
	FolderOverlayImage = nil;
	FolderMaskImage = nil;
	FolderMaskRadius = 0.0;
	FolderMaskRadiusSet = NO;
	FolderGridImageAlpha = 1.0;

	%orig;

	LoadFolderIcons();
}
%end

%hook AnemoneFolderIconView
- (void)configureForDisplay {
	%orig;

	if (FolderMaskRadiusSet){
		self.backdropView.layer.cornerRadius = FolderMaskRadius;
		self.backdropOverlayView.layer.cornerRadius = FolderMaskRadius;
	}

	NSString *name = self.iconLabel.text;

	UIImage *folderIconBG = [UIImage imageWithContentsOfFile:[[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] themedPathForImage:[NSString stringWithFormat:@"ANEMFolderIconBG-%@",name]]];
	if (!folderIconBG)
		folderIconBG = [UIImage imageWithContentsOfFile:[[NSBundle bundleWithPath:@"/System/Library/CoreServices/SpringBoard.app"] themedPathForImage:@"ANEMFolderIconBG"]];
	if (folderIconBG){
		self.backdropView.alpha = 0;
		self.backdropOverlayView.alpha = 0;
		self.iconView.image = folderIconBG;
	}


	UIImageView *overlayView = [[UIImageView alloc] initWithFrame:self.iconView.bounds];
	overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[overlayView setImage:FolderOverlayImage];
	[self.iconView addSubview:overlayView];
}
%end
%end

%group FoldersHook
%hook ANEMSettingsManager
- (void)forceReloadNow {
	FolderIconsLoaded = NO;
	FolderOverlayImage = nil;
	FolderMaskImage = nil;
	FolderMaskRadius = 0.0;
	FolderMaskRadiusSet = NO;
	FolderGridImageAlpha = 1.0;

	%orig;

	LoadFolderIcons();
}
%end

%hook SBFolderIconImageView
- (SBFolderIconImageView *)initWithFrame:(CGRect)frame {
	%orig;
	LoadFolderIcons();

	if (DefaultFolderRadius == 0.0)
		DefaultFolderRadius = [self backgroundView].layer.cornerRadius;

	UIImageView *iconView = [[UIImageView alloc] initWithFrame:self.bounds];
	iconView.contentMode = UIViewContentModeCenter;
	iconView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self insertSubview:iconView aboveSubview:[self backgroundView]];
	
	objc_setAssociatedObject(self, &FolderIconBG, iconView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	UIImageView *overlayView = [[UIImageView alloc] initWithFrame:self.bounds];
	overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[overlayView setImage:FolderOverlayImage];
	objc_setAssociatedObject(self, &FolderIconOverlay, overlayView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self addSubview:overlayView];

	[self setIconGridImageAlpha:1.0];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ANEMresetIcon) name:@"AnemoneReloadNotification" object:nil];

	return self;
}

%new;
- (void)ANEMresetIcon {
	NSString *name = nil;
	SBFolderIcon *icon = [self _folderIcon];
	if ([icon respondsToSelector:@selector(displayName)])
		name = [icon displayName];
	else
		name = [icon displayNameForLocation:0];

	UIImage *folderIconBG = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] themedPathForImage:[NSString stringWithFormat:@"ANEMFolderIconBG-%@",name]]];
	if (!folderIconBG)
		folderIconBG = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] themedPathForImage:@"ANEMFolderIconBG"]];

	if (FolderMaskRadiusSet){
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			[[self backgroundView].layer setCornerRadius:FolderMaskRadius * self.bounds.size.width / 76.0f];
		else
			[[self backgroundView].layer setCornerRadius:FolderMaskRadius];
	}
	else if (DefaultFolderRadius != 0.0)
		[[self backgroundView].layer setCornerRadius:DefaultFolderRadius];

	UIImageView *iconView = objc_getAssociatedObject(self, &FolderIconBG);
	[iconView setImage:folderIconBG];
	if (folderIconBG)
		[[self backgroundView] setAlpha:0];
	else
		[[self backgroundView] setAlpha:1];

	UIImageView *overlayView = objc_getAssociatedObject(self, &FolderIconOverlay);
	[overlayView setImage:FolderOverlayImage];

	[self setIconGridImageAlpha:1.0];
}

-(void)setIcon:(SBFolderIcon *)icon location:(int)location animated:(BOOL)animated {
	%orig;
	
	[self ANEMresetIcon];
}

-(void)_updateOverlayImage {
	%orig;
	if (FolderMaskRadiusSet){
		UIImageView *_overlayView = [self valueForKey:@"_overlayView"];
		[_overlayView setImage:[self squareDarkeningOverlayImage]];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			[_overlayView.layer setCornerRadius:FolderMaskRadius * self.bounds.size.width / 76.0f];
		else
			[_overlayView.layer setCornerRadius:FolderMaskRadius];
		[_overlayView setClipsToBounds:YES];
	}

	[self setIconGridImageAlpha:1.0];
}

-(void)setFloatyFolderCrossfadeFraction:(CGFloat)fraction {
	%orig;
	CGFloat alpha = 1.0f - fraction;
	UIImageView *iconView = objc_getAssociatedObject(self, &FolderIconBG);
	iconView.alpha = alpha;
	UIImageView *overlayView = objc_getAssociatedObject(self, &FolderIconOverlay);
	overlayView.alpha = alpha;
}

- (void)setIconGridImageAlpha:(CGFloat)alpha {
	%orig(FolderGridImageAlpha * alpha);
}

- (void)layoutSubviews {
	%orig;
	if (enableFolderIcons)
		[[self backgroundView] setAlpha:0];

	UIImageView *iconView = objc_getAssociatedObject(self, &FolderIconBG);
	UIImageView *maskView = objc_getAssociatedObject(self, &FolderIconMask);
	if (iconView)
		iconView.frame = self.bounds;
	if (maskView)
		maskView.frame = self.bounds;
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]){
		%init(FoldersHook);
	} else {
		%init(AnemonePreview);
	}
}