---
title: CS-452 Foundations of Software
description: "My notes from the CS-452 Foundations of Software course given at EPFL, in the 2018 autumn semester (MA1)"
date: 2018-09-18
course: CS-452
---

<!-- More -->

* TOC
{:toc}

## Writing a parser with parser combinators
In Scala, you can (ab)use the operator overload to create an embedded DSL (EDSL) for grammars. While a grammar may look as follows in a grammar description language (Bison, Yak, ANTLR, ...):

{% highlight antlr linenos %}
Expr ::= Term {'+' Term | '−' Term}
Term ::= Factor {'∗' Factor | '/' Factor}
Factor ::= Number | '(' Expr ')'
{% endhighlight %}

In Scala, we can model it as follows:

{% highlight scala linenos %}
def expr: Parser[Any] = term ~ rep("+" ~ term | "−" ~ term)
def term: Parser[Any] = factor ~ rep("∗" ~ factor | "/" ~ factor)
def factor: Parser[Any] = "(" ~ expr ~ ")" | numericLit
{% endhighlight %}

This is perhaps a little less elegant, but allows us to encode it directly into our language, which is often useful for interop.

The `~`, `|`, `rep` and `opt` are **parser combinators**. These are primitives with which we can construct a full parser for the grammar of our choice.

### Boilerplate

First, let's define a class `ParseResult[T]` as an ad-hoc monad; parsing can either succeed or fail:

{% highlight scala linenos %}
sealed trait ParseResult[T]
case class Success[T](result: T, in: Input) extends ParseResult[T]
case class Failure(msg : String, in: Input) extends ParseResult[Nothing]
{% endhighlight %}

> 👉 `Nothing` is the bottom type in Scala; it contains no members, and nothing can extend it

Let's also define the tokens produced by the lexer (which we won't define) as case classes extending `Token`:

{% highlight scala linenos %}
sealed trait Token
case class Keyword(chars: String) extends Token
case class NumericLit(chars: String) extends Token
case class StringLit(chars: String) extends Token
case class Identifier(chars: String) extends Token
{% endhighlight %}

Input into the parser is then a lazy stream of tokens (with positions for error diagnostics, which we'll omit here):

{% highlight scala linenos %}
type Input = Reader[Token]
{% endhighlight %}

We can then define a standard, sample parser which looks as follows on the type-level:

{% highlight scala linenos %}
class StandardTokenParsers {
    type Parser = Input => ParseResult
}
{% endhighlight %}

### The basic idea
For each language (defined by a grammar symbol `S`), define a function `f` that, given an input stream `i` (with tail `i'`):

- if a prefix of `i` is in `S`, return `Success(Pair(x, i'))`, where `x` is a result for `S`
- otherwise, return `Failure(msg, i)`, where `msg` is an error message string

The first is called *success*, the second is *failure*. We can compose operations on this somewhat conveniently, like we would on a monad (like `Option`).

### Simple parser primitives
All of the above boilerplate allows us to define a parser, which succeeds if the first token in the input satisfies some given predicate `pred`. When it succeeds, it reads the token string, and splits the input there.

{% highlight scala linenos %}
def token(kind: String)(pred: Token => boolean) = new Parser[String] {
    def apply(in : Input) =
        if (pred(in.head)) Success(in.head.chars, in.tail)
        else Failure(kind + " expected ", in)
}
{% endhighlight %}

We can use this to define a keyword parser:

{% highlight scala linenos %}
implicit def keyword(chars: String) = token("'" + chars + "'") {
    case Keyword(chars1) => chars == chars1
    case _ => false
}
{% endhighlight %}

Marking it as `implicit` allows us to write keywords as normal strings, where we can omit the `keyword` call (this helps us simplify the notation in our DSL; we can write `"if"` instead of `keyword("if")`).

We can make other parsers for our other case classes quite simply:

{% highlight scala linenos %}
def numericLit = token("number")(_.isInstanceOf[NumericLit])
def stringLit = token("string literal")(_.isInstanceOf[StringLit])
def ident = token("identifier")(_.isInstanceOf[Identifier])
{% endhighlight %}

### Parser combinators
We are going to define the following parser combinators:

- `~`: sequential composition
- `<~`, `>~`: sequential composition, keeping left / right only
- `|`: alternative
- `opt(X)`: option (like a `?` quantifier in a regex)
- `rep(X)`: repetition (like a `*` quantifier in a regex)
- `repsep(P, Q)`: interleaved repetition
- `^^`: result conversion (like a `map` on an `Option`)
- `^^^`: constant result (like a `map` on an `Option`, but returning a constant value regardless of result)

But first, we'll write some very basic parser combinators: `success` and `failure`, that respectively always succeed and always fail:

{% highlight scala linenos %}
def success[T](result: T) = new Parser[T] {
    def apply(in: Input) = Success(result, in)
}

def failure(msg: String) = new Parser[Nothing] {
    def apply(in: Input) = Failure(msg, in)
}
{% endhighlight %}

All of the above are methods on a `Parser[T]` class. Thanks to infix space notation in Scala, we can denote `x.y(z)` as `x y z`, which allows us to simplify our DSL notation; for instance `A ~ B` corresponds to `A.~(B)`.

{% highlight scala linenos %}
abstract class Parser[T] {
    // An abstract method that defines the parser function
    def apply(in : Input): ParseResult

    def ~[U](rhs: Parser[U]) = new Parser[T ~ U] {
        def apply(in: Input) = Parser.this(in) match {
            case Success(x, tail) => rhs(tail) match {
                case Success(y, rest) => Success(new ~(x, y), rest)
                case failure => failure
            }
            case failure => failure
        }
    }

    def |(rhs: => Parser[T]) = new Parser[T] {
        def apply(in : Input) = Parser.this(in) match {
            case s1 @ Success(_, _) => s1
            case failure => rhs(in)
        }
    }

    def ^^[U](f: T => U) = new Parser[U] {
        def apply(in : Input) = Parser.this(in) match {
            case Success(x, tail) => Success(f(x), tail)
            case x => x
        }
    }

    def ^^^[U](r: U): Parser[U] = ^^(x => r)
}
{% endhighlight %}

> 👉 In Scala, `T ~ U` is syntactic sugar for `~[T, U]`, which is the type of the case class we'll define below

For the `~` combinator, when everything works, we're using `~`, a case class that is equivalent to `Pair`, but prints the way we want to and allows for the concise type-level notation above.

{% highlight scala linenos %}
case class ~[T, U](_1 : T, _2 : U) {
    override def toString = "(" + _1 + " ~ " + _2 +")"
}
{% endhighlight %}

At this point, we thus have **two** different meanings for `~`: a *function* `~` that produces a `Parser`, and the `~(a, b)` *case class* pair that this parser returns (all of this is encoded in the function signature of the `~` function).

Note that the `|` combinator takes the right-hand side parser as a call-by-name argument. This is because we don't want to evaluate it unless it is strictly needed—that is, if the left-hand side fails.

`^^` is like a `map` operation on `Option`; `P ^^ f` succeeds iff `P` succeeds, in which case it applies the transformation `f` on the result of P. Otherwise, it fails.

### Shorthands

We can now define shorthands for common combinations of parser combinators:

{% highlight scala linenos %}
def opt[T](p : Parser[T]): Parser[Option[T]] = p ^^ Some | success(None)

def rep[T](p : Parser[T]): Parser[List[T]] = 
    p ~ rep(p) ^^ { case x ~ xs => x :: xs } | success(Nil)

def repsep[T, U](p : Parser[T], q : Parser[U]): Parser[List[T]] = 
    p ~ rep(q ~> p) ^^ { case r ~ rs => r :: rs } | success(Nil)
{% endhighlight %}

Note that none of the above can fail. They may, however, return `None` or `Nil` wrapped in `success`.


As an exercise, we can implement the `rep1(P)` parser combinator, which corresponds to the `+` regex quantifier:

{% highlight scala linenos %}
def rep1[T](p: Parser[T]) = p ~ rep(p)
{% endhighlight %}

### Example: JSON parser
Let's define a JSON parser. Scala's parser combinator library has a `StandardTokenParsers` that give us a variety of utility methods for lexing, like `lexical.delimiters`, `lexical.reserved`, `stringLit` and `numericLit`.

{% highlight scala linenos %}
object JSON extends StandardTokenParsers {
    lexical.delimiters += ("{", "}", "[", "]", ":")
    lexical.reserved += ("null", "true", "false")

    // Return Map
    def obj: Parser[Any] = "{" ~ repsep(member, ",") ~ "}" ^^ (ms => Map() ++ ms)

    // Return List
    def arr: Parser[Any] = "[" ~> repsep(value, ",") <~ "]"

    // Return name/value pair:
    def member: Parser[Any] = stringLit ~ ":" ~ value ^^ {
        case name ~ ":" ~ value => (name, value) 
    }

    // Return correct Scala type
    def value: Parser[Any] =
          obj 
        | arr 
        | stringLit
        | numericLit ^^ (_.toInt)
        | "null" ^^^ null
        | "true" ^^^ true
        | "false" ^^^ false
}
{% endhighlight %}

### The trouble with left-recursion

Parser combinators work top-down and therefore do not allow for left-recursion. For example, the following would go into an infinite loop, where the parser keeps recursively matching the same token unto `expr`:

{% highlight scala linenos %}
def expr = expr ~ "-" ~ term
{% endhighlight %}

Let's take a look at an arithmetic expression parser:

{% highlight scala linenos %}
object Arithmetic extends StandardTokenParsers {
    lexical.delimiters ++= List("(", ")", "+", "−", "∗", "/")
    def expr: Parser[Any] = term ~ rep("+" ~ term | "−" ~ term)
    def term: Parser[Any] = factor ~ rep("∗" ~ factor | "/" ~ factor)
    def factor: Parser[Any] = "(" ~ expr ~ ")" | numericLit
}
{% endhighlight %}

This definition of `expr`, namely `term ~ rep("-" ~ term)` produces a right-leaning tree. For instance, `1 - 2 - 3` produces `1 ~ List("-" ~ 2, ~ "-" ~ 3)`. 

The solution is to combine calls to `rep` with a final foldLeft on the list:

{% highlight scala linenos %}
object Arithmetic extends StandardTokenParsers {
    lexical.delimiters ++= List("(", ")", "+", "−", "∗", "/")
    def expr: Parser[Any] = term ~ rep("+" ~ term | "−" ~ term) ^^ reduceList
    def term: Parser[Any] = factor ~ rep("∗" ~ factor | "/" ~ factor) ^^ reduceList
    def factor: Parser[Any] = "(" ~ expr ~ ")" | numericLit

    private def reduceList(list: Expr ~ List[String ~ Expr]): Expr = list match {
        case x ~ xs => (x foldLeft ps)(reduce)
    }

    private def reduce(x: Int, r: String ~ Int) = r match {
        case "+" ~ y => x + y
        case "−" ~ y => x − y
        case "∗" ~ y => x ∗ y
        case "/" ~ y => x / y
        case => throw new MatchError("illegal case: " + r)
    }
}
{% endhighlight %}

> 👉 It used to be that the standard library contained parser combinators, but those are now a [separate module](https://github.com/scala/scala-parser-combinators). This module contains a `chainl` (chain-left) method that reduces after a `rep` for you.

## Arithmetic expressions — abstract syntax and proof principles
This section follows Chapter 3 in TAPL.

### Basics of induction
Ordinary induction is simply:

```
Suppose P is a predicate on natural numbers.
Then:
    If P(0)
    and, for all i, P(i) implies P(i + 1)
    then P(n) holds for all n
```

We can also do complete induction:

```
Suppose P is a predicate on natural numbers.
Then:
    If for each natural number n,
    given P(i) for all i < n we can show P(n)
    then P(n) holds for all n
```

It proves exactly the same thing as ordinary induction, it is simply a restated version. They're *interderivable*; assuming one, we can prove the other. Which one to use is simply a matter of style or convenience. We'll see some more equivalent styles as we go along.

### Mathematical representation of syntax
Let's assume the following grammar:

{% highlight antlr linenos %}
t ::= 
    true
    false
    if t then t else t
    0
    succ t
    pred t
    iszero t
{% endhighlight %}

What does this really define? A few suggestions:

- A set of character strings
- A set of token lists
- A set of abstract syntax trees

It depends on how you read it; a grammar like the one above contains information about all three.

However, we are mostly interested in the ASTs. The above grammar is therefore called an **abstract grammar**. Its main purpose is to suggest a mapping from character strings to trees.

For our use of these, we won't be too strict with these. For instance, we'll freely use parentheses to disambiguate what tree we mean to describe, even though they're not strictly supported by the grammar. What matters to us here aren't strict implementation semantics, but rather that we have a framework to talk about ASTs. For our purposes, we'll consider that two terms producing the same AST are basically the same; still, we'll distinguish terms that only have the same evaluation result, as they don't necessarily have the same AST.

How can we express our grammar as mathematical expressions? A grammar describes the legal *set* of terms in a program by offering a recursive definition. While recursive definitions may seem obvious and simple to a programmer, we have to go through a few hoops to make sense of them mathematically.

#### Mathematical representation 1
We can use a set $\mathcal{T}$ of terms. The grammar is then the smallest set such that:

1. $\left\\{ \text{true}, \text{false}, 0 \right\\} \subseteq \mathcal{T}$,
2. If $t_1 \in \mathcal{T}$ then $\left\\{ \text{succ } t_1, \text{pred } t_1, \text{iszero } t_1 \right\\} \subseteq \mathcal{T}$,
3. If $t_1, t_2, t_3 \in \mathcal{T}$ then we also have $\text{if } t_1 \text{ then } t_2 \text{ else } t_3 \in \mathcal{T}$.

#### Mathematical representation 2
We can also write this somewhat more graphically:

$$
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
\newcommand{\if}{\text{if }}
\newcommand{\then}{\text{ then }}
\newcommand{\else}{\text{ else }}
\newcommand{\ifelse}{\if t_1 \then t_2 \else t_3}
\newcommand{\defeq}{\overset{\text{def}}{=}}
\newenvironment{rcases}
  {\left.\begin{aligned}}
  {\end{aligned}\right\rbrace}

\text{true } \in \mathcal{T},  \quad
\text{false } \in \mathcal{T}, \quad
0 \in \mathcal{T}              \\ \\

\frac{t_1 \in \mathcal{T}}{\text{succ } t_1 \in \mathcal{T}}, \quad
\frac{t_1 \in \mathcal{T}}{\text{pred } t_1 \in \mathcal{T}}, \quad
\frac{t_1 \in \mathcal{T}}{\text{iszero } t_1 \in \mathcal{T}} \\ \\

\frac{t_1 \in \mathcal{T}, \quad t_2 \in \mathcal{T}, \quad t_3 \in \mathcal{T}}{\ifelse \in \mathcal{T}}
$$

This is exactly equivalent to representation 1, but we have just introduced a different notation. Note that "the smallest set closed under..." is often not stated explicitly, but implied.

#### Mathematical representation 3
Alternatively, we can build up our set of terms as an infinite union:

$$
\begin{align}
\mathcal{S}_0 = & & \emptyset \\
\mathcal{S}_{i+1} = 
    &      & \set{\text{true}, \text{ false}, 0} \\
    & \cup & \set{\text{succ } t_1, \text{pred } t_1, \text{iszero } t_1 \mid t_1 \in \mathcal{S}_i} \\
    & \cup & \set{\ifelse \mid t_1, t_2, t_3 \in \mathcal{S}_i}
\end{align}
$$

We can thus build our final set as follows:

$$
\mathcal{S} = \bigcup_i{\mathcal{S}_i}
$$

Note that we can "pull out" the definition into a generating function $F$:

$$
\begin{align}
\mathcal{S}_0     & = \emptyset \\
\mathcal{S}_{i+1} & = F(\mathcal{S}_i) \\
\mathcal{S}       & = \bigcup_i{\mathcal{S}_i} \\
\end{align}
$$

The generating function is thus defined as:

$$
\begin{align}
F_1(U) & = \set{\text{true}} \\
F_2(U) & = \set{\text{false}} \\
F_3(U) & = \set{0} \\
F_4(U) & = \set{\text{succ } t_1 \mid t_1 \in U} \\
F_5(U) & = \set{\text{pred } t_1 \mid t_1 \in U} \\
F_6(U) & = \set{\text{iszero } t_1 \mid t_1 \in U} \\
F_7(U) & = \set{\ifelse \mid t_1, t_2, t_3 \in U} \\
\end{align} \\

F(U) = \bigcup_{i=1}^7{F_i(U)}
$$

Each function takes a set of terms $U$ as input and produces "terms justified by $U$" as output; that is, all terms that have the items of $U$ as subterms.

The set $U$ is said to be **closed under F** or **F-closed** if $F(U) \subseteq U$.

The set of terms $T$ as defined above is the smallest F-closed set. If $O$ is another F-closed set, then $T \subseteq O$.

#### Comparison of the representations
We've seen essentially two ways of defining the set (as representation 1 and 2 are equivalent, but with different notation):

1. The smallest set that is closed under certain rules. This is compact and easy to read.
2. The limit of a series of sets. This gives us an *induction principle* on which we can prove things on terms by induction. 

The first one defines the set "from above", by intersecting F-closed sets.

The second one defines it "from below", by starting with $\emptyset$ and getting closer and closer to being F-closed.

These are equivalent (we won't prove it, but Proposition 3.2.6 in TAPL does so), but can serve different uses in practice.

### Induction on terms
First, let's define depth: the **depth** of a term $t$ is the smallest $i$ such that $t\in\mathcal{S_i}$.

The way we defined $\mathcal{S}_i$, it gets larger and larger for increasing $i$; the depth of a term $t$ gives us the step at which $t$ is introduced into the set.

We see that if a term $t$ is in $$\mathcal{S}_i$$, then all of its immediate subterms must be in $\mathcal{S}_{i-1}$, meaning that they must have smaller depth.

This justifies the principle of **induction on terms**, or **structural induction**. Let P be a predicate on a term:

```
If, for each term s,
    given P(r) for all immediate subterms r of s we can show P(s)
    then P(t) holds for all t
```

All this says is that if we can prove the induction step from subterms to terms (under the induction hypothesis), then we have proven the induction.

We can also express this structural induction using generating functions, which we [introduced previously](#mathematical-representation-3).

```
Suppose T is the smallest F-closed set.
If, for each set U,
    from the assumption "P(u) holds for every u ∈ U",
    we can show that "P(v) holds for every v ∈ F(U)"
then
    P(t) holds for all t ∈ T
```

Why can we use this?

- We assumed that $T$ was the smallest F-closed set, which means that $T\subseteq O$ for any other F-closed set $O$.
- Showing the pre-condition ("for each set $U$, from the assumption...") amounts to showing that the set of all terms satisfying $P$ (call it $O$) is itself an F-closed set. 
- Since $T\subseteq O$, every element of $T$ satisfies $P$.

### Inductive function definitions
An [inductive definition](https://en.wikipedia.org/wiki/Recursive_definition) is used to define the elements in a set recursively, as we have done above. The [recursion theorem](https://en.wikipedia.org/wiki/Recursion#The_recursion_theorem) states that a well-formed inductive definition defines a function. To understand what being well-formed means, let's take a look at some examples.

Let's define our grammar function a little more formally. Constants are the basic values that can't be expanded further; in our example, they are `true`, `false`, `0`. As such, the set of constants appearing in a term $t$, written $\text{Consts}(t)$, is defined recursively as follows:

$$
\begin{align}
\text{Consts}(\text{true})  & = \set{\text{true}}  \\
\text{Consts}(\text{false}) & = \set{\text{false}} \\
\text{Consts}(0)            & = \set{0}            \\

\text{Consts}(\text{succ } t_1) & = \text{Consts}(t_1) \\
\text{Consts}(\text{pred } t_1) & = \text{Consts}(t_1) \\
\text{Consts}(\text{iszero } t_1) & = \text{Consts}(t_1) \\
\text{Consts}(\ifelse & = \text{Consts}(t_1) \cup \text{Consts}(t_2) \cup \text{Consts}(t_3) \\
\end{align}
$$

This seems simple, but these semantics aren't perfect. First off, a mathematical definition simply assigns a convenient name to some previously known thing. But here, we're defining the thing in terms of itself, recursively. And the semantics above also allow us to define ill-formed inductive definitions:

$$
\begin{align}
\text{BadConsts}(\text{true})  & = \set{\text{true}}  \\
\text{BadConsts}(\text{false}) & = \set{\text{false}} \\
\text{BadConsts}(0)            & = \set{0}            \\
\text{BadConsts}(0)            & = \set{} = \emptyset \\

\text{BadConsts}(\text{succ } t_1) & = \text{BadConsts}(t_1) \\
\text{BadConsts}(\text{pred } t_1) & = \text{BadConsts}(t_1) \\
\text{BadConsts}(\text{iszero } t_1) & = \text{BadConsts}(\text{iszero iszero }t_1) \\
\end{align}
$$

The last rule produces infinitely large rules (if we implemented it, we'd expect some kind of stack overflow). We're missing the rules for if-statements, and we have a useless rule for `0`, producing empty sets.

How do we tell the difference between a well-formed inductive definition, and an ill-formed one as above? What is well-formedness anyway? 

#### What is a function?

A relation over $T, U$ is a subset of $T \times U$, where the Cartesian product is defined as:

$$
T\times U = \set{(t, u) : t\in T, u\in U}
$$

A function $f$ from $A$ (domain) to $B$ (co-domain) can be viewed as a two-place relation, albeit with two additional properties:

- It is **total**: $\forall a \in A, \exists b \in B : (a, b) \in f$
- It is **deterministic**: $(a, b_1) \in f, (a, b_2) \in f \implies b_1 = b_2$

Totality ensures that the A domain is covered, while being deterministic just means that the function always produces the same result for a given input.

#### Induction example 1
As previously stated, $\text{Consts}$ is a *relation*. It maps terms (A) into the set of constants that they contain (B). The induction theorem states that it is also a *function*. The proof is as follows.

$\text{Consts}$ is total and deterministic: for each term $t$ there is exactly one set of terms $C$ such that $(t, C) \in \text{Consts}$[^in-relation-notation] . The proof is done by induction on $t$.

[^in-relation-notation]: $(t, C) \in \text{Consts}$ is equivalent to $\text{Consts}(t) = C$

To be able to apply the induction principle for terms, we must first show that for an arbitrary term $t$, under the following induction hypothesis:

> For each immediate subterm $s$ of $t$, there is exactly one set of terms $C_s$ such that $(s, C_s) \in \text{Consts}$

Then the following needs to be proven as an induction step:

> There is **exactly one** set of terms $C$ such that $(t, C) \in \text{Consts}$

We proceed by cases on $t$:

- If $t$ is $0$, $\text{true}$ or $\text{false}$
  
  We can immediately see from the definition that of $\text{Consts}$ that there is exactly one set of terms $C = \set{t}$) such that $(t, C) \in \text{Consts}$.

  This constitutes our base case.
  
- If $t$ is $\text{succ } t_1$, $\text{pred } t_1$ or $\text{iszero } t_1$
  
  The immediate subterm of $t$ is $t_1$, and the induction hypothesis tells us that there is exactly one set of terms $C_1$ such that $(t_1, C_1) \in \text{Consts}$. But then it is clear from the definition that there is exactly one set of terms $C = C_1$ such that $(t, C) \in \text{Consts}$.
  
- If $t$ is $\ifelse$
  
  The induction hypothesis tells us:

    - There is exactly one set of terms $C_1$ such that $(t_1, C_1) \in \text{Consts}$
    - There is exactly one set of terms $C_2$ such that $(t_2, C_2) \in \text{Consts}$
    - There is exactly one set of terms $C_3$ such that $(t_3, C_3) \in \text{Consts}$
  
  It is clear from the definition of $\text{Consts}$ that there is exactly one set $C = C_1 \cup C_2 \cup C_3$ such that $(t, C) \in \text{Consts}$.

This proves that $\text{Consts}$ is indeed a function.

But what about $\text{BadConsts}$? It is also a relation, but it isn't a function. For instance, we have $\text{BadConsts}(0) = \set{0}$ and $\text{BadConsts}(0) = \emptyset$, which violates determinism. To reformulate this in terms of the above, there are two sets $C$ such that $(0, C) \in \text{BadConsts}$, namely $C = \set{0}$ and $C = \emptyset$.

Note that there are many other problems with $\text{BadConsts}$, but this is sufficient to prove that it isn't a function.

#### Induction example 2
Let's introduce another inductive definition:

$$
\begin{align}
\text{size}(\text{true})  & = 1 \\
\text{size}(\text{false}) & = 1 \\
\text{size}(0)            & = 1 \\
\text{size}(\text{succ}\ t_1)   & = \text{size}(t_1) + 1 \\
\text{size}(\text{pred}\ t_1)   & = \text{size}(t_1) + 1 \\
\text{size}(\text{iszero}\ t_1) & = \text{size}(t_1) + 1 \\
\text{size}(\ifelse) & = \text{size}(t_1) + \text{size}(t_2) + \text{size}(t_3)\\
\end{align}
$$

We'd like to prove that the number of distinct constants in a term is at most the size of the term. In other words, that $\abs{\text{Consts}(t)} \le \text{size}(t)$

The proof is by induction on $t$:

- $t$ is a constant; $t=\text{true}$, $t=\text{false}$ or $t=0$
  
  The proof is immediate. For constants, the number of constants and the size are both one: $\abs{\text{Consts(t)}} = \abs{\set{t}} = 1 = \text{size}(t)$

- $t$ is a function; $t = \text{succ}\ t_1$, $t = \text{pred}\ t_1$ or $t = \text{iszero}\ t_1$
  
  By the induction hypothesis, $\abs{\text{Consts}(t1)} \le \text{size}(t_1)$.

  We can then prove the proposition as follows: $\abs{\text{Consts}(t)} = \abs{\text{Consts}(t_1)} \overset{\text{IH}}{\le} \text{size}(t_1) = \text{size}(t) + 1 < \text{size}(t)$

- $t$ is an if-statement: $t = \ifelse$
  
  By the induction hypothesis, $\abs{\text{Consts}(t_1)} \le \text{size}(t_1)$, $\abs{\text{Consts}(t_2)} \le \text{size}(t_2)$ and $\abs{\text{Consts}(t_3)} \le \text{size}(t_3)$.

  We can then prove the proposition as follows: 

$$
\begin{align}
\abs{\text{Consts}}
    & = \abs{\text{Consts}(t_1)\cup\text{Consts}(t_2)\cup\text{Consts}(t_3)} \\
    & \le \abs{\text{Consts}(t_1)}+\abs{\text{Consts}(t_2)}+\abs{\text{Consts}(t_3)} \\
    & \overset{\text{IH}}{\le} \text{size}(t_1) + \text{size}(t_2) + \text{size}(t_3) \\
    & < \text{size}(t)
\end{align}
$$


### Operational semantics and reasoning

#### Evaluation
Suppose we have the following syntax

{% highlight antlr linenos %}
t ::=                  // terms
    true                   // constant true
    false                  // constant false 
    if t then t else t     // conditional
{% endhighlight %}

The evaluation relation $t \longrightarrow t'$ is the smallest relation closed under the following rules.

The following are *computation rules*, defining the "real" computation steps:

$$
\begin{align}
\text{if true then } t_2 \else t_3 \longrightarrow t_2 
\tag{E-IfTrue}
\label{eq:e-iftrue} \\

\text{if false then } t_2 \else t_3 \longrightarrow t_3 
\tag{E-IfFalse}
\label{eq:e-iffalse} \\
\end{align}
$$

The following is a *congruence rule*, defining where the computation rule is applied next:

$$
\frac{t_1 \longrightarrow t_1'}
     {\ifelse \longrightarrow \if t_1' \then t_2 \else t_3} 
\tag{E-If}
\label{eq:e-if}
$$

We want to evaluate the condition before the conditional clauses in order to save on evaluation; we're not sure which one should be evaluated, so we need to know the condition first.

#### Derivations
We can describe the evaluation logically from the above rules using derivation trees. Suppose we want to evaluate the following (with parentheses added for clarity): `if (if true then true else false) then false else true`.

In an attempt to make all this fit onto the screen, `true` and `false` have been abbreviated `T` and `F` in the derivation below, and the `then` keyword has been replaced with a parenthesis notation for the condition.

$$
\frac{
    \frac{
        \if (T)\ T \else F
        \longrightarrow
        T
        \quad (\ref{eq:e-iftrue})
    }{
        \if (\if (T)\ T \else F) \ F \else T
        \longrightarrow
        \if (T) \ F \else T
        \quad (\ref{eq:e-if})
    }

    \qquad 

    \small{
        \if (T) \ F \else T
        \longrightarrow
        F
        \quad (\ref{eq:e-iftrue})
    }
}{
    \if (\if (T) \ T \else F) \ F \else T
    \longrightarrow
    T
}
$$

The final statement is a **conclusion**. We say that the derivation is a **witness** for its conclusion (or a **proof** for its conclusion). The derivation records all reasoning steps that lead us to the conclusion.

#### Inversion lemma
We can introduce the **inversion lemma**, which tells us how we got to a term. 

Suppose we are given a derivation $\mathcal{D}$ witnessing the pair $(t, t')$ in the evaluation relation. Then either:

1. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-iftrue})$, then we have $\if true \then t_2 \else t_3$ and $t'=t_2$ for some $t_2$ and $t_3$
2. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-iffalse})$, then we have $\if false \then t_2 \else t_3$ and $t'=t_2$ for some $t_2$ and $t_3$
3. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-if})$, then we have $t = \if t_1 \then t_2 \else t_3$ and $t' = t = \if t_1' \then t_2 \else t_3$, for some $t_1, t_1', t_2, t_3$. Moreover, the immediate subderivation of $\mathcal{D}$ witnesses $(t_1, t_1') \in \longrightarrow$. 

This is super boring, but we do need to acknowledge the inversion lemma before we can do induction proofs on derivations. Thanks to the inversion lemma, given an arbitrary derivation $\mathcal{D}$ with conclusion $t \longrightarrow t'$, we can proceed with a case-by-case analysis on the final rule used in the derivation tree.

Let's recall our [definition of the size function](#induction-example-2). In particular, we'll need the rule for if-statements:

$$
\text{size}(\ifelse) = \text{size}(t_1) + \text{size}(t_2) + \text{size}(t_3)
$$

We want to prove that if $t \longrightarrow t'$, then $\text{size}(t) > \text{size}(t')$.

1. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-iftrue})$, then we have $t = \if true \then t_2 \else t_3$ and $t'=t_2$, and the result is immediate from the definition of $\text{size}$
2. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-iffalse})$, then we have $t = \if false \then t_2 \else t_3$ and $t'=t_2$, and the result is immediate from the definition of $\text{size}$
3. If the final rule applied in $\mathcal{D}$ was $(\ref{eq:e-if})$, then we have $t = \ifelse$ and $t' = \if t_1' \then t_2 \else t_3$. In this case, $t_1 \longrightarrow t_1'$ is witnessed by a derivation $\mathcal{D}_1$. By the induction hypothesis, $\text{size}(t_1) > \text{size}(t_1')$, and the result is then immediate from the definition of $\text{size}$

