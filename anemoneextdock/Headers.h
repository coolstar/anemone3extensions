#include <UIKit/UIKit.h>
#import "../core/ANEMSettingsManager.h"
#import "../core/Bundle.h"
#import "../core/AnemoneExtensionParameters.h"

@interface CSReflectionView : UIImageView
@end

@interface SBHighlightView : UIView
@end

@interface SBIconImageView : UIView
- (UIImage *)contentsImage;
- (UIImage *)_currentOverlayImage;
@end

@interface SBIconView : UIView
- (void)anemoneInit;
- (BOOL)isInDock;
- (SBIconImageView *)_iconImageView;
- (void)forceUpdateReflection;
- (void)updateReflection;
- (void)updateOverlayReflection;
- (BOOL)isHighlighted;
@end

@interface SBFloatingDockController : NSObject
+ (BOOL)isFloatingDockSupported;
@end

@interface SBDockView : UIView
- (void)_updateCornerRadii;
@end

@interface UICornerRadiusView : UIView
- (void)_setContinuousCornerRadius:(CGFloat)cornerRadius;
@end