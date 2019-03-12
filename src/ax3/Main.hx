package ax3;

import sys.FileSystem;

private typedef Config = {
	var src:String;
	var out:String;
	var swc:Array<String>;
	var ?dump:String;
}

class Main {
	static final loader = new FileLoader();

	static function reportError(path:String, pos:Int, message:String) {
		var posStr = loader.formatPosition(path, pos);
		printerr('$posStr: $message');
	}

	static function main() {
		var args = Sys.args();
		if (args.length != 1) {
			throw "invalid args";
		}
		var config:Config = haxe.Json.parse(sys.io.File.getContent(args[0]));
		var files = [];
		walk(config.src, files);

		var structure = Structure.build(files, config.swc);
		sys.io.File.saveContent("structure.txt", structure.dump());

		var typer = new Typer(structure, reportError);

		var modules = typer.process(files);

		Filters.run(structure, modules);

		var outDir = FileSystem.absolutePath(config.out);
		var dumpDir = if (config.dump == null) null else FileSystem.absolutePath(config.dump);
		for (mod in modules) {
			var gen = new ax3.GenAS3();
			gen.writeModule(mod);
			var out = gen.toString();

			var dir = haxe.io.Path.join({
				var parts = mod.pack.name.split(".");
				parts.unshift(outDir);
				parts;
			});
			Utils.createDirectory(dir);

			var path = dir + "/" + mod.name + ".as";
			sys.io.File.saveContent(path, out);

			if (dumpDir != null) {
				var dir = haxe.io.Path.join({
					var parts = mod.pack.name.split(".");
					parts.unshift(dumpDir);
					parts;
				});
				Utils.createDirectory(dir);
				TypedTreeDump.dump(mod, dir + "/" + mod.name + ".dump");
			}
		}
	}

	static function walk(dir:String, files:Array<ParseTree.File>) {
		function loop(dir) {
			for (name in FileSystem.readDirectory(dir)) {
				var absPath = dir + "/" + name;
				if (FileSystem.isDirectory(absPath)) {
					walk(absPath, files);
				} else if (StringTools.endsWith(name, ".as")) {
					var file = parseFile(absPath);
					if (file != null) {
						files.push(file);
					}
				}
			}
		}
		loop(dir);
	}

	static function parseFile(path:String):ParseTree.File {
		// print('Parsing $path');
		var content = stripBOM(loader.getContent(path));
		var scanner = new Scanner(content);
		var parser = new Parser(scanner, path);
		var parseTree = null;
		try {
			parseTree = parser.parse();
			// var dump = ParseTreeDump.printFile(parseTree, "");
			// Sys.println(dump);
		} catch (e:Any) {
			reportError(path, @:privateAccess scanner.pos, Std.string(e));
		}
		if (parseTree != null) {
			// checkParseTree(path, content, parseTree);
		}
		return parseTree;
	}

	static function checkParseTree(path:String, expected:String, parseTree:ParseTree.File) {
		var actual = Printer.print(parseTree);
		if (actual != expected) {
			printerr(actual);
			printerr("-=-=-=-=-");
			printerr(expected);
			// throw "not the same: " + haxe.Json.stringify(actual);
			throw '$path not the same';
		}
	}

	static function stripBOM(text:String):String {
		return if (StringTools.fastCodeAt(text, 0) == 0xFEFF) text.substring(1) else text;
	}

	static function print(s:String) #if hxnodejs js.Node.console.log(s) #else Sys.println(s) #end;
	static function printerr(s:String) #if hxnodejs js.Node.console.error(s) #else Sys.println(s) #end;
}
