---
title: CS-550 Formal Verification
description: "My notes from the CS-550 Formal Verification course given at EPFL, in the 2019 autumn semester (MA3)"
edited: true
note: true
---

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
\newcommand{\seq}[1]{\left(#1\right)}
\newcommand{\eval}[1]{⟦#1⟧}
\newcommand{\vec}[1]{\mathbf{#1}}
\newcommand{\qed}[0]{\tag*{$\blacksquare$}}
\newcommand{\bigland}{\bigwedge} 
\newcommand{\biglor}{\bigvee} 
$$

Throughout these notes, vectors are denoted in bold and lowercase (e.g. $\vec{x}$).

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
> A *trace* is a finite or infinite sequence, describing steps taken by a transition system:
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
> $\text{Traces}(M)$ is the set of all traces of a transition system $M = (S, I, r, A)$, starting from $I$.

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
Let's study relations more closely. A relation is a *directed edge* in the transition graph. We follow this edge when we see a given input $a \in A$.

If we look at the graph, we may not be interested in the inputs associated to each edge. Therefore, we can construct the edge set $\bar{r}$:

$$
\bar{r} := \set{(s, s') \mid \exists a \in A .\ (s, a, s') \in r}
$$

Generally, we'll use a bar for relations that disregard input. Note that even when $r$ is deterministic, $\bar{r}$ can become non-deterministic.

Relations can be composed:

> definition "Composition of relations"
> $$
> \bar{r_1} \circ \bar{r_2} = \set{(x, z) \mid \exists y.\ (x, y) \in \bar{r_1} \land (y, z) \in \bar{r_2}}
> $$

Note that composition is not commutative, but is associative. 

To understand what a composition means, intuitively, we'll introduce a visual metaphor. Imagine the nodes of the graph as airports, and the edges as possible routes. Let $\bar{r_1}$ be the routes operated by United Airlines, and $\bar{r_2}$ be the routes operated by Delta. Then $\bar{r_1} \circ \bar{r_2}$ is the set of routes possible by taking a United flight followed by a Delta flight.

> definition "Iteration"
> An iteration $\bar{r}^n$ describes paths of length $n$ in a relation $\bar{r}$. It is defined recursively by:
> 
> $$
> \begin{align}
> \bar{r}^0     & := \Delta = \set{(x, x) \mid x \in S} \\ 
> \bar{r}^{n+1} & := \bar{r} \circ \bar{r}^n 
> \end{align}
> $$

Here, $\Delta$ describes the *identity relation*, i.e. a relation mapping every node to itself.

> definition "Transitive closure"
> The transitive closure $\bar{r}^*$ of a relation $\bar{r}$ is:
> 
> $$
> \bar{r}^* = \bigcup_{n \ge 0} \bar{r}^n
> $$

In our airport analogy, the transitive closure is the set of all airports reachable from our starting airports.

Finally, we'll introduce one more definition:

> definition "Image of a set"
> The image $\bar{r}[X]$ of a state set $X$ under a relation $\bar{r}$ is the set of states reachable in one step from $X$:
>  
> $$
> \bar{r}[X] := \set{y \mid \exists x \in X .\ (x, y) \in \bar{r}}
> $$
> 
> We also introduce an alternative notation:
> 
> $$
> X \bullet \bar{r} := \bar{r}[X]
> $$

The alternative notation may make it simpler to read images; $(X \bullet \bar{r_1}) \bullet \bar{r_2}$ can be read as "$X$ following $\bar{r_1}$ then following $\bar{r_2}$".

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
> \bigcup_{n \ge 0} \text{post}^n(I) = \text{Reach}(M)
> $$

The proof is done by expanding the post:

$$
\begin{align}
\bigcup_{n \ge 0} \text{post}^n(I)
\overset{(1)}{=} \bigcup_{n \ge 0} \bar{r}[\dots \bar{r}[I] \dots]
\overset{(2)}{=} \bigcup_{n \ge 0} \bar{r}^n[I]
\overset{(3)}{=} \left(\bigcup_{n \ge 0} \bar{r}^n\right)[I]
\overset{(4)}{=} \bar{r}^*[I]
\overset{(5)}{=} \text{Reach}(M)
\end{align}
$$

Where:

- Step (1) is by [the definition of $\text{post}$](#definition:post).
- Step (2) is by [the definition of iteration](#definition:iteration), and using the identity $\bar{r_1}[\bar{r_2}[X]] = (\bar{r_1}\circ\bar{r_2})[X]$[^proof-ex-1-2-1-1].
- Step (3) is done by moving terms around. We won't go into too many details, but it's easy to convince oneself of this step by thinking about what the terms mean intuitively: the union of states reachable in $1, 2, \dots, n$ steps is equal to the states reachable in the union of $1, 2, \dots, n$ steps.
- Step (4) is by [the definition of transitive closure](#definition:transitive-closure).
- Step (5) is by the [first definition of reach](#theorem:definition-1-of-reach).

[^proof-ex-1-2-1-1]: The proof of this identity is in exercise session 1, exercise 2.1.1. It is done by decomposing into existential quantifiers.

$\qed$

### Invariants
> definition "Invariant"
> An *invariant* $P \subseteq S$ of a system $M$ is any superset of the reachable states:
> 
> $$
> \text{Reach}(M) \subseteq P
> $$

A way to think of invariants is that all the reachable states must "satisfy the invariant", i.e. be included in $P$.

> definition "Inductive Invariant"
> An *inductive invariant* $P \subseteq S$ is a set satisfying:
> 
> - $I \subseteq P$
> - $s \in P \land (s, a, s') \in r \implies s' \in P$

Intuitively, the second condition means that you can't "escape" an inductive invariant by taking a step: there can be ingoing edges to an inductive invariant, but no edges exiting the set.

Note that every inductive invariant is also an invariant. Indeed, for an inductive invariant $P$, if $I \subseteq P$ then we must also grow $P$ to include all states reachable from $I$ in order to satisfy the second property. Therefore, $\text{Reach}(M) \subseteq P$ and $P$ is an invariant.

> definition "Inductive strengthening"
> For an invariant $P$, $P_{\text{ind}}$ is an *inductive strengthening* of $P$ if:
> 
> - $P_{\text{ind}}$ is an inductive invariant
> - $P_{\text{ind}} \subseteq P$

In this case, we have:

$$
\text{Reach}(M) \subseteq P_{\text{ind}} \subseteq P
$$

### Encoding and storage
#### Motivating example
Transition systems very quickly get out of hand. Suppose a snack dispenser has $4\times 6$ different items, and has 10 of each. It can take 500 coins. It then has:

$$
\abs{S} = 10^{4\cdot 6} \cdot 501 \cdot 2 > 10^{27}
$$

They might not all be reachable, but reachability is a separate question. Here, we're just defining the graph. In any case, this is too large to store explicitly. Therefore, we must find formulas and data structures to represent it more compactly.

#### Sequential circuit
We'll consider a deterministic finite-state transition system $M = (S, I, r, A)$. We will let $m, n \in \mathbb{N}$ be such that $2^n \ge \abs{S}$, and $2^m \ge \abs{A}$, or in other words, $n \ge \log_2\abs{S}$ and $m\ge \log_2\abs{A}$.

To encode the transition system in bits, we can think of it as 4-tuple of boolean functions:

- We can represent the states $S$ on $n$ bits: $S = \set{0, 1}^n$
- We can represent the alphabet $A$ on $m$ bits: $A = \set{0, 1}^m$
- We can represent the set of initial states $I \subseteq S$ by the boolean function  $\set{0, 1}^n \rightarrow \set{0, 1}$, which maps each state to a boolean ("initial" or "not initial").
- We can represent the transition relation $r \subseteq S\times A\times S$ as a function $(S \times A) \rightarrow S$, which is $\set{0, 1}^n \times \set{0, 1}^m \rightarrow \set{0, 1}^n$

We can think of these functions as a circuit receiving an input $\bar{a}\in\set{0, 1}^m$, which alters the state $\bar{s}\in\set{0, 1}^n$, which in turn alters the relation $r$.

![Example of a simple sequential circuit](/images/fv/sequential-circuit.png)

#### Formula encoding of boolean functions
Both the initial states $I$ and the transition relation $r$ are boolean functions. We will often define them mathematically (e.g. $r(s, a) = s \oplus a$ or $I(s) = (s = 0)$), but how do we encode them in bits?

We can use a truth table. For instance, the truth table encoding of $r$ is a table mapping inputs $s\in\set{0,1}^n$ and $a\in\set{0,1}^m$ to outputs $r(s, a)$. This is the most efficient encoding if we need to be able to encode *any* relation: there is no better general encoding. However, most functions can be stored more efficiently.

Let us consider the relation function $r \subseteq \set{0,1}^n\times\set{0,1}^m\times\set{0,1}^n$. We can consider an input-output pair as the following condition:

$$
\seq{
    \seq{s_1, \dots, s_n},
    \seq{a_1, \dots, a_m},
    \seq{s_1', \dots, s_n'}
} \in r
$$

We can write this as a propositional formula with variables $\seq{s_1, \dots, s_n, a_1, \dots, a_m, s_1', \dots, s_n'}$. This formula should be true exactly when the tuple belongs to $r$.

Let $v\in\set{0, 1}$, and let $p$ be a propositional variable. We can then define:

$$
p^v = \begin{cases}
p & \text{if } v = 1 \\
\neg p & \text{if } v = 0 \\
\end{cases}
$$

With this notation in hand, we can state the following:

> theorem "Formula encoding of boolean functions"
> We can always represent a transition relation $r$ as a propositional formula $F$ in disjunctive normal form, where:
> 
> $$
> F = 
> \biglor_{\seq{\seq{v_1, \dots, v_n}, \seq{u_1, \dots, u_m}, \seq{v_1', \dots, v_m'}} \in r} \left(
>   \bigland_{1\le i \le n} s_i^{v_i} \land
>   \bigland_{1\le i \le m} a_i^{u_i} \land
>   \bigland_{1\le i \le n} \seq{s'_i}^{v'_i}
> \right)
> $$

For many boolean functions ($\oplus$, $\land$, etc) this formulation will be quite small.

#### Auxiliary variables
This formula is a tree, where variables are leaves, and operations are internal nodes (much like an AST). Clearly, the variables are shared by many operations, so the more efficient representations exploit this sharing, and represent the tree as a directed acyclic graph (DAG) instead. 

Note that not only leaves of the tree are shared, but that bigger nodes can also be shared. This leads us to introduce the notion of *auxiliary variable* definitions. An auxiliary variable represents one such shared node. 

We can define auxiliary variables directly in the propositional logic by using the $=$ operator (which is alternative notation for $\leftrightarrow$). 

For instance, for a $n$-bit [ripple-carry adder](http://www.circuitstoday.com/ripple-carry-adder) can be encoded with:

- Initial state $s_1, \dots, s_n$
- Input numbers $a_1, \dots, a_n$
- Output $s_1', \dots, s_n'$

The formula for the adder with auxiliary variables $c_1, \dots, c_{n+1}$ (serving as the carry) is: 

$$
c_1 = 0 \land \bigland_{i=1}^n (s_i' = s_i \oplus a_i \oplus c_i) \land (c_{i+1} = (s_i \land a_i) \lor (s_i \land c_i) \lor (a_i \land c_i))
$$

The initial carry is $c_1 = 0$. Every individual adder gets 3 bits of input to add: two bits, and the previous carry. It outputs a carry of 1 iff two or more input bits are 1. It outputs a single bit as the result of the addition, which is the XOR of all inputs.

### Definitions and operations on formulas
To continue the discussion of encoding, we'll have to introduce some concepts related to formulas.

#### QBF
We've looked at boolean formulas, but let's now look at a small generalization, QBFs:

> definition "Quantified Boolean Formulas"
> *Quantified Boolean Formulas* (QBFs) is built from:
> 
> - Propositional variables
> - Constants $0$ and $1$
> - Operators $\land, \lor, \neg, \rightarrow, \leftrightarrow, \exists, \forall$

We will use $=$ as alternative notation for $\leftrightarrow$. A boolean formula is QBF without quantifiers ($\forall$ and $\exists$).

#### Free variables
> definition "Free variables"
> The free variables of a formula is the set of variables that are not bound by a quantifier:
>  
> $$
> \begin{align}
> FV(v) & = \set{v} \text{if } v \text{ is a propositional variable} \\
> FV(F_1 \land F_2) & = FV(F_1) \cup FV(F_2) \\
> FV(F_1 \lor F_2) & = FV(F_1) \cup FV(F_2) \\
> FV(F_1 \rightarrow F_2) & = FV(F_1) \cup FV(F_2) \\
> FV(\neg F_1 ) & = FV(F_1) \\
> FV(\exists v. F_1 ) & = FV(F_1)\setminus\set{v} \\
> FV(\forall v. F_1 ) & = FV(F_1)\setminus\set{v} \\
> \end{align}
> $$
 
#### Environment
> definition "Environment"
> An environment $e$ is a partial map from propositional variables to $\set{0, 1}$ ("false" or "true").
> 
> Consider two vectors $\vec{v} = \seq{v_1, \dots, v_n}$ and $\vec{p} = \seq{p_1, \dots, p_n}$ of $n$ propositional variables. We denote the environment as a mapping $[\vec{p}\mapsto\vec{v}]$ given by $e(p_i) = v_i$, $\forall 1 \le i \le n$

We denote the result of evaluating a boolean expression $F$ with the environment as $\eval{F}_e$. This can evaluate to $0$ ("false") or $1$ ("true").

$$
\begin{align}
\eval{x}_e & = e(x) \\
\eval{0}_e & = 0 \\
\eval{1}_e & = 1 \\
\eval{F_1 \land F_2}_e & = \eval{F_1}_e \land \eval{F_2}_e \\
\eval{F_1 \lor F_2}_e & = \eval{F_1}_e \lor \eval{F_2}_e \\
\end{align}
$$

While the formula $\eval{F_1 \land F_2}_e = \eval{F_1}_e \land \eval{F_2}_e$ might seem weird at first (we defined $\land$ in terms of another $\land$, it makes more sense if we think about the first $\land$ as an AST node and the second as a logical and in the host language:

{% highlight scala linenos %}
def eval(expr: Expr)(implicit env: Var => Boolean): Boolean = expr match {
    case x: Var => env(x)
    case Literal(0) => false
    case Literal(1) => true
    case And(a, b) => eval(a) && eval(b)
    case Or(a, b) => eval(a) || eval(b)
}
{% endhighlight %}

With this notation in hand, we can introduce the following shorthand:

> definition "Models"
> We write $e \models F$ to denote that $F$ is true in environment $e$, i.e. that $\eval{F}_e = 1$.

#### Substitution
> definition "Substitution"
> Let $F$ and $G$ be propositional formulas, and let $c$ be a variable. Let $F[c := G]$ denote the result of replacing each occurrence of $c$ in $F$ by $G$:
> 
> $$
> \begin{align}
> c[c := G] & = G \\
> (F_1 \land F_2)[c := G] & = F_1[c := G] \land F_2[c := G] \\
> (F_1 \lor F_2)[c := G] & = F_1[c := G] \lor F_2[c := G] \\
> (\neg F_1)[c := G] & = \neg(F_1[c := G])\\
> \end{align}
> $$

We'll also introduce a general notation to simultaneously replace many variables: $F[\vec{c} := \vec{G}]$ denotes the substitution of a vector $\vec{c}$ of variables with a vector of expressions $\vec{G}$.

#### Validity, Satisfiability and Equivalence
> definition "Satisfiability"
> A formula $F$ is *satisfiable* $\iff \exists e .\ e \models F$

Note that if $F$ is not satisfiable, it is *unsatisfiable*, which means $\forall e, \eval{F}_e = 0$.

> definition "Validity"
> A formula $F$ is *valid* $\iff \forall e .\ e \models F$

> theorem "Validity and unsatisfiability"
> $F$ is valid $\iff \neg F$ is unsatisfiable.

The proof should follow quite trivially from the definitions.

> definition "Equivalence"
> Formulas $F$ and $G$ are equivalent $\iff$ $\forall$ environment $e$ defined for all free variables in $FV(F)\cup FV(G)$, we have:
> 
> $$e \models F \iff e \models G$$

This means that two formulas are equivalent if and only if they always return the same values for the same environment (assuming it's defined for all their free variables).

> theorem "Equivalence and validity"
> $F$ and $G$ are equivalent $\iff$ the formula $F \leftrightarrow G$ is valid.

### Formula representation
#### Formula representation of sequential circuits
> definition "Sequential circuit"
> We represent a sequential circuit as a 5-tuple $C = (\vec{s}, \text{Init}, R, \vec{x}, \vec{a})$ where:
> 
> - $\vec{s} = \seq{s_1, \dots, s_n}$ is the vector of state variables
> - $\text{Init}$ is a boolean formula describing the initial state
> - $R$ is a boolean formula called the *transition formula*
> - $\vec{x} = \seq{x_1, \dots, x_k}$ is the vector of auxiliary variables
> - $\vec{a} = \seq{a_1, \dots, a_m}$ is the vector of input variables
> 
> The boolean formula $\text{Init}$ tells us which states we can start in, so it can only contain state variables:
> 
> $$
> FV(\text{Init}) \subseteq \set{s_1, \dots, s_n}
> $$
> 
> The transition formula $R$ can only contain state ($\vec{s}$), next-state ($\vec{s'}$), auxiliary ($\vec{x}$) or input ($\vec{a}$) variables:
> 
> $$
> FV(R) \subseteq \set{s_1, \dots, s_n, a_1, \dots, a_m, x_1, \dots, x_k, s'_1, \dots, s'_n}
> $$

The sequential circuit is a representation of a transition system $C = (S, I, r, A)$, where:

- $I = \set{\vec{v}\in\set{0,1}^n \mid [\vec{s} \mapsto \vec{v}] \models \text{Init}}$, meaning that the initial states of a transition system is given by an assignment of state variables that verifies the $\text{Init}$ formula
- $r = \set{(\vec{v}, \vec{u}, \vec{v'}) \in \set{0,1}^{m+n+m} \mid [(\vec{s}, \vec{a}, \vec{s}') \mapsto (\vec{v}, \vec{u}, \vec{v'})] \models \exists \vec{x}.\ R }$, meaning that the transition relation is given by a mapping of states $\vec{s}$ and inputs $\vec{a}$ to next-states $\vec{s'}$, such that the mapping satisfies the transition formula. Here, the auxiliary variables are existentially quantified so that we can express the criterion without them.

#### Inductive invariant checking
Given a sequential circuit representation $C = (\vec{s}, \text{Init}, R, \vec{x}, \vec{a})$ of a transition system $M = (S, I, r, A)$, and a formula $\text{Inv}$, how can we check that $\text{Inv}$ is an [inductive invariant](#definition:inductive-invariant)? According to the definition, we require:

- $I \subseteq \text{Inv}$
- $\text{Inv} \bullet r \subseteq \text{Inv}$

We'll ask the SAT solver to check if it's possible to break either of the two conditions by asking it if it can satisfy either of the following two formulas:

- $\text{Init} \land \neg \text{Inv}$ to check if there is an initial state not included in the invariant.
- $\text{Inv} \land R \land \neg\text{Inv}[\vec{s} := \vec{s'}]$ to check if, starting from the invariant and take a step, we can end up outside of the invariant.
  
  To understand this condition, it's useful to think of $\text{Inv}$ as determining the assignment of $\vec{s}$. Then, seeing that $S$ contains variables $\vec{s}, \vec{a}, \vec{x}$ and $\vec{s'}$, it will fix the assignment for the next states $\vec{s'}$. We can then see if the invariant is still true at the next state.

If the SAT solver returns `UNSAT` to both, we have proven that $\text{Inv}$ is an inductive invariant. Note that this resembles a proof by induction (because it is!).

#### Bounded model checking for reachability
How do we check whether a given state is reachable? Often, we're interested in knowing if we can reach an error state or not; being able to do so would be bad. To simplify the question a little, we can ask whether we can reach this error state in $j$ steps.

Let $E$ be the error formula corresponding to the error state, so $FV(E) \subseteq \set{s_1, \dots, s_n}$. When we talked about circuits, we said that the state and inputs change at each step, so let us denote the state at step $i$ as $\vec{s}^i$, and the inputs at step $i$ as $\vec{a}^i$. 

We'll construct an error formula $T_j$ that is satisfiable if and only if there exists a trace of length $j$ starting from the initial state that satisfies $E$:

$$
T_j \equiv 
    \text{Init}[\vec{s} := \vec{s}^0] \land 
    \left(\bigland_{i=0}^{j-1} R\left[
        \seq{\vec{s}, \vec{a}, \vec{x}, \vec{s'}} 
        := \seq{\vec{s}^i, \vec{a}^i, \vec{x}^i, \vec{s}^{i+1}}
    \right]\right) \land
    E[\vec{s} := \vec{s}^j]
$$

This formula starts at the initial state, then computes all states $\vec{s}^i$, and plugs in the final state $\vec{s}^j$ in the error formula to see if it can be satisfied.

If the SAT solver returns `UNSAT`, the error state is not reachable. If it returns `SAT`, the 

## Satisfiability checking
### Propositional boolean logic
Propositional logic is a language for representing Boolean functions $f: \set{0,1}^n \rightarrow {0, 1}$ as formulas. The grammar of this language is:

$$
P ::= x \mid
      0 \mid 1 \mid
      P \land P \mid P \lor P \mid
      P \oplus P \mid P \rightarrow P \mid P \leftrightarrow P
      \neg P
$$

Where $x$ denotes variable identifiers.

### SAT problem
The SAT problem is to determine whether a given formula $F$ is [satisfiable](#definition:satisfiability). The problem is NP-complete, but useful heuristics exist.

A SAT solver is a program that given a boolean formula $F$ either:

- Returns `SAT` and optionally an environment $e$ such that $e \models F$
- Returns `UNSAT` and optionally a proof that no satisfying assignment exists

### Formal proof system
Let's consider a set of logical formulas $\mathscr{F}$ (e.g. propositional logic).

> definition "Proof system"
> A *proof system* is a pair $(\mathscr{F}, \text{Infer})$ where $\text{Infer} \subseteq \mathscr{F}^* \times \mathscr{F}$ is a decidable set of inference steps, where:
> 
> - A set is *decidable* $\iff$ there is a program to check if an element belongs to it
> - Given a set $S$, $S^*$ denotes all finite sequences with elements from $S$

> definition "Inference step"
> An inference step $S$ is a 2-tuple $S=\seq{\seq{P_1, \dots, P_n}, C}\in\text{Infer}$, which we can denote as:
> 
> $$
> \frac{P_1 \dots P_n}{C}
> $$
> 
> We say that from the *premises* $P_1 \dots P_n$, we derive the *conclusion* $C$.

> definition "Axiom"
> We say that an inference step is called an *axiom* when $n = 0$, i.e. that it has no premises:
> 
> $$\frac{\qquad}{C}$$

> definition "Proof"
> Given a proof system $\seq{\mathscr{F}, \text{Infer}}$, a *proof* is a finite sequence of inference steps $S_0, \dots, S_m \in \text{Infer}$ such that, for every inference step $S_i$, each premise $P_j$ is a conclusion of a previous step.

### A minimal propositional logic proof system
We'll look into a simple logic called the [Hilbert system](https://en.wikipedia.org/wiki/Hilbert_system). We'll define the grammar of our logic as follows. This grammar defines a set of formulas $\mathscr{F}$.

$$
F ::= x \mid 0 \mid F \rightarrow F
$$

This may seem very minimal, but we can actually express many things by combining these. For instance, we can introduce negation ("for free") as a shorthand: 

$$
\neg F \equiv F \rightarrow 0
$$

The inference rules are $\text{Infer} = \set{P_2, P_3, MP}$, where:

$$
\begin{align}
P_2 & = 
    \frac{}{F \rightarrow (G \rightarrow F)} 
    \quad \forall F, G \in \mathscr{F} \\ \\

P_3 & = 
    \frac{}{(F \rightarrow (G \rightarrow H)) \rightarrow ((F \rightarrow G) \rightarrow (F \rightarrow H))} 
    \quad \forall F, G, H \in \mathscr{F} \\ \\

MP & =
    \frac{F \rightarrow G, \qquad F}{G} 
    \quad \forall F, G \in \mathscr{F} \\
\end{align}
$$

The first two rules are axioms, telling us that an implication is true if the right-hand side is true ($P_2$), and that implication is distributive ($P_3$). We might recognize [modus ponens](https://en.wikipedia.org/wiki/Modus_ponens) in the last rule.

We can use these rules to construct a proof of $a \rightarrow a$. We'll draw this proof as a DAG: we can always view a proof as a DAG because of the requirement that the premises of an inference step be a conclusion of a previous step.

{% graphviz %}
digraph G {
    graph [bgcolor="transparent"]
    A [label="(a→((a→a)→a) → ((a → (a→a))→(a→a)"]
    B [label="(a((a→a)→a)"]
    C [label="(a→(a→a))→(a→a)",xlabel="Modus Ponens"]
    D [label="(a→(a→a))"]
    E [label="a→a",xlabel="Modus Ponens"]
    A -> C
    B -> C
    C -> E
    D -> E
} 
{% endgraphviz %}

### Provability
TODO assumptions

> definition "Provable"
> We say that "a formula $F \in \mathscr{F}$ is *provable* from a set of assumptions $A$", denoted $A \vdash_{\text{Infer}} F$, $\iff$ there exists a derivation from $A$ in $\text{Infer}$ that contains an inference step whose conclusion is $F$.
> 
> We write $\emptyset \vdash_{\text{Infer}} F$ (or simply $\vdash_{\text{Infer}} F$) to denote that there exists a proof in $\text{Infer}$ containing $F$ as a conclusion.

### Consequence and soundness in propositional logic
> definition "Soundness"
> A step $((P_1, \dots, P_n), C) \in \text{Infer}$ is sound $\iff \set{P_1, \dots, P_n} \models C$
> 
> A proof system is sound if every inference step is sound.

> theorem ""
> Let $(\mathscr{F}, \text{Infer})$ where $\mathscr{F}$ are propositional logic formulas. If every inference rule in $\text{Infer}$ is sound, then $A \vdash_{\text{Infer}} F$ implies $A \models F$.

The proof is immediate by induction on the length of the formal proof. As a consequence $\vdash_{\text{Infer}} F$ implies that $F$ is a tautology (always true? Todo).

Todo

### Proving unsatisfiability
> theorem "Refutation soundness"
> If $A \vdash_{\text{Infer}_D} 0$ then $A$ is *unsatisfiable*

This follows from the soundness of $\vdash_{\text{Infer}_D}$.

> theorem "Refutation completeness"
> If a finite set $A$ is unsatisfiable, then $A \vdash_{\text{Infer}_D} 0$

For the proof, we can take the conjunction of formulas in $A$ and existentially quantify it to get $A'$ (i.e. $\exists x. A$)