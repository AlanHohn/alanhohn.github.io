---
layout: post
title: "Fully Dynamic Classes with ASM"
description: ""
category: articles
tags: []
---

Zone: Java

TLDR: ASM is a Java bytecode manipulation library. Mocking frameworks
and runtime code generators use it to dynamically generate Java classes.
Here is an introduction to how it works.

In two previous articles, I discussed Java's [built in dynamic proxy
support][art1] and [using CGLib to proxy concrete classes][art2]. In
both cases, we provided some regular Java code, then dynamically
generated classes that would wire up that Java code to any arbitrary
interface or class.

[art1]:https://dzone.com/articles/java-dynamic-proxies
[art2]:https://dzone.com/articles/dynamic-class-enhancement-with-cglib

But how does that wiring get created? There is no magic; it must itself
be Java code that the Java Virtual Machine can run. But while most of it
can exist as part of generic libraries, there must be at least a few parts
that are created at runtime, completely dynamically. Similarly, if we use
a mocking framework, most of the behavior of the framework can be written
as regular Java (tracking method calls, throwing exceptions, returning values)
but the actual class file that pretends to be an instance of a class or
interface must be purely generated at runtime.

To do this, we need a library like [ASM][asm]. With ASM, we write Java code
to generate a class file at runtime, but because we can parameterize the Java
code we write, the class file we generate can have any behavior whatsoever,
and any characteristics whatsoever, including what fields and methods it has,
the name of the class, its superclass, and any interfaces.

[asm]:http://asm.ow2.org/

Of course, we could bypass ASM and go directly to writing bytecode ourselves;
after all, a class file is just a binary file that happens to contain instructions
for the Java virtual machine. But in that case we would have to do a lot of work
ourselves to calculate offsets for jump statements and other assembly-level
things. Having ASM do it for us is simpler, though you may not think so once
you've seen how much there is to this "simple" example.

In this article, I'll present a basic example of using ASM to generate a Java
class file, load that class file, and run it. While I will be passing in
constants for things like the name and package of the class and its methods,
of course a real use of ASM would allow these things to be fed in as parameters.

ASM uses a "visitor" pattern for all of its methods. In practice, this mostly
means that all of the methods start with "visit...". But it also means that we
can think of our creation of the class file hierarchically: we will start at
the class as a whole, then proceed to the various pieces of the class, including
its constructors and its methods.

Before I get into the ASM example, we need to think about what we're going to
do with this class when we have it. ASM is going to give us a regular Java byte
array where the contents are the class file data itself. We could write that to
a class file on disk and pretend to be a compiler, but ideally we would like to
immediately load this class and run it. To do that, we need to load it with a
class loader; then we can instantiate it using reflection.

It turns out that `ClassLoader` in Java does have a method we need to define
a class using a byte array, but it's protected. So we make our own dynamic
class loader to expose that method:

```java
public class DynamicClassLoader extends ClassLoader {
    public Class<?> defineClass(String name, byte[] b) {
        return defineClass(name, b, 0, b.length);
    }
}
```

Also, once we have the class, we would like to be able to use it from regular
Java code (i.e. not using reflection). So we'll have the class implement an
interface. Note that, in our Java source code, there won't be any classes that
implement this interface, but we can write to it and call its methods.

```java
package dynamic;
public interface Calculator {
        int add(int left, int right);
}
```

Now that we have a way to load and use the class once we make it, we can start
with ASM. For this discussion, I am using ASM 5.0.3, which is the version that
ships with CGLib 3.2.0. Note that there are some backward-incompatible changes
in both ASM and CGLib, which can make it a challenge when using libraries that
use these two. For this reason, you will often see libraries rewrite package
names and embed a private ASM.

One other quick note: in this class, I "import static" all of the variables
in the "Opcodes" class in ASM. These opcodes are used extensively and it
makes reading easier to refer to them directly. So anywhere you see a
constant name, that's where it comes from.

For this explanation, there's no substitute for showing the purpose of each
parameter to each method, so that's what I've done.  We start by getting
ourselves a `ClassWriter` instance and "visiting" the class itself:

```java
ClassWriter cw = new ClassWriter(ClassWriter.COMPUTE_FRAMES);
        
cw.visit(V1_7,                              // Java 1.7 
        ACC_PUBLIC,                         // public class
        "dynamic/DynamicCalculatorImpl",    // package and name
        null,                               // signature (null means not generic)
        "java/lang/Object",                 // superclass
        new String[]{ "dynamic/Calculator" }); // interfaces
```

Now we have a way to walk through the class, just as if we were writing
source code. However, we have to be more explicit because there is no compiler
to do things for us. This means we have to explicitly define a constructor, even
a no-arg constructor, to make sure our class has one:

