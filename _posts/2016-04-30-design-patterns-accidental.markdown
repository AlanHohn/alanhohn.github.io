---
layout: post
title: "Design Patterns Are Accidental"
description: ""
category: articles
tags: []
---

Henrik Warne's [list of programming quotes][quotes] was recently
published on DZone. One great quote was from Fred Brooks, longtime
head of Computer Science at the University of North Carolina,
just around the corner from DZone itself. The quote was: "Much of the essence
of building a program is in fact the debugging of the specification."

[quotes]:https://dzone.com/articles/more-good-programmingquotes

"Essence" is a word we use every day to mean "the heart" or "the center" of
something, but as he explains in ["No Silver Bullet"][nsb], the essay from
which this quote comes, Brooks himself uses that term in the same way that
Aristotle used it. It means something absolutely required, as opposed to
something "accidental", that is, something that is part of building a program
today, but may not be part of programming tomorrow.

[nsb]:http://www.cs.nott.ac.uk/~pszcah/G51ISS/Documents/NoSilverBullet.html

So what Brooks is saying in his quote above is that debugging of the
specification, which I would define as "figuring out exactly what it is
that we're supposed to be building here" is a necessary task, maybe *the*
necessary task in programming. Which makes sense.

So what kind of things would we consider "accidental"? By accidental, we
don't mean things that are chosen randomly, or for no reason at all. Instead,
we mean things that could be changed while still resulting in the "same
program" from the perspective of the user or another program. It occurs to
me that one answer is "design patterns"; those design approaches within the
software that we use to make the implementation clearer and easier to maintain,
but that do not in themselves affect the program we're writing.

My [previous article][prev] on design patterns got a great comment from
Serguei Meerkat pointing out that some developers see design patterns as
essential to writing a good program, and that "the result is usually an
unreadable and unmaintainable code". I believe that this is because
those pattern-happy developers put the cart before the horse. By focusing
on something that is accidental to the program, like "what design pattern
shall I use today?" rather than something essential like what the program
must do, they get stuck stuffing the essential complexity of the program's
job into the wrong-shaped box of the chosen design pattern.

[prev]:https://dzone.com/articles/design-patterns-are-not-blueprints

It's like the novice programmer in [The Tao of Programming][tao]:

> A novice programmer was once assigned to code a simple financial package.
>
> The novice worked furiously for many days, but when his Master reviewed his
> program, he discovered it contained a screen editor, a set of generalized
> graphics routines, and an artificial intelligence interface, but not the
> slightest hint of anything financial.
> 
> When the Master asked about this, the novice became indignant. "Don't be so
> impatient," he said, "I'll put in the financial stuff eventually."

[tao]:http://www.mit.edu/~xela/tao.html

Of course, "accidental" parts of a program are very important. The choice of
programming language can make it easier or very much harder to write a program.
The choice of algorithms and data structures can be the difference between 
poor performance and excellent performance. And the use of design patterns can
mean the difference between a program that everyone hates to maintain, and a
program that lasts a long time and somehow seems to anticipate the new
features that are thrust upon it. 

Also, "accidental" items like design patterns and programming languages,
exactly by virtue of being "accidental", are applicable to a broad range of
potential programs, so learning them pays dividends beyond just the current
job. A developer who works in the financial sector yesterday and developing
social media apps today has a head full of financial knowledge that isn't
useful any more, but is probably still using factories.

So just like in my article about [Looking Along the Beam][beam] we have to
try to keep both perspectives. But in this case, one of the perspectives
*is* superior to the other. As we put together the architecture and design of
a system, it absolutely should start with the "essential" elements of the
system we're making. 

I remember a project from many years back where there was already a clear,
established way in which human beings performed some work. The system we were
building was one in which computers were asked to just automate that existing
work. The human beings already had perfectly clear terms to refer to the parts
of their job. (Sorry, details stripped to protect the national security.) 

When the development team came in and established the "architecture", it
consisted of "Buy Big Company Product A", "Buy Big Company Product B", and
"Wire Product A to Product B". One top-level model in the system was labeled
something like, "Product to Product Interaction". Lost was the set of nouns
and verbs that the human beings were using to perform this work every day.  

As a result, it became impossible to figure out what part of the "architecture"
was responsible for any of the essential tasks that needed to be performed.  It
took a long time for that system to drag itself out of that approach.  Starting
with design patterns and shoehorning in the real system seems like a similar
error. 

[beam]:https://dzone.com/articles/looking-along-the-beam-analysis-and-insight

