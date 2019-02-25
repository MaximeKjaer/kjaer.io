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

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
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