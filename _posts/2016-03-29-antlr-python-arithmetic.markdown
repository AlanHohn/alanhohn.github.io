---
layout: post
title: "ANTLR 4 with Python 2 Detailed Example"
description: ""
category: articles
tags: []
---

Zone: Integration

TLDR: ANTLR 4 introduced a handy listener-based API, but
sometimes it's better not to use it.

In a [previous post][prev] I showed a very simple example using
[ANTLR 4][antlr] with Python 2. While this example gave the basic
framework necessary, it didn't delve very deeply into ANTLR's API.
In this article, I'll give a little more detail.

[prev]:https://dzone.com/articles/using-antlr-4-with-python-2
[antlr]:http://www.antlr.org/

### Grammar

To get started, we need a grammar that is more complex than
the basic "Hello" grammar. There are a large number of [examples][]
for ANTLR 4 grammars on GitHub. I started with an [arithmetic grammar][ag]
and simplified it (removing exponentiation and scientific notation).

[examples]:https://github.com/antlr/grammars-v4
[ag]:https://github.com/antlr/grammars-v4/blob/master/arithmetic/arithmetic.g4

The most interesting part of the grammar is this:

```antlr
expression
   : multiplyingExpression ((PLUS | MINUS) multiplyingExpression)*
   ;

multiplyingExpression
   : number ((TIMES | DIV) number)*
   ;

number
   : MINUS? DIGIT + 
   ;
```

Our top-level construct is an expression. It consists of multiplying
expressions separated by either a plus or a minus. Similarly, a
multiplying expression consists of numbers separated by a times
or division sign.

There are a couple smart points in the way this grammar is assembled.
First, note that a number by itself is a valid multiplying expression,
and therefore a single number is a valid expression. Second, by
breaking the plus/minus and times/div into separate tokens, it makes
it much easier to handle order of operations (since they will be in
different levels of the tree).

### Code Generation

As before, we run ANTLR on the grammar to generate code. In the
previous example I showed using the downloaded JAR directly. If
using a package manager where `antlr4` ends up on the path, the command
is:

```shell
$ antlr4 -Dlanguage=Python2 arithmetic.g4
```

This generates a lexer, parser, and a base class for a listener.

### Tree Walking

I'll give the main body of the code first. It starts in a similar way to the
previous example:

```python
def main():
    lexer = arithmeticLexer(antlr4.StdinStream())
    stream = antlr4.CommonTokenStream(lexer)
    parser = arithmeticParser(stream)
    tree = parser.expression()
    handleExpression(tree)
if __name__ == '__main__':
    main()
```

We start by reading from standard in and passing that through the
lexer, then the parser. This builds a tree of the parsed input. 

At this point, we head in a different direction from the previous example.
Rather than creating a walker to walk the tree, providing a listener class, we
instead just pass the tree to a method. 

### Listener Class Challenges

The purpose of a listener class is to turn the tree into a series
of stream-like events to make processing easier. However, in this case
we run into a problem. We have listener methods available for expressions,
multiplying expressions, and numbers, because these are defined in terms
of other tokens. But we don't have a method available for "terminal"
nodes such as our operators ("+", "-", "*", "/"). We only find out
about these by inspecting the context of parent objects (expression and
multiplying expression).

Also, because we are using infix notation, at the time we see the operator,
we don't have all of the information that we're going to need to use that
operator. In fact, because expressions can be arbitrarily long, we couldn't
look ahead to get the information we need, even if there was a convenient
way to do that with ANTLR.

Fortunately, the ANTLR API provides us with the means to iterate over the
children of a node. So we don't have to wait for 
stream events to fire; instead, we can walk through the children in order.

Here's the resulting implementation. I'm not yet convinced that this is
the best solution, but it does work and it is reasonably compact.

First, we need an entry method that handles the top-level expression:

```python
def handleExpression(expr):
    adding = True
    value = 0
    for child in expr.getChildren():
        if isinstance(child, antlr4.tree.Tree.TerminalNode):
            adding = child.getText() == "+"
        else:
            multValue = handleMultiply(child)
            if adding:
                value += multValue
            else:
                value -= multValue

    print "Parsed expression %s has value %s" % (expr.getText(), value)
```

We iterate over the children; where we find a multiplying expression,
we evaluate it. Where we find an operator, we use it to set a flag
indicating the next operation to perform.

Multiplying expressions are handled in a similar way:

```python
def handleMultiply(expr):
    multiplying = True
    value = 1
    for child in expr.getChildren():
        if isinstance(child, antlr4.tree.Tree.TerminalNode):
            multiplying = child.getText() == "*"
        else:
            if multiplying:
                value *= int(child.getText())
            else:
                value /= int(child.getText())

    return value
```

Note that we set the initial value to 1, so if we see an expression
with a single number we will handle it correctly. Also, to handle
numbers we just get the text form, which contains all the digits,
and turn it into an integer. (The ANTLR tree contains each digit
individually but this is easier.)

Of course it feels a little clunky to use `isinstance` in this implementation,
and a little clunky to store state related to the "last seen" operator, but the
alternatives seemed even clunkier. For example, the expression contains a
`PLUS()` method, but this method is just a list of all of the "+" symbols in
the expression.

One nice thing about this implementation is that it's safer than it might
initially look. ANTLR catches errors in parsing the input string, so any
characters that don't fit our grammar result in an error before our parsing
code is invoked. (The example code doesn't yet handle those errors, but at
least they are caught.) This means that it's safe to assume that any
number we find can be converted to an integer, and that if there is an
operator in a multiplying expression, it's either "*" or "/" because those
are the only ones that are valid.

### Results

With this implementation in place, we have a somewhat functional calculator
similar to the UNIX command `bc`:

```shell
$ echo "3 * 3 - 2 + 2 * 2" | python arithmetic.py 
Parsed expression 3*3-2+2*2 has value 11
```

### Conclusion

Even though we're still in the realm of a simple example with ANTLR, we've
already gotten into some deeper waters with how we had to handle the
parsed input. If we were to add back in some of the extra operators,
notations, and parenthetical expressions, we might have to consider 
refactoring to avoid additional duplication of code.

