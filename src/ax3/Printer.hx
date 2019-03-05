package ax3;

import ax3.ParseTree;
import ax3.Token;

class Printer {
	var buf:StringBuf;

	public function new() {
		buf = new StringBuf();
	}

	public static function print(f:File):String {
		var p = new Printer();
		p.printFile(f);
		return p.toString();
	}

	function printFile(file:File) {
		for (decl in file.declarations)
			printDeclaration(decl);
		printTrivia(file.eof.leadTrivia);
	}

	function printDeclaration(decl:Declaration) {
		switch (decl) {
			case DPackage(p):
				printPackage(p);
			case DImport(i):
				printImport(i);
			case DClass(c):
				printClass(c);
			case DInterface(i):
				printInterface(i);
			case DFunction(f):
				printFunctionDecl(f);
			case DVar(v):
				printDeclModifiers(v.modifiers);
				printVarDeclKind(v.kind);
				printSeparated(v.vars, printVarDecl, printComma);
				printSemicolon(v.semicolon);
			case DNamespace(ns):
				printNamespace(ns);
			case DUseNamespace(ns, semicolon):
				printUseNamespace(ns);
				printSemicolon(semicolon);
			case DCondComp(v, openBrace, decls, closeBrace):
				printCondCompVar(v);
				printTextWithTrivia("{", openBrace);
				for (d in decls) printDeclaration(d);
				printTextWithTrivia("}", closeBrace);
		}
	}

	function printPackage(p:PackageDecl) {
		printTextWithTrivia("package", p.keyword);
		if (p.name != null) printDotPath(p.name);
		printTextWithTrivia("{", p.openBrace);
		for (d in p.declarations) {
			printDeclaration(d);
		}
		printTextWithTrivia("}", p.closeBrace);
	}

	function printImport(i:ImportDecl) {
		printTextWithTrivia("import", i.keyword);
		printDotPath(i.path);
		if (i.wildcard != null) {
			printDot(i.wildcard.dot);
			printTextWithTrivia("*", i.wildcard.asterisk);
		}
		printSemicolon(i.semicolon);
	}

	function printNamespace(ns:NamespaceDecl) {
		printDeclModifiers(ns.modifiers);
		printTextWithTrivia("namespace", ns.keyword);
		printIdent(ns.name);
		printSemicolon(ns.semicolon);
	}

	function printUseNamespace(ns:UseNamespace) {
		printTextWithTrivia("use", ns.useKeyword);
		printTextWithTrivia("namespace", ns.namespaceKeyword);
		printIdent(ns.name);
	}

	function printFunctionDecl(f:FunctionDecl) {
		printMetadata(f.metadata);
		printDeclModifiers(f.modifiers);
		printTextWithTrivia("function", f.keyword);
		printIdent(f.name);
		printFunction(f.fun);
	}

	function printClass(c:ClassDecl) {
		printMetadata(c.metadata);
		printDeclModifiers(c.modifiers);
		printTextWithTrivia("class", c.keyword);
		printIdent(c.name);
		if (c.extend != null) {
			printTextWithTrivia("extends", c.extend.keyword);
			printDotPath(c.extend.path);
		}
		if (c.implement != null) {
			printTextWithTrivia("implements", c.implement.keyword);
			printSeparated(c.implement.paths, printDotPath, printComma);
		}
		printTextWithTrivia("{", c.openBrace);
		for (m in c.members) {
			printClassMember(m);
		}
		printTextWithTrivia("}", c.closeBrace);
	}

	function printClassMember(m:ClassMember) {
			switch (m) {
				case MCondComp(v, openBrace, members, closeBrace):
					printCondCompVar(v);
					printTextWithTrivia("{", openBrace);
					for (m in members) {
						printClassMember(m);
					}
					printTextWithTrivia("}", closeBrace);
				case MStaticInit(block):
					printBracedExprBlock(block);
				case MUseNamespace(n, semicolon):
					printUseNamespace(n);
					printSemicolon(semicolon);
				case MField(f):
					printClassField(f);
			}
	}

	function printClassField(f:ClassField) {
		printMetadata(f.metadata);
		if (f.namespace != null) printIdent(f.namespace);
		printClassFieldModifiers(f.modifiers);
		switch (f.kind) {
			case FVar(kind, vars, semicolon):
				printVarDeclKind(kind);
				printSeparated(vars, printVarDecl, printComma);
				printSemicolon(semicolon);
			case FFun(keyword, name, fun):
				printTextWithTrivia("function", keyword);
				printIdent(name);
				printFunction(fun);
			case FProp(keyword, kind, name, fun):
				printTextWithTrivia("function", keyword);
				switch (kind) {
					case PGet(keyword): printTextWithTrivia("get", keyword);
					case PSet(keyword): printTextWithTrivia("set", keyword);
				}
				printIdent(name);
				printFunction(fun);
		}
	}

