---
title: CS-550 Formal Verification
description: "My notes from the CS-550 Formal Verification course given at EPFL, in the 2019 autumn semester (MA3)"
date: 2019-09-20
course: CS-550
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
\newcommand{\post}{\text{post}}
\newcommand{\postapprox}{\post^{\text{#}}}
\newcommand{\triple}[3]{\set{#1}\ #2 \ \set{#3}}
\newcommand{\wp}[1]{\text{wp}\!\left(#1\right)}
\newcommand{\sp}[1]{\text{sp}\!\left(#1\right)}
\newcommand{\ar}{\text{ar}}
\newcommand{\divides}{\mid}
$$

Throughout these notes, vectors are denoted in bold and lowercase (e.g. $\vec{x}$). Booleans are denoted interchangeably by $\text{true}$ and $\text{false}$, or $\top$ and $\bot$. Generally, I try to use $\rightarrow$ and $\leftrightarrow$ for formulas, and $\implies$ and $\iff$ for mathematical notation[^equivalent-notation].

[^equivalent-notation]: These are of course equivalent, but it sometimes helps to be able to distinguish whether an operator is written in the context of a formula or in the context of a mathematical statement.

<!-- More --> 

* TOC
{:toc}

## Transition systems

### Definition
We'll start by introducing transition systems, a generalization of DFAs. They may be not finite, and not deterministic.

{% block definition "Transition system" %}
A transition system is a 4-tuple $M = (S, I, r, A)$ where:

- $S$ is the set of states
- $I \subseteq S$ is the set of starting states
- $r \subseteq S \times A \times S$ is the transition relation
- $A$ is the alphabet

For $s, s' \in S$ and $a \in A$, $(s, a, s') \in r$ means that ther is a transition from $s$ to $s'$ on input $a$.
{% endblock %}

A few special cases of this general form exist:

- If $S$ is finite, we have a *finite state machine*
- If $r: S\times A \rightarrow S$ and $\abs{I} = 1$, then the system is *deterministic*.

### Traces and reachability

{% block definition "Trace" %}
A *trace* is a finite or infinite sequence, describing steps taken by a transition system:

$$
(s_0, a_0, s_1, a_1, s_2, \dots)
$$

where we require, $\forall i$:

- $s_0 \in I$
- $s_i \in S$
- $a_i\in A$
- $(s_i, a_i, s_{i+1})\in r$
{% endblock %}

A trace may or may not be finite. If they are finite, we can assume that the trace ends with a state $s_n$. We'll introduce some notation for traces:

{% block definition "Trace of a transition system" %}
$\text{Traces}(M)$ is the set of all traces of a transition system $M = (S, I, r, A)$, starting from $I$.
{% endblock %}

{% block definition "Reachable states of a transition system" %}
The reachable states are states for which there exists a trace that ends in $s_n$:

$$
\text{Reach}(M) = \set{s_n \mid 
  \exists n .\ \exists (s_0, a_0, s_1, a_1, \dots, s_n) \in \text{Traces}(M)
}
$$
{% endblock %}

To check for reachability, for a finite $S$, we can simply run DFS.

### Relations
Let's study relations more closely. A relation is a *directed edge* in the transition graph. We follow this edge when we see a given input $a \in A$.

If we look at the graph, we may not be interested in the inputs associated to each edge. Therefore, we can construct the edge set $\bar{r}$:

$$
\bar{r} := \set{(s, s') \mid \exists a \in A .\ (s, a, s') \in r}
$$

Generally, we'll use a bar for relations that disregard input. Note that even when $r$ is deterministic, $\bar{r}$ can become non-deterministic.

#### Composition
Relations can be composed:

{% block definition "Composition of relations" %}
$$
\bar{r_1} \circ \bar{r_2} = \set{(x, z) \mid \exists y.\ (x, y) \in \bar{r_1} \land (y, z) \in \bar{r_2}}
$$
{% endblock %}

Note that composition is not commutative, but is associative. 

To understand what a composition means, intuitively, we'll introduce a visual metaphor. Imagine the nodes of the graph as airports, and the edges as possible routes. Let $\bar{r_1}$ be the routes operated by United Airlines, and $\bar{r_2}$ be the routes operated by Delta. Then $\bar{r_1} \circ \bar{r_2}$ is the set of routes possible by taking a United flight followed by a Delta flight.

#### Iteration
{% block definition "Iteration" %}
An iteration $\bar{r}^n$ describes paths of length $n$ in a relation $\bar{r}$. It is defined recursively by:

$$
\begin{align}
\bar{r}^0     & := \Delta \\ 
\bar{r}^{n+1} & := \bar{r} \circ \bar{r}^n 
\end{align}
$$
{% endblock %}

#### Identity
In the above, $\Delta$ describes the *identity relation*, i.e. a relation mapping every node to itself. We'll see a small generalization below, which will be useful for the rest of the course:

{% block definition "Identity relation" %}
The *identity relation* $\Delta$ (also called "diagonal relation" or "triangular relation") is the relation mapping every item in the universe $S$ to itself:

$$\Delta = \set{(x, x) \mid x \in S}$$

This relation can be conditioned, so as to only include elements in a set $A$ (or satisfying a condition $A$):

$$\Delta_A = \set{(x, x) \mid x \in A}$$
{% endblock %}

#### Transitive closure
Applying [iteration](#iteration) an arbitrary number of times leads us to the transitive closure:

{% block definition "Transitive closure" %}
The transitive closure $\bar{r}^*$ of a relation $\bar{r}$ is:

$$
\bar{r}^* = \bigcup_{n \ge 0} \bar{r}^n
$$
{% endblock %}

In our airport analogy, the transitive closure is the set of all airports reachable from our starting airports.

A few properties of transitive closure follow from the definition:

- **Reflexivity**: $\Delta \subseteq r^*$, so every item is mapped back onto itself (among others, potentially)
- **Transitivity**: $(a, b) \in r^* \land (b, c) \in r^* \implies (a, c) \in r^*$
- **Distributivity (under certain conditions)**: if $s$ is reflexive and transitive and $r \subseteq s$, then $r^* \subseteq s$
- **Monotonicity**: $r_1 \subseteq r_2 \implies r_1^* \subseteq r_2^*$

A few bonus facts:

- $r^*$ is the smallest reflexive transitive relation containing $r$.
- $\left(r^{-1}\right)^* = (r^*)^{-1}$
- $r^* = \Delta \cup (r \circ r^*)$
- $r^* = \Delta \cup (r^* \circ r)$
- An edge is in the transitive closure if and only if there is a path in the graph $r$. In mathematical notation, this is:
  
  $$(x_0, x_n)\in r^* \iff \exists n \ge 0.\ \exists x_1, \dots, x_{n-1}.\ \forall i\in\set{0, \dots, n-1}.\ (x_i, x_{i+1}) \in r$$

#### Image
Finally, we'll introduce one more definition:

{% block definition "Image of a set" %}
The image $\bar{r}[X]$ of a state set $X$ under a relation $\bar{r}$ is the set of states reachable in one step from $X$:
 
$$\bar{r}[X] := \set{y \mid \exists x \in X .\ (x, y) \in \bar{r}}$$

We also introduce an alternative notation:

$$X \bullet \bar{r} := \bar{r}[X]$$
{% endblock %}

The alternative notation may make it simpler to read images; $(X \bullet \bar{r_1}) \bullet \bar{r_2}$ can be read as "$X$ following $\bar{r_1}$ then following $\bar{r_2}$".

### Reach
The above definitions lead us to a first definition of reach:

{% block theorem "Definition 1 of reach" %}
$$\text{Reach}(M) = (\bar{r})^*[I]$$
{% endblock %}

### Post
We'll introduce another definition in order to give an alternative definition of reach. We're still considering a state system $M = (S, I, r, A)$.

{% block definition "Post" %}
If $X \subseteq S$, define:

$$\post(X) = \bar{r}[X]$$

We also define: 

$$
\begin{align}
\post^0(X)     & := X \\
\post^{n+1}(X) & := \post\left(\post^n(X)\right)
\end{align}
$$
{% endblock %}

This definition of post leads us to another formulation of reach:

{% block theorem "Definition 2 of reach" %}
$$\bigcup_{n \ge 0} \post^n(I) = \text{Reach}(M)$$
{% endblock %}

The proof is done by expanding the post:

$$
\begin{align}
\bigcup_{n \ge 0} \post^n(I)
\overset{(1)}{=} \bigcup_{n \ge 0} \bar{r}[\dots \bar{r}[I] \dots]
\overset{(2)}{=} \bigcup_{n \ge 0} \bar{r}^n[I]
\overset{(3)}{=} \left(\bigcup_{n \ge 0} \bar{r}^n\right)[I]
\overset{(4)}{=} \bar{r}^*[I]
\overset{(5)}{=} \text{Reach}(M)
\end{align}
$$

Where:

- Step (1) is by [the definition of $\post$](#definition:post).
- Step (2) is by [the definition of iteration](#definition:iteration), and using the identity $\bar{r_1}[\bar{r_2}[X]] = (\bar{r_1}\circ\bar{r_2})[X]$[^proof-ex-1-2-1-1].
- Step (3) is done by moving terms around. We won't go into too many details, but it's easy to convince oneself of this step by thinking about what the terms mean intuitively: the union of states reachable in $1, 2, \dots, n$ steps is equal to the states reachable in the union of $1, 2, \dots, n$ steps.
- Step (4) is by [the definition of transitive closure](#definition:transitive-closure).
- Step (5) is by the [first definition of reach](#theorem:definition-1-of-reach).

[^proof-ex-1-2-1-1]: The proof of this identity is in exercise session 1, exercise 2.1.1. It is done by decomposing into existential quantifiers.

$\qed$

### Invariants
{% block definition "Invariant" %}
An *invariant* $P \subseteq S$ of a system $M$ is any superset of the reachable states:

$$\text{Reach}(M) \subseteq P$$
{% endblock %}

A way to think of invariants is that all the reachable states must "satisfy the invariant", i.e. be included in $P$.

{% block definition "Inductive Invariant" %}
An *inductive invariant* $P \subseteq S$ is a set satisfying:

- $I \subseteq P$
- $s \in P \land (s, a, s') \in r \implies s' \in P$
{% endblock %}

Intuitively, the second condition means that you can't "escape" an inductive invariant by taking a step: there can be ingoing edges to an inductive invariant, but no edges exiting the set.

Note that every inductive invariant is also an invariant. Indeed, for an inductive invariant $P$, if $I \subseteq P$ then we must also grow $P$ to include all states reachable from $I$ in order to satisfy the second property. Therefore, $\text{Reach}(M) \subseteq P$ and $P$ is an invariant.

{% block definition "Inductive strengthening" %}
For an invariant $P$, $P_{\text{ind}}$ is an *inductive strengthening* of $P$ if:

- $P_{\text{ind}}$ is an inductive invariant
- $P_{\text{ind}} \subseteq P$
{% endblock %}

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

{% block theorem "Formula encoding of boolean functions" %}
We can always represent a transition relation $r$ as a propositional formula $F$ in disjunctive normal form, where:

$$
F = 
\biglor_{\seq{\seq{v_1, \dots, v_n}, \seq{u_1, \dots, u_m}, \seq{v_1', \dots, v_m'}} \in r} \left(
  \bigland_{1\le i \le n} s_i^{v_i} \land
  \bigland_{1\le i \le m} a_i^{u_i} \land
  \bigland_{1\le i \le n} \seq{s'_i}^{v'_i}
\right)
$$
{% endblock %}

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

## Propositional logic
### Definition
Propositional logic is a language for representing Boolean functions $f: \set{0,1}^n \rightarrow {0, 1}$ as formulas. The grammar of this language is:

$$
P ::= x \mid
      0 \mid 1 \mid
      P \land P \mid P \lor P \mid
      P \oplus P \mid P \rightarrow P \mid P \leftrightarrow P
      \neg P
$$

Where $x$ denotes variable identifiers.

### QBF
Having looked at boolean formulas let's now look at a small generalization, QBFs:

{% block definition "Quantified Boolean Formulas" %}
*Quantified Boolean Formulas* (QBFs) is built from:

- Propositional variables
- Constants $0$ and $1$
- Operators $\land, \lor, \neg, \rightarrow, \leftrightarrow, \exists, \forall$
{% endblock %}

We will use $=$ as alternative notation for $\leftrightarrow$. A boolean formula is QBF without quantifiers ($\forall$ and $\exists$).

### Free variables
{% block definition "Free variables" %}
The free variables of a formula is the set of variables that are not bound by a quantifier:
 
$$
\begin{align}
FV(v) & = \set{v} \text{if } v \text{ is a propositional variable} \\
FV(F_1 \land F_2) & = FV(F_1) \cup FV(F_2) \\
FV(F_1 \lor F_2) & = FV(F_1) \cup FV(F_2) \\
FV(F_1 \rightarrow F_2) & = FV(F_1) \cup FV(F_2) \\
FV(\neg F_1 ) & = FV(F_1) \\
FV(\exists v. F_1 ) & = FV(F_1)\setminus\set{v} \\
FV(\forall v. F_1 ) & = FV(F_1)\setminus\set{v} \\
\end{align}
$$
{% endblock %}
 
### Environment
{% block definition "Environment" %}
An environment $e$ is a partial map from propositional variables to $\set{0, 1}$ ("false" or "true").

Consider two vectors $\vec{v} = \seq{v_1, \dots, v_n}$ and $\vec{p} = \seq{p_1, \dots, p_n}$ of $n$ propositional variables. We denote the environment as a mapping $[\vec{p}\mapsto\vec{v}]$ given by $e(p_i) = v_i$, $\forall 1 \le i \le n$
{% endblock %}

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

{% block definition "Models" %}
We write $e \models F$ to denote that $F$ is true in environment $e$, i.e. that $\eval{F}_e = 1$.
{% endblock %}

### Substitution
{% block definition "Substitution" %}
Let $F$ and $G$ be propositional formulas, and let $c$ be a variable. Let $F[c := G]$ denote the result of replacing each occurrence of $c$ in $F$ by $G$:

$$
\begin{align}
c[c := G] & = G \\
(F_1 \land F_2)[c := G] & = F_1[c := G] \land F_2[c := G] \\
(F_1 \lor F_2)[c := G] & = F_1[c := G] \lor F_2[c := G] \\
(\neg F_1)[c := G] & = \neg(F_1[c := G])\\
\end{align}
$$
{% endblock %}

We'll also introduce a general notation to simultaneously replace many variables: $F[\vec{c} := \vec{G}]$ denotes the substitution of a vector $\vec{c}$ of variables with a vector of expressions $\vec{G}$.

### Validity, Satisfiability and Equivalence
{% block definition "Satisfiability" %}
A formula $F$ is *satisfiable* $\iff \exists e .\ e \models F$
{% endblock %}

Note that if $F$ is not satisfiable, it is *unsatisfiable*, which means $\forall e, \eval{F}_e = 0$.

{% block definition "Validity" %}
A formula $F$ is *valid* $\iff \forall e .\ e \models F$
{% endblock %}

{% block theorem "Validity and unsatisfiability" %}
$F$ is valid $\iff \neg F$ is unsatisfiable.
{% endblock %}

The proof should follow quite trivially from the definitions.

{% block definition "Equivalence" %}
Formulas $F$ and $G$ are equivalent $\iff$ $\forall$ environment $e$ defined for all free variables in $FV(F)\cup FV(G)$, we have:

$$e \models F \iff e \models G$$
{% endblock %}

This means that two formulas are equivalent if and only if they always return the same values for the same environment (assuming it's defined for all their free variables).

{% block theorem "Equivalence and validity" %}
$F$ and $G$ are equivalent $\iff$ the formula $F \leftrightarrow G$ is valid.
{% endblock %}

## Bounded model checking
### Formula representation of sequential circuits
{% block definition "Sequential circuit" %}
We represent a sequential circuit as a 5-tuple $C = (\vec{s}, \text{Init}, R, \vec{x}, \vec{a})$ where:

- $\vec{s} = \seq{s_1, \dots, s_n}$ is the vector of state variables
- $\text{Init}$ is a boolean formula describing the initial state
- $R$ is a boolean formula called the *transition formula*
- $\vec{x} = \seq{x_1, \dots, x_k}$ is the vector of auxiliary variables
- $\vec{a} = \seq{a_1, \dots, a_m}$ is the vector of input variables

The boolean formula $\text{Init}$ tells us which states we can start in, so it can only contain state variables:

$$
FV(\text{Init}) \subseteq \set{s_1, \dots, s_n}
$$

The transition formula $R$ can only contain state ($\vec{s}$), next-state ($\vec{s'}$), auxiliary ($\vec{x}$) or input ($\vec{a}$) variables:

$$
FV(R) \subseteq \set{s_1, \dots, s_n, a_1, \dots, a_m, x_1, \dots, x_k, s'_1, \dots, s'_n}
$$
{% endblock %}

The sequential circuit is a representation of a transition system $C = (S, I, r, A)$, where:

- $I = \set{\vec{v}\in\set{0,1}^n \mid [\vec{s} \mapsto \vec{v}] \models \text{Init}}$, meaning that the initial states of a transition system is given by an assignment of state variables that verifies the $\text{Init}$ formula
- $r = \set{(\vec{v}, \vec{u}, \vec{v'}) \in \set{0,1}^{m+n+m} \mid [(\vec{s}, \vec{a}, \vec{s}') \mapsto (\vec{v}, \vec{u}, \vec{v'})] \models \exists \vec{x}.\ R }$, meaning that the transition relation is given by a mapping of states $\vec{s}$ and inputs $\vec{a}$ to next-states $\vec{s'}$, such that the mapping satisfies the transition formula. Here, the auxiliary variables are existentially quantified so that we can express the criterion without them.

### Inductive invariant checking
Given a sequential circuit representation $C = (\vec{s}, \text{Init}, R, \vec{x}, \vec{a})$ of a transition system $M = (S, I, r, A)$, and a formula $\text{Inv}$, how can we check that $\text{Inv}$ is an [inductive invariant](#definition:inductive-invariant)? According to the definition, we require:

- $I \subseteq \text{Inv}$
- $\text{Inv} \bullet r \subseteq \text{Inv}$

We'll ask the SAT solver to check if it's possible to break either of the two conditions by asking it if it can satisfy either of the following two formulas:

- $\text{Init} \land \neg \text{Inv}$ to check if there is an initial state not included in the invariant.
- $\text{Inv} \land R \land \neg\text{Inv}[\vec{s} := \vec{s'}]$ to check if, starting from the invariant and take a step, we can end up outside of the invariant.
  
  To understand this condition, it's useful to think of $\text{Inv}$ as determining the assignment of $\vec{s}$. Then, seeing that $S$ contains variables $\vec{s}, \vec{a}, \vec{x}$ and $\vec{s'}$, it will fix the assignment for the next states $\vec{s'}$. We can then see if the invariant is still true at the next state.

If the SAT solver returns `UNSAT` to both, we have proven that $\text{Inv}$ is an inductive invariant. Note that this resembles a proof by induction (because it is!).

### Bounded model checking for reachability
How do we check whether a given state is reachable? Often, we're interested in knowing if we can reach an error state or not; being able to do so would be bad. To simplify the question a little, we can ask whether we can reach this error state in $j$ steps.

Let $E$ be the error formula corresponding to the error state, so $FV(E) \subseteq \set{s_1, \dots, s_n}$. When we talked about circuits, we said that the state and inputs change at each step, so let us denote the state at step $i$ as $\vec{s}^i$, and the inputs at step $i$ as $\vec{a}^i$. 

We'll construct an error formula $T_j$ that is satisfiable if and only if there exists a trace of length $j$ starting from the initial state $\text{Init}$ that satisfies $E$:

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
### SAT problem
The SAT problem is to determine whether a given formula $F$ is [satisfiable](#definition:satisfiability). The problem is NP-complete, but useful heuristics exist.

A SAT solver is a program that given a boolean formula $F$ either:

- Returns `SAT` and optionally an environment $e$ such that $e \models F$
- Returns `UNSAT` and optionally a proof that no satisfying assignment exists

### Formal proof system
Let's consider a set of logical formulas $\mathscr{F}$ (e.g. propositional logic).

{% block definition "Proof system" %}
A *proof system* is a pair $(\mathscr{F}, \text{Infer})$ where $\text{Infer} \subseteq \mathscr{F}^* \times \mathscr{F}$ is a decidable set of inference steps, where:

- A set is *decidable* $\iff$ there is a program to check if an element belongs to it
- Given a set $S$, $S^*$ denotes all finite sequences with elements from $S$
{% endblock %}

{% block definition "Inference step" %}
An inference step $S$ is a 2-tuple $S=\seq{\seq{P_1, \dots, P_n}, C}\in\text{Infer}$, which we can denote as:

$$
\frac{P_1 \dots P_n}{C}
$$

We say that from the *premises* $P_1 \dots P_n$, we derive the *conclusion* $C$.
{% endblock %}

{% block definition "Axiom" %}
We say that an inference step is called an *axiom* when $n = 0$, i.e. that it has no premises:

$$\frac{\qquad}{C}$$
{% endblock %}

{% block definition "Proof" %}
Given a proof system $\seq{\mathscr{F}, \text{Infer}}$, a *proof* is a finite sequence of inference steps $S_0, \dots, S_m \in \text{Infer}$ such that, for every inference step $S_i$, each premise $P_j$ is a conclusion of a previous step.
{% endblock %}

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
A formula is provable if we can derive it from a set of initial assumptions. We'll start by formally defining what an assumption even is:

{% block definition "Assumptions" %}
Given $\seq{\mathscr{F}, \text{Infer}}$ where $\text{Infer} \subseteq \mathscr{F}^* \times \mathscr{F}$, and given a set of *assumptions* $A \subseteq \mathscr{F}$, a derivation from $A$ in $\seq{\mathscr{F}, \text{Infer}}$ is a proof in $\seq{\mathscr{F}, \text{Infer}'}$ where:

$$ \text{Infer}' = \text{Infer} \cup \set{\frac{\quad}{F} \mid F \in A} $$
{% endblock %}

In other words, assumptions from $A$ are just treated as axioms (i.e. they are rules that have no prerequisites, hence $\seq{(), F}$). A derivation is a proof that starts from assumptions.

{% block definition "Provable" %}
We say that "a formula $F \in \mathscr{F}$ is *provable* from a set of assumptions $A$", denoted $A \vdash_{\text{Infer}} F$, $\iff$ there exists a derivation from $A$ in $\text{Infer}$ that contains an inference step whose conclusion is $F$.

We write $\emptyset \vdash_{\text{Infer}} F$ (or simply $\vdash_{\text{Infer}} F$) to denote that there exists a proof in $\text{Infer}$ containing $F$ as a conclusion.
{% endblock %}

### Consequence and soundness in propositional logic
{% block definition "Semantic consequence" %}
Given a set of assumptions $A \subseteq \mathscr{F}$, where $\mathscr{F}$ is in propositional logic, and given $C \in \mathscr{F}$, we say that $C$ is a *semantic consequence* of $A$, denoted $A \models C$, $\iff$ for every environment $e$ that defines all variables in $\text{FV}(C) \cup \bigcup_{P \in A} \text{FV}(P)$, we have:

$$ \eval{P}_e = 1 \quad \forall P \in A \implies \eval{C}_e = 1 $$
{% endblock %}

In other words, iff an environment makes all assumptions true, and $C$ is true in an environment $e$ when the set of assumptions $A$ are all true in that environment, then we call $C$ a semantic consequence.

{% block definition "Soundness" %}
A step $((P_1, \dots, P_n), C) \in \text{Infer}$ is sound $\iff \set{P_1, \dots, P_n} \models C$

A proof system $\text{Infer}$ is sound if every inference step is sound.
{% endblock %}

In other words, a conclusion of step is sound if it is a semantic consequence of the previous steps. A proof is sound if all steps are sound.

If $C$ is an axiom (which has no precondition, meaning that $n = 0$ in the above), this definition of soundness means that $C$ is always a valid formula. We call this a **tautology**.

{% block theorem "Semantic consequence and provability in sound proof systems" %}
Let $(\mathscr{F}, \text{Infer})$ where $\mathscr{F}$ are propositional logic formulas. If every inference rule in $\text{Infer}$ is sound, then $A \vdash_{\text{Infer}} F$ implies $A \models F$.
{% endblock %}

This theorem tells us that that if all the inference rules are sound, then $F$ is a semantic consequence of $A$ if $F$ is provable from $A$. This may sound somewhat straightforward (if everything is sound, then it seems natural that the semantic consequence follows from provability), but is a nice way to restate the previous definitions.

The proof is immediate by induction on the length of the formal proof. As a consequence $\emptyset \vdash_{\text{Infer}} F$ implies that $F$ is a tautology.

### Proving unsatisfiability
Let's take a look at two propositional formulas $F$ and $G$. These are semantically equivalent if $F \models G$ and $G \models F$. 

We can prove equivalence by repeatedly applying the following "case analysis" rule, which replaces a given variable $x$ by 0 in $F$ and by 1 in $G$:

{% block definition "Case analysis rule" %}
$$\frac{F \qquad G}{F[x := 0] \lor G[x := 1]}$$
{% endblock %}

This is [sound](#definition:soundness), because if we consider an environment $e$ defining $x \in \text{FV}(F) \cup \text{FV}(G)$, and assume $\eval{F}_e = 1$ and $\eval{G}_e = 1$, then:

- if $e(x) = 0$ then $\eval{F[x := 0]}_e = \eval{F}_e = 1$
- if $e(x) = 1$ then $\eval{G[x := 1]}_e = \eval{G}_e = 1$

In either case $F[x := 0] \lor G[x := 1]$ remains true when $F$ and $G$ are sound.

Strictly speaking, the above rule may not be quite enough, so we'll also introduce a few simplification rules that preserve the equivalence:

$$\begin{align}
0 \land F & \rightsquigarrow 0 \\
1 \land F & \rightsquigarrow F \\
0 \lor F & \rightsquigarrow F \\
1 \lor F & \rightsquigarrow F \\
\neg 0 & \rightsquigarrow 1 \\
\neg 1 & \rightsquigarrow 0 \\
\end{align}$$

Those rules together form the sound system $\text{Infer}_D$, where:

$$\text{Infer}_D = \set{\frac{F}{F'} \mid F' \text{ is simplified from } F}$$

Remember that a set $A$ of formulas is [satisfiable](#definition:satisfiability) if there exists an environment $e$ such that for every formula $F \in A$, $\eval{F}_e = 1$. We can use $\text{Infer}_D$ to conclude unsatisfiability:

{% block theorem "Refutation soundness" %}
If $A \vdash_{\text{Infer}_D} 0$ then $A$ is *unsatisfiable*
{% endblock %}

Here, $0$ means false. This follows from the soundness of $\vdash_{\text{Infer}_D}$. More interestingly, the converse is also true.

{% block theorem "Refutation completeness" %}
If a finite set $A$ is unsatisfiable, then $A \vdash_{\text{Infer}_D} 0$
{% endblock %}

This means that $A$ unsatisfiable $\iff A \vdash_{\text{Infer}_D} 0$. 

For the proof, we can take the conjunction of formulas in $A$ and existentially quantify it to get $A'$ (i.e. $\exists x. A$)

### Conjunctive Normal Form (CNF)

*[CNF]: Conjunctive Normal Form

To define conjunctive normal form, we need to define the three levels of the formula:

- CNF is the conjunction of clauses
- A clause is a disjunction of literals
- A literal is either a variable $x$ or its negation $\neg x$

This is a nice form to work with, because we have the following property: if $C$ is a clause then $\eval{C}_e = 1 \iff$ there exists a literal $x_i \in C$ such that $\eval{x_i}_e = 1$.

We can represent formulas in CNF as a set of sets. For instance:

$$
A = a \land b \land (\neg a \lor \neg b) 
\equiv \set{\set{a}, \set{b}, \set{\neg a, \neg b}}
$$

The false value can be represented as the empty clause $\emptyset$. Note that seeing an empty clause in CNF means that the whole formula is unsatisfiable.

### Clausal resolution
{% block definition "Clausal resolution rule" %}
Let $C_1$ and $C_2$ be two clauses.

$$\frac{C_1 \cup \set{x} \quad C_2 \cup \set{\neg x}}{C_1 \cup C_2}$$
{% endblock %}

This rule resolves two clauses with respect to $x$. It says that if clause $C_1$ contains $x$, and clause $C_2$ contains $\neg x$, then we can remove the variable from the clauses and merge them.

{% block theorem "Soundness of the clausal resolution rule" %}
Clausal resolution is [sound](#definition:soundness) for all clauses $C_1, C_2$ and propositional variables $x$.
{% endblock %}

This tells us that clausal resolution is a valid rule. A stronger result is that we can use clausal resolution to determine satisfiability for any CNF formula:

{% block theorem "Refutational completeness of the clausal resolution rule" %}
A finite set of clauses $A$ is satisfiable $\iff$ there exists a derivation to the empty clause from $A$ using clausal resolution.
{% endblock %}

### Unit resolution
A *unit* clause is a clause that has precisely one literal: it's of the form $\set{L}$ where $L$ is a literal. Note that the literal in a unit clause must be true.

Given a literal $L$ we define the dual $\bar{L}$ as $\bar{\neg x} = x$ and $\bar{x} = \neg x$.

Unit resolution is a special case of resolution where at least one of the clauses is a unit clause. 

{% block definition "Unit resolution" %}
Let $C$ be a clause, and let $L$ be a literal.

$$\frac{C \qquad \set{L}}{C \setminus \set{\bar{L}}}$$
{% endblock %}

This is sound (if $L$ is true then $\bar{L}$ is false and can thus be removed from another clause $C$). When applying this rule we get a clause $C' \subseteq C$: this gives us progress towards $\emptyset$, which is good.

### Equivalence and equisatisfiability
Let's recall that two formulas $F_1$ and $F_2$ are satisfiable iff $F_1 \models F_2$ and $F_2 \models F_1$. TODO is this a typo? Should it be "equivalent"?

{% block definition "Equisatisfiability" %}
Two formulas $F_1$ and $F_2$ are *equisatisfiable* $\iff F_1$ is satisfiable whenever $F_2$ is satisfiable.
{% endblock %}

Equivalent formulas are always equisatisfiable, but equisatisfiable formulas are not necessarily equivalent.

### Tseytin's Transformation
Tseytin's transformation is based on the following insight: if $F$ and $G$ are two formulas, and we let $x \notin \text{FV}(F)$ be a fresh variable, then $F$ is [equisatisfiable](#definition:equisatisfiability) with:

$$(x \leftrightarrow G) \land F[G := x]$$

[Tseytin's transformation](https://en.wikipedia.org/wiki/Tseytin_transformation) applies this recursively in order to transform an expression to CNF. To show this, let's consider a formula using $\neg, \land, \lor, \oplus, \rightarrow, \leftrightarrow$:

$$
F = ((p \lor q) \land r) \rightarrow (\neg s)
$$

The transformation works by introducing a fresh variable for each operation (we can think of it as being for each AST node):

$$\begin{align}
x_1 & \leftrightarrow \neg s \\
x_2 & \leftrightarrow p \lor q \\
x_3 & \leftrightarrow x_2 \land r \\
x_4 & \leftrightarrow x_3 \rightarrow x_1 \\
\end{align}$$

Note that these formulas refer to subterms by their newly introduced equivalent variable. This prevents us from having an explosion of terms in this transformation.

Each of these equivalences can be converted to CNF by using De Morgan's law, and switching between $\oplus$ and $\leftrightarrow$. The resulting conversions are:

| Operation             | CNF                                              |
| :-------------------- | :----------------------------------------------- |
| $x = \neg a$          | $(\neg a \lor \neg x) \land (a \lor x)$          |
| $x = a \land b$       | $(\neg a \lor \neg b \lor x) \land (a \lor \neg x) \land (b \lor \neg x)$ |
| $x = a \lor b$        | $(a \lor b \lor \neg x) \land (\neg a \lor x) \land (\neg b \lor x)$ |
| $x = a \rightarrow b$ | $(\neg a \lor b \lor \neg x) \land (a \lor x) \land (\neg b \lor x)$ |
| $x = a \leftrightarrow b$ | $(\neg a \lor \neg b \lor x) \land (a \lor b \lor x) \land (a \lor \neg b \lor \neg x) \land (\neg a \lor b \lor \neg x)$ |
| $x = a \oplus b$      | $(\neg a \lor \neg b \lor \neg x) \land (a \lor b \lor \neg x) \land (a \lor \neg b \lor x) \land (\neg a \lor b \lor x)$ |

Note that the Tseytin transformations can be read as implications.
For instance, the $x = a \lor b$ transformation can be read as:

- If $a$ and $b$ are true, then $x$ is true
- If $a$ is false, then $x$ is false
- If $b$ is false, then $x$ is false

It then takes the conjunction of all these equivalences:

$$
x_4 \land
(x_4 \leftrightarrow x_3 \rightarrow x_1) \land
(x_3 \leftrightarrow x_2 \land r) \land
(x_2 \leftrightarrow p \lor q) \land
(x_1 \leftrightarrow \neg s)
$$

### SAT Algorithms for CNF
Now that we know how to transform to CNF, let's look into algorithms that solve SAT for CNF formulas.

#### DPLL

*[DPLL]: Davis–Putnam–Logemann–Loveland

The basic algorithm that we'll use is [DPLL](https://en.wikipedia.org/wiki/DPLL_algorithm), which applies clausal resolution recursively until an empty clause appears, or all clauses are unit clauses. This works thanks to the [theorem on refutational completeness of the clausal resolution rule](#theorem:refutational-completeness-of-the-clausal-resolution-rule).

{% highlight scala linenos %}
def DPLL(S: Set[Clause]): Bool = {
    val S' = subsumption(UnitProp(S))
    if (∅ ∈ S') false // an empty clause means the whole thing is unsat
    else if (S' has only unit clauses) true // the unit clauses give e
    else {
        val L = a literal from a clause of S' where {L} not in S'
        DPLL(S' + Set(L)) || DPLL(S' + Set(complement(L)))
    }
}

// Unit Propagation
def UnitProp(S: Set[Clause]): Set[Clause] =
    if (C ∈ S && unit U ∈ S && resolve(U, C) not in S)
        UnitProp((S - C) + resolve(U, C))
    else S

def subsumption(S: Set[Clause]): Set[Clause] =
    if (C1, C2 ∈ S such that C1 ⊆ C2)
        subsumption(S - C2)
    else S
{% endhighlight %}

#### Backtracking
Perhaps the most intuitive algorithm is to construct a binary decision tree. At each node, we take a random decision. If that leads to a conflict, we go back one step, and take the opposite decision.

This is quite simple, but the complexity is exponential. We'll therefore see some smarter algorithms.

#### Non-chronological backtracking
We still construct a binary decision tree. Each decision may also force some other variables into a certain value: we will track these implications in a directed graph.

In this graph, each node represents a value assignment to a variable; let's say we color a node blue if it has been set directly by a decision, and in green if the value is a consequence of a decision. Edges go from nodes (which may be blue or green) to their consequences.

As we construct the graph, we may create conflicts, meaning that we have two (green) nodes assigning different values to the same variable. In this case, we look at the set of nodes pointing to the conflicting pair of nodes:

{% graphviz %}
digraph G {
    graph [bgcolor="transparent"]
    node [style="filled",fillcolor="#e0ecf0"]
    x1 [label="x1 = 0"]
    x2 [label="x2 = 0"]
    x3 [label="x3 = 1"]
    x4 [label="x4 = 1", fillcolor="#e5f0e0"]
    x7 [label="x7 = 1"]
    x8 [label="x8 = 0", fillcolor="#e5f0e0"]
    x11 [label="x11 = 1", fillcolor="#e5f0e0"]
    x12 [label="x12 = 1"]

    subgraph cluster_conflict {
        graph [style="bold", color="red"]
        x9a [label="x9 = 0", fillcolor="#e5f0e0"]
        x9b [label="x9 = 1", fillcolor="#e5f0e0"]
    }

    x1->x4
    x1->x8
    x1->x12
    x2->x11
    x3->x9b
    x3->x8
    x7->x9a
    x7->x9b
    x8->x9a
    x8->x12
} 
{% endgraphviz %}

In the above example, the variables $x_3$, $x_7$ and $x_8$ point to the conflicting pair of $x_9$'s. This means that one of the assignments to these variables was incorrect, because it lead us to the conflict. We can learn from this conflict, and add the following **conflict clause** to the formula:

$$(\neg x_3 \lor \neg x_7 \lor x_8)$$

We can then backtrack to the first decision where we set $x_3$, $x_7$ or $x_8$ (which may be much earlier than the parent decision in the tree). Every once in a while, it may be useful to completely abandon the search tree (but keep the conflict clauses): this is called a restart.

This approach significantly prunes the search tree; by introducing this conflict clause, we've learned something that will be useful forever. 

#### 2-literal watching
This algorithm does the standard trick of unit propagation, but avoids expensive book-keeping by only picking 2 literals in each clause to "watch". We ignore assignments to other variables in the clause.

For each variable, we keep two sets of pointers:

- Pointers to clauses in which the variable is watched in its negated form
- Pointers to clauses in which the variable is watched in its non-negated form

Then, when a variable is assigned true, we only need to visit clauses where its watched literal is negated. This means we don't have to backtrack!

## Linear Temporal Logic
### Definition
With bounded model checking, we've seen how to check for a property over a finite trace. However, there are certain properties that we cannot prove by just seeing a finite trace. For instance, program termination or eventual delivery cannot be proven with the semantics of propositional logic. This will prompt us to introduce linear temporal logic, with which we can study events on a trace.

Let $B$ be a boolean formula over state and input variables.

$$
F ::= B \mid
      \neg F \mid
      F_1 \lor  F_2 \mid
      F_1 \land F_2 \mid
      \text{next } F \mid
      \text{prev } F \mid
      F_1 \text{ until } F_2 \mid
      F_1 \text{ since } F_2 
$$

We write $t, i \models F$ to say that a trace $t$ satisfies formula $F$ at time $i$. The rules for the above constructs are:

$$\begin{align}
t, i \models B & \iff \eval{B}_e = 1 \text{ where } e \text{ is the state of } t \text{ at step } i\\
t, i \models \neg F & \iff \neg (t, i \models F)\\
t, i \models F_1 \lor F_2 & \iff (t, i \models F_1) \lor (t, i \models F_2) \\
t, i \models F_1 \land F_2 & \iff (t, i \models F_1) \land (t, i \models F_2) \\
t, i \models \text{next } F & \iff (t, (i+1) \models F) \\
t, i \models \text{prev } F & \iff i > 0 \land (t, (i-1) \models F) \\
t, i \models F_1 \text{ until } F_2 & \iff \exists k, k \ge i .\ \forall j, i \le j < k .\ (t, k \models F_2) \land (t, j \models F_1) \\
t, i \models F_1 \text{ since } F_2 & \iff \exists k, 0 \le k \le i .\ \forall j, k < j \le i .\ (t, k \models F_2) \land (t, j \models F_1) \\
\end{align}$$

We can interpret *until* to mean that $F_1$ is true until $F_2$ becomes true. For instance, we can guarantee something until an overflow bit is on, at which point all bets are off. Note that this does not impose any constraints on $F_1$ once $F_2$ is true.

Note that *next* and *prev*, and *since* and *until* are duals of each other[^almost-duals].

[^almost-duals]: Or rather, they're almost duals, because the future is infinite but the past is finite.

We can add some derived operations from these:

$$\begin{align}
\text{eventually } F 
    & \equiv 1 \text{ until } F 
    & \iff \exists k \ge i .\ (t, k \models F) \\

\text{globally } F
    & \equiv \neg (\text{eventually } (\neg F))
    & \iff \forall k \ge i .\ (t, k \models F) \\
\end{align}$$

The operation *globally* can be thought of as meaning "forever, from now on" (where "now" is step $i$). For instance, $\text{globally }(p \rightarrow \text{eventually } q)$ means that from now on, every point in the trace satisfying $p$ is followed by a point in the trace satisfying $q$ at some point.

## Binary Decision Diagrams
### Definition
Binary Decision Diagrams (BDDs) are a representation of Boolean functions: we can represent a Boolean function $f: \set{0, 1}^n \rightarrow \set{0, 1}$ as a directed acyclic graph (DAG). We distinguish terminal from non-terminal nodes. Each edge is labeled with a *decision*: a solid edge ("high edge") means the variable is 1, and a dashed edge ("low edge") means that it is 0. The leaf nodes are labeled with the outcome. 

For instance, the BDD for $x \lor y$ is:

{% graphviz %}
digraph G {
    graph [bgcolor="transparent"]

    subgraph cluster_output {
        graph [color="transparent"]
        f1a [label="1",shape="square",fontcolor="red"]
        f1b [label="1",shape="square",fontcolor="red"]
        f0 [label="0",shape="square",fontcolor="red"]       
    }
    x -> y [style="dashed"]
    x -> f1a
    y -> f1b
    y -> f0 [style="dashed"]
}
{% endgraphviz %}

We can also think of this DAG as a finite automaton, or as a (loop-free) branching program. 

### Canonicity
The key idea of BDDs is that specific forms of BDDs are *canonical*, and that BDDs can be transformed into their canonical form. For instance, the previous example can be rewritten as:

{% graphviz %}
digraph G {
    graph [bgcolor="transparent"]
    f1 [label="1",shape="square",fontcolor="red"]
    f0 [label="0",shape="square",fontcolor="red"]
    x -> y [style="dashed"]
    x -> f1
    y -> f1
    y -> f0 [style="dashed"]
}
{% endgraphviz %}

Let's define this transformation more formally. 

We first assign an arbitrary total ordering to variables: variables must appear in that order along all paths. Here, we picked $x < y$ as our ordering. Note that in general, selecting a good ordering is an intractable problem, but decent application-specific heuristics exist. 

Then, the reduced ordered BDD (RO-BDD) is obtained by:

- Merging equivalent leaf nodes (which is what we did above)
- Merging isomorphic nodes (same variables and same children)
- Eliminating redundant tests (where both outgoing edges go to the same child)

Doing this brings us to the following property:

{% block theorem "Unicity of RO-BDD" %}
With a fixed variable order, the RO-BDD for a Boolean function $f$ is unique
{% endblock %}

In the following, we'll always refer to RO-BDDs, and just call them BDDs.

### Data structures for BDDs
To encode a BDD, we'll map number all nodes as 0, 1, 2, ..., where 0 and 1 are terminals. The variables are also numbered as $x_1, x_2, \dots, x_n$. We also number the levels in the diagram, according to the total ordering that we selected: level 1 is the root node, and level $n+1$ contains terminal nodes.

{% graphviz %}
digraph G {
    graph [bgcolor="transparent"]
    subgraph cluster_level1 {
        graph [label="Level 1"]
        x
    }
    subgraph cluster_level2 {
        graph [label="Level 2"]
        y
    }
    subgraph cluster_level3 {
        graph [label="Level 3"]
        f1 [label="1",shape="square",fontcolor="red"]
        f0 [label="0",shape="square",fontcolor="red"]
    }
    x -> y [style="dashed"]
    x -> f1
    y -> f1
    y -> f0 [style="dashed"]
}
{% endgraphviz %}

A data structure for BDDs is the node table $T : u \rightarrow (i, l, h)$, mapping a node $u$ to its low child $l$ and high child $h$. The node table also contains an entry $i$ describing the level in the ordering as well as the name of the variable.

For instance, for the example we used above, the table would be:

| Node number $u$ | Level and name $i$ | Low edge $l$ | High edge $h$ |
| --- | ----- | --- | --- |
| 0   | 3     |     |     |
| 1   | 3     |     |     |
| 2   | 2 $y$ | 0   | 1   |
| 3   | 1 $x$ | 2   | 1   |

We'll assume we have some methods for querying this table:

- `init(T)`: initialize $T$ with 0 and 1 terminal nodes
- `u = add(T, i, l, h)`: add node $u$ with $\seq{i, l, h}$ to $T$
- `var(u)`: get $i$ of node $u$
- `low(u)`: get $l$ of node $u$
- `high(u)`: get $h$ of node $u$

We can also define the inverse $H : (i, l, h) \rightarrow u$ of a node table, allowing us to find a node if we have all the information about it. We'll assume that we have some methods to query and update this structure:

- `init(H)`: initialize $H$ with 0 and 1 terminal nodes
- `u = lookup(H, i, l, h)`: get node $u$ from $(i, l, h)$
- `insert(H, i, l, h, u)`: add an entry from $(i, l, h)$ to $u$

### Basic operations on BDDs
Somewhat surprisingly, given a BDD for a formula $f$, we can check whether it is a tautology, satisfiable or inconsistent in *constant time*:

- $f$ is a tautology $\iff$ the BDD is $1$
- $f$ is satisfiable $\iff$ the BDD is not $0$
- $f \equiv g \iff$ their BDDs are equal[^consequence-unicity-ro-bdd]

[^consequence-unicity-ro-bdd]: This is a consequence of the the [theorem of unicity of the RO-BDD](#theorem:unicity-of-ro-bdd)

To insert a node into $T$, we ensure that we're keeping a RO-BDD by eliminating redundant tests, and preventing isomorphic nodes. If that is not the case, we can update the tabée $T$ and the reverse mapping $H$.

{% highlight scala linenos %}
type NodeId = Int
type Level = Int

def mk(i: Level, l: NodeId, h: NodeId): NodeId = {
  // eliminate redundant tests:
  if (l == h) l
  // prevent isomorphic nodes:
  else if (lookup(H, i, l, h) != null) lookup(H, i, l, h) 
  else {
    u = add(T, i, l, h) // insert node
    insert(H, i, l, h, u) // update reverse mapping
    u
  }
}
{% endhighlight %}

With this method in hand, we can see how to build a BDD from a formula $f$. The key idea is to use Shannon's expansion:

$$f= (\neg x \land f\mid_{x=0}) \lor (x \land f\mid_{x=1})$$

Here, $f\mid_{x=1}$ means that we replace all $x$ nodes by their high-edge subtree. In the formula, we can think of it as a substitution of $x$ by 1. We call this basic operation `Restrict`.

This breaks the problem into two subproblems, which we can solve recursively:

{% highlight scala linenos %}
def build(f: Formula): NodeId = build2(f, 1)
private def build2(f: Formula, level: Level): NodeId =
  if (level > n)
    if (f == False) 0 else 1
  else {
    xi = f.variables.head
    f0 = build2(f.subst(xi, 0), level + 1)
    f1 = build2(f.subst(xi, 1), level + 1)
    mk(level, f0, f1)
  }
{% endhighlight %}

## Interpolation-based model checking

### Interpolation
{% block definition "Interpolant" %}
Let $F$ and $G$ be propositional formulas. An *interpolant* for $F$ and $G$ is a formula $H$ such that:

- $F \models H$
- $H \models G$
- $\text{FV}(H) \subseteq \text{FV}(F) \cap \text{FV}(G)$
{% endblock %}

Note that if these conditions hold, we have $F \models G$. The goal of $H$ is to serve as an explanation of why $F$ implies $G$, using variables that the two have in common.

{% block theorem "Existence and Lattice of Interpolants" %}
Let $F$ and $G$ be propositional formulas such that $F \models G$ and let $S$ be the set of interpolants of $(F, G)$. Then:

- If $H_1, H_2 \in S$ then $H_1 \land H_2 \in S$ and $H_1 \lor H_2 \in S$
- $S \ne \emptyset$
- $\exists H_{\text{min}}.\ \forall H\in S.\ H_{\text{min}} \models H$
- $\exists H_{\text{max}}.\ \forall H\in S.\ H \models H_{\text{max}}$
{% endblock %}

For instance, let's consider two formulas $F(\vec{x}, \vec{y})$ and $G(\vec{y}, \vec{z})$. The variables they have in common are $\vec{y}$ so we're looking for an interpolant $I(\vec{y})$.

### Reverse interpolants
We know that $F \rightarrow G \equiv \neg F \lor G$. The negation of this is $F \land \neg G$. Let $A = F$ and $B = \neg G$. Instead of looking at the [validity](#definition:validity) of $F \rightarrow G$, we can look at [unsatisfiability](#definition:satisfiability) of $A \land B$. To aid us in this, we'll define $H$ as an interpolant for $A \land B$, meaning that we have:

- $A \models H$
- $H \models B$, meaning that $B \models \neg H$
- $\text{FV}(H) \subseteq \text{FV}(A) \cap \text{FV}(B)$

As previously seen, we can determine whether $A \land B$ is unsatisfiable by using the [theorem on completeness of clause resolution](#theorem:refutational-completeness-of-the-clausal-resolution-rule): it is unsatisfiable iff we can derive the empty clause using resolution. A key insight here is that we can use the resolution proof to construct an interpolant $H$ for $A \land B$.

Let's define $I(C)$ as the interpolant for $A \land (\neg C \mid_A)$ and $B \land (\neg C \mid_B)$, where $C \mid_A$ denotes the clause $C$, but only with literals belong in $\text{FV}(A)$. The idea here is that we can construct it recursively, and that $I(\emptyset)$ is the interpolant for $A$ and $B$.

There are multiple ways of constructing this $I(C)$, like the Symmetric System or McMillan's System (which uses a SAT solver). There are many interpolants that exist, and it's unclear which is best. Small formulas are good, but we do not currently know any efficient algorithms to find them.

### Tseytin's transformation and interpolants
Remember that [Tseytin's transformation](#tseytins-transformation) transforms an expression into CNF by introducing fresh variables. Suppose we have converted $A$ and $B$ to $\text{cnf}(A)$ and $\text{cnf}(B)$, and that the newly introduced variables are $\vec{p_A}$ and $\vec{p_B}$, respectively. The results of the Tseytin transformations are:

$$
\emptyset \models A \leftrightarrow \exists \vec{p_A}.\ \text{cnf}(A) 
\quad\text{and}\quad
\emptyset \models B \leftrightarrow \exists \vec{p_B}.\ \text{cnf}(B)
$$

{% block lemma "Interpolant for CNF" %}
The interpolant $H$ for $\text{cnf}(A)$ and $\text{cnf}(B)$ is also an interpolant for $A$ and $B$
{% endblock %}

We'll prove this by showing that all [three properties of interpolants](#definition:interpolant) are preserved:

- todo
- todo
- By assumption of $H$ being an interpolant for $\text{cnf}(A)$ and $\text{cnf}(B)$, we have:
  
  $$\begin{align}
  \text{FV}(H)
  & \subseteq \text{FV}(\text{cnf}(A))\cap\text{FV}(\text{cnf}(B)) \\
  & \subseteq (\text{FV}(A)\cup\vec{p_A}) \cap (\text{FV}(B)\cup\vec{p_B}) \\
  & = \text{FV}(A) \cap \text{FV}(B)
  \end{align}$$

  The second step is by the above definition of the transformation's results. The last step is because $\vec{p_A}$ and $\vec{p_B}$ are disjoint.

$\qed$

### Reachability checking using interpolants
We can use interpolants to improve upon bounded model checking, in order to prove properties without having to unfold up to the maximum length. To do this, we'll need to recall two concepts that we've seen previously:

- Remember that [bounded model checking](#bounded-model-checking-for-reachability) constructs a formula $T_k$ that is satisfiable iff there exists a trace of length $\le k$ starting from the initial state, satisfying an error formula $E$.
- Also, recall the [$\post$ function](#post).

#### Reachability checking
To check for reachability, we can keep adding $\post^i$ to the set of reachable states until one of the following two situations arises:

- We reach a fixpoint: $\post^{i+1}(\text{Init}) = \post^i(\text{Init})$)
- We find that an error state is reachable: $\post^i(\text{Init}) \cap E \ne \emptyset$.

The algorithm would look something like this:

{% highlight scala linenos %}
val errorStates: Set[State] = ???

def reachable(currentStates: Set[State]): Boolean = {
  val nextStates = currentStates union post(currentStates)
  if (nextStates intersect errorStates != emptyset)
    true
  else if (nextStates == currentStates)
    false
  else
    reachable(nextStates)
}

reachable(Init)
{% endhighlight %}

The problem with this approach is that computing $\post$ may result in a complex image (a large formula or BDD), and it may take many steps to compute all reachable states. To fix this problem, we can do the same trick we always do in formal verification: simplifying the model.

#### Approximated reachability checking
The insight to simplify is that we can drop complex and uninteresting parts of the $\post$ formula: instead of $F_\text{interesting} \land F_\text{complex}$, we'll only look at $F_\text{interesting}$. This allows us to be faster: indeed, a formula that says nothing about certain boolean variables describes a **larger set of states** (meaning that we grow faster), and has a **smaller formula** (meaning that the result of $\post$ is less complex).

So how does one approximate the post? There are many possible approximations of it, so we'll use a subscript to denote the (potentially) different approximations. We'll use a superscript $\text{#}$ to denote an approximation of something. Note that a superscript number $n$ still denotes $n$ recursive applications of the function.

Let $\postapprox_j(X)$ denote any over-approximation of $\post$:

$$\post(X) \subseteq \postapprox_j(X)$$

We'll consider a monotonic $\post$[^why-monotonic], meaning that:

[^why-monotonic]: Why do we consider $\post$ to be monotonic? Well, that will become clear [later in the course](#bounded-model-checking-of-a-program): for our application of verifying programs, we will work with monotonic relations.

$$X \subseteq Y \implies \text{post}(X) \subseteq \post(Y)$$

Now, consider the following sequence:

| $\text{Init}$                | $\text{Init}$ |
| $\text{post}(\text{Init})$   | $\postapprox_1(\text{Init})$ |
| $\text{post}^2(\text{Init})$ | $\postapprox_2(\postapprox_1(\text{Init}))$ |
| ... | ... |
| $\text{post}^n(\text{Init})$ | $\postapprox_n(\dots\postapprox_2(\postapprox_1(\text{Init}))\dots)$ |

The relationship here is that:

$$
\text{post}(\text{post}^i(\text{Init}))
\subseteq \text{post}(\postapprox_i(\dots\postapprox_1(\text{Init})\dots))
\subseteq \postapprox_{i+1}(\postapprox_i(\dots))
$$

This means that we can replace $\post^n$ with recursive applications of different $\postapprox_j$ approximations. This leads us to the following algorithm:

{% highlight scala linenos %}
val errorStates: Set[State] = ???
val post#: Array[Set[State] => Set[State]] = ???

def maybeReachable(
  currentStates: Set[State], 
  postAcc: Set[State], // accumulator of post#[i-1](post#[i-2](...))
  i: Int
): Boolean = {
  // compute post#[i](...post#[1](Init)...)
  val nextPostAcc = post#[i](postAcc)

  val nextStates = currentStates union nextPostAcc
  if (nextStates intersect errorStates != emptySet)
    true
  else if (nextStates == currentStates)
    false
  else
    maybeReachable(nextStates, nextPostAcc, i + 1)
}

maybeReachable(Init, Init, 1)
{% endhighlight %}

If `maybeReachable` returns `false`, then we know *for sure* that the system is safe, that the error states are not reachable. However, crucially, if `maybeReachable` returns `true`, then we cannot really conclude anything. Maybe the error states are reachable, and maybe we just need to try again with better approximations $\postapprox$.

#### Constructing approximations from interpolants
We have discussed how to use an approximation, but not how to choose one. We'll start out by showing how to find one from $k=0$, and how to continue from there. Let's look at the [formula for bounded model checking](#bounded-model-checking-for-reachability) again:

$$
T_j \equiv 
    \text{Init}[\vec{s} := \vec{s}^0] \land 
    \left(\bigland_{i=0}^{j-1} R\left[
        \seq{\vec{s},   \vec{a},   \vec{x},   \vec{s'}} :=
        \seq{\vec{s}^i, \vec{a}^i, \vec{x}^i, \vec{s}^{i+1}}
    \right]\right) \land
    E[\vec{s} := \vec{s}^j]
$$

To simplify the formula a little, we'll define:

$$
R_i = R\left[
  \seq{\vec{s},   \vec{a},   \vec{x},   \vec{s'}} :=
  \seq{\vec{s}^i, \vec{a}^i, \vec{x}^i, \vec{s}^{i+1}}
\right]
$$

This allows us to rewrite the formula as:

$$
T_j \equiv 
    \underbrace{\text{Init}[\vec{s} := \vec{s}^0] \land R_0}_A \land
    \underbrace{
      \left(\bigland_{i=1}^{j-1} R_i \right) \land
      E[\vec{s} := \vec{s}^j]
    }_B
$$

We define $A$ and $B$ as above, and are now interested in finding an interpolant $H$ between the two. The first thing we can look at is which variables $A$ and $B$ have in common; by the third property of [interpolants](#definition:interpolant):

$$\text{FV}(H) \subseteq \text{FV}(A) \cap \text{FV}(B) = \vec{s}^1$$

We also need the two first properties of interpolants:

- $A \models H$, which is equivalent to $\text{Init}[\vec{s} := \vec{s}^0] \land R_0 \models H$. Intuitively, this is like $\text{Init}\bullet\bar{r} \subseteq H$, so we can define $\postapprox_1(\text{Init}) = H$. This is a valid approximation, as $\post(\text{Init})\subseteq\postapprox_1(\text{Init})$.

- $H \models B$, which is equivalent to $B \models \neg H$. We can just impose the constraint of $\text{unsat}(H\land B)$ to prevent $H$ from being too general.

Once we have an approximation for $\postapprox_1$, we can find the $\postapprox_2$ by treating $H[\vec{s}^1 := \vec{s}^0]$ as the new $\text{Init}$ and repeating the process, and so on for all the other approximations.

## LCF Approach to Formal Proofs
Logic for Computable Functions (LCF) is a logic for reasoning about computable partial functions based on domain theory.

In "[A metalanguage for Interactive Proof in LCF](http://www-public.imtbs-tsp.eu/~gibson/Teaching/CSC4504/ReadingMaterial/GordonMMNW78.pdf)", the idea is:

- A `Theorem` is an abstract data type that stores a formula
- We cannot create a theorem out of an arbitrary formula (the constructor is private)
- We can create formulas by:
  + Creating axiom instances given some parameters (static methods)
  + Use inference rules to get theorems from other theorems (instance methods)

The idea is that this allows us to maintain invariants about the theorems. For instance:

{% highlight scala linenos %}
final class Theorem private(val formula: Formula) {
  def modusPonens(pq: Theorem, p: Theorem): Theorem = pq.formula match {
    case Implies(pf, qf) if p.formula == pf => Theorem(qf)
    case _ => throw new Exception("illegal use of modus ponens")
  }
}
{% endhighlight %}

## First order logic
### Grammar
We have formulas $F$ and terms $t$:

$$\begin{align}
F ::= \ 
  & p(t_1, \dots, t_n) \mid
    t_1 = t_2 \mid 
    \top \mid \bot \\
  & \mid \neg F \mid
    F_1 \land F_2 \mid F_1 \lor F_2 \mid
    F_1 \rightarrow F_2 \mid F_1 \leftrightarrow F_2 \\
  & \mid \forall x.\ F \mid \exists x.\ F \\ \\

t ::= \ 
  & x \mid c \mid f(t_1, \dots, t_n)
\end{align}$$

Where:

- $x$ denotes a variable
- $p$ denotes a predicate symbol
- $f$ denotes a function symbol
- $c$ denotes a constant. We can think of it as a function symbol of arity 0.

To denote how many arguments a function or predicate symbol takes, we define a function $\ar$. For instance, if $\ar(f) = 2$ then $f$ takes two arguments.

We'll also define granularity levels of a formula:

- We call $p(t_1, \dots, t_n)$ an *atomic formula* if it contains no logical connectives or formulas.
- A *literal* is an atomic formula or its negation.
- A *clause* is a disjunction of literals

### Interpretation
{% block definition "First-order logic interpretation" %}
A first-order interpretation is denoted $I = (D, e)$, where:

- $D \ne \emptyset$ is the set of constants
- $e$ maps constants, functions and predicate functions as follows:
  + Each constant $c$ into an element of $D$, i.e. $e(c) \in D$
  + Each function symbol $f$ with $\ar(f) = n$ into a total function of $n$ arguments, i.e. $e(f): D^n \rightarrow D$
  + Each predicate symbol $p$ with $\ar(p) = n$ into an $n$-ary relation, i.e. $e(p) \subseteq D^n$
{% endblock %}

One thing that's important to understand about first-order logic is that it is not defined over a fixed set of constants. It can be *interpreted* with an arbitrary set of constants $D$, which is not necessarily just booleans (which would be $D = \set{\text{true}, \text{false}}$). Much like with SAT solvers which can return a boolean assignment $e$, in an interpretation of a first-order formula, the choice of $e$ maps constants, function symbols and predicate symbols into actual values.

We can evaluate a given formula $F$ with a given interpretation $I$. We denote this as $\eval{F}_I$. 

- If the result of the evaluation is true, we write $I \models F$ or $\eval{F}_I = 1$.
- If the result of the evaluation is is false, we write $I \nvDash F$ or $\eval{F}_I = 0$.

Since the constants in $D$ aren't necessarily booleans, how does the result of the evaluation return a boolean? Well, we can "push down" evaluation and compute logical operations on those results[^incomplete-rules]:

[^incomplete-rules]: These rules are not complete, but suffice if we've translated the formula to [negational normal form](#negational-normal-form).

$$
\begin{align}
\eval{\neg F}_I & = \neg \eval{F}_I \\
\eval{F_1 \land F_2}_I & = \eval{F_1}_I \land \eval{F_2}_I \\
\eval{F_1 \lor F_2}_I & = \eval{F_1}_I \lor \eval{F_2}_I \\
\eval{\forall x.\ F}_I & = \forall d \in D.\ \eval{F}_{(D, e[x := d])} \\
\eval{\exists x.\ F}_I & = \exists d \in D.\ \eval{F}_{(D, e[x := d])} \\
\end{align}
$$

We say that:

{% block definition "Validity and satisfiability in first-order logic" %}
- $F$ is **valid** if $\forall I.\ \eval{F}_I = 1$
- $F$ is **satisfiable** if $\exists I.\ \eval{F}_I = 1$
{% endblock %}

As an example, let's take a formula $F$ with function symbols $p$ and $q$:

$$F = \forall x.\ \exists y.\ (p(x, y) \land q(y, x))$$

- Validity: $\forall \vec{D}\ne\emptyset .\ \exists \vec{p}, \vec{q} \subseteq \vec{D}^2 .\ \forall x\in D.\ \exists y\in D.\ ((x, y)\in p \land (y, x) \in q)$
- Satisfiability: $\exists \vec{D}\ne\emptyset .\ \exists \vec{p}, \vec{q} \subseteq \vec{D}^2 .\ \forall x\in D.\ \exists y\in D.\ ((x, y)\in p \land (y, x) \in q)$

This leads us to the following observation:

{% block lemma %}
$F$ is valid $\iff \neg F$ is not satisfiable
{% endblock %}

This means that to check validity, we can instead check satisfiability of the negation. Looking into negations will lead us to defining a normal form for negation. 

### Negational normal form
In negational normal form, negation only applies to atomic formulas, and the only other connectives are $\land$ and $\lor$ (we've translated $\rightarrow$ and $\leftrightarrow$ away). It essentially "pushes down" negation. We can transform formulas to negational normal form as follows:

$$
\begin{align}
F_1 \leftrightarrow F_2
  & \rightsquigarrow (F_1 \rightarrow F_2) \land (F_2 \rightarrow F_1) \\
F_1 \rightarrow F_2 
  & \rightsquigarrow \neg F_1 \lor F_2 \\
\neg \neg F
  & \rightsquigarrow F \\
\neg(F_1 \land F_2)
  & \rightsquigarrow \neg F_1 \lor \neg F_2 \\
\neg(F_1 \lor F_2)
  & \rightsquigarrow \neg F_1 \land \neg F_2 \\
\neg \forall x.\ F
  & \rightsquigarrow \exists x.\ \neg F \\
\neg \exists x.\ F
  & \rightsquigarrow \forall x.\ \neg F \\
\neg \bot
  & \rightsquigarrow \top \\
\neg \top
  & \rightsquigarrow \bot \\
\end{align}
$$

### Prenex normal form
Prenex normal form is a form where are all quantifiers appear first, and then we have a formula without quantifiers. Once we are in negational normal form, we can pull quantifiers to the top by the following:

$$
\begin{align}
(\forall x.\ F) \lor G
  & \rightsquigarrow \forall x.\ (F \lor G) \\
(\forall x.\ F) \land G
  & \rightsquigarrow \forall x.\ (F \land G) \\
(\exists x.\ F) \lor G
  & \rightsquigarrow \exists x.\ (F \lor G) \\
(\exists x.\ F) \land G
  & \rightsquigarrow \exists x.\ (F \land G) \\
\end{align}
$$

### Skolem functions
Observe that the following formula is valid:

$$(\forall x.\ p(x, f(x)))) \rightarrow (\forall x.\ \exists y.\ p(x, y))$$

Indeed, if we assume the left-hand side of the implication to be true, we need to prove that the right-hand side also holds. To do this, we can simply pick $y$ to be the value of $f(x)$. This seems obvious.

What's less obvious is a sort of converse: if we assume that the right-hand side holds, we can prove that there exists an $f$ satisfying the whole formula. Note that we can't write $\exists f$ because $f$ is a symbol and the FOL grammar doesn't allow this, but what we can do instead is to extend the signature with a new function symbol $f$ that does not appear in the formula. We call this a Skolem function.

{% block definition "Skolemization" %}
We can **skolemize** a formula in prenex normal form by replacing:

$$\forall x_1, \dots, x_n.\ \exists y.\ F(x_1, \dots, x_n, y)$$

with

$$\forall x_1, \dots, x_n.\ F(x_1, \dots, x_n, g(x_1, \dots, x_n))$$

Where $g$ is a fresh function symbol (called a Skolem function) of arity $n$.
{% endblock %}

{% comment %}
TODO this whole section was (probably) presented in class but isn't on the slides.

Skolemization gives a name to this $y$ that depends on $x_1, \dots, x_n$. Note that skolemization also gets rid of the existential quantifier.

The above definition says prenex normal form, but we can also skolemize a negational normal form.

Let's run through an example. We consider the following formula:

$$todo big formula$$

Skolemizing this, we get:

$$todo skolemized$$

Where $g$ and $b$ are fresh, and $\text{ar}(g) = 1$, $\text{ar}(b) = 0$, so $b$ is a constant. For $b$, we do this because the $\exists$ is before the $\forall$, so it depends on nothing.


***

{% block definition "Herbrand interpretation" %}
Given $I = (D, E)$ such that $\eval{F}_I = 1$ we can define:

$$I_H = (T, e_H) \text{ such that } \eval{F}_{I_H}=1$$

Where $I_H$ is the [Herbrand interpretation](https://en.wikipedia.org/wiki/Herbrand_interpretation), and $T$ is the Herbrand universe, containing all atomic terms:

$$T ::= c \mid f(T_1, \dots, T_n)$$
{% endblock %}

Note that $T$ may be infinite, but it's countably infinite.

{% endcomment %}

## Converting imperative programs to formulas
### Motivating example
An imperative program can be thought of as a relation between initial state and final state. For instance, let's consider the following instructions:

{% highlight scala linenos %}
x = x + 2
y = x + 10
{% endhighlight %}

We can think of this as the relation:

$$
\set{((x, y), (x', y')) \mid x' = x + 2 \land y = x + 12}
$$

We can ensure postconditions on this. In [Stainless](https://github.com/epfl-lara/stainless), we could check the following condition: 

{% highlight scala linenos %}
import stainless.lang._
import stainless.lang.StaticChecks._

case class FirstExample(var x: BigInt, var y: BigInt) {
  def increase: Unit = {
    x = x + 2
    y = x + 10
  }.ensuring(_ => old(this).x > 0 ==> (x > 0 && y > 0))
}
{% endhighlight %}

This is equivalent to the following condition, which says that the relation of the program should be a subset of the relation of the pre- and postconditions.

$$
\begin{align}
& \set{((x, y), (x', y')) \mid x' = x + 2 \land y = x + 12} \\
\subseteq &
\set{((x, y), (x', y')) \mid x > 0 \rightarrow (x' > 0 \land y' > 0)}
\end{align}
$$

This is equivalent to checking the validity of the following formula:

$$
\seq{x' = x + 2 \land y = x + 12}
\rightarrow
\seq{x > 0 \rightarrow (x' > 0 \land y' > 0)}
$$

### Translating commands
We'll first define a general formulation of the translation, and then look into commands on a case-by-case basis.

Suppose we want to translate a program containing $n$ mutable variables $\vec{V} = \set{x_1, \dots, x_n}$. Let $c$ be an arbitrary command. Let $R(c)$ be the formula describing the relation between initial state $\vec{V}$ and final state $\vec{V}'$. We define the relation as $\rho(c)$:

$$\rho(c) = \set{(\vec{x}, \vec{x}') \mid R(c)}$$

#### Assignment
We formulate assignment (`x = t`) as follows:

$$
x' = t \land \bigland_{v \in \vec{v}\setminus\set{x}} v' = v
$$

The formula says that $x$ now has value $t$, but also fixes everything that hasn't changed. We need to constrain the other variables so that they cannot take arbitrary values.

#### Conditions
We formulate conditions (`if (b) c1 else c2`) as follows:

$$(b \land R(c_1)) \lor (\neg b \land R(c_2))$$

This is a fairly straightforward transformation that corresponds to the boolean formulation of a condition.

#### Non-deterministic choice
What if we have a condition where we do not know what happens in the condition (e.g. `if (*) c1 else c2`)? We can simply translate that into a disjunction:

$$R(c_1) \lor R(c_2)$$

#### Sequences
We formulate sequences (`c1; c2`) as [composition of the relations](#definition:composition-of-relations) $r_1$ and $r_2$ corresponding to $c_1$ and $c_2$:

$$
\rho(c_1; c_2) = 
\rho(c_1) \circ \rho(c_2) =
\set{(\vec{x}, \vec{x}') \mid \exists \vec{z}.\ 
  (\vec{x}, \vec{z}) \in r_1 \land
  (\vec{z}, \vec{x}') \in r_2
)}
$$

This simply tells us that there must exist an intermediary state $\vec{z}$ that binds initial and final state together. The formula is thus:

$$
R(c_1; c_2) =
  \exists \vec{z}.\ 
    R(c_1)[\vec{x}' := \vec{z}] \land 
    R(c_2)[\vec{x} := \vec{z}]
$$

Where $\vec{z}$ are freshly picked. This relation places the constraint that the output variables of $c_1$ should be the input variables of $c_2$. This is a little reminiscent of [the formula for bounded model checking](#bounded-model-checking-for-reachability).

As a useful convention when converting larger programs, we can name $\vec{z}$ after the position in the program.

#### Non-deterministic commands
Let's introduce a potentially dangerous command, which we'll call `havoc` (a word meaning destruction and confusion). How can we formulate `havoc(x)`? A conservative approach would be to let $x$ be arbitrary henceforth, but keep all other variables as they are:

$$
R(\text{havoc}(x)) = \bigland_{v \in \vec{v}\setminus\set{x}} v' = v
$$

#### Assumption
An assumption (which we'll call `assume(F)`) limits the space of possibilities. We can use `assume` to recover from `havoc` (e.g. `havoc(x); assume(x == e)` is equivalent to `x = e` if `x` isn't in the free variables of `e`). The command doesn't change anything, but if the condition doesn't hold, execution should be stopped.

$$R(\text{assume}(F)) = F \land \bigland_{v \in \vec{v}} v' = v$$

The relation created by this translation is the [identity relation](#definition:identity-relation) over the set $A = \set{\vec{x} \mid F}$ of variables satisfying $F$. To justify the name "assume", we can look at the following example.

- $R(\text{assume}(F); c) = F \land R(c)$
- $R(c; \text{assume}(F)) = R(c) \land F[\vec{x} := \vec{x}']$, where $\vec{x}'$ are the final values that we get from executing $c$.

Note that `if (b) c1 else c2` is equivalent to `if (*) { assume(b); c1 } else { assume(!b); c2 }`; the generated formulas will be equivalent.

### Full example
Consider the following code:

{% highlight scala linenos %}
(if (b) { x = x + 1 } else { y = x + 2});
x = x + 5;
(if (*) { y = y + 1} else {x = y})
{% endhighlight %}

Notice the line numbers; we'll use those to name our intermediary variables. The translation becomes:

$$
\begin{align}
\exists x_2, y_2, x_3, y_3.\  
  & ((b \land x_1 = x + 1 \land y_1 = y) \lor (\neg b \land x_1 = x \land y_1 = x + 2)) \\
  & (x_2 = x_1 + 5 \land y_2 = y_1) \\
  & ((x' = x_2 \land y' = y_2 + 1) \lor (x' = y_2 \land y' = y_2))
\end{align}
$$

Here, $x$ and $y$ denote the variables' initial state (before execution), and $x'$ and $y'$ denote their final state.

## Hoare Logic
Hoare logic (named after [Sir Tony Hoare](https://en.wikipedia.org/wiki/Tony_Hoare)) is a logic that was introduced to reason about programs. We can think of it as a way of inserting annotations into code, in order to make proofs about (imperative) program behavior simpler.

As an example, annotations have been added in the program below:

{% highlight scala linenos %}
// {0 <= y}
i = y;
// {0 <= y && i = y}
r = 0;
// {0 <= y && i = y && r = 0}
while // {r = (y-i)*x && 0 <= i}
  (i > 0) {
    // {r = (y-i)*x && 0 < i}
    r = r + x;
    // {r = (y-i+1)*x && 0 < i}
    i = i - 1
    // {r = (y-i)*x && 0 <= i}
}
// {r = x * y}
{% endhighlight %}

Let's look at the first three lines:

{% highlight scala linenos %}
// {0 <= y}
i = y;
// {0 <= y && i = y}
{% endhighlight %}

This constitutes a Hoare triple, which we'll study in more detail now.

### Hoare triples
Central to Hoare logic are **Hoare triples**.

{% block definition "Hoare Triple" %}
Let $S$ be the set of possible states. Let $P, Q \subseteq S$. Let $r\subset S \times S$ be a relation over the states $S$. A Hoare triple is defined as:

$$
\triple{P}{r}{Q} \iff \forall s, s' \in S.\ (s \in P \land (s, s') \in r \rightarrow s' \in Q)
$$
{% endblock %}

We call $P$ the precondition and $Q$ the postcondition.

Note that $\set{P}$ does not mean "singleton set of $P$", but is notation for an "assertion" around a command. A Hoare triple may or may not hold; after all it is simply a shorthand for a logical formula, as the definition shows. Let's look at examples of triples that do and do not hold:

- `{j = a} j = j + 1 {a = j + 1}`
  
  This triple does not hold: if $j$ is equal to $a$ initially, and we then increment $j$ by 1, then $a \ne j + 1$.

- `{i != j} if (i > j) then m=i-j else m=j-i {m > 0}`
  
  This triple does hold. If $i > j$ then $m > 0$, and if $j < i$ then it is also positive.

### Preconditions and postconditions
Here are a few cues as to how to think of stronger vs. weaker conditions:

- A stronger condition is a smaller set than the weaker condition.
- A stronger condition is a subset of a weaker condition.
- A stronger condition implies a weaker condition.

In other words, putting conditions on a set makes it smaller.

The strongest possible condition is "false", which is the set $\emptyset$. The weakest condition is "true", which is the biggest set (all tuples).

#### Definitions
{% block definition "Strongest postcondition" %}
$$\sp{P, r} = \set{s' \mid \exists s.\ s \in P \land (s, s') \in r}$$
{% endblock %}

To visualize this, let's look at a diagram of the relation $r$:

<figure markdown="1">
  ![Strongest postcondition of a relation](/images/fv/strongest-postcondition.png)
  <figcaption>Image from <a href="https://lara.epfl.ch/w/sav08/hoare_logic">lara.epfl.ch</a></figcaption>
</figure>

If we let $P$ be the red set, then $\sp{P, r}$ is the blue set: it's the smallest set of values that *all* are pointed to from $P$ by $r$. In other words, it's the image of $P$ ($\text{post}(P)$ or $P\bullet r$), which we can notice has the [same definition](#definition:image-of-a-set).

{% block definition "Weakest precondition" %}
$$\wp{r, Q} = \set{s \mid \forall s'.\ (s, s') \in r \rightarrow s' \in Q}$$
{% endblock %}

<figure markdown="1">
  ![Weakest precondition of a relation](/images/fv/weakest-precondition.png)
  <figcaption>Image from <a href="https://lara.epfl.ch/w/sav08/hoare_logic">lara.epfl.ch</a></figcaption>
</figure>

Dually, if we let $Q$ be the blue set, then $\wp{r, Q}$ is the red set: it's the largest set of values that *only* point to $Q$. Notice that there are points that point to $S$ and $Q$ (since $r$ doesn't need to be injective), but those are not included in $\wp{r, Q}$. The weakest precondition is the largest possible set from which we will definitely end up in $Q$ from.

#### Equivalence
{% block lemma "Three forms of Hoare Triple" %}
The following three conditions are equivalent.

- $\triple{P}{r}{Q}$
- $P \subseteq \wp{r, Q}$
- $\sp{P, r} \subseteq Q$
{% endblock %}

These conditions expand into the following formulas, respectively:

- $\forall s, s'. [(s \in P \land (s, s') \in R) \rightarrow s' \in Q]$ by [definition of a Hoare triple](#definition:hoare-triple)
- $\forall s.\ [s \in P \rightarrow (\forall s'.\ (s, s')\in r \rightarrow s' \in Q)]$, by [definition of the weakest postcondition](#definition:weakest-precondition) and definition of subset.
- $\forall s'.\ [(\exists s.\ s\in P \land (s, s') \in r) \rightarrow s' \in Q)]$ by [definition of the strongest postcondition](#definition:strongest-postcondition) and definition of subset.

From here on, we can prove equivalence using first-order logic properties:

- $(P \land Q \rightarrow R) \iff (P \rightarrow (Q \rightarrow R))$ 
- $(\forall u.\ (A \rightarrow B)) \iff (A \rightarrow \forall u.\ B)$ when $u\notin \text{FV}(A)$
- $(\forall u.\ (A \rightarrow B)) \iff ((\exists u. A) \rightarrow B)$ when $u\notin \text{FV}(B)$

$\qed$

#### Characterization
The above lemma also gives us a good intuitive grip of what wp and sp are: they're the best possible values for $P$ and $Q$, respectively. For the triple to hold, any other $P$ must be a subset of wp (i.e. stronger), and any other $Q$ must be a supserset of $Q$ (i.e. weaker). This leads us to the following characterization lemmas.

{% block lemma "Characterization of sp" %}
$\sp{P, r}$ is the smallest set $Q$ such that $\triple{P}{r}{Q}$, that is, the two following hold:

- $\triple{P}{r}{\sp{P, r}}$
- $\forall Q \subseteq S. \triple{P}{r}{Q} \rightarrow \sp{P, r}\subseteq Q$
{% endblock %}

The first condition immediately follows from the equivalence in the above lemma: it is equivalent to $\sp{P, r} \subseteq \sp{P, r}$. The second condition ensures that the strongest precondition is the smallest one (as it's a subset of all $Q\subseteq S$).

{% block lemma "Characterization of wp" %}
$\wp{r, Q}$ is the largest set $P$ such that $\triple{P}{r}{Q}$, that is, the two following hold:

- $\triple{\wp{r, Q}}{r}{Q}$
- $\forall P \subseteq S. \triple{P}{r}{Q} \rightarrow P \subseteq \wp{P, r}$
{% endblock %}

The reasoning is the same as above.

#### Duality
When [defining wp](#definition:weakest-precondition), we could see from the diagram that $\wp{r, Q}$ *almost* corresponded to going backwards from $Q$. And it is *almost*, because we must deal with the cases where values outside of $\wp{r, Q}$ point to $Q$ (which is possible when the relation is not injective). To deal with this, we don't look at $Q\bullet r^{-1}$, but at the complement set of "error states" $S \setminus Q$ (in brown in the diagram).

{% block lemma "Duality of postcondition-of-inverse and wp" %}
$S \setminus \wp{r, Q} = \sp{S\setminus Q, r^{-1}}$
{% endblock %}
 
Note that $r^{-1} = \set{(y, x) \mid (x, y) \in r}$ and is always defined.

To prove this lemma, we can expand both sides and apply basic first-order logic properties. We first prove it from the left-hand side:

$$\begin{align}
x \in S \setminus \wp{r, Q} 
& = x \notin \wp{r, Q} \\
& = \neg\left(\forall x'.\ (x, x') \in r \rightarrow x' \in Q\right) \\
& = \exists x'.\ (x, x') \in r \land x' \notin Q
\end{align}$$

Now on the right-hand side:

$$\begin{align}
x \in \sp{S \setminus Q, r^{-1}}
& = \exists x'.\ x' \notin Q \land (x', x) \in r^{-1} \\
& = \exists x'.\ x' \notin Q \land (x, x') \in r
\end{align}$$

As these are equal, we have proven equality. $\qed$

#### More laws
First, we'll state a lemma telling us that sp can be applied to each point of a set, or the the whole set, and we get the same results:

{% block lemma "Pointwise sp" %}
$$\sp{P, r} = \bigcup_{s \in P} \sp{\set{s}, r}$$
{% endblock %}

From this, it should be clear what the sp of unions is:

{% block lemma "Disjunctivity of sp" %}
$$\begin{align}
\sp{P_1 \cup P_2, r} & = \sp{P_1, r} \cup \sp{P_2, r} \\
\sp{P, r_1 \cup r_2} & = \sp{P, r_1} \cup \sp{P, r_2}
\end{align}$$
{% endblock %}

For wp, the wp can be obtained by selecting each point for which the sp is in $Q$. To understand this, remember that the sp is like the image, so we can select all points that only point to $Q$, which is the [intuitive explanation we had](#definition:weakest-precondition) for wp.

{% block lemma "Pointwise wp" %}
$$\wp{r, Q} = \set{s \mid s \in S \land \sp{\set{s}, r} \subseteq Q}$$
{% endblock %}

Likewise, this should give us an idea of how to deal with intersections of sets:

{% block lemma "Conjunctivity of wp" %}
$$\begin{align}
\wp{r, Q_1 \cap Q_2} & = \wp{r, Q_1} \cap \wp{r, Q_2} \\
\wp{r_1 \cup r_2, Q} & = \wp{r_1, Q} \cap \wp{r_2, Q}
\end{align}$$
{% endblock %}

All of these can be proven by expanding to formulas and using basic first-order logic.

### Hoare Logic for loop-free programs
By now, we've seen how to annotate a single relation, and how to reason about preconditions and postconditions. How do we scale this up to a whole program? Specifically, we'll need to reason over unions and compositions of relations. To do that, we'll introduce two theorems telling us how to do that.

Suppose the possible paths of a program are $J$, a set of relations.

{% block theorem "Expanding paths" %}
The condition:

$$\triple{P}{\bigcup_{i\in J} r_i}{Q}$$

is equivalent to:

$$\forall i.\ i\in J \rightarrow \triple{P}{r_i}{Q}$$
{% endblock %}

This simply says that to a triple is valid over a set of relations when it is valid over all relations in the set: it serves as a generalization when we're considering multiple possible paths.

To prove this, we can use the definitions to expand into formulas. Alternatively, we can use the previous lemmas:

$$\begin{align}
\triple{P}{\bigcup_{i\in J} r_i}{Q}
& = \sp{P, \bigcup_{i\in J} r_i} \subseteq Q \\
& = \left(\bigcup_{i\in J} \sp{P, r_i}\right) \subseteq Q \\
& = \forall i.\ i \in J. \rightarrow \sp{P, r_i} \subseteq Q \\
& = \forall i.\ i\in J \rightarrow \triple{P}{r_i}{Q}
\end{align}$$

The first step translates into the [third equivalent form](#lemma:three-forms-of-hoare-triple), and the second step uses [disjunctivity of sp](#lemma:disjunctivity-of-sp). The third step translates the union to a quantified formula, and the last step translates back the the [first equivalent form](#lemma:three-forms-of-hoare-triple). $\qed$

{% block theorem "Transitivity of Hoare triples" %}
If $\triple{P}{r_1}{Q}$ and $\triple{Q}{r_2}{R}$ then $\triple{P}{r_1 \circ r_2}{R}$. We can write this as the following inference rule:

$$
\frac{
  \triple{P}{r_1}{Q} \qquad \triple{Q}{r_2}{R}
}{
  \triple{P}{r_1 \circ r_2}{R}
}
$$
{% endblock %}

We won't go into too much detail for this theorem. The two theorems above tell us that if we can annotate Hoare triples for individual statements, we can annotate the whole program.

### Hoare logic for loops
For general loops, the simplest rule that we can have is the following. It says that if a single iteration of the loop doesn't change the precondition, then the whole loop doesn't change the precondition.

{% block lemma "Rule for non-deterministic loops" %}
$$\frac{\triple{P}{r}{P}}{\triple{P}{r^*}{P}}$$
{% endblock %}

This is obviously going to be true by transitivity, but let's prove it formally nonetheless. We can generalize the previous results to programs with loops. A special case of the [transitivity theorem of Hoare triples](#theorem:transitivity-of-hoare-triples) is when $r_1 = r_2$ and $P = Q = R$. In that case, we have:

$$\frac{\triple{P}{r}{P} \qquad \triple{P}{r}{P}}{\triple{P}{r^2}{P}}$$

We can keep applying the [transitivity rule](#theorem:transitivity-of-hoare-triples) to achieve a more general form:

$$\frac{\triple{P}{r}{P} \qquad n \ge 0}{\triple{P}{r^n}{P}}$$

By the [Expanding Paths condition](#theorem:expanding-paths), we then have:

$$\frac{\triple{P}{r}{P}}{\triple{P}{\bigcup_{n\ge 0} r^n}{P}}$$

Note that we have the [transitive closure](#definition:transitive-closure) in the denominator, $r^* = \bigcup_{n\ge 0} r^n$. $\qed$

### Hoare logic for loops with conditions
Also known as `while` loops. We did not previously define the relation for while loops like `while (b) { c }`, so let's do it now. 

Let $b_s$ be the set corresponding to the command `b`, and $(\neg b)_s$ be the set corresponding to the command `!b`. Recall the definition of [identity relation](#definition:identity-relation). Let $r = \rho(c)$ be the relation of the loop body. The relation of the while loop is:

$$
\rho(\text{while }(b)\ c) = (\Delta_{b_s} \circ r)^* \circ \Delta_{(\neg b)_s}
$$

The relation follows the $r$ relation an arbitrary number of times while the $b$ condition is true, and then finally the $b$ condition is false. This translates almost directly into the following rule:

{% block lemma "Rule for loop with condition" %}
For a `while (b) { c }` loop, we have:

$$
\frac{
  \triple{P\cap b_s}{r}{P}
}{\triple{P}{(\Delta_{b_s} \circ r)^* \circ \Delta_{(\neg b)_s}}{P\cap(\neg b)_s}}
$$

Restated with commands and conditions instead of relations and sets:

$$\frac{\triple{P\land b}{c}{P}}{\triple{P}{\text{while }(b)\ c}{P \land \neg b}}$$
{% endblock %}

We trivially have:

$$
\triple{P}{\Delta_{b_s}}{P \cap b_s} \\
\triple{P}{\Delta_{(\neg b)_s}}{P \cap (\neg b)_s}
$$

So by transitivity:

$$
\frac{
  \triple{P\cap b_s}{r}{P}
}{\set{P}\ \Delta_{b_s} \ \set{P \cap b_s}\ r \ \set{P}}
\equiv
\frac{\triple{P\cap b_s}{r}{P}}{\triple{P}{\Delta_{b_s} \circ r}{P}}
$$

From the [rule for non-deterministic loops](#lemma:rule-for-non-deterministic-loops), we have:

$$\frac{\triple{P}{\Delta_{b_s} \circ r}{P}}{\triple{P}{(\Delta_{b_s} \circ r)^*}{P}}$$

Applying these rules, we get the lemma. $\qed$

## Properties of program contexts
### Properties of relations
{% block lemma "Monotonicity over composition" %}
$$
\begin{align}
(r_1 \subseteq r_2) & \implies (r_1 \circ s) \subseteq (r_2 \circ s) \\
(r_1 \subseteq r_2) & \implies (s \circ r_1) \subseteq (s \circ r_2)
\end{align}
$$
{% endblock %}

{% block lemma "Monotonicity over union" %}
$$(r_1 \subseteq r_2) \land (s_1 \subseteq s_2) \implies (r_1 \cup s_1) \subseteq (r_2 \cup s_2)$$
{% endblock %}

{% block lemma "Union distributivity" %}
$$(r_1 \cup r_2) \circ s = (r_1 \circ s) \cup (r_2 \circ s)$$
{% endblock %}

### Properties of expressions
Expressions are functions that take relations, and construct a more complex relation from them. We'll only consider expressions that use union ($\cup$) and composition ($\circ$). An example of such an expression would be: 

$$E(r) = (b_1 \circ r)\cup (r\circ b_2)$$

We'll see two theorems stating that expressions are monotonic, and that they "sort of distribute" over union (meaning sometimes with equality, but always at least with $\subseteq$).

{% block theorem "Monotonicity of expressions using union and composition" %}
Let $S$ be the universe, and let $C = \set{r\mid r \subseteq S^2}$ be the set of all possible relations in $S$. Let $E: C \rightarrow C$ be any function building one relation from another, where $E(r)$ is built from:

- $r$,
- some additional constant expressions $b_1, \dots, b_n$,
- using $\cup$ and $\circ$. 

Such expressions $E$ are monotonic on $C$:

$$r_1 \subseteq r_2 \implies E(r_1) \subseteq E(r_2)$$
{% endblock %}

This theorem can be proven by induction on the expression tree defining $E$, using the monotonicity properties of $\cup$ and $\circ$ that we [have seen above](#properties-of-relations).

{% block theorem "Union &ldquo;distributivity&rdquo; of expressions in one direction" %}
Let $r_i$ with $i \in I$ be a family of relations. Then:

$$E\left(\bigcup_{i \in I} r_i \right) \supseteq \bigcup_{i \in I} E(r_i)$$
{% endblock %}

Let $s = \bigcup_{i\in I} r_i$. Note that $\forall i.\ r_i \subseteq s$. Since $E$ is monotonic, $\forall i.\ E(r_i) \subseteq E(s)$. Since all the $E(r_i)$ are included in $E(s)$, so is their union, so $\bigcup_{i \in I} E(r_i) \subseteq E(s)$. 

$\qed$

Note that we **do not have equality** and we therefore don't really have a real union distributivity! To see this, take $E(r) = r\circ r$, and consider the family of relations $I = \set{1, 2}$ where $r_1 = \set{(1, 2)}$ and $r_2 = \set{(2, 3)}$. In this case:

$$
\begin{align}
E\left(\bigcup_{i \in I} r_i \right) & = E(r_1 \cup r_2) = \set{(1, 3)} \\
\bigcup_{i \in I} E(r_i) & = E(r_1) \cup E(r_2) = \emptyset \\
\end{align}
$$

*However*, under some special assumptions on $E$, we actually have full, normal distributivity with equality:

{% block theorem "Refined union distributivity of expressions" %}
If $E$ satisfies one of the conditions below:

1. $E(r)$ contains $r$ at most once
2. $E(r)$ contains $r$ any number of times, but $I$ is a set of natural numbers and $r_i$ is an increasing sequence $r_1 \subseteq r_2 \subseteq \dots$
3. $E(r)$ contains $r$ any number of times, but $r_i, i \in I$ is a **directed family** of relations, meaning that for each $i, j$ there exists a $k$ such that $r_i \cup r_j \subseteq r_k$ (and $I$ is possibly uncountably infinite)

Then $E$ distributes over union:

$$E\left(\bigcup_{i \in I} r_i \right) = \bigcup_{i \in I} E(r_i)$$
{% endblock %}

The third case is actually a generalization of the second. With the increasing sequence, the $r_k$ can just be the bigger relation between $r_i$ and $r_j$. In this second case, $I$ can be finite or countably infinite, which is also less general than the third case.

All the proofs are done by induction, but we will not go into much detail on them.

## More on mapping programs to formulas
We've seen how to translate really basic constructs like conditions, while loops and assignment, but will now see some more advanced constructs that many real programming languages.

### Mutable local variables
When translating code into formulas, each statement is a relation between variables in scope. What happens if we introduce a variable in local scope? Suppose `x` and `z` are global variables, and we have a block introducing a local variable `y`:

{% highlight scala linenos %}
x = x + 1;
{
  var y;
  y = x + 3;
  z = x + y + z
};
x = x + z
{% endhighlight %}

The final formula should not depend on `y`. Therefore, we need to do some kind of local variable translation, which we can do with existential quantification.

Let's call the whole expression in brackets $P$. Inside $P$, we have variables $V = \set{x, y, z}$. Let $R_V(P)$ be the formula for $P$, containing variables $V$ in the scope. This is a refinement of the [previous definition](#translating-commands) of $R$, which only used the top-level scope $V$; here, we can give it a local scope.

The variable initialization in the bracket block can be translated into a formula by:

$$R_V(\set{\text{var } y; P}) = \exists y, y'.\ R_{V \cup \set{y}}(P)$$

This lets $y$ and $y'$ be unconstrained, and translates the rest of the block with $y$ now added into the scope $V$. This lets $y$ take any value in $P$. Note that the translation of this is quite similar to what `havoc` does. In fact, we can express `havoc` using these semantics:

$$
R_V(\text{havoc}(x)) \iff R_V(\set{\text{var } y; x = y})
$$

This equivalence will serve as a handy shorthand: when we initialize multiple variables, we can write it as:

$$
\text{havoc}(y_1, \dots, y_m)
\equiv 
\text{havoc}(y_1); \dots; \text{havoc}(y_m)
$$

Note that the order of havocs does not matter.

### Specifications
A specification (a.k.a. spec) is a formula that expresses some pre- and postconditions that the program should respect. Note that the spec is often more general than the strongest postcondition, but it could very well be the actual sp. 

There are three ways in which we can think of a spec; we give a translation of the same example for each:

- **Formula**: $(z' = z) \land (x' > 0) \land (y' > 0)$
- **Relation**: $\set{(x, y, z, x', y', z') \mid (z' = z) \land (x' > 0) \land (y' > 0)}$
- **Program**: `havoc(x, y); assume(x > 0 && y > 0)`

A program adheres to the spec if its relation is a subset of the spec's relation. 

Note that the above program representation lets $x$ and $y$ be unconstrained by the `havoc`, and constrains $x'$ and $y'$ through the `assume`. We get $z = z'$ by default, by not writing anything about $z$.

### Program refinement and equivalence
{% block definition "Refinement" %}
For two programs $P_1$ and $P_2$, we define *refinement* $P_1 \sqsubseteq P_2$ if and only if the following is a valid formula:

$$R(P_1) \rightarrow R(P_2)$$
{% endblock %}

We can define the operator in the other direction in the obvious manner:

$$P_2 \sqsupseteq P_1 \iff P_1 \sqsubseteq P_2$$

Note that this is nothing more than a new notation for relation subset, since:

$$P_1 \sqsubseteq P_2 \iff \rho(P_1) \subseteq \rho(P_2)$$

{% block definition "Equivalence" %}
We define *equivalence* of two programs $P_1$ and $P_2$ as: 

$$P_1 \equiv P_2 \iff P_1 \sqsubseteq P_2 \land P_2 \sqsubseteq P_1$$
{% endblock %}

From the above comment, we can see that this is just new notation for relation equality, since:

$$P_1 \equiv P_2 \iff \rho(P_1) = \rho(P_2)$$

{% block theorem "Monotonicity of refinement over sequences and if-statements" %}
$$\begin{align}
P_1 \sqsubseteq P_2 & \implies (P_1; P) \sqsubseteq (P_2; P) \\
P_1 \sqsubseteq P_2 & \implies (P; P_1) \sqsubseteq (P; P_2) \\
(P_1 \sqsubseteq P_2) \land (Q_1 \sqsubseteq Q_2) & \implies
  (\text{if } (*) \ P_1 \text{ else } P_2) \sqsubseteq
  (\text{if } (*) \ Q_1 \text{ else } Q_2) \\
\end{align}$$
{% endblock %}

This follows directly from our lemmas of [monotonicity of relations over composition](#lemma:monotonicity-over-composition) and [monotonicity over union](#lemma:monotonicity-over-union). $\qed$

### Stepwise refinement
Why is this notion of refinement useful? It allows us to model one possible execution of very general, possibly non-deterministic program. We can do this by refining the program in steps, until it becomes deterministic, simple, efficiently executable:

$$P_0 \sqsupseteq P_1 \sqsupseteq \dots \sqsupseteq P_n$$

### Loops, revisited
Let's examine the following program $L$, which has variables $V = \set{x, y}$:

{% highlight scala linenos %}
while (x > 0) {
  x = x - y
}
{% endhighlight %}

We're interested in finding the smallest relation $\rho(L)$ between initial state $(x, y)$ and final state $(x', y')$. Let $k$ be the number of time the loop executes. We can see that there are two different cases here: 

- When $k = 0$, we never enter the loop because the initial $x$ did not satisfy the loop condition; therefore, all variables are kept the same
- When $k > 0$, we enter the loop, and decrement $x$ by $y$ $k$ times, and finally the loop condition no longer holds.

This leads us to the following formulas:

$$
\begin{align}
k = 0 & \implies R(L) = (x \le 0) \land (x' = x) \land (y' = y) \\
k = 1 & \implies R(L) = (x > 0) \land (x' = x - y) \land (y' = y) \land (x' \le 0) \\
      & \vdots \\
k > 0 & \implies R(L) = (x > 0) \land (x' = x - ky) \land (y' = y) \land (x' \le 0) \\
\end{align}
$$

To find a formula that fits both the $k=0$ and $k>0$ cases, we can take the disjunction of the two. For $k > 0$, there will be a single value of $k$ at runtime, so we existentially quantify to express that:

$$
\begin{align}
R(L) = & [(x \le 0) \land (x' = x) \land (y' = y)] \\
       & \lor [\exists k.\ (k > 0) \land (x > 0) \land (x' = x - ky) \land (y' = y) \land (x' \le 0)]
\end{align}
$$

This existential quantifier is annoying, and we will see later how to apply to one-point rule to eliminate it. (TODO, note that the bar in the slides is notation for "y divides ...")

### Fixpoints
Before we see how to translate recursive functions, we need a bit of theory on fixpoints:

{% block definition "Fixpoint" %}
$s\in C$ is a **fixpoint** of $E: C\rightarrow C$ if $E(s) = s$
{% endblock %}

This is analogous to what exists on real function: the fixpoints of $f(x) = x^2 - x - 3$ are $x_1 = -1$ and $x_2 = 3$.

We are often interested in the fixpoint that is smaller than all others, which we call the **least fixpoint**. In the example on the polynomial, it would be $x_1 = -1$. For relations, we're looking for the fixpoint that is $\subseteq$ of all other fixpoints.

### Recursion
A recursive function will result in a recursive relation; say that we're translating the following function `f` into a relation:

{% highlight scala linenos %}
def f() = if (x > 0) {
    x = x -1;
    f();
    y = y + 2
} else { }
{% endhighlight %}

We know how to translate most of these constructs, but what postconditions can we assume on the recursive call? We're not done inferring postconditions on the body, so we don't know what the final result should be. The solution to find a relation $s$ for $f$ such that $E(s) = s$.

For now, let's suppose $s$ has this property, and leave it as a variable. Translating the above function `f`, we get:

$$
E(s) = [
  \Delta_{(x > 0)_s} \circ 
  (\rho(x = x - 1) \circ s \circ \rho(y = y + 2))
] \cup \Delta_{(x \le 0)_s}
$$

Here, the subscript s means "the set corresponding to this formula". We'll how to find this relation $s$:

{% block theorem "Relation for recursion" %}
Let $E(s)$ be the expression translating the body of a recursive function, where $s$ is the relation of the recursive call. Let $s$ be defined as follows:

$$s = \bigcup_{k \ge 0} E^k(\emptyset)$$

where $E^0(\emptyset) = \emptyset$. The relation $s$ is the least fixpoint of $E$, and $E(s)$ is the relation corresponding to the recursive function.
{% endblock %}

We'll prove that $s$ is indeed a fixpoint of $E$. Note that, according to the [theorem of monotonicity of expressions using union and composition](#theorem:monotonicity-of-expressions-using-union-and-composition), $E$ is monotonic. This fact means that we actually satisfy the [second condition of union-distributivity](#theorem:refined-union-distributivity-of-expressions) of $E$. To see this, pick $r_0, r_1, \dots, r_k$ as follows:

- $r_0 = \emptyset$
- $r_1 = E(r_0) = E(\emptyset)$
- ...
- $r_k = E^k(\emptyset)$

We indeed have $r_0 \subseteq r_1 \subseteq \dots \subseteq r_k$ by monotonicity of $E$. Therefore, $E$ distributes over union. Having union-distributivity will be crucial in finding a relation $s$ such that $E(s) = s$. Indeed, we can pick $s$ as follows:

$$s = \bigcup_{k \ge 0} r_k$$

With union-distributivity, we can show that this choice of $s$ satisfies $E(s) = s$:

$$
E(s) 
= E\left(\bigcup_{k \ge 0} r_k \right)
\overset{(1)}{=} \bigcup_{k \ge 0} E(r_k)
= \bigcup_{k \ge 0} r_{k+1}
= \bigcup_{k \ge 1} r_k
= \emptyset \cup \bigcup_{k \ge 1} r_k
= s
$$

The step $(1)$ is the one that needs the union-distributivity property. 

$\qed$

Let's follow this up with a proof that $s$ is the least fixpoint. We obtained $s$ by solving $E(s) = s$; now, suppose $r$ is an arbitrary relation such that $E(r) \subseteq r$. Note that $s$ does satisfies this condition. We now claim that $s \subseteq r$, i.e. that it is the smallest. If we expand $s$ to its definition, we'll see that we need to prove:

$$\bigcup_{k\ge 0} E^k(\emptyset) \subseteq r$$

If we can show $E^k(\emptyset) \subseteq r$ for every $k$, we'll have proven this. This can be done by induction: the base case is $\emptyset \subseteq r$, which is trivially true. The induction step is by monotonicity of $E$:

$$
E^k(\emptyset) \subseteq r
\overset{(1)}{\implies}
E(E^k(\emptyset)) \subseteq E(r) 
\overset{(2)}{\implies}
E(E^k(\emptyset)) \subseteq r
$$

Step $(1)$ is by monotonicity of $E$, and step $(2)$ is by the original assumption of $E(r) \subseteq r$.

$\qed$

Note that this second proof is actually stronger than we strictly need it to be: not only did we prove that $s$ is the least fixpoint (smaller than any $r$ such that $E(r) = r$), we proved that $s$ is also smaller than any other $r$ such that $E(r) \subseteq r$. We'll see some vocabulary for this later (todo link), with which we can say that $s$ is the least postfix point.

This model has the advantage of being simple, but also has limitations; for one, it translates programs that never terminate in the same way as programs that do. Therefore, the correct semantics of the translation is that it only applies to terminating executions. The alternative would be error states for non-termination, but we won't look into that.

### Specification of recursive functions
In the previous section, we had $E(r) \subseteq r$. Let's think about what that means, from a more intuitive perspective. It means that when we plug $r$ into $E$, we get something that conforms to the $r$ spec. This is exactly what we wanted in the first place: finding a translation of a recursive call that also satisfies the spec for the function itself.

Now, suppose that we want to check a user-defined specification $q$:

$$q = \set{\seq{\seq{x, y}, \seq{x', y'}} \mid y' \ge y}$$

As for any spec, we need to check that the relation of the program is a subset of the spec, $s \subseteq q$. This is actually equivalent to proving $E(q) \subseteq q$.

### Mutual recursion
Suppose we have two mutually recursive procedures $r_1 = E_1(r_1, r_2)$ and $r_2 = E_2(r_1, r_2)$. We can extend the previous approach to work on pairs. We define $\vec{E}(r_1, r_2) = \seq{E_1(r_1, r_2), E_2(r_1, r_2)}$ and $\vec{r} = (r_1, r_2)$. We want to find a pair of relations $\vec{r}$ such that:

$$\vec{E}(\vec{r}) = \vec{r}$$

In order to do this, we introduce the a partial ordering (more on this later, todo link), where $(r_1, r_2) \sqsubseteq (r_1', r_2')$ means $r_1 \subseteq r_1'$ and $r_2 \subseteq r_2'$. This will allow us to express [refinements](#definition:refinement).

Pairs aren't sets, but we can define set-like operations on them by applying the operation to both members of the pair. We denote these operations using the square variant of the set operation in question. For instance:

$$(r_1, r_2) \sqcup (r_1', r_2') = (r_1 \cup r_1', r_2 \cup r_2')$$

The entire theory is preserved as long as we have a partial order $\sqsubseteq$ with some "good properties" (i.e. lattice elements are a generalization of sets), so this extension can be done without too much extra work.

To find the least fixpoint, the semantics are now:

$$(s_1, s_2) = \bigsqcup_{i\ge 0} \vec{E}^i(\emptyset, \emptyset)$$

As before, we can prove that if we consider any relations $c_1, c_2$ such that $E_1(c_1, c_2) \subseteq c_1$ and $E_2(c_1, c_2) \subseteq c_2$ then $\vec{s}$ is the least fixpoint, meaning $s_1 \subseteq c_1$ and $s_2 \subseteq c_2$.

## Quantifier elimination in Presburger arithmetic
### Quantifier elimination
{% block definition "Quantifier elimination" %}
Given a formula $F(\vec{y})$, the goal of quantifier elimination (QE) is to find a formula $G(\vec{y})$ that:

- is [equivalent](#definition:equivalence) to $F(\vec{y})$
- has no quantifiers
- has $\text{FV}(G)\subseteq\text{FV}(F)$
{% endblock %}

Generally, given an assignment $\vec{y}$, it's easier to check the truth value of $G(\vec{y})$ because it has no quantifiers. 

The third above condition may prompt an interesting question; what if $F$ has no free variables, for instance because they're all bound by quantifiers? The condition still holds, so $G$ would have no variables at all, it would simply be a constant expression, which we can immediately verify the truth of it.

This also means that we can check satisfiability and validity of $H(\vec{y})$ by: 

- **Satisfiability**: do QE on $\exists \vec{y}.\ H(\vec{y})$ and evaluate
- **Validity**: do QE on $\forall \vec{y}.\ H(\vec{y})$ and evaluate

### Presburger arithmetic
Let's talk about how to use what we've discussed in order to verify programs. We can do this in three steps:

1. Compile programs to logical formulas
2. Express properties in logic or code
3. Use an automated theorem prover for generated conditions (SAT, SMT, rewrite, interactive provers)

Which logic should we use? We'll look into integer linear arithmetic, also known as Presburger arithmetic.

This is integer arithmetic with logical operations ($\land, \lor, \neg$), quantifiers ($\forall, \exists$), addition ($+$), and comparison ($<, =$). This is one of the earliest theories that was shown to be decidable[^presburger-backstory].

[^presburger-backstory]: The story goes that Presburger solved this in his MSc thesis with Tarski in 1929, but that Tarski was not impressed.

We'll see that we can [extend Presburger arithmetic](#making-presburger-arithmetic-admit-qe) to admit quantifier elimination (QE): this is not a trivial result, as not all theories admit QE. The reason for which we want to do QE in the first place is that formulas are hard to decide when they have formulas. A Presburger arithmetic formula of size $n$ with $m$ quantifiers is decidable by a single-tape alternating Turing machine in time $2^{n^{O(m)}}$. This is very sensitive to the value of $m$.

Another reason to do QE is to remove quantifiers from interpolants, which is useful in generalizing counterexamples to invariants. Note that **if a logic has QE, it also has quantifier-free interpolants**.

### One-point rule
The one-point rule is one of the many steps used in quantifier elimination procedures. Note that it is not enough on its own, because it only handles equalities, and not inequalities .

{% block theorem "One-point rule" %}
If $\vec{y}$ is a tuple of variables not containing $x$, then:

$$\exists x.\ (x = t(\vec{y}) \land F(x, \vec{y})) \iff F(t(\vec{y}), \vec{y})$$
{% endblock %}

This rule should make intuitive sense; it's somewhat akin to inlining (in the $\Rightarrow$ direction) or extracting to a variable (in the $\Leftarrow$ direction). In the $\Rightarrow$ direction, we say that we apply the **one-point rule**, and in the $\Leftarrow$ direction we call it **flattening**.

We can also state the dual of this rule, which is the negated version of this statement

{% block theorem "Dual one-point rule" %}
$$\forall x.\ (x = t(\vec{y}) \rightarrow F(x, \vec{y})) \iff F(t(\vec{y}), \vec{y})$$
{% endblock %}

The proof for this is easy; we negate both sides and see that it reduces to the rule for $\exists$:

$$
\exists x.\ (x = t(\vec{y}) \land \neg F(x, \vec{y})) 
\iff \neg F(t(\vec{y}), \vec{y})
\qed
$$

### Making Presburger arithmetic admit QE
As is, Presburger arithmetic (PA) does not admit QE. If we lack some operations that can be expressed with quantifiers, there may be no equivalent without quantifiers. For instance, we can state divisibility by 3 in PA as follows:

$$\exists y.\ x = y + y + y$$

This indicates to us that we need a divisibility operator (e.g. $3 \divides x$), because in order to do QE we must have a quantifier-free equisatisfiable variant of the above formula. We will therefore extend PA with the following, where we always have $K \in \mathbb{Z}$.

- Comparison $x < y$
- Subtraction $x - y$
- Divisibility $K \divides y$
- Multiplication by a constant factor $K \cdot x$ (this is just shorthand for very long additions)

The resulting language has operators $\set{+, -, =, <, \divides, \cdot}$ on numbers and variables, and $\set{\land, \lor, \neg, \rightarrow, \exists, \forall}$ on atomic formulas.

### Normalized Presburger arithmetic
To normalize terms in PA, we can rearrange each term to be of the form: 

$$K_0 + \sum_{i=1}^n K_i x_i$$

A term in this form is called a *linear term*. To normalize literals in PA, we do the following translation:

$$
\begin{align}
\neg(t_1 < t_2) & \rightsquigarrow t_2 < t_1 + 1 \\
\neg(t_1 = t_2) & \rightsquigarrow (t_1 < t_2) \lor (t_2 < t_1) \\
t_1 = t_2       & \rightsquigarrow (t_1 < t_2 + 1) \land (t_2 < t_1 + 1) \\
\neg(K \divides t) & \rightsquigarrow \biglor_{i=1}^{K-1} K\divides t+i \\
t_1 < t_2       & \rightsquigarrow 0 < t_2 - t_1
\end{align}
$$

This generates some disjunctions and conjunctions, but we can convert back to DNF again.

### Eliminating existential quantifiers
Let's see how to eliminate $\exists$ from the following, where $F$ is quantifier-free:

$$\exists x.\ F(x, \vec{y})$$

To do that, we can convert $F$ to disjunctive normal form, a disjunction of clauses $C_i$, each of which is a conjunction of literals.

$$F \iff \biglor_{i=1}^m C_i$$

The elimination is then done by:

$$
\exists x.\ F \iff 
\left(\exists x.\ \biglor_{i=1}^m C_i \right) \iff
\biglor_{i=1}^m \exists x.\ C_i
$$

### Eliminating universal quantifiers
Suppose $F_0(x, \vec{y})$ is quantifier-free, and we want to eliminate $\forall$ from the following formula:

$$\forall x.\ F_0(x, \vec{y})$$

This is equivalent to:

$$\forall x.\ F_0(x, \vec{y}) \iff \neg(\exists x.\ \neg F_0(x, \vec{y}))$$

We know how to handle this right-hand side: we can [eliminate the existential quantifier](#eliminating-existential-quantifiers) in $\exists x.\ \neg F_0(x, \vec{y})$ to obtain $F_1(\vec{y})$. The result of elimination is therefore:

$$\neg F_1(\vec{y})$$

### Exposing the variable to eliminate
Sometimes, we want to do QE of a quantified variable $y$, but $y$ appears in a multiplied in the formula, or with bounds.

#### Multiplication
For comparison and "divides" terms, we can rely on the following observations, for $c \in \mathbb{N}^+$:

- $0 < t \equiv 0 < ct$
- $K \divides t \equiv ck \divides cT$

Let $K_1, \dots, K_n$ be the coefficients next to $y$; we choose $M = \text{lcm}(K_1, \dots, K_n)$. Then, to ensure coefficient 1, we multiply all literals by $M/\abs{K_i}$ to obtain multiples $M$ or $-M$ (as in the example above, in which $M = 30$). Then, we let $x = My$ and solve:

$$\exists x.\ F(x) \land (M \divides x)$$

As an example of this, let's consider the following formula:

$$
\exists y.\ 
  (0 < -w + 3y + 1) \land
  (0 < -2y + z + 6) \land 
  4\divides (5y + 1)
$$

In this case, the we can take the least common multiple (lcm) of the coefficients of $y$:

$$M = \text{lcm}(3, 2, 5) = 30$$

We now make all occurrences of $y$ by have coefficient $M$ (but preserving mathematical equivalence, so we need to update other coefficients too):

$$
\exists y.\ 
  (0 < -10w + 30y + 10) \land
  (0 < -30y + 15z + 90) \land 
  (24\divides (30y + 6))
$$

Let $x$ denote $30y$. Note that this is not an arbitrary $x$, it must be divisible by 30, so we add a condition for that at the end. The formula is now:

$$
\exists x.\ 
  (0 < -10w + x + 10) \land
  (0 < -x + 15z + 90) \land 
  (24\divides (x + 6)) \land
  (30 \divides x)
$$

#### Bounds
Let's focus on a single variable $x$. We can reorganize the formula in terms of $x$ to fit the following form, so that there are $L$ lower bounds on $x$, and $U$ upper bounds, and $D$ divisibility constraints. We call this form $F_1(x)$:

$$
F_1(x) =
\left( \bigland_{i=1}^L a_i < x \right) \land
\left( \bigland_{j=1}^U x < b_j \right) \land
\left( \bigland_{i=1}^D K_i \mid (x + t_i) \right)
$$

If there are no divisibility constraints ($D = 0$), then the formula can be rewritten as:

$$F_1(x) \equiv (\max_i a_i + 1 \le \min_j b_j - 1)$$

The min and the max are not something that we can express directly in PA, but we can convert that into the following equivalent form:

$$
F_1(x) \equiv
(\max_i a_i + 1 \le \min_j b_j - 1) \equiv
\bigland_{i, j} a_i + 1 < b_j
$$

Alternatively, we can express this as follows, where $t_k$ does not contain $x$ (after all, our goal is to eliminate $x$):

$$F_1(x) \equiv \biglor_k F_1(t_k)$$

Let's see a few instances of this, depending on the values of $L$, $U$ and $D$:

- $D = 0$ and $L > 0$:
  
  $$F_1(x) \equiv \biglor_{k=1}^L F_1(a_k + 1)$$

  At least one of the terms in $\biglor$ will evaluate to $\max a_i + 1$, so this is valid.

- $D > 0$:
  
  $$\biglor_{k=1}^L \biglor_{i = 1}^N F_1(a_k + i)$$

  where $N = \text{lcm}(K_1, \dots, K_D)$. This works because if $F_1(u)$ holds, then $F_1(u-N)$ holds too.

- $L = 0$:

  $$\biglor_{x=1}^N \bigland_{i=1}^D K_i \divides (x+t_i)$$

### Generalization of Presburger arithmetic
Let's consider a generalization of Presburger logic: first-order formulas with equality and comparison, interpreted over *rationals* instead of integers. This is called **dense linear order without endpoints**. The solution for QE is actually simpler than for PA, because there are no divisibility constraints.

{% comment %}

## Satisfiability Modulo Theories
We have [discussed how SAT solvers work](#sat-algorithms-for-cnf). Let's see how we can use a SAT solver to determine the satisfiability of a quantifier-free (QF) formula. 

Let's consider formula $F \equiv p \lor (q \land r))$. A SAT solver can give us an assignment for this ($p=1$ and $q, r$ are anything, for instance). Now, let's consider a more complex formula:

$$
\begin{align}
G & \equiv (x < y + 1) \lor ((y < x) \land (x < 0)) \\
  & \equiv F[p := (x < y+1), q := (y<x), r := (x < 0)]
\end{align}
$$

The SAT solver can give us values of $p, q, r$. We have the following theorem:

{% block theorem "Satisfiability of QF formulas using SAT" %}
$G$ is satisfiable $\iff$ there is an assignment for $p, q, r$ that satisfies $F$
{% endblock %}

This result generalizes to any $G$ that can be described in terms of $F$ as above. 

Let's consider another example:

$$
1 \le x \land 
x \le 2 \land
f(x) \ne f(1)
$$

This is not true for every $f$, but we can pick $f$ to be whatever we want. In this case, this is satisfiable with $x = 2$ (and $f(x) = x$). Note that we usually constrain $x$ to be integer, so we only need to consider the cases of $x=1$ and $x=2$ in this example.

Internally, an SMT solver uses a SAT solver. A simple implementation is to give a name to each subterm, by introducing a propositional variable for each atomic formula. In our first example, we can rewrite the formula as $p \land (\neg q \lor r) \land \neg s$. The SAT solver can give us assignments for $p, q, r, s$ that we can use as a starting point to try to solve the formula.

Then, we have two theory solvers that solve equalities between uninterpreted functions, and between linear integer arithmetic. Let's look into those.

### Theory of uninterpreted function symbols
This solver works on quantifier-free first-order logic with equality. The key inference rule is:

$$
\frac{t_1 = t_1' \quad \dots \quad t_n = t_n'}
     {f(t_1, \dots, t_n) = f(t_1', \dots, t_n')}
$$

This rule also applies backwards (this allows us to encode algebraic data types! If we view $f$ as a `case class` constructor, and the arguments are the same, then the constructed `case class`es are equal). Other rules are that $=$ is an equivalence relation, and $t \ne t$ is contradictory.

The implementation can be done as an E-graph storing congruence relations computed so far. Applying a rule is merging nodes in the graph; this can be done efficiently using a [union-find data structure](/algorithms/#data-structures-for-disjoint-sets). The algorithm is known as the **congruence closure algorithm**. Let's look at an example:

$$
(f^3(a) = a) \land (f^5(a) = a) \land (f^2(a) \ne a)
$$

Where $f^n$ represents $n$ applications of $f$. Because $f^3(a) = a$, we can conclude that $f^4(a) = f(a)$ and $f^5(a) = f^2(a)$. Merging those nodes in the union-find shows us a conflict: $f^5(a) = a$ but this implies $f^5(a) = f^2(a) = a$, which is a conflict. However, we can check the negated equalities to see if this creates conflicts. In this case, there is a conflict, as we were supposed to have $f^2(a) \ne a$.

In general, the conjunction is satisfiable *if and only if* there is a literal $t_1 \ne t_2$ where $t_1$ and $t_2$ have been merged, so this algorithm is correct.

## Return of bounded model checking
### Bounded-model checking of a program
For each program, there is a monotonic, [Lipschitz $\omega$-continuous](https://en.wikipedia.org/wiki/Modulus_of_continuity) function $F: C^n \rightarrow C^n$ such that the following describes the set of reachable states for each program point.

$$\vec{c_*} = \bigcup_{i\ge 0} F^i(\emptyset, \dots, \emptyset)$$

This function starts with the empty set so that we start from the smallest possible set. Verification means that we check whether this is a subset of the set of "good states" $G$. This is equivalent to asking:

$$\forall n.\ F^n(\emptyset, \dots, \emptyset)$$

We can also ask the opposite question, i.e.:

$$\exists k\in\mathbb{N}, \vec{c}\in C^n.\ F^k(\emptyset, \dots, \emptyset) \land \vec{c} \notin G$$

For a fixed $k$, we can do quantifier elimination on this. This will allow us to formulate a bounded model checking algorithm. As usual, we check 

{% highlight scala linenos %}
B = Set.empty
while (true) {
  checksat(!(B subseteq G)) match {
    case Assignment(v) => return CounterExample(v)
    case Unsat =>
      B2 = F(B)
      if (B2 subseteq B) return Valid // fixed point
      else B = B2
  }
}
{% endhighlight %}

Here, we have denote the program as `F`, the current set of reachable states as `B`, and the good states as `G`. As `k` increases, it may become harder and harder to run `checksat`; for a large $k$ the formula for $F^k$ becomes so large that deep bugs are hard to find. Still, in practice, for a buggy program, it allows us to very quickly find a counter-example for a small `k`.

### k-Induction
A problem with the above approach is that bounded model checking may check many values of $k$ for otherwise simple instructions. For instance, consider the following (very common) case of initializing a large array:

{% highlight scala linenos %}
var i = 0
var z = 0
while (i < 1000) {
  a(i) = 0
}
var y = 1/z
{% endhighlight %}

Suppose we want to check a property that does not depend on $i$ (for instance, we may want to check that $z \ne 0$ at the end as to ensure that the division works). Here, bounded model checking would need to check the large loop even though the condition is unrelated to $i$.

Remember that our goal was to prove $\forall n.\ F^n(\emptyset, \dots, \emptyset)$. Suppose that this is the case. In particular, for some $k \ge 1$, we have $F^k \subseteq G$. By induction, for every $p \ge 1$ we have:

$$F^{pk}(G) \subseteq G$$

Because we specified that $F$ is monotonic, if $n \le pk$ then:

$$
F^n(\vec{\emptyset}) 
\subseteq F^{pk}(\vec{\emptyset})
\subseteq F^{pk}(G)
\subseteq G
$$

## Abstract interpretation
This is a method for discovering loop invariants. It's a way of inferring properties of program computations.

It's called abstract interpretation because it works much like regular interpretation, but instead of working with values, it works with sets of values. The idea is to evaluate arithmetic as set arithmetic. Sometimes, we may not be able to derive the exact interval, but we can always find an interval that contains the results by taking $]-\infty, +\infty[$ (or `MIN_INT` to `MAX_INT`).

The goal of abstract interpretation is to soundly approximate the semantics of a computer program, by modeling the concrete world into a simpler abstract world. In the image below, the idea is to have a $A$ be a smaller set than $C$, and to be able to translate between them using $\alpha$ (abstraction) and $\gamma$ (concretisation? todo find on Wiki)

Todo paste nice picture

In this chapter, we'll see a bunch of various topics, and bring it all together to see how abstract interpretation is done.

### Least fixpoint
Suppose we want to model a program $F$ (mapping from one set of states to the next). The idea is to model the execution from a starting state to a least fixpoint of $F$ (which we write $\text{lfp}(F)$, but doing so in fewer steps than the real program would go through by generalizing things.

{% block definition "Least fixpoint" %}
$$\text{lfp}(F) = \bigcup_{i=0}^\infty F^i(\emptyset)$$
{% endblock %}

We're given a specification $s$, which describes some set of "good states". Our goal is to prove $\text{lfp}(F)\subseteq s$, which we can do by cases:

- If $F(s) \subseteq s$ then $\text{lfp}(F) \subseteq s$ and we are done
- $\text{lfp}(F) = \bigcup_{i=0}^\infty F^i(\emptyset)$ but that is too hard to compute because this infinite (unless we get lucky and there exists an $n$ for which $F^{n+1}(\emptyset) = F^n(\emptyset)$).

So this turns out to be hard. If we relax our goal a little, we can find an [inductive strengthening](#definition:inductive-strengthening) $s'$ of $s$. As we established, it's hard work computing $F$, so we can simplify by taking some simpler function $F_\text{\#}$, which functions as an approximation of $F$:

$$F(r) \subseteq F_\text{\#}(r), \quad \forall r$$

We'll try to take an $F_\text{\#}$ such that $F_\text{\#}(s') \subseteq s'$; with the above subset relation, we would then have $F(s') \subseteq s'$.

### Control flow analysis
Done as in Advanced Compiler Construction, starting with empty set and applying a function until a fixpoint is reached.

### Partial order
A Hasse diagram presents a partial ordering some elements. An edge tells us which set is a subset of which other set. The direction of the edge is given by which node is above. The transitive and reflexive edges aren't drawn (but can be derived).

Note that in a partial ordering, the nodes on the same level aren't ordered!

We can define the following terms to navigate around the lattice:

- **Upper bound**
- **Lower bound**
- **Minimal element**
- **Maximal element**
- **Greatest element**
- **Least element**
- **Least upper bound** (a.k.a lub, supremum, join, $\sqcup$)
- **Greatest lower bound** (a.k.a glb, infimum, meet, $\sqcap$)

Note that the lub of a set $S$ can actually belong to $S$ (e.g. take a set of a single element: the lub is the element itself). The lub must be unique; there cannot be two possible lubs. Also note that lub is associative, commutative, idempotent.[^also-glb]

[^also-glb]: This whole paragraph also applies to the glb, the dual of the lub.

Looking at open intervals on reals, $(0, 1)$ has no maximal or greatest elements. Its lub is 1.

### Lattice
{% block definition "Lattice" %}
A lattice is a partial order in which every two-element set has a lub and a glb.
{% endblock %}

We generally define a lattice as $(A, \sqsubseteq)$ where:

- $A$ is the alphabet
- elements of the lattice are from $2^A$, the powerset of $A$
- $\sqsubseteq$ is the operator that compares elements[^subset-operator-notation]

[^subset-operator-notation]: Here, I used $\sqsubseteq$ as a generic "less-than" operator. It represents whatever concrete operator is used for a specific lattice. To use a specific operator, say, $\supseteq$, we write $(A, \supseteq)$ to say that the comparison between two elements is done by it (i.e. $a \sqsubseteq b \iff a \supseteq b$).

By induction, this implies the more general lemma:

{% block lemma %}
> In a lattice every non-empty finite set has a lub and a glb.
{% endblock %}

An example of a lattice is a linear ordering, for which:

$$\forall x, y.\ (x \le y \lor y \le x)$$

Indeed, either $x$ or $y$ is the lub.

{% block definition "Complete lattice" %}
A lattice $(A, \sqsubseteq)$ is complete if every subset of $A$ has a lub and a glb:

$$\forall S \subseteq A.\ \exists \sqcap S, \sqcup S$$
{% endblock %}

### Tarski's fixed point theorem
Let $(A, \sqsubseteq)$ be a complete lattice, and $G: A \rightarrow A$ be a monotonic function. We define $\text{Post}$ as the set of postfix points of $xG$, $\text{Pre}$ as the set of prefix points of $G$, and $\text{Fix}$ as the set of fixed points of $G$

$$\begin{align}
\text{Post} & = \set{x \mid G(x) \sqsubseteq x} \\
\text{Pre}  & = \set{x \mid x \sqsubseteq G(x)} \\
\text{Post} & = \set{x \mid G(x) = x} \\
\end{align}$$

{% block theorem "Tarski's Fixed Point theorem" %}
Let $a = \sqcap \text{Post}$ Then $a$ is the least element of $\text{Fix}$. Dually, $\sqcup \text{Pre}$ is the largest element of $\text{Fix}$.
{% endblock %}

Let's prove this. Let $x \in \text{Post}$:

- Since $G$ is monotonic and $a\sqsubseteq x$ so $G(a) \sqsubseteq G(x) \sqsubseteq x$
- Therefore, $G(a)$ is a lower bound on $\text{Post}$ but $a$ is the greatest lower bound so $G(a) \sqsubseteq a$
- Therefore $a \in \text{Post}$
- todo

$\qed$

Tarski's Fixed Point theorem shows that in a complete lattice with a monotonic function $G$ on this lattice, there is at least one fixed point of $G$, namely $\sqcap\text{Post}$. 

It also guarantees that fixpoints exist in complete lattices, but this proof does not say how to find them. How difficult it is depends on the structure of the lattice.

{% block lemma %}
Let $G$ be a monotonic function on a lattice. Let $a_0 = \bot$ and $a_{n+1}= G(a_n)$. Let $a_* = todo$
{% endblock %}

### Omega continuity
{% block definition "Omega continuity" %}
A function $G$ is $\omega$-continuous if for every chain $x_0 \sqsubseteq x_1 \sqsubseteq x_2 \sqsubseteq \dots$ we have:

$$G\left(\bigsqcup_{i\ge 0} x_i \right) = \bigsqcup_{i \ge 0} G(x_i)$$
{% endblock %}

Todo what's the intuition here? This looks a lot like the theorem in section 12.

{% block lemma %}
For an $\omega$-continuous function $G$, the value $a_* = \bigsqcup_{n \ge 0} G^n(\bot)$ is the least fixpoint of $G$.
{% endblock %}

### Galois connection
{% block definition "Galois connection" %}
A galois connection is defined by two monotonic functions $\alpha: C \rightarrow A$ and $\gamma: A \rightarrow C$ between partial orders $\le$ on $C$ and $\sqsubseteq$ on $A$, such that:

$$\forall c, a.\ \alpha(c) \sqsubseteq a \iff c \le \gamma(a)$$
{% endblock %}

Intuitively, this tells us that $c$ is approximated by $a$.

{% block lemma %}
The condition of the Galois connection hold iff the conjunction of these two conditions holds:

$$\begin{align}
\forall c.\  & c                 & \le \         & \gamma(\alpha(c)) \\
\forall a.\  & \alpha(\gamma(a)) & \sqsubseteq \ & a \\
\end{align}$$
{% endblock %}

As a small bonus lemma, we can state that the following three conditions are equivalent:

- $\forall a.\ \alpha(\gamma(a)) = a$
- $\alpha$ is surjective
- $\gamma$ is injective

### Bringing it all together
We're given a control-flow graph $(V, E, r)$ where:

- $V = \set{v_1, \dots, v_n}$ is a set of program points
- $E \subseteq V \times V$ are the edges
- $r: E \rightarrow 2^{S \times S}$ is a relation that "describes the meaning?"

(we skipped a whole bunch of slides here, and went straight to predicate abstraction).


### Predicate abstraction
We have a set of predicates $\mathcal{P} = \set{P_0, P_1, P_2, P_3}$, which is our vocabulary to describe the state[^predicates-in-practice]: we cannot come up with new predicates. We'll assume we have some kind of constraint solver (say, Z3) that can help us answer questions over these predicates.

[^predicates-in-practice]: In practice, we may often define this set of predicates as a set of "templates". Instead of having, say, $x < 0$ we may have something like "a variable is less than 0".

{% endcomment %}