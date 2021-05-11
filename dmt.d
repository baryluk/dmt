/* Python-like indentation for Digital Mars D
 * Version: 1.1
 * Author: Witold Baryluk <witold.baryluk@gmail.com>
 * Copyright 2006, 2011, 2021
 * Licence: BSD
 * ---
 * This package may be redistributed under the terms of the UCB BSD
 * license:
 * 
 * Copyright (c) Witold Baryluk
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 4. Neither the name of the Witold Baryluk nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ---
 */

/**
 * TODO: Support line continuation operator (\ - backslash)
 *       and comments.
 *       Fix line numbering
 *       case, default should not add new {
 *       Brackets in if, switch shouldn't be needed
 *       print => writefln, print ..., => writef transl.
 *       There shouldn't be new line before else
 */

module dmt;

import std.stdio;

/** Check if 'small' is at the start of 'big', and that
 * after small there is no alphanumeric character or underscore (_).
 *
 *
 * Basically it checks if the first "word" of the 'big' is
 * same as 'small'. It is somehow similar to a regular expression
 * pattern ending with \b.
 *
 *  For example:
 *
 *    strcmp_first2("abc", "abc") is true.
 *    strcmp_first2("abc def", "abc") is true.
 *    strcmp_first2("abc(def", "abc") is true.
 *
 *    strcmp_first2("abc3def", "abc") is false.
 */
bool strcmp_first2(string big, string small)
in {
	assert(small.length > 0);
}
body {
	import std.string : startsWith;
	import core.stdc.ctype : isalnum;

	if (big.startsWith(small) == false) {
		return false;
	} else {
		size_t l = small.length;
		if (big.length > l) {
			if (isalnum(big[l]))
				return false;
			if (big[l] == '_')
				return false;	
			return true;
		} else {
			return true;
		}
	}
}
unittest {
	assert(strcmp_first2("abcdef", "abc") == false);
	assert(strcmp_first2("babc", "bab") == false);
	assert(strcmp_first2("bab", "bab") == true);
	assert(strcmp_first2("bab ", "bab") == true);
	assert(strcmp_first2("bab as", "bab") == true);
	assert(strcmp_first2("bab:", "bab") == true);
	assert(strcmp_first2("bab(", "bab") == true);
	assert(strcmp_first2("bab_", "bab") == false);
	assert(strcmp_first2("bab1", "bab") == false);
	assert(strcmp_first2("ba", "bab") == false);
	assert(strcmp_first2("na", "janb") == false);
	assert(strcmp_first2("nab", "ab") == false);
}

/** Decompose line into whitespace prefix (indent), body, and postfix
 * (with eventual comment, and \) */
void decompose(string line, out string pre, out string bdy, out string post) {
	import core.stdc.ctype : isspace;

	size_t i0;  // index of first non white char
	size_t i1;  // index of last non whie char

	for (i0 = 0; i0 < line.length; i0++) {
		if (!isspace(line[i0])) break;
	}
	if (i0 < line.length) {
		for (i1 = line.length-1; i1 >= i0 && i1 >= 0; i1--) {
			if (!isspace(line[i1])) break;
		}
		i1++;
	} else {
		i1 = line.length;
	}
	debug(dmt) writefln("%d-%d-%d-%d", 0, i0, i1, line.length);
	pre = line[0..i0];
	bdy = line[i0..i1];
	post = line[i1..$];
	debug(dmt) writefln("pre='%s',bdy='%s',post='%s'", pre, bdy, post);
}
unittest {
	string a, b, c;
	decompose("", a, b, c);
	assert(a == "" && b == "" && c == "");
	decompose(" ", a, b, c);
	assert(a == " " && b == "" && c == "");
	decompose("d", a, b, c);
	assert(a == "" && b == "d" && c == "");
	decompose("ad", a, b, c);
	assert(a == "" && b == "ad" && c == "");
	decompose(" d", a, b, c);
	assert(a == " " && b == "d" && c == "");
	decompose("d ", a, b, c);
	assert(a == "" && b == "d" && c == " ");
	decompose(" d ", a, b, c);
	assert(a == " " && b == "d" && c == " ");
	decompose("  d ", a, b, c);
	assert(a == "  " && b == "d" && c == " ");
	decompose("  df ", a, b, c);
	assert(a == "  " && b == "df" && c == " ");
}