	function printClassFieldModifiers(modifiers:Array<ClassFieldModifier>) {
		for (m in modifiers) {
			switch (m) {
				case FMPublic(t): printTextWithTrivia("public", t);
				case FMPrivate(t): printTextWithTrivia("private", t);
				case FMProtected(t): printTextWithTrivia("protected", t);
				case FMInternal(t): printTextWithTrivia("internal", t);
				case FMOverride(t): printTextWithTrivia("override", t);
				case FMStatic(t): printTextWithTrivia("static", t);
				case FMFinal(t): printTextWithTrivia("final", t);
			}
		}
	}

	function printInterface(i:InterfaceDecl) {
		printMetadata(i.metadata);
		printDeclModifiers(i.modifiers);
		printTextWithTrivia("interface", i.keyword);
		printIdent(i.name);
		if (i.extend != null) {
			printTextWithTrivia("extends", i.extend.keyword);
			printSeparated(i.extend.paths, printDotPath, printComma);
		}
		printTextWithTrivia("{", i.openBrace);
		for (m in i.members) {
			printInterfaceMember(m);
		}
		printTextWithTrivia("}", i.closeBrace);
	}

	function printInterfaceMember(m:InterfaceMember) {
			switch (m) {
				case MICondComp(v, openBrace, members, closeBrace):
					printCondCompVar(v);
					printTextWithTrivia("{", openBrace);
					for (m in members) {
						printInterfaceMember(m);
					}
					printTextWithTrivia("}", closeBrace);
				case MIField(f):
					printInterfaceField(f);
			}
	}

	function printInterfaceField(f:InterfaceField) {
		printMetadata(f.metadata);
		switch (f.kind) {
			case IFFun(keyword, name, sig):
				printTextWithTrivia("function", keyword);
				printIdent(name);
				printFunctionSignature(sig);
			case IFProp(keyword, kind, name, sig):
				printTextWithTrivia("function", keyword);
				switch (kind) {
					case PGet(keyword): printTextWithTrivia("get", keyword);
					case PSet(keyword): printTextWithTrivia("set", keyword);
				}
				printIdent(name);
				printFunctionSignature(sig);
		}
		printSemicolon(f.semicolon);
	}

	function printMetadata(metadata:Array<Metadata>) {
		for (m in metadata) {
			printTextWithTrivia("[", m.openBracket);
			printIdent(m.name);
			if (m.args != null) printCallArgs(m.args);
			printTextWithTrivia("]", m.closeBracket);
		}
	}

	function printFunction(f:Function) {
		printFunctionSignature(f.signature);
		printBracedExprBlock(f.block);
	}

	function printFunctionSignature(f:FunctionSignature) {
		printTextWithTrivia("(", f.openParen);
		if (f.args != null) printSeparated(f.args, function(arg) {
			switch (arg) {
				case ArgNormal(a):
					printVarDecl(a);
				case ArgRest(dots, name):
					printTextWithTrivia("...", dots);
					printIdent(name);
			}
		}, printComma);
		printTextWithTrivia(")", f.closeParen);
		if (f.ret != null) printTypeHint(f.ret);
	}

	function printVarDecl(a:VarDecl) {
		printIdent(a.name);
		if (a.type != null) printTypeHint(a.type);
		if (a.init != null) printVarInit(a.init);
	}

	function printVarInit(i:VarInit) {
		printTextWithTrivia("=", i.equals);
		printExpr(i.expr);
	}

	function printTypeHint(hint:TypeHint) {
		printTextWithTrivia(":", hint.colon);
		printSyntaxType(hint.type);
	}

	function printSyntaxType(t:SyntaxType) {
		switch (t) {
			case TAny(star): printTextWithTrivia("*", star);
			case TPath(path): printDotPath(path);
			case TVector(v): printVectorSyntax(v);
		}
	}

	function printVectorSyntax(v:VectorSyntax) {
		printTextWithTrivia("Vector", v.name);
		printDot(v.dot);
		printTypeParam(v.t);
	}

	function printTypeParam(t:TypeParam) {
		printTextWithTrivia("<", t.lt);
		printSyntaxType(t.type);
		printTextWithTrivia(">", t.gt);
	}

