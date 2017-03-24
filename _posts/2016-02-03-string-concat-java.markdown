---
layout: post
title: "String Builders and Smart Compilers"
description: ""
category: articles
tags: []
---

TLDR: We've all been trained to stay away from string concatenation.
The Java compiler stays away from it, too, even when the source code
doesn't. /TLDR

## Concatenation, Oh No

A friend of mine discovered "something" in a Java file recently; it
looked about like this:

```java
String s1;
// etc. about 20

String combined = s1 + s2 + ... + s20;
```

For a long time, this has been seen as a bad practice, because of the nature
of strings in the Java programming language. In Java, every string
is immutable; if it needs to change, a new string object is created,
and the contents are copied over.

For the most part, this is done to allow Java to avoid a large class
of buffer overflows that occur from reading off the end of a string.
It's the same reason that the size of an array is established at
the time of its instantiation.

So we look at this code and imagine that for each plus sign, a new
string object is created, which of course would be wildly inefficient.
Of course, most Java developers also know that the Java compiler is
smarter than that. Instead of creating a string object for each
concatenation, or a single new string object for all the concatenations,
it uses the `StringBuilder` class that is built into the Java standard
library.

So we concluded this code probably winds up pretty efficient at runtime,
even though it looks terrible. But that led us to wonder how smart the
compiler really is. Should we just stop worrying about using `StringBuilder`
ourselves and just let the compiler do it?

It turns out that the answer is no; it's probably best to stick with the 
habit of using `StringBuilder` instead of concatenation. At worst, the
compiled bytecode is the same. At best, it saves some object instantiation.
Here's some examples to illustrate, using Java 8.

## Simple Concatenation

The easiest thing in this case is to stay away from development environments
and stick to command-line tools. We'll start with a simple Java class and
compile it using "javac".

```java
public class StringConcatSingle {

        public static void main(String[] args) {
                String s1 = "abc";
                String s2 = "def";
                
                System.out.println(s1 + s2);
        }
}
```

Then compile and run through the `javap` tool, which is built into Java and is 
great for looking at byte code:

```
$ javac *.java
$ javap -c StringConcatSingle.class
```

As expected, the compiler created a `StringBuilder` and used its `append()` method.
Since this example is the shortest, I'll show the full bytecode for `main()`:

```
  public static void main(java.lang.String[]);
    Code:
       0: ldc           #2                  // String abc
       2: astore_1
       3: ldc           #3                  // String def
       5: astore_2
       6: getstatic     #4                  // Field java/lang/System.out:Ljava/io/PrintStream;
       9: new           #5                  // class java/lang/StringBuilder
      12: dup
      13: invokespecial #6                  // Method java/lang/StringBuilder."<init>":()V
      16: aload_1
      17: invokevirtual #7                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      20: aload_2
      21: invokevirtual #7                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      24: invokevirtual #8                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
      27: invokevirtual #9                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
      30: return
```

So the concatenation is replaced with two calls to `StringBuilder.append()`.

To give a bit more detail for those who might not have looked at bytecode
before:

* Lines 0-3: Load the "abc" and "def" strings from the constant pool and
  store them into local registers.
* Line 6: Get a reference to the static field System.out and put it on
  the stack.
* Line 9: Instantiate a StringBuilder object.
* Line 12: Duplicate it on the stack. This is a neat trick that 
  avoids having to store it to a register. Normally, the call to
  its constructor would pop it off the stack, but this way there's
  a reference to it still ready to use.
* Line 13: Call its default no-arg constructor.
* Lines 16-21: Load the first string, append it, then load the second
  string, then append it. Note that "invokevirtual" is the Java bytecode
  to call a method, and that both the target object and its parameters
  are popped off the stack for use. The return value, if any, is then
  pushed onto the stack. It so happens that `StringBuilder.append()`
  returns "this" to support method chaining, so it winds up back on
  the stack again in the right spot for the next call. Another clever
  trick.
* Line 24: Call toString() on the StringBuilder, again taking advantage
  of the fact that `StringBuilder.append()` returns "this".
* Line 27: Invoke `println()` on the reference to `System.out` that was
  pushed onto the stack way back in line 6. Yet another bit of cleverness;
  because it was pushed onto the stack way back there, it is in the
  right place for this method call, "behind" the string parameter. If you own
  a calculator with [Reverse Polish Notation][rpn] this will all make perfect
  sense.

All in all, I hope you walk away with an appreciation for how much thought
goes into compiling even a simple method.

## Simple StringBuilder

It's interesting to see how this compares to code that uses a StringBuilder
directly:

