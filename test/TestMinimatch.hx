import haxe.unit.*;
import Patterns.*;
import minimatchx.Minimatch;
import minimatchx.Minimatch.MinimatchFunctions.*;
using Std;

class TestMinimatch extends TestCase {
	var re = 0;
	function test():Void {
		for (p in patterns) {
			for (c in p.items) {
				var
					pattern = c.pattern,
					expect = {
						var e = c.expect.copy();
						e.sort(Reflect.compare);
						e;
					},
					options = c.options != null ? c.options : {},
					f = c.files != null ? c.files : files,
					assertOpts = c.assertOpts != null ? c.assertOpts : {};

				// trace('$f $pattern $options');
				#if debug
				options.debug = true;
				#end

				// var m = new Minimatch(pattern, options);
				// var r = m.makeRe();
				// var expectRe = regexps[re++];
				// expectRe = '/' + new EReg('([^\\\\])/', 'g').replace(expectRe.substring(1, expectRe.length-1), "$1\\/") + '/';
				// tapOpts.re = String(r) || JSON.stringify(r)
				// tapOpts.re = '/' + tapOpts.re.slice(1, -1).replace(new RegExp('([^\\\\])/', 'g'), '$1\\\/') + '/'
				// tapOpts.files = JSON.stringify(f)
				// tapOpts.pattern = pattern
				// tapOpts.set = m.set
				// tapOpts.negated = m.negate

				var actual = match(f, pattern, options);
				actual.sort(Reflect.compare);

				assertEquals(expect.string(), actual.string());

				// t.equal(tapOpts.re, expectRe, null, tapOpts)
			}
		}
	}
}