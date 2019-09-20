---
title: CS-550 Formal Verification
description: "My notes from the CS-550 Formal Verification course given at EPFL, in the 2019 autumn semester (MA3)"
edited: true
note: true
---

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
$$

<!-- More --> 

* TOC
{:toc}

## Transition systems

### Definition

We'll start by introducing transition systems, a generalization of DFAs. They may be not finite, and not deterministic.

> definition "Transition system"
> A transition system is a 4-tuple $M = (S, I, r, A)$ where:
>
> - $S$ is the set of states
> - $I \subseteq S$ is the set of starting states
> - $r \subseteq S \times A \times S$ is the transition relation
> - $A$ is the alphabet
> 
> For $s, s' \in S$ and $a \in A$, $(s, a, s') \in r$ means that ther is a transition from $s$ to $s'$ on input $a$.

A few special cases of this general form exist:

- If $S$ is finite, we have a *finite state machine*
- If $r: S\times A \rightarrow S$ and $\abs{I} = 1$, then the system is *deterministic*.

### Traces and reachability

> definition "Trace"
> A *trace* describes the states and inputs and steps in a relation $r$:
> 
> $$
> (s_0, a_0, s_1, a_1, s_2, \dots)
> $$
> 
> where we require, $\forall i$:
> 
> - $s_0 \in I$
> - $s_i \in S$
> - $a_i\in A$
> - $(s_i, a_i, s_{i+1})\in r$

A trace may or may not be finite. If they are finite, we can assume that the trace ends with a state $s_n$. We'll introduce some notation for traces:

> definition "Trace of a transition system"
> $\text{Traces}(M)$ is the set of all traces of a transition system $M$, starting from $I$.

> definition "Reachable states of a transition system"
> The reachable states are states for which there exists a trace that ends in $s_n$:
> 
> $$
> \text{Reach}(M) = \set{s_n \mid 
>   \exists n .\ \exists (s_0, a_0, s_1, a_1, \dots, s_n) \in \text{Traces}(M)
> }
> $$

To check for reachability, for a finite $S$, we can simply run DFS.

### Relations
Let's study relations more closely. A relation is a *directed edge* in the transition graph. We follow this edge when we see a given input $\in A$.

If we look at the graph, we may not be interested in the inputs associated to each edge. Therefore, we can construct the edge set $\bar{r}$:

$$
\bar{r} := \set{(s, s') \mid \exists a \in A .\ (s, a, s') \in r}
$$

Note that even when $r$ is deterministic, $\bar{r}$ can become non-deterministic. Generally, we'll use bars for relations that disregard input.

Relations can be composed:

> definition "Composition of relations"
> $$
> \bar{r_1} \circ \bar{r_2} = \set{(x, z) \mid \exists y.\ (x, y) \in \bar{r_1} \land (y, z) \in \bar{r_2}}
> $$

To understand what a composition means, intuitively, we'll introduce a visual metaphor. Imagine the nodes of the graph as airports, and the edges as possible routes. Let $\bar{r_1}$ be the routes operated by United Airlines, and $\bar{r_2}$ be the routes operated by Delta. Then $\bar{r_1} \circ \bar{r_2}$ is the set of routes possible by taking a United flight followed by a Delta flight.

> definition "Iteration"
> An iteration $\bar{r}^n$ describes paths of length $n$ in a relation $\bar{r}$. It is defined recursively by:
> 
> $$
> \begin{align}
> \bar{r}^0     & := \delta = \set{(x, x) \mid x \in S} \\ 
> \bar{r}^{n+1} & := \bar{r} \circ \bar{r}^n 
> \end{align}
> $$

Here, $\delta$ describes the *identity relation*, i.e. a relation composed solely of looping edges, for every node.

> definition "Transitive closure"
> The transitive closure $\bar{r}^*$ of a relation $\bar{r}$ is:
> 
> $$
> \bar{r}^* = \bigcup_{n \ge 0} \bar{r}^n
> $$

In our airport analogy, the transitive closure is the set of all airports reachable from our starting airports.

Finally, we'll introduce one more definition:

> definition "Image of a set"
> The image $\bar{r}[X]$ of a state set $X$ under a relation $\bar{r}$ is:
> 
> $$
> \bar{r}[X] := \set{y \mid \exists x \in X .\ (x, y) \in \bar{r}}
> $$

The image of a set $X$ is the set of states reachable in one step from $X$.

The above definitions lead us to a first definition of reach:

> theorem "Definition 1 of reach"
> $$
> \text{Reach}(M) = (\bar{r})^*[I]
> $$

### Post
We'll introduce another definition in order to give an alternative definition of reach. We're still considering a state system $M = (S, I, r, A)$.

> definition "Post"
> If $X \subseteq S$, define:
> 
> $$\text{post}(X) = \bar{r}[X]$$
> 
> We also define: 
> 
> $$
> \begin{align}
> \text{post}^0(X)     & := X \\
> \text{post}^{n+1}(X) & := \text{post}\left(\text{post}^n(X)\right)
> \end{align}
> $$

This definition of post leads us to another formulation of reach:

> theorem "Definition 2 of reach"
> $$
> \bigcup_{n \ge 0} \text{post}(I) = \text{Reach}(M)
> $$

The proof is done by moving terms around. TODO.

### Invariants
> definition "Invariant"
> An *invariant* $P \subset S$ of a system $M$ is any superset of the reachable states:
> 
> $$
> \text{Reach}(M) \subseteq P
> $$


> definition "Inductive Invariant"
> An *inductive invariant* $P \subset S$ is a set satisfying:
> 
> - $I \subset P$
> - $s \in P \land (s, a, s') \in r \implies s' \in P$

Intuitively, it means that you "can't escape" an inductive invariant. There can be ingoing edges to an inductive invariant, but no edges exiting the set.

Note that every inductive invariant is also an invariant. Indeed, for an inductive invariant $P$, if $I \subset P$ then we must also grow $P$ to include all states reachable from $I$ in order to satisfy the second property. Therefore, $\text{Reach}(M) \subseteq P$ and $P$ is an invariant.

> definition "Inductive strengthening"
> For an invariant $P$, $P_{\text{ind}}$ is an *inductive strengthening* of $I$ if:
> 
> - $P_{\text{ind}}$ is an inductive invariant
> - $P_{\text{ind}} \subseteq P$

In this case, we have:

$$
\text{Reach}(M) \subseteq P_{\text{ind}} \subseteq P
$$

