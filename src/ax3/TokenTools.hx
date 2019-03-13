package ax3;

import ax3.Token;

class TokenTools {
	public static function containsOnlyWhitespace(tr:Array<Trivia>):Bool {
		for (t in tr) {
			if (t.kind != TrWhitespace) {
				return false;
			}
		}
		return true;
	}

	public static function mkTokenWithSpaces(kind:TokenKind, text:String):Token {
		return new Token(0, kind, text, [new Trivia(TrWhitespace, " ")], [new Trivia(TrWhitespace, " ")]);
	}

	public static inline function mkEqualsEqualsToken():Token {
		return mkTokenWithSpaces(TkEqualsEquals, "==");
	}

	public static inline function mkNotEqualsToken():Token {
		return mkTokenWithSpaces(TkExclamationEquals, "!=");
	}

	public static inline function mkAndAndToken():Token {
		return mkTokenWithSpaces(TkAmpersandAmpersand, "&&");
	}
}