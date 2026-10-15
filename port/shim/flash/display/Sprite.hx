package flash.display;

class Sprite {
	public var graphics = new Graphics();
	public var x = 0.;
	public var y = 0.;
	public var scaleX = 1.;
	public var scaleY = 1.;
	public var rotation = 0.;
	public var alpha = 1.;
	public var visible = true;
	public var blendMode : BlendMode = BlendMode.NORMAL;
	public var children : Array<Sprite> = [];
	public var parent : Sprite;
	public function new() {}
	public function addChild( c : Sprite ) {
		if( c.parent != null ) c.parent.children.remove(c);
		c.parent = this;
		children.push(c);
		return c;
	}
	public function removeChild( c : Sprite ) {
		children.remove(c);
		c.parent = null;
		return c;
	}
}
