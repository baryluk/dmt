# Python-like indentation in D programming language

This is a simple, yet powerful, code translator allowing to use Python-like
syntax to write D programs.

It operates by interpreting indents, and some keywords to translate it to a
standard D programming language program.

Functions need to be prefixed by `def`, to make it clear to the parser that they
are functions. Other whitelisted constructs do not require that, as they
already start with a specific keyword and finish with a colon.

This allows to write D code like this:

```d
import std.stdio

class A:
  public:
  int f
  def this():
    f = 4
    writefln("Constructor")
  def ~this():
    writefln("Deconstructor")

  def void times(int k):
    writefln("%d", k * g())

  private:
  def int g():
    return f + 5

def int main(string[] args):
  auto a = new A()
  a.times(10)
  return 0
```

See `tests/test*.dt` files for more examples.

Enjoy.

## Usage

By default `dmt` tool will convert a source code in files ending with the `.dt`
extension, and pass it to a D compiler. By default the `dmd` compiler will be
used. The compiler can be changed by environment variable `DMD`, for example:
`DMD=ldc2 dmt test4.dt`. If multiple files are passed, they are all converted and
passed together to `dmd`.

Options:

- `--keep` - keep transformed temporary files (`.d` files)
- `--convert` - just convert and keep temporary files, do not call `dmd` or remove files.
- `--overwrite` - overwrite temporary files if they already exist
- `--run` - compile first `.dt` source and run it, passing remaining arguments
- `--pipe` - transform a single `.dt` file to `.d` and output it on a standard
output.

`*.d` and `*.o` arguments, and all other options starting with a dash, like for
example `-O`, `-inline`, `-c`, are passed to `dmd` untouched in the same order
and relations to file as on the `dmt` command line.


### `#!` (sh-bang) support.

Just add on a first line of the "script" this:

```sh
#!/usr/bin/env -S dmt --run
```

and make the script executable. And make sure that `dmt` is in your `PATH` (or
use an absolute path to dmt). Extra arguments from the execution will be passed
to your script `main` function as normal.

You can change `dmd` to `ldc2` using `DMD=ldc2` environment variable, or do it
explicitly in the script `#!`:

```sh
#!/usr/bin/env -S DMD=ldc2 dmt --run
```

You can also manually run script, by using `-run` when invoking `dmt`:

```sh
dmt -run foo.dt
```

You can pass multiple source files if you wish.

Using `import std` to import entire Phobos is handy, but if you script is on a
network connected file system (like `sshfs`), it will considerably slow down the
compilation, as the compiler is trying to find files to import relative to the
currently compiled file first, and parse more files too. It is ok for some
prototyping, but importing more specific modules is a better long term solution
(less likely to break too).

## Building

`dmt` has just one source file: `dmt.d`. Compile it as you like into executable,
using your favorite D compiler.

You can also just use `make` (if using dmd), or `DMD=ldc2 DMDFLAGS= make` (if
using ldc), or `DMD=gdc DMDFLAGS= make` (if using gdc).

## Indentation

Indentations only follow after a line starts with a specific keyword, and is
finished with colon.

For example:

```d
  if (x):
     f()
  ...
```

Function and methods should be prefixed with `def`:

```d
def int f(int b, int c):
  ...
  
  
class C:
  def int f():
     ...
```

If you want to declare a function (i.e. C function) or define an interface
method, you can do that on a single line without using `def`, just be sure not to
finish it with the colon. Semicolon (`;`) is optional and should be avoided, as
`dmt` will add one for you.


```d
extern(C) int g(int a, char* c)

interface IFoo:
  int f()
```

### List of keywords introducing indents (if line finishes with colon):

- `def`
- `if`, `else`
- `for`, `foreach`, `foreach_reverse`
- `while`, `do`
- `struct`, `union`
- `class`, `interface`, `abstract class`, `final class`
- `enum` (but read limitations section how to use them)
- `template`
- `mixin` template definition
- `in`, `out`, `body` sections of a function, method or interface contract
- `invariant`
- `try`, `catch`, `finally`
- `switch`, `final switch`
  - `case` and `default` can be indented or not, your choice
- `with`
- `scope(exit)`, `scope(failure)`, `scope(success)`
  - only these three, with no spaces between tokens.
- `synchronized`
- `static if`, `static foreach`, `static foreach_reverse`
- `version`
- `unittest`
- `asm`


Note: `scope class` (storage type constraint on class instances) is not
supported, becasue it is officially deprecated feature of the language, and might
be removed in the future. If you really want to use it, use
`def scope class ...:`

### Multi-line array literls and expressions

Arrays and associative arrays, unfortunately can't be formatted with alignment
or indents at the moment:

```d
int[] a = [
  1,
  2,
  3,
]
```

