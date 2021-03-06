#import <UIKit/UIKit.h>
#import "basis/ios/BasisApplication.h"

namespace basis
{
    void viewManager_doesNothing(){}
    
    void viewManager_initViewManager()
    {
    	[BasisApplication start];
    }
    
    value viewmanager_createView(value type)
    {
        UIView *view = [[BasisApplication getViewManager] createViewOfType:[NSString stringWithCString:val_string(type)encoding:NSUTF8StringEncoding]];
        return alloc_int(view.tag);
    }
    DEFINE_PRIM (viewmanager_createView, 1);
    
    void viewmanager_destroyView(value tag)
    {
        [[BasisApplication getViewManager] destroyView:(val_int(tag))];
    }
    DEFINE_PRIM (viewmanager_destroyView, 1);
    
    void viewmanager_setEventHandler(value handler)
    {
    	[[BasisApplication getViewManager] setEventHandler: new AutoGCRoot(handler)];
    }
    DEFINE_PRIM (viewmanager_setEventHandler, 1);
    
    void viewmanager_setCFFICreateViewHandler(value handler)
    {
    	[[BasisApplication getViewManager] setCFFICreateViewHandler: new AutoGCRoot(handler)];
    }
    DEFINE_PRIM (viewmanager_setCFFICreateViewHandler, 1);
    
    void viewmanager_setCFFIDestroyViewHandler(value handler)
    {
    	[[BasisApplication getViewManager] setCFFIDestroyViewHandler: new AutoGCRoot(handler)];
    }
    DEFINE_PRIM (viewmanager_setCFFIDestroyViewHandler, 1);
    
	void removeView(int tag)
	{
		[[BasisApplication getViewManager] removeView:tag];
	}
    
    void viewmanager_addToRootView(value tag)
    {
    	[[BasisApplication getViewManager] addToRootView:val_int(tag)];
    }
    DEFINE_PRIM (viewmanager_addToRootView, 1);
    
}
