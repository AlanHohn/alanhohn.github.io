---
layout: post
title: "Looking Along the Beam: Analysis and Insight"
description: ""
category: articles
tags: []
---

I've been doing some work on team organization lately, and
it's caused me to return to an idea I had about "defining"
"process". Working in the defense industry, of course I've
seen a lot of plans and procedures for writing software. One
of my favorite things to do is to spot what I call the "magic
happens here" step.

It's a fun game to play. Take a design process like [this
one][pr]. I picked this one not because it's unique, since what
I'm describing is universal, but just because it was in the
first page of Google results for "software design process".

[pr]:http://www.slideshare.net/RiantSoft123/6-basic-steps-of-software-development-process

Under "System Analysis", it says, "[a]t this stage the system
is divided into smaller parts to make it easier [and] more
manageable for the developers, designers, testers, project
managers and other professionals who are going to work on
the software in the latter stages."

Did you spot the "magic happens here" step? The clue is the
use of the passive voice. The system "is divided". By whom?
What are the smaller parts? How do you know that the smaller
parts you've chosen are the right ones? This illustrates a
core problem with process documents (and with methodologies
like [Statistical Process Control][spc]. Nothing in the
process is going to help you figure out whether what you've
built is any good or not. If what you're building is bad,
process control is great at making sure you're consistently
terrible.

[spc]:https://en.wikipedia.org/wiki/Statistical_process_control

Thinking about this, I realized that there's an
interesting parallel to C.S. Lewis' ["Meditation in a Toolshed"][ts].
Those who think of Lewis as a writer of children's stories may
not be aware that he was a respected literary critic and an
expert on Medieval and Renaissance literature. In this 
particular essay, he writes about being in a dark toolshed, with
one beam of light coming through a crack in the door. He starts
by looking *at* the beam of light, with specks of dust floating
in it. Then, he shifts so he is looking *along* the beam.
Immediately, instead of seeing the beam, he sees outside to
trees and the sun.

In our thinking process, what we call "analysis" is like looking
at the beam. The word "analysis" itself comes from a Greek word
meaning "loosen". With analysis, we are separating things into
their parts so we can understand how each part works and how they
fit together. Planning for software development is much like that;
we devise grand plans for how we're going to get started on a new
piece of software. What actions do we need to take first? How do
those actions help us with the next actions (process inputs and
process outputs)? What are the parts of the software itself and
how do they fit together?

Lewis believed that the modern mind prioritizes analysis
over other ways of knowing and understanding things, because of
the phenomenal success that modern science has had in taming the
natural world. It seems to me that engineers tend to be even
more inclined toward analysis than the average person, because
taming the natural world is what engineers do. And in areas like
software, where chaos is at a maximum, our desire to analyze,
comprehend, and fully specify a software engineering process is also at a
maximum.

The other way of looking at something is of course "synthesis",
which comes from a Greek word for placing together. On a couple
occasions when I've written a piece of software of which I was
later inordinately proud, I found that it was necessary to
struggle to hold "the whole thing" in my mind at once in order
to see how particular pieces of it should be implemented.

But I don't want it to sound like I'm trying to encourage
software engineers to adopt a mindset of synthesis over 
analysis, for a couple reasons. First, as Lewis points out in
his essay, both forms of seeing are valid. "One must look
both along and at everything." Second, while you're looking
along the beam, you're focused on something else external.
That is what you're looking *at*. In software engineering, synthesis
comes when we're focused not on synthesis but on the real-world
problem we're trying to solve. To try to "get" synthesis is fatal,
because you start thinking about the mental process of synthesis
rather than the thing you're trying to synthesize.

To me this is the fundamental flaw of all of the "creative" procedures 
like "brainstorming".  At a minimum, it's a silly exercise where we
write down the good ideas we already had and some ideas we know are
bad to fill the space. At its worst, we end up analyzing brainstorming,
breaking it into [10 Longtime Brainstorming Techniques That
Still Work][bs]. Our attempt to "be creative" ends up being one
more process to follow and the "magic happens here" has still eluded us.

[ts]:https://www.calvin.edu/~pribeiro/DCM-Lewis-2009/Lewis/meditation-in-a-toolshed.pdf
[bs]:http://www.inc.com/john-boitnott/10-longtime-brainstorming-techniques-that-still-work.html

One final note: this way of thinking has helped me better understand
and accept that most of my arguments for a particular architecture
or design approach are really post-hoc rationalizations for decisions
made unconsciously. Often, where I've put together an architecture
that ended up working well, the best features of it are emergent.
I didn't go in specifying that things would work a certain way;
instead, they worked a certain way because of the necessary interaction
of parts that were put in place for a different reason. 

For example, in one architecture I worked, I designed the application layer to
send asynchronous messages to update user displays whenever data would change.
This approach ended up simplifying both the keeping of an event log and the
integration of external components from outside the architecture, but that was
not my original reason. My reason is that the legacy system I was replacing had
allowed display-specific logic to creep down into the application layer, and
the asynchronous messages were an architectural separation to prevent that in
the new system. And even that reasoning is somewhat post-hoc; the truth is that
the approach just "felt" right.

This article has been intentionally descriptive, not prescriptive,
because I don't think there's anything you can "do" to make sure you're
properly balancing these two ways of seeing. For what it's worth, I've
found it helpful just to recognize that this perspective exists and
not to expect too much out of a single approach.

