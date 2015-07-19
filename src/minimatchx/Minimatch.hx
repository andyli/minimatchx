package minimatchx;

import haxe.ds.*;
import haxe.io.*;
import minimatchx.BraceExpansion.expand;
using Lambda;
using Reflect;
using StringTools;

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
	GLOBSTAR;
	Str(s:String);
	Re(r:EReg, src:String);
	Sub(s:String, hasMagic:Bool);
}

/**
	Haxe port of [minimatch](https://github.com/isaacs/minimatch) 2.0.9, a minimal matching utility.
	It works by converting glob expressions into `EReg` objects.
*/
@:allow(minimatchx.Minimatch)
class Minimatch {
	static public var pathSep = '/'; //TODO
	public var set:Array<Array<Part>>;
	public var regexp:Option<EReg>;
	public var negate:Bool;
	public var comment:Bool;
	public var empty:Bool;
	public var options:MinimatchOptions;
	public var pattern:String;

	public function new(pattern:String, ?options:MinimatchOptions):Void {
		if (options == null) options = {};
		pattern = pattern.trim();

		// windows support: need to use /, not \
		if (pathSep != '/') {
			pattern = pattern.split(pathSep).join('/');
		}

		this.options = options;
		this.set = [];
		this.pattern = pattern;
		this.regexp = null;
		this.negate = false;
		this.comment = false;
		this.empty = false;

		// make the set of regexps etc.
		this.make();
	}

	public function makeRe():EReg {
		if (this.regexp != null) return switch (this.regexp) {
			case None: null;
			case Some(re): re;
		}

		// at this point, this.set is a 2d array of partial
		// pattern strings, or "**".
		//
		// It's better to use .match().  This function shouldn't
		// be used, really, but it's pretty convenient sometimes,
		// when you just want to work with a regex.
		var set = this.set;

		if (set.length <= 0) {
			this.regexp = None;
			return null;
		}
		var options = this.options;

		var twoStar = options.noglobstar == true ? star
			: options.dot == true ? twoStarDot
			: twoStarNoDot;
		var flags = options.nocase == true ? 'i' : '';

		var re = set.map(function (pattern) {
			return pattern.map(function (p) {
				return switch (p) {
					case GLOBSTAR: twoStar;
					case Str(s): regExpEscape(s);
					case Re(r, src): src;
					case _: throw "error";
				}
			}).join('\\/');
		}).join('|');

		// must match entire pattern
		// ending in a * or ** will make it less strict.
		re = '^(?:' + re + ')$';

		// can match anything, as long as it's not this.
		if (this.negate) re = '^(?!' + re + ').*$';

		return try {
			var r = new EReg(re, flags);
			this.regexp = Some(r);
			r;
		} catch (ex:Dynamic) {
			this.regexp = None;
			null;
		}
	}

	public function match(f:String, ?partial):Bool {
		debug('$f, ${this.pattern}');
		// short-circuit in the case of busted things.
		// comments, etc.
		if (this.comment) return false;
		if (this.empty) return f == '';

		if (f == '/' && partial) return true;

		var options = this.options;

		// windows: need to use /, not \
		if (pathSep != '/') {
			f = f.split(pathSep).join('/');
		}

		// treat the test path as a set of pathparts.
		var f = slashSplit.split(f);
		debug('${this.pattern} split $f');

		// just ONE of the pattern sets in this.set needs to match
		// in order for it to be valid.  If negating, then just one
		// match means that we have failed.
		// Either way, return on the first hit.

		var set = this.set;
		debug('${this.pattern} set $set');

		// Find the basename of the path by looking for the last non-empty segment
		var filename = null;
		var i = f.length - 1;
		while (i >= 0) {
			filename = f[i];
			if (filename != null) break;
			i--;
		}

		for (i in 0...set.length) {
			var pattern = set[i];
			var file = f;
			if (options.matchBase == true && pattern.length == 1) {
				file = [filename];
			}
			var hit = this.matchOne(file, pattern, partial);
			if (hit) {
				if (options.flipNegate == true) return true;
				return !this.negate;
			}
		}

		// didn't get any hits.  this is success if it's a negative
		// pattern, failure otherwise.
		if (options.flipNegate == true) return false;
		return this.negate;
	}

