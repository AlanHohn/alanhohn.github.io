---
layout: post
title: "Process Improvement and Innovation"
description: ""
category: articles
tags: []
---

Recently I wrote several articles on [The Case for Lean][1]. In that context I
was writing about lean agile methods, specifically a class of agile methods
that do not include "sprints" but instead use a continuous flow system with
limits on work-in-progress. In those articles I tried to show why you might
choose continuous flow over sprints to fit certain situations. By contrast, you
might call this article "The Limits of Lean", since I intend to write about
something that can get overlooked when using lean techniques.

[1]:https://dzone.com/articles/the-case-for-lean-oversight

One term that is used within lean is [Kanban][2]. Kanban is a manufacturing
system that controls how much partially completed product is allowed at each
stage of the manufacturing process. The idea is to allow demand, ultimately
from the customer, to "pull" product along the line by not allowing anyone to
work unless their station is below the limit. Of course, the idea is not for
people to sit idle, but for any bottlenecks to become visible and be
immediately addressed.

[2]:http://kanbanblog.com/explained/

### Lean and Green

This idea of lean manufacturing was carried into a variety of other places before
Kanban became explicitly identified with agile software development. I myself
trained as a [Lean Six Sigma][3] "green belt" quite a while back. We spent an
enjoyable afternoon flipping pennies and recording the results.

[3]:http://www.leansixsigmainstitute.org/

One of the key techniques of Lean Six Sigma is known as [Value Stream Mapping][4].
In Lean Six Sigma, there is a very narrow definition of what qualifies as
"value add": it has to add value, from the customer's perspective, and the customer
has to be willing to pay more for more of it. It quickly becomes apparent that
very few activities in a business fit that definition of value add. One activity
that clearly does is creating additional working software, which is why one of
the agile principles is that "working software is the primary measure of progress".
Other activites, such as peer review or testing, are considered "Required
Non-Value-Add". We have to do them in order to get value from the working software,
but there comes a point where the customer won't pay us more no matter how many
times we test the same code.

[4]:http://leanmanufacturingtools.org/551/creating-a-value-stream-map/

### Business Critical, Not Value Add

This perspective is challenging, especially to people whose work is business
critical but is Required Non-Value-Add.  (Even less enjoyable is to fall
into the third category, "non-required non-value-add", which Lean Six Sigma calls
"waste".) Still, it is an important perspective to keep; if nothing else it has
kept me humble as a software lead, manager, or architect, because it's a
reminder that those jobs are important but they are actually further from value
than slinging code.

Of course, companies have managed to turn Value Stream Mapping into a big
ceremony-driven process (and consultants have turned it into big business.) But
it doesn't require a ["Kaizen Event"][5] to identify opportunities to reduce
waste or limit required non-value-add activities. That kind of thing can and
should happen continuously. Or, to put it another way, every agile retrospective
should be a Kaizen Event.

[5]:https://www.isixsigma.com/dictionary/kaizen-event/

However, there is a sense in which Value Stream Mapping and Kaizen are limited
in their ability to find improvements. Looking at [this example plan for Kaizen][6],
we can see that the very beginning of the event is collecting information and
documenting the "current state"; that is, what the team is currently doing. The
limitation to this is that it implicitly restricts the improvements to changes to
the current state, because human beings have a hard time envisioning things that
aren't visible while being presented with something that is visible. What ends up
going missing is innovation.

[6]:https://www.isixsigma.com/methodology/kaizen/a-plan-for-a-five-day-kaizen/

### Innovation is Discontinuous

When looking at a process, I like to identify what I call the "Magic Happens Here"
step; that is, the step in the process where a human being is asked to do something
creative or skilled. From a lean perspective, this tends to be where the value gets
added. Keeping that analogy, we might say that Kaizen is about reducing the activities
where there is no magic happening, so that magic can happen more efficiently. But
innovation is about better magic.

Tools like Vagrant and Ansible are a perfect example of this. One of my teams was
working back in 2005 to build a virtual machine that ran the latest version of our
software, to use for development and integration. Having this virtual machine was
a significant improvement in our value stream, if you'll forgive the jargon. Rather
than have to take a software update to the lab, we could test it immediately in a
realistic environment with the necessary simulators and infrastructure. So we
spent less time on required non-value-add activities like waiting on installs, and 
less time on waste like waiting for other people to finish.

To build this virtual machine, we had someone walk through a manual install and
setup, then spun it out to a snapshot for everyone to copy. We did a lot of
scripting to get it to update to the latest software version. Thanks to Vagrant
and Ansible, for us to stand up exactly the same kind of virtual machine and
install software on it can be fully automated and takes around five minutes,
with configuration changes under version control. I have a hard time believing
that any amount of Value Stream Mapping would have caused anyone to come up
with the idea for Ansible. Rather, we might have tried to make more and better
snapshots to reduce the number of times we had to repeat the manual steps. Or,
we might have tried more and better Bash scripts to automate the setup.  None
of that leads to the idea of a tool that exists to apply an idempotent
configuration to a system. And once the tool exists, it creates a dramatic
change in how machines are built, affecting our virtual machines as well as how
we build for production. The concept is similar to trying to incrementally
evolve an airplane from a bicycle; not that the Wright Brothers didn't use a
lot of bicycle parts in their airplane, but whole new concepts were needed as
well.

### Wrapping Up

So that brings us to the challenge. We're too smart to imagine that we can
force innovation, or create a process for it. Rather, the question is, how do
we allow it to happen and seize upon it when it does? I think there are a
couple things that can help. First, often it takes at least two people to make
an innovation successful; one to have the idea and the other to show others how
to apply it. Allowing teams to emerge with this structure can be helpful.
Second, a pipe dream: the word "pilot" should be a magic word that allows a
team to try out just about anything. (Leaders get concerned about teams chasing
new toys, but as long as the team is focusing on working software as made the
primary measure of progress, their objectives will stay aligned.) Third, one of
the agile principles is to put business people and developers together daily.
This is not just so that developers will have someone available to clarify user
stories.  It is also so that people who aren't constrained by knowing how
something works will interact frequently with people who aren't constrained by
knowing how something is currently being done.

