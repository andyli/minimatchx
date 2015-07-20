import minimatchx.Minimatch;

class Patterns {
	static public var files = [
		'a', 'b', 'c', 'd', 'abc',
		'abd', 'abe', 'bb', 'bcd',
		'ca', 'cb', 'dd', 'de',
		'bdir/', 'bdir/cfile'
	];

	static function item(pattern:String, expect:Array<String>, ?options:MinimatchOptions, ?files:Array<String>, ?assertOpts:Dynamic) {
		return {
			pattern: pattern,
			expect: expect,
			options: options,
			files: files,
			assertOpts: assertOpts,
		};
	}

	static public var patterns:Array<{
		info:String,
		?files:Array<String>,
		items:Array<{
			pattern:String,
			expect:Array<String>,
			options:Null<MinimatchOptions>,
			files:Null<Array<String>>,
			assertOpts:Null<Dynamic>
		}>
	}> = [
		{
			info: 'http://www.bashcookbook.com/bashinfo/source/bash-1.14.7/tests/glob-test',
			items: [
				item('a*', ['a', 'abc', 'abd', 'abe']),
				item('X*', ['X*'], {nonull: true}),

				// allow null glob expansion
				item('X*', []),

				// isaacs: Slightly different than bash/sh/ksh
				// \\* is not un-escaped to literal "*" in a failed match,
				// but it does make it get treated as a literal star
				item('\\*', ['\\*'], {nonull: true}),
				item('\\**', ['\\**'], {nonull: true}),
				item('\\*\\*', ['\\*\\*'], {nonull: true}),

				item('b*/', ['bdir/']),
				item('c*', ['c', 'ca', 'cb']),
				item('**', files),

				item('\\.\\./*/', ['\\.\\./*/'], {nonull: true}),
				item('s/\\..*//', ['s/\\..*//'], {nonull: true}),
			]
		},
		{
			info: 'legendary larry crashes bashes',
			items: [
				item("/^root:/{s/^[^:]*:[^:]*:([^:]*).*$/\\1/", ["/^root:/{s/^[^:]*:[^:]*:([^:]*).*$/\\1/"], {nonull: true}),
				item("/^root:/{s/^[^:]*:[^:]*:([^:]*).*$/\u0001/", ["/^root:/{s/^[^:]*:[^:]*:([^:]*).*$/\u0001/"], {nonull: true}),
			]
		},
		{
			info: 'character classes',
			items: [
				item('[a-c]b*', ['abc', 'abd', 'abe', 'bb', 'cb']),
				item('[a-y]*[^c]', ['abd', 'abe', 'bb', 'bcd', 'bdir/', 'ca', 'cb', 'dd', 'de']),
				item('a*[^c]', ['abd', 'abe']),
				item('a[X-]b', ['a-b', 'aXb'], null, files.concat(['a-b', 'aXb'])),
				item('[^a-c]*', ['d', 'dd', 'de'], null, files.concat(['a-b', 'aXb', '.x', '.y'])),
				item('a\\*b/*', ['a*b/ooo'], null, files.concat(['a-b', 'aXb', '.x', '.y', 'a*b/', 'a*b/ooo'])),
				item('a\\*?/*', ['a*b/ooo'], null, files.concat(['a-b', 'aXb', '.x', '.y', 'a*b/', 'a*b/ooo'])),
				item('*\\\\!*', [], null, ['echo !7']),
				item('*\\!*', ['echo !7'], null, ['echo !7']),
				item('*.\\*', ['r.*'], null, ['r.*']),
				item('a[b]c', ['abc'], null, files.concat(['a-b', 'aXb', '.x', '.y', 'a*b/', 'a*b/ooo'])),
				item('a[\\b]c', ['abc'], null, files.concat(['a-b', 'aXb', '.x', '.y', 'a*b/', 'a*b/ooo'])),
				item('a?c', ['abc'], null, files.concat(['a-b', 'aXb', '.x', '.y', 'a*b/', 'a*b/ooo'])),
				item('a\\*c', [], null, ['abc']),
				item('', [''], null, ['']),
			]
		},
		{
			info: 'http://www.opensource.apple.com/source/bash/bash-23/bash/tests/glob-test',
			files: files.concat(['man/', 'man/man1/', 'man/man1/bash.1']),
			items: [
				item('*/man*/bash.*', ['man/man1/bash.1']),
				item('man/man1/bash.1', ['man/man1/bash.1']),
				item('a***c', ['abc'], null, ['abc']),
				item('a*****?c', ['abc'], null, ['abc']),
				item('?*****??', ['abc'], null, ['abc']),
				item('*****??', ['abc'], null, ['abc']),
				item('?*****?c', ['abc'], null, ['abc']),
				item('?***?****c', ['abc'], null, ['abc']),
				item('?***?****?', ['abc'], null, ['abc']),
				item('?***?****', ['abc'], null, ['abc']),
				item('*******c', ['abc'], null, ['abc']),
				item('*******?', ['abc'], null, ['abc']),
				item('a*cd**?**??k', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('a**?**cd**?**??k', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('a**?**cd**?**??k***', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('a**?**cd**?**??***k', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('a**?**cd**?**??***k**', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('a****c**?**??*****', ['abcdecdhjk'], null, ['abcdecdhjk']),
				item('[-abc]', ['-'], null, ['-']),
				item('[abc-]', ['-'], null, ['-']),
				item('\\', ['\\'], null, ['\\']),
				item('[\\\\]', ['\\'], null, ['\\']),
				item('[[]', ['['], null, ['[']),
				item('[', ['['], null, ['[']),
				item('[*', ['[abc'], null, ['[abc']),
			]
		},
		{
			info: "a right bracket shall lose its special meaning and represent itself in a bracket expression if it occurs first in the list.  -- POSIX.2 2.8.3.2",
			items: [
				item('[]]', [']'], null, [']']),
				item('[]-]', [']'], null, [']']),
				item('[a-z]', ['p'], null, ['p']),
				item('??**********?****?', [], null, ['abc']),
				item('??**********?****c', [], null, ['abc']),
				item('?************c****?****', [], null, ['abc']),
				item('*c*?**', [], null, ['abc']),
				item('a*****c*?**', [], null, ['abc']),
				item('a********???*******', [], null, ['abc']),
				item('[]', [], null, ['a']),
				item('[abc', [], null, ['[']),
			]
		},
		{
			info: 'nocase tests',
			items: [
				item(
					'XYZ',
					['xYz'],
					{ nocase: true },
					['xYz', 'ABC', 'IjK']
				),
				item(
					'ab*',
					['ABC'],
					{ nocase: true },
					['xYz', 'ABC', 'IjK']
				),
				item(
					'[ia]?[ck]',
					['ABC', 'IjK'],
					{ nocase: true },
					['xYz', 'ABC', 'IjK']
				),
			]
		},
		{
			info: 'onestar/twostar',
			items: [
				item('{/*,*}', [], null, ['/asdf/asdf/asdf']),
				item('{/?,*}', ['/a', 'bb'], null, ['/a', '/b/b', '/a/b/c', 'bb']),
			]
		},
		{
			info: 'dots should not match unless requested',
			files: ['a/./b', 'a/../b', 'a/c/b', 'a/.d/b'],
			items: [
				item('**', ['a/b'], {}, ['a/b', 'a/.d', '.a/.d']),
				// .. and . can only match patterns starting with .,
				// even when options.dot is set.
				item('a/*/b', ['a/c/b', 'a/.d/b'], {dot: true}),
				item('a/.*/b', ['a/./b', 'a/../b', 'a/.d/b'], {dot: true}),
				item('a/*/b', ['a/c/b'], {dot: false}),
				item('a/.*/b', ['a/./b', 'a/../b', 'a/.d/b'], {dot: false}),

				// this also tests that changing the options needs
				// to change the cache key, even if the pattern is
				// the same!
				item(
					'**',
					['a/b', 'a/.d', '.a/.d'],
					{ dot: true },
					[ '.a/.d', 'a/.d', 'a/b']
				),
			]
		},
		{
			info: 'paren sets cannot contain slashes',
			items: [
				item('*(a/b)', ['*(a/b)'], {nonull: true}, ['a/b']),

				// brace sets trump all else.
				//
				// invalid glob pattern.  fails on bash4 and bsdglob.
				// however, in this implementation, it's easier just
				// to do the intuitive thing, and let brace-expansion
				// actually come before parsing any extglob patterns,
				// like the documentation seems to say.
				//
				// XXX: if anyone complains about this, either fix it
				// or tell them to grow up and stop complaining.
				//
				// bash/bsdglob says this:
				// , ["*(a|{b),c)}", ["*(a|{b),c)}"], {}, ["a", "ab", "ac", "ad"]]
				// but we do this instead:
				item('*(a|{b),c)}', ['a', 'ab', 'ac'], {}, ['a', 'ab', 'ac', 'ad']),

				// test partial parsing in the presence of comment/negation chars
				item('[!a*', ['[!ab'], {}, ['[!ab', '[ab']),
				item('[#a*', ['[#ab'], {}, ['[#ab', '[ab']),

				// like: {a,b|c\\,d\\\|e} except it's unclosed, so it has to be escaped.
				item(
					'+(a|*\\|c\\\\|d\\\\\\|e\\\\\\\\|f\\\\\\\\\\|g',
					['+(a|b\\|c\\\\|d\\\\|e\\\\\\\\|f\\\\\\\\|g'],
					{},
					['+(a|b\\|c\\\\|d\\\\|e\\\\\\\\|f\\\\\\\\|g', 'a', 'b\\c']
				),
			]
		},
		{
			info: 'crazy nested {,,} and *(||) tests.',
			files: [
				'a', 'b', 'c', 'd', 'ab', 'ac', 'ad', 'bc', 'cb', 'bc,d',
				'c,db', 'c,d', 'd)', '(b|c', '*(b|c', 'b|c', 'b|cc', 'cb|c',
				'x(a|b|c)', 'x(a|c)', '(a|b|c)', '(a|c)'
			],
			items: [
				item('*(a|{b,c})', ['a', 'b', 'c', 'ab', 'ac']),
				item('{a,*(b|c,d)}', ['a', '(b|c', '*(b|c', 'd)']),
				// a
				// *(b|c)
				// *(b|d)
				item('{a,*(b|{c,d})}', ['a', 'b', 'bc', 'cb', 'c', 'd']),
				item('*(a|{b|c,c})', ['a', 'b', 'c', 'ab', 'ac', 'bc', 'cb']),

				// test various flag settings.
				item(
					'*(a|{b|c,c})',
					['x(a|b|c)', 'x(a|c)', '(a|b|c)', '(a|c)'],
					{ noext: true }
				),
				item(
					'a?b',
					['x/y/acb', 'acb/'],
					{ matchBase: true },
					['x/y/acb', 'acb/', 'acb/d/e', 'x/y/acb/d']
				),
				item('#*', ['#a', '#b'], { nocomment: true }, ['#a', '#b', 'c#d']),
			]
		},
		// {
		// 	info: ,
		// 	items: [
		// 		
		// 	]
		// },
		// {
		// 	info: ,
		// 	items: [
		// 		
		// 	]
		// },
	];

	static public var regexps = [
		"/^(?:(?=.)a[^/]*?)$/",
		"/^(?:(?=.)X[^/]*?)$/",
		"/^(?:(?=.)X[^/]*?)$/",
		"/^(?:\\*)$/",
		"/^(?:(?=.)\\*[^/]*?)$/",
		"/^(?:\\*\\*)$/",
		"/^(?:(?=.)b[^/]*?\\/)$/",
		"/^(?:(?=.)c[^/]*?)$/",
		"/^(?:(?:(?!(?:\\/|^)\\.).)*?)$/",
		"/^(?:\\.\\.\\/(?!\\.)(?=.)[^/]*?\\/)$/",
		"/^(?:s\\/(?=.)\\.\\.[^/]*?\\/)$/",
		"/^(?:\\/\\^root:\\/\\{s\\/(?=.)\\^[^:][^/]*?:[^:][^/]*?:\\([^:]\\)[^/]*?\\.[^/]*?\\$\\/1\\/)$/",
		"/^(?:\\/\\^root:\\/\\{s\\/(?=.)\\^[^:][^/]*?:[^:][^/]*?:\\([^:]\\)[^/]*?\\.[^/]*?\\$\\/\u0001\\/)$/",
		"/^(?:(?!\\.)(?=.)[a-c]b[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[a-y][^/]*?[^c])$/",
		"/^(?:(?=.)a[^/]*?[^c])$/",
		"/^(?:(?=.)a[X-]b)$/",
		"/^(?:(?!\\.)(?=.)[^a-c][^/]*?)$/",
		"/^(?:a\\*b\\/(?!\\.)(?=.)[^/]*?)$/",
		"/^(?:(?=.)a\\*[^/]\\/(?!\\.)(?=.)[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?\\\\\\![^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?\\![^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?\\.\\*)$/",
		"/^(?:(?=.)a[b]c)$/",
		"/^(?:(?=.)a[b]c)$/",
		"/^(?:(?=.)a[^/]c)$/",
		"/^(?:a\\*c)$/",
		"false",
		"/^(?:(?!\\.)(?=.)[^/]*?\\/(?=.)man[^/]*?\\/(?=.)bash\\.[^/]*?)$/",
		"/^(?:man\\/man1\\/bash\\.1)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/]*?c)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]c)$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/])$/",
		"/^(?:(?!\\.)(?=.)[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/])$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]c)$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?c)$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?[^/])$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?c)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/])$/",
		"/^(?:(?=.)a[^/]*?cd[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/]k)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/][^/]*?[^/]*?cd[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/]k)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/][^/]*?[^/]*?cd[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/]k[^/]*?[^/]*?[^/]*?)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/][^/]*?[^/]*?cd[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/][^/]*?[^/]*?[^/]*?k)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/][^/]*?[^/]*?cd[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/][^/]*?[^/]*?[^/]*?k[^/]*?[^/]*?)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/]*?[^/]*?c[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/][^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[-abc])$/",
		"/^(?:(?!\\.)(?=.)[abc-])$/",
		"/^(?:\\\\)$/",
		"/^(?:(?!\\.)(?=.)[\\\\])$/",
		"/^(?:(?!\\.)(?=.)[\\[])$/",
		"/^(?:\\[)$/",
		"/^(?:(?=.)\\[(?!\\.)(?=.)[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[\\]])$/",
		"/^(?:(?!\\.)(?=.)[\\]-])$/",
		"/^(?:(?!\\.)(?=.)[a-z])$/",
		"/^(?:(?!\\.)(?=.)[^/][^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?[^/])$/",
		"/^(?:(?!\\.)(?=.)[^/][^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?c)$/",
		"/^(?:(?!\\.)(?=.)[^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?c[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/]*?[^/]*?[^/]*?[^/]*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?c[^/]*?[^/][^/]*?[^/]*?)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?c[^/]*?[^/][^/]*?[^/]*?)$/",
		"/^(?:(?=.)a[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/][^/][^/][^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?[^/]*?)$/",
		"/^(?:\\[\\])$/",
		"/^(?:\\[abc)$/",
		"/^(?:(?=.)XYZ)$/i",
		"/^(?:(?=.)ab[^/]*?)$/i",
		"/^(?:(?!\\.)(?=.)[ia][^/][ck])$/i",
		"/^(?:\\/(?!\\.)(?=.)[^/]*?|(?!\\.)(?=.)[^/]*?)$/",
		"/^(?:\\/(?!\\.)(?=.)[^/]|(?!\\.)(?=.)[^/]*?)$/",
		"/^(?:(?:(?!(?:\\/|^)\\.).)*?)$/",
		"/^(?:a\\/(?!(?:^|\\/)\\.{1,2}(?:$|\\/))(?=.)[^/]*?\\/b)$/",
		"/^(?:a\\/(?=.)\\.[^/]*?\\/b)$/",
		"/^(?:a\\/(?!\\.)(?=.)[^/]*?\\/b)$/",
		"/^(?:a\\/(?=.)\\.[^/]*?\\/b)$/",
		"/^(?:(?:(?!(?:\\/|^)(?:\\.{1,2})($|\\/)).)*?)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?\\(a\\/b\\))$/",
		"/^(?:(?!\\.)(?=.)(?:a|b)*|(?!\\.)(?=.)(?:a|c)*)$/",
		"/^(?:(?=.)\\[(?=.)\\!a[^/]*?)$/",
		"/^(?:(?=.)\\[(?=.)#a[^/]*?)$/",
		"/^(?:(?=.)\\+\\(a\\|[^/]*?\\|c\\\\\\\\\\|d\\\\\\\\\\|e\\\\\\\\\\\\\\\\\\|f\\\\\\\\\\\\\\\\\\|g)$/",
		"/^(?:(?!\\.)(?=.)(?:a|b)*|(?!\\.)(?=.)(?:a|c)*)$/",
		"/^(?:a|(?!\\.)(?=.)[^/]*?\\(b\\|c|d\\))$/",
		"/^(?:a|(?!\\.)(?=.)(?:b|c)*|(?!\\.)(?=.)(?:b|d)*)$/",
		"/^(?:(?!\\.)(?=.)(?:a|b|c)*|(?!\\.)(?=.)(?:a|c)*)$/",
		"/^(?:(?!\\.)(?=.)[^/]*?\\(a\\|b\\|c\\)|(?!\\.)(?=.)[^/]*?\\(a\\|c\\))$/",
		"/^(?:(?=.)a[^/]b)$/",
		"/^(?:(?=.)#[^/]*?)$/",
		"/^(?!^(?:(?=.)a[^/]*?)$).*$/",
		"/^(?:(?=.)\\!a[^/]*?)$/",
		"/^(?:(?=.)a[^/]*?)$/",
		"/^(?!^(?:(?=.)\\!a[^/]*?)$).*$/",
		"/^(?:(?!\\.)(?=.)[^\\/]*?\\.(?:(?!(?:js)$)[^\\/]*?))$/",
		"/^(?:(?:(?!(?:\\/|^)\\.).)*?\\/\\.x\\/(?:(?!(?:\\/|^)\\.).)*?)$/",
		"/^(?:\\[z\\-a\\])$/",
		"/^(?:a\\/\\[2015\\-03\\-10T00:23:08\\.647Z\\]\\/z)$/",
		"/^(?:(?=.)\\[a-0\\][a-Ā])$/",
	];
}