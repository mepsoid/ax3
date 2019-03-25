package ax3.filters;

class InlineStaticConsts extends AbstractFilter {
	override function processClassField(field:TClassField) {
		switch field.kind {
			case TFVar(v):
				@:nullSafety(Off) // TODO: minimize and report this
				var isConstantLiteral = switch v {
					case {kind: VConst(_), vars: [{init: {expr: {kind: TELiteral(_)}}}]}: true;
					case _: false;
				}

				if (isConstantLiteral) {
					v.isInline = true;
					// TODO: deal with leading trivia here
					if (!Lambda.exists(field.modifiers, m -> m.match(FMStatic(_)))) {
						field.modifiers.push(FMStatic(new Token(0, TkIdent, "static", [], [mkWhitespace()])));
					}
				}

			case _:
		}
	}
}