	function printCallArgs(args:CallArgs) {
		printTextWithTrivia("(", args.openParen);
		if (args.args != null) printSeparated(args.args, printExpr, printComma);
		printTextWithTrivia(")", args.closeParen);
	}

	function printBracedExprBlock(b:BracedExprBlock) {
		printTextWithTrivia("{", b.openBrace);
		for (el in b.exprs) {
			printBlockElement(el);
		}
		printTextWithTrivia("}", b.closeBrace);
	}

	function printBlockElement(e:BlockElement) {
		printExpr(e.expr);
		if (e.semicolon != null) printSemicolon(e.semicolon);
	}

	function printExpr(e:Expr) {
		switch (e) {
			case EIdent(i):
				printIdent(i);
			case ELiteral(LString(t) | LDecInt(t) | LHexInt(t) | LFloat(t) | LRegExp(t)):
				printTextWithTrivia(t.text, t);
			case ECall(e, args):
				printExpr(e);
				printCallArgs(args);
			case EParens(openParen, e, closeParen):
				printTextWithTrivia("(", openParen);
				printExpr(e);
				printTextWithTrivia(")", closeParen);
			case EArrayAccess(e, openBracket, eindex, closeBracket):
				printExpr(e);
				printTextWithTrivia("[", openBracket);
				printExpr(eindex);
				printTextWithTrivia("]", closeBracket);
			case EArrayDecl(d):
				printArrayDecl(d);
			case EReturn(keyword, e):
				printTextWithTrivia("return", keyword);
				if (e != null) printExpr(e);
			case EThrow(keyword, e):
				printTextWithTrivia("throw", keyword);
				printExpr(e);
			case EDelete(keyword, e):
				printTextWithTrivia("delete", keyword);
				printExpr(e);
			case EBreak(keyword):
				printTextWithTrivia("break", keyword);
			case EContinue(keyword):
				printTextWithTrivia("continue", keyword);
			case ENew(keyword, e, args):
				printTextWithTrivia("new", keyword);
				printExpr(e);
				if (args != null) printCallArgs(args);
			case EVectorDecl(newKeyword, t, d):
				printTextWithTrivia("new", newKeyword);
				printTypeParam(t);
				printArrayDecl(d);
			case EField(e, dot, fieldName):
				printExpr(e);
				printDot(dot);
				printIdent(fieldName);
			case EXmlAttr(e, dot, at, attrName):
				printExpr(e);
				printDot(dot);
				printTextWithTrivia("@", at);
				printIdent(attrName);
			case EXmlDescend(e, dotDot, childName):
				printExpr(e);
				printTextWithTrivia("..", dotDot);
				printIdent(childName);
			case EBlock(b):
				printBracedExprBlock(b);
			case EObjectDecl(openBrace, fields, closeBrace):
				printTextWithTrivia("{", openBrace);
				printSeparated(fields, function(f) {
					printTextWithTrivia(f.name.text, f.name);
					printTextWithTrivia(":", f.colon);
					printExpr(f.value);
				}, printComma);
				printTextWithTrivia("}", closeBrace);
			case EIf(keyword, openParen, econd, closeParen, ethen, eelse):
				printTextWithTrivia("if", keyword);
				printTextWithTrivia("(", openParen);
				printExpr(econd);
				printTextWithTrivia(")", closeParen);
				printExpr(ethen);
				if (eelse != null) {
					printTextWithTrivia("else", eelse.keyword);
					printExpr(eelse.expr);
				}
			case ETernary(econd, question, ethen, colon, eelse):
				printExpr(econd);
				printTextWithTrivia("?", question);
				printExpr(ethen);
				printTextWithTrivia(":", colon);
				printExpr(eelse);
			case EWhile(keyword, openParen, cond, closeParen, body):
				printTextWithTrivia("while", keyword);
				printTextWithTrivia("(", openParen);
				printExpr(cond);
				printTextWithTrivia(")", closeParen);
				printExpr(body);
			case EDoWhile(doKeyword, body, whileKeyword, openParen, cond, closeParen):
				printTextWithTrivia("do", doKeyword);
				printExpr(body);
				printTextWithTrivia("while", whileKeyword);
				printTextWithTrivia("(", openParen);
				printExpr(cond);
				printTextWithTrivia(")", closeParen);
			case EFor(keyword, openParen, einit, initSep, econd, condSep, eincr, closeParen, body):
				printTextWithTrivia("for", keyword);
				printTextWithTrivia("(", openParen);
				if (einit != null) printExpr(einit);
				printSemicolon(initSep);
				if (econd != null) printExpr(econd);
				printSemicolon(condSep);
				if (eincr != null) printExpr(eincr);
				printTextWithTrivia(")", closeParen);
				printExpr(body);
			case EForIn(forKeyword, openParen, iter, closeParen, body):
				printTextWithTrivia("for", forKeyword);
				printTextWithTrivia("(", openParen);
				printForIter(iter);
				printTextWithTrivia(")", closeParen);
				printExpr(body);
			case EForEach(forKeyword, eachKeyword, openParen, iter, closeParen, body):
				printTextWithTrivia("for", forKeyword);
				printTextWithTrivia("each", eachKeyword);
				printTextWithTrivia("(", openParen);
				printForIter(iter);
				printTextWithTrivia(")", closeParen);
				printExpr(body);
			case EBinop(a, op, b):
				printExpr(a);
				printBinop(op);
				printExpr(b);
			case EPreUnop(op, e):
				printPreUnop(op);
				printExpr(e);
			case EPostUnop(e, op):
				printExpr(e);
				printPostUnop(op);
			case EVars(kind, vars):
				printVarDeclKind(kind);
				printSeparated(vars, printVarDecl, printComma);
			case EAs(e, keyword, t):
				printExpr(e);
				printTextWithTrivia("as", keyword);
				printSyntaxType(t);
			case EIs(e, keyword, etype):
				printExpr(e);
				printTextWithTrivia("is", keyword);
				printExpr(etype);
			case EComma(a, comma, b):
				printExpr(a);
				printTextWithTrivia(",", comma);
				printExpr(b);
			case EVector(v):
				printVectorSyntax(v);
			case ESwitch(keyword, openParen, subj, closeParen, openBrace, cases, closeBrace):
				printTextWithTrivia("switch", keyword);
				printTextWithTrivia("(", openParen);
				printExpr(subj);
				printTextWithTrivia(")", closeParen);
				printTextWithTrivia("{", openBrace);
				for (c in cases) {
					switch (c) {
						case CCase(keyword, v, colon, body):
							printTextWithTrivia("case", keyword);
							printExpr(v);
							printTextWithTrivia(":", colon);
							for (e in body) {
								printBlockElement(e);
							}
						case CDefault(keyword, colon, body):
							printTextWithTrivia("default", keyword);
							printTextWithTrivia(":", colon);
							for (e in body) {
								printBlockElement(e);
							}
					}
				}
				printTextWithTrivia("}", closeBrace);
			case ECondCompValue(v):
				printCondCompVar(v);
			case ECondCompBlock(v, b):
				printCondCompVar(v);
				printBracedExprBlock(b);
			case ETry(keyword, block, catches, finally_):
				printTextWithTrivia("try", keyword);
				printBracedExprBlock(block);
				for (c in catches) {
					printTextWithTrivia("catch", c.keyword);
					printTextWithTrivia("(", c.openParen);
					printIdent(c.name);
					printTypeHint(c.type);
					printTextWithTrivia(")", c.closeParen);
					printBracedExprBlock(c.block);
				}
				if (finally_ != null) {
					printTextWithTrivia("finally", finally_.keyword);
					printBracedExprBlock(finally_.block);
				}
			case EFunction(keyword, name, fun):
				printTextWithTrivia("function", keyword);
				if (name != null) printIdent(name);
				printFunction(fun);
			case EUseNamespace(n):
				printUseNamespace(n);
		}
	}

