import haxe.unit.*;

import minimatchx.Minimatch;

class Test {
	static function main():Void {
		// trace(MinimatchFunctions.match(Patterns.files, "X*", {debug:true}));
		// return;

		var runner = new TestRunner();
		runner.add(new TestBalancedMatch());
		runner.add(new TestBraceExpansion());
		runner.add(new TestMinimatch());
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