	public function matchOne(file:Array<String>, pattern:Array<Part>, partial:Bool = false):Bool {
		var options = this.options;

		debug('this $this, file: $file, pattern: $pattern');

		debug('${file.length}, ${pattern.length}');

		var fi = -1,
			pi = -1,
			fl = file.length,
			pl = pattern.length;
		while ({
			++fi;++pi;
			fi < fl && pi < pl;
		}) {
			debug('loop');
			var p = pattern[pi];
			var f = file[fi];

			debug('$pattern, $p, $f');

			switch (p) {
				#if (haxe_ver >= 3.2)
				case null:
					// should be impossible.
					// some invalid regexp stuff in the set.
					return false;
				#end
				case GLOBSTAR:
					// "**"
					// a/**/b/**/c would match the following:
					// a/b/x/y/z/c
					// a/x/y/z/b/c
					// a/b/x/b/x/c
					// a/b/c
					// To do this, take the rest of the pattern after
					// the **, and see if it would match the file remainder.
					// If so, return success.
					// If not, the ** "swallows" a segment, and try again.
					// This is recursively awful.
					//
					// a/**/b/**/c matching a/b/x/y/z/c
					// - a matches a
					// - doublestar
					//   - matchOne(b/x/y/z/c, b/**/c)
					//     - b matches b
					//     - doublestar
					//       - matchOne(x/y/z/c, c) -> no
					//       - matchOne(y/z/c, c) -> no
					//       - matchOne(z/c, c) -> no
					//       - matchOne(c, c) yes, hit
					var fr = fi;
					var pr = pi + 1;
					if (pr == pl) {
						debug('** at the end');
						// a ** at the end will just swallow the rest.
						// We have found a match.
						// however, it will not swallow /.x, unless
						// options.dot is set.
						// . and .. are *never* matched by **, for explosively
						// exponential reasons.
						while (fi < fl) {
							if (file[fi] == '.' || file[fi] == '..' ||
								(!(options.dot == true) && file[fi].charAt(0) == '.')) return false;
							fi++;
						}
						return true;
					}

					// ok, let's see if we can swallow whatever we can.
					while (fr < fl) {
						var swallowee = file[fr];

						debug('\nglobstar while $file, $fr, $pattern, $pr, $swallowee');

						// XXX remove this slice.  Just pass the start index.
						if (this.matchOne(file.slice(fr), pattern.slice(pr), partial)) {
							debug('globstar found match! $fr, $fl, $swallowee');
							// found a match.
							return true;
						} else {
							// can't swallow "." or ".." ever.
							// can only swallow ".foo" when explicitly asked.
							if (swallowee == '.' || swallowee == '..' ||
								(!(options.dot == true) && swallowee.charAt(0) == '.')) {
								debug('dot detected! $file, $fr, $pattern, $pr');
								break;
							}

							// ** swallows a segment, and continue.
							debug('globstar swallow a segment, and continue');
							fr++;
						}
					}

					// no match was found.
					// However, in partial mode, we can't say this is necessarily over.
					// If there's more *pattern* left, then
					if (partial) {
						// ran out of file
						debug('\n>>> no match, partial? $file, $fr, $pattern, $pr');
						if (fr == fl) return true;
					}
					return false;

				// something other than **
				// non-magic patterns just have to match exactly
				// patterns with magic have been turned into regexps.
				case Str(p):
					var hit = if (options.nocase == true) {
						f.toLowerCase() == p.toLowerCase();
					} else {
						f == p;
					}
					debug('string match $p, $f, $hit');
					if (!hit) return false;
				case Re(r, src):
					var hit = r.match(f);
					debug('pattern match $p, $f, $hit');
					if (!hit) return false;
				case _:
					throw "error";
			}
		}

		debug('here~~~~~~~~~~~');
		debug('$fi, $fl, $pi, $pl');

		// Note: ending in / means that we'll get a final ""
		// at the end of the pattern.  This can only match a
		// corresponding "" at the end of the file.
		// If the file ends in /, then it can only match a
		// a pattern that ends in /, unless the pattern just
		// doesn't have any more for it. But, a/b/ should *not*
		// match "a/b/*", even though "" matches against the
		// [^/]*? pattern, except in partial mode, where it might
		// simply not be reached yet.
		// However, a/b/ should still satisfy a/*

		// now either we fell off the end of the pattern, or we're done.
		if (fi == fl && pi == pl) {
			// ran out of pattern and filename at the same time.
			// an exact hit!
			return true;
		} else if (fi == fl) {
			// ran out of file, but still had pattern left.
			// this is ok if we're doing the match as part of
			// a glob fs traversal.
			return partial;
		} else if (pi == pl) {
			// ran out of pattern, still have file left.
			// this is only acceptable if we're on the very last
			// empty segment of a file with a trailing slash.
			// a/* should match a/b/
			var emptyFileEnd = (fi == fl - 1) && (file[fi] == '');
			return emptyFileEnd;
		}

		// should be unreachable.
		throw 'wtf?';
	}