will not work. Sorry.

### `enum`s

Also `enum` support is limited, but can be done with some workarounds:

```d
enum E { A, B, }
```

```d
enum E:
  A, \
  B \
```


### Line-end continuation:

Examples:

```d
  def auto f():
     return x + \
     y + z
```

and

```d
  def auto f():
     return x + \
            y + z
```

### Multi-line alignment using line-end continuation

Examples:

```d
writeln(a, b, \
        c + 5)
```

```d
int z = (a + b + \
         c + d)
```

## Indentation semantics

You can use space or tabs, or mix of them. But consistency is required for
matching indent levels.

If you open a new indent level, the next line must have the same indent as the
previous line + new indent.

So for example, this is allowed:

```d
  if (a):
  \tif (b):
  \t  if (c):
  \t    f(a, b, c)
```

but this is not:

```d
  if (a):
  \tif (b):
      if (c)
  \t    f(a, b, c)
```

Also, the `if`/`else`, `in`/`out`/`body`, `case`/`default`,
`try`/`catch`/`finally` must match properly:

This is ok:

```d
  if (a):
    if (b):
      f(a, b)
  else:
    f(0, 0)
```

but this is not:

```d
  if (a):
    if (b):
      f(a, b)
   else:
     f(0, 0)
```

Indentations INSIDE the `if`/`else` (and other matching ones) blocks can differ if
you want.

This is ok, but is not recommended:

```d
  if (a):
    f(a)
  else:
       f(0)
```

Multi-statement lines. You can put multiple statements on a line, by simply using
semicolon:

```d
  if (a):
    f(a); g(a)
  else:
       f(0); g(0)
```

You should avoid putting a semicolon (`;`) after the last statement, as this will
most likely trigger a D compiler warning.

Empty blocks. You can put an empty block, by not indenting, or by putting
manually `{}` as an empty statement:

```d
  while (a-- && b--):
  writefln(a, b)
```

or more readable:

```d
  while (a-- && b--):
    {}
  writefln(a, b)
```

If you are unhappy with this form, create a nop function called `pass`, and do:

```d
  while (a-- && b--):
    pass
  writefln(a, b)
```


Non-indented forms. It is possible to do non-indented forms, by omitting the
colon at end, like:

```d
  if (a) f(a)
```

```d
  while (a--) writefln(a)
```

Note, that you can't do more than one statement, unless you actually put it in
brackets

```d
  if (a) f(a); g(a)    // WRONG / MISLEADING
```

Because, this will call `g` even if `f` is not called. This is because this code
is literally translated to D just like on the input (plus semicolon at the end).

Use instead:

```d
  if (a) { f(a); g(a); }  // BETTER
```


For the same reason, you should be careful about opening curly brackets

```d
  if (a) { f(a);
  g(a); }
```

It works, but defeats the entire purpose of the `dmt`.

Also, at the moment `dmt` is kind of all or nothing. You can't just throw an
existing D code into it, because it most likely has indent in it, that will not
work. At least `dmt` will detect it:

```d
  if (a) {
    f(a);    // UNEXPECTED INDENT
    g(a);
  }
```

In the future it might be possible to add `pragma` or comment based directives,
to enable / disable `dmt` processing.

Another issue is commenting blocks of code:

```d
def void f(int a):
  /+
  if (a):
    return 5;
  else:
    if (a > 10):
      return a * 10
    return 1
  +/
```

Will not-work. Because of unexpected indent in the processed lines.

