import haxe.unit.*;

import minimatchx.BalancedMatch;
import minimatchx.Minimatch;

class Test extends TestCase {
	function testEmpty():Void {
		assertTrue(true);
	}

	static function main():Void {
		var runner = new TestRunner();
		runner.add(new TestBalancedMatch());
		runner.add(new Test());
		var success = runner.run();
		if (!success) {
			#if sys
			Sys.exit(1);
			#else
			throw "failed";
			#end
		}
	}
}