### Abstract machines
An abstract machine consists of:

- A set of **states**
- A **transition** relation of states, written $\longrightarrow$

$t \longrightarrow t'$ means that $t$ evaluates to $t'$ in one step. Note that $\longrightarrow$ is a relation, and that $t \longrightarrow t'$ is shorthand for $(t, t') \in \longrightarrow$. Often, this relation is a partial function (not necessarily covering the domain A; there is at most one possible next state). But without loss of generality, there may be many possible next states, determinism isn't a criterion here.

### Normal forms
A normal form is a term that cannot be evaluated any further. More formally, a term $t$ is a normal form if there is no $t'$ such that $t \longrightarrow t'$.  A normal form is a state where the abstract machine is halted; we can regard it as the result of a computation. 

#### Values that are normal form
Previously, we intended for our values (true and false) to be exactly that, the result of a computation. Did we get that right? 

Let's prove that a term $t$ is a value $\iff$ it is in normal form.

- The $\implies$ direction is immediate from the definition of the evaluation relation $\longrightarrow$.
- The $\impliedby$ direction is more conveniently proven as its contrapositive: if $t$ is not a value, then it is not a normal form, which we can prove by induction on the term $t$.

  Since $t$ is not a value, it must be of the form $\ifelse$. If $t_1$ is directly `true` or `false`, then $\ref{eq:e-iftrue}$ or $\ref{eq:e-iffalse}$ apply, and we are done.

  Otherwise, if $t = \ifelse$ where $t_1$ isn't a value, by the induction hypothesis, there is a $t_1'$ such that $t_1 \longrightarrow t_1'$. Then rule $\ref{eq:e-if}$ yields $\if t_1' \then t_2 \else t_3$, which proves that $t$ is not in normal form.


#### Values that are not normal form
Let's introduce new syntactic forms, with new evaluation rules.

{% highlight antlr linenos %}
t ::=        // terms
    0            // constant 0
    succ t       // successor
    pred t       // predecessor 
    iszero t     // zero test

v ::=  nv     // values

nv ::=        // numeric values
    0             // zero value
    succ nv       // successor value
{% endhighlight %}

The evaluation rules are given as follows:

$$
\begin{align}
& \frac{t_1 \longrightarrow t_1'}{\text{succ } t_1 \longrightarrow \text{succ } t_1'} 
\tag{E-Succ} \label{eq:e-succ}
\\ \\
& \text{pred } 0 \longrightarrow 0
\tag{E-PredZero} \label{eq:e-predzero} 
\\ \\
& \text{pred succ } nv_1 \longrightarrow nv_1
\tag{E-PredSucc} \label{eq:e-predsucc}
\\ \\
& \frac{t_1 \longrightarrow t_1'}{\text{pred } t_1 \longrightarrow \text{pred } t_1'}
\tag{E-Pred} \label{eq:e-pred}
\\ \\
& \text{iszero } 0 \longrightarrow true
\tag{E-IszeroZero} \label{eq:e-iszerozero}
\\ \\
& \text{iszero succ } nv_1 \longrightarrow false
\tag{E-IszeroSucc} \label{eq:e-iszerosucc}
\\ \\
& \frac{t_1 \longrightarrow t_1'}{\text{iszero } t_1 \longrightarrow \text{iszero } t_1'}
\tag{E-Iszero} \label{eq:e-iszero} \\
\end{align}
$$

All values are still normal forms. But are all normal forms values? Not in this case. For instance, `succ true`, `iszero true`, etc, are normal forms. These are **stuck terms**: they are in normal form, but are not values. In general, these correspond to some kind of type error, and one of the main purposes of a type system is to rule these kinds of situations out.

### Multi-step evaluation
Let's introduce the *multi-step evaluation* relation, $\longrightarrow^*$. It is the reflexive, transitive closure of single-step evaluation, i.e. the smallest relation closed under these rules:

$$
\begin{align}
\frac{t\longrightarrow t'}{t \longrightarrow^* t'} \\ \\
t \longrightarrow^* t \tag{Reflexivity} \\ \\
\frac{t \longrightarrow^* t' \qquad t' \longrightarrow^* t''}{t \longrightarrow^* t''} \tag{Transitivity}
\end{align}
$$

In other words, it corresponds to any number of single consecutive evaluations.

### Termination of evaluation
We'll prove that evaluation terminates, i.e. that for every term $t$ there is some normal form $t'$ such that $t\longrightarrow^* t'$.

