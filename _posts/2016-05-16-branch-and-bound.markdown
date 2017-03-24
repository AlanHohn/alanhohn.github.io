---
layout: post
title: "Dynamic Programming: Branch and Bound"
description: ""
category: articles
tags: []
---

## Reducing Unhappiness

Imagine yourself in the role of a city planner. Your job is to find a place for
some new undesirable thing, like an electrical substation (potential eyesore)
or a treatment plant (potential nosesore, if that were a word). You want to
choose a site that will irritate the smallest number of people, because irritated
people tend to show up at city council meetings, and that makes the people you
work for irritated with you.

You know that the negative impact to people falls off with the square of the
distance. However, it is also true that people are much more likely to be irritated
if the facility is near homes than if it is near a commercial or industrial area.
At the same time, there are inefficiencies introduced if the chosen site is too
far from the area it needs to serve, so you can't just locate it out in the middle
of nowhere. You need a way to optimize its location.

## Tractability and the Lack Thereof

A while back I [wrote about][prev] the assignment problem, and discused how it
can be solved with a general-purpose Linear Programming (LP) solver like
[GLPK][]. (Really, it needs to be solved with an Integer Programming (IP) solver,
because the way we formulated the problem, the variables must be either zero or
one. But there are ways to get from an LP solver to an IP solver, so in practice
the running time tends to be pretty similar.)

[prev]:https://dzone.com/articles/algorithms-the-assignment-problem
[glpk]:https://www.gnu.org/software/glpk/

I wanted to also write about a problem that can't be solved using a general-purpose
solver, because as a programmer these problems are a bit more interesting to me.
This is because they often end up being solved using dynamic programming, which
is a term from optimization that really just describes the kind of regular computer
program that we programmers are familiar with writing. To the mathematician, these
kinds of problems are "worse" because the solution is unpredictable in running time.

If there were only a few feasible sites within the constraint envelope, we
might just calculate the cost for each one and pick the lowest. But for bigger
and more complicated problems, it can be too expensive to calculate them all.
Think about finding a site in a city with thousands of affected homes and businesses;
just calculating the impact of a single point requires calculating the distances
to all these locations (and may include calculating many other factors as well).
So we need a way to find the best spot in the constraint envelope without having
to calculate every single point.

These kinds of problems have two main features that make them different from linear
or integer programs like the assignment problem. First, they tend to have cost
functions that are not just a linear mix of the coefficients. Second, they tend to
have non-convex constraint envelopes.

## A Few Words to Make Things Clear

We discussed both of these the last time, but it's worth a few words to make things
clear. In optimization, the cost function is how we calculate how "good" a particular
solution is. (Last time I called it the "objective function", but in this case I'm
using the term "cost function" to make it clearer that smaller is better.) All
of the information I discussed above, about impact decreasing with the square
of the distance, residential neighborhoods being worse than others, and
inefficiency if the site is too far, go together into the cost function. Once that's
done, we can calculate the impact for any particular site.

At the same time, we have a set of constraint functions that control what choice
we can make. It may be that we have to choose a site within a certain radius of a
point, or inside political boundaries, or within a certain distance of existing
transmission lines. These complex constraints mean that the constraint envelope
might be a very strange shape. We say that it is non-convex, which means it might
have "holes" or "dents". These might be holes or dents on the map, but because
our constraints can include non-geographic things, our constraint envelope has many
dimensions, so these might be holes or dents in some impossible-to-visualize
n-dimensional shape. So we have to start trusting the math rather than just our
intuition, though intuition is still important.

## Picturing Things Intuitively

When we created the cost function for the assignment problem, it was just a linear
mix of the coefficients. In other words, we just multiplied the coefficients times
the variables (which were either zero or one), then added up. From the perspective
of the solver, this meant that once it found an edge of the constraints, it was
easy to figure out which "direction" to move in order to improve the solution.
Similarly, the constraint functions were also linear, so the solver could move
along the edge of the constraint envelope until it hit a point where two or more
constraints intersect. This point would be better than all the points in between.

However, in this case, the cost function is much more complicated, and the
constraint envelope is non-convex. Because of this, we might move along the
edge of the constraint envelope in a direction that improves the cost function,
only to find that suddenly the cost function starts getting worse again. Or even
worse, we might blindly follow an improving direction only to get "stuck" in a
local minimum cost when there was a better solution somewhere else, but no direct
improving path to reach it.

## Enough Digressions Already

This is where dynamic programming comes in. In particular, I want to talk about
the dynamic programming technique called "branch and bound". We start out by
needing two things. First, we need a way to divide up the constraint envelope
into smaller and smaller pieces. This seems trivial, especially when we are
finding a location on a map, but it can actually be quite complicated, because
it is important that our "pieces" do not contain any illegal locations that
would invalidate the "bounds" we are going to calculate. Second, we need a way
to cheaply calculate, for each given piece, the upper and lower bound; that
is, the range in which all the costs inside must fall. This need not be a
"tight" bound; the algorithm will still work if we give too wide of a range.
But it will work more efficiently the tighter our bound can be. At the same
time, we are going to calculate these bounds lots of times, so they need to be
cheap to calculate.

The actual selection of a bound is specific to the problem. For our example of
finding a site for some undesirable thing, this might mean finding the impact
to each place for the closest location inside that piece and for the farthest
location inside that piece, possibly with a simpler calculation of impact that
either overestimates or underestimates it, depending on whether we need the
maximum or minimum cost.

All of that was the complicated bit; the rest is relatively easy programming.
We divide the whole area into the first set of pieces (rectangles can be used,
but triangles are also common as they make it easy to divide an area up into
multiple pieces so things can be run in parallel). Keep in mind that this
"dividing up" is happening in the constraint space, not necessarily in the
real world. So these might be "triangles" in n-dimensional space; each
triangle would still have three coordinates but each coordinate has `n`
components.

Once we have the pieces, we calculate the bounds for each one. Each piece
that is totally dominated by another (minimum cost higher than the maximum
cost of some other piece) is eliminated. The rest are subdivided again. In
the first few branches, very few pieces will be eliminiated, but as the pieces
get smaller, the bounds will naturally get tighter, and more and more pieces
will be eliminated without having to subdivide and calculate.

When we get below some threshold of accuracy, we calculate actual values for
the relatively small set of possible locations we have left, and choose the
smallest cost. You can see why this would be unpredictable in run time; we
don't know how many branches we will be able to throw away at each stage, and
that has a substantial impact on how much calculation we must do. But it does
have the advantage that it is guaranteed to finish, and it is guaranteed to
produce the true global minimum even with non-convex constraints.

## Wrapping Up

Despite the complexity of splitting into pieces in n-dimensional space and
of finding tight upper and lower bounds for complex problems, branch and
bound has always felt straightforward compared to other types of optimization.
Probably this is because I was a programmer first, and something this
algorithmic just feels like the "right" way to solve these kinds of problems.