	/**
		any single thing other than /
	*/
	static var qmark = '[^/]';

	/**
		* => any number of characters
	*/
	static var star = qmark + '*?';

	/**
		** when dots are allowed.  Anything goes, except .. and .
		not (^ or / followed by one or two dots followed by $ or /),
		followed by anything, any number of times.
	*/
	static var twoStarDot = "(?:(?!(?:\\/|^)(?:\\.{1,2})($|\\/)).)*?";

	/**
		not a ^ or / followed by a dot,
		followed by anything, any number of times.
	*/
	static var twoStarNoDot = '(?:(?!(?:\\/|^)\\.).)*?';

	/**
		characters that need to be escaped in RegExp.
	*/
	static var reSpecials = charSet("().*{}+?[]^$\\!");

	static function charSet(s:String):Map<String, Bool> {
		return 
			[
				for (i in 0...s.length)
				s.charAt(i) => true
			];
	}

	/**
		normalizes slashes.
	*/
	static var slashSplit = ~/\/+/g;

	static function ext(a:{} = null, b:{} = null):Dynamic {
		if (a == null)
			a = {};
		if (b == null)
			b = {};
		var t = {};
		for (k in a.fields())
			t.setField(k, a.field(k));
		for (k in b.fields())
			t.setField(k, b.field(k));
		return t;
	}

	static macro function debug(msg) {
		return macro @:pos(msg.pos)
			if (options.debug == true)
				trace($msg);
	}

	var _made:Bool = false;
	var globSet:Array<String>;
	var globParts:Array<Array<String>>;
	function make():Void {
		// don't do it more than once.
		if (this._made) return;

		var pattern = this.pattern;
		var options = this.options;

		// empty patterns and comments match nothing.
		if (!(options.nocomment == true) && pattern.charAt(0) == '#') {
			this.comment = true;
			return;
		}
		if (pattern == null || pattern == "") {
			this.empty = true;
			return;
		}

		// step 1: figure out negation, etc.
		this.parseNegate();

		// step 2: expand braces
		var set = this.globSet = this.braceExpand();

		debug(this.pattern + ", " + set);

		// step 3: now we have a set, so turn each one into a series of path-portion
		// matching patterns.
		// These will be regexps, except in the case of "**", which is
		// set to the GLOBSTAR object for globstar behavior,
		// and will not contain any / characters
		var set = this.globParts = set.map(function (s) {
			return slashSplit.split(s);
		});

		debug(this.pattern + ", " + set);

		// glob --> regexps
		var set = set.map(function (s) {
			return s.map(function (s) return this.parse(s));
		});

		debug(this.pattern + ", " + set);

		// filter out everything that didn't compile properly.
		var set = set.filter(function(s):Bool {
			return s.indexOf(null) == -1;
		});

		debug(this.pattern + ", " + set);

		this.set = set;
	}

