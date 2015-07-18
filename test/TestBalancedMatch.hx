import haxe.unit.*;
import minimatchx.BalancedMatch;
import minimatchx.BalancedMatch.*;

class TestBalancedMatch extends TestCase {
	function test():Void {
		assertMatchResult({
			start: 3,
			end: 12,
			pre: 'pre',
			body: 'in{nest}',
			post: 'post'
		}, balanced('{', '}', 'pre{in{nest}}post'));

		assertMatchResult({
			start: 8,
			end: 11,
			pre: '{{{{{{{{',
			body: 'in',
			post: 'post'
		}, balanced('{', '}', '{{{{{{{{{in}post'));

		assertMatchResult({
			start: 8,
			end: 11,
			pre: 'pre{body',
			body: 'in',
			post: 'post'
		}, balanced('{', '}', 'pre{body{in}post'));

		assertMatchResult({
			start: 4,
			end: 13,
			pre: 'pre}',
			body: 'in{nest}',
			post: 'post'
		}, balanced('{', '}', 'pre}{in{nest}}post'));

		assertMatchResult({
			start: 3,
			end: 8,
			pre: 'pre',
			body: 'body',
			post: 'between{body2}post'
		}, balanced('{', '}', 'pre{body}between{body2}post'));

		assertTrue(balanced('{', '}', 'nope') == null);

		assertMatchResult({
			start: 3,
			end: 19,
			pre: 'pre',
			body: 'in<b>nest</b>',
			post: 'post'
		}, balanced('<b>', '</b>', 'pre<b>in<b>nest</b></b>post'));

		assertMatchResult({
			start: 7,
			end: 23,
			pre: 'pre</b>',
			body: 'in<b>nest</b>',
			post: 'post'
		}, balanced('<b>', '</b>', 'pre</b><b>in<b>nest</b></b>post'));
	}

	macro static function assertMatchResult(expected:ExprOf<BalancedMatchResult>, actual:ExprOf<BalancedMatchResult>):ExprOf<Void> {
		return macro {
			var e = $expected;
			var a = $actual;
			assertEquals(e.start, a.start);
			assertEquals(e.end, a.end);
			assertEquals(e.pre, a.pre);
			assertEquals(e.body, a.body);
			assertEquals(e.post, a.post);
		}
	}
}