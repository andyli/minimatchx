package minimatchx;

import minimatchx.BalancedMatch.balanced;
using Lambda;

/**
	Haxe port of [brace-expansion](https://github.com/juliangruber/brace-expansion) 1.1.0,
	as known from sh/bash, in JavaScript.
*/
class BraceExpansion {
	static var escSlash = "%%SLASH" + Math.random() + "%%";
	static var escOpen = "%%OPEN" + Math.random() + "%%";
	static var escClose = "%%CLOSE" + Math.random() + "%%";
	static var escComma = "%%COMMA" + Math.random() + "%%";
	static var escPeriod = "%%PERIOD" + Math.random() + "%%";

	static function numeric(str:String):Float {
		return ~/\d/.match(str) ? Std.parseFloat(str) : str.charCodeAt(0);
	}

	static function escapeBraces(str) {
		return str.split('\\\\').join(escSlash)
			.split('\\{').join(escOpen)
			.split('\\}').join(escClose)
			.split('\\,').join(escComma)
			.split('\\.').join(escPeriod);
	}

	static function unescapeBraces(str) {
		return str.split(escSlash).join('\\')
			.split(escOpen).join('{')
			.split(escClose).join('}')
			.split(escComma).join(',')
			.split(escPeriod).join('.');
	}

	// Basically just str.split(","), but handling cases
	// where we have nested braced sections, which should be
	// treated as individual members, like {a,{b,c},d}
	static function parseCommaParts(str:String):Array<String> {
		if (str == "")
			return [''];

		var parts = [];
		var m = balanced('{', '}', str);

		if (m == null)
			return str.split(',');

		var pre = m.pre;
		var body = m.body;
		var post = m.post;
		var p = pre.split(',');

		p[p.length-1] += '{' + body + '}';
		var postParts = parseCommaParts(post);
		if (post.length > 0) {
			p[p.length-1] += postParts.shift();
			p = p.concat(postParts);
		}

		return parts.concat(p);
	}

	static public function expand(str:String):Array<String> {
		if (str == "")
			return [];

		return _expand(escapeBraces(str), true).map(unescapeBraces);
	}

	static function embrace(str:String):String
		return '{' + str + '}';

	static function isPadded(el:String):Bool
		return ~/^-?0\d/.match(el);

	static function lte(i:Float, y:Float):Bool
		return i <= y;

	static function gte(i:Float, y:Float):Bool
		return i >= y;



	static function _expand(str:String, isTop:Bool = false):Array<String> {
		var expansions = [];

		var m = balanced('{', '}', str);
		if (m == null || ~/\$$/.match(m.pre)) return [str];

		var isNumericSequence = ~/^-?\d+\.\.-?\d+(?:\.\.-?\d+)?$/.match(m.body);
		var isAlphaSequence = ~/^[a-zA-Z]\.\.[a-zA-Z](?:\.\.-?\d+)?$/.match(m.body);
		var isSequence = isNumericSequence || isAlphaSequence;
		var isOptions = ~/^(.*,)+(.+)?$/.match(m.body);
		if (!isSequence && !isOptions) {
			// {a},b}
			if (~/,.*}/.match(m.post)) {
				str = m.pre + '{' + m.body + escClose + m.post;
				return _expand(str);
			}
			return [str];
		}

		var n;
		if (isSequence) {
			n = ~/\.\./g.split(m.body);
		} else {
			n = parseCommaParts(m.body);
			if (n.length == 1) {
				// x{{a,b}}y ==> x{a}y x{b}y
				n = _expand(n[0], false).map(embrace);
				if (n.length == 1) {
					var post = m.post.length > 0
						? _expand(m.post, false)
						: [''];
					return post.map(function(p) {
						return m.pre + n[0] + p;
					});
				}
			}
		}

		// at this point, n is the parts, and we know it's not a comma set
		// with a single entry.

		// no need to expand pre, since it is guaranteed to be free of brace-sets
		var pre = m.pre;
		var post = m.post.length > 0
			? _expand(m.post, false)
			: [''];

		var N;

		if (isSequence) {
			var x = numeric(n[0]);
			var y = numeric(n[1]);
			var width:Int = Std.int(Math.max(n[0].length, n[1].length));
			var incr:Int = n.length == 3
				? Std.int(Math.abs(numeric(n[2])))
				: 1;
			var test = lte;
			var reverse = y < x;
			if (reverse) {
				incr *= -1;
				test = gte;
			}
			var pad = n.exists(isPadded);

			N = [];

			var i = x;
			while (test(i, y)) {
				var c;
				if (isAlphaSequence) {
					c = String.fromCharCode(Std.int(i));
					if (c == '\\')
						c = '';
				} else {
					c = Std.string(i);
					if (pad) {
						var need = width - c.length;
						if (need > 0) {
							var z = [for (i in 0...need) "0"].join('');
							if (i < 0)
								c = '-' + z + c.substring(1);
							else
								c = z + c;
						}
					}
				}
				N.push(c);
				i += incr;
			}
		} else {
			N = n
				.map(function(el) return _expand(el, false))
				.fold(function(cur, acc:Array<String>) return acc.concat(cur), []);
		}

		for (j in 0...N.length) {
			for (k in 0...post.length) {
				var expansion = pre + N[j] + post[k];
				if (!isTop || isSequence || expansion != "")
					expansions.push(expansion);
			}
		}

		return expansions;
	}
}