---
title: A monad is not a burrito
description: Monads are this scary, complicated thing for many people learning Scala and functional programming. This article is a pragmatic explanation of what they are, and what they're useful for.
edited: true
---

{% block note %}
This article assumes a little knowledge of Scala, notably of `Option`, `map` and `flatMap`. However, these concepts are also found in many other languages, so my hope is that it should also be fairly accessible to people who do not know Scala in particular.
{% endblock %} 

*[EPFL]: Swiss Federal Institute of Technology, Lausanne

I've been a teaching assistant at EPFL for various Scala courses for about a year and a half. In this job, I've gotten to read and grade a lot of code written by other students; I get to see what people understand well, and what's causing difficulties.

The most common thing I've seen is a tendency for novice Scala programmers to use `Option`s quite awkwardly. I think the root of that problem is an incomplete understanding of what monads really are, and what they're useful for. 

And I don't blame them; monads *are* something that took a while to click in my head, too. The click came from a piece of advice from Martin Odersky, who said something to the effect of[^paraphrasing]:

[^paraphrasing]: I'm heavily paraphrasing here, because this was said in a Scala programming class three years ago, and I don't remember the exact words.

> There are articles online that try to explain monads as being sort of like a burrito, because they wrap values. Disregard those. Here's what a monad really is: a parametric type with a `flatMap` and a `unit` method.

<!-- More -->

The burrito is an unhelpful metaphor, because it says nothing about how to recognize or use monads. Alternatively, other online explanations require good knowledge of Haskell, or are comically complex ("a monad is just a monoid in the category of endofunctors, what's the problem?"[^monoid-in-the-category-of-endofunctors]).