	function printCondCompVar(v:CondCompVar) {
		printIdent(v.ns);
		printTextWithTrivia("::", v.sep);
		printIdent(v.name);
	}

	function printVarDeclKind(k:VarDeclKind) {
		switch (k) {
			case VVar(t): printTextWithTrivia("var", t);
			case VConst(t): printTextWithTrivia("const", t);
		}
	}

	function printForIter(iter:ForIter) {
		printExpr(iter.eit);
		printTextWithTrivia("in", iter.inKeyword);
		printExpr(iter.eobj);
	}

	function printPreUnop(op:PreUnop) {
		switch (op) {
			case PreNot(t): printTextWithTrivia("!", t);
			case PreNeg(t): printTextWithTrivia("-", t);
			case PreIncr(t): printTextWithTrivia("++", t);
			case PreDecr(t): printTextWithTrivia("--", t);
			case PreBitNeg(t): printTextWithTrivia("~", t);
		}
	}

	function printPostUnop(op:PostUnop) {
		switch (op) {
			case PostIncr(t): printTextWithTrivia("++", t);
			case PostDecr(t): printTextWithTrivia("--", t);
		}
	}

	function printBinop(op:Binop) {
		switch (op) {
			case OpAdd(t): printTextWithTrivia("+", t);
			case OpSub(t): printTextWithTrivia("-", t);
			case OpDiv(t): printTextWithTrivia("/", t);
			case OpMul(t): printTextWithTrivia("*", t);
			case OpMod(t): printTextWithTrivia("%", t);
			case OpAssign(t): printTextWithTrivia("=", t);
			case OpAssignAdd(t): printTextWithTrivia("+=", t);
			case OpAssignSub(t): printTextWithTrivia("-=", t);
			case OpAssignMul(t): printTextWithTrivia("*=", t);
			case OpAssignDiv(t): printTextWithTrivia("/=", t);
			case OpAssignMod(t): printTextWithTrivia("%=", t);
			case OpAssignAnd(t): printTextWithTrivia("&&=", t);
			case OpAssignOr(t): printTextWithTrivia("||=", t);
			case OpAssignBitAnd(t): printTextWithTrivia("&=", t);
			case OpAssignBitOr(t): printTextWithTrivia("|=", t);
			case OpAssignBitXor(t): printTextWithTrivia("^=", t);
			case OpAssignShl(t): printTextWithTrivia("<<=", t);
			case OpAssignShr(t): printTextWithTrivia(">>=", t);
			case OpAssignUshr(t): printTextWithTrivia(">>>=", t);
			case OpEquals(t): printTextWithTrivia("==", t);
			case OpNotEquals(t): printTextWithTrivia("!=", t);
			case OpStrictEquals(t): printTextWithTrivia("===", t);
			case OpNotStrictEquals(t): printTextWithTrivia("!==", t);
			case OpGt(t): printTextWithTrivia(">", t);
			case OpGte(t): printTextWithTrivia(">=", t);
			case OpLt(t): printTextWithTrivia("<", t);
			case OpLte(t): printTextWithTrivia("<=", t);
			case OpIn(t): printTextWithTrivia("in", t);
			case OpAnd(t): printTextWithTrivia("&&", t);
			case OpOr(t): printTextWithTrivia("||", t);
			case OpShl(t): printTextWithTrivia("<<", t);
			case OpShr(t): printTextWithTrivia(">>", t);
			case OpUshr(t): printTextWithTrivia(">>>", t);
			case OpBitAnd(t): printTextWithTrivia("&", t);
			case OpBitOr(t): printTextWithTrivia("|", t);
			case OpBitXor(t): printTextWithTrivia("^", t);
		}
	}