/** Table of D langugage keywords which can introduce new indentation level */
immutable string[] can_indent = [
	"if", "else", "for", "foreach", "foreach_reverse",
	"while", "try", "catch", "def", "switch", "case", "version", "finally",
	"body", "in", "out", "invariant", "class", "struct", "template",
	"default", "do", "unittest", "enum", "union",
];

/** Check if m1 introduces a new indentation level, if so return the keyword
 * name of the keybord responsible.
 *
 * `def` and `case` keywords for example can have slightly different semantic.
 *
 * `m1` should already have leading and trailing whitespaces removed,
 * as computed in `bdy` output argument of `decompose` function.
 */
string check_if_can_indent(string m1)
in {
	assert(m1.length > 0);
}
body {
	foreach (ci; can_indent) {
		if (strcmp_first2(m1, ci) == true && m1[$-1] == ':') {
			return ci;
		}
	}
	return null;
}
unittest {
	assert(check_if_can_indent("def void ala():") == "def");
	assert(check_if_can_indent("enum E:") == "enum");
	assert(check_if_can_indent("class C(string s, T) if (s.length > 5):") == "class");
	assert(check_if_can_indent("if (x > f(x)):") == "if");
	assert(check_if_can_indent("else:") == "else");
	assert(check_if_can_indent("import std.stdio") is null);
	assert(check_if_can_indent("int a = 5") is null);
}

/** Repeats string 's' 'times' time on the output 'output'. */
void writetimes(OutputStream)(OutputStream output, string s, size_t times)
in {
	assert(s.length > 0);
}
body {
	for (size_t i = 0; i < times; i++)
		output.writef("%s", s);
}

debug(dmt) {
/** Prints stack of indentations */
void printstack(string[] istack) {
	writefln("Current istack:");
	foreach (i, il; istack) {
		writefln("il[%d]='%s' (len=%d)", i, il, il.length);
	}
}
}

/** Convert supplied file from Python-like ident style to clasic D source 
 *  with curly brackets.
 *
 * Returns false on failure (i.e. mismatched indentations).
 */
