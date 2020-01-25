---
title: CS-450 Advanced Algorithms
description: "My notes from the CS-450 Advanced Algorithms course given at EPFL, in the 2019 spring semester (MA2)"
date: 2019-02-19
course: CS-450
---

A prerequisite for this course is [CS-250 Algorithms](/algorithms/).

<!-- More --> 

* TOC
{:toc}

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\norm}[1]{\left\lVert#1\right\rVert}
\newcommand{\set}[1]{\left\{#1\right\}}
\newcommand{\stream}[1]{\left\langle#1\right\rangle}
\newcommand{\inner}[1]{\left\langle#1\right\rangle}
\newcommand{\bigO}[1]{\mathcal{O}\left(#1\right)}
\newcommand{\smallO}[1]{\mathcal{o}\left(#1\right)}
\newcommand{\vec}[1]{\mathbf{#1}}
\newcommand{\expect}[1]{\mathbb{E}\left[#1\right]}
\newcommand{\prob}[1]{\mathbb{P}\left[#1\right]}
\newcommand{\var}[1]{\text{Var}\left(#1\right)}
\newcommand{\qed}[0]{\tag*{$\blacksquare$}}
\DeclareMathOperator*{\argmin}{\arg\!\min}
$$

## When does the greedy algorithm work? 

### Maximum weight spanning trees
We'll start with a problem called *maximum weight spanning trees*.

- **Input**: A graph $G = (V, E)$ with edge weights $w: E \rightarrow \mathbb{R}$
- **Output**: A spanning tree $T \subseteq E$ of maximum weight $\sum_{e\in T} w(e)$

A [spanning tree](/algorithms/#minimum-spanning-trees-mst) is a subgraph connecting all vertices of $G$ in the minimum possible number of edges. Being a tree, it is acyclic by definition.

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

{% block lemma "Kruskal correctness" %}
`kruskal_greedy` returns a maximum weight spanning tree.
{% endblock %}

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
{% block definition "Matroid" %}
A matroid $M = (E, \mathcal{I})$ is defined on a finite ground set $E$ of elements, and a family $\mathcal{I} \subseteq 2^E$ of subsets of $E$, satisfying two properties:

- $(I_1)$: If $X \subseteq Y$ and $Y \in \mathcal{I}$ then $X\in\mathcal{I}$
- $(I_2)$: If $X\in\mathcal{I}$ and $Y\in\mathcal{I}$ and $\abs{Y}>\abs{X}$ then $\exists e \in Y \setminus X : X + e \in \mathcal{I}$
{% endblock %}

The $(I_1)$ property is called *downward-closedness*, or the *hereditary property*; it tells us that by losing elements of a feasible solution, we still retain a feasible solution.

The sets of $\mathcal{I}$ are called *independent sets*: if $X\in\mathcal{I}$, we say that $X$ is *independent*.

The $(I_2)$ property is the *augmentation property*. It implies that every *maximal*[^maximal-set] independent set is of maximum cardinality[^proof-maximal-independent]. This means that all maximal independent sets have the same cardinality. A set of maximum cardinality is called a *base* of the matroid.

[^maximal-set]: Maximal means that we cannot add any elements to the set and retain independence.

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

{% block theorem %}
For any ground set $E = \set{1, 2, \dots, n}$ and a family of subsets $\mathcal{I}$, `greedy` finds a maximum weight base for any set of weights $w: E \rightarrow \mathbb{R}$ **if and only if** $M=(E, \mathcal{I})$ is a matroid.
{% endblock %}

The if direction ($\Leftarrow$) follows from the [correctness proof](#correctness-proof) we did for Kruskal's algorithm.

For the only if direction ($\Rightarrow$), we must prove the following claim, which we give in the contrapositive form[^contrapositive-form].

[^contrapositive-form]: If we want to prove $A \implies B$ we can equivalently prove the contrapositive $\neg B \implies \neg A$.

{% block claim %}
Suppose $(E, \mathcal{I})$ is not a matroid. Then there exists an assignment of weights $w: E \rightarrow \mathbb{R}$ such that `greedy` does not return a maximum weight base.
{% endblock %}

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
In our [initial example about maximum spanning trees](#maximum-weight-spanning-trees), we were actually considering a matroid in which $E$ is the set of edges, and $\mathcal{I}$ is defined as:

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
In a partition matroid, the ground set $E$ is partitioned into *disjoint* subsets $E_1, E_2, \dots, E_l$ (we can think of them as representing $l$ different colors, for example). Each such subset has an integer $k_i$ associated to it, stating how many elements can be picked from each subset at most.

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

We can think of these subsets as being part of a tree, where each node is the union of its children. For each set $X \in \mathcal{F}$, we define an integer $k_X$. The matroid is then defined by:

$$
\mathcal{I} = \set{S \subseteq E : \abs{S \cap X} \le k_X \, \forall X \in \mathcal{F}}
$$

##### Gammoid ("Netflix matroid")
A gammoid describes a set of vertices that can be reached by vertex-disjoint paths in a directed graph. An example of this is Netflix, which may want to know how many people they can reach from their server nodes if each link has a certain max capacity.

### Matroid intersection
Matroids form a rich set of problems that can be solved by the `greedy` algorithm, but there are also many problems with efficient algorithms that aren't matroids. This is the case for problems that aren't matroids themselves, but can be defined as the intersection of two matroids.

The intersection of two matroids $M_1 = (E, \mathcal{I}_1)$ and $M_2 = (E, \mathcal{I_2})$ is:

$$
M_1 \cap M_2 = (E, \mathcal{I}_1 \cap \mathcal{I}_2)
$$

The intersection of two matroids satisfies $(I_1)$, but generally not $(I_2)$. 

The following theorem adds a lot of power to the concept of matroids.

{% block theorem %}
There is an efficient algorithm for finding a max-weight independent set in the intersection of two matroids.
{% endblock %}

Here, efficient means polynomial time, if we assume a polynomial time membership oracle. This is the case for all the matroid examples seen in class.

#### Definition of bipartite matching
For instance, we can consider the example of [bipartite matching](/algorithms/#bipartite-matching).

- **Input**: A bipartite graph $G = (V = A \cup B, E)$, where $A$ and $B$ are two disjoint vertex sets
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

We'll use two partition matroids $M_A$ and $M_B$ imposing the same restrictions, but on $A$ and $B$, respectively. The ground set for both matroids is $E$. The partitioning of the ground set in $M_A$ is defined as follows, and similarly for $M_B$:

$$
E = \bigcup_{v \in A} \set{\delta(v)}
$$

Here, $\delta(v)$ denotes the edges incident to a vertex $v$. Note that since $G$ is bipartite, none of the vertices in $A$ are connected; this means that the above indeed creates a partitioning in disjoint sets. We let $k_v = 1$ for every $v$ in $A$, so we can define the family of independent sets for the first matroid $M_A$ is:

$$
\mathcal{I}_A = \set{
    X \subseteq E : 
    \abs{X \cap \delta(v)} \le k_v = 1, \quad
    \forall v \in A
}
$$

In other words, a set of edges $X \subseteq E$ is independent for $M_A$ (i.e. $X \in \mathcal{I_A}$) if it has at most one edge incident to every vertex of $A$ (no restrictions on how many edges can be incident to vertices on $B$). Defining $\mathcal{I}_B$ similarly, we see why the matroid intersection corresponds to a matching in $G$:

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

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

The path $P$ corresponds to all the edges in the graph. The symmetric difference $M \bigtriangleup P$ corresponds to a new matching $M'$ of cardinality $\abs{M'} = \abs{M} + 1$:

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

#### Correctness proof
We now prove the correctness of this algorithm, which is to say that it indeed finds a maximum matching. The algorithm returns a set $M$ with respect to which there are no augmenting paths, so to prove correctness we must prove the following:

{% block theorem "Augmenting Path Algorithm Correctness" %}
A matching $M$ is maximal **if and only if** there are no augmenting paths with respect to $M$.
{% endblock %}

The proof is by contradiction.

First, let's prove the $\Rightarrow$ direction. Suppose towards contradiction that $M$ is maximal, but that there exists an augmenting path $P$ with respect to $M$. Then $M' = M \bigtriangleup P$ is a matching of greater cardinality than $M$, which contradicts the optimality of $M$.

Then, let's prove the $\Leftarrow$ direction. We must prove that the lack of augmenting paths implies that $M$ is maximal. We'll prove the contrapositive, so suppose $M$ is not maximal, i.e. that there is a maximal matching $M^\*$ such that $\abs{M^\*} > \abs{M}$. Let $Q = M \bigtriangleup M^\*$; intuitively, this edge set $Q$ represents the edges that $M$ and $M^\*$ disagree on.

From there on, we reason as follows:

- $Q$ has more edges from $M^\*$ than from $M$ (since $\abs{M^\*} > \abs{M}$, which implies that $\abs{M^\* \setminus M} > \abs{M \setminus M^\*}$)
- In $Q$, every vertex $v$ has degree $\le 2$, with at most one edge from $M$, and at most one edge from $M^*$. Thus, every component in $Q$ is either:
    + a path (where middle nodes have degree two and the ends of the path have degree one), or
    + a cycle (where all nodes have degree two)
- The cycles and paths that compose $Q$ alternate between edges from $M$ and $M^\*$ (we cannot have vertices incident to two edges of the same set, as $M$ and $M^\*$ are matchings). This leads us to the following observations:
    + In cycles, there is the same number of edges from $M$ and $M^\*$
    + In paths, there number of edges from $M^\*$ is $\ge$ than the number of edges from $M$
- Let's remove cycles from consideration, and concentrate on paths. We can do so and still retain the property of having more edges from $M^\*$ than from $M$. Since $\abs{M^\*} > \abs{M}$, there must be at least one path with strictly more edges from $M^\*$ than from $M$; it must start and end with a $M^\*$ edge, and alternate between the sets in between. This path is an augmenting path with respect to $M$.

Therefore, there must exist an augmenting path $P$ with respect to $M$. This proves the contrapositive, so the $\Leftarrow$ direction stating that no augmenting paths $\Rightarrow M$ is maximal is proven. $\qed$

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

{% block theorem %}
If the feasible region is bounded, then there always exists an optimum which is an extreme point.
{% endblock %}

The proof is as follows. As the feasible region is bounded, there is an optimal solution $x^\*$. If $x^\*$ happens to be an extreme point, we are done. The real work in this proof is for the case where $x^\*$ isn't an extreme point. To prove this, we'll have to introduce a small lemma:

{% block lemma %}
Any feasible point can be written as a convex combination of the extreme points.
{% endblock %}

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

This proves $c^T x^\* = \sum_j \lambda_j c^T x^{(j)}$. In other words, the value of the objective function is a weighted average of the extreme points. 

We conclude the proof with the "tallest person in the class" argument. If we measured the height of all the people in a class, and got the average value of 170cm, we could say that at least one person has height $\ge$ 170cm. For the same reason, we can conclude from the above:

$$
c^T x^* = \sum_j \lambda_j c^T x^{(j)}
\implies 
\exists j : c^T x^{(j)} \ge c^T x^*
$$

This extreme point $x^{(j)}$ is gives us a higher value for the objective function than $x^\*$. Since $x^\*$ was chosen to be *any* feasible point, this means that $x^{(j)}$ is an optimal solution. $\qed$


### Maximum weight bipartite perfect matching
The problem corresponds to the following:

- **Input**: A bipartite graph $G=(V, E)$ where $V = A \cup B$ and $\abs{A} = \abs{B}$, and edge weights $w: E \rightarrow \mathbb{R}$
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

{% block claim %}
For bipartite graphs, any extreme point solution to the LP is integral.
{% endblock %}

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

- **Input**: A graph $G = (V, E)$ with node weights $w : V \rightarrow \mathbb{R}$
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

{% block claim %}
For bipartite graphs, any extreme point to the vertex cover LP is integral.
{% endblock %}

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

The last inequality holds because $x^\*$ is a feasible solution and thus satisfies the first LP constraint.

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

{% block theorem "Weak duality" %}
If $x$ is a feasible solution to the primal problem and $y$ is feasible to the dual, then:

$$
\sum_{i=1}^n c_i x_i \ge
\sum_{j=1}^m b_j y_j
$$
{% endblock %}

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

{% block theorem "Strong Duality" %}
If $x$ is an optimal primal solution and $y$ is an optimal dual solution, then:

$$
\sum_{i=1}^n c_i x_i = \sum_{j=1}^m b_j y_j
$$
{% endblock %}

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

[^hungarian-algorithm-name]: The Hungarian algorithm bears its name in honor of [Kőnig](https://en.wikipedia.org/wiki/D%C3%A9nes_K%C5%91nig) and [Egerváry](https://en.wikipedia.org/wiki/Jen%C5%91_Egerv%C3%A1ry), the two Hungarian mathematicians whose work it is based on.

{% block theorem "Kőnig's Theorem" %}
Let $M^\*$ be a maximum cardinality matching and $C^\*$ be a minimum vertex cover of a bipartite graph. Then:

$$
\abs{M^*} = \abs{C^*}
$$
{% endblock %}

### Complementarity slackness
As a consequence of strong duality, we have a strong relationship between primal and dual optimal solutions:

{% block theorem "Complementarity Slackness" %}
Let $x\in\mathbb{R}^n$ be a feasible solution to the primal, and let $y\in\mathbb{R}^m$ be a feasible solution to the dual. Then:

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
{% endblock %}

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
- **Input**: $G = (A\cup B, E)$, a bipartite weighted graph with edge weights $c: E \rightarrow \mathbb{R}$
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

We also get a series of less interesting implications, which are trivially true as their right-hand side is always true (because the original constraints already specified equality):

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

{% block lemma "Min-cost perfect matching and dual solution" %}
A perfect matching $M$ is of minimum cost **if and only if** there is a feasible dual solution $u, v$ such that:

$$
u_a + v_b = c(e) \qquad \forall e = (a, b) \in M
$$
{% endblock %}

In other words, if we can find a vertex weight assignment such that every edge has the same weight as the sum of its vertex weights, we've found a min-cost perfect matching. This is an interesting insight that will lead us to the Hungarian algorithm.

### Hungarian algorithm
The Hungarian algorithm finds a min-cost perfect matching. It works with the dual problem to try to construct a feasible primal solution.

#### Example
Consider the following bipartite graph:

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

The thin black edges have cost 1, and the thick red edge has cost 2. The Hungarian algorithm uses the [lemma from above](#lemma:min-cost-perfect-matching-and-dual-solution) to always keep a dual solution $y = (u, v)$ that is *feasible at all times*. For any fixed dual solution, the lemma tells us that the perfect matching can only contain **tight edges**, which are edges $e = (a, b)$ for which $u_a + v_b = c(e)$. 

The Hungarian algorithm initializes the vertex weights to the following trivial solutions:

$$
v_b = 0, \quad
u_a = \min_{b \in B} c_{ab}
$$

The right vertices get weight 0, and the left vertices get the weight of the smallest edge they're incident to. The weights $u$ and $v$, and the set of tight edges $E'$ is displayed below. 

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

Then, we try to find a perfect matching in this graph using the [augmenting path algorithm](#algorithm-1), for instance. However, this graph has no perfect matching (node $E$ is disconnected, $A$ and $B$ are both only connected to $D$). Still, we can use this fact to improve the dual solution $(u, v)$, using Hall's theorem:

{% block theorem "Hall's theorem" %}
An $n$ by $n$ bypartite graph $G = (A \cup B, E')$ has a perfect matching **if and only if** $\abs{S} \le \abs{N(S)}$ for all $S \subseteq A$
{% endblock %}

Here, $N(S)$ is the *neighborhood* of $S$. In the example above, we have no perfect matching, and we have $S = \set{A, B}$ and $N(S) = \set{D}$.

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

This set $S$ is a *certificate* that can be used to update the dual lower bound. If we pick a $\epsilon > 0$ (we'll see which value to pick later), we can increase $u_a$ for all vertices in $S$ by an amount $+\epsilon$, and decrease $v_b \in N(S)$ by $-\epsilon$. Let's take a look at which edges remain tight:

- Edges between $S$ and $N(S)$ remain tight as $u_a + \epsilon + v_b - \epsilon = u_a + v_b = c(a, b)$
- Edges between $A \setminus S$ and $B \setminus N(S)$ are unaffected and remain tight
- Any tight edge between $A\setminus S$ and $N(S)$ will stop being tight
- By definition of the neighborhood, there are no edges from $S$ to $B\setminus N(S)$

Because we've changed the set of tight edges, we've also changed our solution set $E'$ to something we can maybe find an augmenting path in. For instance, picking $\epsilon = 1$ in the graph above gives us a new set $E'$ of tight edges:

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

The augmenting path algorithm can find a perfect matching in this graph, which is optimal by [the lemma](#lemma:min-cost-perfect-matching-and-dual-solution).

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
    + Otherwise, we can find a "certificate" set $S \subseteq A$ such that $\abs{S} > \abs{N(S)}$. This is guaranteed to exist by [Hall's theorem](#theorem:hall-s-theorem).
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
    v_b - \epsilon & \text{if } b \in N(S) \\
    v_b & \text{if } b \notin N(S) \\
\end{cases}
$$

This remains feasible. The dual objective value increases by $(\abs{S} - \abs{N(S)})\epsilon$; as $\abs{S} > \abs{N(S)}$ by [Hall's theorem](#theorem:hall-s-theorem), $\abs{S} - \abs{N(S)} > 1$ so $(\abs{S} - \abs{N(S)})\epsilon > \epsilon$: we only increase the value!

To get the maximal amount of growth in a single step, we should choose $\epsilon$ as large as possible while keeping a feasible solution:

$$
\epsilon = 
\min_{(a, b) \in S \times (B \setminus N(S))} 
    c((a, b)) - u_a - v_b 
> 0
$$

This algorithm is $\bigO{n^3}$, but can more easily be implemented in $\bigO{n^4}$.

## Approximation algorithms
Many optimization problems are NP-hard. Unless P = NP, there is no algorithm for these problems that have the following three properties:

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
3. Solve the LP to get an optimal solution $x^\*\_{\text{LP}}$ which is a lower bound (or upper bound for a maximization problem) on the optimal solution $x^\*\_{\text{ILP}}$ to the ILP, and thus also on the original problem.
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

{% block claim %}
The weight of $C$ is at most twice the value of the optimal solution of vertex cover.

$$
w(C) \le 2\text{VC}_{\text{OPT}}
$$
{% endblock %}

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

The solutions we're looking at are:

- **OPT<sub>LP</sub>**: The optimal solution to the LP 
- **OPT**: The (hypothetical) optimal solution

Because the LP is a relaxation, it admits more solutions. So for a minimization problem, $\text{OPT}_{\text{LP}} \le \text{OPT}$.

The notion of *integrality gap* allows us to bound the power of our LP relaxation. It defines the "gap" in cost between the the optimal solution to the LP (OPT<sub>LP</sub>), and the hypothetical perfect, optimal solution (OPT).

Let $\mathcal{I}$ be the set of all instances of a given problem. For minimization problems, the integrality gap is defined as:

$$
g = \max_{I \in \mathcal{I}}
    \frac{\text{OPT}(I)}{\text{OPT}_{\text{LP}}(I)}
$$

This allows us to give some guarantees on bounds: for instance, suppose $g=2$ and our LP found $\text{OPT}\_{\text{LP}} = 70$. Since the problem instance might have been the one maximizing the integrality, all we can guarantee is that $\text{OPT}(I) \le 2\cdot \text{OPT}\_{\text{LP}}(I) = 140$. In this case, we cannot make an approximation algorithm that approximates better than within a factor $g = 2$.

#### Integrality gap of Vertex Cover
{% block claim "Vertex cover integrality gap" %}
Let $g$ be the integrality gap for the Vertex Cover problem on a graph of $n$ vertices.

$$g \ge 2 - \frac{2}{n}$$
{% endblock %}

On a *complete* graph with $n$ vertices, we have $\text{OPT} = n - 1$ because if there are two vertices we don't choose, the edge between them isn't covered. 

Assigning $\frac{1}{2}$ to every vertex is a feasible solution to the LP of cost $\frac{n}{2}$, so the optimum must be smaller or equal.

We can use these two facts to compute the integrality gap:

$$
g \ge \frac{n-1}{\frac{n}{2}} = 2 - \frac{2}{n}
\qed
$$

Our [2-approximation algorithm for vertex cover](#vertex-cover-for-general-graphs) implies that the integrality gap is at most 2, so we have:

$$
2 - \frac{2}{n} \le g \le 2
$$

### Set cover
#### Problem definition
Set cover is a generalization of vertex cover.

- **Input**:
    + A universe of $n$ elements $\mathcal{U} = \set{e_1, e_2, \dots, e_n}$
    + A family of subsets $\mathcal{T} = \set{S_1, S_2, \dots, S_m}$
    + A cost function $c: \mathcal{T} \rightarrow \mathbb{R}_+$
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

{% block claim "Expected cost in one execution" %}
The expected cost of all sets added in one execution of Step 3 is:

$$
\expect{c(C)} 
= \sum_{i=1}^m x_i^* \cdot c(S_i) 
= \text{LP}_{\text{OPT}}
$$
{% endblock %}

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

{% block corollary "Expected cost in d execution" %}
The expected cost of $C$ after $d$ executions of Step 3 is at most:

$$
\expect{c(C)}
=   d \cdot \sum_{i=1}^m c(S_i)x_i^*
\le d \cdot \text{LP}_{\text{OPT}}
\le d \cdot \text{OPT}
$$
{% endblock %}

Note that $\text{LP}_{\text{OPT}} \le \text{OPT}$ because LP is a relaxation of the ILP, so its optimum can only be better (i.e. lower for minimization problems like this one). This gives us some probabilistic bound on the first "bad event" of the cost being high.

We also need to look into the other "bad event" of the solution not being feasible:

{% block claim "Probability of unsatisfied constraint" %}
The probability that a constraint is unsatisfied after a single execution is at most $\frac{1}{e}$.
{% endblock %}

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

{% block claim "Probability of feasible solution" %}
The output $C$ after $d=c\cdot\ln(n)$ executions is a feasible solution with probability at least:

$$\prob{C \text{ feasible}} \ge 1 - \frac{1}{n^{c-1}}$$
{% endblock %}

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
\le n\cdot\frac{1}{n^c} = \frac{1}{n^{c-1}}
\qed
$$


At this point, we have an idea of the probabilities of the two "bad events": we have an expected value of the cost, and a bound of the probability of the solution not being feasible. Still, there might be a bad correlation between the two: maybe the feasible outputs have very high cost? Maybe all infeasible solutions have low cost? The following claim deals with that worry.

{% block claim "Probability of both good events" %}
The algorithm outputs a feasible solution of cost at most $4d\text{OPT}$ with probability greater that $\frac{1}{2}$.
{% endblock %}

Let $\mu$ be the expected cost, which by the corollary is $d\cdot\text{OPT}$. We can upper-bound the "bad event" of the cost being very bad: by [Markov's inequality](#theorem:markov-s-inequality) we have $\prob{\text{cost} > 4\mu} \le \frac{1}{4}$. We chose a factor $4$ here because this will give us a nice bound later on; we could pick any number to obtain another bound. We can also upper-bound the "bad event" of the solution being infeasible, which we know (thanks to [the previous claim](#claim:probability-of-feasible-solution)) to be upper-bounded by $\frac{1}{n^{c-1}} \le \frac{1}{n}$ for $d = c\cdot\ln(n)$ iterations. By [union bound](https://en.wikipedia.org/wiki/Boole%27s_inequality), the probability that no bad event happens is at least $1 - \frac{1}{4} - \frac{1}{n}$. Supposing $n > 4$, this probability is indeed greater than $\frac{1}{2}$. $\qed$

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

{% block theorem "16.1" %}
For any sequence of outcomes, any duration $T$ and any expert $i$:

$$
\text{# of WM mistakes} \le 2.41 \cdot (\text{# of }i\text{'s mistakes}) + \log_2(n)
$$
{% endblock %}

The $2.41$ seems very arbitrary, but we'll show where it comes from.

Let $i \in [n]$ be any expert. Let $\Phi^{(t)}$ defined as follows be a "potential function":

$$
\Phi^{(t)} = \sum_{i \in [n]} w_i^{(t)}
$$

Our strategy will be to bound $\Phi^{(T+1)}$ from below with expert $i$'s mistakes, and from above with WM's mistakes.

**Lower bound**: We can observe that:

$$
\Phi^{(T+1)} 
= \sum_{j \in [n]} w_j^{(T+1)} 
\ge w_i^{(T+1)}
= \left(\frac{1}{2}\right)^{\text{# of } i \text{'s mistakes}}
$$

The inequality stems from the fact that all weights are always $\ge 0$.

**Upper bound:** let's start by observing the following: $\Phi^{(1)} = n$ as all weights are initialized to 1. Additionally, whenever WM errs, we halve the weights for experts representing at least half of the total weights (since we follow the weighted majority). This means that we loose at least $\frac{1}{4}$ of the total weight:

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

{% block theorem %}
Suppose $\epsilon \le 1$, and $\vec{p}^{(t)}$ is chosen by Hedge for $t \in [T]$. Then for any expert $i$:

$$
\expect{\text{final loss}} 
= \sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}
\le
\sum_{t=1}^T m_i^{(t)} + \frac{\ln(n)}{\epsilon} + \epsilon T
$$
{% endblock %}

Note that this inequality holds for any expert $i$, and in particular, for the best expert. Let's take a look at the terms in this inequality:

$$
\underbrace{\sum_{t=1}^T \vec{p}^{(t)} \cdot \vec{m}^{(t)}}_{\text{our loss}}
\le \underbrace{\sum_{t=1}^T m_i^{(t)}}_{\text{loss of best expert}}
+   \underbrace{\frac{\ln(n)}{\epsilon} + \epsilon T}_{\text{external regret}}
$$

This means that Hedge does as well as the best expert, within a small additive term, which is the external regret. Note that this small error is minimized to be $\bigO{\sqrt{T}}$ when $\epsilon = \sqrt{\frac{\ln(n)}{T}}$.

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
\Phi^{(t+1)} 

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

& \overset{(3)}{=} \Phi^{(t)} (1 + \epsilon^2) 
  - \epsilon \sum_{j\in[n]} \Phi^{(t)} p_j^{(t)} m_j^{(t)} \\

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

& \ \vdots \\

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

{% block corollary "Long-term average regret" %}
Suppose $\epsilon \le 1$. For $t \in [T]$, let $\vec{p}^{(t)}$ be picked by Hedge, and assume the cost vectors are $\vec{m}^{(t)} \in [-\rho, \rho]^n$.

If $T \ge (4\rho^2 \ln n) / \epsilon^2$, then for any expert $i$:

$$
\frac{1}{T}\sum_{t=1}^T \vec{p}^{(t)}\cdot\vec{m}^{(t)}
\le
\frac{1}{T} \sum_{t=1}^T m_i^{(t)} + 2\epsilon
$$
{% endblock %}

This tells us that the average daily performance is as good as the best expert's average daily performance, within some linear term $2\epsilon$. The "average regret" is the difference between the algorithm's and the expert's average daily performances.

### Covering LPs
Covering LPs are defined as follows:

{% block definition %}
A linear program of the form:

$$
\begin{align}
\textbf{minimize: }   & \sum_{j=1}^n c_j x_j   & \\
\textbf{subject to: } 
    & A x \ge b \\
    & 0 \le x_j \le 1 & \forall j \\
\end{align}
$$

is a **covering** LP if all coefficients of the constraints and objective function are non-negative:

$$
A \in \mathbb{R}_+^{m\times n}, \;
b \in \mathbb{R}_+^m \text{ and }
c \in \mathbb{R}_+^n
$$
{% endblock %}

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

This means that $\rho \ge b_i$ and $\rho \ge \sum_j A_{ij} b_i$, $\forall i \in [n]$. By [the corollary](#corollary:long-term-average-regret), for $\epsilon \in [0, 1]$ and $T \ge (4\rho^2 \ln m) / \epsilon^2$, and for any constraint $i$, we have:

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

Note that $(*)$ is non-negative since we're working in a covering LP and because the oracle only outputs feasible solutions $x^{(t)}$, which allows us to conclude in the final step that the whole expression is non-negative. The inequality we derived from [the corollary](#corollary:long-term-average-regret) is therefore:

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

{% graphviz %}
graph G {
    graph [nodesep=0.7, ranksep=0]
    bgcolor="transparent"
    rankdir="LR"

    a -- b [label="e"]
    a -- b -- c -- d -- a
    b -- c -- d
    b -- c
}
{% endgraphviz %}

If we contract edge $e$, we get the following graph:

{% graphviz neato %}
graph G {
    graph [nodesep=0.7, ranksep=0]
    bgcolor="transparent"
    rankdir="LR"

    ab -- c -- d -- ab
    ab -- c -- d
    ab -- c
}
{% endgraphviz %}

We've created a new super-node $ab$. This reduces the total number of nodes in the graph by 1. We do not remove loops when contracting an edge.

#### Analysis
Let $(S^\*, \bar{S^\*})$ be the optimal minimum cut of $G$, of size $k$. We'll work our way towards analyzing the probability that the algorithm finds the optimal cut. 

First, let's take a look at the probability that a single edge is in the optimal min-cut. This corresponds to the probability of the algorithm chose "the wrong edge" when picking uniformly at random: if it contracts an edge that should have been in $E(S^\*, \bar{S^\*})$, then it will not output the optimal solution.

{% block claim "Probability of picking an edge in the cut" %}
The probability that a uniformly random edge is in $E(S^\*, \bar{S^\*})$ is at most $2/n$
{% endblock %}

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

{% block claim "Min-cut size does not decrease" %}
For any graph $G$, when we contract an edge $e$, the size of the minimum cut does not decrease.
{% endblock %}

We won't prove this, but it seems intuitive. If $G'$ is a version of $G$ where $e$ has been contracted, then $\text{MINCUT}(G) \le \text{MINCUT}(G')$.

Now, let's try to analyze the probability that the full algorithm returns the correct solution:

{% block theorem "Karger probability of success" %}
For any graph $G = (V, E)$ with $n$ nodes and a min-cut $(S^\*, \bar{S^\*})$, Karger's algorithm returns $(S^\*, \bar{S^\*})$ with probability at least $\frac{2}{n(n-1)} = 1 / {n \choose 2}$
{% endblock %}

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

{% block corollary "Maximum number of min-cuts" %}
Any graph has at most $n \choose 2$ min-cuts.
{% endblock %}

The proof for this is short and sweet: suppose that there is a graph $G$ that has more than $n \choose 2$ min-cuts. Then, for one of those cuts, the algorithm would find that exact cut with probability less that $1 / {n \choose 2}$, which is a contradiction. $\qed$

An example of a graph with $n \choose 2$ min-cuts is a cycle. We can choose any two vertices, and define a min-cut of size 2 by letting $S$ be all the nodes between them.

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
    let G2 be the contracted graph of size m
    E1, n1 = karger_stein(G2, m)
    E2, n2 = karger_stein(G2, m)
    return best cut of the two
{% endhighlight %}

To analyze the running time, let $T(n)$ be the time that it takes to compute the min-cut of a graph of size $n$:

$$
T(n) = \bigO{n^2} + 2T(n/\sqrt{2})
$$

Using the [master theorem](/algorithms/#master-theorem) to solve this recursion, we find that the algorithm runs in $\bigO{n^2 \log n}$.

{% block theorem "Karger-Stein probability of success" %}
The Karger-Stein algorithm finds a min-cut with probability at least $\frac{1}{2\log_2 n}$.
{% endblock %}

Suppose we have a graph $H$, which is a version of $G$ on which some contractions have been made. Suppose it has $r$ vertices, and let $(S^\*, \bar{S^\*})$ be a min-cut of $H$. Just as in [the proof of success probability of Karger](#theorem:theorem:karger-probability-of-success), the probability of not picking an edge in $(S^\*, \bar{S^\*})$ in any of the $r - \frac{2}{\sqrt{2}}$ steps of the loop is:

$$
\frac{r-2}{r} \cdot \frac{r-3}{r-1} \cdot \frac{r-4}{r-2}
\cdot \dots \cdot
\frac{r/\sqrt{2} - 2}{r/\sqrt{2}}
\approx \frac{(r/\sqrt{2})^2}{r^2}
= \frac{1}{2}
$$

As before, the terms of the fraction cancel out, and we're left with two terms $\approx r/\sqrt{2}$ in the numerator, and two terms $\approx r$ in the denominator, hence the above conclusion.

As long as we don't contract an edge of $(S^\*, \bar{S^\*})$ in the loop, we're guaranteed success. We'll prove inductively that the probability of success is $\ge \frac{1}{2\log_2 n}$. 

The algorithm calls itself recursively with $G_2$, the graph resulting from our $r - r/\sqrt{2}$ contractions on $H$.  Let $p$ be the probability of success on the recursive call on $G_2$. Our induction hypothesis is that the algorithm succeeds on $G_2$ with probability $\ge \frac{1}{2 \log_2 (n/\sqrt{2})}$. 

The probability that either (or both) of the recursive calls succeeds is $p + p - p^2$ (because $\prob{A\cup B} = \prob{A} + \prob{B} - \prob{A \cap B}$, and because the two events are independent).

The probability of the algorithm succeeding in $G$ is therefore that of not picking any edge in $(S^\*, \bar{S^\*})$, and of either of the recursive calls succeeding:

$$
\frac{1}{2}(p + p - p^2) = p - \frac{p^2}{2}
$$

To prove this theorem, we must show:

$$
p - \frac{p^2}{2} \ge \frac{1}{2 \log_2 n}
$$

Using the induction hypothesis, we have that $p = \frac{1}{2 \log_2 (n/\sqrt{2})}$ in the worst case. Plugging this into the above leaves us to prove:

$$
\frac{1}{2 \log_2(n/\sqrt{2})} - \frac{1}{8 \log_2(n/\sqrt{2})^2}
\ge
\frac{1}{2\log_2 n}
$$

Multiplying by 2 and rearranging the terms, we get:

$$
\frac{1}{\log_2(n/\sqrt{2})} - \frac{1}{\log_2 n}
\ge
\frac{1}{4 \log_2(n/\sqrt{2})^2}
$$

However, we can observe that:

$$
\begin{align}
\frac{1}{\log_2(n/\sqrt{2})} - \frac{1}{\log_2 n}
& = \frac{\log_2 n - \log_2(n/\sqrt{2})}{\log_2 n \log_2(n/\sqrt{2})} \\
& = \frac{1/2}{\log_2 n \log_2(n/\sqrt{2})} \\
& \ge \frac{1}{4\log_2(n/\sqrt{2})^2} \\
\end{align}
$$

as desired. $\qed$

We can run $\log^2 n$ independent copies of the algorithm to achieve a $1 - 1/n$ probability of success, in a total runtime of $\bigO{n^2\log^3 n}$.

## Polynomial identity testing
Suppose that we're given two polynomials $p(x)$ and $q(x)$ of degree $d$. We only have access to an oracle that allows us to evaluate the polynomial, but not to see its definition. We'd like to know if $p$ and $q$ are identical, i.e. whether $p(x) - q(x) = 0$ for all inputs $x \in \mathbb{R}^d$.

### Schwartz-Zippel lemma
For polynomials of a single variable, it's quite easy to test if it is zero. By the [fundamental theorem of algebra](https://en.wikipedia.org/wiki/Fundamental_theorem_of_algebra), a degree $d$ polynomial of a single variable has at most $d$ real roots. We can therefore test $d + 1$ roots. The polynomial is zero if all evaluations return 0.

For the multivariate case, things aren't so simple. In fact, a multivariate polynomial may have infinitely many roots. However, not all hope is lost. The Schwartz-Zippel lemma tells us:

{% block lemma "Schwartz-Zippel" %}
Let $p(x_1, \dots, x_n)$ be a **nonzero** polynomial of $n$ variables with degree $d$. Let $S \subseteq \mathbb{R}$ be a finite set, with at least $d$ elements in it. If we assign $x_1, \dots, x_n$ values from $S$ independently and uniformly at random, then:

$$
\prob{p(x_1, \dots, x_n) = 0} \le \frac{d}{\abs{S}} 
$$
{% endblock %}

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

There are $\abs{S}$ choices for $x_i$, and at most one satisfies $a_i x_i = c$, so the final result is:

$$
\prob{g(x_1, \dots, x_n) = 0}
= \prob{a_i x_i = c}
\le \frac{1}{\abs{S}}

\qed
$$

#### General proof
We proceed by strong induction.

**Base case**: $n = 1$, which is the univariate case, which we talked about above. The fundamental theorem of algebra proves this case.

**Inductive step**: Suppose that the lemma holds for any polynomial with less than $n$ variables. We need to show that it also holds for $n$.

Fix $x_1, \dots, x_{n-1}$ arbitrarily. All values in $p(x_1, \dots, x_n)$ are known except $x_n$, so $p$ becomes a univariate of $x_n$ of degree $\le d$. 

We've reduced it to the univariate case again, but this is actually not enough. An adversary could select $x_1, \dots, x_{n-1}$ such that the resulting polynomial is 0, despite $p$ being nonzero. To salvage the argument, we must prove that this adversarial scenario is rare. We'll need to make use of long division for this.

{% block definition "Long division for polynomials" %}
Let $p(x)$ be a polynomial of degree $d$ and $d(x)$ be the polynomial with degree $k \le d$. Then we can write $p(x)$ as:

$$
p(x) = d(x) q(x) + r(x)
$$

Where the **quotient** $q(x)$ has degree at most $d-k$, the **remainder** $r(x)$ has degree at most $k - 1$. The polynomial $d(x)$ is the **divisor**.
{% endblock %}

Let $k$ be the largest degree of $x_n$ in all monomials in $p$. This means $p$ can be "long divided" by $x_n$ as follows:

$$
p(x_1, \dots, x_n) = x_n^k q(x_1,\dots, x_{n-1}) + r(x_1, \dots, x_n)
$$

Using the principle of deferred decision, we assign values to $x_1, \dots, x_{n-1}$ uniformly at random from $S$. We save the randomness of $x_n$ for later use. Under our induction hypothesis, we have:

$$
\mathbb{P}_{x_1, \dots x_{n-1} \overset{\text{i.i.d}}{\sim} S} \left[
    q(x_1, \dots, x_{n-1}) = 0
\right]
\le \frac{d-k}{\abs{S}}
$$

If $q$ is nonzero, then it follows from the formulation of the long division that $p$ is a univariate polynomial in $x_n$, as the coefficient of $x_n^k$ is nonzero. We therefore have:

$$
\mathbb{P}_{x_n \sim S}\left[p = 0 \mid q \ne 0\right] 
\le \frac{k}{\abs{S}}
$$

Using these two probabilities, by Bayes rule, we have:

$$
\begin{align}
\prob{p = 0}
& = \prob{p = 0 \mid q = 0} \cdot \prob{q = 0}
  + \prob{p = 0 \mid q \ne 0} \cdot \prob{q \ne 0} \\
& \le 1 \cdot \prob{q = 0} + \prob{p = 0 \mid q \ne 0} \\
& \le \frac{d-k}{\abs{S}} + \frac{k}{\abs{S}} \\
& = \frac{d}{\abs{S}}
\end{align}
$$

Note that in the second step, we don't need to know $\prob{q \ne 0}$, we just upper-bound it by 1. $\qed$

### Matrix identity
We can use Schwartz-Zippel for identity testing of matrices too; suppose we are given three $n\times n$ matrices $A, B, C$. We'd like to test whether $AB = C$. Matrix multiplication is expensive ($\bigO{n^3}$ or [slightly less](/algorithms/#strassens-algorithm-for-matrix-multiplication)). Instead, we can use the Schwartz-Zippel:

{% block theorem "Schwartz-Zippel for matrices" %}
If $AB \ne C$ then:

$$
\mathbb{P}_{x_i \sim S}\left[
  ABx \ne Cx
\right] \ge 1 - \frac{1}{\abs{S}}
$$
{% endblock %}

Rather than infer it from Schwartz-Zippel, we'll give a direct proof of this. Let's write $AB$ and $C$ as row vectors:

$$
\newcommand{\horzbar}{\rule[.5ex]{2.5ex}{0.5pt}}
AB = \begin{bmatrix}
\horzbar & a_1    & \horzbar \\
         & \vdots &          \\
\horzbar & a_n    & \horzbar \\
\end{bmatrix}, \quad
C = \begin{bmatrix}
\horzbar & c_1    & \horzbar \\
         & \vdots &          \\
\horzbar & c_n    & \horzbar \\
\end{bmatrix}
$$

If $AB \ne C$ then there exists at least one row $i$ where $a_i \ne c_i$. The inner products $\inner{a_i, x}$ and $\inner{c_i, x}$ are likely different:

$$
\prob{\inner{a_i, x} \ne \inner{c_i, x}} \ge 1 - \frac{1}{\abs{S}}
$$

This follows from the [proof for one dimension](#proof-for-one-dimension), as $\inner{a_i, x}$ and $\inner{c_i, x}$ are degree 1 polynomials of variables $x_1, \dots, x_n$.

### Bipartite perfect matching
Let $G = (A \cup B, E)$ be a $n\times n$ bipartite graph. We can represent the graph as a $n\times n$ adjacency matrix having an entry if nodes are connected by an edge:

$$
A_{ij} = \begin{cases}
x_{ij} & \text{if } (v_i, v_j) \in E \\
0      & \text{otherwise}
\end{cases}
$$

For instance:

{% graphviz %}
graph G {
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
}
{% endgraphviz %}

The above graph would have the following matrix representation:

$$
A = \begin{bmatrix}
x_{ab} & 0      & 0      \\
0      & x_{be} & x_{bf} \\
0      & x_{ce} & x_{cf} \\
\end{bmatrix}
$$

We have a nice theorem on this adjacency matrix:

{% block theorem "Perfect Matching and Determinant" %}
A graph $G$ has a perfect matching **if and only if** the determinant $\det(A)$ is not identical to zero.
{% endblock %}

Let's first prove the $\Rightarrow$ direction. Suppose $G$ has a perfect matching, i.e. a bijection $f$ mapping every $a \in A$ to a unique $b \in B$. We can see $f$ as a permutation on the set of integers $[n]$. 

$$
\prod_{i=1}^n A_{i, f(i)}
$$

This is one term (monomial) of the polynomial $\det(A)$. One way to define the determinant is by summing over all possible permutations $\sigma$:

$$
\det(A) 
= \sum_{\sigma: [n]\rightarrow [n]} \text{sgn}(\sigma)
  \prod_{i=1}^n A_{i, \sigma(i)}
$$

The sign of a permutation is the number of swaps needed to order it[^mind-blowing-fact][^not-important].

[^mind-blowing-fact]: No matter the sort algorithm, the parity of the number of swaps to sort is always the same 🤯

[^not-important]: This is not hugely important for the following discussion, so you can safely disregard it if it doesn't make a lot of sense. Just understand that some terms may cancel out because of the sign of the permutation.

In particular, when $\sigma = f$ in the sum (we sum over all possible permutations, so we're guaranteed to get this case), we get a monomial with non-zero coefficient (we know that $A_{i, f(i)}$ is non-zero as $f$ describes edges, so there's a variable in that location of the matrix). This monomial is different from all other monomials in $A$, there are no cancellations. This means $\det(A)$ is non-zero.

Now, onto the $\Leftarrow$ direction. Suppose $\det(A)$ is non-zero. Therefore, using the above definition of determinant, there is some permutation $\sigma$ for which all terms $A_{i, \sigma(i)}$ are non-zero. Since $\sigma$ is a bijection, this indicates a perfect matching. $\qed$

However, this algorithm doesn't give us the matching, it only tells us whether we have one. To fix this, we can run the following procedure. We pick a big set $\abs{S} \gg n$ and set $x_{ij} = 2^{w_{ij}}$ where $w_{ij}$ is chosen independently and uniformly at random in $S$. With high probability, there is a *unique* minimum weight perfect matching[^mulmuley-et-al], call it $M$. We won't prove it here, but we can write the determinant in the following form to reveal $M$:

[^mulmuley-et-al]: See the isolation lemma from the 1987 paper ["Matching is as easy as a matrix inversion"](https://people.eecs.berkeley.edu/~vazirani/pubs/matching.pdf) by Mulmuley, Vazirani and Vazirani.

$$
\det(A) = 2^{w(M)} (\pm 1 + \text{even number})
$$

The $\pm 1$ ensures that the term $2^{w(M)}$ exists in the sum, and the even number ensures that it is the smallest (i.e. that all other powers of 2 in the determinant can be divided by $2^{w(M)}$).

With this in hand, for every edge $(i, j)$ in $G$ we can check whether it is part of $M$ by deleting the edge, compute the determinant as above, and see whether the newly found $w(M')$ is equal to $w(M) - w_{ij}$. If yes, then $(i, j) \in M$, otherwise not.

This algorithm can be implemented in $\bigO{\text{polylog}(n)}$ using polynomial parallelism.

#### General graphs
This result actually generalizes to general graphs, though the proof is much more difficult. For general graphs, we must construct the following matrix $A$ (called the skew-symmetric matrix, or Tutte matrix) instead of the adjacency matrix.

$$
A_{ij} = \begin{cases}
x_{ij}  & \text{if } (v_i, v_j) \in E, \text{ and } i < j \\
-x_{ij} & \text{if } (v_i, v_j) \in E, \text{ and } i \ge j \\
0       & \text{otherwise}
\end{cases}
$$


## Sampling and Concentration Inequalities
### Law of large numbers
Suppose that there is an unknown distribution $D$, and that we draw independent samples $X_1, X_2, \dots, X_n$ from $D$ and return the mean:

$$
X = \frac{1}{n} \sum_{i=1}^n X_i
$$

The law of large numbers tells us that as $n$ goes to infinity, the empirical average $X$ converges to the mean $\expect{X}$. In this chapter, we address the question of how large $n$ should be to get an $\epsilon$-additive error in our empirical measure.

### Markov's inequality
Consider the following simple example. Suppose that the average Swiss salary is 6000 CHF per month. What fraction of the working population receives at most 8000 CHF per month?

One extreme is that everyone earns exactly the same amount of 6000 CHF, in which case the answer is 100%. The other extreme is that a fraction of all workers earn 0 CHF/month; in the worst case, $\frac{1}{4}$ of all workers earn 0 CHF/month, while the rest earns 8000.

Markov's inequality tells us about this worst-case scenario. It allows us to give a bound on the average salary $X$ for the "worst possible" distribution.

{% block theorem "Markov's inequality" %}
Let $X \ge 0$ be a random variable. Then, for all $k$:

$$
\prob{X \ge k \cdot \expect{X}} \le \frac{1}{k}
$$

Equivalently:

$$
\prob{X \ge k} \le \frac{\expect{X}}{k}
$$
{% endblock %}

In the salary example, $X$ denotes the average salary. We know that $\expect{X} = 6000$; we want to look at the probability that $X \ge 8000$, which we can write as $X \ge k\cdot\expect{X}$ for $k = \frac{4}{3}$. This confirms what we said above. The probability that the salary $X$ is at most $8000$ is at most $\frac{1}{k} = \frac{3}{4}$.

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

{% block definition "Variance" %}
The variance of a random variable $X$ is defined as:

$$\var{X} = \expect{(X - \expect{X})^2} = \expect{X^2} - \expect{X}^2$$
{% endblock %}

### Chebyshev's inequality
Using the variance of the distribution, we can give the following bound on how much the empirical average will diverge from the true mean:

{% block theorem "Chebyshev's inequality" %}
For any random variable $X$,

$$
\prob{\abs{X - \expect{X}} > \epsilon} < \frac{\var{X}}{\epsilon^2}
$$

Equivalently:

$$
\prob{\abs{X - \expect{X}} > k\sigma} \le \frac{1}{k^2}
$$

where $\sigma = \sqrt{\var{X}}$ is the standard deviation of $X$.
{% endblock %}

Note that we used strict inequality, but that for continuous random variables, these can be replaced with non-strict inequalities without loss of generality.

It turns out that Chebyshev's inequality is just Markov's inequality applied to the variance random variable $Y := (X - \expect{X})^2$. Indeed, by Markov:

$$
\prob{Y \ge \epsilon^2} \le \frac{\expect{Y}}{\epsilon^2}
$$

In other words:

$$
\prob{\abs{X - \expect{X}}^2 \ge \epsilon^2} 
\ge \frac{\var{X}}{\epsilon^2}
$$

Taking the square root on both sides yields:

$$
\prob{\abs{X - \expect{X}} \ge \epsilon} \ge \frac{\var{X}}{\epsilon^2}
$$

Taking $\epsilon = k\sigma$, where $\sigma = \sqrt{\var{X}}$ trivially gives us the equivalent formulation. $\qed$

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

{% block definition "Pairwise independence" %}
A set of random variables $X_1, X_2, \dots, X_n$ are *pairwise independent* if for all $1 \le i, j \le n$:

$$\expect{X_i X_j} = \expect{X_i} \expect{X_j}$$
{% endblock %}

Note that full independence implies pairwise independence.

{% block lemma "Variance of a sum" %}
For any set of pairwise independent $X_1, \dots, X_n$:

$$
\var{X_1 + \dots + X_n} = \var{X_1} + \dots + \var{X_n}
$$
{% endblock %}

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

In step $(1)$ we used pairwise independence as follows:

$$
\expect{X_i \cdot X_j} = \begin{cases}
\expect{X_i}\cdot\expect{X_j} & \text{if } i \ne j \\
\expect{X_i^2} & \text{if } i = j \\
\end{cases}
$$

This means that the terms where $i \ne j$ cancel out with the subtracted sum. We are thus left with terms where $i = j$ after step $(1)$.

$\qed$


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

{% block theorem "Chernoff bounds for a sum of independent Bernoulli trials" %}
Let $X = \sum_{i = 1}^n X_i$ where $X_i$ = 1 with probability $p_i$ and $X_i = 0$ with probability $1 - p_i$, and all $X_i$ are independent. Let $\mu = \expect{X} = \sum_{i=1}^n p_i$. Then:

1. **Upper tail**: $\prob{X \ge (1 + \delta)\mu} \le \exp{\left(-\frac{\delta^2}{2+\delta}\mu\right)}$ for all $\delta > 0$
2. **Lower tail**: $\prob{X \le (1 - \delta)\mu} \le \exp{\left(-\frac{\delta^2}{2}\mu\right)}$ for all $\delta > 0$
{% endblock %}

Another formulation of the Chernoff bounds, called Hoeffding's inequality, applies to bounded random variables, regardless of their distribution:

{% block theorem "Hoeffding's Inequality" %}
Let $X_1, \dots, X_n$ be independent random variables such that $a \le X_i \le b$ for all $i$ Let $X = \sum_{i=1}^n X_i$ and set $\mu = \expect{X}$. Then:

1. **Upper tail**: $\prob{X \ge (1 + \delta)\mu} \le \exp{\left(-\frac{2\delta^2\mu^2}{n(b-a)^2}\right)}$ for all $\delta > 0$
2. **Lower tail**: $\prob{X \ge (1 - \delta)\mu} \le \exp{\left(-\frac{-\delta^2\mu^2}{n(b-a)^2}\right)}$ for all $\delta > 0$
{% endblock %}

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


## Hashing
### Introduction
Hashing is a technique of mapping from an input domain $U$ to a domain of size $N$, where typically $N \ll \abs{U}$. To do so, we use a hash function $h: U \rightarrow \set{1, 2, \dots, N}$. The question we want to study is how to choose $h$.

A typical application for hashing is that we want to store a subset $S$ of the large universe $U$, where $\abs{S} \ll \abs{U}$. For each $x \in U$, we want to support three operations: `insert(x)`, `delete(x)` and `query(x)`. 

A hash table supports these operations; $x\in U$ is placed in $T[h(x)]$, where $T$ is a table of size $N$. For collisions (i.e. values that hash to the same bucket), we use a linked list.

An ideal hash function should have the property that the probability that two or more elements hash to the same value is low, in order to use the table efficiently, and the linked lists short. 

However, the following statement proves to be problematic if we pick a fixed hash function: for a fixed $h$,

$$
\exists S \subseteq U 
\text{ such that }
\abs{S} \ge \frac{\abs{U}}{N}
\text{ and }
h(x) = h(y) \quad \forall x, y \in S
$$

In other words, if we fix a hash function $h$, an adversary could select a "bad dataset" for which all values hash to the same location, thus rendering hashing useless. We cannot prove any worst-case guarantees for hashing in that case. This will lead us to choose our function $h$ at random from a family $\mathcal{H}$.

The question of how to choose $\mathcal{H}$ remains. We want to choose it such that a random function from $\mathcal{H}$ maps to a given location of the hash table uniformly and independently at random. Choosing according to this goal ensures that the number of collisions is low. To see that, consider a value $x$, and let $L_x$ be the length of the linked list containing $x$. Let $I_y$ be a random variable:

$$
I_y = \begin{cases}
1 & \text{if } h(y) = h(x) \\
0 & \text{otherwise}
\end{cases}
$$

We will hash $x$, and also every $y \in S$ and see how many collisions that brings about. After doing this, the length of the linked list will be one for $x$, plus the number of values in $S$ that hash to the same value:

$$
L_x = 1 + \sum_{y \in S : y \ne x} I_y
$$

Since we're choosing $h$ at random from $\mathcal{H}$, we need to look at the expectation rather than a single realization. By linearity of expectation:

$$
\expect{L_x} 
= 1 + \sum_{y \in S : y \ne x} \expect{I_y} 
= 1 + \frac{\abs{S} - 1}{N}
$$

Usually we'll choose $N > \abs{S}$, in which case we expect less than one collision (so 2 items in the linked list).

The last step in the above uses our assumption that if we choose a function $h$ uniformly at random in $\mathcal{H}$, then a given value hashes to a uniformly random location in the table. This means that for a value $x$:

$$
\begin{align}
\expect{I_y} 
& = 1 \cdot \prob{h(y) = h(x)} + 0 \cdot \prob{h(y) \ne h(x)} \\
& = \prob{h(y) = h(x)} \\
& = \begin{cases}
    1 & \text{if } x = y \\
    \frac{1}{N} & \text{otherwise}
\end{cases} \\
\end{align}
$$

Let's suppose that the family $\mathcal{H}$ contains all possible permutations of mappings. That would mean $\abs{\mathcal{H}} = N^{\abs{U}}$. To store it, we would need $\log_2\left(N^{\abs{U}}\right) = \abs{U} \log_2(N)$ bits, which is too big.

Luckily, we can save on storage by using the following observation: in the above calculations, we don't need full mutual independence between all values $y \in S$ and $x$; we only need pairwise independence between $x$ and each $y \in S$. This means that we don't have to choose uniformly at random from all possible mappings, but instead from a smaller set of functions with limited independence.

### 2-universal hash families
Let's start by defining 2-universality:

{% block definition "2-universal hash families (Carter Wegman 1979)" %}
A family $\mathcal{H}$ of hash functions is 2-universal if for any $x\ne y \in U$, the following inequality holds:

$$
\mathbb{P}_{h \in \mathcal{H}}\left[h(x) = h(y)\right] 
\le \frac{1}{N}
$$
{% endblock %}

We can design 2-universal hash families in the following way. Choose a prime $p \in \set{\abs{U}, \abs{U} + 1, \dots, 2\abs{U}}$ and let:

$$
f_{a, b}(x) = ax + b \mod p \quad \text{where } a, b \in [p], a \ne 0
$$

We let the hash function be:

$$
h_{a, b}(x) = f_{a, b}(x) \mod N
$$

This works because the integers modulo $p$ form a field when $p$ is prime, so we can define addition, multiplication and division among them. 

{% block lemma "Lemma 2, 2-Universal Hash Families" %}
For any $x \ne y$ and $s \ne t$, the following system has exactly one solution:

$$
\begin{align}
ax + b = s & \mod p \\
ay + b = t & \mod p \\
\end{align}
$$
{% endblock %}

Since $[p]$ constitutes a finite field, we have that $a = (x - y)^{-1}(s -t)$ and $b = s - ax$. $\qed$

Note that this proof also explains why we require $s \ne t$: if we had $s = t$ the only solution would be $a = 0$, in which case $f_{a, b}(x)$ would return $b$ for all $x \in U$, thus rendering hashing useless.

Moreover, there are $p\cdot(p-1)$ possible choices for the pair $a \in \set{1, 2, \dots, p-1}$ and $b \in \set{0, 1, \dots, p-1}$. Therefore, over a uniformly at random choice of $a$ and $b$, if we select any $s$, $t$, $x$ and $y$ such that $x \ne y$:

$$
\mathbb{P}_{a, b}\left[
    f_{a, b}(x) = s \land f_{a, b}(y) = t
\right] = \begin{cases}
    0 & \text{if } s = t \\
    \frac{1}{p\cdot(p-1)} & \text{if } s \ne t \\
\end{cases}
\label{eq:collision-prob}\tag{Collision prob.}
$$

This probability describes two cases, which we will comment:

- If $s = t$ then the probability we're looking at is equivalent to $\mathbb{P}\_{a, b}\left[f\_{a, b}(x) = f\_{a, b}(y)\right] = \mathbb{P}\_{a, b}\left[ax + b = ay + b \mod p\right]$. Since $p$ is prime, $[p]$ is a field and thus $ax + b = ay + b \mod p$ implies $x = y \mod p$, which cannot happen by assumption (we chose $x \ne y$).
- If $s \ne t$, then we're looking at the probability that $x$ and $y$ hash to different values. The probability that they both hash to the given $s$ and $t$ is that of having chosen the one correct pair $a, b$ producing $s$ and $t$ for $x$ and $y$. Since there are $p\cdot(p-1)$ possible pairs $a, b$, the probability is $\frac{1}{p\cdot(p-1)}$.

These observations lead us to the following lemma:

{% block lemma "Lemma 3, 2-Universal Hash Families" %}
$\mathcal{H} = \set{h_{a, b} : a, b \in [p] \land a\ne 0}$ is universal.
{% endblock %}

To prove this, we will have to check the definition, i.e. whether the probability of two different values hashing to the same value is less than $\frac{1}{N}$. For any $x \ne y$:

$$
\begin{align}
\prob{h_{a, b}(x) = h_{a, b}(y)}
& = \prob{f_{a, b}(x) = f_{a, b}(y) \mod N} \\
& \overset{(1)}{=} \sum_{s, t \in [p]}
    \mathbb{I}_{s = t \mod N} \cdot \prob{f_{a, b}(x) = s \land f_{a, b}(y) = t} \\
& \overset{(2)}{=} \frac{1}{p\cdot(p-1)} \sum_{s, t \in [p] : s \ne t} \mathbb{I}_{s = t \mod N} \\
& \overset{(3)}{\le} \frac{1}{p\cdot(p-1)} \frac{p\cdot(p-1)}{N} \\
& = \frac{1}{N}
\end{align}
$$

Step $(1)$ uses an indicator variable to capture whether $s = t \mod N$ so that we can reformulate the probability in the same form as in $\ref{eq:collision-prob}$. Step $(2)$ uses the $\ref{eq:collision-prob}$. Step $(3)$ follows from the fact that for each $s \in [p]$, we have at most $\frac{p-1}{N}$ different $t$ such that $s\ne t$ and $s = t \mod N$. $\qed$

The importance of all of the above is that we can now create a 2-universal hash functions solely by picking two numbers $a$ and $b$ uniformly at random, and we only need to store $a \in [p]$ and $b \in [p]$, which requires $\bigO{\log \abs{U}}$ space instead of the completely random hash function which required $\bigO{\abs{U} \log N}$ bits.

Let us calculate the expected number of collisions:

$$
\sum_{x \ne y \in S} \mathbb{P}_{h \in \mathcal{H}}\left[h(x) = h(y)\right]
\le {\abs{S} \choose 2} / N
$$

$\mathcal{H}$ being a 2-universal hash family, the probability of collision is $\le \frac{1}{N}$. There are ${\abs{S} \choose 2}$ possible pairs $x, y \in S$ such that $x \ne y$, which leads us to the above result.

### Two-layer hash tables
If we select $N$ to be greater than $\abs{S}^2$, we can have no collisions with high probability. In practice, such a large table is unrealistic, so we use linked lists or a second layer of hash table for collisions.

The two-layer table works as follows. Let $s_i$ denote the actual number of collisions in bucket $i$. If we construct a second layer for bucket $i$, of size $\approx s_i^2$, we can easily find separate locations in the second layer for all $s_i$ values that collided in the first layer.

The total size of the second layers is:

$$
\sum_{i=1}^N s_i^2
$$

We can compute the expected total size of the second layers by decomposing the squares as follows:

$$
\begin{align}
\expect{\sum_{i=1}^N s_i^2} 
& = \expect{\sum_{i=1}^N s_i^2 + s_i - s_i}  \\
& = \expect{\sum_{i=1}^N s_i(s_i - 1)} + \expect{\sum_{i=1}^N s_i} \\
& \overset{(1)}{\le} \frac{\abs{S}(\abs{S} - 1)}{N} + \abs{S} \\
& \overset{(2)}{\le} 2\abs{S} \\
\end{align}
$$

Step $(2)$ is true if we assume $N \ge \abs{S}$. Step $(1)$ places a (large) upper bound using the fact that the we cannot expect more collisions than there are elements in the set of hashed values $S$.

### k-wise independence
Intuitively, a collection of events is $k$-wise independent if any subset of $k$ of them are mutually independent. We can formalize this as follows:

{% block definition "k-wise independent hash family" %}
A family $\mathcal{H}$ of has functions is $k$-wise independent if for any $k$ distinct elements $(x_1, \dots, x_k) \in U^k$ and any numbers $(u_1, \dots, u_k)$ we have:

$$
\mathbb{P}_{h\in\mathcal{H}}\left[
  h(x_1) = u_1 \land \dots \land h(x_k) = u_k
\right] = \left(
  \frac{1}{\abs{U}}
\right)^k
$$
{% endblock %}

Recall [the definition we gave previously for pairwise independence](#definition:pairwise-independence). Generalizing this to $k$-wise independence, we get:

{% block lemma "Expectation of product of k-wise independent variables" %}
For any set of $k$-wise independent $X_1, \dots, X_n$:

$$
\expect{X_{i_1} X_{i_2} \dots X_{i_k}}
= \expect{X_{i_1}} \expect{X_{i_2}} \dots \expect{X_{i_k}}
$$
{% endblock %}

For some prime number $p$ consider the family of functions constructed by choosing $a_0, \dots, a_{k-1}$ uniformly at random in $\set{0, 1, \dots, p-1}$, and letting the function be defined as:

$$
f_{a_0, \dots, a_{k-1}}(x) = a_{k-1} x^{k-1} + \dots + a_1 x + a_0
$$

This function is $k$-wise independent. We can store it with $\bigO{k \log \abs{U}}$ memory.

We can adapt the [discussion on 2-universality](#2-universal-hash-families) to pairwise independence (also called 2-wise independence).

{% block definition "2-wise independent hash family" %}
We say that $\mathcal{H}$ is 2-wise independent if for any $x \ne y$ and any pair of $s, t \in [N]$,

$$
\mathbb{P}_{h\in\mathcal{H}}\left[h(x) = s \land h(y) = t\right]
= \frac{1}{N^2}
$$
{% endblock %}

Note that 2-wise independence implies 1-wise independence.

{% block definition "1-wise independent hash family" %}
We say that $\mathcal{H}$ is 1-wise independent if for any $x\in U$ and any pair of $s \in [N]$,

$$
\mathbb{P}_{h\in\mathcal{H}}\left[h(x) = s\right]
= \frac{1}{N}
$$
{% endblock %}

### Load balancing
Let's discuss how large the linked lists can get. For simplicity, we'll consider a situation in which we hash $n$ keys into a hash table of size $n$. We also assume that the funciton is completely random, rather than just 2-universal as above.

This situation can be explained by the analogy of balls-and-bins. We throw balls at random, and they each land in a bin, independently and uniformly at random. Clearly, we expect one ball in each bin, but the maximum number of balls in a single bin can be higher. For a given $i$:

$$
\prob{\text{bin } i \text{ gets more than } k \text{ elements}}
\le {n \choose k} \cdot \frac{1}{n^k} 
\le \frac{1}{k!}
$$

The first step uses union bound: the probability that any of the $n \choose k$ events happen is at most the sum of their individual properties. [Stirling's formula](https://en.wikipedia.org/wiki/Stirling%27s_approximation) allows us to approximate the factorial:

$$
k! \approx \sqrt{2nk}\left(\frac{k}{e}\right)^k
$$

Choosing $k = \bigO{\frac{\log n}{\log\log n}}$ ensures $\frac{1}{k!} \le \frac{1}{n^2}$. Thus:

$$
\prob{\exists \text{ a bin with } \ge k \text{ balls}}
\le n\cdot\frac{1}{n^2}
= \frac{1}{n}
$$

Long story short, with probability larger than $1 - 1/n$, the max load is less than $\bigO{\frac{\log n}{\log\log n}}$. We can even boost this probability of success to $1 - 1/n^c$ by changing the parameters a little.

### Power of two choices
This is not bad, but we can do even better using the following cool fact (that we won't prove).

The trick we use at the supermarket is to go to the checkout counter with the shortest queue. This is a linear process in the number of checkout registers, so consider this simpler trick: when throwing a ball, pick two random bins, and select the one with the fewest balls (shortest linked list). This ensures that the maximal load drops to $\bigO{\log\log n}$, which is a huge improvement on $\bigO{\frac{\log n}{\log\log n}}$. This is called the *power of two choices*.

## Streaming algorithms
Streaming algorithms take as input a long stream $\sigma = \stream{a_1, a_2, \dots, a_m}$ consisting of $m$ elements taking values from the universe $[n] = \set{1, \dots, n}$.

We can assume that $m$ and $n$ are huge; if we were Facebook, $m$ could be the number of profiles and $n$ the number of different cities in the world.

The algorithm must be super fast, and cannot store all the data in memory. Our goal is to process the input stream (left to right) using a small amount of space, while calculating some interesting function $\phi(\sigma)$.

Ideally, we would achieve this in $p = 1$ pass with $s = \bigO{\log m + \log n}$ memory, but we may have to allow some error margins to achieve these.

### Finding Frequent Items Deterministically
We have a stream $\sigma = \stream{a_1, a_2, \dots, a_m}$ where each $a_i \in [n]$. This implicitly defines a frequency vector $\vec{f} = (f_1, \dots, f_n)$ describing the number of times each value has been represented in the stream. Note that this $\vec{f}$ is not the input of the algorithm, but simply another way of denoting the stream. Also note that $f_1 + f_2 + \dots + f_n = m$.

We will consider the following two problems:

- **Majority**: if there exists a $j$ such that $f_j > \frac{m}{2}$, output $j$. Otherwise, output "NONE".
- **Frequent**: Output the set $\set{j : f_j > \frac{m}{k}}$

Unfortunately, there is no deterministic one-pass algorithm that doesn't need linear memory $\Omega(\min(m, n))$. 

However, it is possible to define an algorithm that only needs logarithmic memory if we allow for some margin of error. The Misra-Gries algorithm is a single-pass ($p = 1$) algorithm that solves the related problem of estimating the frequencies $f_j$, and can thus also be used to solve the above problems.

The algorithm uses a parameter $k$ that controls the quality of the answers it gives.

{% highlight python linenos %}
def initialize():
    A = dict() # associative key-value array

def process(j):
    if j in A.keys():
        A[j] += 1
    elif len(A.keys()) < k - 1:
        A[j] = 1
    else:
        for l in A.keys():
            A[l] -= 1
            if A[l] == 0:
                del A[l]

def result(a):
    if a in A.keys():
        return A[a]
    else:
        return 0
{% endhighlight %}

The algorithm stores at most $k - 1$ key/value pairs. Each key requires $\log n$ bits to store, and each value at most $\log m$ bits, so the total space is $\bigO{k(\log n + \log m)}$.

To analyze the quality of the solutions, we'll proceed in two steps: first an upper bound, then a lower bound. To make things easier, we'll pretend that the `A` map consists of $n$ key-value pairs, where `A[j] == 0` if `j` is not actually stored in `A` by the algorithm.

Let $\hat{f}_j$ denote the answer output by the algorithm, and $f_j$ be the true answer.

{% block claim "Misra-Gries upper bound" %}
$$\hat{f}_j \le f_j$$
{% endblock %}

We only increase the counter for $j$ when we have seen $j$. $\qed$

{% block claim "Misra-Gries lower bound" %}
$$f_j - \frac{m}{k} \le \hat{f}_j$$
{% endblock %}

We need to look into how often we decrement the counters. To simplify the argumentation, we allow ourselves a small re-interpretation, but everything stays exactly equivalent. We'll consider that whenever `A[j]` is decremented, we also decrement $k - 1$ other counters, for a total of $k$ decrements at a time.

Since the stream consists of $m$ elements, there can be at most $m/k$ decrements. This can be explained by the "elevator argument". Consider an elevator that, every time it goes up, goes up by 1 floor. Every time it goes down, it goes down by $k$ floors. Let $m$ be the number of times it goes up in a day. How many times can it go down? The answer is that it must have gone down $\le m/k$ times. $\qed$

We can summarize these two claims in a theorem about Misra-Gries:

{% block theorem "Misra-Gries" %}
The Misra-Gries algorithm with parameter $k$ uses one pass and $\bigO{k(\log m + \log n)}$ bits of memory. For any token $j$, it provides an estimate $\hat{f}_j$ satisfying:

$$
f_j - \frac{m}{k} \le \hat{f}_j \le f_j
$$
{% endblock %}

We can use the Misra-Gries algorithm to solve the **Frequent** problem with one additional pass. If some token $j$ has $f_j > \frac{m}{k}$ then its counter `A[j]` will be $> 0$ at the end of the algorithm. Thus we can make a second pass over the input stream counting the exact frequencies of all elements $j \in \text{keys}(A)$ and output the set of desired elements.

### Estimating the number of distinct elements
We consider the following problem:

- **Distinct elements**: Output an approximation to the number $d(\sigma) = \abs{\set{j : f_j > 0}}$ of distinct elements that appear in the stream $\sigma$

This is the "Facebook problem" of estimating the number of different cities on the site. The $d$ function is also called the $L_0$ norm.

It is not possible to solve this in sublinear space with deterministic or exact algorithms. We therefore look for a randomized approximation algorithm. The algorithm, which we'll call $A$, should give a guarantee on the quality and failure probability of its output $A(\sigma)$, of the following type:

$$
\prob{\frac{d(\sigma)}{3} \le A(\sigma) \le 3d(\sigma)} \ge 1-\delta
$$

That is, with probability $1 - \delta$ we have a 3-approximate solution. The amount of space we use will be $\bigO{\log(1/\delta) \log n}$.

#### Ingredients
We need a [pairwise independent hash family](#k-wise-independence) $\mathcal{H}$. The following fact will be useful:

{% block lemma "Lemma 2: Pairwise independent hash family" %}
There exists a pairwise independent hash family so that $h$ can be sampled by picking $\bigO{\log n}$ random bits. Moreover, $h(x)$ can be calculated in space $\bigO{\log n}$.
{% endblock %}

We will also need the $\text{zeros}$ function. For an integer $p > 0$, let $\text{zeros}(p)$ denote the number of zeros that the binary representation of $p$ *ends* with (trailing `0`s). Formally:

$$
\text{zeros}(p) = \max\set{i : 2^i \text{ divides } p}
$$

For instance:

| $p$    | Binary representation | $\text{zeros}(p)$ |
| ------ | --------------------- | ----------------- |
| 1      | `1`                   | 0                 |
| 2      | `10`                  | 1                 |
| 3      | `11`                  | 0                 |
| 4      | `100`                 | 2                 |
| 5      | `101`                 | 0                 |
| 6      | `110`                 | 1                 |
| 7      | `111`                 | 0                 |
| 8      | `1000`                | 3                 |

<br> 

#### Algorithm
Let $p$ be a number of $k$ bits, i.e. $p \in \set{0, 1, \dots, 2^k-1}$. There are $n = 2^k$ possible values for $p$. Considering all possible values, we can see that each bit is 0 or 1 with probability $\frac{1}{2}$, independently. Therefore, to have $\text{zeros}(p) \ge r$, the independent event of a bit being 0 must happen $r$ times in a row, so:

$$
\prob{\text{zeros}(p) \ge r} = \left(\frac{1}{2}\right)^r
$$

Equivalently, we have:

$$
\prob{\text{zeros}(p) \ge \log_2 r} 
= \left(\frac{1}{2}\right)^{\log_2 r}
= \frac{1}{r}
$$

Therefore, if we have $r$ distinct numbers, we expect at least one  number $j$ to have $\text{zeros}(h(j)) \ge \log_2 r$.

With this intuition in mind, the algorithm is:

{% highlight python linenos %}
def initialize():
    h = random [n] -> [n] hash function from pairwise indep. family.
    z = 0

def process(j):
    z = max(z, zeros(h(j)))

def output():
    return 2 ** (z + 1/2)
{% endhighlight %}

This algorithm uses $\bigO{\log \log n}$ space to store the binary representation of $z$, which counts the number of zeros in the binary representation of $h(j)$, and $\bigO{\log n}$ for the hash function. Let's analyze the quality of the output.

#### Analysis
For each $j \in [n]$ and each integer $r \ge 0$, let $X_{r, j}$ be an indicator variable for the event "$\text{zeros}(h(j)) \ge r$":

$$
X_{r, j} = \begin{cases}
1 & \text{if } \text{zeros}(h(j)) \ge r \\
0 & \text{otherwise} \\
\end{cases}
$$

Let $Y_r$ count the number of values that hash to something with at least $r$ zeros:

$$
Y_r = \sum_{j : f_j > 0} X_{r, j}
$$

Let $t$ denote the value of $z$ when the algorithm terminates. By definition, iff there's at least one value that hashes to more than $r$ zeros, then the final $t$ is $\ge r$.

$$
Y_r > 0 \iff t \ge r
\label{eq:streaming-equiv-1}\tag{Equivalence 1}
$$

This can be equivalently stated as:

$$
Y_r = 0 \iff t < r
\label{eq:streaming-equiv-2}\tag{Equivalence 2}
$$

Since $h(j)$ is uniformly distributed over $(\log n)$-bit strings we have $\prob{\text{zeros}(h(j)) \ge r} = \left(\frac{1}{2}\right)^r$ as before. This allows us to give the expectation of $Y_r$. Let $d$ be the solution to the problem, i.e. $d = \abs{\set{j : f_j > 0}}$. Then:

$$
\expect{Y_r} = \sum_{j : f_j > 0} \expect{X_{r, j}} = \frac{d}{2^r}
$$

The variance is:

$$
\begin{align}
\var{Y_r} 
& = \expect{Y_r^2} - \expect{Y_r}^2 \\
& = \expect{\sum_{j, j' : f_j, f_{j'} > 0} X_{r, j} \cdot X_{r, j'}}
  - \sum_{j, j' : f_j, f_{j'} > 0} \expect{X_{r, j}} \expect{X_{r, j'}} \\
& \overset{(1)}{=} \sum_{j : f_j > 0} \left(
    \expect{X_{r, j}^2} - \expect{X_{r, j}}^2
  \right) \\
& \le \sum_{j : f_j > 0} \expect{X_{r, j}^2} \\
& \overset{(2)}{=} \sum_{j : f_j > 0} \expect{X_{r, j}}
= \frac{d}{2^r}
\end{align}
$$

Step $(2)$ uses the fact that $X_{j, r}$ is an indicator variable that is either 0 or 1, so $X_{j, r}^2 = X_{j, r}$. Step $(1)$ uses pairwise independence as follows:

$$
\sum_{j, j' : j \ne j'} \expect{X_{j, r} X_{j', r}}
= \sum_{j, j' : j \ne j'} \expect{X_{j, r}}\expect{X_{j', r}}
$$

Applying this in the left-hand side of $(1)$ cancels out the $X_{j, r}$ and $X_{j', r}$ where $j \ne j'$, as those terms are subtracted by sum of expectations. We're left only with terms where $j=j'$, which is why we can rewrite the sum to only sum over $j$ instead of over $j$ and $j'$. Note that this is exactly the same argument as in [our proof of the lemma on the variance of a sum](#lemma:variance-of-a-sum).

By using Markov's inequality, we get:

$$
\prob{Y_r > 0} = \prob{Y_r \ge 1} 
\le \frac{\expect{Y_r}}{1} 
= \frac{d}{2^r}
\label{eq:markov-bound1}\tag{Bound 1}
$$

Since we also know the variance, we can use Chebyshev's inequality[^chebyshev-note]:

[^chebyshev-note]: Note that Chebyshev bounds the probability of being further than $k$ from $\mu$ in either direction. This is a little overkill, because we're only interested in one direction. There may be room to make this bound tighter, but it's good enough for us.

$$
\prob{Y_r = 0} 
\le \prob{\abs{Y_r - \expect{Y_r}} \ge \frac{d}{2^r}}
\le \frac{\var{Y_r}}{(d/2^r)^2}
\le \frac{2^r}{d}
\label{eq:chebyshev-bound2}\tag{Bound 2}
$$

Let $\hat{d}$ be the algorithm's output, the approximate estimation of $d$. Recall that $t$ was the final value of $z$. Then $\hat{d} = 2^{t + 1/2}$.

Let $a$ be the smallest integer such that $2^{a + 1/2} \ge 3d$. Using $\ref{eq:streaming-equiv-1}$ and $\ref{eq:markov-bound1}$: 

$$
\prob{\hat{d} \ge 3d} 
= \prob{t \ge a}
= \prob{Y_a > 0}
\le \frac{d}{2^a}
\le \frac{\sqrt{2}}{3}
$$

Let $b$ be the largest integer such that $2^{b+1/2} \le d/3$. Using $\ref{eq:streaming-equiv-2}$ and $\ref{eq:chebyshev-bound2}$:

$$
\prob{\hat{d} \le d/3}
= \prob{t \le b}
= \prob{Y_{b+1} = 0}
\le \frac{2^{b+1}}{d}
\le \frac{\sqrt{2}}{3}
$$

This gives us failure bounds on both sides of $\frac{\sqrt{2}}{3}$, which is quite high. To decrease this, we can adjust our goal to allow for better than a 3-approximation. Alternatively, we can use the median trick to boost the probability of success.

#### Median trick
If we run $k$ copies of the above algorithm in parallel, using mutually independent random hash functions, we can output the median of the $k$ answers.

If this median exceeds $3d$ then $k/2$ individual answers must exceed $3d$. We can expect $\le k\frac{\sqrt{2}}{3}$ of them to exceed $3d$, so by the Chernoff bounds, the probability of this event is $\le 2^{-\Omega(k)}$. This works similarly for the lower bound.

If we choose $k = \Theta(\log(1 - \delta))$ we can get to a probability of success of $\delta$. This means increasing total memory to $\bigO{\log(1 - \delta) \log n}$.

Note that using the average instead of the median would not work! Messing up the average only requires one bad sample, and we have no guarantee of how far off each wrong answer can be; we only have guarantees on answers being within a successful 3-approximation.

### F2 estimation
We're now interested estimating the second frequency moment $F_2$:

$$
F_2 = \norm{\vec{f}}_2^2 = \sum_{i=1}^n f_i^2
$$

#### Naive attempt
Let's consider a first, naive attempt.

{% highlight python linenos %}
def initialize():
    z = 0

def process(j):
    z = z + 1

def output():
    return z ** 2
{% endhighlight %}

Let's look at the expectation:

$$
\expect{Z^2}
= \left(\sum_{i=1}^n f_i\right)^2
= \underbrace{\sum_{i=1}^n f_i^2}_{\text{we want this}}
+ \underbrace{2\sum_{i < j} f_i f_j}_{\text{additional term we don't want}}
$$

To get rid of this additional term, instead of incrementing $z$ for each element $j$, the solution is to flip a coin on whether to increment or decrement $z$. This is the basis for the following algorithm.

#### Alon Matias Szegedy algorithm
{% highlight python linenos %}
def initialize():
    h = random 4-wise independent hash function, h: [n] -> {-1, +1}
    z = 0

def process(j):
    z = z + h(j)

def output():
    return z ** 2
{% endhighlight %}

At the end of the algorithm, we have $Z = \sum_{i=1}^n f_i h(i)$.

{% block claim "$F_2$ unbiased estimator" %}
$Z^2$ is an unbiased estimator:

$$\expect{Z^2} = \norm{\vec{f}}_2^2$$
{% endblock %}

Let's prove this. 

$$
\begin{align}
\expect{Z^2}
& = \expect{\left(\sum_{i \in [n]} f_i h(i) \right)^2} \\
& \overset{(1)}{=} \expect{\sum_{i, j \in [n]} h(i) h(j) f_i f_j} \\
& \overset{(2)}{=} \expect{\sum_{i \in [n]} h(i)^2 f_i^2} 
  + \expect{\sum_{i \ne j \in [n]} h(i) h(j) f_i f_j} \\
& \overset{(3)}{=} \expect{\sum_{i \in [n]} f_i^2}
  + \sum_{i \ne j \in [n]} \expect{h(i)} \expect{h(j)} f_i f_j \\
& \overset{(4)}{=} \norm{\vec{f}}_2^2
\end{align}
$$

In step $(1)$, we simply expand the square. Step $(2)$ separates products of identical terms from those of non-identical terms using linearity of expectation. Step $(3)$ uses the fact that $h(i)^2 = 1$ as $h(i) = \pm 1$, as well as linearity of expectation and 4-wise independence to push down the expectation into the sum[^push-down-expectation]. Finally, step $(4)$ uses the fact that $\expect{h(i)} = \expect{h(j)} = 0$. $\qed$

[^push-down-expectation]: 4-independence implies 2-independence. We can then use the [lemma for expectation of the product of random variables](#lemma:expectation-of-product-of-k-wise-independent-variables) to "push down" expectation.

{% block claim "$F_2$ variance" %}
$$\var{Z^2} \le 2 \norm{\vec{f}}_2^4$$
{% endblock %}

Recall that we can compute the variance using the following formula:

$$
\var{Z^2} = \expect{Z^4} - (\expect{Z^2})^2
$$

We already have the expectation, so let's compute the first term: 

$$
Z^4 = 
    \left(\sum_{i \in [n]} h(i) f_i\right) \cdot
    \left(\sum_{j \in [n]} h(j) f_j\right) \cdot
    \left(\sum_{k \in [n]} h(k) f_k\right) \cdot
    \left(\sum_{l \in [n]} h(l) f_l\right)
$$

Let's consider several types of terms resulting from this multiplication:

- All the indices are equal:
  
  $$
  \sum_{i \in [n]} h(i)^4 f_i^4 = \sum_{i \in [n]} f_i^4
  $$

- The indices are matched 2 by 2:
  
  $$
  {4 \choose 2} \sum_{i < j} (h(i) h(j) f_i f_j)^2
  = 6 \sum_{i < j} f_i^2 f_j^2
  $$

- Terms with a single unmatched multiplier (meaning at least one index different from all others) can be ignored. Indeed, when we compute the expectation, we will get a term containing $\expect{h(i) \cdot h(j) \cdot h(k) \cdot h(l)}$. Suppose $i$ is different from $j$, $k$ and $l$ (but we impose no restrictions on these three: they could be the same or they could be different). Since $h$ is 4-wise independent, it we can "push down" the expectation by the [lemma on products of independent variables](#lemma:expectation-of-product-of-k-wise-independent-variables), at the very least separating the $h(i)$ term:
  
  $$
  \expect{h(i) \cdot h(j) \cdot h(k) \cdot h(l)} 
  = \expect{h(i)}\cdot\expect{h(j) \cdot h(k) \cdot h(l)}
  $$

  We'll get $\expect{h(i)} = 0$ for any $1 \le i \le n$, which confirms that the term can be ignored.

Therefore:

$$
\expect{Z^4} = \sum_{i \in [n]} f_i^4 + 6 \sum_{i < j} f_i^2 f_j^2
$$

The variance of $Z^2$ is thus:

$$
\begin{align}
\var{Z^2}
& = \expect{Z^4} - \left(\expect{Z^2}\right)^2 \\
& = \sum_{i \in [n]} f_i^4 
  + 6 \sum_{i < j} f_i^2 f_j^2
  - \left( \sum_{i \in [n]} f_i^2 \right)^2 \\
& = \sum_{i \in [n]} f_i^4 
  + 6 \sum_{i < j} f_i^2 f_j^2
  - \sum_{i \in [n]} f_i^4
  - 2 \sum_{i < j} f_i^2 f_j^2 \\
& = 4 \sum_{i < j} f_i^2 f_j^2 \\
& \overset{(1)}{\le}
    2 \left(\sum_{i \in [n]} f_i^2\right)^2 \\
& = 2 \norm{\vec{f}}_2^2
\end{align}
$$

Step $(1)$ uses the following:

$$
2 \left(\sum_{i \in [n]} f_i^2\right)^2 
= 2\left(
    \sum_{i \in [n]} f_i^4 + 2 \sum_{i < j} f_i^2 f_j^2
\right)
$$

$\qed$

#### Boosting the precision
We can improve the precision of the estimate by repeating the algorithm a sufficient number of times independently, and outputting the average.

In this case, the algorithm is:

1. Maintain $t = \frac{6}{\epsilon^2}$ identical and independent copies of the above algorithm, and let $Z_1^2, Z_2^2, \dots, Z_t^2$ denote the output of these copies.
2. Output $\tilde{Z}^2 = \frac{1}{t} \sum_{i=1}^t Z_i^2$

We make the following claim about this algorithm:

{% block claim %}
Let $\norm{\vec{f}}_2^2$ denote the exact correct answer. The algorithm produces outputs an answer $\tilde{Z}^2$ satisfying:

$$
\prob{\abs{\tilde{Z}^2 - \norm{\vec{f}}_2^2} \ge \epsilon \norm{\vec{f}}_2^2}
\le \frac{1}{3}
\label{eq:f2-goal}\tag{$F_2$ goal}
$$
{% endblock %}

By linearity of expectation, $\tilde{Z}^2$ remains an unbiased estimator as:

$$
\expect{\tilde{Z}^2} = \frac{1}{t} \sum_{i=1}^t \expect{Z_i^2} = \norm{\vec{f}}_2^2
$$

Since we know [the variance of a single run](#claim:f-2-variance), the variance of the average of all runs is:

$$
\var{\tilde{Z}^2} 
= \var{\frac{1}{t} \sum_{i=1}^t Z_i^2}
= \frac{1}{t^2} \sum_{i=1}^t \var{Z_i^2}
= \frac{1}{t} \var{Z^2}
\le \frac{2}{t} \norm{\vec{f}}_2^4
$$

By [Chebyshev's inequality](#theorem:chebyshev-s-inequality), this allows us to prove that we're achieving our goal $\ref{eq:f2-goal}$:

$$
\begin{align}
\prob{\abs{\tilde{Z}^2 - \norm{\vec{f}}_2^2} \ge \epsilon \norm{\vec{f}}_2^2}
& \le \frac{\var{\tilde{Z}^2}}{\epsilon^2\norm{\vec{f}}_2^4} \\
& \le \frac{2}{t\epsilon^2} \\
& \le \frac{1}{3}
\end{align}
$$

$\qed$

Note that we didn't use the [median trick](#median-trick) in this case, but we used the average instead. Using the median is especially problematic when the failure probability is $\ge \frac{1}{2}$. As an analogy, when you flip a coin that gives tails 60% of the time, the median will always give tails as $n \rightarrow \infty$, so be careful!

## Locality sensitive hashing
### Definition
Intuitively, a *locality sensitive hashing function* (LSH function) is a hash function that hashes "close points" to the same value, and "distant points" to different values.

To be more precise, if $\text{dist}(p, q) \le r$ we want to map $p$ and $q$ to the same value with high probability; if $\text{dist}(p, q) > c\cdot r$, we want $p$ and $q$ to hash to different values with high probability. More formally:

{% block definition "Locality sensitive hashing families" %}
Let $U$ be the universe containing the points $P$. Suppose he have a family $\mathcal{H} = \set{h: U \rightarrow \mathbb{Z}}$ of functions mapping from $U$ to $\mathbb{Z}$. We say $\mathcal{H}$ is $(r, c\cdot r, p_1, p_2)$-LSH if for all $p, q \in U$:

$$
\begin{align}
\text{dist}(p, q) \le r 
& \implies \mathbb{P}_{h\sim\mathcal{H}}\left[
  h(p) = h(q)
\right] \ge p_1 \\

\text{dist}(p, q) \ge c\cdot r 
& \implies \mathbb{P}_{h\sim\mathcal{H}}\left[
  h(p) = h(q)
\right] \le p_2 \\
\end{align}
$$
{% endblock %}

Here, the distance function could be anything, but we'll just consider it to be Euclidean distance for the sake of simplicity.

Let's try to see what this means visually:

![Visualization of the distances and areas involved](/images/advanced-algorithms/lsh.svg)

We consider $p$ to be at the center of the diagram. Let's consider the guarantees we make for different positions of $q$:

- If $q$ is within the red circle, a function $h$ selected uniformly at random from $\mathcal{H}$ will hash $p$ and $q$ to the same value with probability at least $p_1$.
- If $q$ is within the blue circle (but not within the red), we make no guarantees.
- If $q$ is outside both circles (in the black square), then the two values collide with probability at most $p_2$.

### Boosting probabilities
Given an $(r, c\cdot r, p_1, p_2)$-LSH family (under the assumption $p_1 > p_2$), we can boost it to get $p_1 \approx 1$ and $p_2 \approx 0$. We do this in two steps.

#### Reducing $p_2$
To reduce $p_2$, we simply draw $k$ functions from $\mathcal{H}$ independently. The overall hashing function $h$ maps a point $p \in P$ to a $k$-dimensional vector.

$$
h(p) = \left[ h_1(p), \dots, h_k(p)\right]
$$

By independence of the functions $h_1, \dots, h_k$, we have:

$$
\text{dist}(p, q) \ge c \cdot r 
\implies \prob{h(p) = h(q)}
= \prob{h_1(p) = h_1(q)} \cdot \dots \cdot \prob{h_k(p) = h_k(q)}
\le p_2^k
$$

The last step happens because each term is $\le p_2$ since we're considering the case $\text{dist}(p, q) \ge c \cdot r$.

#### Augmenting $p_1$
Unfortunately, the above also reduced $p_1$: the above hash function hashes close points to the same vector with probability $\ge p_1^k$, which is not what we want. We want to be able to make a better guarantee than that. To boost this probability, we run $l$ independent copies of the above $k$-dimensional vector. This defines something like a $l \times k$ matrix of hashes:

$$
\begin{align}
f_1(p) & = \left[h_{1, 1}(p), \dots, h_{1, k}(p)\right] \\
       & \vdots \\
f_l(p) & =  \left[h_{l, 1}(p), \dots, h_{l, k}(p)\right] \\ 
\end{align}
$$

For a sufficiently large $l$, there is a high probability that there is an $i \in [l]$ such that $f_i(p) = f_i(q)$. Indeed, if $\text{dist}(p, q) \le r$, then:

$$
\begin{align}
\prob{\exists i \mid f_i(p) = f_i(q)} 
& = 1 - \prob{\forall i, f_i(p) \ne f_i(q)} \\
& \overset{(1)}{=} 1 - \prob{f_i(p) \ne f_i(q)}^l \\
& \overset{(2)}{\ge} 1 - (1 - p_1^k)^l
\end{align}
$$

Step $(1)$ is by independence of the functions, and step $(2)$ is because each individual probability term is $\le 1 - p_1^k$ as it's the inverse of the event of two vectors being identical, which we previously said happened with probability $\ge p_1^k$.

#### Tuning parameters
In the above, we want to find any function $f_i$, $i\in[l]$, that hashes $p$ and $q$ to the same vector of size $k$. In other words, we want any one of $l$ function to produce all the same $k$ values; we want a disjunction of a conjunction ($\lor$ of $\land$) to be true in order to consider that a collision has happened.

How do we tune the parameters $k$ and $l$ in this setting?

First, we choose $k$ according to either one of these equivalent equations:

$$
p_2^k = \frac{1}{n}
\iff
k = \frac{\log n}{\log(1 / p_2)}
$$

We'll assume $p_1 = p_2^\rho$ for some $\rho < 1$. We'll see that this $\rho$ parameter is of paramount importance, determining the running time and memory of the algorithm. We choose $l \propto n^\rho \ln n$. 

### Example: LSH for binary vectors
Let's give an example of a LSH family for binary vectors. Consider $P \subseteq \set{0, 1}^d$, and let $\text{dist}$ be the [Manhattan distance](https://en.wikipedia.org/wiki/Taxicab_geometry) (i.e. the number of bits that are different between the two binary vectors).

{% block claim %}
The family $\mathcal{H} := \set{h_i}_{i=1}^d$, where $h_i(p) = p_i$ selects the $i$<sup>th</sup> bit of $p$, is $(r, c\cdot r, e^{-r/d}, e^{-c\cdot r/d})$-LSH.
{% endblock %}

Observe that for each $p, q \in \set{0, 1}^d$:

$$
\mathbb{P}_{h\sim\mathcal{H}}\left[h(p) = h(q)\right] 
= \frac{\text{# bits in common}}{\text{total bits}}
= \frac{d - \text{dist}(p, q)}{d}
= 1 - \frac{\text{dist}(p, q)}{d}
$$

Therefore:

$$
\mathbb{P}_{h\sim\mathcal{H}}\left[h(p) = h(q)\right] = \begin{cases}
\ge 1 - \frac{r}{d} \approx e^{-r/d}  & \text{if dist}(p, q) \le r \\
\le 1 - \frac{c\cdot r}{d} \approx e^{e-c\cdot r/d} & \text{if dist}(p, q) \ge c \cdot r \\
\end{cases}
$$

Therefore, $\mathcal{H}$ is $(r, c\cdot r, e^{-r/d}, e^{-c\cdot r/d})$-LSH. $\qed$

### Application: Approximate Nearest Neighbor Search
#### Nearest Neighbor Search
Consider the following problem, called the Nearest Neighbor Search (NNS): consider a set $P \subset \mathbb{R}^d$ of $n$ points in (potentially) high-dimensional space. For any query $q \in \mathbb{R}^d$, find the closest point $p$:

$$
\argmin_{p \in P} \text{dist}(p, q)
$$

The naive solution would be to loop over all points in $P$, but this takes $\bigO{n\cdot d}$ time and space. 

If we had $d=1$ we pre-process the points by sorting them, and then run a binary search to find the closest element. Generalizing this to higher dimensions leads us to [k-d trees](https://en.wikipedia.org/wiki/K-d_tree), but these unfortunately suffer from the [curse of dimensionality](https://en.wikipedia.org/wiki/Curse_of_dimensionality), and fail to beat the naive solution when $d = \Omega(\log n)$.

#### Approximate Nearest Neighbor Search
If we allow approximate solutions instead of searching for the exact nearest neighbor, we can reduce this problem to that of finding an LHS family. We'll call the approximate variant Approximate Nearest Neighbor Search (ANNS); in this problem, instead of finding the closest point $p$ to a query point $q$, we're happy to find a point $p \in P$ such that:

$$
\text{dist}(p, q) \le c \cdot \min_{s \in P} \text{dist}(s, q)
$$

Here, $c$ is the approximation factor.

#### Reduction to LSH
With the following algorithm, the ANNS problem is reduced to that of finding a LSH.

The idea of the algorithm is to take a $(r, c\cdot r, p_1, p_2)$-LSH family with $p_1 \approx 1$ and $p_2 \approx 0$ (we can [boost the probabilities](#boosting-probabilities) if we need to), and to build a hash table in which we store $h(p)$ for each $p \in P$. For a query point $q$, we can do a lookup in the hash table in $\bigO{1}$: we can then traverse the linked list of points hashing to the same value, and pick the first point $p$ satisfying $\text{dist}(p, q) \le c \cdot r$.

{% highlight python linenos %}
def preprocess():
     choose k * l functions from H
     construct l hash tables
     for i in range(l):
        for p in P:
            store p at location f[i](p) = (h[i, 1](p), ..., h[i, k](p)) in i-th hash table

def query(q):
    for i in range(l):
        compute f[i](q)
        go over all points where f[i](p) = f[i](q)
        return first point p satisfying dist(p, q) <= c * r
{% endhighlight %}

To see how this solves the ANNS problem, consider a point $p$ such that $\text{dist}(p, q) \le r$. In this case, we have $h(p) = h(q)$ with probability $p_1 \approx 1$. If we have $\text{dist}(p, q) \ge c\cdot r$, we have $h(p) = h(q)$ with probability $p_2 \approx 0$.

#### Probability of success
Let's fix a query point $q$, and consider the "good case", i.e. a point $p$ in the inner circle, meaning $\text{dist}(p, q) \le r$. Then:

$$
\begin{align}
\prob{\exists i : f_i(p) = f_i(q)}
& \overset{(1)}{\ge} 1 - (1 - p_1^k)^l \\
& \overset{(2)}{=}   1 - (1 - p_2^{\rho k})^l \\
& \overset{(3)}{=}   1 - (1 - n^{-\rho})^l \\
& \overset{(4)}{\approx} 1 - e^{-l\cdot n^{-\rho}} \\
& \overset{(5)}{=} 1 - \frac{1}{n}
\end{align}
$$

Step $(1)$ follows from [what we proved](#augmenting-p_1) when augmenting $p_1$. Step $(2)$ follows from [our assumption](#tuning-parameters) that $p_1 = p_2^\rho$ for some $\rho < 1$. Step $(3)$ comes from [our choice of $k$](#tuning-parameters) that satisfies $p_2^k = \frac{1}{n}$, and step $(4)$ from the (by now) usual trick of $1-x \le e^{-x}$, which stems from the Taylor expansion of $e^{-x}$. Finally, we simplify the expression in step $(5)$.

This all means that for any point $p$ within distance $\le r$, we output $p$ with probability $\ge 1 - 1/n$.

#### Space and time complexity of the reduction
The algorithm maintains $\bigO{l}$ hash tables, each of which contains $n = \abs{P}$ values, where each is a $k$-dimensional vector. The space complexity is thus:

$$
\bigO{l \cdot n \cdot k} 
= \bigO{n^{1 + \rho} \cdot \ln n \cdot \frac{\log n}{\log(1 / p_2)}}
$$

since we [picked the parameters](#tuning-parameters) $l = \bigO{n^\rho \ln n}$ and $k = \bigO{\frac{\log n}{\log(1 / p_2)}}$.

For the query time, we need to compute the $k$-dimensional vectors $f_i(q)$ for $i \in [l]$, which is $\bigO{l\cdot k}$. Then, we need to look at candidate points: there is overhead in considering ineligible ("far away") points. To know how much overhead this represents, we must consider how many "far away" points we expect to find in a linked list. 

To compute this expectation, we fix a query point $q$, and consider that $\text{dist}(p, q) > c \cdot r$, i.e. the point is outside both circles. For any fixed $i$, the expected number of points $p$ that hash to the same value as $q$ but are outside both circles is:
  
$$
\expect{\# p : \text{dist}(p, q) > c \cdot r \land f_i(p) = f_i(q)}
\le n \cdot p_2^k
\le 1
$$

The first step happens by linearity of expectation, and the second one by our choice of $k$.

Summing up over all $i \in [l]$, in expectation there are $\bigO{l}$ far-away points in our data set mapping to the same value as $q$ for *some* $i$. To measure their distance (and thus know their ineligibility), we must take time $\bigO{d}$ for each such point. This implies an overhead of $\bigO{l\cdot d}$ to examine these.

In total, we have a runtime of:

$$
\bigO{l\cdot k + d \cdot l}
= \bigO{n^\rho \cdot \ln(n) \cdot \left( \frac{\log n}{\log(1/p_2)} + d \right)}
$$

Ignoring lower-order terms, the algorithm runs with memory $\bigO{n^{\rho + 1}}$ and query time $\bigO{n^\rho}$.

## Submodularity
### Definition
{% block definition "Set function" %}
A set function $f : 2^N \rightarrow \mathbb{R}$ is a function assigning a real value to every subset $S \subseteq N$ of a ground set $N$.
{% endblock %}

In many cases, the value of an item may depend on whether we already have selected some other item. For instance, just buying one shoe is much less valuable than buying both. Or in the other direction, in a stamp collection, once we already have a stamp of a particular type, an additional stamp of the same type is less valuable.

In this latter example, the function that assigns a (monetary) value to the stamp collection corresponds to a *submodular function*.

{% block definition "Classic definition of submodularity" %}
A set function $f$ is submodular if, for all $A, B \subseteq N$:

$$f(A) + f(B) \ge f(A \cup B) + f(A \cap B)$$
{% endblock %}

An alternative (but equivalent) definition of submodularity may make more intuitive sense, but requires the introduction of the concept of *marginal contribution*:

{% block definition "Marginal contribution" %}
Given a set function $f$, a set $S \subseteq N$ and an element $u \in S$, the *marginal contribution* of $u$ to $S$ is defined as:

$$f(u \mid S) := f(S \cup \set{u}) - f(S)$$
{% endblock %}

The marginal contribution measures how much value an individual element $u$ adds if added to a set $S$. This allows us to give the alternative definition of submodularity:

{% block definition "Diminishing returns definition of submodularity" %}
A set function $f$ is submodular *if and only if* for all $A \subseteq B \subseteq N$ and each $u \in N \setminus B$ the following holds:

$$f(u \mid A) \ge f(u \mid B)$$
{% endblock %}

Intuitively, this means that a function is submodular if adding elements to a smaller set has a larger marginal contribution than if added to a larger set. Let's prove that this is equivalent to the [classic definition](#definition:classic-definition-of-submodularity).

First, we'll prove the $\Rightarrow$ direction, namely that the [classic definition](#definition:classic-definition-of-submodularity) implies the [diminishing returns definition](#definition:diminishing-returns-definition-of-submodularity). Suppose that $f$ is submodular and let $A \subseteq B$ be two sets. We'll consider the sets $A \cup \set{u}$ and $B$. According to the classic definition:

$$
\begin{align}
f(A \cup \set{u}) + f(B) & \ge f(A \cup \set{u} \cup B) + f((A \cup \set{u}) \cap B) \\

f(A \cup \set{u}) + f(B) & \ge f(\set{u} \cup B) + f(A) \\

f(A \cup \set{u}) - f(A) & \ge f(\set{u} \cup B) - f(B) \\

f(u \mid A) & \ge f(u \mid B)
\end{align}
$$

The first step uses the fact that $A \subseteq B$, thus $A \cap B = A$; this is also the case if we consider $A \cup \set{u}$ instead of $A$, regardless of whether $u \in A$. The second step rearranges the terms, and the third one uses the [definition of marginal contribution](#definition:marginal-contribution).

Now, let's prove the $\Leftarrow$ direction, namely that the [diminishing returns definition](#definition:diminishing-returns-definition-of-submodularity) implies the [classic definition](#definition:classic-definition-of-submodularity). Let's consider two sets $C, D \subseteq N$. Let $h = \abs{D \setminus C}$ be the number of elements in $D \setminus C = \set{d_1, d_2, \dots, d_h}$. Let $D_i = \set{d_j : 1 \le j \le i}$ be the set of the first $i$ elements $D \setminus C$.

$$
\begin{align}
f(D) - f(C \cap D)
& \overset{(1)}{=} f(D_h) - f((C \cap D)\cup D_0) \\
& \overset{(2)}{=} f((C \cap D) \cup D_h) - f((C \cap D)\cup D_0) \\
& \overset{(3)}{=} \sum_{i = 1}^h f((C\cap D)\cup D_i) - f((C\cap D)\cup D_{i-1}) \\
& \overset{(4)}{=} \sum_{i = 1}^h f(d_i \mid (C \cap D) \cup D_{i - 1}) \\
& \overset{(5)}{\ge} \sum_{i = 1}^h f(d_i \mid C \cup D_{i - 1}) \\
& \overset{(6)}{=} \sum_{i = 1}^h f(D_i \cup C) - f(D_{i-1} \cap C) \\
& \overset{(7)}{=} f(C \cup D) - f(C) \\
\end{align}
$$

Step $(1)$ follows from the fact that $D_0 = \emptyset$ and that $D_h = D$, and step $(2)$ from the fact that $(C \cap D) \cup D_h = D = D_h$ since $(C \cap D) \subseteq D$. Step $(3)$ introduces a reformulation as a telescoping sum[^telescoping-sum], and step $(4)$ rewrites the terms as a marginal contribution. The inequality in step $(5)$ holds by assumption, since $(C\cap D) \cup D_{i-1} \subseteq C \cup D_{i-1}$ as $(C \cap D) \subseteq C$. Step $(6)$ expands the marginal contributions according to the definition; this sum is telescoping, so we can do step $(7)$.

[^telescoping-sum]: [Telescoping](https://en.wikipedia.org/wiki/Telescoping_series) means that if we expand the sum, everything cancels out except the very first and last terms.

Rearranging the terms of the above inequality yields $f(C) + f(D) \ge f(C \cup D) + f(C \cap D)$ as required. $\qed$

### Examples
#### Cut size
The function measuring the size of a cut induced by $(S, V \setminus S)$ in a graph $G = (V, E)$ is:

$$
\delta(S) = \abs{\set{(u, v) : u \in S, v \in V \setminus S}}
$$

This function $\delta : 2^V \rightarrow \mathbb{R}$ maps from the ground set $V$ to the reals. To see that it is submodular, we can look at the marginal contribution of a single point $u$ to a cut $S$. Let $E(v, T)$ be the number of edges between some node $v$ and a set of nodes $T$:

$$
\delta(v \mid S) = E(v, V \setminus (S \cup \set{v})) - E(v, S)
$$

In other words, the contribution of adding a node to a cut $S$ is the number of edges that now cross the cut $(S \cup \set{v})$ by the inclusion of $v$, minus the number of edges that no longer cross the cut, i.e. those that have been "absorbed" into the set by inclusion of $v$.

Observe that the first term is decreasing in $S$, and the second is increasing in $S$, but is subtracted. Hence, the whole expression is decreasing in $S$, which proves submodularity.

#### Coverage function
Consider a finite collection of sets $T_1, T_2, \dots T_n$ with each $T_i \subseteq \mathbb{N}$. We consider a ground set of indices of these sets $N = [n]$ and a set function $f: 2^N \rightarrow \mathbb{R}$ defined by:

$$
f(S) = \abs{\bigcup_{i\in S} T_i}
$$

The function counts how many elements in $\mathbb{N}$ are covered by the sets specified by the indices in $S$. To show that this function is submodular, we analyze the marginal contribution of a set $T_i$ (represented by the addition of index $i$ to a set $S$):

$$
f(i \mid S) 
= \abs{T_i \cup \bigcup_{j \in S} T_j} - \abs{\bigcup_{j\in S} T_j}
= \abs{T_i \setminus \bigcup_{j\in S} T_j}
$$

This is decreasing in $S$ so $f$ is submodular.

#### Matroid rank
Let $\mathcal{M} = (X, \mathcal{I})$ be a [matroid](#matroids) on a ground set $X$. Let $r: 2^X \rightarrow \mathbb{R}$ be the rank function, defined by:

$$
r(A) = \max_{I \in \mathcal{I} \cap A} \abs{I}
$$

In words, $r(A)$ is the size of a maximal independent set containing only elements from $A$.

This function is submodular: consider two sets $A, B \in X$. Let $C$ be any maximal independent set of $\mathcal{M}$ contained in $A \cap B$. By the [matroid augmentation property $(I_2)$](#definition:matroid), we can extend $C$ to a maximal independent set $D$ contained in $A \cup B$. Then:

$$
\begin{align}
r(A \cup B) + r(A \cap B)
& =   \abs{D} + \abs{C} \\
& \le \abs{D\cap (A \cup B)} + \abs{D \cap (A \cap B)} \\
& =   \abs{D \cap B} + \abs{D \cap A} \\
& \le r(B) + r(A) \\
\end{align}
$$

This satisfies the classic definition of submodularity.

#### Summarization
A function summarizing data is often submodular, much for the same reason as the stamp collection example.

#### Influence maximization
Suppose we want to select $k$ people to give free samples to in order to launch a product. We want to select people that have the maximum influence, meaning that they tell the most people about the product. Solving this is basically a maximization of a submodular function under a cardinality constraint, which [we'll see more about later](#monotone-cardinality-constrained-submodular-maximization).

#### Entropy
Entropy is another example of a submodular function. If we already have a piece of information, then receiving it a second time adds no entropy. Or perhaps, if we have some information already, additional information adds less entropy than if we had no information at all.

### Submodular function minimization
In the following section, we'll assume that we can evaluate $f(S)$ in constant time. We will show that minimizing $f$ is equivalent to finding the global minimum of a certain convex continuous function, which we can do in polynomial time using the (sub)gradient descent. To be able to use the whole framework of convex optimization, we need to extend our submodular function on discrete sets, to a convex function on a continuous domain. This is what *Lovász extension* does.

#### Lovász extension
Say we have a submodular function $f : 2^N \rightarrow \mathbb{R}$. We want to *extend* it to $\hat{f}$. 

To do that, we can start by thinking of $f : 2^N \rightarrow \mathbb{R}$ as $f : \set{0, 1}^n \rightarrow \mathbb{R}$, where $n = \abs{N}$, which maps indicator vectors to real values. This indicator vector indicates which elements of $N$ are contained in the considered set $S$.

We also introduce an equivalence between $N$ and $[n]$ (we can just let the elements in $N$ be numbered).

{% block definition "Lovász extension" %}
Let $f : \set{0, 1}^n \rightarrow \mathbb{R}$. Define $\hat{f}: [0, 1]^n \rightarrow \mathbb{R}$, the Lovász extension of $f$, as:

$$
\hat{f}(z) = \mathbb{E}_{\lambda\sim\mathcal{U}(0, 1)}\left[
  f(\set{i : z_i \ge \lambda})
\right] \quad \forall z\in[0, 1]^n 
$$

where $\lambda\sim\mathcal{U}(0, 1)$ denotes a uniformly random sample on $[0, 1]$.
{% endblock %}

In other words, given a vector $z \in [0, 1]^n$, the extension $\hat{f}$ returns the expectation of placing a threshold $\lambda$ uniformly at random in $[0, 1]$, and evaluating $f$ with the set of terms in $z$ that are $\ge \lambda$.

Notice that for any $\lambda \in ]0, 1]$, if $z \in \set{0, 1}^n$, then $\set{i : z_i \ge \lambda} = z$, so $\hat{f}$ will agree with $f$ over the hypercube (all integral points). At fractional points, $\hat{f}$ is some kind of average of $f$.

We can actually give a more closed form of this averaging representation of $\hat{f}$. To do so, we order the elements of $z$:

$$
1 = z_1 \ge z_2 \ge \dots \ge z_n \ge z_{n+1} = 0
$$

Let $S_i$ for any $i\in[n]\cup\set{0}$ equal $\set{1, 2, \dots, i}$. Then:

$$
\emptyset = S_0 \subseteq S_1 \subseteq \dots \subseteq S_n = [n]
$$

Note that for any $\lambda \in [z_i, z_{i+1}[$ (the probability of this event being $z_i - z_{i+1}$ since $\lambda$ is selected from $\mathcal{U}(0, 1)$), for any $i \in [n]\cup\set{0}$, we have $\set{j \mid z_j \ge \lambda} = S_i$.

All of this leads us to the following formulation:

{% block definition "Lovász extension formulation" %}
Let $1 = z_0 \ge z_1 \ge z_2 \ge \dots \ge z_n \ge z_{n+1} = 0$ be the non-increasingly ordered components of $z$.

Let $S_i = \set{1, 2, \dots, i}$ where $\emptyset = S_0 \subseteq S_1 \subseteq \dots \subseteq S_n = [n]$. We let $S_i$ be ordered by the same permutation that ordered the $z_i$.

Then:

$$\hat{f}(z) = \sum_{i=0}^n (z_i - z_{i+1})f(S_i)$$
{% endblock %}

This stems from the fact that the probability of $\lambda \in [z_i, z_{i+1})$ is equal to $z_i - z_{i+1}$, for any $i \in [n]\cup\set{0}$, as $\lambda$ is uniformly distributed in $[0, 1]$. Additionally, if this event happens, then $\set{j \mid z_j \ge \lambda} = S_i$. $\qed$

This means that we can evaluate $\hat{f}$ at any $z$ using $n+1$ evaluations of $f$ (we assumed a call to take constant time).

For instance, let $N = \set{1, 2, 3, 4}$. Then $\hat{f}(0.75, 0.3, 0.2, 0.3)$ gives rise to the following values:

- $z_0 = 1, S_0 = \emptyset$
- $z_1 = 0.75, S_1 = \set{1}$
- $z_2 = 0.3, S_2 = \set{1, 2}$
- $z_3 = 0.3, S_3 = \set{1, 2, 4}$
- $z_4 = 0.2, S_4 = \set{1, 2, 3, 4}$
- $z_5 = 0$

The result of the function can be computed from $n + 1$ evaluations of $f$:

$$
\begin{align}
\hat{f}(0.75, 0.3, 0.2, 0.3)
& = (1 - 0.75)f(S_0) + (0.75 - 0.3) f(S_1) + (0.3 - 0.3) f(S_2) \\
& \qquad + (0.3 - 0.2) f(S_3) + (0.2 - 0) f(S_4) \\
& = 0.25f(\emptyset) + 0.45f(\set{1}) + 0.1f(\set{1, 2, 4}) + 0.2f(\set{1, 2, 3, 4}) \\
\end{align}
$$

#### Convexity of the Lovász extension
If the Lovász extension is convex, we have a whole host of convex optimization methods that we can apply (subgradient descent, ellipsoid, ...). Therefore, the following theorem is crucial.

{% block theorem "Convexity of the Lovász extension" %}
Let $\hat{f}$ be the Lovász extension of $f : \set{0, 1}^n \rightarrow \mathbb{R}$. Then:

$$
\hat{f}\text{ is convex} \iff f\text{ is submodular}
$$
{% endblock %}

This proof is quite long, we will only show the $\Rightarrow$ direction, that is, $f$ submodular $\implies \hat{f}$ convex. Let's start with an outline of the proof:

1. Redefine $\hat{f}(z)$ as a maximization problem
2. Observe that the problem is convex
3. Prove that $\hat{f}(z)$ is equal to the objective function by upper-bounding and lower-bounding it.

For this proof, we assume that $f$ is normalized, meaning $f(\emptyset) = 0$ (without loss of generality, as we could just "shift" $f$ to achieve this). We [previously gave a formulation of the Lovász extension](#definition:lovasz-extension-formulation), and we'll give a second one here, as an LP. For $z \in [0, 1]^n$, and $f$ submodular, $\hat{f}$ is the solution to the following LP:

$$
\begin{align}
\textbf{maximize: }   & g(z) = \max_x z^T x  & \\
\textbf{subject to: } 
    & \sum_{i\in S} x_i \le f(S) & \forall S \subseteq N \\
    & \sum_{i\in N} x_i = f(N) & \\
\end{align}
$$

This may seem to come out of nowhere, but we'll see the rationale once we see the dual formulation. This LP has exponentially many constraints, as $\forall S \subseteq N$ is equivalent to $\forall S \in 2^N$.

Our main claim is that the objective function $g(z) = \hat{f}(z)$, $\forall z \in [0, 1]^n$. Note that the objective function $g$ is convex, as it is the max of a linear function over a convex set. To prove this, we observe that for $0 \le \lambda \le 1$ and $z_1, z_2 \in [0, 1]^n$:

$$
\begin{align}
g(\lambda z_1 + (1 - \lambda) z_2)
& =   \max_x (\lambda z_1^T x + (1 - \lambda) z_2^T x) \\
& \le \lambda (\max_x (z_1^T x)) + (1 - \lambda) (\max_x (z_2^T x)) \\
& = \lambda g(z_1) + (1-\lambda)g(z_2) \\
\end{align}
$$

Now, we need to prove $\hat{f} = g$ to finish the proof. We'll do so using [weak duality](#weak-duality). The dual program is given by:

$$
\begin{align}
\textbf{minimize: }   & \sum_{S \subseteq N} y_S f(S)  & \\
\textbf{subject to: } 
    & \sum_{S \ni i} Y_s = z_i & \forall i \in N \\
    & y_S \ge 0                & \forall S \subset N \\
\end{align}
$$

By weak duality, for any $x$ feasible in the primal, and $y$ feasible in the dual, we have:

$$
z^T x \le \sum_{S \subseteq N} y_S f(S)
$$

By strong duality, we achieve equality if $x$ and $y$ are optimal solutions. 

We'll assume the same notation as in the [closed formulation of the Lovász extension](#definition:lovasz-extension-formulation), meaning that we have $1 = z_0 \ge z_1 \ge z_2 \ge \dots \ge z_n \ge z_{n+1} = 0$. We also have $S_i = \set{1, 2, \dots, i}$ where $\emptyset = S_0 \subseteq S_1 \subseteq \dots \subseteq S_n = [n]$. Once again, we let $S_i$ be ordered by the same permutation that ordered the $z_i$.

We define:

$$
\begin{align}
x_i^* & = f(S_i) - f(S_{i-1}) \\
y_S^* & = \begin{cases}
    z_i - z_{i+1} & \text{for } S = S_i \text{ with } i \in [n] \\
    0             & \text{otherwise} \\
\end{cases} \\
\end{align}
$$

Now, we'll make a few claims that complete the proof. To prove these claims, we'll first need:

$$
\begin{align}
z^T x^*
& = \sum_{i=1}^n z_i \cdot (f(S_i) - f(S_{i-1})) 
\tag{1}\label{eq:convexity-step-2} \\

& = \sum_{i=0}^n (z_i - z_{i+1}) f(S_i) 
\tag{2}\label{eq:convexity-step-3} \\

& = \sum_{S \subseteq N} y_S^* f(S)
\tag{3}\label{eq:convexity-step-4} \\
\end{align}
$$

{% block claim "Convexity proof claim 1" %}
$$z^T x^* = \hat{f}(z)$$
{% endblock %} 

This follows from the [closed formulation of the Lovász extension](#definition:lovasz-extension-formulation) and from $(\ref{eq:convexity-step-3})$. $\qed$

{% block claim "Convexity proof claim 2" %}
$$z^T x^* = \sum_{S\subseteq N} y_S f(S)$$
{% endblock %}

This is proven by $(\ref{eq:convexity-step-4})$. $\qed$

{% block claim "Convexity proof claim 3" %}
$y^*$ is feasible for the dual.
{% endblock %}

Observe that $y^*$ has all non-negative entries because $z_i \ge z_{i+1} \ge \dots \ge z_{n+1} = 0$. Further, for any $i$:

$$
\sum_{S : S \ni i} y_S^* 
= \sum_{j \ge i} y_{S_j}^*
= \sum_{j = i}^n z_j - z_{j+1}
= z_i - z_{n+1}
= z_i
$$

The third step happens because the sum is telescoping. This exactly satisfies the dual LP, as required. $\qed$

{% block claim "Convexity proof claim 4" %}
$x^*$ is feasible for the primal.
{% endblock %}

Observe that:

$$
\sum_{i=1}^n x_i^*
= \sum_{i \le n} f(S_i) - f(S_{i-1})
= f(N) - f(\emptyset)
= f(N)
$$

Here, we used that $f$ is normalized so $f(\emptyset) = 0$. Let $S \subset N$. Then, for $x^*$ to be feasible, we must show:

$$
\sum_{i \in S} x_i^* \le f(S)
$$

This can be done by induction on the size of the set. The base case trivially holds as we sum over $S_0 = \emptyset$, which gives us 0, which is equal to $f(\emptyset)$. For the inductive step, we argue that if $i$ is the largest index in $S$. The [classic definition of submodularity](#definition:classic-definition-of-submodularity) can be rearranged to: 

$$
f(S) 
\ge f(S_i) - f(S_{i-1}) + f(S \setminus \set{i})
=   x_i^* + f(S \setminus \set{i})
\ge \sum_{i \in S} x_i^*
$$

The final inequality uses the induction hypothesis. $\qed$

With these four claims proven, we have proven the theorem in the $\Rightarrow$ direction. $\qed$

### Submodular function maximization
For this part, we'll assume that all set functions we deal with are:

- **Non-negative**: $f(S) \ge 0 \quad \forall S \subseteq N$
- **Normalized**: $f(\emptyset) = 0$

#### Monotone cardinality-constrained submodular maximization
For this section, we'll also assume that $f$ is:

- **Monotone**: $f(S) \le f(T) \quad\forall S\subseteq T\subseteq N$

Monotonicity tells us that the value of $f(S)$ cannot decrease as we add elements; the marginal contribution is always positive. This means that $f(N) \ge f(S) \quad \forall S \subseteq N$, so unconstrained maximization is trivial (just pick the ground set). 

Instead, we'll look at the less trivial *constrained maximization* problem, in which we're looking for a set $S \subseteq N$ of size at most $k$ that maximizes $f$. 

In the beginning of the course, we saw that weighted maximization problems with linear objectives can be solved optimally by the greedy algorithm. This is even true if we generalize the constraint that $\abs{S} \le k$ by a general matroid constraint. 

What happens if we try to generalize this submodular functions? The natural approach is to, at each step, greedily add the element that has the maximal marginal gain:

{% highlight python linenos %}
def greedy_submodular_maximization(N, f, k):
    """
    Input:  N   ground set
            f   submodular function 2^N -> R
            k   size constraint 0 <= k <= |N|
    Output: S ⊆ N with |S| <= k
    """
    S = set()
    for i in range(k):
        u_i = argmax over u in (N\S) of f(u|S)
        S += u_i
    return S
{% endhighlight %}

However, this algorithm can produce suboptimal results. For instance, if we consider a [coverage function](#coverage-function) with sets $T_1 = \set{1, 2, 3, 4}$, $T_2 = \set{1, 2, 5}$, $T_3 = {3, 4, 6}$, a greedy algorithm will select $T_1$ and then either $T_2$ and $T_3$ (covering 5 elements), whereas the optimal solution is to pick $T_2$ and $T_3$ (covering 6 elements).

Still, we can show that the greedy algorithm gives a constant factor approximation. To show this, we'll need to introduce a lemma about marginal contributions:

{% block lemma "Sum of marginal contributions" %}
Let $f : 2^N \rightarrow \mathbb{R}$ be a submodular function, and let $S, T\subseteq N$. Then:

$$
\sum_{e \in T \setminus S} f(e \mid S) \ge f(T \cup S) - f(S)
$$

Equivalently:

$$
f(S \cup T) \le f(S) + \sum_{e \in T \setminus S} f(e \mid S)
$$
{% endblock %}

This tells us that the individual contributions of $T \setminus S$ to $S$ are more than the contribution of all of $T \setminus S$. In this instance, "the sum of the parts" is greater than the whole.

To prove this, order the elements of $T \setminus S$ as $\set{e_1, e_2, \dots}$.

$$
\begin{align}
f(S \cup T) 
& =   f(S) + f(e_1 \mid S) + f(e_2 \mid S \cup {e_1}) + \dots \\
& \le f(S) + f(e_1 \mid S) + f(e_2 \mid S) + \dots \\
\end{align}
$$

The inequality follows from the submodularity of $f$. $\qed$

This allows us to prove the following theorem:

{% block theorem "Approximation guarantee of greedy maximization of a submodular function" %}
Let $S$ be the set produced by the greedy algorithm for maximizing a monotone submodular function $f$ subject to a cardinality constraint $k$. Let $O$ be any set of at most $k$ elements. Then:

$$
f(S) \ge \left(1 - \frac{1}{e}\right) f(O) \approx 0.632 f(O)
$$
{% endblock %}

If this is true for any set $O$, it is also true for the optimal solution; therefore, the theorem tells us that the greedy algorithm is a $(1 - 1/e)$ approximation algorithm.

Let us prove this. Since $f$ is monotone, we can assume $\abs{O} = k$; if we had $\abs{O} \le k$ we could always add elements to achieve $\abs{O} = k$, without decreasing $f(O)$. Our proof outline is the following:

1. Do some work to restate the element selection criterion in terms of the optimal solution
2. Set up a recurrence defining $f(S_i)$ in terms of $f(S_{i-1})$
3. Solve the recurrence to find a closed form of the bound

**Part 1**. Let $u_i$ be the $i$<sup>th</sup> element selected by the greedy algorithm. Let $S_i = \set{u_j : j \le i}$ be the set of the first $i$ elements selected. Note that $S_0 = \emptyset$ and $S_k = S$. Consider an iteration $i$ and let $e$ be any element in $O \setminus S_{i-1}$ (i.e. in the optimal solution, but that we haven't picked yet). Then, by our greedy choice criterion:

$$
f(u_i \mid S_{i-1}) \ge f(e \mid S_{i-1})
$$

In other words, the optimal solution increases our current choice $S_{i-1}$ less than the element $u_i$ that we are going to pick at iteration $i$.

We have one such inequality for each $e \in O \setminus S_{i-1}$. If we put all these inequalities together, i.e. we multiply by $\abs{O \setminus S_{i-1}}$, we get:

$$
\begin{align}
\abs{O \setminus S_{i-1}} \cdot f(u_i \mid S_{i-1})
& \overset{(1)}{\ge} \sum_{e \in O \setminus S_{i-1}} f(e \mid S_{i-1}) \\
& \overset{(2)}{\ge} f(S_{i-1} \cup O) - f(S_{i-1}) \\
& \overset{(3)}{\ge} f(O) - f(S_{i-1}) \\
\end{align}
$$

Step $(1)$ uses submodularity of $f$, step $(2)$ uses [the previous lemma on the sum of marginal contributions](#lemma:sum-of-marginal-contributions), and step $(3)$ uses monotonicity (since $O \subseteq (S_{i-1} \cup O)$ we have $f(O) \le f(S_{i-1}\cup O$). 

Now, note that $\abs{O \setminus S_{i-1}} \le k$ since we assumed $\abs{O} \le k$, and $f(u_i \mid S_{i-1})$ since $f$ is monotone. Therefore, as a small recap, we currently have the following inequality:

$$
k \cdot f(u_i \mid S_{i-1}) 
\ge \abs{O \setminus S_{i-1}} \cdot f(u_i \mid S_{i-1})
\ge f(O) - f(S_{i-1})
$$

Now, if we divide by $k$ in the above, and recall how we defined $S_i$ and $S_{i-1}$, we get:

$$
f(S_i) - f(S_{i-1}) 
= f(u_i \mid S_{i-1})
\ge \frac{1}{k} (f(O) - f(S_{i-1}))
$$

**Part 2**. Rearranging the terms, we get:

$$
f(S_i) 
\ge \left(1 - \frac{1}{k}\right) f(S_{i-1}) + \frac{1}{k} f(O)
$$

This gives a recurrence for $f(S_i)$, where it is defined in terms of $f(S_{i-1})$. By induction (a proof we will omit), we can show that:

$$
f(S_i) \ge \left( 1 - \left(1 - \frac{1}{k}\right)^i \right) f(O)
$$

**Part 3**. To complete the proof, it suffices to plug in $i = k$ and note that $(1 - \frac{1}{k})^k \le e^{-1}$ using the usual trick of $1 + x \le e^x$ because of the Taylor expansion of the exponential function. $\qed$

Note that this is the best possible bound. It is NP-hard to do better.

#### Unconstrained submodular maximization
Now, suppose that $f$ is not monotone. Then, the unconstrained maximization is relevant again, because we have no guarantee that the solution should be $N$. 

The greedy algorithm that stops when no element gives any positive marginal gain does not perform well. For instance, consider the following example, where the ground set is $N = \set{u_1, u_2, \dots, u_n, v}$, and the function is:

$$
f(S) = \begin{cases}
2 & \text{if } v \in S \\
\abs{S} & \text{if } v \notin S \\
\end{cases}
$$

Here, $f$ is indeed submodular, but the greedy algorithm would pick $v$ immediately, as it has marginal contribution 2 when $S = \emptyset$, whereas any other option only has marginal contribution 1. However, the optimal solution would be $\set{u_1, u_2, \dots, u_n}$, which would have value $n$.

Instead of the naive greedy approach, we'll see the double-greedy approach that allows us to get a $\frac{1}{3}$ approximation. This algorithm is "greedy from two sides", one side starting at $\emptyset$ and the other at $N$.

{% highlight python linenos %}
def double_greedy_submodular_maximization(N, f):
    """
    Input:  N   ground set
            f   submodular function 2^N -> R

    Output: S ⊆ N with f(S) >= 1/3 * f(Opt)
    """
    X[0] = set()
    Y[0] = N
    for i in range(1, n+1): # 1 to n, inclusive
        a[i] = f(X[i-1] + u[i]) - f(X[i-1]) # marginal contribution of adding u[i]
        b[i] = f(Y[i-1] - u[i]) - f(Y[i-1]) # marginal contribution of removing u[i]
        if a[i] >= b[i]:
            X[i] = X[i-1] + u[i]
        else:
            Y[i] = Y[i-1] - u[i]
    return X[n] # which is equal to Y[n]
{% endhighlight %}

Before we can prove that this algorithm is a $\frac{1}{3}$ approximation, we need some lemmas.

{% block lemma "Sum of marginal contributions in double greedy" %}
For every $1 \le i \le n$:

$$a_i + b_i \ge 0$$
{% endblock %}

This should be clear for a linear function $f$ (which is a special case of a submodular function), in which $a_i + b_i = 0$. We aim to prove this for the more general case of submodular functions.

First, note that for all $i$, $X_{i-1} \subseteq Y_{i-1}$ as they start at $\emptyset$ and $N$ respectively, and meet in the middle. Also, $u_i \in Y_{i-1}$, since at step $i$ we have to make the decision of whether to keep or remove $u_i$ from $Y_{i-1}$. Therefore:

$$
\begin{align}
(X_{i-1}\cup\set{u_i}) \cap (Y_{i-1}\setminus\set{u_i}) &= X_{i-1} \\
(X_{i-1}\cup\set{u_i}) \cup (Y_{i-1}\setminus\set{u_i}) &= Y_{i-1} \\
\end{align}
$$

By definition of $a_i$ and $b_i$, we have:

$$
\begin{align}
a_i + b_i
& = f(X_{i-1}\cup\set{u_i}) - f(X_{i-1}) 
  + f(Y_{i-1}\setminus\set{u_i}) - f(Y_{i-1}) \\
& = f(X_{i-1}\cup\set{u_i}) + f(Y_{i-1}\setminus\set{u_i}) 
  - \left(f(X_{i-1}) + f(Y_{i-1})\right) \\
& \ge 0
\end{align}
$$

The last step follows because we have something of the shape:

$$
f(A) + f(B) - (f(A \cup B) + f(A \cap B))
$$

Where $A = X_{i-1}\cup\set{u_i}$ and $B=Y_{i-1}\setminus\set{u_i}$. By the [classic definition of submodularity](#definition:classic-definition-of-submodularity), this is positive. $\qed$

Next, we'll need a smooth way of walking between our solution and the optimal one. We'll do this by introducing $\text{OPT}_i$, which we define as:

$$
\text{OPT}_i = (\text{OPT} \cup X_i) \cap Y_i
$$

In other words, $\text{OPT}_i$ is obtained by adding all elements in $X_i$ to the optimal solution, and then removing all elements in $Y_i$. This means that $\text{OPT}_i$ is a set that agrees with what the algorithm already has done in the first $i$ steps, and that contains the optimal choices in the following positions. For instance, if we let the previous decisions be denoted by a $*$, we have:

$$
\begin{align}
X_i & = (*, *, \dots, *, 0, 0, \dots, 0) \\
Y_i & = (*, *, \dots, *, 1, 1, \dots, 1) \\
\text{OPT}_i & = (*, *, \dots, *, o_{i+1}, o_{i+2}, \dots, o_n) \\
\end{align}
$$

Note that $\text{OPT}_0 = \text{OPT}$ and that $\text{OPT}_n = X_n = Y_n$.

{% block lemma "Decrease in $\text{OPT}_i$" %}
At each step $i$:

$$
\left[f(X_i) + f(Y_i)\right] - \left[f(X_{i-1}) + f(Y_{i-1})\right]
\ge f(\text{OPT}_{i-1}) - f(\text{OPT}_i)
$$
{% endblock %}

Intuitively, this tells us that each step $i$ brings about a decrease in the value of $\text{OPT}_i$, but this decrease is always matched by an increase in the value of either $X_i$ or $Y_i$.

If we rearrange the terms of this lemma, we get:

$$
\left[f(X_i) - f(X_{i-1})\right] + \left[f(Y_i) - f(Y_{i-1})\right]
\ge f(\text{OPT}_{i-1}) - f(\text{OPT}_i)
$$

We will just prove this lemma for the case $a_i \ge b_i$, but the other case is similar. In this case, the algorithm sets $X_i = X_{i-1} \cup \set{u_i}$ and $Y_i = Y_{i-1}$.

By [the lemma](#lemma:sum-of-marginal-contributions-in-double-greedy) on $a_i + b_i$, we have $a_i \ge 0$. This means that the above inequality is:

$$
f(u_i \mid X_{i-1}) = a_i \ge 0
$$

Let's now consider $\text{OPT}\_i$ Since $a\_i \ge b\_i$, we take $u\_i$, and thus have $\text{OPT}\_i = \text{OPT}\_{i-1}\cup\set{u\_i}$. There are two possible cases for this assignment:

- $u\_i \in \text{OPT}$, in which case $\text{OPT}\_i = \text{OPT}\_{i-1}$. The right-hand side of the lemma is empty and we are done.
- $u\_i \notin \text{OPT}$, in which case $\text{OPT}\_{i-1} \subseteq Y\_{i-1} \setminus \set{u\_i}$. By submodularity, we can replace $\text{OPT}\_{i-1}$ by any superset to obtain this for the right-hand side of the lemma:
  
  $$
  \begin{align}
  f(\text{OPT}_i) - f(\text{OPT}_i) 
  & = f(u_i \mid \text{OPT}_{i-1}) \\
  & =   f(u_i \mid \text{OPT}_{i-1}) \\
  & \ge f(u_i \mid Y_{i-1} \setminus \set{u_i}) \\
  & =   f(Y_{i-1}) - f(Y_{i-1} \setminus \set{u_i}) \\
  & = -b_i \ge -a_i \\
  \end{align}
  $$

  Multiplying by $-1$ on both sides, we get the following, as required:

  $$
  f(\text{OPT}_{i-1}) - f(\text{OPT}_i) \le a_i
  \qed
  $$

With these lemma in place, we can get to the approximation theorem for this algorithm.

{% block theorem "Double greedy approximation" %}
The above algorithm is a $\frac{1}{3}$ approximation for unconstrained submodular maximization.
{% endblock %}

If we sum the inequality of [the lemma on $\text{OPT}_i$](#lemma:decrease-in-text-opt-i) over $i \in [n]$:

$$
\sum_{i=1}^n \left[
    f(\text{OPT}_{i-1}) - f(\text{OPT}_i)
\right]
\le \sum_{i=1}^n \left[
    f(X_i) + f(Y_i) - f(X_{i-1})  f(Y_{i-1})
\right]
$$

Simplifying this telescoping sum, and using that $f$ is non-negative we get:

$$
f(\text{OPT}_0) - f(\text{OPT}_n)
\le f(X_n) + f(Y_n) - f(X_0) - f(Y_0)
\le f(X_n) + f(Y_n)
$$

Rearranging the terms, and using $\text{OPT}_0 = \text{OPT}$, $\text{OPT}_n = X_n = Y_n$, we get:

$$
f(\text{OPT}) \le 3 \cdot f(X_n)
\qed
$$

## Online algorithms
Online algorithms are slightly different from streaming algorithms. They are similar in that they receive elements one at a time, and do not know the future. But while a streaming algorithm computes some kind of metric over the stream with limited memory, the goal of an online algorithm is to output some decision about each element before receiving the next.

### Rental problems
We'll introduce online algorithms with a very Swiss example, called the "[ski rental problem](https://en.wikipedia.org/wiki/Ski_rental_problem)", or more generally the rent/buy problem. 

Suppose we go skiing every winter, and thus need skis. We can either buy a pair for a cost $B$ and use them forever, or rent them every winter and pay cost $R$ per year. If we knew how many times we would ski in our entire lives up-front, the calculation would be very easy. But the reality of it is that we don't know in advance. Instead, every winter we must make the choice of buying or renting. If we will ski less than $B/R$ times, then the optimal solution would be to always rent; if we ski more, we should buy from year 1.

An easy algorithm is to rent every winter until we have paid $B$ in rent, and then buy at that point. If we ski less than $B/R$ times, this is optimal. If we ski more, it's within a factor 2 of the optimal solution (which would have been to buy on day 1).

### Competitive ratio
Note that the factor 2 in the above example isn't an approximation ratio, but something we call a *competitive ratio*. A competitive ratio is the performance loss we get by going to online algorithm, while an approximation ratio is what we get by going from NP to P.

{% block definition "Competitive ratio" %}
If we have an online problem and some algorithm $\text{ALG}$ that, given an instance $I$ of the problem, gives the cost $\text{ALG}$ of the solution. Assume $\text{OPT}(I)$ is the best possible solution of instance $I$. Then:

$$\max_{I} \frac{\text{ALG}(I)}{\text{OPT}(I)}$$

is called the *competitive ratio* of the algorithm.
{% endblock %}

The competitive ratio is how far off our algorithm is from the optimal solution in the worst case. An alternative definition of competitive ratio allows for some warm-up cost:

{% block definition "Strong competitive ratio" %}
Assume the same setting as in the [definition of competitive ratio](#definition:competitive-ratio) above. We call $r$ the *competitive ratio* if:

$$\text{ALG}(I) \le r \cdot \text{OPT}(I) + c$$

for all $I$ and some constant $c$ independent of the length of the sequence $I$. If $c=0$, $r$ is the *strong competitive ratio*
{% endblock %}


### Caching
In computers, processors usually have a *cache* that sits in front of a *main memory*. When the processor needs to load information, it first goes to the cache. If the page is in cache, it's a *hit*; otherwise, it's a *miss*, and we go to main memory, and bring the page into the cache. If the cache is full at this point, one page must be evicted to be replaced. To decide which one to evict, a number of different *caching algorithms* exist; we'll go into the different options later.

Suppose the cache has a capacity of $k$ pages, and the main memory has $N$ pages. A sequence of of reads could look like this:

$$
\stream{4, 1, 2, 1, 5, 3, 4, 4, 1, 2, 3}
$$

With $k=3$ pages, we would fill up the cache with pages 4, 1, 2 on the first three reads. Then we'd read 1, which is a cache hit. Reading 5 would be a cache miss, so we'd read from main memory and bring it in. Which page do we evict at this point though? This is up to the caching algorithm to determine.

#### Deterministic caching
A few examples of deterministic caching algorithms are:

- **LRU (Least Recently Used)**: the page that has been in the cache the longest without being used is evicted
- **FIFO (First In First Out)**: the cache is like a queue, where we evict the page at the head, and enqueue new pages
- **LFU (Least Frequently Used)**: the page in the cache that has been used the least gets evicted
- **LIFO (Last In First Out)**: the cache is like a stack, where we push new pages, and pop to evict

{% block claim "Competitive ratio of LRU and FIFO" %}
LRU and FIFO have a competitive ratio of $k$ (where $k$ is the size of the cache).
{% endblock %}

We'll divide the request sequence $\sigma$ into phases as follows:

- Phase 1 begins at the first page of $\sigma$,
- Phase $i$ begins when we see the $k$<sup>th</sup> distinct page in phase $i-1$.

For instance, for $k=3$, the following stream would be divided as follows:

$$
\sigma = \stream{
    \underbrace{4, 1, 2, 1}_{\text{Phase } 1},
    \underbrace{5, 3, 4, 4}_{\text{Phase } 2},
    \underbrace{1, 2, 3}_{\text{Phase } 3}
}
$$

We will now show that $\text{OPT}(I)$ makes at least one cache miss each time a new phase begins. Let $p_j^i$ denote the $j$<sup>th</sup> *distinct* page in phase $i$. Consider pages $p_2^i$ to $p_k^i$ and page $p_1^{i+1}$ (i.e. pages 2 to $k$ in phase $i$, and the first page of phase $i+1$). These are $k$ distinct pages.

If none of the pages $p_2^i$ to $p_k^i$ have a cache miss, then $p_1^{i+1}$ must have one (because we've now seen more distinct pages than we can fit in our cache). Let $N$ be the number of phases. Then we have $\text{OPT}(I) \ge N - 1$ (the best we can do is no misses in pages 2 to $k$ of the phase, and then a miss in the first one). 

On the other hand, LRU and FIFO make at most $k$ misses per phase, so $\text{ALG}(I)$, and they are thus $k$-competitive. $\qed$

{% block claim "Competitive ratio of LFU and LIFO" %}
LFU and LIFO have *unbounded* competitive ratio. This means that the competitive ratio isn't bounded in terms of the parameters of the problem ($k$ and $N$), but rather by the size of input.
{% endblock %}

Having unbounded competitive ratios is *bad*. To prove this, we'll consider an input stream on which they perform particularly badly. Suppose we have a cache of size $k$, which originally contains pages $1$ through $k$. Suppose main memory has $N > k$ pages. 

Let's start with LIFO. Consider the request sequence alternating between pages $k$ and $k+1$:

$$\sigma = \stream{k+1, k, k+1, k, k+1, \dots}$$

Since $k$ is the last page that was put in the cache, it will be evicted to make space for $k+1$. Then, since $k+1$ was the last page placed in cache, it will be evicted to make space for $k$, and so on. We have a cache miss for each page in the request sequence, whereas an optimal strategy would only have one cache miss.

Now, let's consider LFU. Consider the same setup, but with the following request sequence, which has a "warm-up phase" that requests pages $1$ through $k-1$, $m$ times. Then it alternates between requesting $k$ and $k+1$, $m$ times each.

$$
\sigma = \stream{
    \underbrace{1, 2, \dots, k-1}_{m \text{times}},
    \underbrace{k, k+1, k, k+1, \dots}_{m \text{ times each}}
}
$$

In the warm-up phase, we have no cache misses because we assume the cache to already have values $1$ through $k$. Then, page $k$ is requested, which is a cache hit for the same reason. From there on out, LFU evicts $k$ to make space for $k+1$ and vice versa. This means $2m$ cache misses, while an optimal strategy would only have a single cache miss, for the first request for page $k+1$ (it would evict any other page than $k$). Making $m$ large allows us to get any competitive ratio we want. $\qed$

{% block lemma "Best competitive ratio for caching" %}
No deterministic online algorithm for caching can achieve a better competitive ratio than $k$, where $k$ is the size of the cache.
{% endblock %}

Let $\text{ALG}$ be a deterministic online caching algorithm. Suppose the cache has size $k$ and currently holds pages $1$ to $k$. Suppose $N > k$ is the number of pages in memory.

Since we know the replacement policy of $\text{ALG}$, we can construct an adversary that causes it to miss every element of the request sequence. This adversary doesn't need all $N$ pages to construct a "bad sequence" for the algorithm, but only $\set{1, 2, \dots, k, k+1}$. The requested element in this "bad sequence" is simply the one that isn't in the cache at that moment.

In comparison, when the optimal algorithm has a cache miss, it means that the evicted page won't be requested for the next $k$ rounds. This means that $\text{ALG}$ has a $k$-competitive ratio (every page compared to one in $k$). $\qed$

It may seem counter-intuitive that we consider that a policy that can miss every page is considered to be "the best possible strategy". But the important thing to understand here is that it's good because it's only $k$ times worse than the optimal solutions in the worst of cases, where even the optimal algorithm has some cache misses. The bad caching policies have a large number of misses even when the optimal algorithm has practically none.

#### Randomized caching
The following randomized caching strategy is known as the marking algorithm. Similarly to LRU, if a cache page is recently used, it's marked with a bit of value 1; otherwise, it's unmarked (bit with value 0).

- Initially all pages are unmarked
- Whenever a page is requested:
    + If the page is in the cache, mark it
    + Otherwise:
        * If there is an unmarked page in the cache, evict an unmarked page chosen uniformly at random, bring the requested page in, mark it.
        * Otherwise, unmark all pages and start a new phase.

Let's state the following about the competitive ratio of this strategy:

{% block lemma "Competitive ratio of the marking algorithm" %}
The above strategy achieves a competitive ratio of:

$$
2H_k = 2\left(\frac{1}{1} + \frac{1}{2} + \dots + \frac{1}{k} \right)
$$
{% endblock %}

The above algorithm is almost the best we can do:

{% block lemma "Best possible competitive ratio" %}
No randomized online algorithm has a competitive ratio better than $H_k$
{% endblock %}

### Secretary problem
The following problem is called the secretary problem:

- $n$ candidates arrive in random order
- When a candidate arrives, we must take an irrevocable decision on whether to hire the candidate. 

We'd like to hire the best candidate (we can assume they all have an objective and precise score). Exactly one candidate must be hired. If the algorithm we devise only returns negative decisions, we'll just pick the last candidate regardless of what the algorithm says (this is equivalent to specifying that the algorithm must give us at most one candidate).

#### Simple strategies
If we select the first candidate, regardless of their score, we get:

$$
\prob{\text{hiring best candidate}} = \frac{1}{n}
$$

Another strategy would be to interview but not hire the first $\frac{n}{2}$ candidates ("sampling phase"), and then pick whoever is better than the best candidate in the sampling phase ("hiring phase").

$$
\begin{align}
\prob{\text{hiring best candidate}}
& \ge \prob{\text{second best is in the first half} \land \text{best is in the second half}} \\
& \ge \prob{\text{second best is in the first half}}
\cdot \prob{\text{best is in the second half}} \\
& \ge \frac{1}{2} \cdot \frac{1}{2} \\
& = \frac{1}{4}
\end{align}
$$

Note that the second inequality holds despite the two events not quite being independent (if we know the second best is in the first half, that takes up a spot in the first half and it's slightly more likely that the best is in the second half). There are also other ways of fulfilling the event of hiring the best candidate (i.e. if the third best is in the first half, and the best is before the second best in the second half, etc), so the first inequality is not quite tight, but the above bound is good enough for us.

#### Optimal strategy
We can optimize the previous strategy by changing the point at which we switch from sampling phase to hiring phase. Instead of observing $n/2$, we can observe $r - 1$. Then:

$$
\begin{align}
& \prob{\text{hiring the best candidate}} \\
& = \sum_{i=1}^n \prob{\text{selecting } i \land i \text{ is the best}} \\
& = \sum_{i=1}^n \prob{\text{selecting } i\mid i\text{ is the best}}
    \cdot \prob{i \text{ is the best}} \\
& = \sum_{i=1}^{r-1} 0 
  + \frac{1}{n} \sum_{i=r}^n \prob{2^\text{nd} \text{ best of the first } i \text{ people is among the first } r - 1 \mid i \text{ is the best}} \\
& = \frac{1}{n} \sum_{i=r}^n \frac{r-1}{i-1} \\
& = \frac{r-1}{n}\sum_{i=r}^n \frac{1}{i-1} \\
\end{align}
$$

We want to maximize the above. For large enough $r$, this is at $r = \frac{n}{e}$, which gives us a probability of selecting the best candidate of at least $\frac{1}{e}$, which is optimal!

## Spectral Graph Theory
In spectral graph theory, we look at the eigenvectors and eigenvalues of the (normalized) adjacency matrix of a graph.

### Adjacency matrix
{% block definition "Adjacency matrix" %}
The adjacency matrix $A$ of a graph $G = (V, E)$ of $n = \abs{V}$ vertices is a $\mathbb{R}^{n\times n}$ matrix defined by:

$$
A_{ij} = \begin{cases}
1 & \text{if } \set{i, j} \in E \\
0 & \text{otherwise} \\
\end{cases}
$$

for every pair $i, j \in V$
{% endblock %}

For this course, we'll assume without loss of generality that all graphs are $d$-regular (all vertices have $d$ edges, degree $d$). This will greatly simplify notation.

{% block definition "Normalized adjacency matrix" %}
The normalized adjacency matrix $M$ of a $d$-regular graph is $\frac{1}{d}A$, where $A$ is the adjacency matrix.

$$
M_{ij} = \begin{cases}
\frac{1}{d} & \text{if } \set{i, j} \in E \\
0 & \text{otherwise} \\
\end{cases}
$$
{% endblock %}

This matrix $M$ is also called the *random walk matrix* of the graph. To see why, consider the following graph:

{% graphviz %}
graph G {
    bgcolor="transparent"
    A -- B -- C -- D -- A
}
{% endgraphviz %}

The normalized adjacency matrix will look like this:

$$
M = \begin{bmatrix}
0           & \frac{1}{2} & 0           & \frac{1}{2} \\
\frac{1}{2} & 0           & \frac{1}{2} & 0           \\
0           & \frac{1}{2} & 0           & \frac{1}{2} \\
\frac{1}{2} & 0           & \frac{1}{2} & 0           \\
\end{bmatrix}
$$

Consider that we currently stand at $A$. Our position can be summarized by the following position:

$$
p = \begin{bmatrix}
1 \\ 0 \\ 0 \\ 0 \\
\end{bmatrix}
$$

Notice now that $Mp$ is the probability distribution of our position after a single step:

$$
Mp = \begin{bmatrix}
0 \\ \frac{1}{2} \\ 0 \\ \frac{1}{2} \\
\end{bmatrix}
$$

More generally, $M^k p$ is the probability distribution after $k$ steps.

### Eigenvalues and eigenvectors
{% block definition "Eigenvalues and eigenvectors" %}
A vector $v$ is an eigenvector of a matrix $M$, with eigenvalue $\lambda$, if:

$$Mv = \lambda v$$
{% endblock %}

We'll state the following as a fact of linear algebra. We can use this because our normalized adjacency matrix $M$ is real and symmetric.

{% block lemma "Eigenvalues" %}
If $M \in \mathbb{R}^{n \times n}$ is symmetric, then:

1. $M$ has $n$ non-necessarily distinct real eigenvalues $\lambda_1 \ge \lambda_2 \ge \dots \ge \lambda_n$
2. If $v_1, v_2, \dots, v_{i-1}$ are eigenvectors for $\lambda_1, \lambda_2, \dots, \lambda_{i-1}$ then $\exists v_i : Mv_i = \lambda_i$. If there are multiple vectors satisfying the above, then any such vector $v_i$ can be selected to be the eigenvector corresponding to $\lambda_i$.
{% endblock %}

The second point in particular means that we can always find an orthonormal basis, corresponding to the eigenvectors.

### Relating eigenvalues to graph properties
Let's state the following observation without proof. This will be very important for the rest of this section.

{% block lemma "Observation on product with normalized adjacency matrix" %}
Consider a vector $x \in \mathbb{R}^n$, which assigns a value $x(i)$ to each vertex $i \in V$. Let $y = Mx$, where $M$ is the normalized adjacency matrix of a graph $G=(V, E)$. Then:

$$y(i) = \sum_{\set{i, j}\in E} \frac{x(j)}{d}$$
{% endblock %}

That is, the value that $y$ assigns to a vertex $i$ is the average of the value assigned to the neighbors. Using this observation, we can prove the following properties:

{% block lemma "Eigenvalues and graph properties" %}
Let $M$ be the normalized adjacency matrix of a $d$-regular graph $G$ and let $\lambda_1 \ge \lambda_2 \ge \dots \ge \lambda_n$ be its eigenvalues. Then:

1. $\lambda_1 = 1$
2. $\lambda_2 = 1 \iff G$ is disconnected
3. $\lambda_n = -1 \iff$ one component of $G$ is bipartite
{% endblock %}

Let's prove these properties.

#### Proof of 1
We'll prove this in two steps: $\lambda_1 \ge 1$ and $\lambda_1 \le 1$.

Since $M\vec{1} = 1\times\vec{1}$, $1$ is an eigenvalue, and since $\lambda_1$ is the greatest eigenvalue, $\lambda_1 \ge 1$

Additionally, we consider any eigenvector $x$ and vertex $i \in V$ such that $x(i)$ is maximized. We let $y = Mx$. Then, by [our observation](#lemma:observation-on-product-with-normalized-adjacency-matrix)

$$
\begin{align}
y(i) 
& =   \sum_{\set{i, j} \in E} \frac{x(j)}{d} \\
& \le \sum_{\set{i, j} \in E} \frac{x(i)}{d} \\
& = x(i)
\end{align}
$$

The inequality follows from the fact that $x(i)$ is the maximal value in the vector $x$. From this inequality $y(i) \le x(i)$, we conclude that $\lambda_1 \le 1$ (as $y = Mx = \lambda x$ since we considered $x$ to be an eigenvector). $\qed$

This proof not only tells us that $\lambda_1 = 1$, but also that we can select $v_1 = \vec{1}$, which we will do from now on[^eigenvector-normalization].

[^eigenvector-normalization]: Eigenvectors cannot be the zero vector. Any scalar multiple of an eigenvector is also considered an eigenvector, so we can normalize eigenvectors without loss of generality. For instance, we can consider $v_1 = \vec{1}$ or $v_1 = \vec{1}/\sqrt{n}$ if we need to.

#### Proof of 2
We will show that there is a vector $v_2 \perp v_1$ such that $Mv_2 = v_2$ iff $G$ is disconnected.

Let's start with the $\Leftarrow$ direction. Suppose $G$ is disconnected. This means that there is a subset $S \subset V$ of vertices that are not connect to vertices in $V \setminus S$. Let $v_2$ be defined by:

$$
v_2(i) = \begin{cases}
\frac{1}{\abs{S}} & \text{if } i \in S \\
-\frac{1}{\abs{V\setminus S}} & \text{if } i \in V\setminus S \\
\end{cases}
$$

Notice that $v_2 \perp v_1$, where $v_1 = \vec{1}$. We now show $Mv_2 = v_2$. To do so, we fix an $i \in V$, and let $y = Mv_2$:

$$
y(i) = \frac{1}{d}\sum_{\set{i, j} \in E} v_2(j)
     = \frac{1}{d}\sum_{\set{i, j} \in E} v_2(i)
     = v_2(i)
$$

The first step uses [the observation we previously noted](#lemma:observation-on-product-with-normalized-adjacency-matrix). The second uses the fact that every neighbor $j$ of $i$ has $v_2(j) = v_2(i)$, by the definition we gave of $v_2$ (wherein vertices only have different values when they are not neighbors).

This shows that $\lambda_2 = 1$ if $G$ is disconnected.

Now, let's prove the $\Rightarrow$ direction. We'll prove the contrapositive, so suppose that $G$ is connected. Let $v_2$ be an eigenvector corresponding to the second eigenvalue $\lambda_2$. We have $v_2 \perp v_1$. We must now show $\lambda_2 < 1$.

Since $v_2 \perp v_1$ where $v_1 = \vec{1}$, $v_2$ cannot assign the same value to all vertices. Therefore, as $G$ is connected, there must be a vertex $i$ that has at least one neighbor $j$ for which $v_2(i) \ne v_2(j)$. Select such a vertex that maximizes $v_2(i)$. By selection of $i$ we have:

$$v_2(i) \ge v_2(j), \quad \forall\set{i, j}\in E$$

Since $v_2$ doesn't have the same value for all vertices, for at least one neighbor $j^\*$ of $j$, we have $v_2(i) > v_2(j^\*)$. Again, we let $y = Mv_2$. It follows that

$$
\begin{align}
y(i)
= \frac{1}{d}\sum_{\set{i, j} \in E} v_2(j)
\le \frac{1}{d}\left(\sum_{\set{i, j} \in E : j \ne j^*}
    v_2(i) + v_2(j^*)
\right)
\le v_2(i)
\end{align}
$$

It follows that $\lambda_2 < 1$. Since we were proving the contrapositive, this successfully proves the $\Rightarrow$ direction. $\qed$

#### Proof of 3
First, let us prove the $\Leftarrow$ direction, namely that $G$ bipartite $\implies \lambda_n = -1$. For that, it suffices to find a vector $x$ such that $Mx = -x$. Suppose $G = (A\cup B, E)$ is a bipartite graph. Let $x$ be defined as follows:

$$
x_i = \begin{cases}
-1 & \text{if } i \in A \\
1  & \text{if } i \in B \\
\end{cases}
$$

Recall [our observation](#lemma:observation-on-product-with-normalized-adjacency-matrix) of $y(i) = \frac{1}{d} \sum_{(i, j) \in E} x(j)$. It says that $y(i)$ is the average of the neighboring $x(j)$. Now, vertices in $A$ only have neighbors in $B$, and vertices in $B$ only have neighbors in $A$. Therefore, by multiplying by this vector $x$, vertices in $A$ get value $-1$, and vertices in $B$ get $1$. In other words:

$$
Mx = -x
$$

Now, let us prove the $\Rightarrow$ direction, namely that $\lambda_n = -1 \implies G$ has a disconnected component.

Let $x = v_n$ be the eigenvector associated to $\lambda_n$. We therefore have $Mx = -x$. Let $i \in V$ be the vertex maximizing $\abs{x(i)}$. Let $D = x_i$ be the signed value behind the maximal absolute value. Since $(Mx)_i = -x_i$, by [our observation](#lemma:observation-on-product-with-normalized-adjacency-matrix), it means that the neighbors of $i$ must all have value $-D$. The same goes for the neighbors of $i$, whose neighbors must have value $D$, and so on.

This means that we can split the graph into a vertex set $A$ of nodes with value $D$, and a set $B$ of nodes with values $-D$. All nodes $A$ only have neighbors in $B$ and vice versa. Therefore, $G$ is bipartite, with $V = A \cup B$. $\qed$

### Mixing time of random walks
As we said earlier, we can use the normalized adjacency matrix $M$ to get the probability distribution after taking a single step by computing $Mp$. If we want the probability distribution after $k$ steps, we compute $M^k p$.

Intuitively, *mixing time* is about how many steps one must take to have a uniform probability of being at any given node $v$. More formally, the question is which $k$ should be picked to have $M^k p$ close to a uniform distribution.

The mixing time is highly dependent on graph structure. Some observations:

- If the graph is not connected ($\lambda_2 = 1$) then we will only reach vertices in the same component as the starting node $s$ and will never come close to the uniform distribution, no matter the choice of $k$.
- If the graph is bipartite ($\lambda_n = -1$) then the random walk will alternate between left and right, and will never converge to a uniform distribution (the side we are currently on will only have 0 components in $M^k p$).

To fix the second point, we can do a "lazy random walk" in which we have a probability $\frac{1}{2}$ of staying where we are at each step.

In any case, the above observations tell us that the mixing time has to do with the values $\lambda_2$ and $\lambda_n$. The following lemma tells us that the quantity $\max(\abs{\lambda_2}, \abs{\lambda_n})$ is important to mixing time:

{% block lemma "Mixing time" %}
Let $G = (V, E)$ be a $d$-regular graph and let $1 = \lambda_1 \ge \lambda_2 \ge \dots \ge \lambda_n \ge -1$ be the eigenvalues of the normalized adjacency matrix $M$ of $G$.

If $\max(\abs{\lambda_2}, \abs{\lambda_n}) \le 1-\epsilon$ then no matter from which vertex $s$ we start, we will be at any vertex with probability $\approx\frac{1}{n}$ after $k=\bigO{\frac{1}{\epsilon}\log n}$ steps.

More precisely, if $p$ is the vector of our starting position (a one-hot vector taking value 1 only on the vertex $s$ on which we started), then:

$$
\norm{M^k p - \left(\frac{1}{n}, \dots, \frac{1}{n}\right)}_2^2
\le \smallO{\frac{1}{n^2}}
$$

when $k = \frac{c}{\epsilon}\log n$ for some constant $c$.
{% endblock %}

This lemma tells us that after $k = \frac{c}{\epsilon}\log n$ steps, we'll be within a distance $\frac{1}{n^2}$ from a truly uniform distribution. The parameter $\epsilon$ is controlled by $\lambda_2$ and $\lambda_n$, so the number of steps to do will depend on the graph structure, as anticipated.

To prove this, let $p = (1, 0, 0, 0, \dots)$, i.e. we assume (w.l.o.g) that the vertices are ordered and our start vertex $s$ is first. 

Let $(v_1, v_2, \dots, v_n)$ be the eigenvectors corresponding to the eigenvalues $(\lambda_1, \lambda_2, \dots, \lambda_n)$. These form an orthonormal basis, meaning that we can write $p$ in terms of this basis:

$$
p = \sum_{i=1}^n \alpha_i v_i
$$

where $\alpha_i = \inner{p, v_i}$.

Let's use this to determine how long it takes for the random walk to be mixed; to get a quantitative measure of this, we measure the distance to a uniform distribution. We could use any norm, but we chose the 2<sup>nd</sup> one here.

Seeing that $\lambda_1 = 1$, we have in particular that $\alpha_1 = \inner{p, v_1} = \frac{1}{\sqrt{n}}$. Our goal of $\left(\frac{1}{n}, \dots, \frac{1}{n}\right)$ can be written $\alpha_1 v_1$, where $v_1 = \vec{1}/\sqrt{n}$ is the normalized first eigenvector. In practice, this means that we can also write our goal in the eigenvector basis, and thus subtract it from the sum resulting from $M^k p$. This will be step $(1)$ below.

$$
\begin{align}
\norm{M^k p - \left(\frac{1}{n}, \dots, \frac{1}{n}\right)}_2^2
& \overset{(1)}{=} \norm{\sum_{i=2}^n \alpha_i \lambda_i^k v_i}_2^2 \\
& \overset{(2)}{=}
    \sum_{i=2}^n \abs{\lambda_i}^k \norm{\alpha_i v_i}_2^2 \\
& \overset{(3)}{\le}
    1-\epsilon)^k \sum_{i=2}^n \norm{\alpha_i v_i}_2^2 \\
& \overset{(4)}{=}
    (1-\epsilon)^k \norm{\sum_{i=2}^n \alpha_i v_i}_2^2 \\
\end{align}
$$

Step $(2)$ stems from the fact that the eigenvectors $v_1, \dots, v_n$ are orthogonal. Step $(3)$ comes from our assumption in the lemma that $\max(\abs{\lambda_2}, \abs{\lambda_n}) \le 1-\epsilon$, which means that $\abs{\lambda_i} \le 1-\epsilon$ for all $i\ge 2$. Finally, step $(4)$ follows from the orthogonality of the eigenvectors.

If we take $k = \frac{c}{\epsilon}\log n$ and let $A = \norm{\sum_{i=2}^n \alpha_i v_i}_2^2 \le 1$, we have:

$$
\norm{M^k p - \left(\frac{1}{n}, \dots, \frac{1}{n}\right)}_2^2
\le A(1-\epsilon)^{\frac{\log n}{\epsilon} c}
\le A\left(\frac{1}{e}\right)^{c \log n}
\le \frac{1}{n^c}
$$

With $c > 2$, we get the result we wanted. $\qed$

### Conductance
{% block definition "Conductance" %}
Let $G = (V, E)$ be a $d$-regular graph with $n = \abs{V}$ vertices. We define the conductance $h(S)$ of a cut $S \subseteq V$:

$$h(S) = \frac{\abs{\delta(S)}}{d\cdot\min\set{\abs{S}, \abs{S\setminus V}}}$$

where $\delta(S)$ denotes the set of edges crossing the cut. We also define the conductance of the graph $G$:

$$h(G) = \min_{S\subset V : S \ne \emptyset} h(S)$$
{% endblock %}

In other words, the conductance of a cut is the number of edges crossing the cut, divided by the number of edges that *could* cross the cut (if the smaller component's vertices all used their $d$ edges to cross the cut, and not internally).

The conductance of the graph is that of the cut with the smallest conductance.

### Cheeger's inequalities
Note that a disconnected graph has conductance 0, and that a fully connected graph has conductance 1. Indeed, the conductance is closely related to $\lambda_2$. Cheeger's inequalities give us a quantified version of the fact that $\lambda_2 = 1 \iff G$ is disconnected:

{% block theorem "Cheeger's inequalities" %}
$$\frac{1 - \lambda_2}{2} \le h(G) \le \sqrt{2(1 - \lambda_2)}$$
{% endblock %}

We'll only prove the lower bound. The lecture notes contain a very long and tedious proof of the upper bound. For the lower bound, it'll be useful to introduce an alternative way to define eigenvalues of $M$, namely as an optimization problem on the Rayleigh coefficient $\frac{x^T M x}{x^Tx}$.

{% block lemma "$\lambda_1$ in Rayleigh form" %}
$$\lambda_1 = \max_{x\in\mathbb{R}^n : x \ne 0} \frac{x^T M x}{x^Tx}$$
{% endblock %}

We'll prove this by upper-bounding and lower-bounding $\lambda_1$. Let's start with $\lambda_1 \le \max_{x\in\mathbb{R}^n : x \ne 0} \frac{x^T M x}{x^Tx}$:

$$
\frac{v_1^T M v_1}{v_1^Tv_1}
= \frac{v_1^T \lambda_1 v_1}{v_1^Tv_1}
= \lambda_1 \frac{v_1^T v_1}{v_1^Tv_1}
= \lambda_1
$$

This proves the upper bound, because if $\lambda_1$ is equal to some value of the maximization problem, it's less than the maximal one.

For the lower bound $\lambda_1 \ge \max_{x\in\mathbb{R}^n : x \ne 0} \frac{x^T M x}{x^Tx}$, we let $y$ be the vector that attains the maximal value. Since $(v_1, \dots, v_n)$ is a basis, we can write $y$ in that basis using factors $(\alpha_1, \dots, \alpha_n)$:

$$
y = \sum_{i=1}^n \alpha_i v_i
$$

Then:

$$
\frac{y^T M y}{y^T y} 
= \frac{\sum_{i=1}^n \alpha_i^2 \lambda_i}{\sum_{i=1}^n \alpha_i^2}
\le \lambda_1 \frac{\sum_{i=1}^n \alpha_i^2}{\sum_{i=1}^n \alpha_i^2}
= \lambda_1
$$

The inequality follows from the "tallest person in the class" argument which we've used previously. $\qed$

{% block lemma "$\lambda_2$ in Rayleigh form" %}
Let $v_1$ be the eigenvector corresponding to $\lambda_1$. Then:

$$
\lambda_2 
= \max_{x\in\mathbb{R}^n : x \perp v_1} \frac{x^T M x}{x^T x}
$$
{% endblock %}

The proof is very similar to that of the previous lemma. We will first upper-bound $\lambda_2$. Let $v_2$ be the eigenvector associated to $\lambda_2$. We have $v_2 \perp v_1$, so:

$$
\max_{x\in\mathbb{R}^n : x \perp v_1} \frac{x^T M x}{x^T x}
\ge \frac{v_1^T M v_1}{v_1^T v_1}
= \lambda_2
$$

Once again, this is because the maximum is greater than any value in the maximization problem.

The lower bound of $\lambda_2$ is a little harder. Let's look at the search space $\mathcal{S}$ of this maximization problem:

$$
\mathcal{S} = \set{x \in \mathbb{R}^n : x \perp v_1}
$$

Let $y \in \mathcal{S}$ be the vector that attains the maximum objective value $\frac{y^T M y}{y^T y}$ in this search space. $\mathcal{S}$ has dimension $n-1$ (seeing that a degree of freedom is removed by the constraint of orthogonality to $v_1$), so we can find a basis $(v_2, \dots, v_n)$ for $\mathcal{S}$; these are the eigenvectors corresponding to the eigenvalues $(\lambda_2, \dots, \lambda_n)$. With that basis, we can describe vectors in $\mathcal{S}$ by using factors $(\alpha_2, \dots, \alpha_n)$:

$$
y = \sum_{i=2}^n \alpha_i v_i
$$

With this in mind, we now have:

$$
\max_{x\in\mathcal{S}} \frac{x^T M x}{x^T x}
= \frac{y^T M y}{y^T y}
= \frac{y^T \sum_{i=2}^n \alpha_i M v_i}{y^T y}
= \frac{y^T \sum_{i=2}^n \alpha_i \lambda_i v_i}{y^T y}
\le \frac{y^T \lambda_2 v_i}{y^T y}
= \lambda_2
$$

The inequality step can be done because a single term in a sum is smaller than the whole sum itself. $\qed$

With this proven, we can go on to prove the lower bound of Cheeger's inequality. Because $\lambda_1 = 1$, we consider that the associated eigenvector is $v_1 = \vec{1}$. By the [above lemma](#lemma:lambda-2-in-rayleigh-form) on $\lambda_2$, we have:

$$
\begin{align}
1 - \lambda_2
& = 1 - \max_{x \in \mathbb{R}^n : x \perp v_1} \frac{x^T M x}{x^T x} \\
& = \min_{x \in \mathbb{R}^n : x \perp v_1} \left(1 - \frac{x^T M x}{x^T x}\right) \\
& = \min_{x \in \mathbb{R}^n : x \perp v_1} \frac{x^T (I-M) x}{x^T x} \\
\end{align}
$$

The matrix $L := I - M$ is the *normalized Laplacian matrix*. This is another matrix that is nice to study in spectral graph theory. With this matrix, we have the following identity:

$$
x^T L x
= \frac{1}{d} \sum_{(i, j) \in E} (x(i) - x(j))^2
$$

Using this in the previous equality, we get:

$$
1 - \lambda_2
= \min_{x \in \mathbb{R}^n : x \perp v_1}
    \frac{\sum_{(i, j) \in E} (x(i) - x(j))^2}{d\cdot x^T x}
$$


{% block note %}
What happens if we let $x$ be a vector taking value 1 for vertices in $S$, and 0 everywhere else? 

**Numerator**. To determine the value of the numerator, let's look at the tree possible cases in the sum:

- Edges $(i, j)$ where $i, j\in S$ have $x(i) - x(j) = 1 - 1 = 0$
- Edges $(i, j)$ where $i, j\notin S$ have $x(i) - x(j) = 0 - 0 = 0$
- Edges $(i, j)$ where $i \in S$ and $j \notin S$ (or vice versa) have $(x(i) - x(j))^2 = (\pm 1)^2 = 1$

So in total, only edges crossing the cut count towards the total, and the numerator thus sums up to $\abs{E(S, \bar{S})}$. 

**Denominator**. For the denominator, $x^T x = \sum_{i\in V} x(i)^2$. Again, since the values are all 0 or 1, this sums up to $\abs{S}$. 

**Result**. In summary, we get:

$$
1 - \lambda_2 = \frac{\abs{E(S, \bar{S})}}{d\cdot\abs{S}}
$$

Notice that this is the formulation of conductance. This is obviously a special case of the previous more general formulation, which we can consider as a continuous relaxation of the cut problem. That is indeed the intuition behind Cheeger's inequalities. Let's therefore generalize this result for the continuous case.
{% endblock %}

We consider (w.l.o.g.) that $\abs{S} \le \abs{V}/2$ (otherwise we could swap the set we consider to be called $S$, i.e. consider $V\setminus S$). We define $y \in \mathbb{R}^n$ as follows:

$$
y(i) = \begin{cases}
1 - \frac{\abs{S}}{\abs{V}} & \text{if } i \in S \\
-\frac{\abs{S}}{\abs{V}}    & \text{if } i \notin S \\
\end{cases}
$$

We define it this way to make sure that $y \perp v_1$ (recall that $v_1 = \vec{1}$). Hence:

$$
1 - \lambda_2
= \min_{x \in \mathbb{R}^n : x \perp v_1}
    \frac{\sum_{(i, j) \in E} (x(i) - x(j))^2}{d\cdot x^T x}
\le \frac{\sum_{(i, j) \in E} (y(i) - y(j))^2}{d\cdot y^T y}
$$

Indeed, if $1 - \lambda_2$ is equal to the minimal value, it's less than any value that is part of the minimization problem. Let's now analyze what this fraction is.

**Numerator**. With our selection of $y$, the numerator is actually equal to $\abs{\delta(S)}$:

$$
\sum_{(i, j) \in E} (y(i) - y(j))^2
= \sum_{(i, j) \in E} \left(1 - \frac{\abs{S}}{\abs{V}} + \frac{\abs{S}}{\abs{V}} \right)^2
= \abs{\delta(S)}
$$

This is because, as before, all edges not in the cut cancel out. Only edges in the cut contribute by 1, so the final result of the sum is the number of edges in the cut.

**Denominator**. For the denominator, we have:

$$
\begin{align}
y^T y 
& = \sum_{i \in V} = y(i)^2 \\
& = \abs{S} \left( 1 - \frac{\abs{S}}{\abs{V}} \right)^2 + (\abs{V} - \abs{S}) \cdot \left(\frac{\abs{S}}{\abs{V}} \right)^2 \\
& = \frac{\abs{S}\cdot\abs{V \setminus S}}{\abs{V}} \\
& \ge \frac{S}{2} \\
\end{align}
$$

The last inequality holds because $\abs{V\setminus S} \ge \frac{\abs{V}}{2}$ holds by assumption.

**Result**. Combining the two results above, we get:

$$
\frac{1-\lambda_2}{2} 
\le \frac{1}{2} \frac{\sum_{(i, j) \in E} (y(i) - y(j))^2}{d\cdot y^T y}
\le \frac{1}{2} \frac{\abs{\delta(S)}}{d\cdot\frac{S}{2}}
= \frac{\abs{\delta(S)}}{d\cdot \abs{S}} = h(S)
$$

It follows that the conductance of every cut is at least $\frac{1-\lambda_2}{2}$, so $\frac{1-\lambda_2}{2} \le h(G)$ as required. $\qed$


### Spectral partitioning algorithm
The spectral partitioning algorithm outputs a cut that cuts relatively few edges, with a small conductance.

{% highlight python linenos %}
def spectral_partitioning(G, v2):
    """
    Input   G   graph G = (V, E)
            v2  second eigenvector of the normalized adjacency matrix

    Output  S   cut with low conductance
    """
    # Sort vertices in non-decreasing order of values in v2:
    vertices = sorted(V, key = lambda v: v2[v], reverse = True)
    
    # Find prefix cut of smallest conductance:
    minimum = 1
    best_cut = []
    for i in range(len(vertices)):
        cut = vertices[:i]
        if h(cut) < minimum:
            minimum = h(cut)
            best_cut = cut
    return best_cut
{% endhighlight %}

Assuming that we are given eigenvalues and eigenvectors, sorting is the bottleneck here; everything else is in linear time. This algorithm is therefore $\bigO{\abs{V} \log(\abs{V}) + \abs{E}}$.

Note that the upper bound of Cheeger tells us that the returned set satisfies $h(S) \le \sqrt{2(1 - \lambda_2)}$.