
# Python-like indentation in D programming language

This is a simple yet, powerful code translator allowing to use Python-like syntax
to write D programs.

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
    writefln("Contructor")
  def ~this():
    writefln("Decontructor")
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

See `test*.dt` files for more examples.

Enjoy.

## Usage

By default `dmt` tool will convert a source code, and pass it to the `dmd`
compiler. The compiler can be changes by `DMD` environment variable, for example:
`DMD=ldc2 dmt test4.dt`

## Indentation

Indentations only follows after a line starts with a specific keyword, and is finished with colon.

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

If you want to declare a function (i.e. C function) or define an interface method, you can do that on single line without using `def`, just be sure not to finish it with the colon. Smicolon is optional and should avoided, as `dmt` will add one for you


```d
extern(C) int g(int a, char* c)

interface IFoo:
  int f()
```

List of keywords introducing indents (if line finishes with colon):

- `def`
- `if`, `else`
- `for`, `foreach`, `foreach_reverse`, `while`, `do`
- `class`, `struct`, `union`
- `enum`
- `template`
- `mixin` template definition
- `in`, `out`, `body` sections of a function, method or interface contract
- `invariant`
- `try`, `catch`, `finaly`
- `switch`
  - `case` and `default` can be indented or not, your choice
- `version`
- `unittest`


Arrays and assosciative arrays, unfortunately can't be formated with alignment / indents at the moment:

```d
int[] a = [
  1,
  2,
  3,
]
```

Will not work. Sorry.

## Indentation semantics

You can use space or tabs, or mix of them. But consistency is required for
matching indent levels.

If you open a new indent level, the next line, must have same indent as previous
line + new indent.

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

Also, the `if`/`else`, `in`/`out`/`body`, `case`/`default`, `try`/`catch`/`final` must match
properly:

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

This is ok, but is not recommneded:

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

You should avoid putting semicolon after the last statement, as this will most likely
trigger the D compiler warning.

Empty blocks. You can put an empty block, by not indenting, or by putting
manually `{}` as an empty statetement:

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

Note, that you can not do more than one statement, unless you actually put it in brackets

```d
  if (a) f(a); g(a)    // WRONG / MISLEADING
```

Because, this will call `g` even if `f` is not called. This is because this is
code is literally translated to D just like on the input (plus semicolon at the
end).

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

## Short term TODO

  * Line-end continuation
  * Flags to pass extra parameters to the `DMD`  (for example `-c`, `-O`)
  * `--keep[-tempfile]` to not remove temporary files
  * `--remove_d_file` to remove corresponding temporary `.d` file.
  * `--pipe` to display converted code on stdout
  * `--convert_only` to convert, but not call `DMD`
  * Convert all requested files before passing to `DMD`. So multi-file projects
    are easier to build.
  * Pass through non-`.dt` files to `DMD`, so it is easier to mix and match
    `dmt`, D, C, .o, assembler, etc.
  * Better error diagnostic from `dmt` itself
  * Use `#line` directives to preserve file / line numbers for diagnostic in D
    compiler.
  * `#!` ("sh-bang") support
  * More automated tests
  * Syntax highlighting and auto-indent hints for mcedit, vim, emacs and vs code
  * Conver to `dub` package?
  * Parse comments and handle them properly.
  * Add directives and flags and environment variables to enforce indent
    style (i.e. tabs, spaces, amount, etc)

## Limitations

Note that some features familiar from Python, are not implemented and not
supported. They might be supported in the future, but that will require way more
complex parser. Some examples are listed below.

### Line-end continuation:

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

will not work.

The line-end continuation will probably be supported in the future versions.

### Multi-line alignment:


```d
def auto f(a, b,
           c, d):
```

```d
writeln(a, b,
        c + 5)
```

```d
int z = (a + b +
         c + d)
```

This is unlikely to be implemented. It is quite limiting and can be annoying, but
at the same time, some might argue it is a good thing. Just keep your lines
reasonably short, or assign sub-expression to own variables.


This could be easily resolved for majority of cases, but probably will not be
implemented.

### Mixed colon and single line statements

Note, that this will definitively not work or be implemented:

```d
  if (a): f(a)
```

```d
  if (a): f(a); f(b)
```

```d
  while (a--): writefln(a); f(a)
```

because, it is really tricky to parse without full D language parser.

### Multi-line comments

Multi-line comments using block comments, are limited. Each line must not start
with space, and must be all aligned to same as first line:

```d
/** Foo
 * bar
 */
```

is not allowed, because second line is indented more than the first one.

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

Note the semicolon at the ver end of last line. This could be important if you
put a comment after for example `if` statement, without curly braces:

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

Don't do silly things. And just use `//`-style comments if possible.

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

Only option is to use string concatenation operator (`~`) together with explicit line continuation (to prevent emitting a semicolon by `dmt`):

```d
  int a = "foo\n" \
  ~ "bar\n" \
  ~ "baz"
```

That however, requires implementing multi-line continuation first in `dmt`.


### Multi-line formated arrays / lists

Multi-line formated arrays / lists, like this:

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