```java
/* Build constructor */
MethodVisitor con = cw.visitMethod(
        ACC_PUBLIC,                         // public method
        "<init>",                           // method name 
        "()V",                              // descriptor
        null,                               // signature (null means not generic)
        null);                              // exceptions (array of strings)
```

The "name" in this case is a special name for constructors.  The "descriptor"
is also worth a look. This specifies the parameters accepted and the return
type of the method. Nothing between the parentheses means this method takes no
parameters. Capital "V" means the void type, so this method has no return value.

We've now defined a constructor, but we don't have any behavior yet. If the compiler
was generating code for us, and we didn't include an explicit call to a constructor
in the superclass, the compiler would put one in. Here, we need to do that ourselves.
Fortunately, for this simple example, that's all we need our constructor to do:

```java
con.visitCode();                            // Start the code for this method
con.visitVarInsn(ALOAD, 0);                 // Load "this" onto the stack
        
con.visitMethodInsn(INVOKESPECIAL,          // Invoke an instance method (non-virtual)
        "java/lang/Object",                 // Class on which the method is defined
        "<init>",                           // Name of the method
        "()V",                              // Descriptor
        false);                             // Is this class an interface?

con.visitInsn(RETURN);                      // End the constructor method
con.visitMaxs(1, 1);                        // Specify max stack and local vars
```

In order to invoke any method in Java byte code, we need a pointer to the object
to be on the stack, and any parameters to be pushed onto the stack after it. There
are no parameters needed to invoke the no-arg constructor on `java.lang.Object`, but
we still need an object reference, specifically "this" since we are invoking a superclass
constructor on ourselves. Because we are inside a method, "this" is available to us as our
first local variable (number 0). So we can load it onto the stack.

We next add an "INVOKESPECIAL" operation. If you've looked at disassembled Java code, you
know that most method calls use "INVOKEVIRTUAL". But in this case, we don't want virtual
function behavior, because that would mean calling back into our own subclass no-arg
constructor, which would be bad. So we need "INVOKESPECIAL", which is used for private methods
and other special cases like calling "super()".

Finally, we have to explicitly return from the method; that's another thing the compiler
does for us. We then call `visitMaxs()` to provide a couple numbers to ASM so
when this method is run, Java can make sure there is enough memory space for
it. First, we specify a maximum stack size. Since we only push one thing onto
the stack, this is 1. Second, we specify the maximum number of local variables.
Even though we declared no local variables, and we have no parameters, our
"this" counts as a local variable, so we have to set it to 1.

Lots of work so far, but we haven't written any code that does anything! Fortunately, that is
coming next. We can now implement the "add" method from our interface:

```java
/* Build 'add' method */
MethodVisitor mv = cw.visitMethod(
        ACC_PUBLIC,                         // public method
        "add",                              // name
        "(II)I",                            // descriptor
        null,                               // signature (null means not generic)
        null);                              // exceptions (array of strings)
        
mv.visitCode();
mv.visitVarInsn(ILOAD, 1);                  // Load int value onto stack
mv.visitVarInsn(ILOAD, 2);                  // Load int value onto stack
mv.visitInsn(IADD);                         // Integer add from stack and push to stack
mv.visitInsn(IRETURN);                      // Return integer from top of stack
mv.visitMaxs(2, 3);                         // Specify max stack and local vars

cw.visitEnd();                              // Finish the class definition
```

The call to `visitMethod()` looks very similar. Of course the name is different, as is
the descriptor. In this case, `(II)I` states that this method takes two primitive "int"s as
parameters, and returns an int.

Within the code block, we reference our two parameters, which show up as local variables.
We load those onto the stack, call "add", then return the result. For this method, we have
two things on the stack at maximum (since the add operation takes the operands off before it
pushes the result onto the stack), and we have three local variables: one for "this" and two
for our parameters.

This was the last bit of code we needed, so we can now close things up. We now have all the
definitions in place for our class; we just need to ask ASM to generate the bytecode for us,
then load it and use it like any other Java class.

```java
DynamicClassLoader loader = new DynamicClassLoader();
Class<?> clazz = loader.defineClass("dynamic.DynamicCalculatorImpl", cw.toByteArray());
System.out.println(clazz.getName());
Calculator calc = (Calculator)clazz.newInstance();
System.out.println("2 + 2 = " + calc.add(2, 2));
```

That was a lot of work to create a Java class that can be written in about five lines
of code. But at least for me, stepping through this and learning it (and teaching to others)
helped me understand some of the behind-the-scenes behavior of the Java Virtual Machine.
Hopefully it's helpful to you as well.

