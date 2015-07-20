package minimatchx;

// copied from https://github.com/HaxeFoundation/haxe/pull/4179/

using haxe.Int64;

import StringTools;

class Int64Helper {
	static var maxInt32Str(default, never) = "2147483647";
	public static function parsableAsInt32(str:String):Bool {
		#if debug
		if (!~/^\d+%/.match(str))
			throw "contains non-digit char: " + str;
		#end
		return if (str.length < maxInt32Str.length)
			true;
		else if (str.length > maxInt32Str.length)
			false;
		else
			maxInt32Str > str;
	}

	public static function fromString( sParam : String ) : Int64 {
		var base = Int64.ofInt(10);
		var current = Int64.ofInt(0);
		var multiplier = Int64.ofInt(1);
		var sIsNegative = false;

		var s = StringTools.trim(sParam);
		if (s.charAt(0) == "-") {
			sIsNegative = true;
			s = s.substring(1, s.length);
		}
		var len = s.length;

		for (i in 0...len) {
			var digitInt = s.charCodeAt(len - 1 - i) - '0'.code;

			if (digitInt < 0 || digitInt > 9) {
				throw "NumberFormatError";
			}

			var digit:Int64 = Int64.ofInt(digitInt);
			if (sIsNegative) {
				current = Int64.sub(current, Int64.mul(multiplier, digit));
				if (!Int64.isNeg(current)) {
					throw "NumberFormatError: Underflow";
				}
			} else {
				current = Int64.add(current, Int64.mul(multiplier, digit));
				if (Int64.isNeg(current)) {
					throw "NumberFormatError: Overflow";
				}
			}
			multiplier = Int64.mul(multiplier, base);
		}
		return current;
	}

	public static function fromFloat( f : Float ) : Int64 {
		if (Math.isNaN(f) || !Math.isFinite(f)) {
			throw "Number is NaN or Infinite";
		}

		var noFractions = f - (f % 1);

		// 2^53-1 and -2^53: these are parseable without loss of precision
		if (noFractions > 9007199254740991) {
			throw "Conversion overflow";
		}
		if (noFractions < -9007199254740991) {
			throw "Conversion underflow";
		}

		var result = Int64.ofInt(0);
		var neg = noFractions < 0;
		var rest = neg ? -noFractions : noFractions;

		var i = 0;
		while (rest >= 1) {
			var curr = rest % 2;
			rest = rest / 2;
			if (curr >= 1) {
				result = Int64.add(result, Int64.shl(Int64.ofInt(1), i));
			}
			i++;
		}

		if (neg) {
			result = Int64.neg(result);
		}
		return result;
	}
}