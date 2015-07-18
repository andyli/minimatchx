import haxe.unit.*;
import minimatchx.BraceExpansion.expand;
using Std;

class TestBraceExpansion extends TestCase {
	function test_empty_option():Void {
		assertEquals(
			['-v', '-v', '-v', '-v', '-v'].string(),
			expand('-v{,,,,}').string()
		);
	}

	function test_nested():Void {
		assertEquals(
			['a', 'b1', 'b2', 'b3', 'c'].string(),
			expand('{a,b{1..3},c}').string()
		);
		assertEquals(
			'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split('').string(),
			expand('{{A..Z},{a..z}}').string()
		);
		assertEquals(
			['ppp', 'pppconfig', 'pppoe', 'pppoeconf'].string(),
			expand('ppp{,config,oe{,conf}}').string()
		);
	}

	function test_order():Void {
		assertEquals(
			['ade', 'ace', 'abe'].string(),
			expand('a{d,c,b}e').string()
		);
	}

	function test_pad():Void {
		assertEquals(
			['9', '10', '11'].string(),
			expand('{9..11}').string()
		);
		assertEquals(
			['09', '10', '11'].string(),
			expand('{09..11}').string()
		);
	}

	function test_same_type():Void {
		assertEquals(
			['{a..9}'].string(),
			expand('{a..9}').string()
		);
	}

	function test_sequence():Void {
		// numeric sequences
		assertEquals(
			['a1b2c', 'a1b3c', 'a2b2c', 'a2b3c'].string(),
			expand('a{1..2}b{2..3}c').string()
		);
		assertEquals(
			['12', '13', '22', '23'].string(),
			expand('{1..2}{2..3}').string()
		);

		//numeric sequences with step count
		assertEquals(
			['0', '2', '4', '6', '8'].string(),
			expand('{0..8..2}').string()
		);
		assertEquals(
			['1', '3', '5', '7'].string(),
			expand('{1..8..2}').string()
		);

		//numeric sequence with negative x / y
		assertEquals(
			['3', '2', '1', '0', '-1', '-2'].string(),
			expand('{3..-2}').string()
		);

		//alphabetic sequences
		assertEquals(
			['1a2b3', '1a2c3', '1b2b3', '1b2c3'].string(),
			expand('1{a..b}2{b..c}3').string()
		);
		assertEquals(
			['ab', 'ac', 'bb', 'bc'].string(),
			expand('{a..b}{b..c}').string()
		);

		//alphabetic sequences with step count
		assertEquals(
			['a', 'c', 'e', 'g', 'i', 'k'].string(),
			expand('{a..k..2}').string()
		);
		assertEquals(
			['b', 'd', 'f', 'h', 'j'].string(),
			expand('{b..k..2}').string()
		);
	}

	function test_negative_increment():Void {
		assertEquals(
			['3', '2', '1'].string(),
			expand('{3..1}').string()
		);
		assertEquals(
			['10', '9', '8'].string(),
			expand('{10..8}').string()
		);
		assertEquals(
			['10', '09', '08'].string(),
			expand('{10..08}').string()
		);
		assertEquals(
			['c', 'b', 'a'].string(),
			expand('{c..a}').string()
		);
		assertEquals(
			['4', '2', '0'].string(),
			expand('{4..0..2}').string()
		);
		assertEquals(
			['4', '2', '0'].string(),
			expand('{4..0..-2}').string()
		);
		assertEquals(
			['e', 'c', 'a'].string(),
			expand('{e..a..2}').string()
		);
	}

	function test_dollar():Void {
		assertEquals(
			["${1..3}"].string(),
			expand("${1..3}").string()
		);
		assertEquals(
			["${a,b}${c,d}"].string(),
			expand("${a,b}${c,d}").string()
		);
		assertEquals(
			["x${a,b}x${c,d}x"].string(),
			expand("x${a,b}x${c,d}x").string()
		);
	}

	function test_bash_results():Void {
		var resfile:String = file("brace-expansion_bash-results.txt");
		var cases = resfile.split('><><><><');
		// throw away the EOF marker
		cases.pop();

		for (testcase in cases) {
			trace(testcase);
			var set = testcase.split('\n');
			var pattern = set.shift();
			var actual = expand(pattern);
			trace(actual);

			// If it expands to the empty string, then it's actually
			// just nothing, but Bash is a singly typed language, so
			// "nothing" is the same as "".
			if (set.length == 1 && set[0] == '') {
				set = [];
			} else {
				// otherwise, strip off the [] that were added so that
				// "" expansions would be preserved properly.
				set = set.map(function (s) {
					return ~/^\[|\]$/g.replace(s, '');
				});
			}

			assertEquals(set.string(), actual.string());
		}
	}

	macro static function file(file:String):ExprOf<String> {
		var c = sys.io.File.getContent(haxe.macro.Context.resolvePath(file));
		return macro $v{c};
	}
}