[^monoid-in-the-category-of-endofunctors]: This quote is from the brilliant [Brief, Incomplete and Mostly Wrong History of Programming Languages](https://james-iry.blogspot.com/2009/05/brief-incomplete-and-mostly-wrong.html). There's a good discussion of it on [this StackOverflow post](https://stackoverflow.com/q/3870088/918389), if ever.

I think that's a shame.

A better understanding of monads would go a long way to improve the style of a lot of code I've read. It's the one thing I'd like to teach all these Scala students I've had, and that's what this article is for.

## So what is a monad, anyway?
Let's repeat the definition of a monad: "a parametric type with a `flatMap` and a `unit` method". This gives us three criteria defining a monad:

1. A parametric type
2. with a `flatMap` method
3. and a `unit` method.

In Scala, we'd write this as:

{% highlight scala linenos %}
trait Monad[T] {
    def flatMap[U](f: T => Monad[U]): Monad[U]
}

def unit[T](x: T): Monad[T]
{% endhighlight %}

`Monad` is a parametric (or *generic*) type, in that it takes a type parameter `T`.

We already know `flatMap` from lists: it applies a function to all elements of the list and its sublists, and returns a flat list of results. 

The second method, `unit`, works as a constructor of monads: it takes a value `x` of type `T` and returns a `Monad[T]` containing `x`. To discuss the theory, we call it `unit`, but in Scala implementations, we typically define it as `apply`, the constructor method, on the companion object.

To be a little more formal about what these methods should do, we can quickly mention the three *monadic laws*. Let `f` and `g` be functions that create a monad from some value, `x` be some value, and `m` be an instance of the monad. We want the following properties to always hold:

1. **Associativity**: `m.flatMap(f).flatMap(g) == m.flatMap(x => f(x).flatMap(g))`
2. **Left identity**: `unit(x).flatMap(f) == f(x)`
3. **Right identity**: `m.flatMap(unit) == m`

In English, these mean:

1. **Associativity**: if we have a chain of `flatMap` applications, it doesn't matter how they're nested
2. **Left identity**: constructing a monad with `x` and then doing a `flatMap(f)` is the same as calling `f` on `x` directly, because `flatMap` flattens results
3. **Right identity**: calling `flatMap(unit)` changes nothing, because `flatMap` flattens results

If all of the above are satisfied, we have a monad!  That's all good and well, but what can we use this for?

## Monads, *huh*, what are they good for?
It turns out that many things have secretly been monads all along:

- `Option` is a monad
- `Set` is a monad
- `List` is a monad

`Option`s are somewhat of a canonical example for monads, so let's stick to the tradition here and use them to see what monads bring to the table. As an example, let's write a small and oddly specific library to read numbers from the standard input.

{% highlight scala linenos %}
def readInt: Option[Int] = ...

def readAndAddOne: Option[Int] = readInt match {
    case Some(x) => Some(x + 1)
    case None => None
}

def readPositiveInt: Option[Int] = readInt match {
    case Some(x) if x >= 0 => Some(x)
    case None => None
}

def readAndSum: Option[Int] = readInt match {
    case Some(x) => readInt match {
        case Some(y) => Some(x + y)
        case None => None
    }
    case None => None
}
{% endhighlight %}

This code uses a lot of pattern matching, but I've also seen a lot of code written in a more imperative style, like so:

{% highlight scala linenos %}
def readPositiveInt: Option[Int] = {
    val value = readInt
    if (value.isDefined && value.get >= 0) value
    else None
}
{% endhighlight %}

All of this is a little clumsy. So many lines are spent managing the `Option` that we don't clearly see the logic of what the functions are meant to do anymore. 

How can we improve this? A very common trick in computer science is that when we see a repeated pattern, we abstract it out into a definition. Here, the pattern is differentiating the `Some` and `None` cases, and doing something with the value in the `Some` case. 

Perhaps we could write some function so that we don't repeat ourselves so much? Well, that's exactly what `Option.flatMap` is! This process of abstracting away boilerplate code is what monads are for in the first place.

The `flatMap` function applies a function to the value, if there is one; if the value is nested (e.g. `Some(Some(1))`), `flatMap` ignores the nested structure in order to work with the actual value (in this case, `1`). Remember, that's exactly the functionality we wanted to abstract away.

If you find it counter-intuitive to think of a `flatMap` on something that has a single value (at best!), you can think of an `Option` as being a kind of list, except that it may only contain zero or one value. With this in mind, we can just think of `flatMap` as doing what it does on lists: applying a given function to the value, if there is one.

We implement it as `flatMap` instead of `map` because it's more general: we can always implement `map` with `flatMap` and `unit` if we need to.

Speaking of which, monads in the Scala collection usually offer a host of useful methods in addition to `flatMap` and `unit`. Let's see how we can use these to improve our example code:

{% highlight scala linenos %}
def readAndAddOne: Option[Int] = readInt.map(_ + 1)
def readPositiveInt: Option[Int] = readInt.filter(_ >= 0)
def readAndSum: Option[Int] = 
    readInt.flatMap(x => readInt.map(y => x + y))
{% endhighlight %}

Using these methods allows us to dramatically reduce the number of lines of code, and more importantly, to reduce the implementation to the core logic; all boilerplate is gone.

Again, if you're not familiar with what these methods do on an `Option`, it's useful to think of what they do on lists.

Perhaps `readAndAddSum` is still a little complex. To solve this, Scala has for-comprehensions, which are syntactic sugar for `flatMap` and `unit`. This allows us to rewrite the function in a more legible way:

{% highlight scala linenos %}
def readAndSum: Option[Int] = for {
  a <- readInt
  b <- readInt
} yield a + b
{% endhighlight %}

## The power of monads™
As the example above shows, understanding monads can help us write short, legible, [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) code that respects the [principle of least power](http://www.lihaoyi.com/post/StrategicScalaStylePrincipleofLeastPower.html). In other words: better code. My advice to people who are new to functional programming or Scala is therefore two-fold:

**Know what a monad is**. A monad is a parametric type with a `flatMap` and a `unit` method. This sentence may sound complicated at first, but it succinctly outlines three simple requirements. In Scala, the following types fit the bill: `List`, `Set`, `Option`, `Either`, `Try` and `Future`[^almost-monad].

[^almost-monad]: `Future` and `Try` may not strictly be monads because they break referential transparency or monadic laws in subtle ways, but for the sake of this post, I think we can safely consider them "almost-monads".

**Use monadic functions**. Instead of writing complex, custom control flow or pattern matching, use `flatMap`, `filter`, `orElse`, or whatever else is available; build pipelines of monadic functions instead of nested logic. If you need to do complex things, use for-comprehensions.

Hopefully, an understanding of monads that goes just a bit further than "🌯" will improve your code.