The line continuation marker (`\` at the end of the line), allows you do indent
next line arbitarly, and does not introduce the `{` in translated code. The line
continuation can be continued on subsequent lines, but should respect
indentations and de-indentations.

```d
writeln(a + (c \
             + d * (x \
                    - y) \
             + e))
```

should work. Additionally, it is allowed to put comments between such lines:

```d
auto x = a \
         + b \
         // foo bar
         + c \
         + d
```

(this is somehow implicit - the semicolon will be inserted, but because it is in
a comment, it will not be a problem).


## Short term TODO

  * Refactor `convert` API to allow unittests of it.
  * Once refactored, make `convert` functionality available as a CTFE-able
    function. Together with `q{}` strings and `import()` expressions,
    this could be really cool.
  * Add directives and flags and environment variables to enforce indent
    style (i.e. tabs, spaces, amount, etc)
  * Make `dmt` self hosting (`dmt.d` converted to `dmt.dt`, and provide
    a bootstrap binary, or a simplified / older implementation of `dmt.d`,
    to do a bootstrap process)
  * Parse comments better and handle them properly.
  * Improve support for function / method contracts (`in`, `out`, `do`, `body`),
    with line-continuations it now works, but would be nice to make it even better
  * Syntax highlighting and auto-indent hints for mcedit, vim, emacs and vs code
  * Convert to a `dub` package?
  * Enforce same alignment of `case` and `default` in `switch`. This is should be
    possible to disable tho, because of ability to add switch `case` cases using
    `static foreach` for example
  * Enforce `catch` and `finally` to have same indent as `try`, similar how
    `else` needs to have same indent as `if`.
  * Once `gdc` compiler catches up and supports `do` (instead of `body`).
    DMD 2.097.0 will start producing deprecation notices about usage of `body`.
    Once this is in gdc, we can also start using `body` as identifier, instead of
    `bdy` (i.e. in `decompose` and `convert`).
  * Similarly once `gdc` compiler supports "new" short style versions of
    function contracts (`in (AssertExpression)`,
    `out ([ref] ident; AssertExpression)`), convert to using them.

## Speed

There was no profiling or deeper optimizations done yet with `dmt`, but on my
machine in release mode, it processes 1.14 million lines per second, and
processes 37MB/s (this is quite dependent on the average line length in the
source file) from the input. Pretty good. This certainly can be improved, but is
plenty fast, and for big projects with many files, the conversion process can be
fully parallelized in the build system. A moderatly complex module with 1000
lines converts in just 5ms.

## Limitations and notices

Note that some features familiar from Python, are not implemented and not
supported. They might be supported in the future, but that will require a more
complex parser. Some examples are listed below.


### Multi-line alignment limitations

```d
def auto f(a, b,
           c, d):
  // ...
```

will not work.

This is unlikely to be implemented. It is quite limiting and can be annoying, but
at the same time, some might argue it is a good thing. Just keep your lines
reasonably short, or assign sub-expression to own variables.

This could be easily resolved for the majority of cases, but probably will not be
implemented.

For statements and expressions, as a work around, simply put everything on a
single line, or use line continuations:


```d
auto x = f(a, b, \
           c, d)
```

For function, method, class, templates, and other definitions / declarations,
maybe try this:

```d
auto f(a, b, \
       c, d) \
def:
   // ...
```

or for functions and methods specifically:

```d
auto f(a, b, \
       c, d) \
do:
   // ...
```

(`do` is equivalent to `body`).

Other example:

```d
class A : B, \
          C!int, \
          D!int \
def:
   def int f():
     return 1
```

### Empty aggregate definitions

A trick might be to use a dummy `private:` or a comment.

```d
def class A:
  private:
```

```d
def interface I:
  // nothing
```


using `{}`, will not work, because directly inside aggregate declarations are
expected, not BlockStatement.


### Mixed colon and single line statements

Note, that this will definitely not work or be implemented:

```d
  if (a): f(a)
```

```d
  if (a): f(a); f(b)
```

```d
  while (a--): writefln(a); f(a)
```

because, it is really tricky to parse without a full D language parser.

### Multi-line comments

Multi-line comments using block comments are limited. Each line must not start
with space, and must be all aligned to same as first line:

```d
/** Foo
 * bar
 */
```

is not allowed, because a second line is indented more than the first one.

```d
/** Foo
** bar
**/
```

could work. Other option is to do this:

```d
/*
Foo
bar
*/
```

Note, however, that `dmt` adds a semicolon (`;`) at the end of each line, so this
is equivalent to:

```d
/*;
Foo;
bar;
*/;
```

Note the semicolon at the very end of the last line. This could be important if
you put a comment after for example `if` statement, without curly braces:

```d
  if (a)
  /*
  Foo
  bar
  */
  g()
```

In this case the body of `if` will be EMPTY. And `g` will be called
unconditionally.

Do not do silly things. And just use `//`-style comments if possible.

Also mentioned before, you might opt out of some indenting features, but that
makes it awkward and not nice at all:

```d
  if (a) {
  f(a)
  } else {
  g(a)
  }
```

Do not do that. Hopefully in the future, `dmt` will actually reject such
constructs.


### Multi-line string literals

Multi-line string literals / raw literals, and quoted tokens, will often not work
properly:

```d
  int a = "foo
bar
baz"
```

will make the `dmt` confused, and generate an error.

Only option is to use string concatenation operator (`~`) together with explicit
line continuation (to prevent emitting a semicolon by `dmt`):

```d
  int a = "foo\n" \
  ~ "bar\n" \
  ~ "baz"
```

That however, requires implementing multi-line continuation first in `dmt`.


### Multi-line formatted arrays / lists

Multi-line formatted arrays / lists, like this:

```d
  auto a = [
     "foo": 1,
     "bar": 3,
  ]
```

will not work. Sorry.

One of the easier option is to introduce explicit keyword, and maybe do this:


```d
  def_array auto a = [
  ]
```

### Comments after colon

Comments are not supported after a colon (`:`)

```d
  foreach (a; l):  // iterate list
    f(a)
```

will not work.


### Functions and delegate literals

```d
  int a = 5
  auto l = delegate int(int b):
    return a + b
```

will not work.

```d
  int a = 5
  auto l = delegate int(int b) {\
  return a + b
  }
```

is an option probably, so is:

```d
  int a = 5
  auto l = delegate int(int b) \
  def:
    return a + b
  ;
```

(Note explicit semicolon `;` after finishing the `def:` block, to finish the
assignment statement.)


Other option is to abandon anonymous delegates, and define named inner function:

```d
  int a = 5;
  def int f(int b):
    return a + b
  auto l = &f
```

### Some annotations on declarations are not easily possible

```d
extern (C++) interface IFoo:
  ...

private class X:
  ...
```

To work around this, simply add a `def` at the start:

```d
def extern (C++) interface IFoo:
  ...

def private class X:
  ...
```

### Inline assembler

`asm` can be used, but all instructions and labels must be at the same level of indentation:

```d
asm:
    call L1
    L1:
    pop  EBX
    mov  pc[EBP],EBX ; // pc now points to code at L1
```

### A scope block

There is no easy way to introduce a new local scope. Just use `if (true)` for the
moment:

```d
if (true):
  auto x = 6
  writefln(x)
// writefln(x)  // x not in local scope.
```

or better `def` with nothing after:

```d
def:
  auto x = 6
  writefln(x)
// writefln(x)  // x not in local scope.
```

It is a bit awkward, but works.


### Enums

Named and anonymous `enum` definitions are not currently supported:

```d
enum X:
  A,
  B,
  C
```

The reason is because they require commas at the end of each line, but `dmt`
inserts semicolons at the end of each such line. Possible solutions would be make
special case for `enum` indents, but that requires more than a simple one-level
hack, because of things like this:

```d
enum X:
  A = 1
  version(a):
    B = 5
  else:
    B = 9
```

One of the options would be to explicitly prefix enumerations with some keyword:

```d
enum X:
  enumvalue A = 1
  version(a):
    enumvalue B = 5
  else:
    enumvalue B = 9
```

This should also be possible then (because trailing commas are ok):

```d
enum X:
  enumvalue A, B, C
  enumvalue D, E, F
```

As a workaround use line continuations:

```d
enum X:
  A, \
  B, \
  C \
```

The line continuation marker is required after the last element of the enum too,
even if it is end of the file. It is safe to de-indent on a next line:

```d
enum X:
  A, \
  B, \
  C \
enum Y:
  F, \
```


### Unittests

To add attributes to unittests, use `def`:

```d
def @safe nothrow unittest:
  {}
```

```d
/// Bzium
def private unittest:
  {}
```

### parentheses in `if`, `while`, `for`, ...

At the moment, it is required to put parentheses around the conditions, just like
in D:

```d
  if (a > 5 && b > 3):
    f()
```

but it should not be hard to allow also these forms:

```d
  if a > 5 && b > 3:
    f()
```

At the moment it is not supported. This requires a bit of evaluation, to not hide
possible coding errors, like `if (a = 5):`, which are currently detected by D
compilers.


### `@disable`d functions / methods

Simply do not use `def` for declaration of `@disable`d functions

```d
class C:
  @disable int foo();
```

because `def` requires colon and opens a new scope:

```d
class C:
  def @disable int foo():
    return int.init;
```

and that will most likely upset the compiler. Making the return type a `void`
could help.


### Function contracts

Unfortunately, `dmt` at the moments does not support contracts.

```d
def int f(int b):
  in:
    assert(b < 10)
  out (ret):
    assert(ret < 1000)
  do:
    return b * b * b
```

```d
def int f(int b):
  in (b < 10)
  out (ret; ret < 1000)
  body:
    return b * b * b
```

unfortuantely will not compile. A workaround is to use line-continuations in a
bit hacky, but a reasonable way:

```d
int f(int b) \
in:
  assert(b < 10)
out (ret):
  assert(ret < 1000)
do:
  return b * b * b
```

```d
def int f(int b) \
in (b < 10) \
out (ret; ret < 1000) \
body:
  return b * b * b
```

### Pipeline / UCFS heavy range processing is tricky:


A D code like this:

```d
import std.stdio, std.array, std.algorithm;

void main() {
    stdin
        .byLineCopy
        .array
        .sort!((a, b) => a > b) // descending order
        .each!writeln;
}
```

is somehow tricky to convert to `dmt` format, without introducing ugly code:

```d
import std.stdio, std.array, std.algorithm

def void main():
    stdin \
        .byLineCopy \
        .array \
        .sort!((a, b) => a > b) \
        .each!writeln
```
