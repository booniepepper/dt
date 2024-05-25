[![License](https://img.shields.io/github/license/so-dang-cool/dt)](https://github.com/so-dang-cool/dt/blob/core/LICENSE.md)
[![unconventions.org](https://img.shields.io/badge/unconventions-%E7%84%A1%E9%99%90-orange)](https://unconventions.org)
[![justforfunnoreally.dev badge](https://img.shields.io/badge/justforfunnoreally-dev-9ff)](https://justforfunnoreally.dev)

# dt

<img alt='dt' align='right' src='https://raw.githubusercontent.com/so-dang-cool/dt/core/img/dt-logo-white.svg' height='128' width='128'>

It's duct tape for your unix pipes. A programming language for doing small
stuff fast, easy, and readable.

In the words of [Red Green](https://www.redgreen.com):

> Remember, it's only temporary... unless it works!

Note: [The dt User Guide](https://dt.plumbing/user-guide/) exists but is still
in progress. Basic usage is shown in the instructions below.


## Use in pipes

When piping in/out, the REPL is skipped. If something is piping into `dt` then
standard input is fed into `dt` as a list of lines.

```
$ seq 3 | dt rev pls
3
2
1
```

Great for aliases:

```
$ alias scream-lines="dt [upcase words unlines] map pls"
$ echo "hey you pikachu" | scream-lines
HEY
YOU
PIKACHU
```

If you want to read lines manually, use `stream` as the first command:

```
$ alias head.dt="dt stream [rl pl] args last to-int times"
$ seq 100 | head.dt 3
1
2
3
```

## Use as a shebang

When the first argument to `dt` is a file starting with `#!` it will interpret
the file. In short: `dt` supports shebang scripting.

A naive tee implementation:

`tee.dt`

```
#!/usr/bin/env dt

readln unlines   \stdin :
args pop   \file :

stdin pl
stdin file writef
```

Then use like:

```
cat wish-list | sed 's/red/green/g' | tee.dt new-wish-list
```

## Interactive mode

Running `dt` by itself with no pipes in or out starts a read-eval-print loop
(REPL).

```
$ dt
dt 1.x.x
Now, this is only temporary... unless it works.
» # Comments start with #
»
» 1 1 + println
2
»
» # Printing is common, so there are a bunch of printing shorthands.
» # "p" is print, "pl" is print line, "pls" is print lines (i.e. of a list of values)
» # Let's define a command that consumes a value, prints it, then returns its double.
»
» [ \n :   n p " " p   n 2 *] \print-and-double def
»
»
» # And let's do it... 7 times!
»
» 1 \print-and-double 7 times   drop
1 2 4 8 16 32 64
»
»
» # You can conditionally execute code
»
» ["hi" pl] false do?
» ["bye" pl] true do?
bye
»
» quit
```

For a best experience, also install
[`rlwrap`](https://github.com/hanslub42/rlwrap) and set a shell alias like so:

```
$ alias dtsh='rlwrap dt'
$ dtsh
dt 1.x.x
Now, this is only temporary... unless it works.
»
```

The above example assumes a bash-like shell. Details on the syntax and
configuration files to set an alias that persists will vary by your shell.


## Installing

[![Packaging status](https://repology.org/badge/vertical-allrepos/dt-script.svg)](https://repology.org/project/dt-script/versions)

[![FlakeHub](https://img.shields.io/endpoint?url=https://flakehub.com/f/so-dang-cool/dt/badge)](https://flakehub.com/flake/so-dang-cool/dt)

More ways to install: https://dt.plumbing/user-guide/install.html


## Community and resources

Discuss dt on Discord. As interest grows and the language matures we will probably prefer
discussion to be on platforms that can be indexed for searches. Let us know of other communities!

* Scripters, packagers, and terminal fans:  [![discord badge](https://img.shields.io/discord/1141777454164365382?logo=discord)](https://discord.gg/9ByutGCrJX)
* Concatenative language theorists: [![discord badge](https://img.shields.io/discord/1150472957093744721?logo=discord)](https://discord.gg/pwrVPJJMfZ)

Other resources:

* [dt User Guide](https://dt.plumbing/user-guide/) ([sources](https://github.com/so-dang-cool/dt/tree/gh-pages))
* [dt on Rosetta Code](https://www.rosettacode.org/wiki/Category:Dt)
* [dt on the concatenative wiki](https://concatenative.org/wiki/view/dt)

## The nerdy stuff

The dt language is a functional programming language, and a
[concatenative language](https://concatenative.org/wiki/view/Concatenative%20language),
with a very imperative feel. For those interested, the user guide has a more
in-depth discussion of [the language classification](https://dt.plumbing/user-guide/misc/classification.html).

`dt` is implemented in Zig with no plans to self-host or rewrite in Rust or Go.
Please do suggest better strategies for memory management and optimizations! I
have some experience working at this level, but still much to learn. The
current implementation is still fairly naive.

## Credits

Shared as open source software, distributed under the terms of [the 3-Clause BSD License](https://opensource.org/license/BSD-3-clause/).

By J.R. Hill | https://so.dang.cool | https://github.com/booniepepper

