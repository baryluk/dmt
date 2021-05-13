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
 * TODO: Support comments.
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

	if (!big.startsWith(small)) {
		return false;
	}
	const size_t l = small.length;
	assert(big.length >= l);
	if (big.length == l) {
		return true;
	}
	if (isalnum(big[l]) || big[l] == '_') {
		return false;
	}
	return true;
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
void decompose(string line, out string pre, out string bdy, out string post)
out {
	import core.stdc.ctype : isspace;

	assert(line == pre ~ bdy ~ post);
	foreach (c; pre) {
		assert(isspace(c));
	}
	if (bdy.length > 0) {
		assert(!isspace(bdy[0]));
		assert(!isspace(bdy[$-1]));
	}
	foreach (c; post) {
		assert(isspace(c));
	}
	if (bdy.length == 0) {
	//	assert(pre.length == 0);
		assert(post.length == 0);
	}
}
body {
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
	debug(dmt) stderr.writef!"decompose split: %d-%d-%d-%d"(0, i0, i1, line.length);
	pre = line[0..i0];
	bdy = line[i0..i1];
	post = line[i1..$];
	debug(dmt) stderr.writefln!": pre='%s',bdy='%s',post='%s'"(pre, bdy, post);
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
	"def",
	"if", "else",
	"for", "foreach", "foreach_reverse",
	"while", "do",
	"struct", "union",
	"class", "interface", "abstract class", "final class",
	"enum",
	"template", "mixin template",
	"body", "in", "out",
	"invariant",
	"try", "catch", "finally",
	"switch", "final switch",
	"case", "default",
	"with",
	"scope(exit)", "scope(failure)", "scope(success)",
	"synchronized",
	"static if", "static foreach", "static foreach_reverse",
	"version",
	"unittest",
	"asm",
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

private struct IndentElement {
	// At what line of the input file, this indent level was introduced.
	int start_line;
	// A non-empty string with used indent.
	string indent_chars;
	// Is this a "normal" indent introduced using `:`, for example `if ...:`, `def:`, or one using line continuation.
	bool bracing;
}

debug(dmt) {
/** Prints stack of indentations */
void printstack(IndentElement[] istack) {
	import std.stdio;

	stderr.writefln("Current istack:");
	foreach (i, il; istack) {
		stderr.writefln("il[%d]='%s' (len=%d) (bracing: %s)", i, il.indent_chars, il.indent_chars.length, il.bracing);
	}
}
}

import std.typecons : Flag, Yes, No;

/** Convert supplied file from Python-like ident style to clasic D source 
 *  with curly brackets.
 *
 * Returns false on failure (i.e. mismatched indentations).
 */
bool convert(string filename, string tempfilename,
             Flag!"RunMode" run_mode = No.RunMode,
             Flag!"PipeMode" pipe_mode = No.PipeMode) {
	assert(!(run_mode && pipe_mode));

	import std.stdio;
	import std.string : startsWith;
	import core.stdc.ctype : isspace;

	auto file = File(filename, "r");
	auto tempfile = pipe_mode ? stdout : File(tempfilename, "w");

	const string tab = "   ";

	// Indentation stack
	IndentElement[] istack;

	// Will identation be needed on next line?
	bool indent_need = false;
	bool waiting_for_else = false;
	// There was a line continuation indicator on previous line?
	bool indent_allow = false;

	int lineno = 0;
	int output_lineno = 0;
	int last_sync_lineno = 0;

	bool processline(string line) {
		last_sync_lineno++;

		if (!pipe_mode) {
			// Only output the '# line' sequences when needed. This
			// speeds up parsing a little, and makes debuging `dmt`
			// converted code easier.
			//
			// Note, that in --pipe mode, we don't emit '# line' sequences
			// for readability.
			if (last_sync_lineno != output_lineno || lineno == 1) {
				// See https://dlang.org/spec/lex.html#special-token-sequence for details.
				tempfile.writefln!"#line %d \"%s\""(lineno, filename);
				last_sync_lineno = output_lineno;
			}
		}

		string pre, bdy, post;
		decompose(line, pre, bdy, post);
		if (bdy == "") {
			debug(dmt) stderr.writefln!"%s:%d: IgnoringInput (blank line): %s"(filename, lineno, line);
			//debug(dmt) {
				// We output the empty lines, just to make output more extra readable,
				// and to reduce the amount of '# line' sequences.
				tempfile.writeln();
				output_lineno++;
			//}
			return true;
		}

		debug assert(bdy != "");

		debug(dmt) {
			stderr.writefln!"Input:%s"(line);
			stderr.writefln!"pre:'%s' (len=%d)"(pre, pre.length);
			stderr.writefln!"bdy:'%s'"(bdy);
			stderr.writefln!"post:'%s'"(post);
			printstack(istack);
		}
		string indent = pre;

		// TODO(baryluk): Move this to a separate helper function.
		size_t i = 0;  // Which levels match.
		size_t last_il_lvl = 0;
		foreach (il_lvl, il; istack) {
			last_il_lvl = il_lvl + 1;
			if (indent[i..$].length > 0) {
				if (indent[i..$].startsWith(il.indent_chars) == false) {
					stderr.writefln!"%s:%d: Indentation error"(filename, lineno);
					return false;
				}
				i += il.indent_chars.length;
			} else {
				last_il_lvl--;
				debug(dmt) writefln!"%s:%d: Back to the last indent"(filename, lineno);
				break;
			}
		}

		debug(dmt) stderr.writefln("%s:%d: We were on %d level of indent", filename, lineno, last_il_lvl);
		size_t left = indent.length - i;
		waiting_for_else = false;
		if (last_il_lvl < istack.length) {
			assert(left == 0);
			for (size_t tempi = 0; tempi < istack.length - last_il_lvl - 1; tempi++) {
				writetimes(tempfile, tab, istack.length - tempi - 1);
				if (istack[istack.length - tempi - 1].bracing) {
					debug(dmt) stderr.writefln!"Closing indent level %d using brace"(istack.length - tempi - 1);
					// Fake comment: { - to make my editor happier.
					tempfile.writeln("}");
					output_lineno++;
				} else {
					debug(dmt) stderr.writefln!"Closing indent level %d without using brace"(istack.length - tempi - 1);
					tempfile.writeln("");
					output_lineno++;
				}
			}
			if (last_il_lvl - 1 >= 0) {
				writetimes(tempfile, tab, last_il_lvl);
				if (istack[last_il_lvl].bracing) {
					// Fake comment: { - to make my editor happier.
					tempfile.write("}");
					output_lineno++;
				}
				waiting_for_else = true;
			}
			istack.length = last_il_lvl;
		} else {
			if (left > 0 && bdy.length > 0) {
				debug(dmt) stderr.writefln!"%s:%d: New indent level: '%s' (len=%d)"(
				    filename, lineno, indent[i..$], indent[i..$].length);
				if (!indent_need) {
					if (bdy.startsWith("//")) {
						// Comment, ignore and do nothing
						// writetimes(tempfile, tab, istack.length);
						// tempfile.writeln(bdy);
						// TODO(baryluk): It might be actually good idea to write it, for ddoc processing.
						return true;
					}
					if (!indent_allow) {
						stderr.writefln!"%s:%d: Unexpected or not allowed indentation. Maybe missed colon (:) on the previous line?"(filename, lineno);
						return false;
					} else {
						debug(dmt) stderr.writefln!"%s:%d: New optional indent, allowing due to previous line having line continuation indicator"(filename, lineno);
					}
				}
				debug(dmt) stderr.writefln!"%s:%d: allowed indent"(filename, lineno);
				bool bracing = true;
				if (indent_allow) {
					bracing = false;  // Indent was introduced after line continuation marker.
				}
				istack ~= IndentElement(lineno, indent[i..$].idup, bracing);
			} else {
				debug(dmt) stderr.writefln!"%s:%d: No additional indent or line is blank"(filename, lineno);
				if (indent_need) {
					stderr.writefln!"%s:%d: Indentation expected"(filename, lineno);
					return false;
				}
			}
		}
		debug(dmt) printstack(istack);

		indent_need = false;
		indent_allow = false;

		debug(dmt) stderr.writef!"%s:%d: Checking if it will be allowed on a next line (bdy='%s'): "(filename, lineno, bdy);
		auto ci = check_if_can_indent(bdy);
		if (ci) {
			debug(dmt) stderr.writefln!"yes ('%s' keyword)"(ci);
			indent_need = true;
			// Remove def from the begin if any.
			if (ci == "def") {
				bdy = bdy[3..$];
			}
			// Remove the space after def, if any.
			// Make this optional, allows use to do: `def:`
			if (bdy.length >= 1 && isspace(bdy[0])) {
				bdy = bdy[1..$];
			}
			if (ci == "case" || ci == "default") {
				if (waiting_for_else) { tempfile.writeln(); output_lineno++; }
				writetimes(tempfile, tab, istack.length);
				// For case and default, both dmt and real-D, require actuall collon at the end.
				// case 5:  -> case 5:
				// default: -> default:
				// However, we still add the {. This could be avoided, and enable few extra
				// features, but I find them error-prone, and almost never used.
				tempfile.writefln!"%s {"(bdy[0..$]);  // Fake comment: } - to make my editor happier.
				output_lineno++;
			} else {
				if (ci != "else") {
					if (waiting_for_else) { tempfile.writeln(); output_lineno++; }
					writetimes(tempfile, tab, istack.length);
				} else {
					tempfile.write(" ");
				}
				// For cases other than case and default, we need to strip the collon at the end.
				// else: -> else {
				// class A : B: -> class A : B {
				tempfile.writefln!"%s {"(bdy[0..$-1]);  // Fake comment: } - to make my editor happier.
				output_lineno++;
			}
		} else if (bdy.length >= 1 && bdy[$-1] == '\\') {
			debug(dmt) stderr.writefln!"no - line continuation next"();
			assert(indent_need == false);
			if (waiting_for_else) { tempfile.writeln(); output_lineno++; }
			writetimes(tempfile, tab, istack.length);
			// Emit the line, without ';' at the end.
			tempfile.writefln!"%s"(bdy[0..$-1]);
			output_lineno++;
			indent_allow = true;  // Allow custom alignment on a next line.
			/* Example:
			 *    writef(a, \
			 *           b)
			 */
		} else if (!indent_need) {
			debug(dmt) stderr.writefln!"no"();
			if (waiting_for_else) { tempfile.writeln(); output_lineno++; }
			writetimes(tempfile, tab, istack.length);
			// TODO(baryluk): Investigate possibility: Don't add ';', if there is already ';' at the end.
			tempfile.writefln!"%s;"(bdy);
			output_lineno++;
		} else {
			debug(dmt) stderr.writefln!"what?"();
			assert(0);
		}

		debug(dmt) stderr.writeln();
		return true;
	}

	foreach(ref line; file.byLine) {
		lineno++;

		if (run_mode && lineno == 1) {
			if (line.startsWith("#!")) {
				// Emit an empty line, so line numbers match in temporary file.
				tempfile.writeln();
				continue;
			} else {
				stderr.writefln("%s:%d: Expected #! on the first line, when in --run mode!", filename, lineno);
				return false;
			}
		}

		// FIXME(baryluk): byLine returns char[], but we can safely cast it to
		// a string, because we dont presist references to line after processing it.
		if (processline(cast(string)line) == false) {
			return false;
		}

	}

	// Close any remaining indentations opened so far.
	debug(dmt) stderr.writeln("End of file. Closing any remaining indentations.");
	for (size_t tempi = 0; tempi < istack.length; tempi++) {
		if (istack[istack.length - tempi - 1].bracing) {
			writetimes(tempfile, tab, istack.length - tempi - 1);
			tempfile.writefln("}");
		}
	}

	if (!pipe_mode) {
		tempfile.close();
	}

	return true;
}

int main(string[] args) {
	import std.file : exists, remove;
	import std.string : startsWith, endsWith, toStringz;
	import std.path : stripExtension, setExtension;

	if (args.length == 1) {
		writef("D Indentation Converter v1.2\n"
			~ "Copyright (c) 2006, 2011, 2021, Witold Baryluk <witold.baryluk@gmail.com>\n"
			~ "Usage:\n"
			~ "\t%s [--keep | --convert | --overwrite | --pipe | --run] files.dt... other_files args\n", args[0]);
		return 1;
	}

	string[] filenames;
	string[] tempfilenames;

	bool keep_tempfile = false;
	bool just_convert = false;
	bool allow_overwrite = false;
	auto run_mode = No.RunMode;
	auto pipe_mode = No.PipeMode;

	foreach (arg; args[1..$]) {
		if (arg == "--keep") {
			keep_tempfile = true;
			continue;
		}
		if (arg == "--convert") {
			just_convert = true;
			continue;
		}
		if (arg == "--overwrite") {
			allow_overwrite = true;
			continue;
		}
		if (arg == "--run") {
			run_mode = Yes.RunMode;
			continue;
		}
		if (arg == "--pipe") {
			pipe_mode = Yes.PipeMode;
			continue;
		}
		filenames ~= arg;
	}

	if (filenames.length == 0) {
		stderr.writefln("No filenames specified");
		return 1;
	}

	if (pipe_mode && run_mode) {
		stderr.writefln("--pipe and --run can not be specified at the same time");
		return 1;
	}

	if (pipe_mode) {
		if (filenames.length != 1) {
			stderr.writefln("Exactly one .dt file expected when using --pipe");
			return 1;
		}
	}

	bool convert_failed = false;

	string[] dmd_args;
	string[] run_args;

	// Convert all specified files.
	foreach (filename; filenames) {
		// In --run mode we only convert the first file, rest of arguments is passed as program arguments.
		if (run_mode) {
			if (tempfilenames.length >= 1) {
				run_args ~= filename;
				continue;
			}
		}

		if (filename.startsWith("-")) {
			// Pass other options directly to DMD unchanged.
			dmd_args ~= filename;
			continue;
		}

		if (!filename.endsWith(".dt")) {
			// Pass .d and .o files directly to DMD.
			if (filename.endsWith(".d") || filename.endsWith(".o")) {
				dmd_args ~= filename;
				continue;
			} else {
				stderr.writefln("Unknown file type: %s", filename);
				return 1;
			}
		}

		if (!exists(filename)) {
			stderr.writefln("Aborting due to missing input file %s", filename);
			return 1;
		}

		const string basename = filename.stripExtension;
		if (basename.length == 0) {
			stderr.writefln("Empty basename");
			return 1;
		}
		const string tempfilename = basename ~ ".d";
		// const string tempfilename = basename.setExtension(".d");

		if (exists(tempfilename) && !pipe_mode) {
			if (!allow_overwrite) {
				stderr.writefln("Aborting due to existing temporary file %s", tempfilename);
				return 1;
			} else {
				stderr.writefln("Will overwrite existing temporary file %s", tempfilename);
			}
		}

		if (convert(filename, tempfilename, run_mode, pipe_mode) == false) {
			stderr.writefln("Convert failed for file %s", filename);
			convert_failed = true;
			if (!pipe_mode && exists(tempfilename)) {
				remove(tempfilename);
			}
			// TODO(baryluk): Cleanup other tempfiles
			return 1;
		}

		tempfilenames ~= tempfilename;
		dmd_args ~= tempfilename;
	}

	if (tempfilenames.length == 0) {
		stderr.writefln("No filenames specified");
		return 1;
	}

	int ret = 0;
	if (convert_failed) {
		ret = 1;
	} else {
		if (!just_convert && !pipe_mode) {
			import std.process : environment;

			const string DMD = environment.get("DMD", "dmd");

			string cmd = DMD;

			if (run_mode) {
				cmd ~= " -run";
			}

			foreach (dmd_arg; dmd_args) {
				// Compose the command line of files and pass-thrugh options.
				// TODO(baryluk): Test filenames with space.
				cmd ~= " " ~ dmd_arg;
			}

			if (run_mode) {
				// cmd ~= " --run";

				foreach (run_arg; run_args) {
					cmd ~= " " ~ run_arg;
				}
			}

			import core.stdc.stdlib : system;

			stderr.writeln(cmd);

			// TODO(baryluk): Use std.process.spawnShell instead.
			ret = system(cmd.toStringz);
		}
	}

	if (!just_convert && !pipe_mode) {
		foreach (tempfilename; tempfilenames) {
			if (exists(tempfilename)) {
				if (!keep_tempfile) {
					try {
						remove(tempfilename);
					} catch (Exception e) {
						stderr.writefln("Could not remove temporary file %s", tempfilename);
					}
				}	else {
					stderr.writefln("Keeping temporary file %s for source file %s", tempfilename, tempfilename);
				}
			}
		}
	}

	return ret;
}
