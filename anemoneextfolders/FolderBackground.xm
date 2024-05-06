#import "../core/ANEMSettingsManager.h"
#import "../core/Bundle.h"
@interface SBFolderBackgroundView : UIView {
	UIView *_backdropView;
}
-(void)_updateBackgroundImageView;
@end

static char *FolderBackgroundIconImageView;

static BOOL FolderBackgroundImageLoaded = NO;
static UIImage *FolderBackgroundImage = nil;

static void LoadFolderBackgroundIcons(){
	if (FolderBackgroundImageLoaded)
		return;

	NSString *path = [[NSBundle mainBundle] themedPathForImage:@"ANEMFolderBackground"];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	if (image)
		FolderBackgroundImage = image;
	FolderBackgroundImageLoaded = YES;
}

%group FoldersBackgroundHook
%hook ANEMSettingsManager
- (void)forceReloadNow {
	FolderBackgroundImageLoaded = NO;
	FolderBackgroundImage = nil;

	%orig;

	LoadFolderBackgroundIcons();
}
%end

%hook SBFolderBackgroundView
-(id)initWithFrame:(CGRect)arg1 {
	%orig;
	LoadFolderBackgroundIcons();

	if (self){
		UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
		backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[backgroundImageView setImage:FolderBackgroundImage];
		objc_setAssociatedObject(self, &FolderBackgroundIconImageView, backgroundImageView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

		UIView *backdropView = [self valueForKey:@"_tintView"];

		[self insertSubview:backgroundImageView aboveSubview:backdropView];
	}
	return self;
}

- (void)_updateBackgroundImageView {
	%orig;
	UIImageView *imageView = objc_getAssociatedObject(self, &FolderBackgroundIconImageView);
	[imageView setImage:FolderBackgroundImage];
}
%end
%end

%ctor {
	if (kCFCoreFoundationVersionNumber > MaxSupportedCFVersion)
        return;
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]){
		%init(FoldersBackgroundHook);
	}
}