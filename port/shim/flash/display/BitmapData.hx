package flash.display;

typedef Rect = { x : Int, y : Int, width : Int, height : Int }

/** Solo para que compile; en modo sin pantalla no se usa. */
class BitmapData {
	public var rect : Rect;
	public function new( w : Int, h : Int, ?transparent = true, ?color = 0 ) rect = { x : 0, y : 0, width : w, height : h };
	public function getVector( r : Rect ) : flash.Vector<UInt> return new flash.Vector<UInt>(r.width * r.height);
	public function setVector( r : Rect, v : flash.Vector<UInt> ) {}
}