	function parseNegate():Void {
		var pattern = this.pattern;
		var negate = false;
		var options = this.options;
		var negateOffset = 0;

		if (options.nonegate == true) return;

		for (i in 0...pattern.length) {
			if (pattern.charAt(i) != '!')
				break;
			negate = !negate;
			negateOffset++;
		}

		if (negateOffset > 0) this.pattern = pattern.substr(negateOffset);
		this.negate = negate;
	}

	function braceExpand(?pattern:String, ?options:Dynamic):Array<String> {
		if (options == null) {
			options = this.options;
		}

		if (pattern == null) {
			pattern = this.pattern;
		}

		if (pattern == null) {
			throw 'undefined pattern';
		}

		if (options.nobrace == true ||
			!~/\{.*\}/.match(pattern)) {
			// shortcut. no need to expand.
			return [pattern];
		}

		return expand(pattern);
	}

	function parse(pattern:String, isSub:Bool = false):Part {
		var options = this.options;

		// shortcuts
		if (!(options.noglobstar == true) && pattern == '**') return GLOBSTAR;
		if (pattern == '') return Str('');

		var re = '';
		var hasMagic = options.nocase == true;
		var escaping = false;
		// ? => one single character
		var patternListStack:Array<{
			type:String,
			start:Int,
			reStart:Int,
			reEnd:Int,
		}> = [];
		var negativeLists:Array<Dynamic> = [];
		var plType;
		var stateChar:Null<String> = null;
		var inClass = false;
		var reClassStart = -1;
		var classStart = -1;
		// . and .. never match anything that doesn't start with .,
		// even when options.dot is set.
		var patternStart = pattern.charAt(0) == '.' ? '' // anything
		// not (start or / followed by . or .. followed by / or end)
		: options.dot == true ? '(?!(?:^|\\/)\\.{1,2}(?:$|\\/))'
		: '(?!\\.)';
		var self = this;

		function clearStateChar () {
			if (stateChar != null) {
				// we had some state-tracking character
				// that wasn't consumed by this pass.
				switch (stateChar) {
					case '*':
						re += star;
						hasMagic = true;
					case '?':
						re += qmark;
						hasMagic = true;
					default:
						re += '\\' + stateChar;
				}
				debug('clearStateChar $stateChar $re');
				stateChar = null;
			}
		}

		for (i in 0...pattern.length) {
			var c;
			if ((c = pattern.charAt(i)) == "")
				break;

			debug('$pattern\t$i $re $c');

			// skip over any that are escaped.
			if (escaping && reSpecials.exists(c)) {
				debug("there!!!");
				re += '\\' + c;
				escaping = false;
				continue;
			}

			switch (c) {
				case '/':
					// completely not allowed, even escaped.
					// Should already be path-split by now.
					return null;

				case '\\':
					clearStateChar();
					escaping = true;
					continue;

				// the various stateChar values
				// for the "extglob" stuff.
				case '?', '*', '+', '@', '!':
					debug('$pattern\t$i $re $c <-- stateChar');

					// all of those are literals inside a class, except that
					// the glob [!a] means [^a] in regexp
					if (inClass) {
						debug('  in class');
						if (c == '!' && i == classStart + 1) c = '^';
						re += c;
						continue;
					}

					// if we already have a stateChar, then it means
					// that there was something like ** or +? in there.
					// Handle the stateChar, then proceed with this one.
					debug('call clearStateChar $stateChar');
					clearStateChar();
					stateChar = c;
					// if extglob is disabled, then +(asdf|foo) isn't a thing.
					// just clear the statechar *now*, rather than even diving into
					// the patternList stuff.
					if (options.noext == true) clearStateChar();
					continue;

				case '(':
					if (inClass) {
						re += '(';
						continue;
					}

					if (stateChar == null) {
						re += '\\(';
						continue;
					}

					plType = stateChar;
					patternListStack.push({
						type: plType,
						start: i - 1,
						reStart: re.length,
						reEnd: -1,
					});
					// negation is (?:(?!js)[^/]*)
					re += stateChar == '!' ? '(?:(?!(?:' : '(?:';
					debug('plType $stateChar $re');
					stateChar = null;
					continue;

				case ')':
					if (inClass || patternListStack.length == 0) {
						re += '\\)';
						continue;
					}

					clearStateChar();
					hasMagic = true;
					re += ')';
					var pl = patternListStack.pop();
					plType = pl.type;
					// negation is (?:(?!js)[^/]*)
					// The others are (?:<pattern>)<type>
					switch (plType) {
						case '!':
							negativeLists.push(pl);
							re += ')[^/]*?)';
							pl.reEnd = re.length;
						case '?', '+', '*':
							re += plType;
						case '@': // the default anyway
					}
					continue;

				case '|':
					if (inClass || patternListStack.length == 0 || escaping) {
						re += '\\|';
						escaping = false;
						continue;
					}

					clearStateChar();
					re += '|';
					continue;

				// these are mostly the same in regexp and glob
				case '[':
					// swallow any state-tracking char before the [
					clearStateChar();

					if (inClass) {
						re += '\\' + c;
						continue;
					}

					inClass = true;
					classStart = i;
					reClassStart = re.length;
					re += c;
					continue;

				case ']':
					//  a right bracket shall lose its special
					//  meaning and represent itself in
					//  a bracket expression if it occurs
					//  first in the list.  -- POSIX.2 2.8.3.2
					if (i == classStart + 1 || !inClass) {
						re += '\\' + c;
						escaping = false;
						continue;
					}

					// handle the case where we left a class open.
					// "[z-a]" is valid, equivalent to "\[z-a\]"
					if (inClass) {
						// split where the last [ was, make sure we don't have
						// an invalid re. if so, re-walk the contents of the
						// would-be class to re-translate any characters that
						// were passed through as-is
						// TODO: It would probably be faster to determine this
						// without a try/catch and a new RegExp, but it's tricky
						// to do safely.  For now, this is safe and works.
						var cs = pattern.substring(classStart + 1, i);
						try {
							new EReg('[' + cs + ']', "");
						} catch (er:Dynamic) {
							// not a valid class!
							switch(this.parse(cs, true)) {
								case Sub(str, isMagic):
									re = re.substr(0, reClassStart) + '\\[' + str + '\\]';
									hasMagic = hasMagic || isMagic;
									inClass = false;
								case _: throw "error";
							}
							continue;
						}
					}

					// finish up the class.
					hasMagic = true;
					inClass = false;
					re += c;
					continue;

				default:
					// swallow any state char that wasn't consumed
					clearStateChar();

					debug('$escaping ${reSpecials[c]} $c $inClass');

					if (escaping) {
						// no need
						escaping = false;
					} else if (reSpecials.exists(c)
						&& !(c == '^' && inClass)) {
						re += '\\';
					}

					re += c;

			} // switch
		} // for

		// handle the case where we left a class open.
		// "[abc" is valid, equivalent to "\[abc"
		if (inClass) {
			// split where the last [ was, and escape it
			// this is a huge pita.  We now have to re-walk
			// the contents of the would-be class to re-translate
			// any characters that were passed through as-is
			var cs = pattern.substr(classStart + 1);
			switch (this.parse(cs, true)) {
				case Sub(s, hasMagic):
					re = re.substr(0, reClassStart) + '\\[' + s;
					hasMagic = hasMagic || hasMagic;
				case _: throw "error";
			}
		}

		// handle the case where we had a +( thing at the *end*
		// of the pattern.
		// each pattern list stack adds 3 chars, and we need to go through
		// and escape any | chars that were passed through as-is for the regexp.
		// Go through and escape them, taking care not to double-escape any
		// | chars that were already escaped.
		var pl;
		while ((pl = patternListStack.pop()) != null) {
			var tail = re.substring(pl.reStart + 3);
			// maybe some even number of \, then maybe 1 \, followed by a |
			tail = ~/((?:\\{2})*)(\\?)\|/g.map(tail, function (re:EReg):String {
				var _1 = re.matched(1);
				var _2 = re.matched(2);
				if (_2 == "") {
					// the | isn't already escaped, so escape it.
					_2 = '\\';
				}

				// need to escape all those slashes *again*, without escaping the
				// one that we need for escaping the | character.  As it works out,
				// escaping an even number of slashes can be done by simply repeating
				// it exactly after itself.  That's why this trick works.
				//
				// I am sorry that you have to see this.
				return _1 + _1 + _2 + '|';
			});

			debug('tail=$tail');
			var t = pl.type == '*' ? star
				: pl.type == '?' ? qmark
				: '\\' + pl.type;

			hasMagic = true;
			re = re.substring(0, pl.reStart) + t + '\\(' + tail;
		}

		// handle trailing things that only matter at the very end.
		clearStateChar();
		if (escaping) {
			// trailing \\
			re += '\\\\';
		}

		// only need to apply the nodot start if the re starts with
		// something that could conceivably capture a dot
		var addPatternStart = switch (re.charAt(0)) {
			case '.', '[', '(': true;
			case _: false;
		}

		// Hack to work around lack of negative lookbehind in JS
		// A pattern like: *.!(x).!(y|z) needs to ensure that a name
		// like 'a.xyz.yz' doesn't match.  So, the first negative
		// lookahead, has to look ALL the way ahead, to the end of
		// the pattern.
		var n = negativeLists.length - 1;
		while (n > -1) {
			var nl = negativeLists[n];

			var nlBefore = re.substring(0, nl.reStart);
			var nlFirst = re.substring(nl.reStart, nl.reEnd - 8);
			var nlLast = re.substring(nl.reEnd - 8, nl.reEnd);
			var nlAfter = re.substring(nl.reEnd);
			var dollar = '';
			if (nlAfter == '' && !isSub) {
				dollar = '$';
			}
			var newRe = nlBefore + nlFirst + nlAfter + dollar + nlLast + nlAfter;
			re = newRe;

			n--;
		}

		// if the re is not "" at this point, then we need to make sure
		// it doesn't match against an empty path part.
		// Otherwise a/* will match a/, which it should not.
		if (re != '' && hasMagic) {
			re = '(?=.)' + re;
		}

		if (addPatternStart) {
			re = patternStart + re;
		}

		// parsing just a piece of a larger pattern.
		if (isSub) {
			return Sub(re, hasMagic);
		}

		// skip the regexp for non-magical patterns
		// unescape anything in it, though, so that it'll be
		// an exact match against a file etc.
		if (!hasMagic) {
			return Str(globUnescape(pattern));
		}

		var flags = options.nocase == true ? 'i' : '';
		var regExp = new EReg('^' + re + '$', flags);

		// regExp._glob = pattern;
		// regExp._src = re;

		return Re(regExp, re);
	}

