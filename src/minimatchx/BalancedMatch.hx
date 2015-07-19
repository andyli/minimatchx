package minimatchx;

@:allow(minimatchx.BalancedMatch)
class BalancedMatchResult {
	/**
		the index of the first match of `a`
	*/
	public var start:Int;
	/**
		the index of the matching `b`
	*/
	public var end:Int;
	/**
		the preamble, `a` and `b` not included
	*/
	public var pre:String;
	/**
		the match, `a` and `b` not included
	*/
	public var body:String;
	/**
		the postscript, `a` and `b` not included
	*/
	public var post:String;

	function new():Void {}
}

/**
	Haxe port of [balanced-match](https://github.com/juliangruber/balanced-match) 0.2.0.
	Match balanced string pairs, like `{` and `}` or `<b>` and `</b>`.
*/
class BalancedMatch {
	static public function balanced(a:String, b:String, str:String):Null<BalancedMatchResult> {
		var bal = 0;
		var m = null;
		var ended = false;

		for (i in 0...str.length) {
			if (a == str.substr(i, a.length)) {
				if (m == null) {
					m = new BalancedMatchResult();
					m.start = i;
				}
				bal++;
			}
			else if (b == str.substr(i, b.length) && m != null) {
				ended = true;
				bal--;
				if (bal <= 0) {
					m.end = i;
					m.pre = str.substr(0, m.start);
					m.body = (m.end - m.start > 1)
						? str.substring(m.start + a.length, m.end)
						: '';
					m.post = str.substring(m.end + b.length);
					return m;
				}
			}
		}

		// if we opened more than we closed, find the one we closed
		if (bal > 0 && ended) {
			var start = m.start + a.length;
			m = balanced(a, b, str.substr(start));
			if (m != null) {
				m.start += start;
				m.end += start;
				m.pre = str.substring(0, start) + m.pre;
			}
			return m;
		}

		return null;
	}
}