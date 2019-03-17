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

**Lemma**: *`kruskal_greedy` returns a maximum weight spanning tree*.

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

**Theorem**: *For any ground set* $E = \set{1, 2, \dots, n}$ *and a family of subsets* $\mathcal{I}$, `greedy` *finds a maximum weight base for any set of weights* $w: E \mapsto \mathbb{R}$ **if and only if** $M=(E, \mathcal{I})$ *is a matroid.*

The if direction ($\Leftarrow$) follows from the [correctness proof](#correctness-proof) we did for Kruskal's algorithm.

For the only if direction ($\Rightarrow$), we must prove the following claim, which we give in the contrapositive form.

**Claim**: Suppose $(E, \mathcal{I})$ is not a matroid. Then there exists an assignment of weights $w: E \mapsto \mathbb{R}$ such that `greedy` does not return a maximum weight base.

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

However, since $T\in\mathcal{I}$ and $\abs{T} > \abs{S}$, we expect the optimal solution to have value $\abs{T} \ge \abs{S} + 1 > \abs{S} + \frac{1}{2}$.

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
Todo

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

**Theorem**: *There is an efficient[^efficient-meaning] algorithm for finding a max-weight independent set in the intersection of two matroids.*

[^efficient-meaning]: Here, efficient means polynomial time, if we assume a polynomial time membership oracle. This is the case for all the matroid examples seen in class.

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

Recall that a path is a collection of edges $\set{(v_0, v_1), (v_1, v_2), \dots, (v_{k-1}, v_k)}$ where all the $v_i$'s are distinct vertices.

An *alternating* path with respect to an edge set $M$ is a path that alternates between edges in $M$ and edges in $E\setminus M$.

An *augmenting* path with respect to an edge set $M$ is an alternating path in which the first and last vertices are unmatched, i.e. $(v_0, v_k) \notin M$.

In a bipartite graph, the matching $M$ may define alternating paths in which we cannot revisit a node (by definition of a matching). Also note that an augmenting path is one that increases the matching; this is the core idea behind the following algorithm.

#### Algorithm

{% highlight python linenos %}
def augmenting_path_algorithm(G):
    """
    Input:  Bipartite graph G = (V, E)
    Output: Matching M of maximum cardinality
    """
    M = set()
    while exists an augmenting path P:
        M = MΔP
    return M
{% endhighlight %}

$M \Delta P$ is the [symmetric difference](https://en.wikipedia.org/wiki/Symmetric_difference), which we can also denote:

$$
M \Delta P 
\equiv (M \setminus P) \cup (P \setminus M)
\equiv (M \cup P) \setminus (M \cap P)
$$

An efficient algorithm to find an augmenting path $P$ is to run BFS, looking for unmatched vertices. This can be run in linear for bipartite graphs (though it is harder in general graphs), so the total runtime of the algorithm is $\bigO{\abs{V}^2 + \abs{E}\cdot\abs{V}}$.

#### Correctness proof
We now prove the correctness of this algorithm, which is to say that it indeed finds a maximum matching. The algorithm returns a set $M$ with respect to which there are no augmenting paths, so to prove correctness we must prove the following:

**Theorem**: A matching $M$ is a maximum **if and only if** there are no augmenting paths with respect to $M$.

The proof is by contradiction.

First, let's prove the $\Rightarrow$ direction. Suppose for the sake of contradiction that $M$ is maximum, but that there exists an augmenting path $P$ with respect to $M$. Then $M' = M \Delta P$ is a matching of greater cardinality than $M$, which contradicts the optimality of $M$.

Then, let's prove the $\Leftarrow$ direction. We must prove that the lack of augmenting paths implies that $M$ is maximal. Suppose toward contradiction that it is not, i.e. that there is a maximal matching $M^\*$ such that $\abs{M^\*} > \abs{M}$. Let $Q = M \Delta M^\*$; intuitively, this edge set $Q$ represents the edges that $M$ and $M^\*$ disagree on.

From there on, we reason as follows:

- $Q$ has more edges from $M^\*$ than from $M$ (since $\abs{M^\*} > \abs{M}$, which implies that $\abs{M^\* \setminus M} > \abs{M \setminus M^\*}$)
- In $Q$, every vertex $v$ has degree $\le 2$, with at most one edge from $M$, and at most one edge from $M^*$. Thus, every component in $Q$ is either:
    + a path (where middle nodes have degree two and the ends of the path have degree one), or
    + a cycle (where all nodes have degree two)
- The cycles and paths that compose $Q$ alternate between edges from $M$ and $M^\*$ (we cannot have vertices incident to two edges of the same set, as $M$ and $M^\*$ are matchings). This leads us to the following observations:
    + In cycles, there is the same number of edges from $M$ and $M^\*$
    + In paths, there number of edges from $M^\*$ is $\ge$ than the number of edges from $M$
- Let's remove cycles from consideration, and concentrate on paths. We can do so and still retain the property of having more edges from $M^\*$ than from $M$. Since $\abs{M^\*} > \abs{M}$, there must be at least one path with strictly more edges from $M^\*$ than from $M$; it must start and end with a $M^\*$ edge, and alternate between the sets in between. This path is an augmenting path with respect to $M$.

Therefore, there must exist an augmenting path $P$ with respect to $M$, which is a contradiction.

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

**Theorem**: If the feasible region is bounded, then there always exists an optimum which is an extreme point.

The proof is as follows. As the feasible region is bounded, there is an optimal solution $x^\*$. If $x^\*$ happens to be an extreme point, we are done. The real work in this proof is for the case where $x^\*$ isn't an extreme point. To prove this, we'll have to introduce a small lemma:

**Lemma**: Any feasible point can be written as a convex combination of the extreme points.

This is essentially proven by the following diagram:

![A feasible point and the extreme points that it is constructed from](/images/advanced-algorithms/convex-combination-extreme-points.png)

Indeed, if we draw a line from a feasible point $P$ in a bounded domain, we'll hit the bounds in two locations $X$ and $Y$, which are convex combination of the extreme points $A$, $B$ and $B$, $C$, respectively. $P$ is itself a convex combination of $X$ and $Y$, and thus of the extreme points $A$, $B$, $C$ and $D$.

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

This extreme point $x^{(j)}$ is gives us a higher value for the objective function than $x^\*$. Since $x^\*$ was chosen to be *any* feasible point, this means that $x^{(j)}$ is an optimal solution.


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

**Claim**: For bipartite graphs, any extreme point solution to the LP is integral[^integral-definition].

[^integral-definition]: Integral means that it is an integer; coupled with the constraint that $0 \le x_e \le 1$, being integral implies $x_e \in \set{0, 1}$.

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

Note that this indeed satisfies $x^\* = \frac{1}{2}(y + z)$, so we have a contradiction of the assumption that $x^\*$ is an extreme point.

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

**Claim**: For bipartite graphs, any extreme point to the vertex cover LP is integral.

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

These $y$ and $z$ are feasible solutions, and therefore show a contradiction in our initial assumption that $x^\*$ is an extreme point; the claim is therefore verified.

For general graphs, we have the same problem with odd cycles as for matchings. But the situation is actually even worse in this case, as the problem is NP-hard for general graphs, and we do not expect to have efficient algorithms for it. Still, we'll see an [approximation algorithm](#vertex-cover-for-general-graphs) later on.

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

**Theorem**: If $x$ is a feasible solution to the primal problem and $y$ is feasible to the dual, then:

$$
\sum_{i=1}^n c_i x_i \ge
\sum_{j=1}^m b_j y_j
$$

We can prove this by rewriting the right-hand side:

$$
\sum_{j=1}^m b_j y_j \le
\sum_{j=1}^m \sum_{i=1}^n A_{ji} x_i y_j =
\sum_{i=1}^n \left( \sum_{j=1}^m A_{ji} y_j \right) x_i \le
\sum_{i=1}^n c_i x_i
$$

The first inequality uses the constraints of the primal, and the second uses the constraints of the dual. We also use the fact that $x, y \ge 0$ throughout.

This leads us to the conclusion that the optimal solution of the primal is lower bounded by the optimal solution to the dual. In fact, we can make a stronger assertion than that, which is what we do in strong duality.

### Strong duality
Strong duality tells us that the dual solutions aren't just a lower bound, but that the optimal solutions to the dual and the primal are equal.

**Theorem**: If $x$ is an optimal primal solution and $y$ is an optimal dual solution, then:

$$
\sum_{i=1}^n c_i x_i = \sum_{j=1}^m b_j y_j
$$

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

**Theorem**: Let $M^\*$ be a maximum cardinality matching and $C^\*$ be a minimum vertex cover of a bipartite graph. Then:

$$
\abs{M^*} = \abs{C^*}
$$

### Complementarity slackness
As a consequence of strong duality, we have a strong relationship between primal and dual optimal solutions:

**Theorem**: Let $x\in\mathbb{R}^n$ be a feasible solution to the primal, and let $y\in\mathbb{R}^m$ be a feasible solution to the dual. Then:

$$
x, y \text{ are optimal solutions}
\iff
\begin{cases}
x_i > 0 \implies c_i = \sum_{j=1}^m A_{ji} y_j
& \forall i = 1, \dots, n \\

y_j > 0 \implies b_j = \sum_{i=1}^n A_{ji} x_i
& \forall j = 1, \dots, m \\
\end{cases}
$$

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

This is equivalent to $x, y$ being optimal solutions, by weak duality.

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
\end{align}
$$

Therefore, we have a 2-approximation algorithm for Vertex Cover.
