#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ViewEventManager.h"
#include <hx/CFFI.h>


@interface ViewManager : UIResponder <UIApplicationDelegate>
	
	-(UIView*) getView:(int) tag;
	-(int) addView:(UIView*) view type:(NSString*)type;
	-(UIView*) createViewOfType:(NSString*) type;
	-(void)destroyView:(int) tag;
	-(void)destroyCFFIView:(UIView *) view;
	-(void) setEventHandler:(AutoGCRoot *) handler;
	-(void) setCFFICreateViewHandler:(AutoGCRoot *) handler;
	-(void) setCFFIDestroyViewHandler:(AutoGCRoot *) handler;
	-(void) removeView:(int) tag;
	-(void) addToRootView:(int) tag;
	-(void) setMainWindow:(UIWindow *) win;
	
	@property (nonatomic, retain) UIWindow *window;

@end