```java
public class StringBuilderSingle {

    public static void main(String[] args) {
        String s1 = "abc";
        String s2 = "def";
                
        StringBuilder sb = new StringBuilder();
        sb.append(s1);
        sb.append(s2);

        System.out.println(sb.toString());
    }
}
```

```
  public static void main(java.lang.String[]);
    Code:
       0: ldc           #2                  // String abc
       2: astore_1
       3: ldc           #3                  // String def
       5: astore_2
       6: new           #4                  // class java/lang/StringBuilder
       9: dup
      10: invokespecial #5                  // Method java/lang/StringBuilder."<init>":()V
      13: astore_3
      14: aload_3
      15: aload_1
      16: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      19: pop
      20: aload_3
      21: aload_2
      22: invokevirtual #6                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      25: pop
      26: getstatic     #7                  // Field java/lang/System.out:Ljava/io/PrintStream;
      29: aload_3
      30: invokevirtual #8                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
      33: invokevirtual #9                  // Method java/io/PrintStream.println:(Ljava/lang/String;)V
      36: return
```

It's pretty much identical; the only difference is that the `StringBuilder` instance
gets stored away and reloaded on each use, because the compiler is operating on
successive statements independently rather than writing optimized bytecode for a
single statement. We could use our insights about method chaining above to improve
this code further, and make it almost identical to the concatenation version.

## Multiple Statements

Let's make things a little more complicated for the compiler:

```java
public class StringConcatDouble {

    public static void main(String[] args) {
        String s1 = "abc";
        String s2 = "def";
        String s3 = "ghi";
        String s4 = "jkl";
                
        String output = s1 + s2;
        output = output + s3 + s4;
        System.out.println(output);
    }
}
```

In this case, we have two statements, but they are both assembling the
same string. And here, probably out of a need to only make safe
optimizations, the compiler treats each statement separately, so we
end up with two `StringBuilder` instances:

```
      13: new           #6                  // class java/lang/StringBuilder
      16: dup
      17: invokespecial #7                  // Method java/lang/StringBuilder."<init>":()V
      20: aload_1
      21: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      24: aload_2
      25: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      28: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
      31: astore        5
      33: new           #6                  // class java/lang/StringBuilder
      36: dup
      37: invokespecial #7                  // Method java/lang/StringBuilder."<init>":()V
      40: aload         5
      42: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      45: aload_3
      46: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      49: aload         4
      51: invokevirtual #8                  // Method java/lang/StringBuilder.append:(Ljava/lang/String;)Ljava/lang/StringBuilder;
      54: invokevirtual #9                  // Method java/lang/StringBuilder.toString:()Ljava/lang/String;
```

The "output" variable gets the contents of the first `StringBuilder`, then that
string is loaded back into the next variable (lines 28-42). However, note that
the second concatenation statement, with its three strings, only uses one
`StringBuilder` (lines 42-51).

To push it one more step, I tried looping over an array of strings,
concatenating each one, to see if there was an optimization for loops, but the
compiler generated a new `StringBuilder` for each iteration of the loop.

So we can conclude that the code at the top of this article would actually
compile to something pretty well optimized. But for anything more complicated,
the resulting bytecode is not as good as we could get if we do things correctly
ourselves. 

In my view, it means that the advice to avoid concatenation is still
good advice, because it's a decent habit. But it means I have a justification
for my habit of using concatenation in debug logging and similar places
where it makes the code more compact and readable.

## Postscript: Decompiling 

One more interesting note I came across while looking at this. There's a great
library, [Java Decompiler][jd], that turns Java class files back into source code,
even if the source is not available. If the Java code is compiled with debugging
symbols, it can pretty much re-create the original source file. But even if
the debug symbols are not available, it gets pretty close. Here's the first
example, compiled with "-g:none" for no debug symbols, then decompiled:

<img class="ctr" src="/post-images/java-decompile.png" style="max-width:100%;max-height:250px;" />

Variable names and line numbers were lost, but otherwise it did amazingly well.
Note that it turns the calls to `StringBuilder` back into a string concatenation.
Based on the difference we saw above in the bytecode, it is able to infer that the
optmization was performed and undo it. Similarly, it can recognize that the reference
to `System.out` is not stored in a local variable, and so it can reassemble the call
to `System.out.println()` even though it is in two places in the bytecode.

For more fun, I invite you to write a version of the above StringBuilderSingle
class that uses method chaining and an anonymous `StringBuilder`, something like:

```java
new StringBuilder().append(s1).append(s2).toString()
```

The decompiler will turn it back into concatenation in the decompiled source code.

[rpn]:http://www.calculator.org/rpn.aspx
[jd]:http://jd.benow.ca/

