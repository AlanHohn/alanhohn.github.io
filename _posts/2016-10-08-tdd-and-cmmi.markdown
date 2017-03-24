---
layout: post
title: "TDD and CMM"
description: ""
category: articles
tags: []
---

---
layout: post
title: "Suggested Zone: DevOps"
description: ""
category: articles
tags: []
---

*TLDR: Extreme Programming appears to be at odds with traditional
software engineering processes. But there are some interesting
parallels.*

Like over two thousand others at DZone, I recently read [Grzegorz Ziemoński's
article][1] on Test Driven Development (TDD). I always enjoy Grzegorz's
articles and appreciate his bold willingness to state opinions. I especially
respect any author who takes on the challenge to write about things they've
done wrong.

[1]:https://dzone.com/articles/three-modes-of-tdd

I'm also a fan of TDD, or at least what the JUnit folks call being [Test
Infected][2] (admittedly, not the best name). So what I'm offering here is a
counterpoint as opposed to a disagreement. Like [I've written before][3], I
think it is often necessary in programming to hold on to two ideas that are in
tension. In the case of TDD, in my view there is a serious benefit to building
tests in parallel with writing the software. But any attempt to argue that it
is a holistic or complete approach to programming is bound to fail.

[2]:http://junit.sourceforge.net/doc/testinfected/testing.htm
[3]:https://dzone.com/articles/looking-along-the-beam-analysis-and-insight

### YAGNI and YAGBATTAC

One of the stronger arguments for TDD is that it helps keep the code clean,
both in the sense of being designed for testability (which generally means
well designed) and in the sense of not including anything that is not necessary
to meet the requirements. Another way to say this is [You Ain't Gonna Need It][4]
or YAGNI. If it isn't immediately necessary to meet requirements, don't put it
in as a way of "future proofing" the code, because the future is uncertain and
what you really need to add to the code might not fit into your plan.

[4]:http://martinfowler.com/bliki/Yagni.html

But I think there's a counterpoint to YAGNI that is often invisible, which I
will call "You Ain't Gonna Be Able To Test All Cases", or YAGBATTAC (pronounced
"yag-ba-tack"). For an example, take the [Roman numeral code][5] from my
[article on table-driven tests in Go][6]. I have 41 separate test cases in that
code, but obviously it is way short of all of the possible inputs that the
function should handle correctly. 

[5]:https://github.com/AlanHohn/roman
[6]:https://dzone.com/articles/table-driven-tests-in-go

And it does no good to claim, "well, I tested the most important cases" or, "I
tested the edge cases". In order to know what the "most important" or "edge"
cases are for testing, we have to bring in *extra knowledge* from outside the
process of TDD. We have to make decisions about what the requirements mean,
and those have to come from somewhere. That means we have *an external standard*
which is the real source of our knowledge about when the code is "done". As a
result, it is no longer enough to say, "when the code passes all the test cases,
it is complete." Now we have to say, "when the code passes all the test cases,
and the test cases *represent* all of the functionality required of the code,
then the code is complete." That is a very different statement and one that is
much more subject to our engineering judgment.

Advocates for TDD understand this. On the [XP page][7] on test-first, it says
to continue until there is "nothing left to test". Where I think things go
astray is where TDD itself is treated as the source of the decision as to
whether there are more tests to write, out of some idea that it is obvious when
the system has "enough" or "complete" functionality. For simple cases like Roman
numerals and squares it might be possible to agree on "complete" functionality.
But for real systems it is not so easy.

[7]:http://www.extremeprogramming.org/rules/testfirst.html

### Magic is Going to Happen

Similarly, a critical step in TDD (and one that TDD advocates claim is
the difference between success and failure) is refactoring. The idea is
that we write a failing test first, then make it pass, then refactor to
remove duplication.

Now it is immediately obvious that while we have a clear measure of
sufficiency for writing the code (when the new test passes, we are done)
it is just as clear that there is no such rule for refactoring. How much
is enough? We talk about things like removing duplication or having only
one return from a method, but we know these are subjective rules of thumb
that have to be broken sometimes. It seems we are left again with our
engineering judgment. This is an example of the necessary tension I
mentioned above: we need to combine a willingness to go far in improving
the quality of our code with YAGNI. Knowing when to stop means knowing
how to balance those two seemingly contradictory ideas.

And that takes us to a deeper problem with using TDD as a complete
methodology. TDD examples like [this one with Roman numerals][8] are full
of statements like "it's pretty obvious", "we have discovered a rule based
on similarities", and "[l]ooks OK to me". You might say that these are
"design smells" where some kind of design activity is going on in the mind
of the programmer in a way that approaches jumping ahead to the solution in
a leap of insight. "Seeing" a generalization like this (or the one that enables
Grzegorz to go from `0.0` to `square*square`) is a pure act of human creation,
what I call a "Magic Happens Here" step that cannot be reduced to a process
or further decomposed into smaller subtasks.

[8]:https://remonsinnema.com/2011/12/05/practicing-tdd-using-the-roman-numerals-kata/

### TDD and CMM

And that is the way in which TDD, as it is often described, reminds me of traditional
software processes like the [Capability Maturity Model (CMM)][9]. To the extent that
either becomes a rote list of steps to follow that promise to remove the need for
human creativity and human aesthetics about what consitutes "good" design, "good"
architecture, or "good" code, they ultimately get in the way of building quality
software rather than enabling it. To the extent that TDD and any other "process" or
"practice" for making software incorporates the fact that engineering is a
creative activity, and that the process exists to serve and enable that
creativity, they are useful.

[9]:http://cmmiinstitute.com/

As I said above, I approach this topic as a fan of TDD (and code review, and
static analysis, and other "practices" to ensuring code quality). But there are
times when I feel our industry looks too hard for some silver bullet that will
take the uniquely human "craft" out of writing software. I would much prefer
that we just admitted that much of what we do is more craft than science and
spent our time learning to be better craftsmen.

