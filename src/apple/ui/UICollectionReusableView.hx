package apple.ui;

import cpp.Lib;
import basis.ios.ViewManager;
import basis.ios.ViewBase;

class UICollectionReusableView extends UIView
{
	public function new(?type:String = "UICollectionReusableView")
	{
		super(type);
	}
	
	
	public var reuseIdentifier(getReuseIdentifier, null) : String;
		private function getReuseIdentifier():String
	{
		return cpp_uicollectionreusableview_getReuseIdentifier(_tag);
	}
	private static var cpp_uicollectionreusableview_getReuseIdentifier = Lib.load("basis", "uicollectionreusableview_getReuseIdentifier", 1);

	public function prepareForReuse():Void
	{
		cpp_uicollectionreusableview_prepareForReuse(_tag);
	}
	private static var cpp_uicollectionreusableview_prepareForReuse = Lib.load("basis", "uicollectionreusableview_prepareForReuse", 1);

}