First, let's [recall our proof](#induction-example-2) that $t\longrightarrow t' \implies \text{size}(t) > \text{size}(t')$. Now, for our proof by contradiction, assume that we have an infinite-length sequence $t_0, t_1, t_2, \dots$ such that:

$$
t_0 \longrightarrow t_1 \longrightarrow t_2 \longrightarrow \dots
\quad \implies \quad 
\text{size}(t_0) > \text{size}(t_1) > \text{size}(t_2) > \dots
$$

But this sequence cannot exist: since $\text{size}(t_0)$ is a finite, natural number, we cannot construct this infinite descending chain from it. This is a contradiction.

Most termination proofs have the same basic form. We want to prove that the relation $R\subseteq X \times X$ is terminating &mdash; that is, there are no infinite sequences $x_0, x_1, x_2, \dots$ such that $(x_i, x_{i+1}) \in R$ for each $i$. We proceed as follows:

1. Choose a well-suited set $W$ with partial order $<$ such that there are no infinite descending chains $w_0 > w_1 > w_2 > \dots$ in $W$. Also choose a function $f: X \rightarrow W$.
2. Show $f(x) > f(y) \quad \forall (x, y) \in R$
3. Conclude that are no infinite sequences $(x_0, x_1, x_2, \dots)$ such that $(x_i, x_{i+1}) \in R$ for each $i$. If there were, we could construct an infinite descending chain in $W$.

As a side-note, **partial order** is defined as the following properties:

1. **Anti-symmetry**: $\neg(x < y \land y < x)$
2. **Transitivity**: $x<y \land y<z \implies x < z$

We can add a third property to achieve **total order**, namely $x \ne y \implies x <y \lor y<x$.

## Lambda calculus
Lambda calculus is Turing complete, and is higher-order (functions are data). In lambda calculus, all computation happens by means of function abstraction and application.

Lambda calculus is isomorphic to Turing machines. 

Suppose we wanted to write a function `plus3` in our previous language:

{% highlight linenos %}
plus3 x = succ succ succ x
{% endhighlight %}

The way we write this in lambda calculus is:

$$
\text{plus3 } = \lambda x. \text{ succ}(\text{succ}(\text{succ}(x)))
$$

$\lambda x. t$ is written `x => t` in Scala, or `fun x -> t` in OCaml. Application of our function, say `plus3(succ 0)`, can be written as:

$$
(\lambda x. \text{succ succ succ } x)(\text{succ } 0)
$$

Abstraction over functions is possible using higher-order functions, which we call $\lambda$-abstractions. An example of such an abstraction is the function $g$ below, which takes an argument $f$ and uses it in the function position. 

$$
g = \lambda f. f(f(\text{succ } 0))
$$

If we apply $g$ to an argument like $\text{plus3}$, we can just use the substitution rule to see how that defines a new function.

Another example: the `twice` function below takes two arguments, as a curried function would. First, it takes the function to apply twice, then the argument on which to apply it, and then returns $f(f(y))$.

$$
\text{twice} = \lambda f. \lambda y. f(f(y))
$$

### Pure lambda calculus
Once we have $\lambda$-abstractions, we can actually throw out all other language primitives like booleans and other values; all of these can be expressed as functions, as we'll see below. In pure lambda-calculus, *everything* is a function.

Variables will always denote a function, functions always take other functions as parameters, and the result of an evaluation is always a function.

The syntax of lambda-calculus is very simple:

{% highlight antlr linenos %}
t ::=      // terms, also called λ-terms
    x         // variable
    λx. t     // abstraction, also called λ-abstractions
    t t       // application
{% endhighlight %}

A few rules and syntactic conventions:

- Application associates to the left, so $t\ u\ v$ means $(t\ u)\ v$, not $t\ (u\ v)$.
- Bodies of lambda abstractions extend as far to the right as possible, so $\lambda x. \lambda y.\ x\ y$ means $\lambda x.\ (\lambda y. x\ y)$, not $\lambda x.\ (\lambda y.\ x)\ y$

#### Scope
The lambda expression $\lambda x.\ t$ **binds** the variable $x$, with a **scope** limited to $t$. Occurrences of $x$ inside of $t$ are said to be *bound*, while occurrences outside are said to be *free*. 

Let $\text{fv}(t)$ be the set of free variables in a term $t$. It's defined as follows:

$$
\begin{align}
\text{fv}(x) & = \set{x} \\
\text{fv}(\lambda x.\ t_1) & = \text{fv}(t_1) \setminus \set{x} \\ 
\text{fv}(t_1 \ t_2) & = \text{fv}(t_1)\cup\text{fv}(t_2) \\
\end{align}
$$

#### Operational semantics
As we saw with our previous language, the rules could be distinguished into *computation* and *congruence* rules. For lambda calculus, the only computation rule is:

$$
(\lambda x. t_{12})\ v_2 \longrightarrow \left[ x \mapsto v_2 \right] t_{12}
\tag{E-AppAbs}\label{eq:e-appabs}
$$

The notation $\left[ x \mapsto v_2 \right] t_{12}$ means "the term that results from substituting free occurrences of $x$ in $t_{12}$ with $v_2$".

The congruence rules are:

$$
\begin{align}
& \frac{t_1 \longrightarrow t_1'}{t_1\ t_2 \longrightarrow t_1'\ t_2} \tag{E-App1}\label{eq:e-app1} \\ \\
& \frac{t_2 \longrightarrow t_2'}{t_1\ t_2 \longrightarrow t_1\ t_2'} \tag{E-App2}\label{eq:e-app2} \\
\end{align}
$$

A lambda-expression applied to a value, $(\lambda x.\ t)\ v$, is called a **reducible expression**, or **redex**.

#### Evaluation strategies
There are alternative evaluation strategies. In the above, we have chosen call by value (which is the standard in most mainstream languages), but we could also choose:

- **Full beta-reduction**: any redex may be reduced at any time. This offers no restrictions, but in practice, we go with a set of restrictions like the ones below (because coding a fixed way is easier than coding probabilistic behavior).
- **Normal order**: the leftmost, outermost redex is always reduced first. This strategy allows to reduce inside unapplied lambda terms
- **Call-by-name**: allows no reductions inside lambda abstractions. Arguments are not reduced before being substituted in the body of lambda terms when applied. Haskell uses an optimized version of this, call-by-need (aka lazy evaluation).

### Classical lambda calculus
Classical lambda calculus allows for full beta reduction. 

#### Confluence in full beta reduction
The congruence rules allow us to apply in different ways; we can choose between $\ref{eq:e-app1}$ and $\ref{eq:e-app2}$ every time we reduce an application, and this offers many possible reduction paths. 

While the path is non-deterministic, is the result also non-deterministic? This question took a very long time to answer, but after 25 years or so, it was proven that the result is always the same. This is known the **Church-Rosser confluence theorem**:

Let $t, t_1, t_2$ be terms such that $t \longrightarrow^* t_1$ and $t \longrightarrow^* t_2$. Then there exists a term $t_3$ such that $t_1 \longrightarrow^* t_3$ and $t_2 \longrightarrow^* t_3$

#### Alpha conversion
Substitution is actually trickier than it looks! For instance, in the  expression $\lambda x.\ (\lambda y.\ x)\ y$, the first occurrence of $y$ is bound (it refers to a parameter), while the second is free (it does not refer to a parameter). This is comparable to scope in most programming languages, where we should understand that these are two different variables in different scopes, $y_1$ and $y_2$.

The above example had a variable that is both bound and free, which is something that we'll try to avoid. This is called a hygiene condition.

We can transform a unhygienic expression to a hygienic one by renaming bound variables before performing the substitution. This is known as **alpha conversion**. Alpha conversion is given by the following conversion rule:

$$
\frac{y \notin \text{fv}(t)}{(\lambda x.\ t) =_\alpha (\lambda y.\ \left[ x\mapsto y\right]\ t)}
\tag{$\alpha$}
\label{eq:alpha-conv}
$$

And these equivalence rules (in mathematics, equivalence is defined as symmetry and transitivity):

$$
\begin{align}
& \frac{t_1 =_\alpha t_2}{t_2 =_\alpha t_1} 
\tag{$\alpha \text{-Symm}$}
\label{eq:alpha-sym}
\\ \\

& \frac{t_1 =_\alpha t_2 \quad t_2 =_\alpha t_3}{t_1 =_\alpha t_3}
\tag{$\alpha \text{-Trans}$}
\label{eq:alpha-trans}
\\
\end{align}
$$

The congruence rules are as usual.

### Programming in lambda-calculus

#### Multiple arguments
The way to handle multiple arguments is by currying: $\lambda x.\ \lambda y.\ t$

#### Booleans
The fundamental, universal operator on booleans is if-then-else, which is what we'll replicate to model booleans. We'll denote our booleans as $\text{tru}$ and $\text{fls}$ to be able to distinguish these pure lambda-calculus abstractions from the true and false values of our previous toy language.

We want `true` to be equivalent to `if (true)`, and `false` to `if (false)`. The terms $\text{tru}$ and $\text{fls}$ *represent* boolean values, in that we can use them to test the truth of a boolean value:

$$
\begin{align}
\text{tru } & = \lambda t.\ \lambda f.\ t \\
\text{fls } & = \lambda t.\ \lambda f.\ f \\
\end{align}
$$

We can consider these as booleans. Equivalently `tru` can be considered as a function performing `(t1, t2) => if (true) t1 else t2`. To understand this, let's try to apply $\text{tru}$ to two arguments:

$$
\begin{align}
&   && \text{tru } v\ w \\
& = && (\lambda t.\ (\lambda f.\  t))\ v\ w \\
& \longrightarrow && (\lambda f.\ v)\ w \\
& \longrightarrow && v \\
\end{align}
$$

This works equivalently for `fls`. 

We can also do inversion, conjunction and disjunction with lambda calculus, which can be read as particular if-else statements:

$$
\begin{align}
\text{not } & = \lambda b.\ b\ \text{fls}\ \text{true} \\
\text{and } & = \lambda b.\ \lambda c.\ b\ c\ \text{fls} \\
\text{or }  & = \lambda b.\ \lambda c.\ b\ \text{tru}\ c \\
\end{align}
$$


- `not` is a function that is equivalent to `not(b) = if (b) false else true`. 
- `and` is equivalent to `and(b, c) = if (b) c else false`
- `or` is equivalent to `or(b, c) = if (b) true else c`

#### Pairs
The fundamental operations are construction `pair(a, b)`, and selection `pair._1` and `pair._2`.

$$
\begin{align}
\text{pair } & = \lambda f.\ \lambda s.\ \lambda b.\ b\ f\ s\\
\text{fst }  & = \lambda p.\ p\ \text{tru} \\
\text{snd }  & = \lambda p.\ p\ \text{fls} \\
\end{align}
$$

- `pair` is equivalent to `pair(f, s) = (b => b f s)`
- When `tru` is applied to `pair`, it selects the first element, by definition of the boolean, and that is therefore the definition of `fst`
- Equivalently for `fls` applied to `pair`, it selects the second element

#### Numbers
We've actually been representing numbers as lambda-calculus numbers all along! Our `succ` function represents what's more formally called **Church numerals**.

$$
\begin{align}
c_0 & = \lambda s.\ \lambda z.\ z \\
c_1 & = \lambda s.\ \lambda z.\ s\ z \\
c_2 & = \lambda s.\ \lambda z.\ s\ s\ z \\
c_3 & = \lambda s.\ \lambda z.\ s\ s\ s\ z \\
\end{align}
$$

Note that $c_0$'s implementation is the same as that of $\text{fls}$ (just with renamed variables).

Every number $n$ is represented by a term $c_n$ taking two arguments, which are $s$ and $z$ (for "successor" and "zero"), and applies $s$ to $z$, $n$ times. Fundamentally, a number is equivalent to the following:

$$
c_n = \lambda f.\ \lambda x.\ \underbrace{f\ \dots\ f}_{n \text{ times}}\ x
$$

With this in mind, let us implement some functions on numbers.

$$
\begin{align}
\text{scc } & = \lambda n.\ \lambda s.\ \lambda z.\ s\ (n\ s\ z) \\
\text{add } & = \lambda s.\ \lambda z.\ m\ s\ (n\ s\ z) \\
\text{mul } & = \lambda m.\ \lambda n.\ m\ (\text{add } n)\ c_0 \\
\text{sub } & = \lambda m.\ \lambda n.\ n\ \text{pred}\ m \\
\text{iszero } & = \lambda m.\ m\ (\lambda x.\ \text{fls})\ \text{tru}
\end{align}
$$

- **Successor** $\text{scc}$: we apply the successor function to $n$ (which has been correctly instantiated with $s$ and $z$)
- **Addition** $\text{add}$: we pass the instantiated $n$ as the zero of $m$
- **Subtraction** $\text{sub}$: we apply $\text{pred}$ $n$ times to $m$
- **Multiplication** $\text{mul}$: instead of the successor function, we pass the addition by $n$ function.
- **Zero test** $\text{iszero}$: zero has the same implementation as false, so we can lean on that to build an iszero function. An alternative understanding is that we're building a number, in which we use true for the zero value $z$. If we have to apply the successor function $s$ once or more, we want to get false, so for the successor function we use a function ignoring its input and returning false if applied.

What about predecessor? This is a little harder, and it'll take a few steps to get there. The main idea is that we find the predecessor by rebuilding the whole succession up until our number. At every step, we must generate the number and its predecessor: zero is $(c_0, c_0)$, and all other numbers are $(c_{n-1}, c_n)$. Once we've reconstructed this pair, we can get the predecessor by taking the first element of the pair.

$$
\begin{align}
\text{zz} & = \text{pair } c_0 \  c_0 \\
\text{ss} & = \lambda p.\ \text{pair } (\text{snd } p)\ (\text{scc } (\text{snd } p)) \\
\text{prd} & = \lambda m.\ \text{fst } (m\ \text{ss zz}) \\
\end{align}
$$

{% details Sidenote %}
The story goes that Church was stumped by predecessors for a long time. This solution finally came to him while he was at the barber, and he jumped out half shaven to write it down.
{% enddetails %}

#### Lists
Now what about lists? 

$$
\begin{align}
\text{nil} & = \lambda f.\ \lambda g.\ g \\
\text{cons} & = \lambda x.\ \lambda xs.\ (\lambda f.\ \lambda g.\ f\ x\ xs) \\
\text{head} & = \lambda xs.\ (\lambda y.\ \lambda ys.\  y) \\
\text{isEmpty} & = \lambda xs.\ xs\ (\lambda y.\ \lambda ys.\ \text{fls}) \\
\end{align}
$$

### Recursion in lambda-calculus
Let's start by taking a step back. We talked about normal forms and terms for which we terminate; does lambda calculus always terminate? It's Turing complete, so it must be able to loop infinitely (otherwise, we'd have solved the halting problem!).

The trick to recursion is self-application:

$$
\lambda x.\ x\ x
$$

From a type-level perspective, we would cringe at this. This should not be possible in the typed world, but in the untyped world we can do it. We can construct a simple infinite loop in lambda calculus as follows:

$$
\begin{align}
\Omega
    & = & (\lambda x.\ x\ x)\ (\lambda x.\ x\ x) \\
    & \longrightarrow & \ (\lambda x.\ x\ x)\ (\lambda x.\ x\ x)
\end{align}
$$

The expression evaluates to itself in one step; it never reaches a normal form, it loops infinitely, diverges. This is not a stuck term though; evaluation is always possible.

In fact, there are no stuck terms in pure lambda calculus. Every term is either a value or reduces further.

So it turns out that $\text{omega}$ isn't so terribly useful. Let's try to construct something more practical:

$$
Y_f = (\lambda x.\ f\ (x\ x))\ (\lambda x.\ f\ (x\ x))
$$

Now, the divergence is a little more interesting:

$$
\begin{align}
Y_f & = & (\lambda x.\ f\ (x\ x))\ (\lambda x.\ f\ (x\ x)) \\
& \longrightarrow & f\ ((\lambda x.\ f\ (x\ x))\ (\lambda x.\ f\ (x\ x))) \\
& = & f\ (Y_f) \\
& \longrightarrow & \dots \\
& = & f\ (f\ (Y_f)) \\
\end{align}
$$

This $Y_f$ function is known as a **Y combinator**. It still loops infinitely (though note that while it works in classical lambda calculus, it blows up in call-by-name), so let's try to build something more useful.

To delay the infinite recursion, we could build something like a poison pill:

$$
\text{poisonpill} = \lambda y.\ \text{omega}
$$

It can be passed around (after all, it's just a value), but evaluating it will cause our program to loop infinitely. This is the core idea we'll use for defining the **fixed-point combinator** $\text{fix}$ (also known as the call-by-value Y combinator), which allows us to do recursion. It's defined as follows:

$$
\text{fix} = \lambda f.\ (\lambda x.\ f\ (\lambda y.\ x\ x\ y))\ (\lambda x.\ f\ (\lambda y.\ x\ x\ y))
$$

This looks a little intricate, and we won't need to fully understand the definition. What's important is mostly how it is used to define a recursive function. For instance, if we wanted to define a modulo function in our toy language, we'd do it as follows:

{% highlight scala linenos %}
def mod(x, y) = 
    if (y > x) x
    else mod(x - y, y)
{% endhighlight %}

In lambda calculus, we'd define this as:

$$
\text{mod} = \text{fix } (\lambda f.\ \lambda x.\ \lambda y.\ 
    (\text{gt } y\ x)\ x\ (f (\text{sub } a\ b)\ b)
)
$$

We've assumed that a greater-than $\text{gt}$ function was available here.

More generally, we can define a recursive function as:

$$
\text{fix } \bigl(\lambda f.\ (\textit{recursion on } f)\bigr)
$$

### Equivalence of lambda terms
We've seen how to define Church numerals and successor. How can we prove that $\text{succ } c_n$ is equal to $c_{n+1}$? 

The naive approach unfortunately doesn't work; they do not evaluate to the same value.

$$
\begin{align*}
\text{scc } c_2 
    & = (\lambda n.\ \lambda s.\ \lambda z.\  s\ (n\ s\ z))\ (\lambda s.\ \lambda z.\ s\ (s\ z)) \\
    & \longrightarrow \lambda s.\ \lambda z.\ s\ ((\lambda s.\ \lambda z.\ s\ (s\ z))\ s\ z) \\
    & \neq \lambda s.\ \lambda z.\ s\ (s\ (s\ z)) \\
    & = c_3 \\
\end{align*}
$$

This still seems very close. If we could simplify a little further, we do see how they would be the same.

The intuition behind the Church numeral representation was that a number $n$ is represented as a term that "does something $n$ times to something else". $\text{scc}$ takes a term that "does something $n$ times to something else", and returns a term that "does something $n+1$ times to something else".

What we really care about is that $\text{scc } c_2$ *behaves* the same as $c_3$ when applied to two arguments. We want *behavioral equivalence*. But what does that mean? Roughly, two terms $s$ and $t$ are behaviorally equivalent if there is no "test" that distinguishes $s$ and $t$.

Let's define this notion of "test" this a little more precisely, and specify how we're going to observe the results of a test. We can use the notion of **normalizability** to define a simple notion of a test:

> Two terms $s$ and $t$ are said to be **observationally equivalent** if they are either both normalizable (i.e. they reach a normal form after a finite number of evaluation steps), or both diverge.

In other words, we observe a term's behavior by running it and seeing if it halts. Note that this is not decidable (by the halting problem).

For instance, $\text{omega}$ and $\text{tru}$ are not observationally equivalent (one diverges, one halts), while $\text{tru}$ and $\text{fls}$ are (they both halt).

Observational equivalence isn't strong enough of a test for what we need; we need behavioral equivalence.

> Two terms $s$ and $t$ are said to be **behaviorally equivalent** if, for every finite sequence of values $v_1, v_2, \dots, v_n$ the applications $s\ v_1\ v_2\ \dots\ v_n$ and $t\ v_1\ v_2\ \dots\ v_n$ are observationally equivalent.

This allows us to assert that true and false are indeed different: 

$$
\begin{align}
\text{tru}\ x\ \Omega & \longrightarrow x \\
\text{fls}\ x\ \Omega & \longrightarrow \Omega \\
\end{align}
$$

The former returns a normal form, while the latter diverges.

## Types
As previously, to define a language, we start with a *set of terms* and *values*, as well as an *evaluation relation*. But now, we'll also define a set of **types** (denoted with a first capital letter) classifying values according to their "shape". We can define a *typing relation* $t:\ T$. We must check that the typing relation is *sound* in the sense that:

$$
\frac{t: T \qquad t\longrightarrow^* v}{v: T} 
\qquad\text{and}\qquad
\frac{t: T}{\exists t' \text{ such that } t\longrightarrow t'}
$$

These rules represent some kind of safety and liveness, but are more commonly referred to as [progress and preservation](#properties-of-the-typing-relation), which we'll talk about later. The first one states that types are preserved throughout evaluation, while the second says that if we can type-check, then evaluation of $t$ will not get stuck.

In our previous toy language, we can introduce two types, booleans and numbers:

{% highlight antlr linenos %}
T ::=     // types
    Bool     // type of booleans
    Nat      // type of numbers
{% endhighlight %}

Our typing rules are then given by:

$$
\begin{align}
\text{true } : \text{ Bool} 
\tag{T-True} \label{eq:t-true} \\ \\

\text{false } : \text{ Bool} 
\tag{T-False} \label{eq:t-false} \\ \\

0: \text{ Nat} 
\tag{T-Zero} \label{eq:t-zero} \\ \\

\frac{t_1: \text{Bool} \quad t_2 : T \quad t_3: T}{\ifelse}
\tag{T-If} \label{eq:t-if} \\ \\

\frac{t_1: \text{Nat}}{\text{succ } t_1: \text{Nat}}
\tag{T-Succ} \label{eq:t-succ} \\ \\

\frac{t_1: \text{Nat}}{\text{pred } t_1: \text{Nat}}
\tag{T-Pred} \label{eq:t-pred} \\ \\

\frac{t_1: \text{Nat}}{\text{iszero } t_1: \text{Nat}}
\tag{T-IsZero} \label{eq:t-iszero} \\ \\
\end{align}
$$

With these typing rules in place, we can construct typing derivations to justify every pair $t: T$ (which we can also denote as a $(t, T)$ pair) in the typing relation, as we have done previously with evaluation. Proofs of properties about the typing relation often proceed by induction on these typing derivations.

Like other static program analyses, type systems are generally imprecise. They do not always predict exactly what kind of value will be returned, but simply a conservative approximation. For instance, `if true then 0 else false` cannot be typed with the above rules, even though it will certainly evaluate to a number. We could of course add a typing rule for `if true` statements, but there is still a question of how useful this is, and how much complexity it adds to the type system, and especially for proofs. Indeed, the inversion lemma below becomes much more tedious when we have more rules.

### Properties of the Typing Relation
The safety (or soundness) of this type system can be expressed by the following two properties:

- **Progress**: A well-typed term is not stuck. 
  
  If $t\ :\ T$ then either $t$ is a value, or else $t\longrightarrow t'$ for some $t'$.

- **Preservation**: Types are preserved by one-step evaluation. 
  
  If $t\ :\ T$ and $t\longrightarrow t'$, then $t'\ :\ T$.


We will prove these later, but first we must state a few lemmas.

#### Inversion lemma
Again, for types we need to state the same (boring) inversion lemma:

1. If $\text{true}: R$, then $R = \text{Bool}$.
2. If $\text{false}: R$, then $R = \text{Bool}$.
3. If $\ifelse: R$, then $t_1: \text{ Bool}$, $t_2: R$ and $t_3: R$
4. If $0: R$ then $R = \text{Nat}$
5. If $\text{succ } t_1: R$ then $R = \text{Nat}$ and $t_1: \text{Nat}$
6. If $\text{pred } t_1: R$ then $R = \text{Nat}$ and $t_1: \text{Nat}$
7. If $\text{iszero } t_1: R$ then $R = \text{Bool}$ and $t_1: \text{Nat}$

From the inversion lemma, we can directly derive a typechecking algorithm:

{% highlight scala linenos %}
def typeof(t: Expr): T = t match {
    case True | False => Bool
    case If(t1, t2, t3) =>
        val type1 = typeof(t1)
        val type2 = typeof(t2)
        val type3 = typeof(t3)
        if (type1 == Bool && type2 == type3) type2
        else throw Error("not typable")
    case Zero => Nat
    case Succ(t1) => 
        if (typeof(t1) == Nat) Nat
        else throw Error("not typable")
    case Pred(t1) => 
        if (typeof(t1) == Nat) Nat
        else throw Error("not typable")
    case IsZero(t1) => 
        if (typeof(t1) == Nat) Bool
        else throw Error("not typable")
}
{% endhighlight %}

#### Canonical form
A simple lemma that will be useful for lemma is that of canonical forms. Given a type, it tells us what kind of values we can expect:

1. If $v$ is a value of type Bool, then $v$ is either $\text{true}$ or $\text{false}$
2. If $v$ is a value of type Nat, then $v$ is a numeric value

The proof is somewhat immediate from the syntax of values.

#### Progress Theorem
**Theorem**: suppose that $t$ is a well-typed term of type $T$. Then either $t$ is a value, or else there exists some $t'$ such that $t\longrightarrow t'$.

**Proof**: by induction on a derivation of $t: T$.

- The $\ref{eq:t-true}$, $\ref{eq:t-false}$ and $\ref{eq:t-zero}$ are immediate, since $t$ is a value in these cases.
- For $\ref{eq:t-if}$, we have $t=\ifelse$, with $t_1: \text{Bool}$, $t_2: T$ and $t_3: T$. By the induction hypothesis, there is some $t_1'$ such that $t_1 \longrightarrow t_1'$. 

  If $t_1$ is a value, then rule 1 of the [canonical form lemma](#canonical-form) tells us that $t_1$ must be either $\text{true}$ or $\text{false}$, in which case $\ref{eq:e-iftrue}$ or $\ref{eq:e-iffalse}$ applies to $t$.

  Otherwise, if $t_1 \longrightarrow t_1'$, then by $\ref{eq:e-if}$, $t\longrightarrow \if t_1' \then t_2 \text{ else } t_3$

- For $\ref{eq:t-succ}$, we have $t = \text{succ } t_1$. 
  
  $t_1$ is a value, by rule 5 of the [inversion lemma](#inversion-lemma) and by rule 2 of the [canonical form](#canonical-form), $t_1 = nv$ for some numeric value $nv$. Therefore, $\text{succ }(t_1)$ is a value. If $t_1 \longrightarrow t_1'$, then $t\longrightarrow \text{succ }t_1$.

- The cases for $\ref{eq:t-zero}$, $\ref{eq:t-pred}$ and $\ref{eq:t-iszero}$ are similar.

#### Preservation Theorem
**Theorem**: Types are preserved by one-step evaluation. If $t: T$ and $t\longrightarrow t'$, then $t': T$.

**Proof**: by induction on the given typing derivation

- For $\ref{eq:t-true}$ and $\ref{eq:t-false}$, the precondition doesn't hold (no reduction is possible), so it's trivially true. Indeed, $t$ is already a value, either $t=\text{ true}$ or $t=\text{ false}$.
- For $\ref{eq:t-if}$, there are three evaluation rules by which $t\longrightarrow t'$ can be derived, depending on $t_1$
    + If $t_1 = \text{true}$, then by $\ref{eq:e-iftrue}$ we have $t'=t_2$, and from rule 3 of the [inversion lemma](#inversion-lemma-1) and the assumption that $t: T$, we have $t_2: T$, that is $t': T$
    + If $t_1 = \text{false}$, then by $\ref{eq:e-iffalse}$ we have $t'=t_3$, and from rule 3 of the [inversion lemma](#inversion-lemma-1) and the assumption that $t: T$, we have $t_3: T$, that is $t': T$
    + If $t_1 \longrightarrow t_1'$, then by the induction hypothesis, $t_1': \text{Bool}$. Combining this with the assumption that $t_2: T$ and $t_3: T$, we can apply $\ref{eq:t-if}$ to conclude $\if t_1' \then t_2 \else t_3: T$, that is $t': T$

### Messing with it
#### Removing a rule
What if we remove $\ref{eq:e-predzero}$? Then `pred 0` type checks, but it is stuck and is not a value; the [progress theorem](#progress-theorem) fails.

#### Changing type-checking rule
What if we change the $\ref{eq:t-if}$ to the following?

$$
\frac{
    t_1 : \text{Bool} \quad
    t_2 : \text{Nat} \quad 
    t_3 : \text{Nat}
}{
    (\ifelse) : \text{Nat}
}
\tag{T-If 2}
\label{eq:t-if2}
$$

This doesn't break our type system. It's still sound, but it rejects if-else expressions that return other things than numbers (e.g. booleans). But that is an expressiveness problem, not a soundness problem; our type system disallows things that would otherwise be fine by the evaluation rules.

#### Adding bit
We could add a boolean to natural function `bit(t)`. We'd have to add it to the grammar, add some evaluation and typing rules, and prove progress and preservation.

$$
\begin{align}
\text{bit true} \longrightarrow 0 \\ \\
\text{bit false} \longrightarrow 1 \\ \\

\frac{t_1 \longrightarrow t_1'}{\text{bit }t_1 \longrightarrow \text{bit }t_1'}
\\ \\
\frac{t : \text{Bool}}{\text{bit } t : \text{Nat}}
\end{align}
$$

We'll do something similar this below, so the full proof is omitted.

## Simply typed lambda calculus
Simply Typed Lambda Calculus (STLC) is also denoted $\lambda_\rightarrow$. The "pure" form of STLC is not very interesting on the type-level (unlike for the term-level of pure lambda calculus), so we'll allow base values that are not functions, like booleans and integers. To talk about STLC, we always begin with some set of "base types":

{% highlight antlr linenos %}
T ::=     // types
    Bool    // type of booleans
    T -> T  // type of functions
{% endhighlight %}

In the following examples, we'll work with a mix of our previously defined toy language, and lambda calculus. This will give us a little syntactic sugar.

{% highlight antlr linenos %}
t ::=                // terms
    x                   // variable
    λx. t               // abstraction
    t t                 // application
    true                // constant true
    false               // constant false
    if t then t else t  // conditional

v ::=   // values
    λx. t  // abstraction value
    true   // true value
    false  // false value
{% endhighlight %}


### Type annotations
We will annotate lambda-abstractions with the expected type of the argument, as follows:

$$
\lambda x: T_1 .\ t_1
$$

We could also omit it, and let type inference do the job (as in OCaml), but for now, we'll do the above. This will make it simpler, as we won't have to discuss inference just yet.

### Typing rules
In STLC, we've introduced abstraction. To add a typing rule for that, we need to encode the concept of an environment $\Gamma$, which is a set of variable assignments. We also introduce the "turnstile" symbol $\vdash$, meaning that the environment can verify the right hand-side typing, or that $\Gamma$ must imply the right-hand side.

$$
\begin{align}

\frac{
    \bigl( \Gamma \cup (x_1 : T_1) \bigr) \vdash  t_2 : T_2
}{ \Gamma\vdash(\lambda x: T_1.\ t_2): T_1 \rightarrow T_2 }
\tag{T-Abs} \label{eq:t-abs} \\ \\

\frac{x: T \in \Gamma}{\Gamma\vdash x: T}
\tag{T-Var} \label{eq:t-var} \\ \\

\frac{
    \Gamma\vdash t_1 : T_{11}\rightarrow T_{12}
    \quad
    \Gamma\vdash t_2 : T_{11}
}{\Gamma\vdash t_1\ t_2 : T_{12}}
\tag{T-App} \label{eq:t-app} 

\end{align}
$$

This additional concept must be taken into account in our definition of progress and preservation:

- **Progress**: If $\Gamma\vdash t : T$, then either $t$ is a value or else $t\longrightarrow t'$ for some $t'$
- **Preservation**: If $\Gamma\vdash t : T$ and $t\longrightarrow t'$, then $\Gamma\vdash t' : T$

To prove these, we must take the same steps as above. We'll introduce the inversion lemma for typing relations, and restate the canonical forms lemma in order to prove the progress theorem.

### Inversion lemma
Let's start with the inversion lemma.

1. If $\Gamma\vdash\text{true} : R$ then $R = \text{Bool}$
2. If $\Gamma\vdash\text{false} : R$ then $R = \text{Bool}$
3. If $\Gamma\vdash\ifelse : R$ then $\Gamma\vdash t_1 : \text{Bool}$ and $\Gamma\vdash t_2, t_3: R$.
4. If $\Gamma\vdash x: R$ then $x: R \in\Gamma$
5. If $\Gamma\vdash\lambda x: T_1 .\ t_2 : R$ then $R = T_1 \rightarrow T_2$ for some $R_2$ with $\Gamma\cup(x: T_1)\vdash t_2: R_2$
6. If $\Gamma\vdash t_1\ t_2 : R$ then there is some type $T_{11}$ such that $\Gamma\vdash t_1 : T_{11} \rightarrow R$ and $\Gamma\vdash t_2 : T_{11}$.

### Canonical form
The canonical forms are given as follows:

1. If $v$ is a value of type Bool, then it is either $\text{true}$ or $\text{false}$
2. If $v$ is a value of type $T_1 \rightarrow T_2$ then $v$ has the form $\lambda x: T_1 .\ t_2$

### Progress
Finally, we get to prove the progress by induction on typing derivations.

**Theorem**: Suppose that $t$ is a closed, well typed term (that is, $\Gamma\vdash t: T$ for some type $T$). Then either $t$ is a value, or there is some $t'$ such that $t\longrightarrow t'$.

- For boolean constants, the proof is immediate as $t$ is a value
- For variables,  the proof is immediate as $t$ is closed, and the precondition therefore doesn't hold
- For abstraction, the proof is immediate as $t$ is a value
- Application is the only case we must treat.
  
  Consider $t = t_1\ t_2$, with $\Gamma\vdash t_1: T_{11} \rightarrow T_{12}$ and $\Gamma\vdash t_2: T_{11}$.

  By the induction hypothesis, $t_1$ is either a value, or it can make a step of evaluation. The same goes for $t_2$.

  If $t_1$ can reduce, then rule $\ref{eq:e-app1}$ applies to $t$. Otherwise, if it is a value, and $t_2$ can take a step, then $\ref{eq:e-app2}$ applies. Otherwise, if they are both values (and we cannot apply $\beta$-reduction), then the canonical forms lemma above tells us that $t_1$ has the form $\lambda x: T_11.\ t_{12}$, and so rule $\ref{eq:e-appabs}$ applies to $t$.


### Preservation
**Theorem**: If $\Gamma\vdash t: T$ and $t \longrightarrow t'$ then $\Gamma\vdash t': T$.

**Proof**: by induction on typing derivations. We proceed on a case-by-case basis, as we have done so many times before. But one case is hard: application.


For $t = t_1\ t_2$, such that $\Gamma\vdash t_1 : T_{11} \rightarrow T_{12}$ and $\Gamma\vdash t_2 : T_{11}$, and where $T=T_{12}$, we want to show $\Gamma\vdash t' : T_{12}$. 

To do this, we must use the [inversion lemma for evaluation](#inversion-lemma) (note that we haven't written it down for STLC, but the idea is the same). There are three subcases for it, starting with the following: 

The left-hand side is $t_1 = \lambda x: T_{11}.\ t_{12}$, and the right-hand side of application $t_2$ is a value $v_2$. In this case, we know that the result of the evaluation is given by $t' = \left[ x\mapsto v_2 \right] t_{12}$.

And here, we already run into trouble, because we do not know about how types act under substitution. We will therefore need to introduce some lemmas.

#### Weakening lemma
Weakening tells us that we can *add* assumptions to the context without losing any true typing statements:

If $\Gamma\vdash t: T$, and the environment $\Gamma$ has no information about $x$&mdash;that is, $x\notin \text{dom}(\Gamma)$&mdash;then the initial assumption still holds if we add information about $x$ to the environment:

$$
\bigl(\Gamma \cup (x: S)\bigr)\vdash t: T
$$

Moreover, the latter $\vdash$ derivation has the same depth as the former.

#### Permutation lemma
Permutation tells us that the order of assumptions in $\Gamma$ does not matter.

If $\Gamma \vdash t: T$ and $\Delta$ is a permutation of $\Gamma$, then $\Delta\vdash t: T$.

Moreover, the latter $\vdash$ derivation has the same depth as the former.

#### Substitution lemma
Substitution tells us that types are preserved under substitution.

That is, if $\Gamma\cup(x: S) \vdash t: T$ and $\Gamma\vdash s: S$, then $\Gamma\vdash \left[x\mapsto s\right] t: T$.

The proof goes by induction on the derivation of $\Gamma\cup(x: S) \vdash t: T$, that is, by cases on the final typing rule used in the derivation.

- Case $\ref{eq:t-app}$: in this case, $t = t_1\ t_2$. 
  
  Thanks to typechecking, we know that the environment validates $\bigl(\Gamma\cup (x: S)\bigr)\vdash t_1: T_2 \rightarrow T_1$ and $\bigl(\Gamma\cup (x: S)\bigr)\vdash t_2: T_2$. In this case, the resulting type of the application is $T=T_1$. 
   
   By the induction hypothesis, $\Gamma\vdash[x\mapsto s]t_1 : T_2 \rightarrow T_1$, and $\Gamma\vdash[x\mapsto s]t_2 : T_2$. 

   By $\ref{eq:t-app}$, the environment then also verifies the application of these two substitutions as $T$: $\Gamma\vdash[x\mapsto s]t_1\ [x\mapsto s]t_2: T$. We can factorize the substitution to obtain the conclusion, i.e. $\Gamma\vdash \left\[x\mapsto s\right\](t_1\ t_2): T$

- Case $\ref{eq:t-var}$: if $t=z$ ($t$ is a simple variable $z$) where $z: T \in \bigl(\Gamma\cup (x: S)\bigr)$. There are two subcases to consider here, depending on whether $z$ is $x$ or another variable:
    + If $z=x$, then $\left[x\mapsto s\right] z = s$. The result is then $\Gamma\vdash s: S$, which is among the assumptions of the lemma
    + If $z\ne x$, then $\left[x\mapsto s\right] z = z$, and the desired result is immediate
- Case $\ref{eq:t-abs}$: if $t=\lambda y: T_2.\ t_1$, with $T=T_2\rightarrow T_1$, and $\bigl(\Gamma\cup (x: S)\cup (y: T_2)\bigr)\vdash t_1 : T_1$.
  
  Based on our [hygiene convention](#alpha-conversion), we may assume $x\ne y$ and $y \notin \text{fv}(s)$. 

  Using [permutation](#permutation-lemma) on the first given subderivation in the lemma ($\Gamma\cup(x: S) \vdash t: T$), we obtain $\bigl(\Gamma\cup (y: T_2)\cup (x: S)\bigr)\vdash t_1 : T_1$ (we have simply changed the order of $x$ and $y$).

  Using [weakening](#weakening-lemma) on the other given derivation in the lemma ($\Gamma\vdash s: S$), we obtain $\bigl(\Gamma\cup (y: T_2)\bigr)\vdash s: S$.

  By the induction hypothesis, $\bigl(\Gamma\cup (y: T_2)\bigr)\vdash\left[x\mapsto s\right] t_1: T_1$.

  By $\ref{eq:t-abs}$, we have $\Gamma\vdash(\lambda y: T_2.\ [x\mapsto s]t_1): T_1$

  By the definition of substitution, this is $\Gamma\vdash([x\mapsto s]\lambda y: T_2.\ t_1): T_2 \rightarrow T_1$.

#### Proof
We've now proven the following lemmas:

- Weakening
- Permutation
- Type preservation under substitution
- Type preservation under reduction (i.e. preservation)

We won't actually do the proof, we've just set up the pieces we need for it.

### Erasure
Type annotations do not play any role in evaluation. In STLC, we don't do any run-time checks, we only run compile-time type checks. Therefore, types can be removed before evaluation. This often happens in practice, where types do not appear in the compiled form of a program; they're typically encoded in an untyped fashion. The semantics of this conversion can be formalized by an erasure function:

$$
\begin{align}
\text{erase}(x) & = x \\
\text{erase}(\lambda x: T_1. t_2) & = \lambda x. \text{erase}(t_2) \\
\text{erase}(t_1\ t_2) & = \text{erase}(t_1)\ \text{erase}(t_2)
\end{align}
$$

### Curry-Howard Correspondence
The Curry-Howard correspondence tells us that there is a correspondence between constructive logic and typed lambda-calculus with product and sum types.

An implication $P\supset Q$ (which could also be written $P\implies Q$) can be proven by transforming evidence for $P$ into evidence for $Q$. A conjunction $P\land Q$ is a [pair](#pairs-1) of evidence for $P$ and evidence for $Q$. For more examples of these correspondences, see the [Brouwer–Heyting–Kolmogorov (BHK) interpretation](https://en.wikipedia.org/wiki/Brouwer–Heyting–Kolmogorov_interpretation) or [Curry-Howard correspondence](https://en.wikipedia.org/wiki/Curry%E2%80%93Howard_correspondence) on Wikipedia.

| Logic                           | Programming languages                |
| :------------------------------ | :----------------------------------- |
| Propositions                    | Types                                |
| $P \supset Q$ or $P \implies Q$ | Function type $P\rightarrow Q$       |
| $P \land Q$                     | [Pair type](#pairs-1) $P\times Q$    |
| $P \lor Q$                      | [Sum type](#sum-type) $P+Q$          |
| $\exists x\in S: \phi(x)$       | Dependent type $\sum{x: S, \phi(x)}$ |
| $\forall x\in S: \phi(x)$       | $\forall (x:S): \phi(x)$             |
| Proof of $P$                    | Term $t$ of type $P$                 |
| $P$ is provable                 | Type $P$ is inhabited                |
| Proof simplification            | Evaluation                           |

In Scala, all types are inhabited except for the bottom type `Nothing`. Singleton types are only inhabited by a single term.

As an example of the equivalence, we'll see that application is equivalent to [modus ponens](https://en.wikipedia.org/wiki/Modus_ponens):

$$
\frac{\Gamma\vdash t_1 : P \supset Q \quad \Gamma\vdash t_2 : P}{\Gamma\vdash t_1\ t_2 : Q}
$$

This also tells us that if we can prove something, we can evaluate it.

How can we prove the following? Remember that $\rightarrow$ is right-associative.

$$
(A \land B) \rightarrow C \rightarrow ((C\land A)\land B)
$$

The proof is actually a somewhat straightforward conversion to lambda calculus:

$$
\lambda p: A\times B.\ \lambda c: C.\ \text{pair} (\text{pair} (c\ \text{fst}(p))\ \text{snd}(p))
$$

### Extensions to STLC

#### Base types
Up until now, we've defined our base types (such as $\text{Nat}$ and $\text{Bool}$) manually: we've added them to the syntax of types, with associated constants ($\text{zero}, \text{true}, \text{false}$) and operators ($\text{succ}, \text{pred}$), as well as associated typing and evaluation rules.

This is a lot of minutiae though, especially for theoretical discussions. For those, we can often ignore the term-level inhabitants of the base types, and just treat them as uninterpreted constants: we don't really need the distinction between constants and values. For theory, we can just assume that some generic base types (e.g. $B$ and $C$) exist, without defining them further.

#### Unit type
In C-like languages, this type is usually called `void`. To introduce it, we do not add any computation rules. We must only add it to the grammar, values and types, and then add a single typing rule that trivially verifies units.

$$
\Gamma\vdash\text{unit}:\text{Unit}
\label{eq:t-unit} \tag{T-Unit}
$$

Units are not too interesting, but *are* quite useful in practice, in part because they allow for other extensions.

#### Sequencing
We can define sequencing as two statements following each other:

{% highlight antlr linenos %}
t ::=
    ...
    t1; t2
{% endhighlight %}

This implies adding some evaluation and typing rules, defined below:

$$
\begin{align}
\frac{t_1 \longrightarrow t_1'}{t_1;\ t_2 \longrightarrow t_1';\ t_2}
\label{eq:e-seq}\tag{E-Seq} \\ \\

(\text{unit};\ t_2) \longrightarrow t_2
\label{eq:e-seqnext}\tag{E-SeqNext} \\ \\

\frac{\Gamma\vdash t_1 : \text{Unit} \quad \Gamma\vdash t_2: T_2}{\Gamma\vdash t_1;\ t_2 : T_2}
\label{eq:t-seq}\tag{T-Seq} \\
\end{align}
$$

But there's another way that we could define sequencing: simply as syntactic sugar, a derived form for something else. In this way, we define an external language, that is transformed to an internal language by the compiler in the desugaring step.

$$
t_1;\ t_2 \defeq (\lambda x: \text{Unit}.\ t_2)\ t_1
\qquad \text{where } x\notin\text{ FV}(t_2)
$$

This is useful to know, because it makes proving soundness much easier. We do not need to re-state the inversion lemma, re-prove preservation and progress. We can simple rely on the proof for the underlying internal language.

#### Ascription
{% highlight antlr linenos %}
t ::=
    ...
    t as T
{% endhighlight %}

Ascription allows us to have a compiler type-check a term as really being of the correct type:

$$
\frac{\Gamma\vdash t_1 : T}{\Gamma\vdash t_1 \text{ as } T: T}
\label{eq:t-ascribe}\tag{T-Ascribe}
$$

This seems like it preserves soundness, but instead of doing the whole proof over again, we'll just propose a simple desugaring, in which an ascription is equivalent to the term $t$ applied the identity function, typed to return $T$:

$$
t \text{ as } T \defeq (\lambda x: T.\ x)\ t
$$

Alternatively, we could do the whole proof over again, and institute a simple evaluation rule that ignores the ascription.

$$
v_1 \text{ as } T \longrightarrow v_1
\label{eq:e-ascribe}\tag{E-Ascribe} \\
$$


#### Pairs
We can introduce pairs into our grammar.

{% highlight antlr linenos %}
t ::= 
    ...
    {t, t}    // pair
    t.1       // first projection
    t.2       // second projection

v ::=
    ...
    {v, v}    // pair value

T ::=
    ...
    T1 x T2   // product types
{% endhighlight %}

Note that product types are right-associative: $A \times B \times C = A \times (B \times C)$. We can also introduce evaluation rules for pairs:

$$
\begin{align}
\set{v_1, v_2}.1 \longrightarrow v_1
\tag{E-PairBeta1}\label{eq:e-pairbeta1} \\ \\

\set{v_1, v_2}.2 \longrightarrow v_2
\tag{E-PairBeta2}\label{eq:e-pairbeta2} \\ \\

\frac{t_1 \longrightarrow t_1'}{t_1.1\longrightarrow t_1'.1}
\tag{E-Proj1}\label{eq:e-proj1} \\ \\

\frac{t_1 \longrightarrow t_1'}{t_1.2\longrightarrow t_1'.2}
\tag{E-Proj2}\label{eq:e-proj2} \\ \\

\frac{t_1 \longrightarrow t_1'}{\set{t_1, t_2} \longrightarrow \set{t_1', t_2}}
\tag{E-Pair1}\label{eq:e-pair1} \\ \\

\frac{t_2 \longrightarrow t_2'}{\set{t_1, t_2} \longrightarrow \set{t_1, t_2'}}
\tag{E-Pair2}\label{eq:e-pair2} \\ \\
\end{align}
$$

The typing rules are then:

$$
\begin{align}
\frac{
    \Gamma\vdash t_1: T_1 \quad \Gamma\vdash t_2: T_2
}{
    \Gamma\vdash \set{t_1, t_2} : T_1 \times T_2
} \label{eq:t-pair} \tag{T-Pair} \\ \\

\frac{\Gamma\vdash t_1 : T_{11}\times T_{12}}{\Gamma\vdash t_1.1:T_{11}}
\label{eq:t-proj1}\tag{T-Proj1} \\ \\

\frac{\Gamma\vdash t_1 : T_{11}\times T_{12}}{\Gamma\vdash t_1.2:T_{12}}
\label{eq:t-proj2}\tag{T-Proj2} \\ \\
\end{align}
$$

Pairs have to be added "the hard way": we do not really have a way to define them in a derived form, as we have no existing language features to piggyback onto.

#### Tuples
Tuples are like pairs, except that we do not restrict it to 2 elements; we allow an arbitrary number from 1 to n. We can use pairs to encode tuples: `(a, b, c)` can be encoded as `(a, (b, c))`. Though for performance and convenience, most languages implement them natively.

#### Records
We can easily generalize tuples to records by annotating each field with a label. A record is a bundle of values with labels; it's a map of labels to values and types. Order of records doesn't matter, the only index is the label. 

If we allow numeric labels, then we can encode a tuple as a record, where the index implicitly encodes the numeric label of the record representation. 

No mainstream language has language-level support for records (two case classes in Scala may have the same arguments but a different constructor, so it's not quite the same; records are more like anonymous objects). This is because they're often quite inefficient in practice, but we'll still use them as a theoretical abstraction.

### Sums and variants

#### Sum type
A sum type $T = T_1 + T_2$ is a *disjoint* union of $T_1$ and $T_2$. Pragmatically, we can have sum types in Scala with case classes extending an abstract object:

{% highlight scala linenos %}
sealed trait Option[+T]
case class Some[+T] extends Option[T]
case object None extends Option[Nothing]
{% endhighlight %}

In this example, `Option = Some + None`. We say that $T_1$ is on the left, and $T_2$ on the right. Disjointness is ensured by the tags $\text{inl}$ and $\text{inr}$. We can *think* of these as functions that inject into the left or right of the sum type $T$:

$$
\text{inl}: T_1 \rightarrow T_1 + T_2 \\
\text{inr}: T_2 \rightarrow T_1 + T_2
$$

Still, these aren't really functions, they don't actually have function type. Instead, we use them them to tag the left and right side of a sum type, respectively.

Another way to think of these stems from  [Curry-Howard correspondence](#curry-howard-correspondence). Recall that in the [BHK interpretation](https://en.wikipedia.org/wiki/Brouwer%E2%80%93Heyting%E2%80%93Kolmogorov_interpretation), a proof of $P \lor Q$ is a pair `<a, b>` where `a` is 0 (also denoted $\text{inl}$) and `b` a proof of $P$, *or* `a` is 1 (also denoted $\text{inr}$) and `b` is a proof of $Q$.

To use elements of a sum type, we can introduce a `case` construct that allows us to pattern-match on a sum type, allowing us to distinguishing the left type from the right one. 

We need to introduce these three special forms in our syntax:

{% highlight antlr linenos %}
t ::= ...                           // terms
    inl t                              // tagging (left)
    inr t                              // tagging (right)
    case t of inl x => t | inr x => t  // case

v ::= ... // values
    inl v   // tagged value (left)
    inr v   // tagged value (right)

T ::= ...  // types
    T + T     // sum type
{% endhighlight %}


This also leads us to introduce some new evaluation rules:

$$
\begin{align}
    \begin{rcases}
        \text{case } (& \text{inl } v_0) \text{ of} \\
                      & \text{inl } x_1 \Rightarrow t_1 \ \mid \\
                      & \text{inr } x_2 \Rightarrow t_2 \\
    \end{rcases} \longrightarrow [x_1 \mapsto v_0] t_1
    \label{eq:e-caseinl}\tag{E-CaseInl} \\ \\

    \begin{rcases}
        \text{case } (& \text{inr } v_0) \text{ of} \\
                      & \text{inl } x_1 \Rightarrow t_1 \ \mid \\
                      & \text{inl } x_2 \Rightarrow t_2 \\
    \end{rcases} \longrightarrow [x_2 \mapsto v_0] t_2
    \label{eq:e-caseinr}\tag{E-CaseInr} \\ \\

    \frac{t_0 \longrightarrow t_0'}{
        \begin{rcases}
            \text{case } & t_0 \text{ of} \\
                         & \text{inl } x_1 \Rightarrow t_1 \ \mid \\
                         & \text{inr } x_2 \Rightarrow t_2
        \end{rcases} \longrightarrow \begin{cases}
            \text{case } & t_0' \text{ of} \\
                         & \text{inl } x_1 \Rightarrow t_1 \ \mid \\
                         & \text{inr } x_2 \Rightarrow t_2
        \end{cases}
    } \label{eq:e-case}\tag{E-Case} \\ \\

\frac{t_1 \longrightarrow t_1'}{\text{inl }t_1 \longrightarrow \text{inl }t_1'}
\label{eq:e-inl}\tag{E-Inl} \\ \\

\frac{t_1 \longrightarrow t_1'}{\text{inr }t_1 \longrightarrow \text{inr }t_1'}
\label{eq:e-inr}\tag{E-Inr} \\ \\
\end{align}
$$

And we'll also introduce three typing rules:

$$
\begin{align}
\frac{\Gamma\vdash t_1 : T_1}{\Gamma\vdash\text{inl } t_1 : T_1 + T_2}
\label{eq:t-inl}\tag{T-Inl} \\ \\

\frac{\Gamma\vdash t_1 : T_2}{\Gamma\vdash\text{inr } t_1 : T_1 + T_2}
\label{eq:t-inr}\tag{T-Inr} \\ \\

\frac{
    \Gamma\vdash t_0 : T_1 + T_2 \quad
    \Gamma\cup(x_1: T_1) \vdash t_1 : T \quad
    \Gamma\cup(x_2: T_2) \vdash t_2 : T
}{
    \Gamma\vdash\text{case } t_0 \text{ of inl } x_1 \Rightarrow t_1 \mid \text{inr } x_2 \Rightarrow t_2 : T
}
\label{eq:t-case}\tag{T-Case} \\
\end{align}
$$

#### Sums and uniqueness of type
The rules $\ref{eq:t-inr}$ and $\ref{eq:t-inl}$ may seem confusing at first. We only have one type to deduce from, so what do we assign to $T_2$ and $T_1$, respectively? These rules mean that we have lost uniqueness of types: if $t$ has type $T$, then $\text{inl } t$ has type $T+U$ **for every** $U$.

There are a couple of solutions to this:

1. We can infer $U$ as needed during typechecking
2. Give constructors different names and only allow each name to appear in one sum type. This requires generalization to [variants](#variants), which we'll see next. OCaml adopts this solution.
3. Annotate each inl and inr with the intended sum type.

For now, we don't want to look at type inference and variance, so we'll choose the third approach for simplicity. We'll introduce these annotation as ascriptions on the injection operators in our grammar:

{% highlight antlr linenos %}
t ::=
    ...
    inl t as T
    inr t as T

v ::=
    ...
    inl v as T
    inr v as T
{% endhighlight %}

The evaluation rules would be exactly the same as previously, but with ascriptions in the syntax. The injection operators just now also specify *which* sum type we're injecting into, for the sake of uniqueness of type.

#### Variants
Just as we generalized binary products to labeled records, we can generalize binary sums to labeled variants. We can label the members of the sum type, so that we write $\langle l_1: T_1, l_2: T_2 \rangle$ instead of $T_1 + T_2$ ($l_1$ and $l_2$ are the labels). 

As a motivating example, we'll show a useful idiom that is possible with variants, the optional value. We'll use this to create a table. The example below is just like in OCaml.

{% highlight scala linenos %}
OptionalNat = <none: Unit,  some: Nat>;
Table = Nat -> OptionalNat;
emptyTable = λt: Nat. <none=unit> as OptionalNat;

extendTable = 
    λt: Table. λkey: Nat. λval: Nat.
        λsearch: Nat.
            if (equal search key) then <some=val> as OptionalNat
            else (t search)
{% endhighlight %}

The implementation works a bit like a linked list, with linear look-up. We can use the result from the table by distinguishing the outcome with a `case`:

{% highlight scala linenos %}
x = case t(5) of
    <none=u> => 999
  | <some=v> => v
{% endhighlight %}

### Recursion 
In STLC, all programs terminate. We'll [go into a little more detail later](#strong-normalization), but the main idea is that evaluation of a well-typed program is guaranteed to halt; we say that the well-typed terms are *normalizable*. 

Indeed, the infinite recursions from untyped lambda calculus (terms like $\text{omega}$ and $\text{fix}$) are not typable, and thus cannot appear in STLC. Since we can't express $\text{fix}$ in STLC, instead of defining it as a term in the language, we can add it as a primitive instead to get recursion.

{% highlight antlr linenos %}
t ::=
    ...
    fix t
{% endhighlight %}

We'll need to add evaluation rules recreating its behavior, and a typing rule that restricts its use to the intended use-case.

$$
\begin{align}
\text{fix } (\lambda x: T_1.\ t_2) \longrightarrow \left[
    x\mapsto (\text{fix }(\lambda x: T_1.\ t_2))
\right] t_2
\label{eq:e-fixbeta}\tag{E-FixBeta} \\ \\

\frac{t_1 \longrightarrow t_1'}{\text{fix }t_1 \longrightarrow \text{fix }t_1'}
\label{eq:e-fix}\tag{E-Fix} \\ \\

\frac{\Gamma\vdash t_1 : T_1 \rightarrow T_1}{\Gamma\vdash\text{fix }t_1:T_1}
\label{eq:t-fix}\tag{T-Fix}
\end{align}
$$

In order for a function to be recursive, the function needs to map a type to the same type, hence the restriction of $T_1 \rightarrow T_1$. The type $T_1$ will itself be a function type if we're doing a recursion. Still, note that the type system doesn't enforce this. There will actually be situations in which it will be handy to use something else than a function type inside a fix operator. 

Seeing that this fixed-point notation can be a little involved, we can introduce some nice syntactic sugar to work with it:

$$
\text{letrec } x: T_1 = t_1 \text{ in } t_2
\quad \defeq \quad
\text{let } x = \text{fix } (\lambda x: T_1.\ t_1) \text{ in } t_2
$$

This $t_1$ can now refer to the $x$; that's the convenience offered by the construct. Although we don't strictly need to introduce typing rules (it's syntactic sugar, we're relying on existing constructs), a typing rule for this could be:

$$
\frac{\Gamma\cup(x:T_1)\vdash t_1:T_1 \quad \Gamma\cup(x: T_1)\vdash t_2:T_2}{\Gamma\vdash\text{letrec } x: T_1 = t_1 \text{ in } t_2:T_2}
$$

In Scala, a common error message is that a recursive function needs an explicit return type, for the same reasons as the typing rule above.

### References
#### Mutability 
In most programming languages, variables are (or can be) mutable. That is, variables can provide a name referring to a previously calculated value, as well as a way of overwriting this value with another (under the same name). How can we model this in STLC?

Some languages (e.g. OCaml) actually formally separate variables from mutation. In OCaml, variables are only for naming, the binding between a variable and a value is immutable. However, there is the concept of *mutable values*, also called *reference cells* or *references*. This is the style we'll study, as it is easier to work with formally. A mutable value is represented in the type-level as a `Ref T` (or perhaps even a `Ref(Option T)`, since the null pointer cannot produce a value).

The basic operations are allocation with the `ref` operator, dereferencing with `!` (in C, we use the `*` prefix), and assignment with `:=`, which updates the content of the reference cell. Assignment returns a `unit` value.

#### Aliasing
Two variables can reference the same cell: we say that they are *aliases* for the same cell. Aliasing is when we have different references (under different names) to the same cell. Modifying the value of the reference cell through one alias modifies the value for all other aliases.

The possibility of aliasing is all around us, in object references, explicit pointers (in C), arrays, communication channels, I/O devices; there's practically no way around it. Yet, alias analysis is quite complex, costly, and often makes is hard for compilers to do optimizations they would like to do.

With mutability, the order of operations now matters; `r := 1; r := 2` isn't the same as `r := 2; r := 1`. If we recall the [Church-Rosser theorem](#confluence-in-full-beta-reduction), we've lost the principle that all reduction paths lead to the same result. Therefore, some language designers disallow it (Haskell). But there are benefits to allowing it, too: efficiency, dependency-driven data flow (e.g. in GUI), shared resources for concurrency (locks), etc. Therefore, most languages provide it.

Still, languages without mutability have come up with a bunch of abstractions that allow us to have some of the benefits of mutability, like monads and lenses.

#### Typing rules
We'll introduce references as a type `Ref T` to represent a variable of type `T`. We can construct a reference as `r = ref 5`, and access the contents of the reference using `!r` (this would return `5` instead of `ref 5`).

Let's define references in our language:

{% highlight antlr linenos %}
t ::=          // terms
    unit          // unit constant
    x             // variable
    λx: T. t      // abstraction
    t t           // application
    ref t         // reference creation
    !t            // dereference
    t := t        // assignment
{% endhighlight %}

$$
\begin{align}
\frac{\Gamma\vdash t_1 : T_1}{\Gamma\vdash \text{ref } t_1 : \text{Ref } T_1}
\label{eq:t-ref}\tag{T-Ref} \\ \\

\frac{\Gamma\vdash t_1: \text{Ref } T_1}{\Gamma\vdash !t_1 : T_1}
\label{eq:t-deref}\tag{T-Deref} \\ \\

\frac{\Gamma\vdash t_1 : \text{Ref } T_1 \quad \Gamma\vdash t_2: T_1}{\Gamma\vdash t_1 := t_2 : \text{Unit}}
\label{eq:t-assign}\tag{T-Assign} \\ \\
\end{align}
$$

#### Evaluation
What is the *value* of `ref 0`? The crucial observation is that evaluation `ref 0` must *do* something. Otherwise, the two following would behave the same:

{% highlight c linenos %}
r = ref 0
s = ref 0

r = ref 0 
s = r
{% endhighlight %}

Evaluating `ref 0` should allocate some storage, and return a reference (or pointer) to that storage. A reference names a location in the **store** (also known as the *heap*, or just *memory*). Concretely, the store could be an array of 8-bit bytes, indexed by 32-bit integers. More abstractly, it's an array of values, or even more abstractly, a partial function from locations to values.

We can introduce this idea of locations in our syntax. This syntax is exactly the same as the previous one, but adds the notion of locations:

{% highlight antlr linenos %}
v ::=         // values
    unit         // unit constant
    λx: T. t     // abstraction value
    l            // store location

t ::=         // terms
    unit         // unit constant
    x            // variable
    λx: T. t     // abstraction
    t t          // application
    ref t        // reference creation
    !t           // dereference
    t := t       // assignment
    l            // store location 
{% endhighlight %}

This doesn't mean that we'll allow programmers to write explicit locations in their programs. We just use this as a modeling trick; we're enriching the internal language to include some run-time structures.

With this added notion of stores and locations, the result of an evaluation now depends on the store in which it is evaluated, which we need to reflect in our evaluation rules. Evaluation must now include terms $t$ **and** store $\mu$:

$$
t \mid \mu \longrightarrow t' \mid \mu'
$$

Let's take a look for the evaluation rules for STLC with references, operator by operator.

$$
\begin{align}
\frac{t_1 \mid \mu \longrightarrow t_1'\mid\mu'}{t_1 := t_2 \mid \mu \longrightarrow t_1' := t_2 \mid \mu'}
\label{eq:e-assign1}\tag{E-Assign1} \\ \\

\frac{t_2 \mid \mu \longrightarrow t_2'\mid\mu'}{t_1 := t_2 \mid \mu \longrightarrow t_1 := t_2' \mid \mu'}
\label{eq:e-assign2}\tag{E-Assign2} \\ \\

l := v_2 \mid \mu \longrightarrow \text{unit}\mid[l\mapsto v_2]\mu
\label{eq:e-assign}\tag{E-Assign} \\ \\
\end{align}
$$

The assignments $\ref{eq:e-assign1}$ and $\ref{eq:e-assign2}$ evaluate terms until they become values. When they have been reduced, we can do that actual assignment: as per $\ref{eq:e-assign}$, we update the store and return return `unit`.

$$
\begin{align}
\frac{t_1 \mid \mu \longrightarrow t_1' \mid \mu'}{\text{ref } t_1 \mid \mu \longrightarrow \text{ref } t_1' \mid \mu'}
\label{eq:e-ref}\tag{E-Ref} \\ \\

\frac{l \notin \text{dom}(\mu)}{\text{ref } v_1 \mid \mu \longrightarrow l \mid (\mu \cup (l\mapsto v_1))}
\label{eq:e-refv}\tag{E-RefV}
\end{align}
$$

A reference $\text{ref }t_1$ first evaluates $t_1$ until it is a value ($\ref{eq:e-ref}$). To evaluate the reference operator, we find a fresh location $l$ in the store, to which it binds $v_1$, and it returns the location $l$.

$$
\begin{align}
\frac{t_1 \mid \mu \longrightarrow t_1' \mid \mu'}{!t_1 \mid \mu \longrightarrow !t_1' \mid \mu'}
\label{eq:e-deref}\tag{E-Deref} \\ \\

\frac{\mu(l) = v}{!l\mid\mu \longrightarrow v\mid\mu}
\label{eq:e-derefloc}\tag{E-DerefLoc}
\end{align}
$$

We find the same congruence rule as usual in $\ref{eq:e-deref}$, where a term $!t_1$ first evaluates $t_1$ until it is a value. Once it is a value, we can return the value in the current store using $\ref{eq:e-derefloc}$.

The evaluation rules for abstraction and application are augmented with stores, but otherwise unchanged.

#### Store typing
What is the type of a location? The answer to this depends on what is in the store. Unless we specify it, a store could contain anything at a given location, which is problematic for typechecking. The solution is to type the locations themselves. This leads us to a typed store:

$$
\begin{align}
\mu = (& l_1 \mapsto \text{Nat}, \\
       & l_2 \mapsto \lambda x: \text{Unit}. x)
\end{align}
$$

As a first attempt at a typing rule, we can just say that the type of a location is given by the type of the value in the store at that location:

$$
\frac{\Gamma\vdash\mu(l) : T_1}{\Gamma\vdash l : \text{Ref } T_1}
$$

This is problematic though; in the following, the typing derivation for $!l_2$ would be infinite because we have a cyclic reference:

$$
\begin{align}
\mu =\ (& l_1 \mapsto \lambda x: \text{Nat}.\ !l_2\ x, \\
        & l_2 \mapsto \lambda x: \text{Nat}.\ !l_1\ x)
\end{align}
$$

The core of the problem here is that we would need to recompute the type of a location every time. But shouldn't be necessary. Seeing that references are strongly typed as `Ref T`, we know exactly what type of value we can place in a given store location. Indeed, the typing rules we chose for references guarantee that a given location in the store always is used to hold values of the same type.

So to fix this problem, we need to introduce a **store typing**. This is a partial function from location to types, which we'll denote by $\Sigma$. 

Suppose we're given a store typing $\Sigma$ describing the store $\mu$. We can use $\Sigma$ to look up the types of locations, without doing a lookup in $\mu$:

$$
\frac{\Sigma(l) = T_1}{\Gamma\mid\Sigma\vdash l : \text{Ref } T_1}
\label{eq:t-loc}\tag{T-Loc}
$$

This tells us how to check the store typing, but how do we create it? We can start with an empty typing $\Sigma = \emptyset$, and add a typing relation with the type of $v_1$  when a new location is created during evaluation of $\ref{eq:e-refv}$.

The rest of the typing rules remain the same, but are augmented with the store typing. So in conclusion, we have updated our evaluation rules with a *store* $\mu$, and our typing rules with a *store typing* $\Sigma$.

#### Safety
Let's take a look at progress and preservation in this new type system. Preservation turns out to be more interesting, so let's look at that first.

We've added a store and a store typing, so we need to add those to the statement of preservation to include these. Naively, we'd write:

$$
\Gamma\mid\Sigma\vdash t: T \text{ and }
t\mid\mu\longrightarrow t'\mid\mu'
\quad \implies \quad 
\Gamma\mid\Sigma\vdash t': T
$$

But this would be wrong! In this statement, $\Sigma$ and $\mu$ would not be constrained to be correlated at all, which they need to be. This constraint can be defined as follows:

A store $\mu$ is well typed with respect to a typing context $\Gamma$ and a store typing $\Sigma$ (which we denote by $\Gamma\mid\Sigma\vdash\mu$) if the following is satisfied:

$$
\text{dom}(\mu) = \text{dom}(\Sigma)
\quad \text{and} \quad 
\Gamma\mid\Sigma\vdash\mu(l) : \Sigma(l),\ \forall l\in\text{dom}(\mu)
$$

This gets us closer, and we can write the following preservation statement:

$$
\Gamma\mid\Sigma \vdash t : T \text{ and }
t\mid\mu \longrightarrow t'\mid\mu \text{ and }
\Gamma\mid\Sigma \vdash \mu
\quad \implies \quad
\Gamma\mid\Sigma\vdash t' : T
$$

But this is still wrong! When we create a new cell with $\ref{eq:e-refv}$, we would break the correspondence between store typing and store.

The correct version of the progress theorem is the following:

$$
\Gamma\mid\Sigma \vdash t : T \text{ and }
t\mid\mu \longrightarrow t'\mid\mu \text{ and }
\Gamma\mid\Sigma \vdash \mu
\quad \implies \quad
\text{for some } \Sigma' \supseteq \Sigma, \;\;
\Gamma\mid\Sigma'\vdash t' : T
$$

This progress theorem just asserts that there is *some* store typing $\Sigma' \supseteq \Sigma$ (agreeing with $\Sigma$ on the values of all old locations, but that may have also add new locations), such that $t'$ is well typed in $\Sigma'$.

The progress theorem must also be extended with stores and store typings:

Suppose that $t$ is a closed, well-typed term; that is, $\emptyset\mid\Sigma\vdash t: T$ for some type $T$ and some store typing $\Sigma$. Then either $t$ is a value or else, for any store $\mu$ such that $\emptyset\mid\Sigma\vdash\mu$[^well-typed-store-notation], there is some term $t'$ and store $\mu'$ with $t\mid\mu \longrightarrow t'\mid\mu'$.

[^well-typed-store-notation]: Recall that this notation is used to say a store $\mu$ is well typed with respect to a typing context $\Gamma$ and a store typing $\Sigma$, as defined in the section on [safety in STLC with stores](#safety).

## Type reconstruction and polymorphism
In type checking, we wanted to, given $\Gamma$, $t$ and $T$, check whether $\Gamma\vdash t: T$. So far, for type checking to take place, we required explicit type annotations.

In this section, we'll look into **type reconstruction**, which allows us to infer types when type annotations aren't present: given $\Gamma$ and $t$, we want to find a type $T$ such that $\Gamma\vdash t:T$.

Immediately, we can see potential problems with this idea:

- Abstractions without the parameter type annotation seem complicated to reconstruct (a parameter could almost have any type)
- A term can have  many types

To solve these problems, we'll introduce polymorphism into our type system.

### Constraint-based Typing Algorithm
The idea is to split the work in two: first, we want to generate and record constraints, and then, unify them (that is, attempt to satisfy the constraints).

In the following, we'll denote constraints as a set of equations $\set{T_i \hat{=} U_i}_{i=1, \dots, m}$, constraining type variables $T_i$ to actual types $U_i$.

#### Constraint generation
The constraint generation algorithm can be described as the following function $TP: \text{Judgment} \rightarrow \text{Equations}$

{% highlight pseudo linenos %}
TP: Judgment -> Equations
TP(Γ ⊦ t : T) = case t of
    x     :    {Γ(x) ^= T}

    λx. t1:    let a, b fresh in
               {(a -> b) ^= T} ∪
               TP(Γ, (x: a) ⊦ t1 : b)

    t1 t2 :    let a fresh in
               TP(Γ ⊦ t1 : a -> T) ∪
               TP(Γ ⊦ t2 : a)
{% endhighlight %}

This creates a set of constraints between type variables and the expected types.

The above essentially gives us constraint generation rules in algorithmic form. An alternative notation is as to give the set of constraint typing relations, which are denoted as:

$$
\Gamma \vdash t: T \mid_\chi C
$$

This can be read as "a term $t$ has type $T$ in the environment $\Gamma$ whenever constraints $C$ with type variables $\chi$ are satisfied". The $\chi$ subscript keeps track of the fresh variables created in the various subderivations, and ensures that they are distinct. 

The implementation we gave above could also be described by the following constraint generation rules:

$$
\begin{align}
\frac{
    x : T \in \Gamma
}{
    \Gamma \vdash x: T \mid_\emptyset \set{ }
} \label{eq:ct-var}\tag{CT-Var}
\\ \\
\frac{
    \Gamma\cup(x: T_1) \vdash t_2 : T_2 \mid_\chi C
}{
    \Gamma\vdash \lambda x: T_1.\ t_2 : T_1 \rightarrow T_2 \mid_\chi C
} \label{eq:ct-abs}\tag{CT-Abs}
\\ \\
\frac{
    \Gamma \vdash t_1 : T_1 \mid_{\chi_1} C_1
    \quad
    \Gamma \vdash t_2 : T_2 \mid_{\chi_2} C_2
}{
    \Gamma \vdash t_1 \ t_2 : X 
    \mid_{\chi_1\cup\chi_2\cup\set{X}} 
    C_1 \cup C_2 \cup \set{T_1 \ \hat{=} \  T_2 \rightarrow X}
} \label{eq:ct-app}\tag{CT-App}
\end{align}
$$

We haven't explicitly written it in $\ref{eq:ct-app}$, but we expect $\chi_1$ and $\chi_2$ to be distinct (i.e. $\chi_1 \cap \chi_2 = \emptyset$), and we expect $X$ to be fresh (i.e. not clash with anything else).

#### Soundness and completeness
In general a type reconstruction algorithm $\mathcal{A}$ assigns to an environment $\Gamma$ and a term $t$ a set of types $\mathcal{A}(\Gamma, t)$.

The algorithm is **sound** if for every type $T\in \mathcal{A}(\Gamma, t)$ we can prove the judgment $\Gamma\vdash t: T$.

The algorithm is **complete** if for every provable judgment $\Gamma\vdash t: T$ we have $T\in\mathcal{A}(\Gamma, t)$.

Soundness and completeness are the two directions of the following implication:

$$
\text{the algorithm can prove it} \iff \text{it holds}
$$

Soundness and completeness are about the $\Leftarrow$ and $\Rightarrow$ directions of the above, respectively. The TP function we defined previously for STLC is sound and complete, and the relationship is thus $\iff$. We can write this mathematically as follows:

$$
\Gamma\vdash t: T \iff \exists \bar{b} \text{ s.t. } [a\mapsto T] EQNS
$$

Where:

- $a$ is a new type variable
- $EQNS = TP(\Gamma\vdash t: a)$ is the set of type constraints
- $\bar{b} = \text{tv}(EQNS)\setminus\text{tv}(\Gamma)$, where $\text{tv}$ denotes the set of free type variables.
- $[a \mapsto T] EQNS$ is notation for replacing $a$ with $T$ in $EQNS$

#### Substitutions
Now that we've generated a constraint set in the form $C = \set{T_i\ \hat{=}\ U_i}_{i=1, \dots, m}$, we'd like a way to substitute these constraints into real types. We must generate a set of substitutions:

$$
s = \set{a_j \mapsto T_j'}_{j=1, \dots, n}
$$

These substitutions cannot be cyclical. The type variables may not appear recursively on their right-hand side (directly or indirectly). We can write this requirement as:

$$
a_j \notin \text{tv}(T_k') \quad \text{for } j=1,\dots, n, \ k = j, \dots n
$$

This substitution is an idempotent mapping from type variables to types, mapping all but a finite number of type variables to themselves. We can think of a substitution as a set of equations:

$$
\set{a\ \hat{=}\ T}, \quad a \notin \text{tv}(T)
$$

Alternatively, we can think of it as a function transforming types (based on the set of equations). Substitution is applied in a straightforward way:

$$
\begin{align}
s(X)  & = \begin{cases}
    T & \text{if } (X \mapsto T) \in s \\
    X & \text{otherwise}
\end{cases} \\
s(\text{Nat})         & = \text{Nat} \\
s(\text{Bool})        & = \text{Bool} \\
s(T \rightarrow U)    & = sT \rightarrow sU \\
\end{align}
$$

Substitution has two properties:

- **Idempotence**: $s(s(T)) = s(T)$
- **Composition**: $(f \circ g)\ x = f(g\ x)$, the composition of substitutions, is also a substitution

The composition of two substitutions $f$ and $g$ is:

$$
f \circ g = \begin{bmatrix}
X \mapsto f(T) & \text{for each } (X \mapsto T) \in g \\
X \mapsto T    & \text{for each } (X \mapsto T) \in f \text{ with } X \notin dom(g) \\
\end{bmatrix}
$$

Essentially, if $g$ modifies $X$, we apply the $f$ substitution on top of $g(X)$. If it leaves it unchanged, the result is just $f(X)$.

#### Unification
We present a unification algorithm based on Robinson's 1965 unification algorithm:

{% highlight pseudo linenos %}
mgu                      : (Type ^= Type) -> Subst -> Subst
mgu(T ^= U) s            = mgu'(sT ^= sU) s

mgu'(a ^= a) s           = s
mgu'(a ^= T) s           = s ∪ {a → T} if a ∉ tv(T)
mgu'(T ^= T) s           = s ∪ {a → T} if a ∉ tv(T)
mgu'(T -> T' ^= U -> U') = (mgu(T' ^= U') ◦ mgu(T ^= U)) s
mgu'(K[T1, ..., Tn] ^= K[U1, ..., Un]) s
                         = (mgu(Tn ^= Un) ◦ ... ◦ mgu(T1 ^= U1)) s
mgu'(T ^= U) s           = error
{% endhighlight %}

This function is called $\text{mgu}$, which stands for most general unifier.

A substitution $u$ is a **unifier** of a set of equations $\set{T_i\ \hat{=}\ U_i}$ if $uT_i = uU_i,\, \forall i$. This means that it can find an assignment to the type variables in the constraints so that all equations are trivially true.

The substitution is a **most general unifier** if for every other unifier $u'$ of the same equations, there exists a substitution $s$ such that $u' = s\circ u$. In other words, it must be less specific (or more general) than all other unifiers.

If we give the following piece of code to a most general unifier, $f$ will be typed as $\forall a. a \rightarrow a$, and not $\text{Int}\rightarrow\text{Int}$ (more on universal types in [the next chapter](#polymorphism)). Both would be correct, but the former would be most general.

{% highlight text linenos %}
let f = (λx. x) in f(3)
{% endhighlight %}

We won't prove this, but just state it as a theorem: if we get a set of constraints $\text{EQNS}$ which has a unifier, then $\text{mgu EQNS} \set{}$ computes the most general unifier of the constraints. If the constraints do not have a unifier, it fails. 

In other words, the TP function is sound and complete.

#### Single-pass unification
Previously, we defined constraint generation. Once we had *all* the constraints, we passed them on to the unifier, which attempted to find a most general substitution satisfying the constraints.

In practice, however, it's more common to merge the two, and to unify earlier. This allows us to eliminate some constraints early (which is good for performance), but also to get better error reporting.

{% highlight pseudo linenos %}
TP: Judgment -> Subst -> Subst
TP(Γ ⊦ t : T) = case t of
    x     :    mgu({Γ(x) ^= T})

    λx. t1:    let a, b fresh in
               mgu({(a -> b) ^= T}) ◦
               TP(Γ, (x: a) ⊦ t1 : b)

    t1 t2 :    let a fresh in
               TP(Γ ⊦ t1 : a -> T) ◦
               TP(Γ ⊦ t2 : a)
{% endhighlight %}

This works because `mgu` is the *most general* unifier, meaning that it only generates principal types ([more on these later](#principal-types)) at each step. The means that the algorithm never needs to re-analyze a subterm, as it only makes the minimum commitments to achieve typability at each step. 

#### Strong normalization
With this typing inference in place, we can be tempted to try to run this on the diverging $\Omega$ that [we defined much earlier](#recursion-in-lambda-calculus), or perhaps on the [Y combinator](#recursion-in-lambda-calculus). But as we said before, self-application is not typable. In fact, we can state a stronger assertion:

**Strong Normalization Theorem**: if $\vdash t: T$, then there is a value $V$ such that $t \longrightarrow^* V$.

In other words, if we can type it, it reduces to a value. In the case of the infinite recursion, we cannot type it, and it does not evaluate to a value (instead, it diverges). So looping infinitely isn't possible in STLC, which leads us to the corollary of this theorem: **STLC is not Turing complete**.

### Polymorphism
There are multiple forms of polymorphism:

- **Universal polymorphism** (aka *generic types*): the ability to instantiate type variables
- **Inclusion polymorphism** (aka *subtying*): the ability to treat a value of a subtype as a value of one of its supertypes
- **Ad-hoc** (aka *overloading*): the ability to define several versions of the same function name with different types.

We'll concentrate on universal polymorphism, of which there are to variants: explicit and implicit. 

#### Explicit polymorphism
In STLC, a term can have many types, but a variable or parameter only has one type. With polymorphism, we open this up: we allow functions to be applied to arguments of many types. The resulting system is known as **System F**.

To do this, we can introduce a type abstraction with $\Lambda$: this does the same thing as a regular $\lambda$, except that it takes a type. For instance, we could build a polymorphic identity function:

$$
\text{id} = \Lambda X.\ \lambda x: X.\ x
$$

Application is like before, except that we write the type in square brackets $[T]$ (like in Scala, where we use `[T]`, or `<T>` in Java). For instance, to get the identity function for natural numbers, we write:

$$
\text{id } [\text{Nat}]
$$

This returns $\lambda x: \text{Nat}.\ x$, which is an instance of the polymorphic function.

The type of the $\Lambda$ abstraction is written as $\forall X.\ X \rightarrow X$. This polymorphic type notation $\forall a.T$ can be used as any other type. The typing rules are:

$$
\begin{align}
\frac{\Gamma\vdash t: \forall a.T}{\Gamma\vdash t[U] : [a \mapsto U] T}
\label{eq:polymorphic-app}\tag{$\forall$E} \\ \\

\frac{\Gamma\vdash t: T}{\Gamma\vdash\Lambda a.t : \forall a.T}
\label{eq:polymorphic-abs}\tag{$\forall$I} \\ \\
\end{align}
$$

For instance, the signature of `map` could be written as follows in Scala:

{% highlight scala linenos %}
def map[A][B](f: A => B)(xs: List[A]) = ...
{% endhighlight %}

In System F we'd write:

$$
\Lambda X.\ \Lambda Y.\ \lambda f: X\rightarrow Y.\ \lambda xs: \text{List }[X].\ \dots
$$

#### Implicit polymorphism
An alternative type system is **Hindley-Milner**, which does not require annotations for parameter types, and instead opts for implicit polymorphism. The idea is that inference treats unannotated named values (i.e. `let ... in ...` statements) as polymorphic types. This explains why this feature is also known as *let-polymorphism*.

To have this feature, we must introduce the notion of **type schemes**. These are not fully general types, but are an internal construct used to type let expressions. A type scheme has the following syntax:

$$
S ::= T \mid \forall a. S
$$

Not that a plain type is a type scheme, but that we can also add an arbitrary number of universal type arguments $\forall a.$ before it. 

The typing rules for the Hindley-Milner are given below. Here, we always use $S$ as a metavariable for type schemes, and $T$ and $U$ for plain (non-polymorphic) types.

$$
\begin{align}
\Gamma \cup (x: S) \cup \Gamma' \vdash x: S, \quad x\notin\text{dom}(\Gamma')
\label{eq:hm-var}\tag{Var} \\ \\

\frac{\Gamma\vdash t: \forall a. T}{\Gamma\vdash t: [a \mapsto U]T}
\label{eq:hm-forall-e}\tag{$\forall E$} \\ \\

\frac{\Gamma\vdash t: T \quad a\notin \text{tv}(\Gamma)}{\Gamma\vdash \forall a.T}
\label{eq:hm-forall-i}\tag{$\forall I$} \\ \\

\frac{\Gamma\vdash t: S \quad \Gamma\cup(x: S)\vdash t' : T}
{\Gamma \vdash \text{let } x = t \text{ in } t': T}
\label{eq:hm-let}\tag{Let} \\ \\

\frac{\Gamma\cup(x: T)\vdash t: T}{\Gamma\vdash\lambda x. t: T \rightarrow U}
\label{eq:hm-arrow-i}\tag{$\rightarrow I$} \\ \\

\frac{\Gamma\vdash t_1: T \rightarrow U \quad \Gamma\vdash t_2: T}{\Gamma\vdash t_1\ t_2: U}
\label{eq:hm-arrow-e}\tag{$\rightarrow E$} \\
\end{align}
$$

$\ref{eq:hm-var}$ means that we can verify $x: S$ if $(x: S)$ is in the environment and it isn't overwritten later (in $\Gamma'$). This allows us to have some concept of scoping of variables.

$\ref{eq:hm-forall-e}$ allows to verify specific instances of a polymorphic type, and $\ref{eq:hm-forall-i}$ allows to generalize to a polymorphic type (with a hygiene condition telling us that the type variable we choose isn't already in the environment).

$\ref{eq:hm-let}$ is fairly straightforward. $\ref{eq:hm-arrow-i}$ and $\ref{eq:hm-arrow-e}$ are simply as in STLC.


#### Alternative Hindley Milner
A let-in statement can be regarded as shorthand for a substitution:

$$
\text{let } x = t \text{ in } t' 
\quad \equiv \quad 
[x\mapsto t] t' 
$$

We can use this to get a revised Hindley-Milner system which we call HM', where $\ref{eq:hm-let}$ is replaced by the following:

$$
\frac{\Gamma\vdash t: T \quad \Gamma\vdash [x\mapsto t] t' : U}
{\Gamma \vdash \text{let } x = t \text{ in } t': U}
\label{eq:hm-let-prime}\tag{Let'}
$$

In essence, it only changes the typing rule for `let` so that they perform a step of evaluation before calculating the types. This is equivalent to the previous HM system; we'll state that as a theorem, without proof.

**Theorem**: $\Gamma\vdash_{\text{HM}} t: S \iff \Gamma\vdash_{\text{HM}'} t: S$

The corollary to this theorem is that, if we let $t^*$ be the result of expanding all `let`s in $t$ using the substitution above, then:

$$
\Gamma\vdash_{\text{HM}} t: T \Longrightarrow \Gamma\vdash_{F_1} t^* : T
$$

The converse is true if every let-bound name is used at least once:

$$
\Gamma\vdash_{\text{HM}} t: T \Longleftarrow \Gamma\vdash_{F_1} t^* : T
$$

### Principal types
We [previously remarked](#unification) that there is a most general unifier, which instantiates the type variables in the most general way, the *principal* way. Principal types are a small formalization of this idea.

A type $T$ is a **generic instance** of a type scheme $S = \forall \alpha_1.\  \dots \forall \alpha_n.\ T'$ if there is a substitution $s$ on $\alpha_1, \dots, \alpha_n$ such that $T = sT'$. In this case, we write $S \le T$. 

A type scheme $S'$ is a **generic instance** of a type scheme $S$ iff for all types $T$:

$$
S' \le T \implies S \le T
$$ 

In this case, we write $S \le S'$.

A type scheme $S$ is **principal** (or *most general*) for $\Gamma$ and $t$ iff:

- $\Gamma\vdash t: S$
- $\Gamma\vdash t: S' \implies S \le S'$

A type system TS has the **principal typing property** iff, whenever $\Gamma\vdash_{\text{TS}} t: S$, there exists a principal type scheme for $\Gamma$ and $t$.

In other words, a type system with principal types is one where the type engine doesn't make any choices; it always finds the most general solution. The type checker may fail if it cannot advance without making a choice (e.g. for $\lambda x. x+x$, where the typechecker would have to choose between $\text{Int} \rightarrow \text{Int}$, $\text{Float} \rightarrow \text{Float}$, etc).

The following can be stated as a theorem:

1. HM' without `let` has the principal typing property
2. HM' with `let` has the principal typing property
3. HM has the principal typing property

## Subtyping

### Motivation
Under $\ref{eq:t-app}$, the following is not well typed:

$$
(\lambda r.\ \set{x: \text{Nat}}.\ r.\!x)\ \set{x=0, y=1}
$$

We're passing a record to a function that selects its `x` member. This is not well typed, but would still evaluate just fine; after all, we're passing the function a *better* argument than it needs. 

In general, we'd like to be able to define hierarchies of classes, with descendants having richer interfaces. These should still be usable instead of their ancestors. We solve this using subtyping.

We achieve this by introducing a subtyping relation $S <: T$, and a **subsumption rule**:

$$
\frac{\Gamma\vdash t: S \quad S <: T}{\Gamma\vdash t: T}
\label{eq:t-sub}\tag{T-Sub}
$$

This rule tells us that if $S <: T$, then any value of type $S$ can also be regarded as having type $T$. With this rule in place, we just need to define the rules for when we can assert $S <: T$. 

### Rules

#### General rules
Subtyping is reflective and transitive:

$$
\begin{align}
S <: S
\label{eq:s-refl}\tag{S-Refl} \\ \\

\frac{S <: U \quad U <: T}{S <: T}
\label{eq:s-trans}\tag{S-Trans} \\ \\
\end{align}
$$


#### Records
To solve our previous example, we can introduce subtyping between record types:

$$
\set{x: \text{Nat}, y: \text{Nat}} <: \set{x: \text{Nat}}
$$

Using $\ref{eq:t-sub}$, we can see that our example is now well-typed. Of course, the subtyping rule we introduced here is too specific; we need something more general. We can do this by introducing three rules for subtyping of record types:

$$
\begin{align}
\set{l_i: {T_i}^{i\in 1\dots n+k}} <: \set{l_i: {T_i}^{i\in 1\dots n}}
\label{eq:s-rcdwidth}\tag{S-RcdWidth} \\ \\

\frac{
    \set{k_j : {S_j}^{j\in 1 \dots n}} \text{ is a permutation of } \set{l_i : {T_i}^{i\in 1 \dots n}}
}{
    \set{k_j : {S_j}^{j\in 1 \dots n}} <: \set{l_i : {T_i}^{i\in 1 \dots n}}
}
\label{eq:s-rcdperm}\tag{S-RcdPerm} \\ \\


\frac{
    \forall i \ S_i <: T_i
}{
    \set{l_i : {S_i}^{i\in 1\dots n}} <: \set{l_i: {T_i}^{i\in 1\dots n}}
}
\label{eq:s-rcddepth}\tag{S-RcdDepth} \\ \\
\end{align}
$$

$\ref{eq:s-rcdwidth}$ tells us that a record is a supertype of a record with additional fields to the right. Intuitively, the reason that the record *more* fields is a *subtype* of the record with fewer fields is because it places a stronger constraint on values, and thus describes fewer values (think of the Venn diagram of possible values).

Of course, adding fields to the right only is not strong enough of a rule, as order in a record shouldn't matter. We fix this with $\ref{eq:s-rcdperm}$, which allows us to reorder the record so that all additional fields are on the right: $\ref{eq:s-rcdperm}$, $\ref{eq:s-rcdwidth}$ and $\ref{eq:s-trans}$ allows us to drop arbitrary fields within records.

Finally, $\ref{eq:s-rcddepth}$ allows for the types of individual fields to be subtypes of the supertype record's fields.

Note that real languages often choose not to adopt these [structural record subtyping](#aside-structural-vs-declared-subtyping) rules. For instance, Java has no depth subtyping (a subclass may not change the argument or result types of a method of its superclass), no permutation for classes (single inheritance means that each member can be assigned a single index; new members can be added as new indices "on the right"), but has permutation for interfaces (multiple inheritance of interfaces is allowed). 

#### Arrow types
Function types are contravariant in the argument and covariant in the return type. The rule is therefore:

$$
\frac{T_1 <: S_1 \quad S_2 <: T_2}{S_1 \rightarrow S_2 <: T_1 \rightarrow T_2}
\label{eq:s-arrow}\tag{S-Arrow}
$$

#### Top type
For convenience, we have a top type that everything can be a subtype of. In Java, this corresponds to `Object`.

$$
S <: \text{Top}
\label{eq:s-top}\tag{S-Top}
$$

#### Aside: structural vs. declared subtyping
The [subtype relation we defined for records](#records-1) is *structural*: we decide whether $S$ is a subtype of $T$ by examining the structure of $S$ and $T$. By contrast, most OO languages (e.g. Java) use *declared* subtyping: $S$ is only a subtype of $T$ if the programmer has stated that it should be (with `extends` or `implements`).

We'll come back to this when we talk about [Featherweight Java](#featherweight-java).

### Properties of subtyping

#### Safety
The problem with subtyping is that it changes how we do proofs. They become a bit more involved, as the typing relation is no longer syntax directed; when we're proving things, we need to start making choices, as the rule $\ref{eq:t-sub}$ could appear anywhere. Still, the proofs are possible.

#### Inversion lemma for subtyping
Before we can prove safety and preservation, we'll introduce the inversion lemma for subtyping.

**Inversion Lemma**: If $U <: T_1 \rightarrow T_2$, then $U$ has the form $U_1 \rightarrow U_2$ with $T_1 <: U_1$ and $U_2 <: T_2$. 

The proof is by induction on subtyping derivations:

- Case $\ref{eq:s-arrow}$, $U=U_1 \rightarrow U_2$: immediate, as $U$ already has the correct form, and as we can deduce $T_1 <: U_1$ and $U_2 <: T_2$ from $\ref{eq:s-arrow}$.
- Case $\ref{eq:s-refl}$, $U=T_1 \rightarrow T_2$: by applying $\ref{eq:s-refl}$ twice, we get $T_1 <: T_1$ and $T_2 <: T_2$, as required.
- Case $\ref{eq:s-trans}$, $U <: W$ and $W <: T_1 \rightarrow T_2$
  
  By the IH on the second subderivation, we find that $W$ has the form $W_1 \rightarrow W_2$ with $T_1 <: W_1$ and $W_2 <: T_2$. 

  Applying the IH again to the first subderivation, we find that $U$ has the form $U_1 \rightarrow U_2$ with $W_1 <: U_1$ and $U_2 <: W_2$

  By $\ref{eq:s-trans}$, we get $T_1 <: U_1$, and by $\ref{eq:s-trans}$ again, $U_2 <: T_2$ as required

#### Inversion lemma for typing
We'll introduce another lemma, but this time for typing (not subtyping):

**Iversion lemma**: if $\Gamma\vdash\lambda x: S_1. s_2 : T_1 \rightarrow T_2$, then $T_1 <: S_1$ and $\Gamma\cup(x: S_1)\vdash s_2: T_2$.

Again, the proof is by induction on typing derivations:

- Case $\ref{eq:t-abs}$, where $T_1 = S_1$, $T_2 = S_2$ and $\Gamma\cup(x: S_1)\vdash s_2 : S_2$: the result is immediate (using $\ref{eq:s-refl}$ to get $T_1 <: S_1$ from $T_1 = S_1$).
- Case $\ref{eq:t-sub}$, $\Gamma\vdash\lambda x: X_1.\ s_2: U$ and $U <: T_1 \rightarrow T_2$
  
  By the [inversion lemma for subtyping](#inversion-lemma-for-subtyping), we have $U = U_1 \rightarrow U_2$, with $T_1 <: U_1$ and $U_2 <: T_2$.

  By the IH, we then have $U_1 <: S_1$ and $\Gamma\cup(x: S_1)\vdash s_2 : U_2$.

  We can apply $\ref{eq:s-trans}$ to $U_1 <: S_1$ and $T_1 <: U_1$ to get $T_1 <: S_1$.

  We can apply $\ref{eq:t-sub}$ to the assumptions that $\Gamma\cup(x: S_1)\vdash s_2: U_2$ and $U_2 <: T_2$ to conclude $\Gamma\cup(x: S_1)\vdash s_2: T_2$

#### Preservation
Remember that preservation states that if $\Gamma\vdash t: T$ and $t\longrightarrow t'$ then $\Gamma\vdash t': T$.

The proof is by induction on typing derivations:

- Case $\ref{eq:t-sub}$: $t: S$ and $S <: T$.
  
  By the IH, $\Gamma\vdash t': S$. 

  By $\ref{eq:t-sub}$, $\Gamma\vdash t: T$.

- Case $\ref{eq:t-app}$: $t = t_1\ t_2$, $\Gamma\vdash t_1: T_{11} \rightarrow T_{12}$, $\Gamma\vdash t_2: T_{11}$ and $T = T_{12}$. By the inversion lemma for evaluation[^inversion-lemma-evaluation-lambda], there are three rules by which $t\longrightarrow t'$ can be derived:
    + Subcase $\ref{eq:e-app1}$: $t_1 \longrightarrow t_1'$ and $t' = t_1'\ t_2$. The result follows from the IH and $\ref{eq:t-app}$
    + Subcase $\ref{eq:e-app2}$: $t_1 = v_1$, $t_2 \longrightarrow t_2'$ and $t' = v_1\ t_2'$. The result follows from the IH and $\ref{eq:t-app}$
    + Subcase $\ref{eq:e-appabs}$: $t_1 = \lambda x: S_{11}.\ t_{12}$, $t_2 = v_2$ and $t' = [x\mapsto v_2]t_{12}$.
      
      By the [inversion lemma for typing](#inversion-lemma-for-typing), $T_{11} <: S_{11}$ and $\Gamma\cup (x: S_{11})\vdash t_{12}: T_{12}$.

      By $\ref{eq:t-sub}$, $\Gamma\vdash t_2: S_{11}$

      By the [substitution lemma](#substitution-lemma), $\Gamma\vdash t': T_{12}$.

[^inversion-lemma-evaluation-lambda]: Both the course and TAPL only specify the inversion lemma for evaluation [for the toy language with if-else and booleans](#inversion-lemma), but the same reasoning applies to get an inversion lemma for evaluation for pure lambda calculus, in which three rules can be used: $\ref{eq:e-app1}$, $\ref{eq:e-app2}$ and $\ref{eq:e-appabs}$.


### Subtyping features
#### Casting
In languages like Java and C++, ascription is a little more interesting than [what we previously defined it as](#ascription). In these languages, ascription serves as a casting operator.

$$
\begin{align}
\frac{\Gamma\vdash t_1 : S}{\Gamma\vdash t_1 \text{ as } T : T}
\label{eq:t-cast}\tag{T-Cast} \\ \\

\frac{\vdash_r v_1: T}{v_1 \text{ as } T \longrightarrow v_1}
\label{eq:e-cast}\tag{E-Cast} \\
\end{align}
$$

Contrary to $\ref{eq:t-ascribe}$, the $\ref{eq:t-cast}$ rule allows the ascription to be of a different type than the term. This allows the programmer to have an escape hatch, and get around the type checker. However, this *laissez-faire* solution means that a run-time check is necessary, as $\ref{eq:e-cast}$ shows.

#### Variants
The subtyping rules for [variants](#variants) are almost identical to those of records, with the main difference being the width rule allows variants to be *added*, not dropped:

$$
\begin{align}
\langle l_i : {T_i}^{i\in 1\dots n} \rangle
<:
\langle l_i : {T_i}^{i\in 1\dots n+k} \rangle
\label{eq:s-variantwidth}\tag{S-VariantWidth} \\ \\

\frac{\forall i \ S_i <: T_i}{
    \langle l_1 : {S_i}^{i\in 1 \dots n} \rangle
    <:
    \langle l_1 : {T_i}^{i\in 1 \dots n} \rangle
} \label{eq:s-variantdepth}\tag{S-VariantDepth} \\ \\

\frac{
    \langle k_j : {S_j}^{j\in 1 \dots n} \rangle
    \text{ is a permutation of }
    \langle l_i : {T_i}^{i\in 1 \dots n} \rangle
}{
    \langle k_j : {S_j}^{j\in 1 \dots n} \rangle
    <:
    \langle l_i : {T_i}^{i\in 1 \dots n} \rangle
}
\label{eq:s-variantperm}\tag{S-VariantPerm} \\ \\

\frac{
    \Gamma\vdash t_1 : T_1
}{
    \Gamma\vdash \langle l_1 = t_1 \rangle : \langle l_1 : T_1 \rangle 
} \label{eq:t-variant}\tag{T-Variant}
\end{align}
$$

The intuition for $\ref{eq:s-variantwidth}$ is that a tagged expression $\langle l = t \rangle$ belongs to a variant type $\langle l_i : {T_i}^{i\in 1\dots n} \rangle$ if the label $l$ is *one of the possible labels* $\set{l_i}$. This is easy to understand if we consider the [`Option` example that we used previously](#variants): `some` and `none` are subtypes of `Option`. 

#### Covariance
`List` is an example of a covariant type constructor: we want `List[None]` to be a subtype of `List[Option]`.

$$
\frac{S_1 <: T_1}{\text{List } S_1 <: \text{List } T_1}
\label{eq:s-list}\tag{S-List}
$$

#### Invariance
References are not covariant nor invariant. An example of an invariant constructor is a [reference](#references).

- When a reference is *read*, the context expects $T_1$ so giving a $S_1 <: T_1$ is fine
- When a reference is *written*, the context provides a $T_1$. If the the actual type of the reference is $\text{Ref } S_1$, someone may later use the $T_1$ as an $S_1$, so we need $T_1 <: S_1$

Similarly, arrays are invariant, for the same reason:

$$
\frac{S_1 <: T_1 \quad T_1 <: S_1}{\text{Array } S_1 <: \text{Array } T_1}
\label{eq:s-array}\tag{S-Array}
$$

Instead, Java has covariant arrays:

$$
\frac{S_1 <: T_1}{\text{Array } S_1 <: \text{Array } T_1}
\label{eq:s-arrayjava}\tag{S-ArrayJava}
$$

This is because the Java language designers felt that they needed to be able to write a sort routine for mutable arrays, and implemented this as a quick fix. Instead, it turned out to be a mistake that even the Java designers regret.

The solution to this invariance problem is based on the following observation: a `Ref T` can be used either for reading or writing. To be able to have contravariant reading and covariant writing, we can split a `Ref T` in three:

- `Source T`: a reference with read capability
- `Sink T`: a reference cell with write capability
- `Ref T`: a reference cell with both capabilities

The typing rules then limit dereference to sources, and assignment to sinks:

$$
\begin{align}
\frac{
    \Gamma \mid \Sigma \vdash t_1 : \text{Source } T_{11}
}{
    \Gamma \mid \Sigma \vdash !t_1 : T_{11}
} \label{eq:t-derefsource}\tag{T-DerefSource} \\ \\

\frac{
    \Gamma \mid \Sigma \vdash t_1 : \text{Sink } T_{11}
    \quad 
    \Gamma \mid \Sigma \vdash t_2 : T_{11}
}{
    \Gamma \mid \Sigma \vdash t_1 := t_2 : \text{Unit}
}
\label{eq:t-assignsink}\tag{T-AssignSink} \\
\end{align}
$$

The subtyping rules establish sources as covariant constructors, sinks as contravariant, and a reference as a subtype of both:

$$
\begin{align}
\frac{S_1 <: T_1}{\text{Source } S_1 <: \text{Source } T_1}
\label{eq:s-source}\tag{S-Source} \\ \\

\frac{T_1 <: S_1}{\text{Sink } S_1 <: \text{Sink } T_1}
\label{eq:s-sink}\tag{S-Sink} \\ \\

\text{Ref } T_1 <: \text{Source } T_1
\label{eq:s-refsource}\tag{S-RefSource} \\ \\

\text{Ref } T_1 <: \text{Sink } T_1
\label{eq:s-refsink}\tag{S-RefSink} \\
\end{align}
$$


### Algorithmic subtyping
So far, in STLC, our typing rules were *syntax directed*. This means that for every for every form of a term, a specific rule applied; which rule to choose was always straightforward. 

The reason the choice is so straightforward is because we can divide the positions of a typing relation like $\ref{eq:t-app}$ into input positions ($\Gamma$ and $t$), and output positions ($T_{11}$, $T_{12}$).

However, by introducing subtyping, we introduced rules that break this: $\ref{eq:t-sub}$ and $\ref{eq:s-trans}$ apply to *any* kind of term, and can appear at any point of a derivation. Every time our type checking algorithm encounters a term, it must decide which rule to apply. $\ref{eq:s-trans}$ also introduces the problem of having to pick an intermediary type $U$ (which is neither an input nor an output position), for which there can be multiple choices. $\ref{eq:s-refl}$ also overlaps with the conclusions of other rules, although this is a less severe problem.

But this excess flexibility isn't strictly needed; we don't need 1000 ways to prove a given typing or subtyping statement, one is enough. The solution to these problems is to replace the ordinary, *declarative* typing and subtyping relations with *algorithmic* relations, whose sets of rules are syntax directed. This implies proving that the algorithmic relations are equivalent to the original ones, that subsumption, transitivity and reflexivity are consequences of our algorithmic rules.

## Objects
For simple objects and classes, we can easily use a translational analysis, converting ideas like dynamic dispatch, state, inheritance, into derived forms from lambda calculus such as (higher-order) functions, records, references, recursion, subtyping. However, for more complex features (like `this`), we'll need a more direct treatment.

In this section, we'll just identify the core features of object-oriented programming, and propose translations for the simpler features. The more complex features will lead us to defining Featherweight Java.

### Classes
Let's take a look at an example of a class:

{% highlight java linenos %}
class Counter {
    protected int x = 1;
    int get() { return x; }
    void inc() { x++; }
}
{% endhighlight %}

To represent this in lambda calculus, we could use a record in a let body:

{% highlight stlc linenos %}
let x = ref 1 in {
    get = λ_: Unit. !x
    inc = λ_: Unit. x := succ(!x)
}
{% endhighlight %}

More generally, the state may consist of more than a single reference cell, so we can let the state be represented by a variable `r` corresponding to a record with (potentially) multiple fields.

{% highlight stlc linenos %}
let r = {x = ref 1} in {
    get = λ_: Unit. !(r.x)
    inc = λ_: Unit. r.x := succ(!(r.x))
}
{% endhighlight %}

### Object generators
To create a new object, we can just define a function that creates and returns a `Counter`:

{% highlight stlc linenos %}
newCounter = λ_: Unit. 
    let r = {x = ref 1} in {
        get = λ_: Unit. !(r.x)
        inc = λ_: Unit. r.x := succ(!(r.x))
    }
{% endhighlight %}

This returns a `newCounter` object of type $\text{Unit} \rightarrow \text{Counter}$, where the $\text{Counter}$ type is defined as:

$$
\text{Counter} = \set{
    \text{get}: \text{Unit} \rightarrow \text{Nat},\ 
    \text{inc}: \text{Unit}\rightarrow\text{Unit}
}
$$

### Dynamic dispatch
When an operation is invoked on an object, the ensuing behavior depends on the object itself; indeed, two object of the same type may be implemented internally in completely different ways.

For instance, we can define two subclasses doing very different things:

{% highlight java linenos %}
class A {
    int x = 0;
    int m() {
        x = x + 1;
        return x;
    }
}

class B extends A {
    int m() {
        x = x + 5;
        return x;
    }
}

class C extends A {
    int m() {
        x = x - 10;
        return x;
    }
}
{% endhighlight %}

Here, `(new B()).m()` and `(new C()).m()` have different results. 

Dynamic dispatch is a kind of *late binding* for function calls. Rather than construct the binding from call to function at compile-time, the idea in dynamic dispatch is to bind at runtime.

### Encapsulation
In most OO languages, each object consists of some internal state. The state is directly accessible to the methods, but inaccessible from the outside.In Java, the encapsulation can be enabled with `protected`, which allows for a sort of information hiding.

The type of an object is just the set of operations that can be performed on it. It doesn't include the internal state.

### Inheritance and subtyping
Subtyping is a way to talk about types. Inheritance is more focused on the idea of sharing behavior, on avoiding duplication of code. 

The basic mechanism of inheritance is classes, which can be:

- **instantiated** to create new objects ("instances"), *or*
- **refined** to create new classes ("subclasses"). Subclasses are subtypes of their parent classes.

When we refine a class, it's usually to add methods to it. We saw previously that a record A with more fields than B is a subtype of B; let's try to extend that behavior to objects.

As an example, let's try to look at a `ResetCounter` inheriting from `Counter`, adding a `reset` method that sets `x` to 1. In Java, we'd do this as follows:

{% highlight java linenos %}
class Counter {
    protected int x = 1;
    int get() {
        return x;
    }
    void increment() {
        x++;
    }
}

class ResetCounter extends Counter {
    void reset() {
        x = 1;
    }
}
{% endhighlight %}

How can we implement `ResetCounter` in lambda calculus? Initially, we can just try to do this by coping the `Counter` body into a new object `ResetCounter`, and add a `reset` method:

{% highlight stlc linenos %}
newResetCounter =
    λ_: Unit. let r = {x = ref 1} in {
        get   = λ_: Unit. !(r.x),
        inc   = λ_: Unit. r.x := succ(!(r.x)),
        reset = λ_: Unit. r.x := 1
    }
{% endhighlight %}

But this goes against the [DRY principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) from software engineering. 

Another thing that we could try is to take a `Counter` as an argument in the `ResetCounter` object generator:

{% highlight stlc linenos %}
resetCounterFromCounter = λc. Counter. 
    let r = {x = ref 1} in {
        get   = c.get,
        inc   = c.inc,
        reset = λ_: Unit. r.x := 1
    }
{% endhighlight %}

However, this is problematic because we're not sharing the state; we've got two separate counts in `Counter` and `ResetCounter`, and they cannot access each other's state.

To solve this, we must separate the method definition from the object generator. To do this, we can use the age-old computer science adage of "every problem can be solved with an additional level of indirection". 

{% highlight stlc linenos %}
counterClass = λr: CounterState. {
    get = λ_: Unit. !(r.x),
    inc = λ_: Unit. r.x := succ(!(r.x))
};

newCounter = λ_: Unit. 
    let r = {x = ref 1} in counterClass r;
{% endhighlight %}

To define the subclass, we'll first have to introduce the notion of `super`. We know this construct from Java, among others. Java's `super` gives us a mechanism to avoid dynamic dispatch, since we *specifically* call the method in the superclass we inherit from.

For the subclass, the idea is to instantiate the `super`, and bind the methods of the object to the `super`'s methods. The classes both have access to the same value through the use of references.

{% highlight stlc linenos %}
resetCounterClass = λr: CounterState.
    let super = counterClass r in {
        get   = super.get,
        inc   = super.inc,
        reset = λ_: Unit. r.x := 1
    };

newResetCounter = λ_: Unit.
    let r = {x = ref 1} in resetCounterClass r;
{% endhighlight %}

This also allows us to call `super` in added or redefined methods (so `reset` could call `super.inc` if it needed to, or we could redefine `inc` to add functionality around `super.inc`).

Our state record `r` can even contain more variable than the superclass needs, as records with more fields are subtypes of those with a subset of fields. This allows us to have more instance variables in the subclass.

Note that if we wanted to be more rigorous, we'd have to define this more precisely. In STLC, we've defined records through *structural subtyping*. But most object-oriented languages use *nominal subtyping*, where things aren't subtypes of each other just because they have the same methods, but because we declare them to be so. We'll see [more on this later](#structural-vs-nominal-type-systems).

### This
Above, we saw how to call methods from the parent class through `super`. To call methods between each other, we need to add `this`. 

Let's consider the following class as an example:

{% highlight java linenos %}
class SetCounter {
    protected int x = 0;
    int get() {
        return x;
    }
    void set(int i) {
        x = i
    }
    void inc() {
        this.set(this.get() + 1);
    }
}
{% endhighlight %}

This example may be a little simplistic, but in practice, it's very useful to be able to use other methods within the same class.

In an initial attempt at implementing this in lambda calculus, we can add a fix operator to the class definition, so that we can call ourselves:

{% highlight stlc linenos %}
setCounterClass = λr: CounterState. 
    fix (λthis: SetCounter. {
        get = λ_: Unit. !(r.x),
        set = λi: Nat.  r.x := i,
        int = λ_: Unit. this.set (succ (this.get unit))
    });
{% endhighlight %}

As a small sanity check, we pass a $\text{SetCounter} \longrightarrow \text{SetCounter}$ type to `fix` operation, so the resulting type is indeed $\text{SetCounter}$.

We have "tied the knot" by using the `fix` operator, which arranges for the very record we built to also be passed as `this`.

But this does not model the behavior of `this` in most object-oriented languages, which support a more general form of recursive call between methods, known as *open recursion*. This allows the methods of a superclass to call the methods of a subclass through `this`.

The problem here is that the fixed point operation is "closed": it only gives us the exact set we built in `this`, and isn't open to extension. To solve this, we can move the application of `fix` from the class definition to the object creation function (essentially switching the order of `fix` and `λr: CounterState`):

{% highlight stlc linenos %}
setCounterClass = λr: CounterState. 
    λthis: SetCounter. {
        get = λ_: Unit. !(r.x),
        set = λi: Nat.  r.x := i,
        int = λ_: Unit. this.set (succ (this.get unit))
    };

newSetCounter = λ_: Unit.
    let r = {x = ref 1} in fix (setCounterClass r);
{% endhighlight %}

Note that this changes the type signature of the class, which goes from:

$$
\text{SetCounterClass}: \text{CounterState} \longrightarrow \text{SetCounter} 
$$

To the following:

$$
\text{SetCounterClass}: 
    \text{CounterState} \longrightarrow 
    \text{SetCounter} \longrightarrow 
    \text{SetCounter} 
$$

But passing it the state, and passing that to `fix` does indeed give us a $\text{SetCounter}$ type, so our constructor returns the expected type.

### Using `this`
Let's continue the example from above by defining a new class of counter object, keeping count of the number of times `set` has been called. We'll call this an "instrumented counter" `InstrCounter`, extending the `SetCounter` we defined above: 

{% highlight plain linenos %}
InstrCounter = {
    get: Unit -> Nat,
    set: Nat  -> Unit,
    inc: Unit -> Unit
    accesses: Unit -> Nat
};

IntrCounterState = {
    x: Ref Nat,
    a: Ref Nat
};

instrCounterClass = λr: InstrCounterState. λthis: InstrCounter.
    let super = setCounterClass r this in {
        get = super.get,
        set = λi: Nat. (
            r.a := succ(!(r.a));
            super.set i
        ),
        inc = super.inc,
        accesses = λ_: Unit. !(r.a)
    };

newInstrCounter = λ_: Unit. 
    let r = {x = ref 1, a = ref 0} in fix (instrCounterClass r);
{% endhighlight %}

A few notes about this implementation:

- The methods use `this` (passed as a parameter) and `super` (constructed using `this` and the state variable `r`)
- Because we allow for open recursion, the `inc` in `super` calls the `set` defined here, which calls the `super.set`

But this implementation is not very useful, as the object creator diverges! Intuitively, the problem is that the "unprotected" use of `this`. The argument that we pass to `fix` uses its own argument (`this`) too early; in general, to create fixed points abstractions that don't diverge, the assumption is that one should only use the argument in "protected" locations, such as in the bodies of inner lambda abstractions.

A solution is to "delay" this by putting a dummy abstraction in front of it:

{% highlight stlc linenos %}
setCounterClass = λr: CounterState. 
    λthis: Unit -> SetCounter.
        λ_: Unit. {
            get = λ_: Unit. !(r.x),
            set = λi: Nat.  r.x := i,
            int = λ_: Unit. this.set (succ (this.get unit))
        };
{% endhighlight %}

This essentially replaces call-by-value with call-by-name. Now, `this` is of type $\text{Unit} \rightarrow \text{SetCounter}$.

This works, but very slowly. All the delaying we added has a side effect. Instead of computing the method table just once, we now re-compute it every time we invoke a method. Indeed, every time we need it, since we're in call-by-name, we re-compute it every time. 

The solution here is to use lazy values, which we can represent in lambda calculus as a reference, along with a flag about whether we've computed it or not. Section 18.12 describes this in more detail.


## Featherweight Java

We've now covered the essence of objects, but there are still certain things missing compared to Java. With objects, we've captured the runtime aspect of classes, but we haven't really talked about the classes as types. 

We're also missing a discussion on:

- Named types with declared subtyping (we've only done structural subtyping)
- Recursive types, like the ones we need for list tails, for instance
- Run-time type analysis:  most type systems have escape hatches known as casts, which we haven't talked about
- Many other things

Seeing that we have plenty to talk about, let's try to define a model for Java. A model always abstracts details away, so there's no such thing as a perfect model. It's always a question of which trade-offs we choose for our specific use-case. 

Java is used for a lot of different purposes, so we are going to have lots of different models. For instance, some of the choices we need to make are: 

- Source-level vs. bytecode level
- Large (inclusive) vs small (simple) models
- Type system vs. run-time
- Models of specific features

Featherweight Java was proposed as a tool for analyzing GJ (Java with generics), and has since been used to study proposed Java extensions. It aims to be very simple, modeling just the core OO features and their types, *and nothing else*. It models:

- Classes and objects,
- Method and method invocation,
- Fields and field access,
- Inheritance (including open recursion through `this`)
- Casting

It leaves out more complex topics such as reflection, concurrency, exceptions, loops, assignment (!) and overloading.

The model aims to be very explicit, and simple. To maintain this simplicity, it imposes some conventions:

- Every class must declare a superclass
- All classes must have a constructor
- All fields must be represented 1-to-1 in the constructor
    + It takes the same number of parameters of fields of the class
    + It assigns constructor parameters to local fields
    + Calls `super` constructor to assign remaining fields
    + Nothing else!
- The constructor must call `super()`
- Always explicitly name receiver object in method invocation or field access (using `this.x` or `that.x`)
- Methods are just a single `return` expression

### Structural vs. Nominal type systems

There's a big dichotomy in the world of programming languages. 

On one hand, we have *structural* type systems, where the names are convenient but inessential abbreviations of types. What really matters about a type in a structural type system is its structure. It's somewhat cleaner and more elegant, easier to extend, but once we need to talk about recursive types, some of the elegance falls away. Examples include Haskell, Go and TypeScript.

On the other hand, what's used in almost all mainstream programming languages is *nominal* type systems. Here, recursive types are much simpler, and using names everywhere makes type checking much simpler. Having named types is also useful at run-time for casting, type testing, reflection, etc. Examples include Java, C++, C# and Kotlin.

### Representing objects
How can we represent an object? What defines it? Two objects are different if their constructors are different, or if their constructors have been passed different arguments. This observation leads us to the idea that we can identify an object fully by looking at the `new` expression. Here, having omitted assignments makes our life much easier.

### Syntax
The syntax of Featherweight Java is:

$$
\begin{align}
t ::= &                        & \textbf{terms} \\
      & x                      & \text{variable} \\
      & t.\!f                  & \text{field access} \\
      & t.\!m(\bar{t})           & \text{method invocation} \\
      & \text{new } C(\bar{t}) & \text{object creation} \\
      & (C)\ t                 & \text{cast} \\
\\
v ::= &                        & \textbf{values} \\
      & \text{new } C(\bar{v}) & \text{object creation} \\
\\
K ::= & & \textbf{constructor declarations} \\
      & C(\bar{C}\ \bar{f})\ \set{\text{super}(\bar{f});\ \text{this}.\!\bar{f}=\bar{f};} & \\
\\
M ::= & & \textbf{method declarations} \\
      & C\ m(\bar{C}\ \bar{x}) \set{\text{return } t;} \\
\\
CL ::= & & \textbf{class declarations} \\
       & \text{class } C \text{ extends } C\ \set{\bar{C}\ \bar{f};\ K\ \bar{M}} \\
\end{align}
$$

Above and in the following, we use the following metavariables:

- $A$, $B$, $C$, $D$, $E$ for class names
- $f$, $g$ for field names
- $x$ for parameter names
- $s$, $t$ for terms
- $u$, $v$ for values
- $K$ for constructor declarations
- $M$ for method declarations

We'll use the notation $\bar{C}$ to mean arbitrary repetition $C_1, \dots, C_n$ of $C$, and similarly for $\bar{f}, \bar{x}, \bar{t}$, etc. For method declaration, $\bar{M}$ means $M_1 \dots M_n$ (no commas).

The notation $\bar{C}\ \bar{f}$ means we've "zipped" the two together: $C_1\ f_1, \dots, C_n\ f_n$. 

Similarly, $\text{this}.\\!\bar{f}=\bar{f}$ means $\text{this}. \\! f_1 = f_1; \dots; \text{this}. \\! f_n = f_n$

### Subtyping
Java is a nominal type system, so subtyping in FJ is *declared*. This means that in addition to two properties for reflexion and transitivity, the subtyping relationship is given by the declared superclass.

$$
\begin{align}
C <: C
\\ \\
\frac{C <: D \quad D <: E}{C <: E}
\\ \\
\frac{\text{CT}(C) = \text{class } C \text{ extends } D \set{\dots}}{C <: D}
\end{align}
$$

We assume to have a *class table* $\text{CT}$, mapping class names to their definition. 

### Auxiliary definitions
We can glean a lot of useful properties from the definition in the class table, so it'll come in handy for evaluation and typing.

We said earlier that every class needed to define a superclass, but what about `Object`? The simplest way to deal with this is to let `Object` be an exception, a distinguished class name whose definition does not appear in the class table.

The fields of a class $C$, written $\text{fields}(C)$ is the sequence $\bar{C}\ \bar{f}$ mapping the class to each field. The fields of a class are those defined within it, and those it inherits from the superclasses:

$$
\begin{align}
\text{fields}(\text{Object}) = \emptyset 
\\ \\
\frac{
    \text{CT}(C) = \text{class } C \text{ extends } D \set{\bar{C}\ \bar{f}; K\ \bar{M}},
    \quad
    \text{fields}(D) = \bar{D}\ \bar{g}
}{
    \text{fields}(C) = \bar{D}\ \bar{g}, \bar{C}\ \bar{f}
}
\end{align}
$$

The type of a method $m$, written $\text{mtype}(m, C)$ is a pair $\bar{B}\rightarrow B$ mapping argument types $\bar{B}$ to a result type $B$ by searching up the chain of superclasses until we find the definition of the method $m$:

$$
\begin{align}
\frac{
    \text{CT}(C) = \text{class } C \text{ extends } D \ \set{\bar{C}\ \bar{f}; K\ \bar{M}},
    \quad
    B\ m (\bar{B}\ \bar{x})\ \set{\text{return } t;} \in \bar{M}
}{
    \text{mtype}(m, C) = \bar{B} \rightarrow B
}
\\ \\
\frac{
    \text{CT}(C) = \text{class } C \text{ extends } D \ \set{\bar{C}\ \bar{f}; K\ \bar{M}},
    \quad
    m \text{ is not defined in } \bar{M}
}{
    \text{mtype}(m, C) = \text{mtype}(m, D)
}
\end{align}
$$

Method body lookups work in basically the same way. It returns a pair $(\bar{x}, t)$ of parameters $\bar{x}$ and a term $t$ by searching up the chain of superclasses:

$$
\begin{align}
\frac{
    \text{CT}(C) = \text{class } C \text{ extends } D \ \set{\bar{C}\ \bar{f}; K\ \bar{M}},
    \quad
    B\ m (\bar{B}\ \bar{x})\ \set{\text{return } t;} \in \bar{M}
}{
    \text{mbody}(m, C) = (\bar{x}, t)
}
\\ \\
\frac{
    \text{CT}(C) = \text{class } C \text{ extends } D \ \set{\bar{C}\ \bar{f}; K\ \bar{M}},
    \quad
    m \text{ is not defined in } \bar{M}
}{
    \text{mbody}(m, C) = \text{mbody}(m, D)
}
\end{align}
$$

Featherweight Java also models overriding, so we can define a predicate function $\text{override}(m, D, \bar{C}\rightarrow C_0)$ that checks whether the method $m$ with argument types $\bar{C}$ and result type $C_0$ is overridden in a subclass of $D$:

$$
\frac{
    \text{mtype}(m, D) = \bar{D} \rightarrow D_0 
    \implies
    \bar{C} = \bar{D} \land C_0 = D_0
}{
    \text{override}(m, D, \bar{C}\rightarrow C_0)
}
$$


### Evaluation
FJ has three computation rules for field access, method invocation and casting.

$$
\begin{align}
\frac{
    \text{fields}(C) = \bar{C}\ \bar{f}
}{
    (\text{new } C(\bar{v})).\!f_i 
    \longrightarrow
    v_i
}
\tag{E-ProjNew}\label{eq:fj-eprojnew} 
\\ \\
\frac{
    \text{mbody}(m, C) = (\bar{x}, t_0)
}{
    (\text{new } C(\bar{v})).m(\bar{u})
    \longrightarrow
    [\bar{x}\mapsto\bar{u}, \text{this}\mapsto\text{new } C(\bar{v})]t_0
}
\tag{E-InvkNew}\label{eq:fj-e-invknew}
\\ \\
\frac{
    C <: D
}{
    (D)\ (\text{new } C(\bar{v}))
    \longrightarrow
    \text{new } C(\bar{v})
}
\tag{E-CastNew}\label{eq:fj-e-castnew}
\end{align}
$$


It also has a bunch of congruence rules:

$$
\begin{align}
\frac{
    t_0 \longrightarrow t_0'
}{
    t_0.\!f \longrightarrow t_0'.\!f
} \tag{E-Field}\label{eq:fj-e-field}
\\ \\
\frac{
    t_0 \longrightarrow t_0'
}{
    t_0.\!m(\bar{t}) \longrightarrow t_0'.\!m(\bar{t})
} \tag{E-Invk-Recv}\label{eq:fj-e-invk-recv}
\\ \\
\frac{
    t_i \longrightarrow t_i'
}{
    v_0.\!m(\bar{v}, t_i, \bar{t})
    \longrightarrow
    v_0.\!m(\bar{v}, t_i', \bar{t})
} \tag{E-Invk-Arg}\label{eq:fj-e-invk-arg}
\\ \\
\frac{
    t_i \longrightarrow t_i'
}{
    \text{new } C(\bar{v}, t_i, \bar{t})
    \longrightarrow
    \text{new } C(\bar{v}, t_i', \bar{t})
} \tag{E-New-Arg}\label{eq:fj-e-new-arg}
\\ \\
\frac{
    t_0 \longrightarrow t_0'
}{
    (C)\ t_0 \longrightarrow (C)\ t_0'
} \tag{E-Cast}\label{eq:fj-e-cast}
\end{align}
$$

As $\ref{eq:fj-e-invknew}$ and $\ref{eq:fj-e-invk-arg}$ show, it uses call-by-value evaluation order.

### Typing
$$
\begin{align}
\frac{x: C \in \Gamma}{\Gamma\vdash x: C}
\tag{T-Var}\label{eq:fj-t-var}
\\ \\
\frac{
    \Gamma\vdash t_0 : C_0
    \quad \text{fields}(C_0) = \bar{C}\ \bar{f}
}{
    \Gamma\vdash t_0.\!f_i : C_i
} \tag{T-Field}\label{eq:fj-t-field}
\\ \\
\frac{
    \Gamma\vdash t_0 : C_0
    \quad \text{mtype}(m, C_0) = \bar{D} \rightarrow C
    \quad \Gamma\vdash \bar{t}: \bar{C}
    \quad \bar{C} <: \bar{D}
}{
    \Gamma\vdash t_0.\!m(\bar{t}): C
} \tag{T-Invk}\label{eq:fj-t-invk}
\\ \\
\frac{
    \text{fields}(C) = \bar{D}\ \bar{f}
    \quad \Gamma\vdash \bar{t}: \bar{C}
    \quad \bar{C} <: \bar{D}
}{
    \Gamma\vdash \text{new } C(\bar{t}): C
}\tag{T-New}\label{eq:fj-t-new}
\\ \\
\frac{
    \Gamma\vdash t_0 : D
    \quad D <: C
}{
    \Gamma\vdash (C)\ t_0 : C
} \tag{T-UCast}\label{eq:fj-t-ucast}
\\ \\
\frac{
    \Gamma\vdash t_0 : D
    \quad C <: D
    \quad C \ne D
}{
    \Gamma\vdash (C)\ t_0 : C
} \tag{T-DCast}\label{eq:fj-t-dcast}
\\ \\
\frac{
    (\bar{x}: \bar{C})\cup(\text{this}: C) \vdash t_0 : E_0
    \qquad E_0 <: C_0 \\
    \text{CT}(C) = \text{class } C \text{ extends } D\ \set{\dots}
    \qquad \text{override}(m, D, \bar{C}\rightarrow C_0)
}{
    C_0\ m\ (\bar{C}\ \bar{x})\ \set{\text{return } t_0;}\text{ OK in } C
} \tag{M OK in C}\label{eq:fj-m-ok-in-c}
\\ \\
\frac{
    K = C(\bar{D}\ \bar{g}, \bar{C}\ \bar{f})\ \set{
        \text{super}(\bar{g});
        \text{this}.\!\bar{f} = \bar{f};
    } \\
    \text{fields}(D)=\bar{D}\ \bar{g}
    \qquad \bar{M} \text{ OK in } C
}{
    \text{class } C \text{ extends } D \ \set{
        \bar{C}\ \bar{f};
        K\ \bar{M}
    } \text{ OK}
} \tag{C OK}\label{eq:fj-c-ok}
\end{align}
$$

$\ref{eq:fj-t-var}$ is as usual. $\ref{eq:fj-t-field}$ says that we can type-check the i<sup>th</sup> field by looking up the type of the i<sup>th</sup> field in the class.

We have two rules for casting: one for subtypes ($\ref{eq:fj-t-dcast}$), and one for supertypes ($\ref{eq:fj-t-ucast}$). We do not allow casting to an unrelated type, because FJ complies with Java, and Java doesn't allow it.

For methods and classes, we want to make sure that overrides are valid, that we pass the correct arguments to the superclass constructor.

Also note that the our typing rules often have subsumption built into them (e.g. see $\ref{eq:fj-t-invk}$), instead of having a separate subsumption rule. This allows us to have algorithmic subtyping, which we need for two reasons: 

1. To perform static overloading resolution (picking between different overloaded methods at compile-time), we need to be able to speak about the type of an expression (and we need one single type, not several of them)
2. We'd run into trouble typing conditional expressions. This is not something that we have included in FJ, but regular Java has it, and we may wish to include it as an extension to FJ

Let's talk about this problem with conditionals (aka ternary expressions) in a little more detail. If we have a conditional $t_1 ?\ t_2 : t_3$, with $t_1: \text{Bool}$, $t_2: T_2$ and $t_3: T_3$, what is the return type of the expression? The simple solution is the least common supertype (this corresponds to the lowest common ancestor), but that becomes problematic with interfaces, which allow for multiple inheritance (for instance, if $T_2$ and $T_3$ both implement $I_2$ and $I_3$, we wouldn't know which one to pick).

The actual Java rule that's used is that the return type is $\min (T_2, T_3)$. Scala solves this (in Dotty) with union types, where the result type is $T_2 \mid T_3$.

### Evaluation context
We can't actually prove progress, as well-typed programs can get stuck because of casting. Casting can fail, and we'd get stuck. The solution is to weaken the statement of progress:

**FJ progress** (*informally*): a well-typed FJ term is either value, reduces to one, or gets stuck at a cast failure.

To formalize this, we need a little more work. We'll first need to introduce **evaluation contexts**. For FJ, the evaluation context is defined as:

$$
\begin{align}
E ::= &                                    & \textbf{evaluation contexts} \\
      & []                                 & \text{hole} \\
      & E.\!f                              & \text{field access} \\
      & E.\!m(\bar{t})                     & \text{method invocation (rcv)} \\
      & v.m(\bar{v}, E, \bar{t})           & \text{method invocation (arg)} \\
      & \text{new } C(\bar{v}, E, \bar{t}) & \text{object creation (arg)} \\
      & (C)\ E                             & \text{cast} \\
\end{align}
$$

All expressions in $E$ are recursive, except for $[]$; this means an expression is a nested composition of the above forms, with a hole somewhere inside it. We write $E[t]$ for the term obtained by replacing the hole in $E$ with $t$.

Evaluation contexts are essentially just shorthand notation to avoid the verbosity of congruence rules. Usually, congruence rules just "forward" the computation to some part of the expression, and that's exactly what we capture with evaluation contexts: the position of $[]$ tells us which part of the expression to evaluate.

Having defined the execution context, we can then express all congruence rules as a single rule:

$$
\frac{t \longrightarrow t'}{E[t] \longrightarrow E[t']}
$$

### Properties

#### Progress
We can now restate progress more formally. 

**FJ progress**: Suppose $t$ is a closed, well-typed normal form. Then either: 

1. $t$ is a value
2. $t \longrightarrow t'$ for some $t'$
3. For some evaluation context $E$, we can express $t$ as $t = E[(C)\ (\text{new } D(\bar{v}))]$, with $\neg (D <: C)$

#### Preservation
The preservation theorem can be stated as:

**Preservation**: If $\Gamma\vdash t: C$ and $t \longrightarrow t'$ then $\Gamma\vdash t': C'$ for some $C' <: C$

But this doesn't actually for FJ. Because we allow casts to go up and down, we can upcast to Object before downcasting to another, unrelated type. Because FJ must model Java, we need to actually introduce a rule for this. In this new rule, we give a "stupid warning" to indicate that the *implementation* should generate a warning if this rule is used:

$$
\frac{
    \Gamma\vdash t_0 : D
    \quad \neg(C <: D)
    \quad \neg(D <: C) \\
    \text{stupid warning}
}{
    \Gamma\vdash (C) t_0 : C
} \tag{T-SCast}\label{eq:fj-t-scast}
$$

#### Correspondence with Java
FJ corresponds to Java; by this, we mean:

1. Every syntactically well-formed FJ program is also a syntactically well-formed Java program.
2. A syntactically well-formed FJ program is typable in FJ (without using $\ref{eq:fj-t-scast}$) $\iff$ it is typable in Java
3. A well-typed FJ program behaves the same in FJ as in Java (e.g. diverges in FJ $\iff$ it diverges in Java)

Without a formalization of full Java, we cannot *prove* this, but it's still useful to say what we're trying to accomplish, as it provides us with a rigorous way of judging potential counterexamples.

## Foundations of Scala

### Modeling lists
If we'd like to apply everything we've learned so far to model Scala, we'll run into problems fairly quickly. Say we'd like to model a `List`.

{% highlight scala linenos %}
trait List[+T] {
    def isEmpty: Boolean
    def head: T
    def tail: List[T]
}

def Const[T](hd: T, tl: List[T]) = new List[T] {
    def isEmpty = false
    def head = hd
    def tail = tl
}

def Nil[T] = new List[T] {
    def isEmpty = true
    def head = ???
    def tail = ???
}
{% endhighlight %}

Immediately, we run into these problems:

- It's parameterized
- It's recursive
- It can be invariant or covariant

To solve the parametrization, we need a way to express type constructors. Traditionally, the solution is to express this as *higher-kinded types*.

{% highlight scala linenos %}
*            // Kind of normal types (Boolean, Int, ...)
* -> *       // Kind of unary type constructor: 
             // something that takes a type, returns one
* -> * -> *  // and so on...
...
{% endhighlight %}

We've previously had abstraction and application for terms, but we'd now like to extends this to types. We'll introduce $\mu$, which works like $\lambda$ but for types. 

This also leads us to solving the problem of modeling recursive types, as we can now create type-level functions, called *type operators*. For instance, we can define a constructor for recursive types $\mu t. T(t)$. For instance:

{% highlight scala linenos %}
mu ListInt. { head: Int, tail: ListInt }
{% endhighlight %}

However, we get into some tricky questions when it comes to equality and subtyping. For instance, in the following, how do `T` and `Int -> T` relate?

{% highlight scala linenos %}
type T = mu t. Int -> Int -> t
{% endhighlight %}

Finally, we need to model the covariance of lists. We can deal with variance by expressing definition site variance as use-site variance, using Java wildcards:

{% highlight scala linenos %}
// We can go from definition site variance...
trait List[+T] { ... }
trait Function1[-T, +U] { ... }

List[C]
Function1[D, E]

// ... to use-site variance by rewriting with Java wildcards:
trait List[T] { ... }
trait Function1[T, U]

List[_ <: C]
Function1[_ >: D, _ <: E]
{% endhighlight %}

Here, we should understand `Function1[_ >: D, _ <: E]` as the type of functions from some (unknown) supertpye of `D` to some (unknown) subtype of `E`. How can we model this?  One possibility is existential types:

{% highlight scala linenos %}
// Scala:
Function1[X, Y] forSome {
    type X >: D
    type Y <: E
}

// more traditional notation, with existential types:
∃ X >: D, Y <: E. Function1[X, Y]
{% endhighlight %}

But this gets messy rather quickly. Can we find a nicer way of expressing this? As we saw above, Scala has type members, so we can re-formulate `List` as follows:

{% highlight scala linenos %}
trait List { self => 
    type T
    def isEmpty: Boolean
    def head: T
    def tail: List { type T <: self.T } // refinement handling co-variance
}

def Cons[X](hd: X, tl: List { type T <: X }) = new List {
    type T = X
    def isEmpty = false
    def head = hd
    def tail = tl
}

// analogous for Nil
{% endhighlight %} 

This offers an alternative way to express the above, without using existential types, but instead using:

- Variables, functions
- Abstract types `type T <: B`
- Refinements `List { ... }`
- Path-dependent types `self.T`

### Abstract types
Abstract types are types without a concrete implementation. They may have an upper and/or lower bound, like `type L >: T <: U`, or no bounds like below:

{% highlight scala linenos %}
// Trait containing an abstract type:
trait KeyGen {
    type Key
    def key(s: String): this.Key
}

// Implementation refining the abstract type:
object HashKeyGen extends KeyGen {
    type Key = Int
    def key(s: String) = s.hashCode
}
{% endhighlight %}

We can reference the `Key` type of a term `k` as `k.Key`. This is a *path-dependent* type. For instance:

{% highlight scala linenos %}
def mapKeys(k: KeyGen, ss: List[String]): List[k.Key] = 
    ss.map(s => k.key(s))
{% endhighlight %}

The function `mapKeys` has a *dependent function type*. This is an interesting type, because the result type has an internal dependency: `(k: KeyGen, ss: List[String]) -> List[k.Key]`. 

In Scala 2, we can't express this directly; we'd have to go through a trait with an apply method, meaning that we have to define a type for every dependent function:

{% highlight scala linenos %}
trait KeyFun {
    def apply(k: KeyGen, ss: List[String]): List[k.Key]
}

mapKeys = new KeyFun {
    def apply(k: KeyGen, ss: List[String]): List[k.Key] = 
        ss.map(s => k.key(s))
}
{% endhighlight %}

However, Scala 3 (dotty) [introduces these dependent function types](http://dotty.epfl.ch/docs/reference/new-types/dependent-function-types.html) at the language level; it's done with a similar trick to what we just saw. 

In dotty, the intention was to have everything map to a simple object type; this has been formalized in a calculus called DOT, (path-)Dependent Object Types. 

### DOT
The DOT syntax is described in the [DOT paper](http://lampwww.epfl.ch/~amin/dot/fool.pdf).

$$
\begin{align}
S, T, U ::= & & \textbf{Type} \\
    & \top & \text{top type} \\
    & \bot & \text{bot type} \\
    & \set{a: T} & \text{field declaration} \\
    & \set{A: S..T} & \text{type declaration} \\
    & x.A & \text{type projection} \\
    & S \land T & \text{intersection type} \\
    & \mu(x: T) & \text{recursive type} \\
    & \forall(x: S) T & \text{dependent function} \\
\\

v ::= & & \textbf{Value} \\
    & \nu(x: T)d & \text{object} \\
    & \lambda(x: T)t & \text{lambda} \\
\\

s, t, u ::= & & \textbf{Term} \\
    & x & \text{variable} \\
    & v & \text{value} \\
    & x.a & \text{selection} \\
    & x\ y & \text{application} \\
    & \text{let } x = t \text{ in } u & \text{let} \\
\\

d ::= & & \textbf{Definition} \\
    & \set{a = t} & \text{field definition} \\
    & \set{A = T} & \text{type definition} \\
    & d_1 \land d_2 & \text{aggregate definition} \\
\end{align}
$$

We use the following metavariables:

- $x$, $y$, $z$ for variables
- $a$, $b$, $c$ for term members
- $A$, $B$, $C$ for type members

Types are in uppercase, terms in lowercase. Note that recursive types $\mu (x: T)$ are a little different from what we've talked about, but we'll get to that later. 

As a small technicality, DOT imposes the restriction of only allowing member selection and application on variables, and not on values or full terms. This is equivalent, because we could just assign the value to a variable before selection or application. This way of writing programs is also called *administrative normal form* (ANF).

To simplify things, we can introduce a programmer-friendly notation with ASCII versions of DOT constructs:

{% highlight scala linenos %}
(x: T) => U          for   λ(x : T)U
(x: T) -> U          for   ∀(x : T)U
new(x: T)d           or
new { x: T => d }    for   ν(x : T)d
rec(x: T)            or
{ x => T }           for   μ(x: T)
T & U                for   T ∧ U
Any                  for   ⊤
Nothing              for   ⊥
{ type A >: S <: T } for   {A: S..T}
{ def a = t }        for   {a = t}
{ type A = T }       for   {A = T}
{% endhighlight %}

This calculus does not have generic types, because we can encode them as dependent function types. 

#### Example 1: Twice
Let's take a look at an example. The polymorphic type of the `twice` method (which we [defined previously](#lambda-calculus)) is:

$$
\forall X.\ (X \rightarrow X) \rightarrow X \rightarrow X
$$ 

In other words, it takes a function from $X$ to $X$, an argument of type $X$, and returns a value of type $X$, where $X$ is some generic type. This is represented as:

{% highlight scala linenos %}
(cX: {A: Nothing..Any}) -> (cX.A -> cX.A) -> cX.A -> cX.A
{% endhighlight %}

The `cX` parameter is a kind of cell containing a type variance X (hence the name `cX`).

#### Example 2: Church booleans
Let's see how Church Booleans could be implemented:

{% highlight scala linenos %}
// Define an abstract "if type" IFT
type IFT = { if: (x: {A: Nothing..Any}) -> x.A -> x.A -> x.A }

let boolimpl =
    let boolImpl =
        new(b: { Boolean: IFT..IFT } &
            { true: IFT } &
            { false: IFT })
        { Boolean = IFT } &
        { true = { if = (x: {A: Nothing..Any}) => (t: x.A) => (f: x.A) => t } &
        { false = { if = (x: {A: Nothing..Any}) => (t: x.A) => (f: x.A) => f }
in ...
{% endhighlight %}

We can hide the implementation details of this with a small wrapper to which we apply `boolImpl`. 

{% highlight scala linenos %}
let bool =
    let boolWrapper =
        (x: rec(b: {Boolean: Nothing..IFT} &
                   {true: b.Boolean} &
                   {false: b.Boolean})) => x
    in boolWrapper boolImpl
{% endhighlight %}

This is all a little long-winded, so we can introduce some abbreviations:

{% highlight scala linenos %}
// Abstract types:
type A                   for {A: Nothing..Any}
type A = T               for {A: T..T}
type A >: S              for {A: S..Any}
type A <: U              for {A: Nothing..U}
type A >: S <: U         for {A: S..U}

// Intersections:
{ type A = T; a = t }    for {A = T} & {a = t}
{ type A <: T; a = T }   for {A: Nothing..T} & {a: T}

// Ascription:
t: T
// Which expands to:
((x: T) => x) t
// Which expands to:
let y = (x: T) => x in
    let z = t in 
        y z

// Object definition:
new { x => d }           for new (x: T)d
{% endhighlight %}

With these in place, we can give an abbreviated definition:

{% highlight scala linenos %}
let bool =
    new { b =>
        type Boolean = {if: (x: { type A }) -> (t: x.A) -> (f: x.A) -> x.A}
        true = {if: (x: { type A }) => (t: x.A) => (f: x.A) => t}
        false = {if: (x: { type A }) => (t: x.A) => (f: x.A) => f}
    }: { b => type Boolean; true: b.Boolean; false: b.Boolean }
{% endhighlight %}

#### Example 3: Lists
We've now introduced all the concepts we need to actually define the covariant list in DOT. We'd like to model the following Scala code in DOT:

{% highlight scala linenos %}
package scala.collection.immutable

trait List[+A] {
    def isEmpty: Boolean
    def head: A
    def tail: List[A]
}

object List{
    def nil: List[Nothing] = new List[Nothing] {
        def isEmpty = true
        def head = head // infinite loop
        def tail = tail // infinite loop
    }

    def cons[A](hd: A, tl: List[A]) = new List[A] {
        def isEmpty = false
        def head = hd
        def tail = tl
    }
}
{% endhighlight %}

We can write this in DOT as:

{% highlight scala linenos %}
let scala_collection_immutable_impl = new { sci =>
    type List = { thisList =>
        type A
        isEmpty: bool.Boolean
        head: thisList.A
        tail: sci.List & {type A <: thisList.A }
    }

    cons = (x: {type A}) => (hd: x.A) =>
        (tl: sci.List & { type A <: x.A }) =>
            let l = new {
                type A = x.A
                isEmpty = bool.false
                head = hd
                tail = tl 
            } in l

    nil = (x: {type A}) =>
        let l = new { l =>
            type A = x.A
            isEmpty = bool.true
            head = l.head
            tail = l.tail
        } in l
}
{% endhighlight %}

To hide the implementation, we can wrap `scala_collection_immutable_impl`:

{% highlight scala linenos %}
let scala_collection_immutable = scala_collection.immutable_impl: { sci =>
    type List <: { thisList =>
        type A
        isEmpty: bool.Boolean
        head: thisList.A
        tail: sci.List & {type A <: thisList.A }
    }

    nil: sci.List & { type A = Nothing }

    cons: (x: {type A}) ->
          (hd: x.A) ->
          (tl: sci.List & { type A <: x.A }) ->
          sci.List & { type A = x.A }
}
{% endhighlight %}

This concept of hiding the implementation gives us *nominality*. A nominal type such as `List` is simply an abstract type with a hidden implementation. This shows that nominal and structural types aren't completely separated; we can do nominal types within a structural setting if we have these constructs.

### Evaluation
Evaluation is interesting, because we'd like for it to keep terms in ANF.

First, to define the congruence rules, let's define an evaluation context $E$:

$$
\begin{align}
E ::= & \\
    & [] \\
    & \text{let } x = [] \text{ in } t \\
    & \text{let } x = v  \text{ in } E \\ 
\end{align}
$$

The rules are then:

$$
\begin{align}
\frac{t \longrightarrow t'}{E[t] \longrightarrow E[t']}
\\ \\
\frac{v = \lambda(z: T)t}{
    \text{let } x = v \text{ in } E[x\ y]
    \longrightarrow
    \text{let } x = v \text{ in } E[[z\mapsto y] t]
}
\\ \\
\frac{v = \nu(z: T)...\set{a = t}}{
    \text{let } x = v \text{ in } E[x.a]
    \longrightarrow
    \text{let } x = v \text{ in } E[t]
}
\\ \\
\text{let } x = y \text{ in } t
\longrightarrow
[x \mapsto y] t
\\ \\
\text{let } x = (\text{let } y = s \text{ in } t) \text{ in } u
\longrightarrow
\text{let } y = s \text{ in } \text{let } x = t \text{ in } u
\end{align}
$$

### Type assignment and subtyping
These are in the slides and in the DOT paper.

### Abstract types
Abstract types turn out to be both the most interesting and most difficult part of this, so let's take a quick look at it before we go on.

Abstract types can be used to encode type parameters (as in `List`), hide information (as in `KeyGen`), and also to resolve some puzzlers like this one:

{% highlight scala linenos %}
trait Food
trait Grass extends Food

trait Animal {
    def eat(food: Food): Unit
}

trait Cow extends Animal with Food {
    // error: does not override Animal.eat because of contravariance
    def eat(food: Grass): Unit
}

trait Lion extends Animal {
    // error: does not override Animal.eat because of contravariance
    def eat(food: Cow): Unit
}
{% endhighlight %}

Scala disallows this, but Eiffel, Dart and TypeScript and allow it. The trade-off that the latter languages choose is modeling power over soundness, though some languages have eventually come back around and tried to fix this (Dart has a strict mode, Eiffel proposed some data flow analysis, ...).

In Scala, this contravariance problem can be solved with abstract types:

{% highlight scala linenos %}
trait Animal {
    type Diet <: Food
    def eat(food: Diet): Unit
}

trait Cow extends Animal {
    type Diet <: Grass
    def eat(food: this.Diet): Unit
}

object Milka extends Cow {
    type Diet = AlpineGrass
    def eat(food: AlpineGrass): Unit
}
{% endhighlight %}

### Progress and preservation
Progress is actually wrong. Here's a counter example:

{% highlight scala linenos %}
t = let x = (y: Bool) => y in x
{% endhighlight %}

But we can extend our definition of progress. Instead of values, we'll just want to get answers, which we define as variables, values or let-bindings.

But this is difficult (and it's what took 8 years to prove), because we always need an inversion, and the subtyping relation is user-definable. This is not a problem for simple type bounds:

{% highlight scala linenos %}
type T >: S <: U
{% endhighlight %}

But it becomes complex for non-sensical bounds:

{% highlight scala linenos %}
type T >: Any <: Nothing
{% endhighlight %}

By transitivity, it would mean that `Any <: Nothing`, so by transitivity all types are subtypes of each other. This is bad because it means that inversion fails, as we cannot tell anything from the types anymore.

We might say that this should be easy to disallow in the compiler, but it isn't. The compiler cannot always tell.

{% highlight scala linenos %}
// S and T are both good:
type S = { type A; type B >: A <: Bot }
type T = { type A >: Top <: B; type B }

// But their intersection is bad
type S & T == { type A >: Top <: Bot; type B >: Top <: Bot }
{% endhighlight %}

Bad bounds can arise from intersecting types with good bounds. This isn't too bad in and of itself, as we could just check all intersection types, written or inferred, for these bad bounds. But there's a final problem: bad bounds can arise at run-time. By preservation, if $\Gamma\vdash t: T$ and $t\longrightarrow u$ then $\Gamma\vdash u: T$. Because of subsumption, $u$ may also have a type $S$ which is a true subtype of $T$, and that type $S$ could have bad bounds (from an intersection for instance).

To solve this, the idea is to reason about environments $\Gamma$ arising from an actual computation in the preservation rule. This environment corresponds to an evaluated `let` binding, binding variables to values. Values are guaranteed to have good bounds because all type members are aliases. 

In other words, the `let` prefix acts like a store, a set of bindings $x = v$ of variables to values. Evaluation will then relate terms *and* stores:

$$
s \mid t \longrightarrow s' \mid t' 
$$

For the theorems of proofs and preservation, we need to relate environment and store. We'll introduce a definition:

> An environment $\Gamma$ *corresponds* to a store $s$, written $\Gamma \sim s$ if for every binding $x=v$ there is an entry $\Gamma\vdash x: T$ where $\Gamma \vdash_{!} v: T$. 

Here $\vdash_{!}$ denotes an exact typing relation, whose typing derivation ends with `All-I` or `{}-I` (so no subsumption or structural rules).

By restating our theorems as follows, we can then prove them.

- **Preservation**: If $\Gamma\vdash t: T$ and $G\sim s$ and $s \mid t \longrightarrow s' \mid t'$ then there exists an environment $\Gamma' \subset \Gamma$ such that $\Gamma' \vdash t' : T$ and $\Gamma' \sim s'$.
- **Progress**: if $\Gamma\vdash t: T$ and $\Gamma\sim s$ then either $t$ is a normal form, or $s\mid t \longrightarrow s' \mid t'$ for some store $s'$ and term $t'$.
