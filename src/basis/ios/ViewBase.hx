package basis.ios;

import cpp.Lib;
import basis.ios.ViewManager;

class ViewBase
{
	private var _tag:Int;
	public var tag(getTag, null) : Int;
	private function getTag():Int {return _tag;}
	
	private var _type:String;
	
	public function new(type:String)
	{
		_type = type;
		init();
	}

	private function init():Void
	{
		_tag = ViewManager.createView(this, _type);
	}
	
	public function setTagFromCFFI(newTag:Int):Void
	{
		_tag = newTag;
	}
	
	public function addEventListener(type:String, handler:ViewBase->String->Void):Void
	{
		ViewManager.addEventListener(type, this, handler);
	}
	
	public function destroy():Void
	{
		ViewManager.destroyView(this.tag);
	}
}