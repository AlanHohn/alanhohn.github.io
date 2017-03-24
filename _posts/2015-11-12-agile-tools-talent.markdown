---
layout: post
title: "Agile Tools?"
description: ""
category: articles
tags: []
---

*tldr*The agile manifesto says to emphasize individuals and interactions over
processes and tools. So why do we spend so much time on tools?*/tldr*

The very first of the four values in the [agile manifesto][am] is, "[i]ndividuals
and interactions over processes and tools". The agile mentors I have worked
with emphasize this value when teaching agile; for example, they use only
flipcharts and sticky notes to teach new teams how to write user stories and do
sprint planning and daily standups.

However, so much of the time I have spent helping teams integrate agile has
focused on the "other" side: helping teams understand how agile "processes"
are different from their experience, and setting up tools to help them
run their project.

Of course, the manifesto says that "there is value in the items on the right".
Anyone who has had to develop software with inferior tooling knows the
productivity drain this can cause. I have worked projects where a full compile
and link was an overnight affair, and debug traces were limited to eight
static characters, with performance limits on how often a trace could be
printed. In that environment finding a simple bug could be a multi-day
process.

I think this example illustrates what the value is in processes and tools,
and why they are valuable but less valuable than people. Processes and tools
have the potential to be a [dissatisfier][tf]. They can interfere with how
the team performs work and with how they interact with each other. If the
tools or processes are getting in the way and slowing the team down, then
they just became important. Poor processes and tools can prevent teams
from having the kind of interactions necessary to create a bond and
an effective culture.

That said, people are more valuable because the processes and tools cannot do the work.
As I mentioned in a [previous article][pa], in every process there is a
"magic happens here" step where human creativity comes into play. The process
and the tools need to recognize where the real value of the work comes from
and not interfere.

At the same time, there is a positive side to processes and tools in that
they promote regularity in interactions. Inventing a new approach to every
problem is itself a productivity drain. For example, most teams now use
automatic formatters to solve issues like where line breaks and spaces
go in order to ensure consistency. That automated formatters do a poorer
job than human beings is less important than the human time saved not
carefully aligning variable declarations.

This understanding can lead us to a description of what good agile
processes and tools look like. First, they don't get in the way of what
the team wants to do. The team takes responsibility for planning work,
performing it, and maintaining quality. In exchange, the team deserves
trust in areas like making and controlling changes, and in how they
assign work and track completion.

Second, they allow for adaptation by the team. As a team forms, they
identify preferred ways of working, whether in how to divide the work
or how to move code through into production. If tools cannot be adapted,
the team will become dissatisfied and start looking for ways around them.
This adaptation allows the team to codify its culture and practices
into the tool so the tool helps the team encourage members to follow
the team's norms.

Third, they streamline the team's work by standardizing and automating.
Team members spend less time doing things that don't add value and
less mental energy deciding how to track work, communicate, compile,
test, and deploy software.

Hopefully, the processes and tools we choose for agile programs will
enable good interactions and help fulfill the goals of agile.

[am]:http://agilemanifesto.org/
[tf]:https://en.wikipedia.org/wiki/Two-factor_theory
[pa]:https://dzone.com/articles/situational-test-driven-development