bool convert(string filename, string tempfilename) {
	import std.stdio;
	import std.string : startsWith;
	import core.stdc.ctype : isspace;

	auto file = File(filename, "r");
	auto tempfile = File(tempfilename, "w");

	const string tab = "   ";

	// Indentation stack
	string[] istack;

	// Will identation be needed on next line?
	bool indent_need = false;
	bool waiting_for_else = false;

	bool processline(string line) {
		string pre, bdy, post;
		decompose(line, pre, bdy, post);
		if (bdy == "") {
			debug(dmt) writefln("IgnoringInput (blank line):%s", line);
			debug(dmt) tempfile.writefln();
			return true;
		}

		debug assert(bdy != "");

		debug(dmt) {
			writefln("Input:%s", line);
			writefln("pre:'%s' (len=%d)", pre, pre.length);
			writefln("bdy:'%s'", bdy);
			writefln("post:'%s'", post);
			printstack(istack);
		}
		string indent = pre;


		// TODO(baryluk): Move this to a separate helper function.
		size_t i = 0;
		size_t last_il_lvl = 0;
		foreach (il_lvl, il; istack) {
			last_il_lvl = il_lvl + 1;
			if (indent[i..$].length > 0) {
				if (indent[i..$].startsWith(il) == false) {
					writefln("Indentation error");
					return false;
				}
				i += il.length;
			} else {
				last_il_lvl--;
				debug(dmt) writefln("Back to the last indent");
				break;
			}
		}

		debug(dmt) writefln("We were on %d level of indent", last_il_lvl);
		size_t left = indent.length - i;
		waiting_for_else = false;
		if (last_il_lvl < istack.length) {
			assert(left == 0);
			for (size_t tempi = 0; tempi < istack.length - last_il_lvl - 1; tempi++) {
				writetimes(tempfile, tab, istack.length - tempi - 1);
				// Fake comment: { - to make my editor happier.
				tempfile.writefln("}");
			}
			if (last_il_lvl - 1 >= 0) {
				writetimes(tempfile, tab, last_il_lvl);
				// Fake comment: { - to make my editor happier.
				tempfile.writef("}");
				waiting_for_else = true;
			}
			istack.length = last_il_lvl;
		} else {
			if (left > 0 && bdy.length > 0) {
				debug(dmt) writefln("New indent level: '%s' (len=%d)",
				    indent[i..$], indent[i..$].length);
				if (!indent_need) {
					writefln("Unallowed indentation");
					return false;
				}
				debug(dmt) writefln("allowed");
				istack ~= indent[i..$].idup;
			} else {
				debug(dmt) writefln("No additional indent or line is blank");
				if (indent_need) {
					writefln("Indentation expected");
					return false;
				}
			}
		}
		debug(dmt) printstack(istack);

		indent_need = false;

		debug(dmt) writef("Checking if it will be allowed on a next line (bdy='%s'): ", bdy);
		auto ci = check_if_can_indent(bdy);
		if (ci) {
			debug(dmt) writefln("yes ('%s' keyword)", ci);
			indent_need = true;
			// Remove def from the begin if any.
			if (ci == "def") {
				bdy = bdy[3..$];
			}
			if (bdy.length >= 1 && isspace(bdy[0])) {
				bdy = bdy[1..$];
			}
			if (ci == "case" || ci == "default") {
				if (waiting_for_else) tempfile.writeln();
				writetimes(tempfile, tab, istack.length);
				// For case and default, both dmt and real-D, require actuall collon at the end.
				// case 5:  -> case 5:
				// default: -> default:
				// However, we still add the {. This could be avoided, and enable few extra
				// features, but I find them error-prone, and almost never used.
				tempfile.writefln("%s {", bdy[0..$]);  // Fake comment: } - to make my editor happier.
			} else {
				if (ci != "else") {
					if (waiting_for_else) tempfile.writeln();
					writetimes(tempfile, tab, istack.length);
				} else {
					tempfile.writef(" ");
				}
				// For cases other than case and default, we need to strip the collon at the end.
				// else: -> else {
				// class A : B: -> class A : B {
				tempfile.writefln("%s {", bdy[0..$-1]);  // Fake comment: } - to make my editor happier.
			}
		}
		if (!indent_need) {
			debug(dmt) writefln("no");
			if (waiting_for_else) tempfile.writeln();
			writetimes(tempfile, tab, istack.length);
			// TODO(baryluk): Investigate possibility: Don't add ';', if there is already ';' at the end.
			tempfile.writefln("%s;", bdy);
		}

		debug(dmt) writefln();
		return true;
	}

	foreach(ref line; file.byLine) {
		// FIXME(baryluk): byLine returns char[], but we can safely cast it to
		// a string, because we dont presist references to line after processing it.
		if (processline(cast(string)line) == false)
			return false;
	}

	// Close any remaining indentations opened so far.
	for (size_t tempi = 0; tempi < istack.length; tempi++) {
		writetimes(tempfile, tab, istack.length - tempi - 1);
		tempfile.writefln("}");
	}

	tempfile.close();

	return true;
}

int main(string[] args) {
	import std.file : exists, remove;
	import std.string : endsWith, toStringz;
	import std.path : stripExtension, setExtension;

	if (args.length == 1) {
		writef("D Indentation Converter v1.2\n"
			~ "Copyright (c) 2006, 2011, 2021, Witold Baryluk <witold.baryluk@gmail.com>\n"
			~ "Usage:\n"
			~ "\t%s files.dt...\n", args[0]);
		return 1;
	}

	// Process files one by one
	foreach (filename; args[1..$]) {
		if (!filename.endsWith(".dt")) {
			writefln("Unknown file type: %s", filename);
			return 1;
		}
		const string basename = filename.stripExtension;
		if (basename.length == 0) {
			writefln("Empty basename");
			return 1;
		}
		const string tempfilename = basename ~ ".d";
		// const string tempfilename = basename.setExtension(".d");
		// TODO(baryluk): Add option to overwrite without question.
		if (exists(tempfilename)) {
			writefln("Temporary file exists, aborting.");
			return 1;
		}

		try {
			if (convert(filename, tempfilename) == false) {
				if (exists(tempfilename)) {
					remove(tempfilename);
				}
				return 1;
			}

			import std.process : environment;

			const string DMD = environment.get("DMD", "dmd");
			const string cmd = DMD ~ " " ~ tempfilename;
			stderr.writeln(cmd);

			import core.stdc.stdlib : system;

			// TODO(baryluk): Use std.process.spawnShell instead.
			int ret = system(cmd.toStringz);
			// TODO(baryluk): Add option to keep the temporary file.
			remove(tempfilename);
			if (ret != 0) {
				return ret;
			}
		} finally {
			if (exists(tempfilename)) {
				remove(tempfilename);
			}
		}
	}

	return 0;
}