	function printArrayDecl(d:ArrayDecl) {
		printTextWithTrivia("[", d.openBracket);
		if (d.elems != null) printSeparated(d.elems, printExpr, printComma);
		printTextWithTrivia("]", d.closeBracket);
	}

	function printDeclModifiers(modifiers:Array<DeclModifier>) {
		for (m in modifiers) {
			switch (m) {
				case DMPublic(t): printTextWithTrivia("public", t);
				case DMInternal(t): printTextWithTrivia("internal", t);
				case DMFinal(t): printTextWithTrivia("final", t);
				case DMDynamic(t): printTextWithTrivia("dynamic", t);
			}
		}
	}

	inline function printDot(s:Token) {
		printTextWithTrivia(".", s);
	}

	inline function printComma(c:Token) {
		printTextWithTrivia(",", c);
	}

	inline function printSemicolon(s:Token) {
		printTextWithTrivia(";", s);
	}

	function printDotPath(p:DotPath) {
		printSeparated(p, t -> printTextWithTrivia(t.text, t), t -> printTextWithTrivia(".", t));
	}

	function printSeparated<T>(s:Separated<T>, f:T->Void, fsep:Token->Void) {
		f(s.first);
		for (v in s.rest) {
			fsep(v.sep);
			f(v.element);
		}
	}

	inline function printIdent(token:Token) {
		printTextWithTrivia(token.text, token);
	}

	function printTextWithTrivia(text:String, triviaToken:Token) {
		printTrivia(triviaToken.leadTrivia);
		buf.add(text);
		printTrivia(triviaToken.trailTrivia);
	}

	function printTrivia(trivia:Array<Trivia>) {
		for (item in trivia) {
			buf.add(item.text);
		}
	}

	public function toString() return buf.toString();
}