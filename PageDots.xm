#import "core/ANEMSettingsManager.h"
#import <dlfcn.h>

@interface _UILegibilityView : UIView
	- (UIImageView *)imageView;
@end

@interface SBIconListPageControl : UIPageControl
	- (BOOL)shouldShowSearchIndicator;
	- (void)ANEMsetPageDotEnabled:(_UILegibilityView *)image enabled:(BOOL)enabled index:(long long)index;
	- (void)_setIndicatorImage:(_UILegibilityView *)image toEnabled:(BOOL)enabled;
	- (void)_setIndicatorImage:(_UILegibilityView *)image toEnabled:(BOOL)enabled index:(long long)index;
@end

static BOOL pageDotImagesLoaded = NO;
static UIImage *currentPageDotImage;
static UIImage *pageDotImage;
static UIImage *currentSpotlightPageDotImage;
static UIImage *spotlightPageDotImage;

static void loadPageDotImages(){
	if (pageDotImagesLoaded)
		return;
	pageDotImagesLoaded = YES;
	NSArray *themes = [[%c(ANEMSettingsManager) sharedManager] themeSettings];
	NSString *themesDir = [[%c(ANEMSettingsManager) sharedManager] themesDir];

	for (NSString *theme in themes)
	{
		NSString *themePath = [NSString stringWithFormat:@"%@/%@",themesDir,theme];
		NSString *dotCurrentPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Dot_CurrentSB.png", themePath];
		if (!currentPageDotImage)
			currentPageDotImage = [UIImage imageWithContentsOfFile:dotCurrentPath];

		dotCurrentPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Dot_Current.png", themePath];
		if (!currentPageDotImage)
			currentPageDotImage = [UIImage imageWithContentsOfFile:dotCurrentPath];

		NSString *dotPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Dot_PagesSB.png", themePath];
		if (!pageDotImage)
			pageDotImage = [UIImage imageWithContentsOfFile:dotPath];

		dotPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Dot_Pages.png", themePath];
		if (!pageDotImage)
			pageDotImage = [UIImage imageWithContentsOfFile:dotPath];

		NSString *spotlightCurrentPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Spotlight_Current.png", themePath];
		if (!currentSpotlightPageDotImage)
			currentSpotlightPageDotImage = [UIImage imageWithContentsOfFile:spotlightCurrentPath];

		NSString *spotlightPath = [NSString stringWithFormat:@"%@/ANEMPageDots/Spotlight_Pages.png", themePath];
		if (!spotlightPageDotImage)
			spotlightPageDotImage = [UIImage imageWithContentsOfFile:spotlightPath];

		if (currentPageDotImage && pageDotImage && spotlightPageDotImage && currentSpotlightPageDotImage)
			break;
	}
}

%group common
%hook ANEMSettingsManager
- (void)forceReloadNow {
	pageDotImagesLoaded = NO;
	currentPageDotImage = nil;
	pageDotImage = nil;
	currentSpotlightPageDotImage = nil;
	spotlightPageDotImage = nil;

	%orig;

	loadPageDotImages();
}
%end
%end

%group AnemoneApp
%hook AnemoneExtensionParameters
+ (UIImage *)kitImageNamed:(NSString *)name {
	if ([name isEqualToString:@"UIPageIndicator"]){
		if (pageDotImage)
			return pageDotImage;
	}
	if ([name isEqualToString:@"UIPageIndicatorCurrent"]){
		if (currentPageDotImage)
			return currentPageDotImage;
	}
	return %orig;
}
%end
%end

%group SpringBoard
%hook SBIconListPageControl
- (id)initWithFrame:(CGRect)arg1 {
	self = %orig;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAllDots) name:@"AnemoneReloadNotification" object:nil];


	return self;
}

%new;
- (void)ANEMsetPageDotEnabled:(_UILegibilityView *)image enabled:(BOOL)enabled index:(long long)index {
	loadPageDotImages();

	if (![image respondsToSelector:@selector(imageView)])
		return;

	UIImageView *imageView = [image imageView];

	CGSize pageDotSize = currentPageDotImage.size;
	if (!currentPageDotImage)
		pageDotSize = imageView.frame.size;

	CGRect imageFrame = CGRectMake(0,0,pageDotSize.width, pageDotSize.height);
	imageView.frame = imageFrame;

	BOOL showSearchIndicator = NO;
	if ([self respondsToSelector:@selector(shouldShowSearchIndicator)])
		showSearchIndicator = [self shouldShowSearchIndicator];

	BOOL isSearchIndicator = NO;
	if (showSearchIndicator && index == 0)
		isSearchIndicator = YES;

	if (currentPageDotImage){
		if (enabled)
			if (isSearchIndicator)
				[imageView setImage:currentSpotlightPageDotImage];
			else
				[imageView setImage:currentPageDotImage];
		else
			if (isSearchIndicator)
				[imageView setImage:spotlightPageDotImage];
			else
				[imageView setImage:pageDotImage];
	}
}

- (void)_setIndicatorImage:(_UILegibilityView *)image toEnabled:(BOOL)enabled index:(long long)index { //iOS 9+
	%orig;
	[self ANEMsetPageDotEnabled:image enabled:enabled index:index];
}

%new;
- (void)reloadAllDots {
	loadPageDotImages();

	NSArray *indicators = [self valueForKey:@"_indicators"];

	NSUInteger index = 0;
	for (_UILegibilityView *image in indicators){
		if ([self respondsToSelector:@selector(_setIndicatorImage:toEnabled:index:)])
			[self _setIndicatorImage:image toEnabled:(index == [self currentPage]) index:index];
		else
			[self _setIndicatorImage:image toEnabled:(index == [self currentPage])];
		index++;
	}
	[self layoutSubviews];
}

- (void)layoutSubviews {
	%orig;
	loadPageDotImages();

	if (!currentPageDotImage)
		return;
	
	CGSize pageDotSize = currentPageDotImage.size;

	NSArray *indicators = [self valueForKey:@"_indicators"];

	NSInteger count = indicators.count;

	CGFloat pageDotSeparators = 8.0f;

	CGFloat width = (pageDotSize.width * count) + (pageDotSeparators * (count - 1));

	CGFloat x = (self.frame.size.width / 2.0) - (width / 2.0);

	CGFloat y = (self.frame.size.height / 2.0) - (pageDotSize.height / 2.0);

	for (UIView *dotView in indicators){
		dotView.frame = CGRectMake(x, y, pageDotSize.width, pageDotSize.height);
		x += pageDotSize.width + pageDotSeparators;
	}
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
		return;

	dlopen("/usr/lib/TweakInject/AnemoneCore.dylib",RTLD_LAZY);

	%init(common);
	if (objc_getClass("SBIconListPageControl") != nil){
		%init(SpringBoard);
	} else {
		%init(AnemoneApp);
	}
}