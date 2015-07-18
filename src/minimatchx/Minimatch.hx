package minimatchx;

typedef MinimatchOptions = {
	@:optional var debug:Bool;
	@:optional var nobrace:Bool;
	@:optional var noglobstar:Bool;
	@:optional var dot:Bool;
	@:optional var noext:Bool;
	@:optional var nocase:Bool;
	@:optional var nonull:Bool;
	@:optional var matchBase:Bool;
	@:optional var nocomment:Bool;
	@:optional var nonegate:Bool;
	@:optional var flipNegate:Bool;
}

enum Part {
	s(s:String);
	r(r:EReg);
}

class MinimatchFunctions {
	static public function minimatch(path:String, pattern:String, options:MinimatchOptions):Bool {
		return false;
	}

	static public function filter(pattern:String, options:MinimatchOptions):String->Bool {
		return null;
	}

	static public function match(list:Array<String>, pattern:String, options:MinimatchOptions):Bool {
		return false;
	}

	static public function makeRe(pattern:String, options:MinimatchOptions):EReg {
		return null;
	}
}

class Minimatch {
	public var set:Array<Array<Part>>;
	public var regexp:EReg;
	public var negate:Bool;
	public var comment:Bool;
	public var empty:Bool;

	public function new(pattern:String, options:MinimatchOptions):Void {

	}

	public function makeRe():EReg {
		return null;
	}

	public function match(fname:String):Bool {
		return false;
	}

	public function matchOne(fileArray:Dynamic, patternArray:Dynamic, partial:Dynamic):Bool {
		return false;
	}
}