	static function globUnescape(s:String):String {
		return ~/\\(.)/g.replace(s, "$1");
	}

	static function regExpEscape (s) {
		return ~/[-[\]{}()*+?.,\\^$|#\s]/g.replace(s, "\\$&");
	}
}


class MinimatchFunctions {
	static public function minimatch(path:String, pattern:String, ?options:MinimatchOptions):Bool {
		if (options == null) options = {}

		// shortcut: comments match nothing.
		if (!options.nocomment == true && pattern.charAt(0) == '#') {
			return false;
		}

		// "" only matches ""
		if (pattern.trim() == '') return path == '';

		return new Minimatch(pattern, options).match(path);
	}

	static public function filter(pattern:String, ?options:MinimatchOptions):String->Int->Array<String>->Bool {
		if (options == null)
			options = {};
		return function (p, i, list) {
			return minimatch(p, pattern, options);
		}
	}

	static public function match(list:Array<String>, pattern:String, ?options:MinimatchOptions):Array<String> {
		if (options == null)
			options = {};
		var mm = new Minimatch(pattern, options);
		list = list.filter(function (f) {
			return mm.match(f);
		});
		if (mm.options.nonull == true && list.length == 0) {
			list.push(pattern);
		}
		return list;
	}

	static public function makeRe(pattern:String, ?options:MinimatchOptions):EReg {
		return new Minimatch(pattern, options != null ? options : {}).makeRe();
	}
}