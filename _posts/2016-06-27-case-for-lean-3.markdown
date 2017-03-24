---
layout: post
title: "The Case for Lean: The Principal Agent Problem"
description: ""
category: articles
tags: []
---

I've found myself advocating for Kanban methodologies as I've
advised agile teams, and I'm working through my reasoning in
the hopes of understanding it better myself. In the [first article][1]
I talked about program oversight, and in the [second][2] I talked
about team dynamics. This time I'm admitting to the fact that I
went to business school as I talk about the principal agent problem.

At the University of Minnesota [Carlson School of Management][csom] (Ski U
Mah), I had a professor who wrote [a book][3] on franchising.  In it, he quotes
a cleaning company CEO with a great assessment of the joys of business. "You
see, a manager will do what you want, but he won't work very hard. A franchisee
will work hard, but he won't do what you want."

In business school terms, this idea in general is called the "principal agent
problem".  Let's say you start a business. As the owner and sole employee, you
want the business to get bigger. Now you hire your first employee. Obviously
their interests are somewhat aligned with yours; if the business fails, they
are out of a job. But their interests are not fully aligned with yours. As long
as the business can afford to pay them, they don't really need the business to
grow.  As Peter Gibbons says in *Office Space*, "that will only make someone
work just hard enough not to get fired."

So lots of professors have thought hard about this, and lots of managers live
with it every day. And, of course, managers try to deal with it by measuring
their employees' output, and incentivizing them to increase their output
(either with bonuses, raises, or with threats of getting fired). But as a
business gets bigger, the direct impact of each employee on the growth of
the business gets less and less direct. So it becomes harder and harder to
use things like profit sharing or a direct equity stake to motivate someone's
behavior. Instead, managers measure things that the employee can control. But
those things aren't perfectly aligned with the growth of the business, so
just because the employee can maximize that measurement (and their bonus)
doesn't mean the business benefits. And when employees know they're being
measured on something (or even when they *think* they're being measured on
something) they will change their behavior accordingly, even if that's not
the best thing for the business.

This is especially a problem where the work involves creativity and has
qualitative attributes, which certainly is true in engineering. We software
engineers can't generally agree on a standard as to what makes some code
better than other code, and even where we do agree on a standard it wouldn't
allow a useful comparison of two completely separate pieces of code written
by different people to do different things. There's also the problem introduced
when measuring on individual output while people are working in teams, which can
harm team dynamics.

You can't make this problem go away. The best you can do is two things. First,
make sure that, as much as possible, what you measure is well aligned with
what is good for the business. Second, break the direct link between measurement
and incentives at the level of the individual, both by measuring just at the
team or organization level, and by clearly demonstrating that a wide variety of
behaviors are considered valuable (not just individual output, but also
teaching, mentoring, and making others more efficient).

One more digression, while on this topic, since this is a major hobby horse
of mine. For those managers that think, "if you can't measure it, you can't 
manage it," I would say first, [Deming didn't say that][deming], and second,
you'd better figure out how to manage it.

OK, so what does this have to do with agile and Kanban? Well, there has
been a lot of work around measuring the performance of agile teams, and our
perspective on the principal agent problem can help us understand and assess it.
First, think about typical agile measurement used in a sprint methodology.
The team ends up with a velocity per sprint, usually measured in story points.
Note that this metric is unitless as long as story points are unitless. This is
on purpose. The people who invented story points were quite aware of the principal
agent problem and the fact that measuring something alters it, and set out to
create something that is hard to use for comparing teams or measuring changes
in performance over time.

Unfortunately, we're not really left with much that *can* be used to measure
value to the business. And that is a problem, because while we must manage all
sorts of things we can't measure, large organizations are going to have to manage
a lot of things by measurement, because there's just no other way to have a large
organization. (Maybe the right answer would be to not have large organizations,
but while we have them, that answer is of limited utility.)

So what ends up happening, in my experience, is that teams get encouraged to
make their story points "unitful" so they can be compared across teams and over
time. Or, some other method is used to achieve the same thing, like measuring
completed stories or requirements. The disadvantage of this, in a sprint-based
methodology, is that there is an incentive to declare a story "done" to improve
the metrics, especially at the end of a sprint when the sprint goals are in danger.
This kind of temptation is hard to resist, since that's the only apparent thing
that can make the metric look better.

On the other hand, if we're using a Kanban methodology, what we are typically
measuring is flow: how much time it takes to get some business requirement from
the point at which we start working it until it is delivered to the customer.
In this context, while there can still be an incentive to declare victory on
something to improve the metrics, there are other, less-risky ways of improving
the numbers. First, we can break work into smaller pieces so it can flow through
the process more quickly. Second, we can identify and remove bottlenecks that are
slowing things down.

The key insight about these two approaches is that they actually align with what
is valuable for the business. Finding ways to break the work up so we can deliver
quicker makes us more agile, so we can respond better to change. Removing bottlenecks
removes waste from the process. Of course, it is possible to do both those things
in a sprint-based methodology, and they would have similar positive results. But
in a sprint-based methodology, the need to do them is less obvious because it's not
being directly measured.

I'm not suggesting that this will immediately fix what's wrong with an organization.
But what the organization measures and how the measurements are used have a significant
impact on culture. Sometimes just starting to measure something is enough to identify
that it is important.

[1]:https://dzone.com/articles/the-case-for-lean-oversight
[2]:https://dzone.com/articles/the-case-for-lean-team-dynamics
[csom]:http://carlsonschool.umn.edu/
[3]:https://www.amazon.com/Franchising-Dreams-Lure-Entrepreneurship-America/dp/0226051919/
[deming]:https://blog.deming.org/2015/08/myth-if-you-cant-measure-it-you-cant-manage-it/

