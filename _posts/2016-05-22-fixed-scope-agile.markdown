---
layout: post
title: "Agile on a Fixed Scope Contract"
description: ""
category: articles
tags: []
---

I spent a recent week working with a program that is starting up some work
using an agile methodology, but has a mixed team, both in terms of time on the
program and time with agile. So it was an interesting week, because I picked up
a bunch of new ideas from people with experiences different from mine. It also
means I've done a lot of thinking about agile, which hopefully will result in a
few interesting thoughts to write down.

One of the biggest questions on the program is how to handle agile on a fixed
scope contract. It's all very well to say that we value customer collaboration
over contract negotiation. And we do; even in the defense industry, very few
programs over my couple of decades of experience actually go to court or
contract arbitration to resolve disagreements, and only in cases where the
customer relationship has already broken down irretrievably.

## The Fixed Scope Challenge

But what about the cases where the customer relationship is good, but the
customer just isn't interested in early delivery or in changing the scope of
the contract? I don't think it does any good to tell a team that has no control
over their customer's mindset that agile will be ineffective without that
flexibility. And I don't think it makes sense to be the absolutist that thinks
agile isn't worth doing in these kinds of cases.

I understand that for agile advocates, it can be frustrating to see teams
operate with "constrained" agile or "partial" agile, run into problems, and
then see agile get the blame. Unfortunately, I think that frustration is just
something we have to live with; the cost of discouraging agile adoption in
cases where the program isn't "pure" agile is to discourage agile adoption as a
whole, and to convince people that agile methodologies can't be that great if
they only work on unrealistic "perfect" programs.

So if we're going to encourage the use of agile, even in cases where the
customer doesn't intend to be flexible about scope or schedule, we have to face
that problem squarely. Of course, the customer is giving up the ability to
adjust and prioritize the work in response to more information. If that's not a
priority for them, we can mostly ignore it, though we might still want to try
to pull them in as much as possible to see what we're building so we ensure we
don't disappoint them at the end.

The bigger issue is that our fixed scope and fixed schedule, by definition,
has to be based on some estimate that has less fidelity than we'll have
once we start doing the work. So when we run into those inevitable challenges
where something is harder than expected, we won't have the flexibility to
work with the customer to give them the highest priority items first.

## Advantages We Get Anyway

So what advantages do we get from agile on this kind of contract? I think
there are still plenty worth having:

* Lower risk. Even in cases where the customer or program leadership does
  not have a positive connotation for the word "agile", it tends to be
  very easy to present the practices of continuous integration and
  automated test. It is obvious that putting a lot of software pieces
  together all at once is risky, and that tests that can be run continuously
  as the software changes can be an early warning of introduced bugs.
* Easier staffing. Traditional programs have a bell-shaped curve of
  staffing. In my industry, systems engineering peaks first, followed by
  software and hardware, followed by the test organization. It is hard to
  staff up to the peak, both in terms of availability and in getting people
  up to speed on the work. Agile tends to emphasize level staffing, with
  teams working continuously, which is easier on both counts.
* Efficiency. As I've pointed out [before][prev], I don't think a primary
  motivation for agile should be cost or schedule savings. Methodology changes
  are [accidental][], not essential, which means they don't make the real
  problem any simpler. Still, if by bringing in agile methodologies, and
  keeping the cross-functional team in place, can reduce the amount of
  documentation that is needed to communicate within the team (and reduce
  the confusion that results from throwing requirements documents over the
  wall), then some work can be avoided.

[prev]:https://dzone.com/articles/expected-utility-and-agile
[accidental]:https://dzone.com/articles/design-patterns-are-accidental

## Specific Suggestions

So we've decided that it's still worth following an agile methodology on
a fixed scope, fixed schedule contract. But we would like to do more than
just run our agile program within a "waterfall box". So what do we do? It's
hard to make a complete list, but I can think of some good suggestions:

* Leverage Ambiguity. Fixed-scope programs typically have some "source"
  requirements document that comes from the customer. Every one of these
  documents has some kind of ambiguity in how the requirements will be
  met. An agile program can start by minimally meeting the requirements,
  especially in areas that are not perceived to be as important to the
  customer.
* Work the System. Even fixed-scope programs typically have some process
  for change. (In the defense industry, we typically call this an
  Engineering Change Proposal or ECP.) Over time, the program manager builds trust
  with the customer (which can be helped by early demonstrations of real
  functionality, even for customers who do not value "agile"). This trust
  can be leveraged to get customers comfortable with small contract changes
  to trade a fuller implementation of a feature for the removal of some
  unimportant but annoying requirement.
* Keep the Practices, Lose the Jargon. Some customers may not have a positive
  view of agile, because some previous vendor ruined agile for them by doing
  it badly. In many cases, though, the practices of agile are obviously
  superior and can be used as long as the agile-style jargon is avoided. So
  Kanban becomes "continuous workflow tracking system", and agile itself
  becomes "feature based development". Nothing is being hidden here; in fact,
  by using language from the customer's vocabulary, the value of the practices
  is being made clearer.
* Play the Long Game. It is a clear fact that even on a fixed-scope, fixed-
  schedule contract, a customer will allow a contractor to do almost anything
  in terms of interpreting requirements and adjusting schedules as long as the
  customer trusts the contractor. It takes a long time to build that trust, but
  the transparency, focus on working software as a measure of progress, and
  continual process of really listening to the customer that comes with agile is
  the fastest way to build that trust. And at the end of the day, the
  individuals and interactions are more important than our processes and tools,
  even agile processes and agile tools.

None of these suggestions will make 10 months of work fit into a 5 month schedule.
But that 10 months of work was never going to fit into 5 months anyway. At least with
an agile methodology, there's a chance the customer will be brought to realize that
fact while there's still time to focus on the most important half.

