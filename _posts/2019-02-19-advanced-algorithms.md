---
title: CS-450 Advanced Algorithms
description: "My notes from the CS-450 Advanced Algorithms course given at EPFL, in the 2019 spring semester (MA2)"
edited: true
note: true
---

A prerequisite for this course is [CS-250 Algorithms](/algorithms/).

<!-- More --> 

* TOC
{:toc}

⚠ *Work in progress*

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
\newcommand{\bigO}[1]{\mathcal{O}\left(#1\right)}
\newcommand{\vec}[1]{\mathbf{#1}}
\newcommand{\expect}[1]{\mathbb{E}\left[#1\right]}
\newcommand{\prob}[1]{\mathbb{P}\left[#1\right]}
\newcommand{\qed}[0]{\tag*{$\blacksquare$}}
$$

## When does the greedy algorithm work? 

### Maximum weight spanning trees
We'll start with a problem called *maximum weight spanning trees*.

- **Input**: A graph $G = (V, E)$ with edge weights $w: E \mapsto \mathbb{R}$
- **Output**: A spanning tree $T \subseteq E$ of maximum weight $\sum_{e\in T} w(e)$

A [spanning tree](/algorithms/#minimum-spanning-trees) is a subgraph connecting all vertices of $G$ in the minimum possible number of edges. Being a tree, it is acyclic by definition.

#### Kruskal's algorithm
We'll consider the simplest greedy algorithm: [Kruskal's algorithm](/algorithms/#kruskals-algorithm)[^minimum-and-maximum-kruskals], which greedily adds the largest weight edge if it doesn't create a cycle.

[^minimum-and-maximum-kruskals]: Note that in the Algorithms course we saw it for *minimum* spanning trees, but that we're now looking at a variation for *maximum* spanning trees. These are equivalent problems, because we can just take $-w(e)$ instead of $w(e)$.

{% highlight python linenos %}
def kruskal_greedy(G, w):
    """
    Input:   a connected undirected graph G=(V, E)
             edge weights w
    Output:  a maximum weight spanning tree S
    """
    S = set()
    sort edges in decreasing weight order
    for i = 1 to |E|:
        if S + E[i] is acyclic:
            S += E[i]
    return S
{% endhighlight %}

#### Running time
The running time of this algorithm is:

- Sorting: $\Theta(m \log{m})$ where $m = \abs{E}$.
- For-loop: to determine whether a graph is acyclic, we can use [union-find](/algorithms/#data-structures-for-disjoint-sets), which is $\Theta(m)\cdot\alpha(m) = O(m \log{m})$ (where $\alpha(m)$ is almost a constant)

Thus, the total running time is $\Theta(m \log{m})$.

#### Useful facts for the correctness proof
In the correctness proof below, we'll need a few useful facts, which we won't take the time to prove. We define $n = \abs{V}$.

- In a connected graph, the spanning tree has $n-1$ edges. 
- Suppose we have a graph $G' = (V, F)$, where $F$ is an acyclic edge set of $k = \abs{F}$ edges. Then the number of connected components is $n - k$. Intuitively, we get to this result by observing the following:
    + If $\abs{F} = 0$, then there are no edges, and every node is a connected component, so there are $n$ connected components
    + If $\abs{F} = 1$, then there's only one edge, then we have $n-1$ components (the added edge connected two components)
    + If $\abs{F} = 2$, then there are $n-2$ connected components
    + ...

#### Correctness proof
We will prove the following lemma by contradiction.

> lemma "Kruskal correctness"
> `kruskal_greedy` returns a maximum weight spanning tree.

We'll suppose for the sake of contradiction that `kruskal_greedy` doesn't return a *maximum* weight spanning tree. This means that we suppose it picks edges $S = \set{s_1, s_2, \dots, s_{n-1}}$ [^number-edges], but that there exists a tree $T = \set{t_1, t_2, \dots, t_{n-1}}$ of higher weight.

[^number-edges]: As we said previously, the spanning tree has $n-1$ edges.

Note that the edges are indexed in decreasing order. $T$ is of higher weight than $S$, so there exists a first index $p$ such that $w(t_p) > w(s_p)$. We can use this index to define two sets:

- $A = \set{t_1, t_2, \dots, t_p}$ is the set of the first $p$ edges of $T$. Because `kruskal_greedy` picks edges in order of decreasing weight and because $w(t_p) > w(s_p)$, all these weights are $> w(s_p)$.
- $B = \set{s_1, s_2, \dots, s_{p-1}}$ is the set of the first $p-1$ edges of $S$. Because `kruskal_greedy` picked these before $s_p$,  all these weights are $> w(s_p)$.

We can notice that $\abs{A} > \abs{B}$, which is useful because of the following key property:

**Key property**: As $\abs{A} > \abs{B}$, $\exists e \in A \setminus B$ such that $B + e$ is acyclic.[^set-notation]

[^set-notation]: We use the notation $B + e$ as a shorthand for $B \cup \set{e}$

{% details Proof of the key property %}
This follows from the fact that an acyclic graph with $k$ edges has $n-k$ connected components, as we previously stated. Thus, for any acyclic edge sets $S, T$ with $\abs{S} > \abs{T}$, the graph $(V, S)$ has fewer components than $(V, T)$, so there must be an edge $e \in S$ connecting two components in $(V, T)$; it follows that $e \notin T$ and $T + e$ is acyclic.

More succinctly, $\exists e \in S \setminus T$ such that $T + e$ is acyclic.
{% enddetails %}

This edge is $e\in A \setminus B$, so $w(e) \ge w(t_p) > w(s_p)$. Since it has higher weight, $e$ must have been considered by the algorithm before $s_p$.

When $e$ was considered, the algorithm checked whether $e$ could be added to the current set at the time, which we'll call $B' \subseteq B$. In the above, we stated that $B + e$ is acyclic. Since $B' + e \subseteq B + e$ and since a subset of acyclic edges is also acyclic[^subset-acyclic], $B' + e$ is also acyclic.

[^subset-acyclic]: We cannot create a cycle by removing edges

Since adding the edge $e$ to $B$ doesn't create a cycle, according to the algorithm, it must have been selected to be a part of $S$. At this point, we have $e\in S$, but also $e\notin B \subset S$ (because of our initial assumption that $e \in A \setminus B$), which is a contradiction.

#### Conclusion
In the correctness proof above, we used two properties of acyclic graphs: 

- A subset of acyclic edges is acyclic
- For two acyclic edge sets $A$ and $B$ such that $\abs{A} > \abs{B}$, there is $e \in A \setminus B$ such that $B + e$ is acyclic

The generalization of these two properties will lead us to matroids.

### Matroids
#### Definition
A matroid $M = (E, \mathcal{I})$ is defined on a finite ground set $E$ of elements, and a family $\mathcal{I} \subseteq 2^E$ of subsets of $E$, satisfying two properties:

- $(I_1)$: If $X \subseteq Y$ and $Y \in \mathcal{I}$ then $X\in\mathcal{I}$
- $(I_2)$: If $X\in\mathcal{I}$ and $Y\in\mathcal{I}$ and $\abs{Y} > \abs{X}$ then $\exists e \in Y \setminus X : X + e \in \mathcal{I}$

#### Remarks
The $(I_1)$ property is called "downward-closedness"; it tells us that by losing elements of a feasible solution, we still retain a feasible solution.

The sets of $\mathcal{I}$ are called *independent sets*: if $X\in\mathcal{I}$, we say that $X$ is *independent*.

$(I_2)$ implies that every *maximal* independent set is of maximum cardinality[^proof-maximal-independent]. This means that all maximal independent sets have the same cardinality. A set of maximum cardinality is called a *base* of the matroid.

[^proof-maximal-independent]: Suppose toward contradiction that two sets $S$ and $T$ are maximal, but that $\abs{S} > \abs{T}$. By $(I_2)$, $\exists e \in S \setminus T : T + e \in \mathcal{I}$, which means that $T$ isn't maximal, which is a contradiction.

Since $\mathcal{I}$ can be exponential in the size of the ground set $E$, we assume that we have a *membership oracle* which we can use to efficiently check $X \in \mathcal{I}$ for a set $X\subseteq E$.

#### Algorithm
{% highlight python linenos %}
def greedy(M, w):
    """
    Input:  a matroid M = (E, I),
            |E| weights w
    Output: a maximum weight base S
    """
    S = set()
    sort elements of E in decreasing weight order
    for i = 1 to |E|:
        if S + E[i] in I:
            S += E[i]
    return S
{% endhighlight %}

#### Correctness proof
We'd like to prove the following theorem:

> theorem ""
> For any ground set $E = \set{1, 2, \dots, n}$ and a family of subsets $\mathcal{I}$, `greedy` finds a maximum weight base for any set of weights $w: E \mapsto \mathbb{R}$ **if and only if** $M=(E, \mathcal{I})$ is a matroid.

The if direction ($\Leftarrow$) follows from the [correctness proof](#correctness-proof) we did for Kruskal's algorithm.

For the only if direction ($\Rightarrow$), we must prove the following claim, which we give in the contrapositive form.

> claim ""
> Suppose $(E, \mathcal{I})$ is not a matroid. Then there exists an assignment of weights $w: E \mapsto \mathbb{R}$ such that `greedy` does not return a maximum weight base.

To prove this, we're going to cook up some weights for which `greedy` doesn't return a maximum weight base when $(E, \mathcal{I})$ isn't a matroid (i.e. the tuple either violates $(I_1)$ or $(I_2)$).

**First**, consider the case where $(E, \mathcal{I})$ isn't a matroid because it violates $(I_1)$. Therefore, there exists two sets $S \subset T$ such that $S\notin\mathcal{I}$ but $T\in\mathcal{I}$. Let's pick the following weights:

$$
w_i = \begin{cases}
2 & i \in S \\
1 & i \in T \setminus S \\
0 & \text{otherwise} \\
\end{cases}
$$

This weight assignment has been chosen so that the algorithm considers elements in the following order: first $S$, then $T$, then everything else. Since $S \notin \mathcal{I}$, the algorithm only selects $S_1 \subset S$ (it's a strict subset as $S \notin \mathcal{I}$). Best case, the strict subset has size $\abs{S_1} = \abs{S} - 1$, so the solution's weight is at most:

$$
\begin{align}
2\abs{S_1} + \abs{T \setminus S}
& = 2(\abs{S} - 1) + \abs{T \setminus S} \\
& = 2\abs{S} - 2 + \abs{T} - \abs{S} \\
& = \abs{T} + \abs{S} - 2 \\
& < \text{optimal}
\end{align}
$$

**Second**, consider the case where $(I_2)$ is violated (but $(I_1)$ isn't). Let $S, T \in \mathcal{I}$ be two independent sets, such that $\abs{S} < \abs{T}$, and $\forall i \in T\setminus S$, $S + i \notin \mathcal{I}$.

Let's use the following weights, which again have been carefully chosen to have the algorithm consider elements in $S$, then $T$, then everything else. The value of the weights is also carefully chosen to get a nice closed form later.

$$
w_i = \begin{cases}
1 + \frac{1}{2\abs{S}} & i \in S \\
1                      & i \in T \setminus S \\
0                      & \text{otherwise} \\
\end{cases}
$$

Because of $(I_1)$ (and our assumption that $S \in \mathcal{I}$), `greedy` will first select all elements in $S$. But at this point, because we assumed $(I_2)$ to be violated, we have $\forall i \in T\setminus S$, $S + i \notin \mathcal{I}$. That means that we cannot pick any elements in $T \setminus S$ to add to the solution, so the solution would have weight:

$$
\left(1 + \frac{1}{2\abs{S}}\right) \cdot \abs{S}
= \abs{S} + \frac{1}{2}
$$

However, since $T\in\mathcal{I}$ and $\abs{T} > \abs{S}$, we expect the optimal solution to have value $\abs{T} \ge \abs{S} + 1 > \abs{S} + \frac{1}{2}$. $\qed$

#### Examples
<br/>

##### Graphic matroid
In our initial example about maximum spanning trees, we were actually considering a matroid in which $E$ is the set of edges, and $\mathcal{I}$ is defined as:

$$
\mathcal{I} = \set{X \subseteq E : X \text{ is acyclic}}
$$

##### k-Uniform matroid
The k-Uniform matroid $M = (E, \mathcal{I})$ is a matroid in which $\mathcal{I}$ is given by:

$$
\mathcal{I} = \set{X \subseteq E : \abs{X} \le k}
$$

$(I_1)$ is satisfied because dropping elements still satisfies $\mathcal{I}$. $(I_2)$ is satisfied because $\abs{X} < \abs{Y}$ and $X < k$ implies that $\abs{X + e} \le k$.

##### Partition matroid
In a partition monoid, the ground set $E$ is partitioned into *disjoint* subsets $E_1, E_2, \dots, E_l$ (we can think of them as representing $l$ different colors, for example). Each such subset has an integer $k_i$ associated to it, stating how many elements can be picked from each subset at most.

$$
\mathcal{I} = \set{X \subseteq E : \abs{E_i \cap X} \le k_i \text{ for } i = 1, 2, \dots, l}
$$

##### Linear matroid
The linear matroid $M = (E, \mathcal{I})$ is defined for a matrix $A$. The ground set $E$ is the index set of the columns of $A$; a subset $X \subseteq E$ gives us a matrix $A_X$ containing the columns indexed by the set $X$. The matroid is then given by:

$$
\mathcal{I} = \set{X \subseteq E : \text{rank}(A_X) = \abs{X}}
$$

##### Truncated matroid
Matroids can be constructed from other matroids. For instance, the truncated matroid $M_k = (E, \mathcal{I}_k)$ is constructed from the matroid $M = (E, \mathcal{I})$, such that:

$$
\mathcal{I}_k = \set{X \in \mathcal{I} : \abs{X} \le k}
$$

##### Laminar matroid
Laminar matroids $M = (E, \mathcal{I})$ are defined by a family $\mathcal{F}$ of subsets of the ground set $E$ that satisfy the following. If $X, Y \in \mathcal{F}$, then either:

- $X \cap Y = \emptyset$
- $X \subseteq Y$
- $Y \subseteq X$

We can think of these subsets as being [part of a tree](http://vu-my.s3.amazonaws.com/wp-content/uploads/sites/2392/2015/07/30090557/Tara-E-Fife.pdf), where each node is the union of its children. For each set $X \in \mathcal{F}$, we define an integer $k_X$. The matroid is then defined by:

$$
\mathcal{I} = \set{S \subseteq E : \abs{S \cap X} \le k_X \, \forall X \in \mathcal{F}}
$$

##### Gammoid ("Netflix matroid")
Todo

### Matroid intersection
Matroids form a rich set of problems that can be solved by the `greedy` algorithm, but there are also many problems with efficient algorithms that aren't matroids. This is the case for problems that aren't matroids themselves, but can be defined as the intersection of two matroids.

The intersection of two matroids $M_1 = (E, \mathcal{I}_1)$ and $M_2 = (E, \mathcal{I_2})$ is:

$$
M_1 \cap M_2 = (E, \mathcal{I}_1 \cap \mathcal{I}_2)
$$

The intersection of two matroids satisfies $(I_1)$, but generally not $(I_2)$. 

The following theorem adds a lot of power to the concept of matroids.

> theorem ""
> There is an efficient algorithm for finding a max-weight independent set in the intersection of two matroids.

Here, efficient means polynomial time, if we assume a polynomial time membership oracle. This is the case for all the matroid examples seen in class.

#### Definition of bipartite matching
For instance, we can consider the example of [bipartite matching](/algorithms/#bipartite-matching).

- **Input**: A bipartite graph $G(V = A \cup B, E)$, where $A$ and $B$ are two disjoint vertex sets
- **Output**: Matching $M\subseteq E$ of maximum weight (or maximum cardinality[^equivalent-bipartite]).

[^equivalent-bipartite]: Maximum cardinality is a special case of maximum weight, where all the weights are equal.

A matching means that each vertex is incident to *at most* one edge, i.e. that:

$$
\abs{\set{e \in M : v \in e}} \le 1, \quad \forall v \in V
$$

For this problem, we can define $(E, \mathcal{I})$ with $E$ being the edge set, and $\mathcal{I}$ defined as:

$$
\mathcal{I} = \set{M \subset E : M \text{ is a matching}}
$$

This $(E, \mathcal{I})$ satisfies downward closedness $(I_1)$ but not $(I_2)$.

#### Bipartite matching as a matroid intersection
The bipartite matching problem can be defined as the intersection of two matroids:

$$
(E, \mathcal{I}) 
= (E, \mathcal{I}_A \cap \mathcal{I}_B)
= M_A \cap M_B
$$

We'll use two partition matroids $M_A$ and $M_B$ imposing the same restrictions, but on $A$ and $B$, respectively. The ground set for both matroids is $E$, whose partition is as follows:

$$
E = \bigcup \set{\delta(v) : v \in A}
$$

Here, $\delta(v)$ denotes the edges incident to a vertex $v$. We let $k_v = 1$ for every $v$ in $A$, so we can define the family of independent sets for the first matroid $M_A$ is:

$$
\mathcal{I}_A = \set{
    X \subseteq E : 
    \abs{X \cap \delta(v)} \le k_v = 1, \quad
    \forall v \in A
}
$$

In other words, a set of edges $X \subseteq E$ is independent for $M_A$ (i.e. $X \in \mathcal{I_A}$) if it has at most one edge incident to every vertex of $A$ (no restrictions on how many edges can be incident to vertices on $B$). Defining $\mathcal{I}_B$ similarly, we see why the matroid intersection corresponds to a matching in $G$

 is defined similarly:

$$
\mathcal{I}_B = \set{
    X \subseteq E : 
    \abs{X \cap \delta(v)} \le 1, \quad
    \forall v \in B
}
$$

#### Colorful spanning trees
- **Input**: A graph $G = (V, E)$, where every edge $v \in V$ has one of $k$ colors, which we denote by $v \in E_i$, with $i = 1, \dots, k$
- **Output**: Whether the graph has a spanning tree in which all edges have a different color

We want to find a spanning tree, so we'll use a graphic matroid for $M_1$.

The color assignment gives us the partition of $E$ into disjoint sets $E_1 \cup E_2 \cup \dots \cup E_k$, where each $E_i$ represents all the edges that have the same color $i$. This gives us a hint for the second matroid: we need a partition matroid. We let $M_2$ be defined by:

$$
\mathcal{I}_2 = \set{X \subseteq E : \abs{X \cap E_i} \le 1, \quad \forall i}
$$

#### Arborescences
- **Input**: Directed graph $D = (V, A)$ and a special root vertex $r \in V$ that has no incoming edges
- **Output**: An arborescence $T$ of $D$

An arborescence of a directed graph is a spanning tree (ignoring edge directions), directed away from $r$. In an arborescence $T$, every vertex in $V$ is reachable from $r$. 

More formally, $T$ is an arborescence if:

1. $T$ is a spanning tree (ignoring edge direction)
2. $r$ has in-degree 0 and all other nodes have in-degree 1 in the edge set $T$ (considering edge direction)

These two criteria give us a good hint of which matroids to choose. We let $M_1 = (A, \mathcal{I}_1)$ be a graphic matroid for $G$ (disregarding the edge direction), and $M_2 = (A, \mathcal{I}_2)$ be a partition matroid in which:

$$
\mathcal{I}_2 = \set{
    X \subseteq E :
    \abs{X \cap \delta^-(v)} \le 1,
    \quad \forall v \in V \setminus \set{r}
} 
$$

Here, $\delta^-(v)$ denotes the set of arcs $\set{(u, v) \in A}$ incoming to $v$. In this partition matroid, the independent edge sets are those that have at most one arc incoming to every vertex $v \ne r$.

Any arborescence is independent in both matroids, by definition. Conversely, a set $T$ independent in both matroids of cardinality $\abs{V} - 1$ (so that it is a base in both) is an arborescence: being a spanning tree, it has a unique path between $r$ and any vertex $v$.

## Linear Programming

### Maximum cardinality bipartite matching

#### Definitions
We've seen [the definition](#definition-of-bipartite-matching) and [one algorithm](#bipartite-matching-as-a-matroid-intersection) for bipartite matching. Let's look into an alternative method.

Recall that a *path* is a collection of edges $\set{(v_0, v_1), (v_1, v_2), \dots, (v_{k-1}, v_k)}$ where all the $v_i$'s are distinct vertices. We can represent a path as $(v_0, v_1, \dots, v_k)$.

A *maximal path* is a path to which we cannot add any edges to make it longer.

A *maximum length path* is the longest path. Note that it is also a maximal path, but that this is a stronger assertion.

An *alternating path* with respect to an edge set $M$ is a path that alternates between edges in $M$ and edges in $E\setminus M$.

An *augmenting path* with respect to an edge set $M$ is an alternating path in which the first and last vertices are unmatched, meaning that they are not incident to an edge in $M$.

In a bipartite graph, the matching $M$ may define alternating paths in which we cannot revisit a node (by definition of a matching). Also note that an augmenting path is one that increases the matching; this is the core idea behind the following algorithm.

#### Algorithm

{% highlight python linenos %}
def augmenting_path_algorithm(G):
    """
    Input:  Bipartite graph G = (V, E)
    Output: Matching M of maximum cardinality
    """
    M = set()
    while exists an augmenting path P wrt. M:
        M = M △ P
    return M
{% endhighlight %}

$M \bigtriangleup P$ is the [symmetric difference](https://en.wikipedia.org/wiki/Symmetric_difference), which we can also denote:

$$
M \bigtriangleup P 
\equiv (M \setminus P) \cup (P \setminus M)
\equiv (M \cup P) \setminus (M \cap P)
$$

An efficient algorithm to find an augmenting path $P$ is make edges in $M$ directed from $B$ to $A$, and edges in $E\setminus M$ directed from $A$ to $B$. We can then run BFS from unmatched vertices in $A$, looking for unmatched vertices in $B$. This can be run in $\bigO{\abs{V} + \abs{E}}$ time for bipartite graphs (it is harder in general graphs). Seeing that there can be up to $k = \bigO{\abs{V}}$ matchings in the graph and that each augmenting path increases the matching size by one, we have to run $k$ loops. Therefore, the total runtime of the algorithm is $\bigO{\abs{V}^2 + \abs{E}\cdot\abs{V}}$.

Here's how the algorithm works. Suppose we already have a graph with a matching $M$ (in red):

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    B A C
}

subgraph cluster_right {
    color=invis
    F E D
}

B -- F [color=red, penwidth=3.0]
A -- E [color=red, penwidth=3.0]
B -- E
A -- D
C -- F
{% endgraph %}

The path $P$ corresponds to all the edges in the graph. The symmetric difference $M \bigtriangleup P$ corresponds to a new matching $M'$ of cardinality $\abs{M'} = \abs{M} + 1$:

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    A B C
}

subgraph cluster_right {
    color=invis
    D E F
}

B -- E [color=red, penwidth=3.0]
A -- D [color=red, penwidth=3.0]
C -- F [color=red, penwidth=3.0]
{% endgraph %}

#### Correctness proof
We now prove the correctness of this algorithm, which is to say that it indeed finds a maximum matching. The algorithm returns a set $M$ with respect to which there are no augmenting paths, so to prove correctness we must prove the following:

> theorem "Augmenting Path Algorithm Correctness"
> A matching $M$ is maximal **if and only if** there are no augmenting paths with respect to $M$.

The proof is by contradiction.

First, let's prove the $\Rightarrow$ direction. Suppose for the sake of contradiction that $M$ is maximum, but that there exists an augmenting path $P$ with respect to $M$. Then $M' = M \bigtriangleup P$ is a matching of greater cardinality than $M$, which contradicts the optimality of $M$.

Then, let's prove the $\Leftarrow$ direction. We must prove that the lack of augmenting paths implies that $M$ is maximal. Suppose toward contradiction that it is not, i.e. that there is a maximal matching $M^\*$ such that $\abs{M^\*} > \abs{M}$. Let $Q = M \bigtriangleup M^\*$; intuitively, this edge set $Q$ represents the edges that $M$ and $M^\*$ disagree on.

From there on, we reason as follows:

- $Q$ has more edges from $M^\*$ than from $M$ (since $\abs{M^\*} > \abs{M}$, which implies that $\abs{M^\* \setminus M} > \abs{M \setminus M^\*}$)
- In $Q$, every vertex $v$ has degree $\le 2$, with at most one edge from $M$, and at most one edge from $M^*$. Thus, every component in $Q$ is either:
    + a path (where middle nodes have degree two and the ends of the path have degree one), or
    + a cycle (where all nodes have degree two)
- The cycles and paths that compose $Q$ alternate between edges from $M$ and $M^\*$ (we cannot have vertices incident to two edges of the same set, as $M$ and $M^\*$ are matchings). This leads us to the following observations:
    + In cycles, there is the same number of edges from $M$ and $M^\*$
    + In paths, there number of edges from $M^\*$ is $\ge$ than the number of edges from $M$
- Let's remove cycles from consideration, and concentrate on paths. We can do so and still retain the property of having more edges from $M^\*$ than from $M$. Since $\abs{M^\*} > \abs{M}$, there must be at least one path with strictly more edges from $M^\*$ than from $M$; it must start and end with a $M^\*$ edge, and alternate between the sets in between. This path is an augmenting path with respect to $M$.

Therefore, there must exist an augmenting path $P$ with respect to $M$, which is a contradiction. $\qed$

#### Generalization
In the above, we've seen an algorithm for unweighted bipartite matching. If we'd like to generalize it to weighted bipartite matching[^equivalent-bipartite], we'll have to introduce a powerful algorithmic tool: linear programming.

### Definition of Linear Programming
A linear program (LP) is the problem of finding values for $n$ variables $x_1, x_2, \dots, x_n \in \mathbb{R}$ that minimize (or equivalently, maximize) a given linear objective function, subject to $m$ linear constraints:

$$
\begin{align}
\textbf{minimize: }   & \sum_{i=1}^n c_i x_i   & \\
\textbf{subject to: } 
    & \sum_{i=1}^n e_{i, j} x_i =   b_j & \text{for }j=1,\dots,m_1 \\
    & \sum_{i=1}^n d_{i, k} x_i \ge g_k & \text{for }k=1,\dots,m_2 \\
    & \sum_{i=1}^n f_{i, p} x_i \le l_p & \text{for }p=1,\dots,m_3 \\
\end{align}
$$ 

Where $m = m_1 + m_2 + m_3$.

Strictly speaking, it isn't necessary to allow equality and upper-bound constraints: 

- We can get an equality constraint with a lower-bound and an upper-bound.
- We can transform an upper-bound into a lower-bound by multiplying all factors and the bound by $-1$.

Still, we allow them for simpler notation for now. Strict inequality, however, is disallowed (otherwise, we wouldn't have a closed set, and there would never be an optimal solution, as we could always get closer to the bound by an infinitesimal amount).

### Extreme points
A feasible solution is an **extreme point** if it cannot be written as a convex combination of other feasible solutions.

A **convex combination** of points $x_1, x_2, \dots, x_n$ is a point of the form $\sum_{i=1}^n \lambda_i x_i$ where the $\lambda_i \in [0, 1]$ satisfy $\sum_{i=1}^n \lambda_i = 1$.

To gain some intuition about what an extreme point is, we can take a look at the diagram below:

![A feasible which isn't an extreme point](/images/advanced-algorithms/extreme-point.png)

In the above, $P$ is not an extreme point because $P = \frac{1}{2} X + \frac{1}{2} Y$. If we can walk an $\epsilon$ amount in opposing directions, then it is not an extreme point.

Extreme points are important because they have useful structural properties that we can exploit to design algorithms and construct proofs. We can state the following theorem about extreme points:

> theorem ""
> If the feasible region is bounded, then there always exists an optimum which is an extreme point.

The proof is as follows. As the feasible region is bounded, there is an optimal solution $x^\*$. If $x^\*$ happens to be an extreme point, we are done. The real work in this proof is for the case where $x^\*$ isn't an extreme point. To prove this, we'll have to introduce a small lemma:

> lemma ""
> Any feasible point can be written as a convex combination of the extreme points.

This is essentially proven by the following diagram:

![A feasible point and the extreme points that it is constructed from](/images/advanced-algorithms/convex-combination-extreme-points.png)

Indeed, if we draw a line from a feasible point $P$ in a bounded domain, we'll hit the bounds in two locations $X$ and $Y$, which are convex combination of the extreme points $A$, $B$ and $C$, $D$, respectively. $P$ is itself a convex combination of $X$ and $Y$, and thus of the extreme points $A$, $B$, $C$ and $D$.

With this lemma in place, we can write the feasible solution $x^\*$ as a convex combination of extreme points: 

$$
x^* = \sum_i \lambda_i x^{(i)}
$$

Where the $x^{(i)}$ are extreme points, and $\lambda_i \in [0, 1]$ satisfy $\sum_i \lambda_i = 1$.

Let $c = \begin{bmatrix}c_1 & c_2 & \dots & c_n\end{bmatrix}$ be the vector defining the objective that we wish to maximize (the proof is the same if we minimize). Then we have:

$$
\begin{align}
  c^T x^*
& = \sum_{i=1}^n c_i x_i^*
  = c^T \left( \sum_j \lambda_j x^{(j)} \right)
  = \sum_i c_i \left( \sum_j \lambda_j x_i^{(j)} \right) \\
& = \sum_j \lambda_j \left( \sum_i c_i x_i^{(j)} \right)
  = \sum_j \lambda_j c^T x^{(j)}
\end{align}
$$ 

This proves $c^T x^\* = \sum_j \lambda_j c^T x^{(j)}$. In other words, the value of the objective function is a weighted average of the extreme points. If we measured the height of all the people in a class, and got the average value of 170cm, we could say that at least one person has height $\ge$ 170cm. For the same reason, we can conclude from the above:

$$
c^T x^* = \sum_j \lambda_j c^T x^{(j)}
\implies 
\exists j : c^T x^{(j)} \ge c^T x^*
$$

This extreme point $x^{(j)}$ is gives us a higher value for the objective function than $x^\*$. Since $x^\*$ was chosen to be *any* feasible point, this means that $x^{(j)}$ is an optimal solution. $\qed$


### Maximum weight bipartite perfect matching
The problem corresponds to the following:

- **Input**: A bipartite graph $G=(V, E)$ where $V = A \cup B$ and $\abs{A} = \abs{B}$, and edge weights $w: E \mapsto \mathbb{R}$
- **Output**: A perfect matching $M$ maximizing $w(M) = \sum_{e \in M} w(e)$

A matching is **perfect** if every vertex is incident to *exactly* one edge in the matching (i.e. every vertex is matched). We need $\abs{A} = \abs{B}$ for this to work.

This problem can be formulated as the following linear program:

$$
\begin{align}
\textbf{maximize: }   & \sum_{e \in E} x_e w(e)   & \\
\textbf{subject to: } 
    & \sum_{e = (a, b) \in E} x_e = 1 & \forall a \in A \\
    & \sum_{e = (a, b) \in E} x_e = 1 & \forall b \in B \\
    & x_e \ge 0                       & \forall e \in E \\
\end{align}
$$

The constraints say that every vertex is chosen exactly once. The intended meaning for variables $x_e$ is:

$$
x_e = \begin{cases}
1 & \text{if } e \in M \\
0 & \text{otherwise}
\end{cases}
$$

But in linear programming, we cannot take on discrete values; instead, we can only have $x_e \in [0, 1]$, which gives us the constraint $0 \le x_e \le 1$. The upper bound of 1 is implied by the other constraints, so for the sake of conciseness, we only give the minimal set of constraints above.

Still, we will see that relaxing $x_e$ to be in $[0, 1]$ still gives us an optimal solution $x^\*$ for which $x_e^\* \in \set{0, 1} \forall e \in E$.

> claim ""
> For bipartite graphs, any extreme point solution to the LP is integral.

Integral means that it is an integer; coupled with the constraint that $0 \le x_e \le 1$, being integral implies $x_e \in \set{0, 1}$.

We'll prove this by contradiction. Let $x^\*$ be an extreme point for the graph $G=(A \cup B, E)$, and let $E_f = \set{e \in E : 0 < x_e^\* < 1}$ be the set of edges for which optimal extreme point solution $x^\*$ is not integral. We suppose toward contradiction that the solution $x^\*$ contains such edges, i.e. that $E_f \ne \emptyset$.

We have the constraint that for any given vertex $a\in A$ or $b\in B$, $\sum_{e = (a, b) \in E} x_e^\* = 1$. This means that either:

- All the incident edges $e$ to the vertex have integral weights $x_e^\* \in \set{0, 1}$, and the vertex therefore has no incident edges in $E_f$.
- At least one incident edge $e$ to the vertex has non-integral weight $0 < x_e^\* < 1$. But because of the above constraint, it takes at least two non-integral weights $x_{e_1}^\*$ and $x_{e_2}^\*$ to sum up to 1, so having one incident edge in $E_f$ implies having at least two incident edges in $E_f$.

This implies that $E_f$ must contain a cycle. By construction, because we only have a finite number of vertices in $E_f$ and because they cannot have degree 1, the path must close back to the original vertex.

Further, cycles in a bipartite graph must have even length. This follows from the fact that to get back to a vertex in $A$, we must go to $B$ and back to $A$ $k$ times, for a total of $2k$ edges.

All these edges in the cycle are fractional (being in $E_f$). Since this is a proof by contradiction, we'll try to find two feasible points $y$ and $z$ such that $x^\* = \frac{1}{2}(y + z)$, which would be a contradiction of the assumption that $x^\*$ is an extreme point.

Let $e_1, e_2, \dots, e_{2k}$ be the edges of the cycle. Let $y$ and $z$ be defined for each edge $e$ as follows:

$$
\begin{align}
y_e & = \begin{cases}
    x_e^* + \epsilon & \text{if } e \in \set{e_1, e_3, e_5, \dots, e_{2k-1}} \\
    x_e^* - \epsilon & \text{if } e \in \set{e_2, e_4, e_6, \dots, e_{2k}} \\
    x_e^* & \text{otherwise} \\
\end{cases} \\ \\

z_e & = \begin{cases}
    x_e^* - \epsilon & \text{if } e \in \set{e_1, e_3, e_5, \dots, e_{2k-1}} \\
    x_e^* + \epsilon & \text{if } e \in \set{e_2, e_4, e_6, \dots, e_{2k}} \\
    x_e^* & \text{otherwise} \\
\end{cases} \\
\end{align}
$$

The degree constraints of $\sum_{e = (a, b) \in E} y_e = 1$ and $\sum_{e = (a, b) \in E} z_e = 1$ are satisfied, because they alternate between adding and subtracting $\epsilon$ in a cycle of even length, and we assumed that $x_e^\*$ satisfies them.

To ensure feasibility, we must choose a small $\epsilon$ to guarantee that all $y_e, z_e \in [0, 1] \forall e \in E$. We can choose the following value to do so:

$$
\epsilon = \min\set{x_e^*, (1 - x_e^*)} \forall e \in E_f
$$

Note that this indeed satisfies $x^\* = \frac{1}{2}(y + z)$, so we have a contradiction of the assumption that $x^\*$ is an extreme point. $\qed$

#### Bipartite perfect matching polytope
The polytope[^polytope-definition] corresponding to the bipartite perfect matching LP constraints is called the *bipartite perfect matching polytope*. 

[^polytope-definition]: A polytope is a geometric object with flat sides, which is exactly what linear constraints form.

$$
\begin{align}
P = \bigg\{ x : 
& \sum_{e = (a, b) \in E} x_e = 1 & \forall a \in A, & \\
& \sum_{e = (a, b) \in E} x_e = 1 & \forall b \in B, & \\
& x_e \ge 0                       & \forall e \in E & 
\bigg\}
\end{align}
$$

We can solve the maximum weight bipartite matching problem by solving the above linear program.

#### General graphs
Unfortunately, this is only for bipartite graphs; for general graphs, we have a problem with odd cycles. We could solve this by imposing an addition constraint on odd cycles:

$$
\sum_{e \in E} x_e \le \frac{\abs{S} - 1}{2}, 
\quad \forall S \subseteq V,
\quad \abs{S} \text{ odd}
$$

Unfortunately, this adds exponentially many constraints. A proof 2 or 3 years ago established that there is no way around this.

### Vertex cover for bipartite graphs
The vertex cover problem is defined as follows:

- **Input**: A graph $G = (V, E)$ with node weights $w : V \mapsto \mathbb{R}$
- **Output**: A vertex cover $C \subseteq V$ that minimizes $w(C) = \sum_{v\in C} w(v)$

A vertex cover $C$ is a vertex set that ensures that every edge has at least one endpoint in $C$. In other words, $C$ is a vertex cover if $\forall e = (u, v) \in E$, we have $u\in C$ or $v\in C$.

Just like [maximum weight bipartite perfect matching](#maximum-weight-bipartite-perfect-matching), the vertex cover problem can be formulated as LP constraints:

$$
\begin{align}
\textbf{minimize: }   & \sum_{v \in V} x_v w(v)   & \\
\textbf{subject to: } 
    & x_u + x_v \ge 1 & \forall (u, v) \in E \\
    & 0 \le x_v \le 1 & \forall v \in V \\
\end{align}
$$

The constraints tell us that at least one of the endpoints should be in the vertex cover, as the intended meaning for $x_v$ is:

$$
x_v = \begin{cases}
1 & \text{if } v \in C \\
0 & \text{otherwise}
\end{cases}
$$

> claim ""
> For bipartite graphs, any extreme point to the vertex cover LP is integral.

We'll prove this by contradiction. Let $x^\*$ be an extreme point, and $V_f = \set{v : 0 < x_v^\* < 1}$ be the vertices with fractional values in $x^\*$. Suppose toward contradiction that $V_f \ne \emptyset$. 

Since $G$ is bipartite, the vertices $V$ are split into disjoint subsets $A$ and $B$. In the same way, we can divide $V_f$ into disjoint subsets $A_f = V_f \cap A$ and $B_f = V_f \cap B$, which are the fractional vertices in $A$ and $B$, respectively.

As previously, we'll define $y$ and $z$ such that $x^\* = \frac{1}{2}(y + z)$, by setting $\epsilon = \min\set{x_v, (1 - x_v) : v \in A_f \cup B_f}$, and letting:

$$
\begin{align}
y_v & = \begin{cases}
    x_v^* + \epsilon & \text{if } v \in A_f \\
    x_v^* - \epsilon & \text{if } v \in B_f \\
    x_v^* & \text{otherwise} \\
\end{cases} \\ \\

z_v & = \begin{cases}
    x_v^* - \epsilon & \text{if } v \in A_f \\
    x_v^* + \epsilon & \text{if } v \in B_f \\
    x_v^* & \text{otherwise} \\
\end{cases} \\
\end{align}
$$

Let's verify that these are feasible solutions. We'll just verify $y$, but the proof for $z$ follows the same reasoning.

By the selection of $\epsilon$, we have $0 \le y_v \le 1$, $\forall v\in V$, which satisfies the second constraint. 

To verify the first constraint, we must verify that $y_a + y_b \ge 1$ for every edge $(a, b) \in E$.

- If $x_a = 1$ (or $x_b = 1$), then $a \notin V_f$ (or $b \notin V_f$), so $y_a = x_a = 1$ (or $y_b = x_b = 1$), so the constraint holds.
- If $0 < x_a, x_b < 1$, then $a \in A_f$ and $b \in B_f$, which also respects the constraint, because:

$$
y_a + y_b = (x_a + \epsilon) + (x_b - \epsilon) = x_a + x_b \ge 1
$$

The last inequality holds because $x^\*$ is a feasible solution and thus satisfies the first property.

These $y$ and $z$ are feasible solutions, and therefore show a contradiction in our initial assumption that $x^\*$ is an extreme point; the claim is therefore verified. $\qed$

For general graphs, we have the same problem with odd cycles as for matchings. But the situation is actually even worse in this case, as the problem is NP-hard for general graphs, and we do not expect to have efficient algorithms for it. Still, we'll see an [approximation algorithm](#vertex-cover-for-general-graphs) later on.

In the above, we have seen two integrality proofs. These both have the same general approach: construct $y$ and $z$ adding or subtracting $\epsilon$ from $x^\*$ such that $y \ne x^\*$, $z \ne x^\*$ and $x^\* = \frac{y + z}{2}$, and such that $y$ and $z$ are feasible solutions. To prove feasibility, we much choose a construction where all the $\epsilon$ cancel out. If that isn't possible, then we must the variables for which the $\epsilon$ don't cancel out are "on their own" (i.e. not with any other variables) in the constraint.

## Duality

### Intuition
Consider the following linear program:

$$
\begin{align}
\textbf{minimize: }   & 7x_1 + 3x_2 \\
\textbf{subject to: } 
    & x_1  +  x_2 \ge 2 \\
    & 3x_1 +  x_2 \ge 4 \\
    & x_1,  x_2   \ge 0 \\
\end{align}
$$

We're looking for an optimal solution OPT. To find this value, we can ask about the upper bound and about the lower bound. 

- Is there a solution of cost $\le 10$? Is OPT $\le 10$?
- Is there no better solution? Is OPT $\ge 10$?

For instance, for the [max weight bipartite perfect matching problem](#maximum-weight-bipartite-perfect-matching), we can ask[^maximization-problem]:

[^maximization-problem]: This particular example is a maximization problem, but in general we'll be considering minimization problems. It all still holds, just don't get confused if things are switched in this example.

- Is there a matching of value at least $v$? In other words, is $\text{OPT} \ge v$?
- Do all matchings have value at most $v$? In other words, is $\text{OPT} \le v$?

Answering the first kind of question is easy enough: we can just find a feasible solution to the LP with an objective function that fits the bill (i.e. is $\ge v$). 

To answer the second kind of question though, we have to be a little smarter. The intuition is that a linear combination of primal constraints cannot exceed the primal objective function. This leads us to define the following dual LP with variables $y_1$ and $y_2$:

$$
\begin{align}
\textbf{maximize: }   & 2y_1 + 4y_2 \\
\textbf{subject to: } 
    & y_1 + 3y_2 \le 7 \\
    & y_1 +  y_2 \le 3 \\
    & y_1, y_2   \ge 0 \\
\end{align}
$$

Let's formalize this approach for the general case.

### General case
Consider the following linear program with $n$ variables, $x_i$ for $i \in [1, n]$ and $m$ constraints:

$$
\begin{align}
\textbf{minimize: }   & \sum_{i=1}^n c_i x_i   & \\
\textbf{subject to: } 
    & \sum_{i=1}^n A_{ji} x_i \ge b_j & \forall j = 1, \dots, m \\
    & x_i \ge 0 & \forall i = 1, \dots, n \\
\end{align}
$$

The $A$ matrix of factors is an $m\times n$ matrix (with $i$ ranging over columns, and $j$ over rows). This means that the factors in the primal are in the same layout as in $A$; we'll see that they're transposed in the dual.

Indeed, the dual program has $m$ variables $y_j$ for $j \in [1, m]$ and $n$ constraints:

$$
\begin{align}
\textbf{maximize: }   & \sum_{j=1}^m b_j y_j   & \\
\textbf{subject to: } 
    & \sum_{j=1}^m A_{ji} y_j \le c_i & \forall i = 1, \dots, n \\
    & y_j \ge 0 & \forall j = 1, \dots, m \\
\end{align}
$$

Note that the dual of the dual is the primal, so we can convert problems both ways.

### Weak duality
Weak duality tells us that every dual-feasible solution is a lower bound of primal-feasible solutions.

> theorem "Weak duality"
> If $x$ is a feasible solution to the primal problem and $y$ is feasible to the dual, then:
> 
> $$
> \sum_{i=1}^n c_i x_i \ge
> \sum_{j=1}^m b_j y_j
> $$

We can prove this by rewriting the right-hand side:

$$
\sum_{j=1}^m b_j y_j \le
\sum_{j=1}^m \sum_{i=1}^n A_{ji} x_i y_j =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i \le
\sum_{i=1}^n c_i x_i

\qed
$$

The first inequality uses the constraints of the primal, and the second uses the constraints of the dual. We also use the fact that $x, y \ge 0$ throughout.

This leads us to the conclusion that the optimal solution of the primal is lower bounded by the optimal solution to the dual. In fact, we can make a stronger assertion than that, which is what we do in strong duality.

### Strong duality
Strong duality tells us that the dual solutions aren't just a lower bound, but that the optimal solutions to the dual and the primal are equal.

> theorem "Strong Duality"
> If $x$ is an optimal primal solution and $y$ is an optimal dual solution, then:
> 
> $$
> \sum_{i=1}^n c_i x_i = \sum_{j=1}^m b_j y_j
> $$

Furthermore, if the primal problem is unbounded, then the dual problem is infeasible, and vice versa: if the dual is unbounded, the primal is infeasible.

### Example: Maximum Cardinality Matching and Vertex Cover on bipartite graphs
These two problems are the dual of each other. Remember that max cardinality matching is the following problem:

- **Input**: a bipartite graph $G = (A \cup B, E)$
- **Output**: a matching $M$

We define a variable $x_e$ for each edge $e\in E$, with the intended meaning that $x_e$ represents the number of incident edges to $e$ in the matching $M$. This leads us to defining the following LP:

$$
\begin{align}
\textbf{maximize: }   & \sum_{e \in E} x_e & \\
\textbf{subject to: } 
    & \sum_{e = (a, b) \in E} x_e \le 1 & \forall a \in A \\
    & \sum_{e = (a, b) \in E} x_e \le 1 & \forall b \in B \\
    & x_e \ge 0 & \forall e \in E \\
\end{align}
$$

The dual program is:

$$
\begin{align}
\textbf{minimize: }   & \sum_{v \in A\cup B} y_v & \\
\textbf{subject to: } 
    & y_a + y_b \ge 1 & \forall (a, b) \in E \\
    & y_v \ge 0       & \forall v \in A \cup B \\
\end{align}
$$

This dual problem corresponds to the relaxation of vertex cover, which returns a vertex set $C$. By weak duality, we have $\abs{M} \le \abs{C}$, for any matching $M$ and vertex cover $C$. Since both [the primal](#maximum-weight-bipartite-perfect-matching) and [the dual](#vertex-cover-for-bipartite-graphs) are integral for bipartite graphs, we have strong duality, which implies Kőnig's theorem.

### Kőnig's theorem
Kőnig's theorem describes an equivalence between the maximum matching and the vertex cover problem in bipartite graphs. Another Hungarian mathematician, Jenő Egerváry, discovered it independently the same year[^hungarian-algorithm-name].

[^hungarian-algorithm-name]: The Hungarian algorithm bears its name in honor of Kőnig and Egerváry, the two Hungarian mathematicians whose work it is based on.

> theorem "Kőnig's Theorem"
> Let $M^\*$ be a maximum cardinality matching and $C^\*$ be a minimum vertex cover of a bipartite graph. Then:
> 
> $$
> \abs{M^*} = \abs{C^*}
> $$

### Complementarity slackness
As a consequence of strong duality, we have a strong relationship between primal and dual optimal solutions:

> theorem "Complementarity Slackness"
> Let $x\in\mathbb{R}^n$ be a feasible solution to the primal, and let $y\in\mathbb{R}^m$ be a feasible solution to the dual. Then:
> 
> $$
> x, y \text{ are optimal solutions}
> \iff
> \begin{cases}
> x_i > 0 \implies c_i = \sum_{j=1}^m A_{ji} y_j
> & \forall i = 1, \dots, n \\
> 
> y_j > 0 \implies b_j = \sum_{i=1}^n A_{ji} x_i
> & \forall j = 1, \dots, m \\
> \end{cases}
> $$

Note that we could equivalently write $x_i \ne 0$ instead of $x_i > 0$ because we assume to have the constraint that $x_i \ge 0$ (similarly for $y_j$).

The "space" between the value of a constraint and its bound is what we call "slackness". In this case, since the right-hand side of the iff says that the variables being positive implies that the constraints are met exactly (and aren't just bounds), we have no slackness.

#### Proof
We can prove this complementarity slackness by applying strong duality to weak duality.

First, let's prove the $\Rightarrow$ direction. Let $x, y$ be the optimal primal solution. From the proof of weak duality, we have:

$$
\sum_{j=1}^m b_j y_j \le
\sum_{j=1}^m \sum_{i=1}^n A_{ji} x_i y_j =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i \le
\sum_{i=1}^n c_i x_i
$$

Since we're assuming that $x, y$ are optimal solutions, we also have strong duality, which tells us that:

$$
\sum_{i=1}^n c_i x_i = \sum_{j=1}^m b_j y_j
$$

With this in mind, all the inequalities above become equalities:

$$
\sum_{j=1}^m b_j y_j =
\sum_{j=1}^m \sum_{i=1}^n A_{ji} x_i y_j =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i =
\sum_{i=1}^n c_i x_i
$$

From this, we can quite trivially arrive to the following conclusion:

$$
\sum_{i=1}^n c_i x_i =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i
\implies 
c_i x_i = \left( \sum_{j=1}^m A_{ji} y_j \right) x_i
\quad \forall i = 1, \dots, n
$$

This means that as long as $x_i \ne 0$, we have:

$$
c_i = \sum_{j=1}^m A_{ji} y_j
$$

Now, let's prove the $\Leftarrow$ direction. We know that:

$$
\begin{align}
c_i x_i & = \left( \sum_{j=1}^m A_{ji} y_j \right) x_i 
& \forall i = 1, \dots, n \\

b_j y_j & = \left( \sum_{i=1}^n A_{ji} x_i \right) y_j 
& \forall j = 1, \dots, m \\
\end{align}
$$

Therefore, we can do just as in the proof of weak duality:

$$
\sum_{j=1}^m b_j y_j =
\sum_{j=1}^m \sum_{i=1}^n A_{ji} x_i y_j =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i =
\sum_{i=1}^n c_i x_i
$$

This is equivalent to $x, y$ being optimal solutions, by weak duality. $\qed$

### Duality of Min-Cost Perfect Bipartite Matching
- **Input**: $G = (A\cup B, E)$, a bipartite weighted graph with edge weights $c: E \mapsto \mathbb{R}$
- **Output**: Perfect matching $M$ of maximum cost $c(M) = \sum_{e \in M} c(e)$ 

We assume that $G$ is a *complete* bipartite graph, meaning that all possible edges exist. This is equivalent to not having a complete graph, as we can just consider missing edges in an incomplete graph as having infinite weight in a complete graph.

In the LP for this problem, we let $x_e$ be a variable for every edge $e$, taking value 1 if $e$ is picked in the matching, and 0 if not. The problem is then:

$$
\begin{align}
\textbf{maximize: }   & \sum_{e \in E} c(e) x_e & \\
\textbf{subject to: } 
    & \sum_{b \in B : (a, b) \in E} x_{ab} = 1 & \forall a \in A \\
    & \sum_{a \in A : (a, b) \in E} x_{ab} = 1 & \forall b \in B \\
    & x_e \ge 0 & \forall e \in E \\
\end{align}
$$

As [we saw previously](#maximum-weight-bipartite-perfect-matching), any extreme point of this problem is integral, so we can solve the min-cost perfect matching by solving the above LP. But that is not the most efficient approach. Using duality, we can reduce the problem to that of finding a perfect matching in an unweighted graph, which [we saw how to solve](#algorithm-1) using augmenting paths.

To obtain the dual, we'll first write the above LP in a form using inequalities, which gives us the following primal:

$$
\begin{align}
\textbf{minimize: }   & \sum_{e \in E} c(e) x_e & \\
\textbf{subject to: }
    & \sum_{b \in B : (a, b) \in E} x_{ab} \ge 1 & \forall a \in A \\
    & - \sum_{b \in B : (a, b) \in E} x_{ab} \ge -1 & \forall a \in A \\
    & \sum_{a \in A : (a, b) \in E} x_{ab} \ge 1 & \forall b \in B \\
    & -\sum_{a \in A : (a, b) \in E} x_{ab} \ge -1 & \forall b \in B \\
    & x_e \ge 0 & \forall e \in E \\
\end{align}
$$

This notation is a little tedious, so we'll introduce a variable for each constraint. For each $a \in A$, we introduce $u_a^-$ for the first constraint and $u_a^+$ for the second; similarly for each $b \in B$, we introduce $v_b^-$ and $v_b^+$ for the third and fourth constraint respectively. These will play the same role as the dual $y$ variables, in that every constraint in the primal has a variable in the dual. The dual is thus:

$$
\begin{align}
\textbf{maximize: }  
    & \sum_{a \in A} (u_a^+ - u_a^-) + \sum_{b \in B} (v_b^+ - v_b^-) & \\
\textbf{subject to: }
    & (u_a^+ - u_a^-) + (v_b^+ - v_b^-) \le c(e) 
    & \forall e = (a, b) \in E \\
    & u_a^+, u_a^-, v_b^+, v_b^- \ge 0
    & \forall a \in A, b \in B \\
\end{align}
$$

By [complementarity slackness](#complementarity-slackness), $x$ and $y = (u^+, u^-, v^+, v^-)$ are feasible *if and only if* the following holds:

$$
x_e > 0
\implies 
(u_a^+ - u_a^-) + (v_b^+ - v_b^-) = c(e)
\quad \forall e = (a, b) \in E
$$

We also get a series of more less interesting implications, which are trivially true as their right-hand side is always true (because the original constraints already specified equality):

$$
\begin{align}
  u_a^+ > 0 
& \implies \sum_{b \in B : (a, b) \in E} x_{ab} = 1 
& \forall a \in A \\

  u_a^- > 0 
& \implies - \sum_{b \in B : (a, b) \in E} x_{ab} = -1 
& \forall a \in A \\

  v_b^+ > 0
& \implies \sum_{a \in A : (a, b) \in E} x_{ab} = 1
& \forall b \in B \\

  v_b^- > 0
& \implies -\sum_{a \in A : (a, b) \in E} x_{ab} = -1 
& \forall b \in B \\
\end{align}
$$

For the following discussion, we'll define:

$$
\begin{align}
u_a \in \mathbb{R} = u_a^+ - u_a^-  & \quad \forall a \in A \\
v_b \in \mathbb{R} = v_b^+ - v_b^-  & \quad \forall b \in B \\
\end{align}
$$

Note that these are not constrained to be $\ge 0$. If we need to go back from $(u, v)$ notation to $(u^+, u^-, v^+, v^-)$ notation, we can define $u_a^+ = u_a$ and $u_a^- = 0$ when $u_a \ge 0$, and $u_a^+ = 0$ and $u_a^- = u_a$ if not (equivalently for $v_b$).

We can simplify the notation of our dual LP to the equivalent notation:

$$
\begin{align}
\textbf{maximize: }  
    & \sum_{a \in A} u_a + \sum_{b \in B} v_b & \\
\textbf{subject to: }
    & u_a + v_b \le c(e) 
    & \forall e = (a, b) \in E \\
\end{align}
$$

With this simplified notation, complementarity slackness gives us that $x$ and $y = (u, v)$ are feasible if and only if the following holds:

$$
x_e > 0
\implies
u_a + v_b = c(e) \quad \forall e = (a, b) \in E
$$

In other words, we can summarize this as the following lemma:

> lemma ""
> A perfect matching $M$ is of minimum cost **if and only if** there is a feasible dual solution $u, v$ such that:
> 
> $$
> u_a + v_b = c(e) \qquad \forall e = (a, b) \in M
> $$

In other words, if we can find a vertex weight assignment such that every edge has the same weight as the sum of its vertex weights, we've found a min-cost perfect matching. This is an interesting insight that will lead us to the Hungarian algorithm.

### Hungarian algorithm
The Hungarian algorithm finds a min-cost perfect matching. It works with the dual problem to try to construct a feasible primal solution.

#### Example
Consider the following bipartite graph:

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    A B C
}

subgraph cluster_right {
    color=invis
    D E F
}

A -- D
B -- D
B -- E [color=red, penwidth=3.0]
C -- D
C -- F
{% endgraph %}

The thin edges have cost 1, and the thick red edge has cost 2. The Hungarian algorithm uses the [lemma from above](#duality-of-min-cost-perfect-bipartite-matching) to always keep a dual solution $y = (u, v)$ that is *feasible at all times*. For any fixed dual solution, the lemma tells us that the perfect matching can only contain **tight edges**, which are edges $e = (a, b)$ for which $u_a + v_b = c(e)$. 

The Hungarian algorithm initializes the vertex weights to the following trivial solutions:

$$
v_b = 0, \quad
u_a = \min_{b \in B} c_{ab}
$$

The right vertices get weight 0, and the left vertices get the weight of the smallest edge they're incident to. The weights $u$ and $v$, and the set of tight edges $E'$ is displayed below. 

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    A[label="A = 1"];
    B[label="B = 1"];
    C[label="C = 1"];
}

subgraph cluster_right {
    color=invis
    D[label="D = 0"];
    E[label="E = 0"];
    F[label="F = 0"];
}

A -- D
B -- D
C -- D
C -- F
{% endgraph %}

Then, we try to find a perfect matching in this graph using the [augmenting path algorithm](#algorithm-1), for instance. However, this graph has no perfect matching (node $E$ is disconnected, $A$ and $B$ are both only connected to $D$). Still, we can use this fact to improve the dual solution $(u, v)$, using Hall's theorem:

> theorem "Hall's theorem"
> An $n$ by $n$ bypartite graph $G = (A \cup B, E')$ has a perfect matching **if and only if** $\abs{S} \le \abs{N(S)}$ for all $S \subseteq A$

Here, $N(S)$ is the *neighborhood* of $S$. In the example above, we have no perfect matching, and we have $S = \set{A, B}$ and $N(S) = \set{D}$.

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    subgraph cluster_S {
        color=black;
        label="S";
        A[label="A = 1"];
        B[label="B = 1"];
    }
    C[label="C = 1"];
}

subgraph cluster_right {
    color=invis
    subgraph cluster_NS {
        color=black;
        label="N(S)";
        D[label="D = 0"];
    }
    E[label="E = 0"];
    F[label="F = 0"];
}

A -- D
B -- D
C -- D
C -- F
{% endgraph %}

This set $S$ is a *certificate* that can be used to update the dual lower bound. If we pick a $\epsilon > 0$ (we'll see which value to pick later), we can increase $u_a$ for all vertices in $S$ by an amount $+\epsilon$, and decrease $v_b \in N(S)$ by $-\epsilon$. Let's take a look at which edges remain tight:

- Edges between $S$ and $N(S)$ remain tight as $u_a + \epsilon + v_b - \epsilon = u_a + v_b = c(a, b)$
- Edges between $A \setminus S$ and $B \setminus N(S)$ are unaffected and remain tight
- Any tight edge between $A\setminus S$ and $N(S)$ will stop being tight
- By definition of the neighborhood, there are no edges from $S$ to $B\setminus N(S)$

Because we've changed the set of tight edges, we've also changed our solution set $E'$ to something we can maybe find an augmenting path in. For instance, picking $\epsilon = 1$ in the graph above gives us a new set $E'$ of tight edges:

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    A[label="A = 2"];
    B[label="B = 2"];
    C[label="C = 1"];
}

subgraph cluster_right {
    color=invis
    D[label="D = -1"];
    E[label="E = 0"];
    F[label="F = 0"];
}

A -- D
B -- D
B -- E [color=red, penwidth=3.0]
C -- F
{% endgraph %}

The augmenting path algorithm can find a perfect matching in this graph, which is optimal by the lemma (TODO link).

#### Algorithm
Initialize:

$$
v_b = 0, \quad
u_a = \min_{b \in B} c_{ab}
$$

Iterate:

- Consider $G' = (A \cup B, E')$ where $E' = \set{(a, b) \in E : u_a + v_b = c((a, b))}$ is the set of all tight edges
- Find a maximum-cardinality matching in $G'$. 
    + If it is a perfect matching, we are done by complementarity slackness' $\Rightarrow$ direction.
    + Otherwise, we can find a "certificate" set $S \subseteq A$ such that $\abs{S} > \abs{N(S)}$. This is guaranteed to exist by Hall's theorem.
        * Update weights by $\epsilon$
        * Go to step 1

The weights are updated as follows:

$$
u'_a = \begin{cases}
    u_a + \epsilon & \text{if } a \in S \\
    u_a & \text{if } a \notin S \\
\end{cases}
\qquad
v'_b = \begin{cases}
    v_b + \epsilon & \text{if } b \in N(S) \\
    v_b & \text{if } b \notin N(S) \\
\end{cases}
$$

This remains feasible. The dual objective value increases by $(\abs{S} - \abs{N(S)})\epsilon$; as $\abs{S} > \abs{N(S)}$ by Hall's theorem, $\abs{S} - \abs{N(S)} > 1$ so $(\abs{S} - \abs{N(S)})\epsilon > \epsilon$: we only increase the value!

To get the maximal amount of growth in a single step, we should choose $\epsilon$ as large as possible while keeping a feasible solution:

$$
\epsilon = 
\min_{(a, b) \in S \times (B \setminus N(S))} 
    c((a, b)) - u_a - v_b 
> 0
$$

This algorithm is $\bigO{n^3}$, but can more easily be implemented in $\bigO{n^4}$.

## Approximation algorithms
Many optimization problems are NP-hard. Unless $P = NP$, there is no algorithm for these problems that have the following three properties:

1. Efficiency (polynomial time)
2. Reliability (works for any input instance)
3. Optimality (finds an optimal solution)

Properties 2 and 3 are related to *correctness*. Perhaps we could relax property 3 a little to obtain property 1? Doing so will lead us to approximation algorithms.

An $\alpha$-approximation algorithm is an algorithm that runs in polynomial time and outputs a solution a solution $S$ such that (for a minimization problem):

$$
\frac{\text{cost}(S)}{\text{cost}(OPT)} \le \alpha
$$

Alternatively, for maximization problems:

$$
\frac{\text{profit}(S)}{\text{profit}(OPT)} \ge \alpha
$$

Here, "cost" and "profit" refer to the objective functions. We will have $\alpha \ge 1$ for minimization problems, and $\alpha \le 1$ for maximization. If we have $\alpha = 1$ then we have a precise algorithm (not really an *approximation* algorithm).

Giving a value for $\alpha$ can be hard: we don't know the cost of the optimal solution, which is what we're stuck trying to compute in the first place. Instead, for minimization problems, we can do compare ourselves with a *lower bound* on the optimum, which gives us:

$$
\frac{\text{cost}(S)}{\text{cost}(OPT)} 
\le \frac{\text{cost}(S)}{\text{lower bound on OPT}} 
\le \alpha
$$

To get this bound, we typically proceed as follows:

1. Give an exact formulation of the problem as an Integer Linear Program (ILP), usually with $x_i \in \set{0, 1}$.
2. Relax the ILP to a LP with $x_i \in [0, 1]$
3. Solve the LP to get an optimal solution $x^\*\_{\text{LP}}$ which is a lower (respectively upper) bound on the optimal solution $x^\*\_{\text{ILP}}$ to the ILP, and thus also on the original problem.
4. Somehow round $x^\*\_{\text{LP}}$ "without losing too much", which will determine $\alpha$.

### Vertex Cover for general graphs
As we [saw previously](#vertex-cover-for-bipartite-graphs), vertex cover can be formulated as the following LP:

$$
\begin{align}
\textbf{minimize: }   & \sum_{v \in V} x_v w(v)   & \\
\textbf{subject to: } 
    & x_u + x_v \ge 1 & \forall (u, v) \in E \\
    & 0 \le x_v \le 1 & \forall v \in V \\
\end{align}
$$

Letting $x_i \in \set{0, 1}$ gives us our ILP. If we relax this to $x_i \in [0, 1]$, we get our LP. We proved that this LP works for bipartite graphs (i.e. that any extreme point for bipartite graphs is integral), but we're now considering the general case, in which we know we won't always get integral solutions.

Therefore, to go from LP to ILP, we must define a rounding scheme: given an optimal solution $x^\*$ to the LP, we will return:

$$
C = \set{v \in V : x_v^* \ge \frac{1}{2}}
$$

This is still a feasible solution, because for any edge $(u, v)$, we have $x_u^\* + x_v^\* \ge 1$, so at least one of $x_u^\*$ and $x_v^\*$ is $\ge \frac{1}{2}$.

We'll now talk about the value of $\alpha$.

> claim ""
> The weight of $C$ is at most twice the value of the optimal solution of vertex cover.
> 
> $$
> w(C) \le 2\text{VC}_{\text{OPT}}
> $$

We prove the claim as follows:

$$
\begin{align}
w(C) 
& = \sum_{v \in C}   w(v)
  = \sum_{v \in V : x_v^* \ge \frac{1}{2}}  w(v) \\

& \le \sum_{v \in V : x_v^* \ge \frac{1}{2}}  2x_v^* w(v)
  \le \sum_{v \in V}   2x_v^* w(v) \\

& =   2\sum_{v \in V}   x_v^* w(v)
  =   2\text{LP}_{\text{OPT}} \\
& \le 2\text{VC}_{\text{OPT}}
\qed
\end{align}
$$

Therefore, we have a 2-approximation algorithm for Vertex Cover.

Note that the above LP formulation can be generalized to $k$-uniform hypergraphs[^hypergraph] by summing over all vertices of an edge in the constraints. In the rounding step, we select all vertices that have weight $\ge \frac{1}{k}$. The algorithm then becomes a $k$-approximation algorithm.

[^hypergraph]: A $k$-uniform hypergraph $G=(V, E)$ is defined over a vertex set $V$ and an edge set $E$, where each edge $e \in E$ contains $k$ vertices. A normal graph is just a 2-uniform hypergraph.


### Integrality gap
#### Definition 
As a recap, we're talking about the following programs:

- **ILP**: Integral LP, the original definition of the problem.
- **LP**: Relaxation of the ILP. Its optimal solution has the lowest cost of all the programs; it's lower or equal to that of the ILP because the LP allows variables to take on more values than the ILP ($[0, 1]$ instead of $\set{0, 1}$).
- **Approximation algorithm**: Rounding of LP. Rounding increases cost by a factor $\alpha$.
- **OPT**: The (hypothetical) optimal solution

The notion of *integrality gap* allows us to bound the power of our LP relaxation. It defines the "gap" in cost between the optimal LP solution and the optimal OPT solution.

Let $\mathcal{I}$ be the set of all instances of a given problem. For minimization problems, the integrality gap is defined as:

$$
g = \max_{I \in \mathcal{I}}
    \frac{\text{OPT}(I)}{\text{OPT}_{\text{LP}}(I)}
$$

This allows us to give some guarantees on bounds: for instance, suppose $g=2$ and our LP found $\text{OPT}\_{\text{LP}} = 70$. Since the problem instance might have been the one maximizing the integrality, all we can guarantee is that $\text{OPT}(I) \le 2\cdot \text{OPT}\_{\text{LP}}(I) = 140$. In this case, we cannot make an approximation algorithm that approximates better than within a factor $g = 2$.

#### Integrality gap of Vertex Cover
> claim "Vertex cover integrality gap"
> The integrality gap for Vertex Cover for a graph of $n$ vertices is at least $2 - \frac{2}{n}$

On a *complete* graph with $n$ vertices, we have $OPT = n - 1$ because if there are two vertices we don't choose, the edge between them isn't covered. 

Assigning $\frac{1}{2}$ to every vertex is a feasible solution of cost $\frac{n}{2}$ so the optimum must be smaller or equal.

We can use these two facts to compute the integrality gap:

$$
g \ge \frac{n-1}{\frac{n}{2}} = 2 - \frac{2}{n}
\qed
$$

Our 2-approximation algorithm for vertex cover implies that the integrality gap is at most 2, so we have:

$$
2 - \frac{2}{n} \le g \le 2
$$

### Set cover
#### Problem definition
Set cover is a generalization of vertex cover.

- **Input**:
    + A universe of $n$ elements $\mathcal{U} = \set{e_1, e_2, \dots, e_n}$
    + A family of subsets $\mathcal{T} = \set{S_1, S_2, \dots, S_m}$
    + A cost function $c: \mathcal{T} \mapsto \mathbb{R}_+$
- **Output**: A collection $C \subseteq \mathcal{T}$ of subsets of minimum cost that cover all elements

More formally, the constraint of $C$ is:

$$
C \subseteq \mathcal{T} : \bigcup_{S \in C} S = \mathcal{U}
\quad
\text{and } c(C) \text{ is minimal}
$$

#### First attempt at an approximation algorithm
We can formulate this as an ILP of $n$ constraints, with $m$ variables. We'll let each $x_i \in \set{0, 1}$ be 1 if $S_i \in C$, and 0 otherwise. The LP is:

$$
\begin{align}
\textbf{minimize: }   & \sum_{i=1}^m x_i \cdot c(S_i)   & \\
\textbf{subject to: } 
    & \sum_{S_i : e \in S_i} x_i \ge 1 & \forall e \in \mathcal{U} \\
\end{align}
$$

As for the rounding, suppose that the element that belongs in the most sets is represented in $f$ sets $S_i$; each element belongs to at most $f$ sets. We'll do the following rounding to ensure feasibility:

$$
C = \set{S_i : x_i^* \ge \frac{1}{f}}
$$

Analyzing this in the same way as we did for Vertex Cover would short us that this is an approximation within a factor of $f$.

#### Better approximation algorithm
If we introduce some randomness and allow our algorithm to sometimes output non-feasible solutions, we can get much better results in expectation.

We'll run the following algorithm:

1. Solve the LP to get an optimal solution $x^\*$
2. Choose some positive integer constant $d$
3. Start with an empty result set $C$ and run the following $d$ times:
    - For $i = 1, \dots, m$, add set $S_i$ to the solution $C$ with probability $x_i^\*$ (choosing independently for each set).

The algorithm gives each set $d$ chances to be picked. This randomness introduces the possibility of two "bad events", the probabilities of which we'll study later:

- The solution has too high cost
- The solution is not feasible: there is at least one element that isn't covered by $C$

As we'll see in the two following claims, we can bound both of them.

> claim "Set Cover Claim 7"
> The expected cost of all sets added in one execution of Step 3 is:
> 
> $$
> \sum_{i=1}^m x_i^* \cdot c(S_i) = \text{LP}_{\text{OPT}}
> $$

For each set $S_i \in \mathcal{T}$, we let $Y_{S_i}$ be a random indicator variable telling us whether $S_i$ was picked to be in $C$:

$$
Y_{S_i} = \begin{cases}
0 & \text{if } S_i \in C \\
1 & \text{otherwise} \\
\end{cases}
$$

Unsurprisingly, the expected value of $Y_{S_i}$ is:

$$
\expect{Y_{S_i}} 
= \prob{Y_{S_i} = 1}\cdot 1 + \prob{Y_{S_i} = 0}\cdot 0 
= x_i^*
$$

The expected cost is therefore:

$$
\expect{c(C)}
= \sum_{i=1}^m c(S_i) \prob{S_i \text{is picked}}
= \sum_{i=1}^m c(S_i) Y_{S_i}
= \sum_{i=1}^m c(S_i) x_i^*
= \text{LP}_{\text{OPT}}
\qed
$$

From this, we can immediately derive the following corollary: 

> corollary "Set Cover Corollary 8"
> The expected cost of $C$ after $d$ executions of Step 3 is at most:
> 
> $$
>     d \cdot \sum_{i=1}^m c(S_i)x_i^*
> \le d \cdot \text{LP}_{\text{OPT}}
> \le d \cdot \text{OPT}
> $$

Note that $\text{LP}_{\text{OPT}} \le \text{OPT}$ because LP is a relaxation of the ILP, so its optimum can only be better (i.e. lower for minimization problems like this one). This gives us some probabilistic bound on the first "bad event" of the cost being high.

We also need to look into the other "bad event" of the solution not being feasible:

> claim "Set Cover Claim 9"
> The probability that a constraint is unsatisfied after a single execution is at most $\frac{1}{e}$.

A constraint is unsatisfied if $\exists e \in \mathcal{U} : e$ is not covered by $C$. Suppose that the unsatisfied constraint contains $k$ variables:

$$
x_1 + x_2 + \dots + x_k \le 1
$$

Let $S_1, \dots, S_k$ be the sets covering $e$. Then:

$$
\begin{align}
\prob{\text{constraint unsatisfied}} 
& = \prob{S_1 \notin C, \dots, S_k \notin C} \\
& = \prob{S_1 \text{ not taken}} \dots \prob{S_k \text{ not taken}} \\
& = (1-x_1^*) \dots (1 - x_k^*) \\
& \le e^{-x_1^*} \cdot \dots \cdot e^{-x_k^*} \\
& = \exp\left( -\sum_{i=1}^k x_i^* \right) \\
& \le e^{-1}
\qed
\end{align}
$$

Note that:

- The second step uses the independence of the $S_i$; while their probabilities are linked, their inclusion in $C$ is determined by independent "coin flips".
- The first inequality step uses $1-x \le e^{-x}$. This is a small lemma that follows from the Taylor expansion (it's good to know, but it's not vital to do so). 
- The second inequality uses the constraints of the problem, which tell us that $\sum_i x_i^\* \ge 1$.

So we have probability $e^{-1}\approx\frac{1}{3}$ of leaving a constraint unsatisfied. This is pretty bad! 

To get a better bound, we could have our algorithm pick set $S_i$ with probability $\min(1, 2\ln(n) x_s^\*)$, which would make $\prob{S_i \notin C} = (1 - 2\ln(n) x_i^\*)$, and the probability would be upper-bounded by $\frac{1}{n^2}$.

Another technique to "boost" the probability of having a feasible solution is to run the loop $d$ times instead of once. In the following, we'll pick $d = c\cdot\ln(n)$ because it will enable us to get nice closed forms. But these proofs could be done for any other formulation of $d$.

> claim "Set Cover claim 10"
> The output $C$ after $d=c\cdot\ln(n)$ is a feasible solution with probability at least $1 - \frac{1}{n^{c-1}}$.

The probability that a given constraint $i$ is unsatisfied after $d$ executions of step 3 is at most:

$$
\prob{\text{constraint } i \text{ unsatisfied}}
= \left(\frac{1}{e}\right)^{d}
$$


If we pick $d = c\cdot\ln(n)$, we get:

$$
\prob{\text{constraint } i \text{ unsatisfied}}
= \left(\frac{1}{e}\right)^{c\cdot\ln(n)} = \frac{1}{n^c}
$$

By [union bound](https://en.wikipedia.org/wiki/Boole%27s_inequality), we get that the probability of any constraint being unsatisfied is at most:

$$
\prob{\text{any constraint unsatisfied}}
= n\cdot\frac{1}{n^c} = \frac{1}{n^{c-1}}
\qed
$$


At this point, we have an idea of the probabilities of the two "bad events": we have an expected value of the cost, and a bound of the probability of the solution not being feasible. Still, there might be a bad correlation between the two: maybe the feasible outputs have very high cost? Maybe all infeasible solutions have low cost? The following claim deals with that worry.

> claim "Set Cover Claim 11"
> The algorithm outputs a feasible solution of cost at most $4d\text{OPT}$ with probability greater that $\frac{1}{2}$.

To prove this, we'll make use of Markov's inequality:

> theorem "Markov's Inequality"
> For a non-negative random variable $X$:
> 
> $$
> \prob{X \ge c \expect{X}} \le \frac{1}{c}
> $$

This stems from:

$$
\begin{align}
         & \prob{X \ge c} \cdot c \le \expect{X} \\
\implies & \prob{X \ge c} \le \frac{\expect{X}}{c} \\
\end{align}
$$

If we set $c = d\cdot\expect{X}$ we get:

$$
\prob{X \ge d\cdot\expect{X}} \le \frac{1}{d}
\qed
$$

Now onto the proof of our claim: let $\mu$ be the expected cost, which by the corollary is $d\cdot\text{OPT}$. We can upper-bound the "bad event" of the cost being very bad: by Markov's inequality we have $\prob{\text{cost} > 4\mu} \le \frac{1}{4}$. We chose a factor $4$ here because this will give us a nice bound later on; we could pick any number to obtain another bound. We can also upper-bound the "bad event" of the solution being infeasible, which we know (thanks to claim 10) to be upper-bounded by $\frac{1}{n^{c-1}} \le \frac{1}{2}$ for $d = c\cdot\ln(n)$ iterations. By [union bound](https://en.wikipedia.org/wiki/Boole%27s_inequality), the probability that no bad event happens is at least $1 - \frac{1}{4} - \frac{1}{n}$. Supposing $n > 4$, this probability is indeed greater than $\frac{1}{2}$. $\qed$

This claim tells us that choosing $d = c\cdot\ln(n)$, we have a $\bigO{\log n}$ approximation algorithm for the set cover problem.

## Multiplicative Weights Algorithm

### Warm-up
Suppose that you want to invest money on the stock market. To help you invest this money, you listen to $n$ experts. Every day, each of them tells you whether the stock will go up or down.

| Day  | Expert 1 | Expert 2 | Expert 3 | Expert 4 | Actual |
| :--: | :------: | :------: | :------: | :------: | :----: |
|  1   |    📈    |    📈    |    📈    |    📈    |   📈   |
|  2   |    📈    |    📈    |    📉    |    📈    |   📈   |
|  3   |    📈    |    📉    |    📈    |    📉    |   📉   |

All the experts were right on day 1, but expert 3 was wrong on day 2, and experts 1 and 3 were wrong on day 3.

Your goal is to devise a strategy that allows you to do as well as the best expert. For this warm-up example, we'll work under the assumption that there is a "perfect expert" who is never wrong.

Our strategy is then the following. At day $t$, let $S_t$ be the set of experts who have been right so far. We will follow the majority in $S_t$. This ensures that we'll be wrong at most $\log_2(n)$ times (we follow the majority, so we can divide the pool of trusted experts at least in half whenever we make a mistake).

### Formalization of the problem
We'll generalize and formalize the problem we saw above. The following game is played between an omniscient Adversary (the stock market) and an Aggregator (you), who is advised by $n$ experts. 

For $t = 1, \dots, T$ (days on the stock market), each expert $i \in [n]$ advises "yes" or "no" ("up" or "down"). The Aggregator predicts either yes or no. The Adversary, with knowledge of the Aggregator's prediction and of the expert advice, decides the yes-or-no outcome. The Aggregator observes the outcome, and suffers some cost if his prediction was incorrect.

Note that the Adversary's role is not to make the Aggregator be wrong all the time, which would be easy: seeing that it's omniscient, the Adversary could just observe the opposite outcome of what the Aggregator predicted. Instead, we can consider that the Adversary's role is to make the Aggregator look as bad as possible compared to the best expert.

The Aggregator's role is to make as few mistakes as possible, but since the experts may be unhelpful and the outcomes can be bad, the Aggregator can only hope for a performance guarantee relative to the best expert, in hindsight. To do so, it can track which experts are helpful; we'll see some good strategies for this.

The number of mistakes in excess of the best expert is called *(external) regret*.

### Weighted Majority (WM)
In a world where experts can be wrong (yes, really), we can somewhat "soften" our strategy. Instead of discarding them completely on their first mistake, we can just discount their advice. This leads us to the [Weighted Majority algorithm](https://www.sciencedirect.com/science/article/pii/S0890540184710091), which is defined as follows.

We begin by assigning a weight $w_i^{(1)}$ to each expert $i$, initialized at 1. Thereafter, for each day $t$:

- Aggregator predicts yes or no based on a majority vote, weighted by $\vec{w}^{(t)} = (w_1^{(t)}, \dots, w_n^{(t)})$
- After observing the outcome, for every mistaken expert $i$, set $w_i^{(t+1)} = w_i^{(t)} / 2$

We chose to update the experts' weights by a factor $\frac{1}{2}$, which leads us to some fast learning (maybe too fast!). 

> theorem "16.1"
> For any sequence of outcomes, any duration $T$ and any expert $i$:
> 
> $$
> \text{# of WM mistakes} \le 2.41 \cdot (\text{# of }i\text{'s mistakes}) + \log_2(n)
> $$

The $2.41$ seems very arbitrary, but we'll show where it comes from.

Let $i \in [n]$ be any expert. Let $\Phi^{(t)}$ defined as follows be a "potential function":

$$
\Phi^{(t)} = \sum_{i \in [n]} w_i^{(t)}
$$

Our strategy will be to bound $\Phi^{(T+1)}$ from below with expert $i$'s mistakes, and from above with WM's mistakes.

For the lower bound, we can observe that:

$$
\Phi^{(T+1)} 
= \sum_{j \in [n]} w_j^{(T+1)} 
\ge w_i^{(T+1)}
= \left(\frac{1}{2}\right)^{\text{# of } i \text{'s mistakes}}
$$

The inequality stems from the fact that all weights are always $\ge 0$.

For the upper bound, let's start by observing the following: $\Phi^{(1)} = n$ as all weights are initialized to 1. Additionally, whenever WM errs, we halve the weights for experts representing at least half of the total weights (since we follow the weighted majority). This means that we loose at least $\frac{1}{4}$ of the total weight:

$$
\Phi^{(t+1)} \le \frac{3}{4}\Phi^{(t)}
$$

This implies that we can bound the final value of the potential function as follows:

$$
\Phi^{(T+1)} \le \left(\frac{3}{4}\right)^{\text{# of WM mistakes}} \cdot \Phi^{(1)}
$$

Combining these bounds together, we get:

$$
\left(\frac{1}{2}\right)^{\text{# of } i \text{'s mistakes}}
\le
\Phi^{(T+1)}
\le
\left(\frac{3}{4}\right)^{\text{# of WM mistakes}} \cdot n
$$

Taking the $\log_2$ of both bounds yields:

$$
-(\text{# of }i\text{'s mistakes})
\le
\log_2(n) + \log_2\left(\frac{3}{4}\right) \cdot (\text{# of WM mistakes})
$$

So finally:

$$
\text{# of WM mistakes} 
\le
(1/\log_2(4/3)) \cdot (\text{# of }i\text{'s mistakes} + \log_2(n))
$$

We have $(1/\log_2(4/3)) \approx 2.41$, which proves the theorem. $\qed$

The 2.41 constant is a consequence of our arbitrary choice to halve the weights; if instead we choose to divide by a $(1+\epsilon)$ factor in the update rule:

$$
w_i^{(t+1)} = \begin{cases}
    w_i^{(t)} / (1 + \epsilon) & \text{if expert } i \text{ was wrong} \\
    w_i^{(t)} & \text{otherwise}
\end{cases}
$$

Then we achieve a more general formulation:

$$
\text{# of WM mistakes} \le 2(1 + \epsilon) \cdot (\text{# of }i\text{'s mistakes}) + \bigO{\frac{\log_2(n)}{\epsilon}}
$$

### Generalized Game with Randomized Strategies
We now allow the Aggregator to play a random strategy instead of always making deterministic predictions. Randomization is in fact often a good strategy to limit the effect of adversaries.

In this variation of the problem, we still have $t = 1, \dots, T$ days, on each of which all experts $i\in[n]$ give their advice. Previously, the answer could only be one of two options (up/down or yes/no), but we will generalize this to any number of possible options.

The Aggregator (whom we'll now call the Allocator) picks some distribution $\vec{p}^{(t)} = \left(p_1^{(t)}, \dots, p_n^{(t)} \right)$ over the experts. Now, $p_i^{(t)}$ represents the probability of following expert $i$'s advice.

The Adversary is still omniscient: with knowledge of the expert advice and of $\vec{p}^{(t)}$, it determines the cost vector $\vec{m}^{(t)} = \left(m_1^{(t)}, \dots, m_n^{(t)} \right) \in [-1, 1]^n$. The intended meaning of $m_i^{(t)}$ is the cost[^negative-cost] of following expert $i$'s advice on day $t$.

[^negative-cost]: A negative value of $m_i^{(t)}$ thus means that it was profitable to follow the expert's advice.

The expected cost is therefore:

$$
\expect{\text{cost at day } t} 
= \sum_{i\in[n]} p_i^{(t)} \cdot m_i^{(t)}
=: \vec{p}^{(t)} \cdot \vec{m}^{(t)}
$$

### Hedge Strategy
The Hedge strategy operates in the problem setting described above. It is parametrized by a learning parameter $\epsilon > 0$.

- Initially, set all expert weights $w_i^{(1)}$ to 1.
- For each day $t$:
    + Pick the distribution $p_i^{(t)} = w_i^{(t)} / \Phi^{(t)}$, where $\Phi^{(t)} = \sum_{i\in[n]} w_i^{(t)}$ is the potential function as defined previously.
    + After observing the cost vector $\vec{m}^{(t)}$, set $w_i^{(t+1)} = w_i^{(t)} \cdot \exp(-\epsilon \cdot m_i^{(t)})$

Note that:

- $\exp(-\epsilon \cdot m_i^{(t)}) < 1$ if $m_i^{(t)} > 0$
- $\exp(-\epsilon \cdot m_i^{(t)}) > 1$ if $m_i^{(t)} < 0$

This means that the weights increase when it was profitable to follow the expert, and decrease when it wasn't.

An alternative strategy is the Multiplicative Weights Update (MWU) strategy, which uses $w_i^{(t+1)} = w_i^{(t)} \cdot (1 - \epsilon \cdot m_i^{(t)})$. This is just as good, as it leads us to the same guarantee:

> theorem ""
> Suppose $\epsilon \le 1$, and $\vec{p}^{(t)}$ is chosen by Hedge for $t \in [T]$. Then for any expert $i$:
> 
> $$
> \expect{\text{final cost}} 
> = \sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}
> \le
> \sum_{t=1}^T m_i^{(t)} + \frac{\ln(n)}{\epsilon} + \epsilon T
> $$

Note that this inequality holds for any expert $i$, and in particular, for the best expert. Let's take a look at the terms in this inequality:

$$
\underbrace{\sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}}_{\text{our loss}}
\le \underbrace{\sum_{t=1}^T m_i^{(t)}}_{\text{loss of best expert}}
+   \underbrace{\frac{\ln(n)}{\epsilon} + \epsilon T}_{\text{small additive term}}
$$

This means that Hedge does as well as the best expert, within a small additive term. Note that this small error is minimized to be $\bigO{\sqrt{T}}$ when $\epsilon = \sqrt{\frac{\ln(n)}{T}}$.

Let's prove this theorem. Like before, our proof strategy will be to upper bound and lower bound the potential function $\Phi^{(t)}$.

**Lower bound**: We can lower-bound the final potential $\Phi^{(T+1)}$ as before:

$$
\Phi^{(T+1)} 
:=  \sum_{j\in [n]} w_j^{(T+1)} 
\ge w_i^{(T+1)} 
=   w_i^{(1)} \cdot \prod_{t=1}^T \exp\left(-\epsilon m_i^{(t)}\right)
=   \exp\left( -\epsilon \sum_{t=1}^T m_i^{(t)} \right)
$$

**Upper bound**: the proof for the upper bound will be somewhat longer. Let's start by bounding the individual update rule of the potential function:

$$
\begin{align}
\phi^{(t+1)} 

& = \sum_{j\in[n]} w_j^{(t+1)} \\

& = \sum_{j\in[n]} w_j^{(t)} \cdot \exp\left(-\epsilon m_j^{(t)}\right) \\

& \overset{(1)}{\le}  \sum_{j\in[n]} w_j^{(t)} \cdot \left(
    1 -\epsilon m_j^{(t)} + \epsilon^2 \left(m_j^{(t)}\right)^2
\right) \\

& \overset{(2)}{\le}  \sum_{j\in[n]} w_j^{(t)} \cdot \left(
    1 -\epsilon m_j^{(t)} + \epsilon^2
\right) \\

& = \sum_{j\in[n]} w_j^{(t)} \cdot (1 + \epsilon^2)
  - \sum_{j\in[n]} \epsilon w_j^{(t)} m_j^{(t)} \\

& \overset{(3)}{=} \phi^{(t)} (1 + \epsilon^2) 
  - \epsilon \sum_{j\in[n]} \phi^{(t)} p_j^{(t)} m_j^{(t)} \\

& = \Phi^{(t)} \left(1 + \epsilon^2 - \epsilon \vec{p}^{(t)}\cdot\vec{m}^{(t)}\right)  \\

& \overset{(4)}{\le} \Phi^{(t)} \cdot \exp\left(
    \epsilon^2 - \epsilon \vec{p}^{(t)}\cdot\vec{m}^{(t)}
\right)
\end{align}
$$

Step $(1)$ uses the the Taylor expansion of $e^{-x}$:

$$
e^{-x} 
= \sum_{i=0}^\infty \frac{(-x)^i}{i!} 
= 1 - x + \frac{x^2}{2} - \frac{x^3}{6} + \dots
$$

For $x \in [-1, 1]$, we have that $e^{-x} \le 1 - x + x^2$. We can use this fact to our advantage in the following, as the exponentiated term $-\epsilon m_j^{(t)}$ is in $[-1, 1]$ (because we supposed $0 < \epsilon \le 1$ in the theorem).

Step $(2)$ uses the fact that $\left(m_j^{(t)}\right)^2 \le 1$ as $m_j^{(t)} \in [-1, 1]$ by definition.

Step $(3)$ uses $\Phi^{(t)} p_j^{(t)} = w_j^{(t)}$, which stems from the definition of the Hedge strategy.

Step $(4)$ uses the same Taylor expansion, but in the other direction, using the fact that $1 + x \le e^x$.

This gives us an upper bound on $\Phi^{(t+1)}$ in terms of $\Phi^{(t)}$. We can use this bound repeatedly to find a bound for $\Phi^{(T+1)}$:

$$
\begin{align}
\Phi^{(T+1)}

& \le \Phi^{(T)} \cdot \exp\left(
    \epsilon^2 - \epsilon \vec{p}^{(T)}\cdot\vec{m}^{(T)}
\right) \\

& \le \Phi^{(T-1)} \cdot \exp\left(
    \epsilon^2 - \epsilon \vec{p}^{(T-1)}\cdot\vec{m}^{(T-1)}
\right) \cdot \exp\left(
    \epsilon^2 - \epsilon \vec{p}^{(T)}\cdot\vec{m}^{(T)}
\right) \\

& \vdots \\

& \le \Phi^{(1)}\cdot \exp\left(
    \epsilon^2 T - \epsilon \sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
\right) \\

& = n\cdot \exp\left(
    \epsilon^2 T - \epsilon \sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
\right) \\
\end{align}
$$

The last step uses the fact that all weights were initialized to 1, and thus that $\Phi^{(1)} = n$. Putting the bounds together, we get:

$$
\exp\left( -\epsilon \sum_{t=1}^T m_i^{(t)} \right)
\le
\Phi^{(T+1)}
\le
n\cdot\exp\left(
    \epsilon^2 T - \epsilon \sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
\right)
$$

Taking the natural logarithm on both sides of the bound yields:

$$
- \epsilon \sum_{t=1}^T m_i^{(t)}
\le 
\ln(n) + \epsilon^2 T 
- \epsilon \sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
$$

We get to the final result by dividing by $\epsilon$ and rearranging the terms. $\qed$

From this, we can infer a corollary that will be useful for solving covering LPs. For these problems, it's useful to consider the *average cost* incurred per day. We will also generalize the cost vector so that it can take values in $[-\rho, \rho]^n$ instead of just $[-1, 1]^n$. This $\rho$ is called the **width**.

> corollary "Corollary 3"
> Suppose $\epsilon \le 1$. For $t \in [T]$, let $\vec{p}^{(t)}$ be picked by Hedge, and assume the cost vectors are $\vec{m}^{(t)} \in [-\rho, \rho]^n$.
> 
> If $T \ge (4\rho^2 \ln n) / \epsilon^2$, then for any expert $i$:
> 
> $$
> \frac{1}{T}\sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
> \le
> \frac{1}{T} \sum_{t=1}^T m_i^{(t)} + 2\epsilon
> $$

This tells us that the average daily performance is as good as the best expert's average daily performance, within some linear term $2\epsilon$. The "average regret" is the difference between the algorithm's and the expert's average daily performances.

### Covering LPs
Covering LPs are defined as follows:

> definition ""
> A linear program of the form:
> 
> $$
> \begin{align}
> \textbf{minimize: }   & \sum_{j=1}^n c_j x_j   & \\
> \textbf{subject to: } 
>     & A x \ge b \\
>     & 0 \le x_j \le 1 & \forall j \\
> \end{align}
> $$
> 
> is a **covering** LP if all coefficients of the constraints and objective function are non-negative:
> 
> $$
> A \in \mathbb{R}_+^{m\times n}, \;
> b \in \mathbb{R}_+^m \text{ and }
> c \in \mathbb{R}_+^n
> $$

Note that covering LPs require the variables to be in $[0, 1]$ (whereas the more general form of LPs simply requires $x \ge 0$). Vertex cover and set cover, for instance, satisfy this requirement. 

### Hedging for LPs
#### Example
An example of a covering LP is:

$$
\begin{align}
\textbf{minimize: }   & x_1 + 2 x_2 & \\
\textbf{subject to: } 
    &   x_1 + 3 x_2 \ge 2 \\
    & 2 x_1 +   x_2 \ge 1 \\
    & x_i \ge 0 & \forall i = 1, \dots, n \\
\end{align}
$$

This LP has two constraints: we could simplify it by adding up those constraints into one, with weights $p_1 = p_2 = \frac{1}{2}$, which would give us the following LP:

$$
\begin{align}
\textbf{minimize: }   & x_1 + 2 x_2 & \\
\textbf{subject to: } 
    & 1.5 x_1 + 2 x_2 \ge 1.5 \\
    & x_i \ge 0 & \forall i = 1, \dots, n \\
\end{align}
$$

This has an optimal solution of $x_1 = 1, x_2 = 0$, but that doesn't work in the original LP. In general, any solution that is valid in the original LP will be valid in the simplified summed LP, but that implication does not hold the other way around. This means that the cost of the simplified LP is lower (as it allows for more solutions).

To remediate this, we can perhaps update the weights $p_1$ and $p_2$: we need to increase the weights of the satisfied constraint, and decrease the weights of the unsatisfied constraint. This will lead us to using the Hedge strategy to solve LPs.

#### General idea
When using Hedge for LPs, the "experts" are the constraints of the LP. Hedge maintains a weight distribution over the constraints, and iteratively updates those weights based on the cost function at each step.

The "simplified problem" as we defined it above can more strictly be defined as:

$$
\begin{align}
\textbf{minimize: }   & \sum_{j=1}^n c_j x_j \\
\textbf{subject to: } 
    & \left(
        \sum_{i=1}^m p_i A_i
    \right) \cdot x 
    \ge \sum_{i=1}^m p_i b_i \\
    & 0 \le x \le 1 \\
\end{align}
$$

The oracle we need takes a probability distribution $\vec{p} = \left(p_1, \dots, p_m\right)$ over the $m$ experts such that $\sum_{i=1}^m p_i = 1$, and outputs an optimal solution $x^\*$ to the above "simplified problem".

#### Hedge Algorithm for Covering Linear Programs
The Hedge Algorithm plays the role of the Aggregator/Allocator, determining the $\vec{p}^{(t)}$, but also that of the Adversary, determining the cost $\vec{m}^{(t)}$ using the result of the oracle.

Initially, we assign each constraint $i$ a weight $w_i^{(1)} := 1$.

Then, for each step $t$, we pick the distribution as follows:

$$
p_i^{(t)} = \frac{w_i^{(t)}}{\Phi^{(t)}},
\quad
\text{where } \Phi^{(t)} = \sum_{i\in[n]} w_i^{(t)}
$$

Now, we need to play the role of the Adversary. We let $x^{(t)}$ be the solution returned by the oracle on the LP created using the convex combination $\vec{p}^{(t)}$ of constraints. As we said above, the cost $c \cdot x^{(t)}$ of the "simplified" LP is at most that of the original LP. We can define the cost of the constraint $i$ as:

$$
m_i^{(t)} 
= \sum_{j=1}^n A_{ij} x_j^{(t)} - b_i 
= A_i x^{(t)} - b_i
$$

We have a positive cost if the constraint is satisfied (so the weight will be decreased by Hedge), and a positive cost if not (which increases the weight).

After observing the cost, we can go back to playing the Allocator and update the weights as always in Hedge:

$$
w_i^{(t+1)} = w_i^{(t)} \cdot \exp\left(-\epsilon \cdot m_i^{(t)}\right)
$$

After $T$ steps, the algorithm should output the average of the constructed solutions:

$$
\bar{x} = \frac{1}{T} \sum_{t=1}^T x^{(t)}
$$

#### Analysis
Let's now analyze how we should pick $T$ and see the properties of the algorithm. 

First off, since we proved that Hedge works for an adversarial, omniscient construction of the cost vectors, it will definitely work for this construction.

Let's define $\rho$ to be a bound on $\abs{m_i^{(t)}}$, basically answering "how big can the cost be"? Let:

$$
\rho = \max_{1 \le i \le m} \set{max(b_i, A_i \vec{1} - b_i)}
$$

This means that $\rho \ge b_i$ and $\rho \ge \sum_j A_{ij} b_i$, $\forall i \in [n]$. By corollary 3, for $\epsilon \in [0, 1]$ and $T \ge (4\rho^2 \ln m) / \epsilon^2$, and for any constraint $i$, we have:

$$
\frac{1}{T}\sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}
\le 
\frac{1}{T}\sum_{t=1}^T \vec{m}_i^{(t)} + 2\epsilon
$$

Let's consider the sum in the left-hand side of this expression, corresponding to the "final performance":

$$
\begin{align}
\sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}
& = \sum_{t=1}^T \left(
    \sum_i \vec{p}_i^{(t)} \cdot \vec{m}_i^{(t)}
\right) \\

& = \sum_{t=1}^T \left(
    \underbrace{\sum_i \vec{p}_i^{(t)} \cdot \left(
        A_i x^{(t)} - b_i
    \right)}_{(*)}
\right) \\

& \ge 0 \\
\end{align}
$$

Note that $(*)$ is non-negative since we're working in a covering LP and because the oracle only outputs feasible solutions $x^{(t)}$, which allows us to conclude in the final step that the whole expression is non-negative. The inequality we derived from corollary 3 is therefore:

$$
0 \le
\frac{1}{T}\sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}
\le 
\frac{1}{T}\sum_{t=1}^T \vec{m}_i^{(t)} + 2\epsilon
$$

Rearranging the terms, we get that:

$$
-2\epsilon 
\le
\frac{1}{T}\sum_{t=1}^T \vec{m}_i^{(t)}
= \frac{1}{T}\sum_{t=1}^T \left(
    A_i x^{(t)} - b_i
\right)
= A_i \bar{x} - b_i
$$

This implies that for every constraint $i$:

$$
A_i \bar{x} \ge b_i - 2\epsilon
$$

This means that the solution $\bar{x}$ is always **almost feasible**: it might break some constraints with up to $2\epsilon$. 

The cost $c^T\bar{x}$ is **at most the cost of an optimal solution** to the original LP since each solution $x^{(t)}$ to the "simplified LP" has a cost lower than the original LP. 

How do we set the right parameters? Let's look at the [set cover](#set-cover) LP relaxation. We have that $\rho \le n$ since the LP uses $b_i = 1\, \forall i \in [m]$ and $A_{ij}$ is always either 0 or 1. Therefore, if we define $\rho$ as above, this holds. We can set $T = (4n^2 \ln m)/\epsilon^2$[^more-careful-analysis]: this gives us an "almost feasible" solution $\bar{x}$:

[^more-careful-analysis]: A more careful analysis can tell us to use $\approx n \ln m / \epsilon^2$.

$$
\sum_{e\in S} x_e \ge 1 - 2\epsilon
$$

We can obtain a feasible (almost optimal) solution by using:

$$
x^* = \frac{\bar{x}}{1-2\epsilon}
$$

## Simplex method
The simplex method is an algorithm to solve LPs. Its running time is exponential in the worst case, but runs very fast in practice. This makes it a very used algorithm, more so than other polynomial-time algorithms that are often slower in practice.

A small overview of the steps of the simplex method is given below. This is a very rough overview; the lecture notes go over example runs of the simplex method, so check those for the details of how to run simplex.

1. Rewrite the constraints as equality, introducing "slack variables" $s_1, s_2, \dots$
2. Set $z$ to be equal to the objective function
3. Set $x_i = 0$, so $s_i = b_i$, $\forall i \in [n]$
4. Maintain a simplex tableau with non-zero variables to the left of the equality, and the rest to the right.
5. Select a variable ($s$ or $x$) with positive weight (or negative if we're minimizing) in the formulation of $z$ to increase. Say we chose $x_k$. Increase it as much as the constraints will allow.
6. Compensate by modifying the value of all left-hand side constraints in which $x_k$ appears.
7. Pivot[^pivot-joke]: in the constraint that dictated the new value of $x_k$, swap the left-hand side (call it $s_j$) with $x_k$: $s_j \leftrightarrow x_k$.
8. Rewrite the constraints to use the newly determined formulation of $x_k$. This will also update $z$.
9. Go to step 5; stop when we can no longer increase any variables.

[^pivot-joke]: There's a Friends reference to be made here, but I wouldn't ever be the type of person to make [that kind of joke](https://www.youtube.com/watch?v=R2u0sN9stbA)

A few problems can arise when trying to apply the simplex method, which we'll discuss here:

- **Unboundedness**: If the polytope defined by the given constraints is not bounded, the optimal solution is infinite.
- **Degeneracy**: it might happen that we cannot increase any variable but still need to pivot two of them to proceed. This doesn't mean that the simplex method won't terminate, but this is an edge case that must be handled. One possible solution is to use a lexicographic ordering of variables.
- **Initial vertex**: Sometimes, it's easy to find that $\vec{x} = \vec{0}$ is a feasible solution, but other times it may be harder. To find a feasible starting point, we may have to solve another LP to find a starting point (Phase I), and then do what we described above to solve the original LP (Phase II).
- **Infeasibility**: If the constraints define an empty polytope, there is no feasible starting point; Phase I will detect this.

## Randomized Algorithms
As before, when we discussed the possible "bad events" in approximation algorithms, there are two kinds of claims that we want to make about randomized algorithms:

- It gives (close to) correct solutions with good probability
- The expected cost (value of the objective function) is close to the cost of the optimal solution.

If we have an algorithm that generates the correct (optimal) solution with probability $p > 0$, we can obtain an algorithm that succeeds with high probability, even when $p$ is low. The trick is to "boost" the probabilities by running the algorithm $k$ times: the probability that one run succeeds is $1 - (1 - p)^k$. 

For small values of $p$, we'll generally use the approximation of $e^{-p}$ for $(1-p)$. It follows that one of the repeated runs will find the correct (optimal) solution with probability at least $1-e^{-pk}$. We can pick $k$ so that this number is close to 1.

### Minimum cut problem
- **Input**: An undirected graph $G = (V, E)$ with $n = \abs{V}$ vertices
- **Output**: An edge set $S$ that is a min-cut of the graph

To define this min-cut more formally, we'll need to introduce $E(S, \bar{S})$, the set of edges that have *exactly one* endpoint in $S$:

$$
E(S, \bar{S}) = \set{(u, v) \in E : u \in S, v \notin S}
$$

In the min-cut problem, we're looking the partition of $G$ where the two parts are joined together with the minimum number of edges:

$$
\min_{\emptyset \subset S \subset V} \abs{E(S, \bar{S})}
$$

### Karger's algorithm

#### Algorithm
Karger's algorithm solves the min-cut problem in $\bigO{n^4 \log n}$. A single run, as defined below, is $\bigO{n^2}$, but as [we'll see later](#boosting-the-probability-of-success), we may have to run it $\bigO{n^2 \log n}$ times to find a min-cut with high probability.

{% highlight python linenos %}
def karger(G, n):
    """
    Input: Graph G = (V, E) of size n
    Output: Size of the min-cut
    """
    for i in range(1, n - 2):
        choose edge (u, v) uniformly at random
        contract it
    size_min_cut = number of edges between two final super-nodes
    return size_min_cut
{% endhighlight %}

Let's define how the contracting procedure happens. Consider the following graph:

{% graph %}
graph [nodesep=0.7, ranksep=0]
bgcolor="transparent"
rankdir="LR"

a -- b [label="e"]
a -- b -- c -- d -- a
b -- c -- d
b -- c
{% endgraph %}

If we contract edge $e$, we get the following graph:

{% graph neato %}
graph [nodesep=0.7, ranksep=0]
bgcolor="transparent"
rankdir="LR"

ab -- c -- d -- ab
ab -- c -- d
ab -- c
{% endgraph %}

We've created a new super-node $ab$. This reduces the total number of nodes in the graph by 1. We do not remove loops when contracting an edge.

#### Analysis
Let $(S^\*, \bar{S^\*})$ be the optimal minimum cut of $G$, of size $k$. We'll work our way towards analyzing the probability that the algorithm finds the optimal cut. 

First, let's take a look at the probability that a single edge is in the optimal min-cut. This corresponds to the probability of the algorithm chose "the wrong edge" when picking uniformly at random: if it contracts an edge that should have been in $E(S^\*, \bar{S^\*})$, then it will not output the optimal solution.

> claim "Karger Claim 1"
> The probability that a uniformly random edge is in $E(S^\*, \bar{S^\*})$ is at most $2/n$

Consider the first contraction of the algorithm (this is without loss of generality). Let $e$ be a uniformly random edge in $G$:

$$
\newcommand{\mincut}[0]{(S^*, \bar{S^*})}
\newcommand{\mincutedges}[0]{E\mincut}

\prob{e \in \mincutedges}
= \frac{\abs{\mincutedges}}{\abs{E}}
= \frac{k}{\abs{E}}
$$

We do not know in advance what the value of $k$ is, so we'll upper-bound $\frac{k}{\abs{E}}$ by lower-bounding $\abs{E}$.

Let $d(v)$ be the degree of a vertex $v$. The [handshaking lemma](https://en.wikipedia.org/wiki/Handshaking_lemma) tells us that:

$$
\sum_{v \in V} d(v) = 2 \abs{E} 
$$

If the min-cut is of size $k$, we can lower bound $d(v)$ by $k$. This is because if the size of the min-cut is $k$, no vertex $w$ can have degree less than $k$; otherwise, we'd have chosen $S = \set{w}$ and achieved a smaller min-cut. Therefore, $k \le d(v)$.

It follows then that:

$$
2\abs{E} = \sum_{v \in V} d(v) \ge n\cdot k
$$

With this, we've bounded our probability:

$$
\prob{e \in \mincutedges} 
= \frac{k}{\abs{E}}
\le \frac{k}{nk / 2}
= \frac{2}{n}               \qed
$$

In the following, we'll need to use the following property of the algorithm:

> claim "Karger Fact 2"
> For any graph $G$, when we contract an edge $e$, the size of the minimum cut does not decrease.

We won't prove this, but it seems intuitive. If $G'$ is a version of $G$ where $e$ has been contracted, then $\text{MINCUT}(G) \le \text{MINCUT}(G')$.

Now, let's try to analyze the probability that the full algorithm returns the correct solution:

> theorem "Karger Theorem 3"
> For any graph $G = (V, E)$ with $n$ nodes and a min-cut $(S^\*, \bar{S^\*})$, Karger's algorithm returns $(S^\*, \bar{S^\*})$ with probability at least $\frac{2}{n(n-1)} = 1 / {n \choose 2}$

Let $A_i$ be the probability that the edge picked in step $i$ of the loop is not in $\mincutedges$. The algorithm succeeds in finding the min-cut $\mincut$ if $A_1, A_2, \dots, A_{n-2}$ all occur. By the chain rule, the probability of this is:

$$
\prob{A_1, A_2, \dots, A_{n-2}}
= \prob{A_1} \cdot \prob{A_2 \mid A_1} \cdot \dots \cdot \prob{A_{n-2} \mid A_1, A_2, \dots, A_{n-3}}
$$

By the two previous claims, seeing that there are at most $n - i + 1$ edges to choose from at step $i$, then for all $i$:

$$
\prob{A_i \mid A_1, A_2, \dots, A_{i-1}} 
\ge
1 - \frac{2}{n - i + 1}
$$

Therefore:

$$
\begin{align}
\prob{A_1, A_2, \dots, A_{n-2}}
& \overset{(1)}{\ge}
    \left(1 - \frac{2}{n}   \right) 
    \left(1 - \frac{2}{n-1} \right)
    \dots
    \left(1 - \frac{2}{3} \right) \\
& \overset{(2)}{=}
    \frac{n-2}{n} \cdot
    \frac{n-3}{n-1} \cdot
    \frac{n-4}{n-2} \cdot
    \dots \cdot
    \frac{3}{5}\cdot\frac{2}{4}\cdot\frac{1}{3} \\
& \overset{(3)}{=}
    \frac{2}{n(n-1)} \\
& \overset{(4)}{=} 1 / {n \choose 2}
\end{align}
$$

Step $(1)$ uses the inequality we defined above. 

Step $(2)$ rewrites $(1 - \frac{2}{n - i + 1})$ as $\frac{n - 2 - i + 1}{n - i + 1} = \frac{n-i-1}{n-i+1}$. 

Step $(3)$ uses the structure of these fractions to cancel out terms (notice how the numerator appears in the denominator two fractions later).

Finally, $(4)$ uses the definition of the binomial coefficient. $\qed$

This leads us to the following corollary:

> corollary "Karger Corollary 4"
> Any graph has at most $n \choose 2$ min-cuts.

The proof for this is short and sweet: suppose that there is a graph $G$ that has more than $n \choose 2$ min-cuts. Then, for one of those cuts, the algorithm would find that exact cut with probability less that $1 / {n \choose 2}$, which is a contradiction. $\qed$

#### Boosting the probability of success
The algorithm runs in $\bigO{n^2}$, but the probability of success is $\ge 1 {n \choose 2}$, which is $\bigO{1/n^2}$. As [we said above](#randomized-algorithms), we can "boost" this probability of success to $1 - 1/n$ by running the same algorithm a bunch of times. If we run it $\bigO{n^2 \log n}$ times, we can get a probability of success of $1 - 1/n$:

$$
\begin{align}
\prob{\text{does not return min-cut}} 
& = \prob{\text{all } m \text{ runs fail}} \\
& \le \left(1 - \frac{1}{n^2}\right)^m \\
& \le \exp\left(-\frac{1}{n^2} \right)^m \\
& \le \frac{1}{n} \quad \text{for } m = n^2 \log n
\end{align}
$$

### Karger-Stein's algorithm
Karger's algorithm only fails when it contracts an edge of the min-cut. In the beginning, that probability is $2 / n$, and towards the end it goes up to a constant; in the very last step, the probability that we contract an edge of the min-cut is $1/3$.

This means that we'll often run the first steps correctly, only to make mistakes towards the very end. Karger-Stein fixes this by running more copies as the graph gets smaller.

{% highlight python linenos %}
def karger_stein(G, n):
    """
    Input: Graph G = (V, E) of size n
    Output: (min cut, size)
    """
    if n == 2:
        return E, len(E)
    for i in range(1, n - n/sqrt(2)):
        choose edge (u, v) uniformly at random
        contract it
    let G' be the contracted graph
    E1, n1 = karger_stein(G', m)
    E2, n2 = karger_stein(G', m)
    return best cut of the two
{% endhighlight %}

To analyze the running time, let $T(n)$ be the time that it takes to compute the min-cut of a graph of size $n$:

$$
T(n) = \bigO{n^2} + 2T(n/\sqrt{2})
$$

Using the [master theorem](/algorithms/#master-theorem) to solve this recursion, we find that the algorithm runs in $\bigO{n^2 \log n}$.

> theorem "Karger-Stein Theorem 5"
> The Karger-Stein algorithm finds a min-cut with probability at least $1 / 2\log n$.

Proof todo $\qed$

We can boost this probability to $1 - 1/n$ by running the algorithm $\log^2 n$ times.

## Polynomial identity testing
Suppose that we're given two polynomials $p(x)$ and $q(x)$ of degree $d$. We only have access to an oracle that allows us to evaluate the polynomial, but not to see its definition. We'd like to know if $p$ and $q$ are identical, i.e. whether $p(x) - q(x) = 0$ for all inputs $x \in \mathbb{R}^d$.

### Schwartz-Zippel
The Schwartz-Zippel lemma tells us the following.

> lemma "Schwartz-Zippel Lemma"
> Let $p(x_1, \dots, x_n)$ be a **nonzero** polynomial of $n$ variables with degree $d$. Let $S \subseteq \mathbb{R}$ be a finite set, with at least $d$ elements in it. If we assign $x_1, \dots, x_n$ values from $S$ independently and uniformly at random, then:
> 
> $$
> \prob{p(x_1, \dots, x_n) = 0} \le \frac{d}{\abs{S}} 
> $$ 

#### Proof for one dimension
Let's start by proving this for $d = 1$. We want to know whether $p(x) = q(x)$ for all inputs $x$. As we saw above, this is equivalent to answering whether $g(x) = p(x) - q(x) = 0$. When the polynomial is one-dimensional, we can write it as follows:

$$
g(x) = \sum_{i=1}^n a_i x_i
$$

If $g \ne 0$ then $\exists i : a_i \ne 0$. Suppose $g$ is a non-zero polynomial; we can then write the probability of it evaluating to zero as:

$$
\begin{align}
\prob{g(x_1, \dots, x_n) = 0} 
& = \prob{\sum_{j=1}^n a_j x_j = 0} \\
& = \prob{a_i x_i = - \sum_{j \ne i} a_j x_j}
\end{align}
$$

Writing the probability in this form is called the *principle of deferred decision*. We set all the $x_1, \dots, x_n$ except $x_j$ arbitrarily; this means that we can now see the sum in the last line as a constant $c$. What's left is the following:

$$
\prob{a_i x_i = c}
$$

There are $\abs{S}$ choices for $x_i$, and at most one satisfies $a_i x_1 = c$, so the final result is:

$$
\prob{g(x_1, \dots, x_n) = 0}
= \prob{a_i x_i = c}
\le \frac{1}{\abs{S}}

\qed
$$

#### General proof
Todo.

#### Matrix identity
We can use this for identity testing of matrices too; suppose we are given three $n\times n$ matrices $A, B, C$. We'd like to test whether $AB = C$. Matrix multiplication is expensive ($\bigO{n^3}$ or [slightly less](/algorithms/#strassens-algorithm-for-matrix-multiplication)). Instead, we can use the Schwartz-Zippel:

> theorem "Schwartz-Zippel for matrices"
> If $AB \ne C$ then:
> 
> $$
> \mathbb{P}_{x_i \sim S}\left[
>   ABx \ne Cx
> \right] \ge 1 - \frac{1}{\abs{S}}
> $$

Rather than infer it from Schwartz-Lippel, we'll give a direct proof of this.

### Perfect matching
### Adjacency matrix
Let $G = (A \cup B, E)$ be a $n\times n$ bipartite graph.We can represent the graph as a $n\times n$ adjacency matrix having an entry if nodes are connected by an edge:

$$
A_{ij} = \begin{cases}
x_{ij} & \text{if } (v_i, v_j) \in E \\
0      & \text{otherwise}
\end{cases}
$$

For instance:

{% graph %}
graph [nodesep=0.3, ranksep=2]
bgcolor="transparent"
rankdir="LR"

subgraph cluster_left {
    color=invis
    a b c
}

subgraph cluster_right {
    color=invis
    d e f
}

a -- d
b -- e -- c -- f -- b
{% endgraph %}

The above graph would have the following matrix representation:

$$
A = \begin{bmatrix}
x_{ab} & 0      & 0      \\
0      & x_{be} & x_{bf} \\
0      & x_{ce} & x_{cf} \\
\end{bmatrix}
$$

#### Bipartite graphs
We have a nice theorem on this adjacency matrix:

> theorem "Perfect Matching and Determinant"
> A graph $G$ has a perfect matching **if and only if** the determinant $\det(A)$ is not identical to zero.

Proof todo

#### General graphs
This result actually generalizes to general graphs, though the proof is much more difficult. If we construct the following matrix (called the Tutte matrix):

$$
A_{ij} = \begin{cases}
x_{ij}  & \text{if } (v_i, v_j) \in E, \text{ and } i < j \\
-x_{ij} & \text{if } (v_i, v_j) \in E, \text{ and } i \ge j \\
0       & \text{otherwise}
\end{cases}
$$

> theorem "General Graph Matching"
> Graph $G$ has a perfect matching **if and only if** $\det(A)$ is not identical to zero.


Todo finish lecture 12

## Sampling and Concentration Inequalities
For this chapter, suppose that there is an unknown distribution $D$, and that we draw independent samples $X_1, X_2, \dots, X_n$ from $D$ and return the mean:

$$
X = \frac{1}{n} \sum_{i=1}^n X_i
$$

The law of large numbers tells us that as $n$ goes to infinity, the empirical average $X$ converges to the mean $\expect{X}$. In this chapter, we address the question of how large $n$ should be to get an $\epsilon$-additive error in our empirical measure.


### Markov's inequality
Consider the following simple example. Suppose that the average Swiss salary is 6000 CHF per month. What fraction of the working population receives at most 8000 CHF per month?

One extreme is that everyone earns exactly the same amount of 6000 CHF, in which case the answer is 100%. The other extreme is that a fraction of all workers earn 0 CHF/month; in the worst case, $\frac{1}{4}$ of all workers earn 0 CHF/month, while the rest earns 8000.

Markov's inequality tells us about this worst-case scenario. It allows us to give a bound on the average salary $X$ for the "worst possible" distribution.

> theorem "Markov's inequality"
> Let $X \ge 0$ be a random variable. Then, for all $k$:
> 
> $$
> \prob{X \ge k \cdot \expect{X}} \le \frac{1}{k}
> $$
> 
> Equivalently:
> 
> $$
> \prob{X \ge k} \le \frac{\expect{X}}{k}
> $$

In the salary example, $X$ denotes the average salary. We know that $\expect{X} = 6000$ and $k = \frac{4}{3}$. 

The proof can be stated in a single line:

$$
\expect{X} 
=   \sum_i \prob{X = i} \cdot i 
\ge \sum_{i \ge k} \prob{X = i} \cdot i
\ge \sum_{i \ge k} \prob{X = i} \cdot k
=   k \cdot \prob{X \ge k}

\qed
$$

This proof is tight, meaning that all inequalities are equalities if the distribution of $X$ only has two points mass:

$$
X = \begin{cases}
0 & \text{with probability } 1 - 1/k \\
k + \epsilon & \text{with probability } 1/k \\
\end{cases}
$$

### Variance
Markov's inequality is a bound we can give if we don't know much about the distribution $D$. Indeed, if all we know is the expectation of $D$, Markov's inequality is the best bound we can give. 

We can get a stronger bound if we know the variance of the distribution.

> definition "Variance"
> The variance of a random variable $X$ is defined as:
> 
> $$
> \var{X} = \expect{(X - \expect{X})^2} = \expect{X^2} - \expect{X}^2
> $$

### Chebyshev's inequality
Using the variance of the distribution, we can give the following bound on how much the empirical average will diverge from the true mean:

> theorem "Chebyshev's inequality"
> For any random variable $X$,
> 
> $$
> \prob{\abs{X - \expect{X}} > \epsilon} < \frac{\var{X}}{\epsilon^2}
> $$
> 
> Equivalently:
> 
> $$
> \prob{\abs{X - \expect{X}} > k\sigma} \le \frac{1}{k^2}
> $$
> 
> where $\sigma = \sqrt{\var{X}}$ is the standard deviation of $X$.

Note that we used strict inequality, but that these can be replaced with non-strict inequalities without loss of generality.

It turns out that Chebyshev's inequality is just Markov's inequality applied to the variance random variable $Y := (X - \expect{X})^2$. Indeed, by Markov:

$$
\prob{Y \ge \epsilon^2} \le \frac{\expect{Y}}{\epsilon^2}
$$

In other words:

$$
\prob{\abs{X - \epsilon{X}}^2 \ge \epsilon^2} \ge \frac{\var{X}}{\epsilon^2}
$$

Taking the square root on both sides yields:

$$
\prob{\abs{X - \expect{X}} \ge \epsilon} \ge \frac{\var{X}}{\epsilon^2}
\qed
$$

### Polling
We can use Chebyshev's inequality to answer the question we raised in the beginning of this section, namely of estimating a mean $\mu$ using independent samples of the distribution $D$.

By linearity of expectation, mean $\mu$ is the same thing as $\expect{X}$:

$$
\expect{X} = \expect{\frac{1}{n} \sum_i X_i} = \mu
$$

We can use Chebyshev's inequality to upper bound the following:

$$
\prob{\abs{\frac{X_1 + X_2 + \dots + X_n}{n} - \mu} \ge \epsilon}
$$

To use Chebyshev's inequality, we first need to calculate the variance. To do that, we will first introduce the idea of *pairwise independence*.

> definition "Pairwise independence"
> A set of random variables $X_1, X_2, \dots, X_n$ are *pairwise independent* if for all $1 \le i, j \le n$:
> 
> $$
> \expect{X_i X_j} = \expect{X_i} \expect{X_j}
> $$

Note that full independence implies pairwise independence.

> lemma "Variance of sums"
> For any set of pairwise independent $X_1, \dots, X_n$:
> 
> $$
> \var{X_1 + \dots + X_n} = \var{X_1} + \dots + \var{X_n}
> $$

We can write:

$$
\begin{align}
\var{X_1 + \dots + X_n}
& = \expect{(X_1 + \dots + X_n)^2} - (\expect{X_1} + \dots + \expect{X_n} )^2 \\
& = \expect{\sum_{i, j} X_i X_j} - \sum_{i, j} \expect{X_i} \expect{X_j} \\
& \overset{(1)}{=} \sum_{i=1}^n \left( \expect{X_i^2} - (\expect{X_i})^2 \right) \\
& = \sum_{i=1}^n \var{X_i} 
\end{align}
$$

In step $(1)$ we used pairwise independence. $\qed$

Going back the polling example, we use the above lemma. Since the samples are independent, they're also pairwise independent, so by the lemma:

$$
\begin{align}
\var{X} 
& = \var{\frac{X_1 + \dots + X_n}{n}} \\
& = \frac{1}{n^2} \var{X_1 + \dots + X_n}  \\
& = \frac{1}{n^2} (\var{X_1} + \dots + \var{X_n}) \\
& = \frac{\var{D}}{n} \\
\end{align}
$$

By Chebyshev's inequality:

$$
\prob{\abs{X - \mu} \ge \epsilon} \le \frac{\var{D}}{n\epsilon^2}
\label{eq:test123}
$$

For the following discussion, let's suppose that our poll was about whether people would vote yes or no in a referendum. This means that the random variables $X_i$ are independent Bernoulli variables:

$$
X_i = \begin{cases}
1 & \text{with probability } p \\
0 & \text{with probability } 1 - p \\
\end{cases}
$$

Here, $p$ represents the fraction of the population that would vote yes. We want to estimate $p$ (the expectation of the Bernoulli trial) within $\epsilon$ additive error. To do this, we calculate the variance of $X_i$, for which we need to know $\expect{X_i}^2$ and $\expect{X_i^2}$.

We know that the expectation of a Bernoulli variable is $\expect{X_i} = p$. The second moment is:

$$
\expect{X_i^2} = 1^2 \cdot p + 0^2 \cdot (1 - p) = p
$$

Therefore, the variance is:

$$
\var{X_i} = \expect{X_i^2} - \expect{X_i}^2 = p - p^2 = p(1-p) \le \frac{1}{4}
$$

This confirms that the variance of a Bernoulli variable is $p(1-p)$, which we maybe already knew. In the worst case, $p = \frac{1}{2}$ gives us an upper-bound of $\frac{1}{4}$ on the variance.

By the bound we obtained with Chebyshev, we have:

$$
\prob{\abs{\frac{\sum_i X_i}{n} - p} \ge \epsilon} \le \frac{1}{4n\epsilon^2}
$$

This means that to achieve an $\epsilon$-additive error with probability $1 - \delta$, we need $\bigO{\frac{1}{\delta\epsilon^2}}$ many samples. The important part of the above inequality is that the size $n$ of the sample is independent of the size $N$ of the population.

For instance, suppose we chose 10 000 individuals randomly from the population, and calculated the empirical mean. By the above inequality, with probability 15/16, our estimate is within 2% of the true mean[^used-numbers].

[^used-numbers]: We obtain this by setting $\epsilon = 0.02$ and $n = 10 000$. This tells us the probability that our empirical average is off by more than $\epsilon = 0.02$, which is $\frac{1}{4n\epsilon^2} = \frac{1}{16}$.

### Chernoff bounds
The Chernoff bounds, also called *strong concentration bounds*, give us quantitative bounds for the convergence described by the law of large numbers. If $X$ is an average of independent random variables with standard deviation $\sigma$ and satisfy other properties, then:

$$
\prob{\abs{X - \expect{X}} \ge k\sigma} \le e^{-\Omega(k^2)}
$$

This is an exponentially improved bound compared to Chebyshev's inequality. To get this strong bound, we need $X$ to be an average of mutually independent random variables, which is a stronger assumption than the pairwise independence needed for Chebyshev.

There are different formulations of Chernoff bounds, each tuned to different assumptions. We start with the statement for a sum of independent Bernoulli trials:

> theorem "Chernoff bounds for a sum of independent Bernoulli trials"
> Let $X = \sum_{i = 1}^n X_i$ where $X_i$ = 1 with probability $p_i$ and $X_i = 0$ with probability $1 - p_i$, and all $X_i$ are independent. Let $\mu = \expect{X} = \sum_{i=1}^n p_i$. Then:
> 
> 1. **Upper tail**: $\prob{X \ge (1 + \delta)\mu} \le \exp{\left(-\frac{\delta^2}{2+\delta}\mu\right)}$ for all $\delta > 0$
> 2. **Lower tail**: $\prob{X \le (1 - \delta)\mu} \le \exp{\left(-\frac{\delta^2}{2}\mu\right)}$ for all $\delta > 0$

Another formulation of the Chernoff bounds, called Hoeffding's inequality, applies to bounded random variables, regardless of their distribution:

> theorem "Hoeffding's Inequality"
> Let $X_1, \dots, X_n$ be independent random variables such that $a \le X_i \le b$ for all $i$ Let $X = \sum_{i=1}^n X_i$ and set $\mu = \expect{X}$. Then:
> 
> 1. **Upper tail**: $\prob{X \ge (1 + \delta)\mu} \le \exp{\left(-\frac{2\delta^2\mu^2}{n(b-a)^2}\right)}$ for all $\delta > 0$
> 2. **Lower tail**: $\prob{X \ge (1 - \delta)\mu} \le \exp{\left(-\frac{-\delta^2\mu^2}{n(b-a)^2}\right)}$ for all $\delta > 0$

<br>

#### Polling with Chernoff bounds
We can use the Chernoff bounds in our polling example:

$$
\begin{align}
\prob{\abs{\frac{\sum_{i=1}^n X_i}{n} - p} \ge \epsilon}
& =   \prob{\abs{\sum_{i=1}^n X_i - pn} \ge n\epsilon} \\
& \ge \prob{\sum_{i=1}^n X-i \ge (1 + \frac{\epsilon}{p})pn}
    + \prob{\sum_{i=1}^n X-i \le (1 + \frac{\epsilon}{p})pn} \\
& \ge \exp{-\frac{\epsilon^2n}{3}} + \exp{-\frac{\epsilon^2n}{2}}
\end{align}
$$

If we want to estimate $p$ within an additive error $\epsilon$ with probability $1 - \delta$ we can simply let:

$$
n = 3\frac{\ln(2/\delta)}{\epsilon^2}
$$

To illustrate the difference between Chernoff and Chebyshev, suppose we wanted to estimate $p$ with additive error $\epsilon$ with probability $1 - \delta$. If we wanted this probability of success to be $1 - 2^{-100}$, with Chebyshev we would need $2^{100}/\epsilon^2$ samples, whereas we only need $100/\epsilon^2$ with Chernoff. 

#### Proof sketch of Chernoff bounds
We will give the proof for the upper tail bound; the lower tail is analogous. For any $s > 0$:

$$
\prob{X \ge a} 
= \prob{(e^s)^X \ge (e^s)^a}
\le \frac{\expect{e^{sX}}}{e^{sa}}
$$

The "magic trick" here is to take the exponent on both sides. We can then use Markov to get an upper bound. Let us analyze the numerator. Seeing that the variables $X_1, \dots, X_n$ are independent:

$$
\expect{e^{sX}} 
= \expect{e^{s(X_1 + X_2 + \dots + X_n)}}
= \prod_{i=1}^n \expect{e^{s X_i}}
$$

We can use the fact that $X_i$ is a Bernoulli random variable taking value 1 with probability $p_i$, and 0 with probability $(1 - p_i)$. This means that the random variable $e^{sX}$ takes value $e^s$ with probability $p_i$, and 1 with probability $(1 - p_i)$. This allows us to give a bound for this product of expectations:

$$
\begin{align}
\prod_{i=1}^n \expect{e^{s X_i}}
& = \prod_{i=1}^n (p_i \cdot e^s + (1-p_i) \cdot 1) \\
& = \prod_{i=1}^n 1 + p_i (e^s - 1) \\
&\le\prod_{i=1}^n \exp\left(p_i (e^s - 1)\right) \\
& = \exp\left( \mu(e^s - 1) \right)
\end{align}
$$

The inequality step uses the same fact we've used in Hedge, that because of the Taylor expansion of $e^y$, we have that $1 + y \le e^y$. We simply plug $y = p(e^s - 1)$ to get this result.

Now, we can set $a = (1+\delta) \mu$ and $s = \ln(1 + \delta)$, and get[^choice-of-s]

[^choice-of-s]: For reasons we won't go into, it just turns out that this choice of $s$ makes the upper bound for the tail probability as small as possible

$$
\prob{X \ge a} 
\le \frac{e^{\mu\delta}}{(1 + \delta)^{\mu(1+\delta)}}
=   \left(\frac{e^\delta}{(1 + \delta)^{1 + \delta}}\right)^\mu
$$

This can simplified to be at most $\exp{\left(-\frac{\delta^2}{2+\delta}\mu\right)}$. $\qed$