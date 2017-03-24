---
layout: post
title: "Expected Utility and Agile"
description: ""
category: articles
tags: []
---

### Selling Agile

When convincing others to adopt agile practices, I have often found it useful
to discuss those practices in terms of risk reduction. For example, we can talk
about continuous integration in terms of reducing the "schedule risk" that
results from performing all the integration at the end.

Unfortunately, selling agile in this way has a major disadvantage, which is
that people tend to associate reduced risk with reduced cost, even though that
is not really a valid association. In fact, I'm not sure that there's any
reason to expect agile to be less expensive in the "everything goes well" case,
because there is an increase in certain repetitve activities like planning and
integration. Thinking about this problem led me to start thinking about
choosing agile in terms of [utility theory][ut], which is used in economics to
try to explain how humans actually make decisions.

[ut]:https://en.wikipedia.org/wiki/Utility

### Expected Value

The expected value, or the mean, is very easy to understand and use; unfortunately it
does not really consider risk.

Imagine that we have some software work that we can choose to perform
either using agile practices or using a more traditional approach. To
keep things simple, we'll decide that the value of the project is
the same either way, and we're not highly concerned about schedule or
about getting an early working version, so we just care about performing
the work at the lowest cost.

This may seem like an over-simplified assumption, but there are plenty
of plausible examples, like having the software ready for a new car or
airplane; in many cases software is not the schedule driver on that
kind of effort, and there is no where for an early version to run.
So the only remaining advantage to agile is the ability to try out
working code in a simulated environment, which is a risk reducer
but not value from the end user's perspective.

But even in this case, we buy the idea that agile practices will reduce risk.
So we might say that if we use our traditional approach, the project
will cost $1m with a standard deviation of $500k, and if we use an
agile approach, the project will cost $1m with a standard deviation
of $200k.

At this point, in a lot of organizations, we would just report the expected
value, which is the average expected cost. (For that matter, in a lot of
organizations we would only be coming up with a single number estimate, so we
wouldn't be able to quantify the lower risk, much less put it in terms of
standard deviation.) 

If we only look at the expected value we don't have any reason to prefer the
agile approach; in fact, we might avoid it because people quite rightly prefer
not to change for no reason. ("And the Gods of the Copybook Headings said:
['Stick to the Devil you know.'][kip]".)

[kip]:https://en.wikipedia.org/wiki/The_Gods_of_the_Copybook_Headings#Text

While this is a contrived example, I have absolutely seen similar situations,
where a team suggests process improvement with the intent of reducing
variability, only to be asked for some justification in terms of lower cost.
And what tends to happen is that software teams that "know" agile is a move in
the right direction will sometimes agree to lower their estimates, because a
better process must mean that there will be cost savings, right?

### Risk Aversion

The problem with the above way of approaching things is that, in the terms of
economists, we've taken a "risk neutral" strategy to comparing the two
approaches. And while it is true that some economics argue that companies
*should* take a risk neutral strategy, because over time successful projects
will balance out unsuccessful ones, in practice large projects that fail
can have unrecoverable negative impacts, and if anything we software estimators
tend to underestimate risk. 

So in practice we probably want to have a risk averse strategy. This means
that we would potentially be willing to pay more if it means we reduce the
potential downside.

To see how this works, consider a simple example. You are on a game show and
the host is offering you a choice. You can flip a coin; if the coin is heads
you win $100k, but if it's tails, you get nothing. Or, you can walk away with
$25k right now. Depending on your level of risk aversion, you may choose to
flip the coin at this point. But before you flip the coin, the host increases
the "sure thing" offer to $40k. At this point, even though your expected value
is higher with the coin flip, most people would take the money.

This is the primary insight of utility theory, which is that ordinary statistics
doesn't explain how people really behave, because they don't consider their
comfort with risk. (On the other side, a person who loves to gamble will spend
hours taking risks with a negative expected value, because of the small chance
of a big payout.)

### Expected Utility

So how does utility work in practice? There are different types of
equations, but the simplest uses an exponential function. 

$$ u(c) = 1 - e^{-ac} $$

In this equation, `c` is whatever we want more of, and `u(c)` is the "utility"
or benefit we receive from having a certain amount of `c`. (To express a desire
for reduced cost, we would just use the negative of the cost.) The variable `a`
is our level of risk aversion. Settling on this can be very challenging; it is
usually done through "games" such as the one described above, where people are
asked which of two scenarios they would choose. This is repeated until a
reasonably consistent value is achieved.

Also, since our ability to acquire `c` is uncertain, we need to extend this
utility function with the notion of "expected utility". This is the equivalent
to expected value, except instead of just finding the mean for `c`, we are
finding the mean for the utility function `u(c)` given the distribution of
possible outcomes for `c`.

Unfortunately, we have introduced some additional unknowns here, because in
addition to finding a utility function, which is challenging, we also need to
know the distribution of `c`, which is challenging. Here again some simplifying
assumptions can help. For example, for a normally distributed `c`, our expected
utility function is:

$$ 1 - e^{-a\(\mu-\frac{a}{2}\sigma\)} $$

This function will increase as long as this increases:

$$ \mu - \frac{a}{2}\sigma $$

Looking at this expression, it is easy to see that in our earlier example, we
would have a higher expected utility where we have a lower standard deviation.
And we can determine the value of the risk reduction by choosing a risk posture and
then setting the expression equal in the two scenarios. For example, for a risk
aversion value of `a = 0.5`, we would be willing to pay up to $75k more for the
reduction in standard deviation of $300k.

### Implications

If we really believed that we should be risk averse, we would be willing to
accept an approach that is more expensive as long as it is sufficiently lower
in risk.  In that case, it would be possible for the agile practitioner to say,
"switching to agile practices may be more expensive, because we will be
performing planning and integration in small increments. However, it will
reduce risk and therefore is worth doing."

Of course, to say that, there are a few things we might be expected to
produce, such as an estimate of risk before and after changing to agile,
and some sense of whether the additional expense is worth it, given
our risk posture. I'm interested in exploring the concept further to
see if there would be a reasonable way to quantify these items and to
provide an intuitive explanation for them. However, while I'm interested
in what the concept of expected utility says we should do, I'm not
convinced that it would be terribly useful. It's challenging enough to
explain agile practices using analogies to assembly lines. Bringing
in utility functions is not likely to make the explanations easier.

