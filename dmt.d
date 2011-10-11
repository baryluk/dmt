/* Python-like indentation for Digital Mars D
 * Version: 1.0
 * Author: Witold Baryluk <baryluk@smp.if.uj.edu.pl>
 * Copyright 2006
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
import std.stream;
import std.ctype;
import std.file;
import std.process;
import std.cstream;

/** Check if small is on the begining of big */
bool strcmp_first(string big, string small)
in {
	assert(small.length > 0);
}
body {
	size_t l = small.length;
	if (l > big.length)
		return false;
	if (big[0..l] == small)
		return true;
	return false;
}
unittest {
	assert(strcmp_first("abcdef", "abc") == true);
	assert(strcmp_first(" sda", "sd") == false);
	assert(strcmp_first(" \tabc", " abc") == false);
	assert(strcmp_first(" abc", " \tab") == false);
	assert(strcmp_first("babc", "bab") == true);
	assert(strcmp_first("babc", "ban") == false);
	assert(strcmp_first("  abcdef", " abc") == false);
	assert(strcmp_first("babc", "banca") == false);
	assert(strcmp_first("babc", "vagcaa") == false);
}

/** Similar to strcmp_first2,
	but after small cann't be digit, char, or underscore (_) */
bool strcmp_first2(string big, string small)
in {
	assert(small.length > 0);
}
body {
	if (strcmp_first(big, small) == false) {
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

/++
/** Prints stack of indentations */
void printstack(string[] istack) {
	writefln("Current istack:");
	foreach (i, il; istack) {
		writefln("il[%d]='%s' (len=%d)", i, il, il.length);
	}
}
++/

/** Table of D langugage keywords which can introduce new indentation level */
string[] canindent = ["if", "else", "for", "foreach", "foreach_reverse",
	"while", "try", "catch", "def", "switch", "case", "version", "finally",
	"body", "in", "out", "invariant", "class", "struct", "template",
	"default", "do", "unittest", "enum", "union"];

/** Decompose line into whitespace prefix (indent), body, and postfix
 * (with eventual comment, and \) */
void decompose(string line, out string pre, out string bdy, out string post) {
	int i0; // index of first non white char
	int i1; // index of last non whie char

	for (i0 = 0; i0 < line.length; i0++)
		if (!isspace(line[i0])) break;
	if (i0 < line.length) {
		for (i1 = line.length-1; i1 >= i0 && i1 >= 0; i1--)
			if (!isspace(line[i1])) break;
		i1++;
	} else {
		i1 = line.length;
	}
//	writefln("%d-%d-%d-%d", 0,i0,i1,line.length);
	pre = line[0..i0];
	bdy = line[i0..i1];
	post = line[i1..$];
//	writefln("pre='%s',bdy='%s',post='%s'", pre, bdy, post);
}
unittest {
	string a,b,c;
	decompose("",a,b,c);
	assert(a == "" && b == "" && c == "");
	decompose(" ",a,b,c);
	assert(a == " " && b == "" && c == "");
	decompose("d",a,b,c);
	assert(a == "" && b == "d" && c == "");
	decompose("ad",a,b,c);
	assert(a == "" && b == "ad" && c == "");
	decompose(" d",a,b,c);
	assert(a == " " && b == "d" && c == "");
	decompose("d ",a,b,c);
	assert(a == "" && b == "d" && c == " ");
	decompose(" d ",a,b,c);
	assert(a == " " && b == "d" && c == " ");
	decompose("  d ",a,b,c);
	assert(a == "  " && b == "d" && c == " ");
	decompose("  df ",a,b,c);
	assert(a == "  " && b == "df" && c == " ");
}

void writetimes(OutputStream output, string s, int times)
in {
	assert(times >= 0);
	assert(s.length > 0);
}
body {
	for (int i = 0; i < times; i++)
		output.writef("%s", s);
}

/** Convert supplied file from Python-like ident style to clasic D source 
 *  with curly brackets. */
bool Convert(string filename, string tempfilename) {
	auto file = new BufferedFile(filename, FileMode.In);
	auto tempfile = new BufferedFile(tempfilename, FileMode.Out);

	const string tab = "   ";

	// Indentation stack
	string[] istack;

	// will be identation be needed on next line?
	bool indent_need = false;
	bool waiting_for_else = false;

	bool processline(string line) {
		string m[3];
		decompose(line,m[0],m[1],m[2]);
		if (m[1] != "") {
//			writefln("Input:%s", line);
//			writefln("m1:'%s' (len=%d)", m[0], m[0].length);
//			writefln("m2:'%s'", m[1]);
//			writefln("m3:'%s'", m[2]);
//			printstack(istack);
			string indent = m[0];

			size_t i = 0;
			size_t last_il_lvl = 0;
			foreach (il_lvl, il; istack) {
				last_il_lvl = il_lvl+1;
				if (indent[i..$].length > 0) {
					if (strcmp_first(indent[i..$], il) == false) {
						writefln("Indentation error");
						return false;
					} else {
						i += il.length;
					}
				} else {
					last_il_lvl--;
//					writefln("Back to then last indent");
					break;
				}
			}

//			writefln("We were on %d level of indent", last_il_lvl);
			size_t left = indent.length-i;
			waiting_for_else = false;
			if (last_il_lvl < istack.length) {
				assert(left == 0);
				for (size_t tempi=0; tempi < istack.length - last_il_lvl-1; tempi++) {
					writetimes(tempfile, tab, istack.length-tempi-1);
					tempfile.writefln("}");
				}
				if (last_il_lvl-1 >= 0) {
					writetimes(tempfile, tab, last_il_lvl);
					tempfile.writef("}");
					waiting_for_else = true;
				}
				istack.length = last_il_lvl;
			} else {
				if (left > 0 && m[1].length > 0) {
//					writefln("New indent level: '%s' (len=%d)",
//						indent[i..$], indent[i..$].length);
					if (indent_need) {
//						writefln("allowed");
						istack ~= indent[i..$].idup;
					} else {
						writefln("Unallowed indetation");
						return false;
					}
				} else {
//					writefln("No additional indent or line is blank");
					if (indent_need) {
						writefln("Indetation expected");
						return false;
					}
				}
			}
//			printstack(istack);

//			writef("Checking if it will be allowed on next line (m[1]='%s'): ", m[2]);
			indent_need = false;
			foreach (ci; canindent) {
				if (strcmp_first2(m[1], ci) == true && m[1][$-1] == ':') {
//					writefln("yes ('%s' keyword)", ci);
					indent_need = true;
					// Remove def from the begin
					if (strcmp_first2(m[1], "def")) {
						m[1] = m[1][3..$];
					}
					if (isspace(m[1][0])) {
						m[1] = m[1][1..$];
					}
					if (strcmp_first2(m[1], "case") || strcmp_first2(m[1], "default")) {
						if (waiting_for_else) tempfile.writefln();
						writetimes(tempfile, tab, istack.length);
						tempfile.writefln("%s {", m[1][0..$]);
					} else {
						if (!strcmp_first2(m[1], "else")) {
							if (waiting_for_else) tempfile.writefln();
							writetimes(tempfile, tab, istack.length);
						} else {
							tempfile.writef(" ");
						}
						tempfile.writefln("%s {", m[1][0..$-1]);
					}
					break;
				}
			}
			if (!indent_need) {
//				writefln("no");
				if (waiting_for_else) tempfile.writefln();
				writetimes(tempfile, tab, istack.length);
				tempfile.writefln("%s;",m[1]);
			}

//			writefln();
		} else {
//			writefln("IgnoringInput (blank line):%s", line);
//			tempfile.writefln();
			;
		}
		return true;
	}

	/// TODO: this should be ref string line, with no casts, see bug
	foreach(ref char[] line; file) {
		/// FIXME: This just hack with cast
		if (processline(cast(string)line) == false)
			return false;
	}

	for (size_t tempi=0; tempi < istack.length; tempi++) {
		writetimes(tempfile, tab, istack.length-tempi-1);
		tempfile.writefln("}");
	}

	tempfile.close();

	return true;
}

int main(string[] args) {
	if (args.length == 1) {
		writef("D Indentation Converter v1.0\n"
			"Copyright (c) 2006 Witold Baryluk <baryluk@smp.if.uj.edu.pl>\n"
			"Usage:\n"
			"\t%s files.dt...\n", args[0]
		);
		
		return 1;
	}

	/* Process files */
	foreach (filename; args[1..$]) {
		if (filename.length < 3 || filename[$-3..$] != ".dt") {
			writefln("Unknown file type: %s", filename);
			return 1;
		}
		string basename = filename[0..$-3];
		if (basename.length == 0) {
			writefln("Empty basename");
			return 1;
		}
		string tempfilename = basename~".d";
		if (exists(tempfilename)) {
			writefln("Temporary file exists, aborting.");
			return 1;			
		}
		if (Convert(filename, tempfilename) == false) {
			if (exists(tempfilename)) {
				std.file.remove(tempfilename);
			}
			return 1;
		}
		string DMD = environment.get("DMD", "dmd");
		string c = DMD ~ " " ~ tempfilename;
		derr.writeLine(c);
		int ret = system(c);
		std.file.remove(tempfilename);
		if (ret != 0) {
			return ret;
		}
	}
	return 0;
}
