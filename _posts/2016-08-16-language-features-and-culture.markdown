---
layout: post
title: "Language Features and Culture"
description: ""
category: articles
tags: []
---

I was reading an interesting article on DZone recently that pointed
out how many different programming languages have a rich community
producing modules that are available for reuse. In some cases this
community is not strictly affiliated with the creators of the language
itself.

It's instructive to see just how many examples there are out there. This
is just a few that popped into my head without thinking hard.

* Perl has the [Comprehensive Perl Archive Network (CPAN)][cpan].
* R has the [Comprehensive R Archive Network (CRAN)][cran].
* Python has the [Python Package Index][pypi].
* Node.js has the [Node Package Manager][npm].
* Ruby has [RubyGems][gem].
* Java has [Maven Central][maven].

[cpan]:http://www.cpan.org/
[cran]:https://cran.r-project.org/
[pypi]:https://pypi.python.org/pypi
[npm]:http://npmjs.org/
[gem]:http://rubygems.org/
[maven]:http://search.maven.org/

Together these repositories represent millions of programmer hours spent
putting together libraries, and probably millions of hours spent maintaining
the index and the servers on which they run. On the other hand, even though
C and its semi-successor C++ have been around since before the Internet age,
there isn't an exactly equivalent library and module system available.

Of course, C is the language of Linux, and so to some extent your favorite
package manager is a C and C++ library and module system. But there's 
pretty clearly a difference in scope between what's available for C or C++ and
what's available even for a relative newcomer of a language like [Go][] or a
language with a relatively small user base like [Haskell][]. Compare the
[Hackage][] with this [list of C++ libraries][cpp].

[go]:https://golang.org/
[haskell]:https://www.haskell.org/
[hackage]:http://hackage.haskell.org/packages/
[cpp]:http://en.cppreference.com/w/cpp/links/libs

Why is that? There's clearly a large and high quality user base for C and
C++. I think that the issue comes down to language features and to one
language feature in particular: garbage collection. To explain why I'll give
an example.

Several years back, I spent some time building a cross-platform user interface
based on the Mozilla codebase. How we arrived at that approach is a long story,
but it did allow us to create something truly cross-platform, with the ability
to build the user interface using HTML and JavaScript, with some C++ as needed
on the back end, and to end up with a rich client user interface. (This was back
before modern browsers made browser-based interfaces good.)

As a result, I spent a lot of time in the Mozilla code base for someone who
wasn't part of the team. I learned a lot about C++ from that code base; it
remains a very impressive example of large-scale C++ development. 

As expected, a decent amount of the core work that became the Mozilla codebase
was centered around making the same C++ work well on Windows, Linux, and Mac,
via two isolation layers: the [Netscape Portable Runtime (NSPR)][nspr] and the
[Cross-Platform Component Object Model (XPCOM)][xpcom].  NSPR allows most of
the Mozilla codebase to be written independent of the underlying operating
system. It handles the kinds of things you would expect: threads, input /
output, networking, etc.

XPCOM provides a number of cross-platform features similar to Microsoft COM.
The most visible in terms of its impact in the Mozilla codebase is memory
management in the form of "nsCOMPtr" smart pointers, similar to [COM smart
pointers][com].  Basically, a smart pointer is a pointer that keeps track of
how many things are pointing to it, and cleans up the thing it's pointing to
when no one is using it anymore. It's an elegant alternative to garbage
collection; instead of having a core runtime function that finds unused
allocated memory and cleans it up, each new allocation of memory comes with a
little bit of garbage collection intelligence.

[nspr]:https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSPR
[xpcom]:https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM
[com]:https://msdn.microsoft.com/en-us/magazine/dn904668.aspx

Of course, in order for this smart pointer to work, any time a new reference to the
pointer is stored outside a single function scope, the smart pointer needs to be notified
so it can increment its count. And whenever that reference goes out of scope, the pointer
also needs to be notified. And the consequences of missing one of these is pretty
significant, either in the form of memory leaks or in the form of dereferencing a pointer
that is no longer valid.

This is one of the most sophisticated memory management schemes available in a
non-garbage-collected runtime. But it's hard to imagine how it could be made to work
across a wide range of libraries. Either each library would have to build on top of
a single implementation of smart pointers, or each library would have its own similar
scheme to learn (and bridge between when integrating multiple libraries).

And that's exactly what we see when we look at some example libraries.  Imagine
an XML or JSON parser in C that provides data binding to a struct. The parser
needs to allocate the memory for the struct (or array of structs), along with
variable sized data inside. How long should this allocated memory stick around?
The application code that uses the struct data ideally should not have to worry
about the fact that it came from JSON, but somehow there has to be a way to
identify that the application is "done" with the data. To solve this issue, the
very well written [json-c][jsonc] library provides its own reference counting
that is very similar to COM smart pointers.  Unfortunately, that leaves the
onus on the using application to help out with reference counting, even if the
corresponding data is passed to some other library that might use it for an
unknown amount of time. The same kind of functionality can be found in [GLib][]
as used in the GNOME Toolkit, and in [Boost][]. 

All of these implementations are different, so a programmer using these three
libraries would need to learn and remember three different APIs for handling
pointer references. Under these circumstances, it's little wonder that
libraries in C and C++ tend to be limited in scope and mostly serve to isolate
from hardware or provide low-level implementation of a standard. 

[jsonc]:https://github.com/json-c/json-c
[glib]:https://developer.gnome.org/gobject/stable/gobject-memory.html#gobject-memory-refcount
[boost]:http://www.boost.org/doc/libs/1_61_0/libs/smart_ptr/smart_ptr.htm

I for one consider this a very interesting thought. The primary argument in
adding garbage collection to a language is that it raises the level of
abstraction, allowing a clearer focus on the business logic of the application
by avoiding boilerplate memory management code (and also thereby decreasing the
chances of errors caused by memory management done poorly). But the broader
effect is to create a different kind of culture where a broad set of
community-contributed libraries are possible. It neatly illustrates the way
that [the best features of a system are often emergent][toolshed].

[toolshed]:https://dzone.com/articles/looking-along-the-beam-analysis-and-insight

