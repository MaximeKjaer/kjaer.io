---
title: CS-443 Machine Learning
description: "My notes from the CS-443 Machine Learning course given at EPFL, in the 2018 autumn semester (MA1)"
date: 2018-09-18
course: CS-443
---

The course follows a few books:

- Christopher Bishop, [Pattern Recognition and Machine Learning](https://www.springer.com/us/book/9780387310732)
- Kevin Patrick Murphy, [Machine Learning: a Probabilistic Perspective](https://www.cs.ubc.ca/~murphyk/MLbook/)
- Michael Nielsen, [Neural Networks and Deep Learning](http://neuralnetworksanddeeplearning.com/)

The repository for code labs and lecture notes is [on GitHub](https://github.com/epfml/ML_course). A useful website for this course is [matrixcalculus.org](http://www.matrixcalculus.org/).

<!-- More --> 

* TOC
{:toc}

In this course, we'll always denote the dataset as a $N \times D$ matrix $\mathbf{X}$, where $N$ is the data size and $D$ is the dimensionality, or the number of features. We'll always use subscript $n$ for data point, and $d$ for feature. The labels, if any, are denoted in a $\mathbf{y}$ vector, and the weights are denoted by $\mathbf{w}$:

$$
\newcommand{\vec}[1]{\mathbf{#1}}
\newcommand{\abs}[1]{\left\lvert#1\right\rvert}
\newcommand{\set}[1]{\left\{#1\right\}}
\newcommand{\norm}[1]{\left\lVert#1\right\rVert}
\newcommand{\frobnorm}[1]{\norm{#1}_{\text{Frob}}}
\newcommand{\expect}[1]{\mathbb{E}\left[#1\right]}
\newcommand{\expectsub}[2]{\mathbb{E}_{#1}\left[#2\right]}
\newcommand{\cost}[1]{\mathcal{L}\left(#1\right)}
\newcommand{\normal}[1]{\mathcal{N}\left(#1\right)}
\newcommand{\diff}[2]{\frac{\partial #1}{\partial #2}}
\newcommand{\difftwo}[3]{\frac{\partial^2 #1}{\partial #2 \partial #3}}
\newcommand{\Strain}{S_{\text{train}}}
\newcommand{\Stest}{S_{\text{test}}}
\DeclareMathOperator*{\argmax}{\arg\!\max}
\DeclareMathOperator*{\argmin}{\arg\!\min}

\vec{w}=\begin{bmatrix}
    w_1 \\ w_2 \\ \vdots \\ w_N
\end{bmatrix},
\quad
\vec{y}=\begin{bmatrix}
    y_1 \\ y_2 \\ \vdots \\ y_N
\end{bmatrix}, 
\quad
\vec{X}=\begin{bmatrix}
x_{11} & x_{12} & \dots & x_{1D} \\
x_{21} & x_{22} & \dots & x_{2D} \\
\vdots & \vdots & \ddots & \vdots \\
x_{N1} & x_{N2} & \dots & x_{ND} \\
\end{bmatrix}
$$

Vectors are denoted in bold and lowercase (e.g. $\vec{y}$ or $\vec{x}_n$), and matrices are bold and uppercase (e.g. $\vec{X}$). Scalars and functions are in normal font weight[^here-be-dragons].

[^here-be-dragons]: I've done my best to respect this notational convention everywhere in these notes, but a few mistakes may have slipped through. If you see any, please correct me in the comments below!

## Linear regression
A linear regression is a model that assumes a linear relationship between inputs and the output. We will study three types of methods:

1. Grid search
2. Iterative optimization algorithms
3. Least squares

### Simple linear regression

For a single input dimension ($D=1$), we can use a simple linear regression, which is given by:

$$
y_n \approx f(x_n) := w_0 + w_1 x_{n1}
$$

$\vec{w} = (w_0, w_1)$ are the parameters of the model.

### Multiple linear regression

If our data has multiple input dimensions, we obtain multivariate linear regression:

$$
y_n \approx 
    f(\vec{x}_n) := w_0 + w_1 x_{n1} + \dots + w_D x_{wD} 
    = w_0 + \vec{x}_n^T \begin{bmatrix}
        w_1 \\
        \vdots \\
        w_D \\
    \end{bmatrix}
    = \tilde{\vec{x}}_n^T \tilde{\vec{w}}
$$

> 👉 If we wanted to be a little more strict, we should write $f_{\vec{w}}(\vec{x}_n)$, as the model of course also depends on the weights.

The tilde notation means that we have included the offset term $w_0$, also known as the **bias**:

$$
\tilde{\vec{x}}_n=\begin{bmatrix}1 \\ x_{n1} \\ \vdots \\ x_{nD} \end{bmatrix} \in \mathbb{R}^{D+1}, 
\quad
\tilde{\vec{w}} = \begin{bmatrix}w_0 \\ w_1 \\ \vdots \\ w_D\end{bmatrix} \in \mathbb{R^{D+1}}
$$

### The $D > N$ problem

If the number of parameters exceeds the number of data examples, we say that the task is *under-determined*. This can be solved by regularization, which we’ll get to more precisely later.

## Cost functions

$\vec{x}_n$ is the data, which we can easily understand where comes from. But how does one find a good $\vec{w}$ from the data? 

A **cost function** (also called loss function) is used to learn parameters that explain the data well. It quantifies how well our model does by giving errors a score, quantifying penalties for errors. Our goal is to find parameters that minimize the loss functions.

### Properties

Desirable properties of cost functions are:

- **Symmetry around 0**: that is, being off by a positive or negative amount is equivalent; what matters is the amplitude of the error, not the sign.
- **Robustness**: penalizes large errors at about the same rate as very large errors. This is a way to make sure that outliers don’t completely dominate our regression.

### Good cost functions

#### MSE

Probably the most commonly used cost function is Mean Square Error (MSE): 

$$
\mathcal{L}_{\text{MSE}}(\vec{w}) := \frac{1}{N} \sum_{n=1}^N \left(y_n - f(\vec{x}_n)\right)^2
\label{def:mse}
$$

MSE is symmetrical around 0, but also tends to penalize outliers quite harshly (because it squares error): MSE is not robust. In practice, this is problematic, because outliers occur more often than we’d like to.

Note that we often use MSE with a factor $\frac{1}{2N}$ instead of $\frac{1}{N}$. This is because it makes for a cleaner derivative, but we'll get into that later. Just know that for all intents and purposes, it doesn't really change anything about the behavior of the models we'll study.

#### MAE

When outliers are present, Mean Absolute Error (MAE) tends to fare better:

$$
\text{MAE}(\vec{w}) := \frac{1}{N} \sum_{n=1}^N \left| y_n - f(\vec{x}_n)\right|
$$

Instead of squaring, we take the absolute value. This is more robust. Note that MAE isn’t differentiable at 0, but we’ll talk about that later.

There are other cost functions that are even more robust; these are available as additional reading, but are not exam material.

### Convexity

A function is **convex** iff a line joining two points never intersects with the function anywhere else. More strictly defined, a function $f(\vec{u})$ with $\vec{u}\in\chi$ is *convex* if, for any $\vec{u}, \vec{v} \in\chi$, and for any $0 \le\lambda\le 1$, we have:

$$
f(\lambda\vec{u}+(1-\lambda)\vec{v})\le\lambda f(\vec{u}) +(1-\lambda)f(\vec{v})
$$

A function is **strictly convex** if the above inequality is strict ($<$). This inequality is known as *Jensen's inequality*.

A strictly convex function has a unique global minimum $\vec{w}^*$. For convex functions, every local minimum is a global minimum. This makes it a desirable property for loss functions, since it means that cost function optimization is guaranteed to find the global minimum.

Linear (and affine) functions are convex, and sums of convex functions are also convex. Therefore, MSE and MAE are convex.

We'll see another way of characterizing convexity for differentiable functions [later in the course](#non-smooth-non-differentiable-optimization).

## Optimization

### Learning / Estimation / Fitting

Given a cost function (or loss function) $\cost{\vec{w}}$, we wish to find $\vec{w}^*$ which minimizes the cost:

$$
\min_{\vec{w}}{\cost{\vec{w}}}, \quad\text{ subject to } \vec{w} \in \mathbb{R}^D
$$

This is what we call **learning**: learning is simply an optimization problem, and as such, we’ll use an optimization algorithm to solve it – that is, find a good $\vec{w}$.

### Grid search

This is one of the simplest optimization algorithms, although far from being the most efficient one. It can be described as “try all the values”, a kind of brute-force algorithm; you can think of it as nested for-loops over the individual $w_i$ weights.

For instance, if our weights are $\vec{w} = \begin{bmatrix}w_1 \\ w_2\end{bmatrix}$, then we can try, say 4 values for $w_1$, 4 values for $w_2$, for a total of 16 values of $\mathcal{L}(\vec{w})$.

But obviously, complexity is exponential $\mathcal{O}(a^D)$ (where $a$ is the number of values to try), which is really bad, especially when we can have $D\approx$ millions of parameters. Additionally, grid search has no guarantees that it’ll find an optimum; it’ll just find the best value we tried.

If grid search sounds bad for optimization, that’s because it is. In practice, it is not used for optimization of parameters, but it *is* used to tune hyperparameters.

### Optimization landscapes

#### Local minimum

A vector $\vec{w}^\*$ is a *local minimum* of a function $\mathcal{L}$ (we’re interested in the minimum of cost functions $\mathcal{L}$, which we denote with $\vec{w}^*$, as opposed to any other value $\vec{w}$, but this obviously holds for any function) if $\exists \epsilon > 0$ such that

$$
\mathcal{L}(\vec{w}^*) \le \mathcal{L(\vec{w})}, \quad \forall \vec{w} : \norm{\vec{w} -\vec{w}^*} < \epsilon
$$

In other words, the local minimum $\vec{w}^*$ is better than all the neighbors in some non-zero radius.

#### Global minimum

The global minimum $\vec{w}^*$ is defined by getting rid of the radius $\epsilon$ and comparing to all other values:

$$
\cost{\vec{w}^*} \le \cost{\vec{w}}, \qquad \forall\vec{w}\in\mathbb{R}^D
$$

#### Strict minimum

A minimum is said to be **strict** if the corresponding equality is strict for $\vec{w} \ne \vec{w}^*$, that is, there is only one minimum value.

$$
\cost{\vec{w}^*} < \cost{\vec{w}}, \qquad \forall\vec{w}\in\mathbb{R}^D\setminus\set{\vec{w}^*}
$$

### Smooth (differentiable) optimization

#### Gradient

A gradient at a given point is the slope of the tangent to the function at that point. It points to the direction of largest increase of the function. By following the gradient (in the opposite direction, because we’re searching for a minimum and not a maximum), we can find the minimum.

![Graphs of MSE and MAE](/images/ml/mse-mae.png)

Gradient is defined by:

$$
\nabla \mathcal{L}(\vec{w}) := \begin{bmatrix}
    \diff{\cost{\vec{w}}}{w_1} & 
    \diff{\cost{\vec{w}}}{w_2} & 
	\cdots &
	\diff{\cost{\vec{w}}}{w_D}  \\
\end{bmatrix}^T
$$

This is a vector, i.e. $\nabla\cost{\vec{w}}\in\mathbb R^D$. Each dimension $i$ of the vector indicates how fast the cost $\mathcal{L}$ changes depending on the weight $w_i$.

#### Gradient descent

Gradient descent is an iterative algorithm. We start from a candidate $\vec{w}^{(t)}$, and iterate.

$$
\vec{w}^{(t+1)}:=\vec{w}^{(t)} - \gamma \nabla\mathcal{L}\left(\vec{w}^{(t)}\right)
$$

As stated previously, we’re adding the negative gradient to find the minimum, hence the subtraction.

$\gamma$ is known as the **step-size**, which is a small value (maybe 0.1). You don’t want to be too aggressive with it, or you might risk overshooting in your descent. In practice, the step-size that makes the learning as fast as possible is often found by trial and error 🤷🏼‍♂️.

As an example, we will take an analytical look at a gradient descent, in order to understand its behavior and components. We will do gradient descent on a 1-parameter model ($D=1$ and $\vec{w} = [w_0]$), in which we minimize the MSE, which is defined as follows:

$$
\mathcal{L}\left(w_0\right)=\frac{1}{2N}\sum_{n=1}^N{\left(y_n - w_0\right)^2}
$$

Note that we’re dividing by 2 on top of the regular MSE; it has no impact on finding the minimum, but when we will compute the gradient below, it will conveniently cancel out the $\frac{1}{2}$.

The gradient of $\cost{w_0}$ is:

$$
\begin{align}
\nabla\cost{\vec{w}}
	& = \frac{\partial}{\partial w_0}\cost{\vec{w}} \\
	& = \frac{1}{2N}\sum_{n=1}^N{-2(y_n - w_0)}  \\
	& = w_0 - \bar{y}
\end{align}
$$

Where $\bar{y}$ denotes the average of all $y_n$ values. And thus, our gradient descent is given by:

$$
\begin{align}
w_0^{(t+1)}
	&:= w_0^{(t)} - \gamma\nabla\mathcal{L}\left(\vec{w}\right) \\
	& = w_0^{(t)} - \gamma(w_0^{(t)} - \bar{y}) \\
	& = (1-\gamma)w_0^{(t)} + \gamma\bar{y}, 
	\qquad\text{where } \bar{y}:=\sum_{n}{\frac{y_n}{N}}
\end{align}
$$

In this case, we've managed to find to this exact problem analytically from gradient descent. This sequence is guaranteed to converge to $\vec{w}^* = \bar{y}$[^optimality-linear-mse]. This would set the cost function to 0, which is the minimum.

[^optimality-linear-mse]: To understand why, see the sections on [optimality conditions](#optimality) and on [single parameter linear regressions](#single-parameter-linear-regression) 

The choice of $\gamma$ has an influence on the algorithm’s outcome:

- If we pick $\gamma=1$, we would get to the optimum in one step
- If we pick $\gamma < 1$, we would get a little closer in every step, eventually converging to $\bar{y}$
- If we pick $\gamma > 1$, we are going to overshoot $\bar{y}$. Slightly bigger than 1 (say, 1.5) would still converge; $\gamma=2$ would loop infinitely between two points; $\gamma > 2$ diverges.

#### Gradient descent for linear MSE

Our linear regression is given by a line $\vec{y}$ that is a regression for some data $\vec{X}$:

$$
\vec{y}=\begin{bmatrix}
	y_1 \\ y_2 \\ \vdots \\ y_N
\end{bmatrix}, 
\quad
\vec{X}=\begin{bmatrix}
x_{11} & x_{12} & \dots & x_{1D} \\
x_{21} & x_{22} & \dots & x_{2D} \\
\vdots & \vdots & \ddots & \vdots \\
x_{N1} & x_{N2} & \dots & x_{ND} \\
\end{bmatrix}
$$

We make predictions by multiplying the data by the weights, so our model is:

$$
f_{\vec{w}}(\vec{x}_n)=\vec{x}_n^T \vec{w}
$$

We define the error vector by:

$$
\vec{e}=\vec{y} - \vec{Xw}, 
\quad \text{ or } \quad 
e_n = y_n - \vec{x}_n^T\vec{w}
$$

The MSE can then be restated as follows:

$$
\mathcal{L}\left(\vec{w}\right)
	:= \frac{1}{2N}\sum_{n=1}^N{\left( y_n - \vec{x}_n^T \vec{w}\right)^2}
	=  \frac{1}{2N}\vec{e}^T\vec{e}
$$

And the gradient is, component-wise:

$$
\frac{\partial}{\partial\vec{w}_d} \cost{\vec{w}}
	= -\frac{1}{2N} \sum_{n=1}^N {2(y_n - \vec{x}_n^T \vec{w}) x_{nd}}
	= -\frac{1}{N} (\vec{X}_{:d})^T \vec{e}
$$

We’re using column notation $\vec{X}_{:d}$ to signify column $d$ of the matrix $X$.

And thus, all in all, our gradient is:

$$
\nabla\cost{\vec{w}} = -\frac{1}{N}\vec{X}^T\vec{e}
$$

To compute this expression, we must compute:

- The error $\vec{e}$, which takes $2N\cdot D - 1$ floating point operations (flops) for the matrix-vector multiplication, and $N$ for the subtraction, for a total of $2N\cdot D + N - 1$, which is $\mathcal{O}(N\cdot D)$
- The gradient $\nabla\mathcal{L}$, which costs $2N\cdot D + D - 1$, which is $\mathcal{O}(N\cdot D)$.

In total, this process is $\mathcal{O}(N\cdot D)$ at every step. This is not too bad, it’s equivalent to reading the data once.

#### Stochastic gradient descent (SGD)

In ML, most cost functions are formulated as a sum of:

$$
\mathcal{L}\left(\vec{w}\right) = \frac{1}{N}\sum_{n=1}^N{\mathcal{L}_n(\vec{w})}
$$

In practice, this can be expensive to compute, so the solution is to sample a training point $n\in\set{1, N}$ uniformly at random, to be able to make the sum go away.

The stochastic gradient descent step is thus:

$$
\vec{w}^{(t+1)}:=\vec{w}^{(t)} - \gamma \nabla\mathcal{L}_n\left({\vec{w}^{(t)}}\right)
$$

Why is it allowed to pick just one $n$ instead of the full thing? We won’t give a full proof, but the intuition is that:

$$
\expect{\nabla\mathcal{L}_n(\vec{w})}
	= \frac{1}{N} \sum_{n=1}^N{\nabla\mathcal{L}_n(\vec{w})}
	= \nabla\left(\frac{1}{N} \sum_{n=1}^N{\mathcal{L}_n(\vec{w})}\right)
	\equiv \nabla\mathcal{L}\left(\vec{w}\right)
$$

The gradient of a single n is:

$$
\mathcal{L}_n(\vec{w}) = \frac{1}{2} \left(y_n -\vec{x}_n^T \vec{w}\right)^2 \\
\nabla\mathcal{L}_n(\vec{w}) = (-\vec{x}_n^T) (y_n-\vec{x}_n^T \vec{w})
$$

Note that $\vec{x}_n^T \in\mathbb{R}^D$, and $e_n = (y_n-\vec{x}_n^T \vec{w})\in\mathbb{R}$. Computational complexity for this is $\mathcal{O}(D)$. 

#### Mini-batch SGD

But perhaps just picking a **single** value is too extreme; there is an intermediate version in which we choose a subset $B\subseteq \set{1, \dots, N}$ instead of a single point.

$$
\vec{g} := \frac{1}{|B|}\sum_{n\in B}{\nabla\mathcal{L}_n(\vec{w}^{(t)})} \\
\vec{w}^{(t+1)} := \vec{w}^{(t)} - \gamma\vec{g}
$$

Note that if $\abs{B} = N$ then we’re performing a full gradient descent.

The computation of $\vec{g}$ can be parallelized easily over $\abs{B}$ GPU threads, which is quite common in practice; $\abs{B}$ is thus often dictated by the number of available threads.

Computational complexity is $\mathcal{O}(\abs{B}\cdot D)$.

### Non-smooth (non-differentiable) optimization

We’ve defined [convexity previously](#convexity), but we can also use the following alternative characterization of convexity, for differentiable functions:

$$
\cost{\vec{u}} \ge \cost{\vec{w}} + \nabla \cost{\vec{w}}^T (\vec{u} - \vec{w}) 
\quad \forall \vec{u}, \vec{w}
\iff \mathcal{L} \text{ convex}
$$

Meaning that the function must always lie above its linearization (which is the first-order Taylor expansion) to be convex.

![A convex function lies above its linearization](/images/ml/convex-above-linearization.png)

#### Subgradients

A vector $\vec{g}\in\mathbb{R}^D$ such that:

$$
\mathcal{L}\left(\vec{u}\right) \ge \mathcal{L}\left(\vec{w}\right) + \vec{g}^T(\vec{u} - \vec{w}) \quad \forall \vec{u}
$$

is called a **subgradient** to the function $\mathcal{L}$ at $\vec{w}$. The subgradient forms a line that is always below the curve, somewhat like the gradient of a convex function.

![The subgradient lies below the function](/images/ml/subgradient-below-function.png)

This definition is valid even for an arbitrary $\mathcal{L}$ that may not be differentiable, and not even necessarily convex.

If the function $\mathcal{L}$ is differentiable at $\vec{w}$, then the *only subgradient* at $\vec{w}$ is $\vec{g} = \nabla\mathcal{L}\left(\vec{w}\right)$.

#### Subgradient descent

This is exactly like gradient descent, except for the fact that we use the *subgradient* $\vec{g}$ at the current iterate $\vec{w}^{(t)}$ instead of the *gradient*:

$$
\vec{w}^{(t+1)} := \vec{w}^{(t)} - \gamma\vec{g}
$$

For instance, MAE is not differentiable at 0, so we must use the subgradient.

$$
\text{Let }h: \mathbb{R} \rightarrow \mathbb{R}, \quad h(e) := |e| \\
\text{At } e, \text{the subgradient }
g \in \partial h = \begin{cases}
-1 & \text{if } e < 0 \\
[-1, 1] & \text{if } e = 0 \\
1 & \text{if } e > 0 \\
\end{cases}
$$

Here, $\partial h$ is somewhat confusing notation for the set of all possible subgradients at our position.

For linear regressions, the (sub)gradient is easy to compute using the *chain rule*.

Let $h$ be non-differentiable, $q$ differentiable, and $\mathcal{L}\left(\vec{w}\right) = h(q(w))$. The chain rule tells us that, at $\vec{w}$, our subgradient is:

$$
g \in \partial h(q(\vec{w})) \cdot \nabla q(\vec{w})
$$

#### Stochastic subgradient descent

This is still commonly abbreviated SGD.

It’s exactly the same, except that $\vec{g}$ is a subgradient to the randomly selected $\mathcal{L}_n$ at the current iterate $\vec{w}^{(t)}$.



### Comparison

|                             | Smooth                                                       | Non-smooth                                                   |
| --------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Full gradient descent       | Gradient of $$\mathcal{L}$$ <br />Complexity is $\mathcal{O}(N\cdot D)$ | Subgradient of $\mathcal{L}$<br />Complexity is $\mathcal{O}(N\cdot D)$ |
| Stochastic gradient descent | Gradient of $\mathcal{L}_n$                                | Subgradient of $\mathcal{L}_n$                             |



### Constrained optimization

Sometimes, optimization problems come posed with an additional constraint.

#### Convex sets

We’ve seen convexity for functions, but we can also define it for sets. A set $\mathcal{C}$ is convex iff the line segment between any two points of $\mathcal{C}$ lies in $\mathcal{C}$. That is, $\forall \vec{u}, \vec{v} \in \mathcal{C}, \quad \forall 0 \le \theta \le 1$, we have:

$$
\theta \vec{u} + (1 - \theta)\vec{v} \in \mathcal{C}
$$

This means that the line between any two points in the set $\mathcal{C}$ must also be fully contained within the set.

![Examples of convex and non-convex sets](/images/ml/convex-sets.png)

A couple of properties of convex sets:

- Intersection of convex sets is also convex.
- Projections onto convex sets are **unique** (and often efficient to compute).


#### Projected gradient descent

When dealing with constrained problems, we have two options. The first one is to add a projection onto $\mathcal{C}$ in every step:

$$
P_\mathcal{C}(\vec{w}') := \argmin_{\vec{v}\in\mathcal{C}}{\norm{\vec{v}-\vec{w}'}}
$$

The rule for gradient descent can thus be updated to become:

$$
\vec{w}^{(t+1)} := P_\mathcal{C}\left(\vec{w}^{(t)} - \gamma \nabla \cost{\vec{w}^{(t)}} \right)
$$

This means that at every step, we compute the new $w^{(t+1)}$ normally, but apply a projection on top of that. In other words, if the regular gradient descent sets our weights outside of the constrained space, we project them back.

<figure>
    <img alt="Steps of projected SGD" src="/images/ml/projected-sgd.png" />
    <figcaption>Here, $\vec{w}'$ is the result of regular SGD, i.e. $\vec{w}' = \vec{w}^{(t)} - \gamma \nabla\cost{\vec{w}^{(t)}}$</figcaption>
</figure>

This is the same for stochastic gradient descent, and we have the same convergence properties.

Note that the computational cost of the projection is very important here, since it is performed at every step.

#### Turning constrained problems into unconstrained problems

If projection as described above is approach A, this is approach B.

We use a **penalty function**, such as the “brick wall” indicator function below:

$$
I_\mathcal{C}(\vec{w}) = \begin{cases}
0 & \vec{w} \in \mathcal{C} \\
+\infty & \vec{w} \notin \mathcal{C}
\end{cases}
$$

We could also perhaps use something with a less drastic error value than $+\infty$, if we don’t care about the constraint quite as extreme.

Note that this is similar to regularization, which we’ll talk about later. 

Now, instead of directly solving $\min_{\vec{w}\in\mathcal{C}}{\mathcal{L}(\vec{w})}$, we solve for:

$$
\min_{\vec{w}\in \mathbb{R}^D} {
    \mathcal{L}(\vec{w}) + I_\mathcal{C}(\vec{w})
}
$$

### Implementation issues in gradient methods

#### Stopping criteria

When $\norm{\nabla\mathcal{L}(\vec{w})}$ is zero (or close to zero), we are often close to the optimum.

#### Optimality
For a convex optimization problem, a *necessary* condition for optimality is that the gradient is 0 at the optimum:

$$
\text{optimum at }\vec{w}^*, \quad \mathcal{L} \text{ convex} 
\implies 
\nabla\cost{\vec{w}^*} = 0
$$

For convex functions, if the gradient is 0, then we're at an optimum:

$$
\nabla\cost{\vec{w}^*} = 0, \quad \mathcal{L} \text{ convex} 
\implies 
\text{optimum at }\vec{w}^*
$$

This tells us when $\vec{w}^*$ is an optimum, but says nothing about whether it's a minimum or a maximum. To know about that, we must look at the second derivative, or in the general case where $D > 1$, the Hessian. The Hessian is the matrix of second derivatives, defined as follows:

$$
\vec{H}_{ij} = \difftwo{\mathcal{L}}{w_i}{w_j}
$$

If the Hessian of the optimum is [positive semi-definite](https://en.wikipedia.org/wiki/Positive-definite_matrix), then it is a minimum (and not a maximum or a saddle point):

$$
\vec{H}(\vec{w}^*) := \difftwo{\cost{\vec{w}^*}}{\vec{w}}{\vec{w}^T} \text{ positive semidefinite}
\implies
\vec{w}^* \text{ is a minimum}
$$

The Hessian is also related to convexity; it is positive semi-definite on its entire domain (i.e. all its eigenvalues are non-negative) if and only if the function is convex.

$$
\vec{H} \text{ positive semidefinite}
\iff
\mathcal{L} \text{ convex}
$$

#### Step size

If $\gamma$ is too big, we might diverge ([as seen previously](#gradient-descent)). But if it is too small, we might be very slow! Convergence is only guaranteed for $\gamma < \gamma_{min}$, which is a value that depends on the problem. 

## Least squares

### Normal equations

In some rare cases, we can take an analytical approach to computing the optimum of the cost function, rather than a computational one; for instance, for linear regression with MSE, as we've done previously. These types of equations are sometimes called **normal equations**. This is one of the most popular methods for data fitting, called **least squares**.

How do we get these normal equations?

First, we show that the problem is convex. If that is the case, then according to the [optimality conditions](#optimality) for convex functions, the point at which the derivative is zero is the optimum:

$$
\nabla\cost{\vec{w}^*}=\vec{0}
$$

This gives us a system of $D$ equations known as the normal equations.

### Single parameter linear regression
Let's try this for a single parameter linear regression (where $D = 1$), with MSE as the cost function. We will start by accepting that the cost function is convex in the $w_0$ parameter[^mse-is-convex].

[^mse-is-convex]: We accept this without a formal proof for now, but it should be clear from the [section on convexity](#convexity) that MSE is convex. Otherwise, the section on [normal equations for multi-parameter linear regression](#multiple-parameter-linear-regression) has more complete proofs.

As [proven previously](#gradient-descent), we know that for the single parameter model, the derivative is:

$$
\begin{align}
\nabla\mathcal{L}\left(\vec{w}\right)
    & = \frac{\partial}{\partial w_0}\mathcal{L} \\
    & = \frac{1}{2N}\sum_{n=1}^N{-2(y_n - w_0)}  \\
    & = w_0 - \bar{y}
\end{align}
$$

This means that the derivative is 0 for $w_0 = \bar{y}$. This allows us to define our optimum parameter $\vec{w}^\*$ as $\vec{w}^* = \begin{bmatrix}\bar{y}\end{bmatrix}$.

### Multiple parameter linear regression

Having done $D=1$, let's look at the general case where $D \ge 1$. As we know by now, the cost function for linear regression with MSE is:

$$
\mathcal{L}\left(\vec{w}\right)
	:= \frac{1}{2N}\sum_{n=1}^N{\left( y_n - \vec{x}_n^T \vec{w}\right)^2}
	=  \frac{1}{2N}(\vec{y-Xw})^T(\vec{y-Xw})
$$


Where the matrices are defined as:

$$
\vec{y}=\begin{bmatrix}
	y_1 \\ y_2 \\ \vdots \\ y_N
\end{bmatrix}, 
\quad
\vec{X}=\begin{bmatrix}
x_{11} & x_{12} & \dots & x_{1D} \\
x_{21} & x_{22} & \dots & x_{2D} \\
\vdots & \vdots & \ddots & \vdots \\
x_{N1} & x_{N2} & \dots & x_{ND} \\
\end{bmatrix}
$$


We denote the $i^\text{th}$ row of $X$ by $x_i^T$. Each $x_i^T$ represents a different data point.

We claim that this cost function is *convex* in $\vec{w}$. We can prove that in any of the following ways:

***

#### Simplest way
The cost function is the sum of many convex functions, and is thus also convex.

#### Directly verify the definition

$$
\forall \lambda\in [0,1], 
\quad \forall \vec{w}, \vec{w}',
\qquad
\mathcal{L}\left(\lambda\vec{w} + \left(1-\lambda\right)\vec{w}'\right) 
- \left(\lambda\mathcal{L}(\vec{w}) + \left( 1-\lambda \right) \mathcal{L}(\vec{w}')\right) \le 0
$$
  
The left-hand side of the inequality reduces to:
  
$$
-\frac{1}{2N}\lambda(1-\lambda)\norm{\vec{X}(\vec{w}-\vec{w}')}_2^2
$$
   
which indeed is $\le 0$.

#### Compute the Hessian

As [we've seen previously](#optimality), if the Hessian is positive semidefinite, then the function is convex. For our case, the Hessian is given by:
  
$$
\frac{1}{N}\vec{X}^T\vec{X}
$$
  
This is indeed positive semi-definite, as its eigenvalues are the squares of the eigenvalues of $\vec{X}$, and must therefore be positive.

***

Knowing that the function is convex, we can find the minimum. If we take the gradient of this expression, we get:

$$
\nabla\mathcal{L}(\vec{w}) = -\frac{1}{N}\vec{X}^T(\vec{y-Xw})
$$

We can set this to 0 to get the normal equations for linear regression, which are:

$$
\vec{X}^T(\vec{y-Xw}) =: \vec{X}^T\vec{e} = \vec{0}
$$

This proves that the normal equations for linear regression are given by $\vec{X}^T\vec{e} = \vec{0}$.

### Geometric interpretation

The above definition of normal equations are given by $\vec{X}^T\vec{e} = \vec{0}$. How can visualize that?

The error is given by:

$$
\vec{e} := \vec{y} - \vec{Xw}
$$

By definition, this error vector is orthogonal to all columns of $\vec{X}$. Indeed, it tells us how far above or below the span our prediction $\vec{y}$ is. 

The **span** of $\vec{X}$ is the space spanned by the columns of $\vec{X}$. Every element of the span can be written as $\vec{u} = \vec{Xw}$ for some choice of $\vec{w}$. 

For the normal equations, we must pick an optimal $\vec{w}^\*$ for which the gradient is 0. Picking an $\vec{w}^\*$ is equivalent to picking an optimal $\vec{u}^* = \vec{Xw}^\*$ from the span of $\vec{X}$.

But which element of $\text{span}(\vec{X})$ shall we take, which one is the optimal one? The normal equations tell us that the optimum choice for $\vec{u}$, called $$\vec{u}^*$$ is the element such that $$\vec{y} - \vec{u}^*$$ is orthogonal to $\text{span}(X)$.

In other words, we should pick $\vec{u}^*$ to be the projection of $\vec{y}$ onto $\text{span}(\vec{X})$.

![Geometric interpretation of the normal equations](/images/ml/geometric-interpretation-normal-equations.png)


### Closed form
All we've done so far is to solve the same old problem of a matrix equation:

$$
Ax = b
$$

But we've always done so with a bit of a twist; there may not be an exact value of $x$ satisfying exact equality, but we could find one that gets us as close as possible:

$$
Ax \approx b
$$

This is also what least squares does. It attempts to minimize the MSE to get as $Ax$ close as possible to $b$.

In this course, we often denote the data matrix $A$ as $\vec{X}$, the weights $x$ as $\vec{w}$, and $b$ as $y$; in other words, we're trying to solve:

$$
\vec{X}\vec{w} \approx \vec{y}
$$

In least squares, we multiply this whole equation by $\vec{X}^T$ on the left. We attempt to find $\vec{w}^*$, the minimal weight that gets us as minimally wrong as possible. In other we're trying to solve:

$$
\left( \vec{X}^T\vec{X} \right) \vec{w} \approx \vec{X}^T\vec{y}
$$

One way to solve this problem would simply be to invert the $A$ matrix, which in our case is $\vec{X}^T\vec{X}$:

$$
\vec{w}^* = (\vec{X}^T\vec{X})^{-1} \vec{X}^T y
$$

As such, we can use this model to predict values for unseen data points:

$$
\hat{y}_m := \vec{x}_m^T \vec{w}^* = \vec{x}_m^T (\vec{X}^T\vec{X})^{-1} \vec{X}^T y
$$

### Invertibility and uniqueness
Note that the Gram matrix, defined as $\vec{X}^T\vec{X} \in \mathbb{R}^{D\times D}$, is invertible **if and only if** $\vec{X}$ has **full column rank**, or in other words, $\text{rank}(\vec{X}) = D$.

$$
\vec{X}^T\vec{X} \in \mathbb{R}^{D\times D} \text{ invertible}
\iff
\text{rank}(\vec{X}) = D
$$

Unfortunately, in practice, our data matrix $\vec{X}\in\mathbb{R}^{N\times D}$ is often **rank-deficient**.

- If $D>N$, we always have $\text{rank}(\vec{X}) < D$ (since column and row rank are the same, which implies that $\text{rank}(\vec{X}) \le N < D$).
- If $D \le N$, but some of the columns $\vec{X}_{:d}$ are collinear (or in practice, nearly collinear), then the matrix is **ill-conditioned**. This leads to numerical issues when solving the linear system.
  
  To know how bad things are, we can compute the condition number, which is the maximum eigenvalue of the Gram matrix, divided by the minimum See course contents of Numerical Methods.

If our data matrix is rank-deficient or ill-conditioned (which is practically always the case), we certainly shouldn't be inverting it directly! We'll introduce high numerical errors that falsify our output.

That doesn't mean we can't do least squares in practice. We can still use a linear solver. In Python, that means you should use [`np.linalg.solve`](https://docs.scipy.org/doc/numpy/reference/generated/numpy.linalg.solve.html), which uses a LU decomposition internally and thus avoids the worst numerical errors. In any case, do not directly invert the matrix as we have done above! 


## Maximum likelihood
Maximum likelihood offers a second interpretation of least squares, but starting with a probabilistic approach.

### Gaussian distribution
A Gaussian random variable in $\mathbb{R}$ has mean $\mu$ and variance $\sigma^2$. Its distribution is given by: 

$$
\normal{y \mid \mu, \sigma^2} = 
    \frac{1}{\sqrt{2\pi\sigma^2}} 
    \exp{\left[ -\frac{(y-\mu)^2}{2\sigma^2} \right]}
$$

For a Gaussian random *vector*, we have $\vec{y} \in \mathbb{R}^N$ (instead of a single random variable in $\mathbb{R}$). The vector has mean $\pmb{\mu}$ and covariance $\pmb{\Sigma}$ (which is positive semi-definite), and its distribution is given by:

$$
\pmb{\mathcal{N}}(\vec{y} \mid \pmb{\mu}, \pmb{\Sigma}) = 
    \frac{1}
         {\sqrt{(2\pi)^D \text{ det}(\pmb{\Sigma})}} 

    \exp{\left[ -\frac{1}{2} (\vec{y} - \pmb{\mu})^T \pmb{\Sigma}^{-1} (\vec{y} - \pmb{\mu}) \right]}
$$

As another reminder, two variables $x$ and $y$ are said to be **independent** when $p(x, y) = p(x)p(y)$.

### A probabilistic model for least squares
We assume that our data is generated by a linear model $\vec{x}_n^T\vec{w}$, with added Gaussian noise $\epsilon_n$:

$$
y_n = \vec{x}_n^T\vec{w} + \epsilon_n
$$

This is often a realistic assumption in practice.

![Noise generated by a Gaussian source](/images/ml/gaussian-noise.png)

The noise is $\epsilon_n \overset{\text{i.i.d.}}{\sim}\normal{y_n \mid \mu = 0, \sigma^2}$ for each dimension $n$. In other words, it is centered at 0, has a certain variance, and the error in each dimension is independent of that in other dimensions. 


The model $\vec{w}$ is, as always, unknown. But we can try to do a thought experiment: if we did know the model $\vec{w}$ the data $\vec{X}$, in a system without the noise $\epsilon_n$, we would know the labels $\vec{y}$ with 100% certainty. The only thing that prevents that is the noise $\epsilon_n$; therefore, given the model and data, the probability distribution of seeing a certain $\vec{y}$ is only given by all the noise sources $\epsilon_n$. Since they are generated independently in each dimension, we can take the product of these noise sources. 

Therefore, given $N$ samples, the **likelihood** of the data vector $\vec{y} = (y_1, \dots, y_n)$ given the model $\vec{w}$ and the input $\vec{X}$ is:

$$
p(\vec{y} \mid \vec{X}, \vec{w}) 
    = \prod_{n=1}^N {p(y_n \mid \vec{x}_n, \vec{w})}
    = \prod_{n=1}^N {\normal{y_n \mid \vec{x}_n^T\vec{w}, \sigma^2}}
$$

Intuitively, we'd like to maximize this likelihood over the choice of the best model $\vec{w}$. The best model is the one that maximizes this likelihood.

### Defining cost with log-likelihood
The log-likelihood (LL) is given by:

$$
\mathcal{L}_{LL}(\vec{w}) := \log{p(\vec{y} \mid \vec{X}, \vec{w})}
    = - \frac{1}{2\sigma^2} \sum_{n=1}^N{\left(y_n - \vec{x}_n^T\vec{w}\right)^2} + \text{ cnst}
$$

Taking the log allows us to get away from the nasty product, and get a nice sum instead. Notice that this definition looks pretty similar to MSE:

$$
\mathcal{L}_{\text{MSE}}(\vec{w}) := \frac{1}{N} \sum_{n=1}^N \left(y_n - \vec{x}_n^T\vec{w}\right)^2
$$

Note that we would like to minimize MSE, but we want the log-likelihood to be as high as possible (intuitively, we can look at the sign to understand that).

### Maximum likelihood estimator (MLE)
Maximizing the log-likelihood (and thus the likelihood) will be equivalent to minimizing the MSE; this gives us another way to design cost functions. We can describe the whole process as:

$$
\argmin_{\vec{w}}{\mathcal{L}_\text{MSE}(\vec{w})} =
\argmax_{\vec{w}}{\mathcal{L}_\text{LL}(\vec{w})}
$$

The maximum likelihood estimator (MLE) can be understood as finding the model under which the observed data is most likely to have been generated from (probabilistically). This interpretation has some advantages that we discuss below. 

#### Properties of MLE
MLE is a *sample* approximation to the *expected log-likelihood*. In other words, if we had an infinite amount of data, MLE would perfectly be equal to the true expected value of the log-likelihood.

$$
\mathcal{L}_{LL}(\vec{w}) 
    \approx \expectsub{p(y, \vec{x})}{\log{p(y \mid \vec{x}, \vec{w})}}
$$

This means that MLE is **consistent**, i.e. it gives us the correct model assuming we have enough data. This means it converges in probability[^convergence-prob-distrib] to the true value:

$$
\vec{w}_\text{MLE} \overset{p}{\longrightarrow} \vec{w}_\text{true}
$$

MLE is asymptotically normal, meaning that the difference between the approximation and the true value of the weights converges in distribution[^convergence-prob-distrib] to a normal distribution centered at 0, and with variance $\frac{1}{N}$ times the Fisher information of the true value:

[^convergence-prob-distrib]: Convergence in probability means that the actual realizations of $X$ converges to that of $Y$ (i.e. $\mathbb{P}(X=Y)\rightarrow 1$), while convergence in distribution means that the distribution function of $X$ converges to that of $Y$ (but without any guarantee that the actual realizations will be the same). Convergence in probability implies convergence in distribution, and is therefore a stronger assertion.

$$
(\vec{w}_{\text{MLE}} - \vec{w}_{\text{true}}) 
\overset{d}{\longrightarrow}
\frac{1}{\sqrt{N}} \normal{\vec{w}_{\text{MLE}} \mid \vec{0}, \vec{F}^{-1}(\vec{w}_{\text{true}})}
$$

Where the Fisher information[^fisher-information] is:

$$
\vec{F}(\vec{w}) 
= -\expectsub{p(\vec{y})}{
    \frac{\partial^2\mathcal{L}}{\partial\vec{w}\partial\vec{w}^T}
}
$$

[^fisher-information]: Fisher information is a way of measuring the information that a random variable carries about an unknown parameter. See [the Wikipedia article for Fisher information](https://en.wikipedia.org/wiki/Fisher_information).

This sounds amazing, but the catch is that this all is under the assumption that the noise $\epsilon$ indeed was generated under a Gaussian model, which may not always be true. We'll relax this assumption later when we talk about [exponential families](#exponential-family).

## Overfitting and underfitting
Models can be too limited; when we can't find a function that fits the data well, we say that we are *underfitting*. But on the other hand, models can also be too rich: in this case, we don't just model the data, but also the underlying noise. This is called *overfitting*. Knowing exactly where we are on this spectrum is difficult, since all we have is data, and we don't know a priori what is signal and what is noise.

Sections 3 and 5 of Pedro Domingos' paper [*A Few Useful Things to Know about Machine Learning*](https://homes.cs.washington.edu/~pedrod/papers/cacm12.pdf) are a good read on this topic.

### Underfitting with linear models
Linear models can very easily underfit; as soon as the data itself is given by anything more complex than a line, fitting a linear model will underfit: the model is too simple for the data, and we'll have huge errors.

But we can also easily overfit, where our model learns the specificities of the data too intimately. And this happens quite easily with linear combination of high-degree polynomials.

### Extended feature vectors
We can actually get high-degree linear combinations of polynomials, but still keep our linear model. Instead of making the model more complex, we simply "augment" the input to become degree $M$. If the input is one-dimensional, we can add a polynomial basis to the input:

$$
\pmb{\phi}(x_n) =
\begin{bmatrix}
1 & x_n & x_n^2 & x_n^3 & \dots & x_n^M
\end{bmatrix}
$$

Note that this is basically a [Vandermonde matrix](https://en.wikipedia.org/wiki/Vandermonde_matrix).

We then fit a linear model to this extended feature vector $\pmb{\phi}(x_n)$:

$$
y_n \approx w_0 + w_1 x_n + w_2 x_n^2 + \dots + w_m x_n^M =: \pmb{\phi}(x_n)^T\vec{w}
$$

Here, $\vec{w}\in\mathbb{R}^{M+1}$. In other words, there are $M+1$ parameters in a degree $M$ extended feature vector. One should be careful with this degree; too high may overfit, too low may underfit.

If it is important to distinguish the original input $\vec{x}$ from the augmented input $\pmb{\phi}(\vec{x})$ then we will use the $\pmb{\phi}(\vec{x})$ notation. But often, we can just consider this as a part of the pre-processing, and simply write $\vec{x}$ as the input, which will save us a lot of notation.

### Reducing overfitting
To reduce overfitting, we can chose a less complex model (in the above, we can pick a lower degree $M$), but we could also just add more data:

![An overfitted model acts more reasonably when we add a bunch of data](/images/ml/reduce-overfit-add-data.png)

## Regularization
To prevent overfitting, we can introduce **regularization** to penalize complex models. This can be applied to any model.

The idea is to not only minimize cost, but also minimize a regularizer:

$$
\min_{\vec{w}} {\mathcal{L}(\vec{w}) + \Omega(\vec{w})}
$$

The $\Omega$ function is the regularizer, measuring the complexity of the model. We'll see some good candidates for the regularizer below.

### $L_2$-Regularization: Ridge Regression
The most frequently used regularizer is the standard Euclidean norm ($L_2$-norm):

$$
\Omega(\vec{w}) = \lambda \norm{\vec{w}}^2_2
$$

Where $\lambda \in \mathbb{R}$. The value of $\lambda$ will affect the fit; $\lambda \rightarrow 0$ can have overfitting, while $\lambda \rightarrow \infty$ can have underfitting.

The norm is given by:

$$
\norm{\vec{w}}_2^2 = \sum_i{w_i^2}
$$

The main effect of this is that large model weights $w_i$ will be penalized, while small ones won't affect our minimization too much.

#### Ridge regression
Depending on the values we choose for $\mathcal{L}$ and $\Omega$, we get into some special cases. For instance, choosing MSE for $\mathcal{L}$ is called **ridge regression**, in which we optimize the following:

$$
\min_{\vec{w}} {\left(\frac{1}{N} \sum_{n=1}^N \left[y_n - f(\vec{x}_n)\right]^2 \quad + \quad \Omega(\vec{w})\right)}
$$

Least squares is also a special case of ridge regression, where $\lambda = 0$

We can find an explicit solution for $\vec{w}$ in ridge regression by differentiating the cost and regularizer, and setting them to zero:

$$
\begin{align}
\nabla \mathcal{L}(\vec{w}) & = -\frac{1}{N} \vec{X}^T (\vec{y} - \vec{Xw}) \\ \\
\nabla \Omega(\vec{w}) & = 2\lambda \vec{w} \\
\end{align}
$$

We can now set the full cost to zero, which gives us the result:

$$
\vec{w}^*_\text{ridge} = (\vec{X}^T\vec{X} + \lambda' \vec{I})^{-1}\vec{X}^T\vec{y}
$$

Where $\frac{\lambda'}{2N} = \lambda$. Note that for $\lambda = 0$, we have the least squares solution. 

#### Ridge regression to fight ill-conditioning 
This formulation of $\vec{w}^*$ is quite nice, because adding the identity matrix helps us get something that always is invertible; in cases where we have ill-conditioned matrices, it also means that we can invert with more stability.

We'll prove that the matrix indeed is invertible. The gist is that the eigenvalues of $(\vec{X}^T\vec{X} + \lambda' \vec{I})$ are all at least $\lambda'$. 

To prove it, we'll write the singular value decomposition (SVD) of $\vec{X}^T\vec{X}$ as $\vec{USU}^T$. We then have:

$$
\vec{X}^T\vec{X} + \lambda'\vec{I} = \vec{USU}^T + \lambda'\vec{UIU}^T = \vec{U}(\vec{S} + \lambda'\vec{I})\vec{U}^T
$$

The singular value is "lifted" by an amount $\lambda'$. There's an alternative proof in the class notes, but we won't go into that.

### $L_1$-Regularization: The Lasso
We can use a different norm as an alternative measure of complexity. The combination of $L_1$-norm and MSE is known as **The Lasso**:

$$
\min_{\vec{w}} {\frac{1}{2N} \sum_{n=1}^N \left[y_n - f(\vec{x}_n)\right]^2 + \lambda \norm{\vec{w}}_1}
$$

Where the $L_1$-norm is defined as

$$
\norm{\vec{w}}_1 := \sum_i{\abs{w_i}}
$$

If we draw out a constant value of the $L_1$ norm, we get a sort of "ball". Below, we've graphed $\set{\vec{w} : \norm{\vec{w}}_1 \le 5}$.

![Graph of the lasso](/images/ml/lasso.png)

To keep things simple in the following, we'll just claim that $\vec{X}^T\vec{X}$ is invertible. We'll also claim that the following set is an ellipsoid which scales around the origin as we change $\alpha$:

$$
\set{\vec{w} : \norm{\vec{y} - \vec{Xw}}^2 = \alpha}
$$

The slides have a formal proof for this, but we won't get into it.

Note that the above definition of the set corresponds to the set of points with equal loss (which we can assume is MSE, for instance):

$$
\set{\vec{w} : \cost{\vec{w}} = \alpha}
$$

Under these assumptions, we claim that for $L_1$ regularization, the optimum solution will likely be sparse (many zero components) compared to $L_2$ regularization.

To prove this, suppose we know the $L_1$ norm of the optimum solution. Visualizing that ball, we know that our optimum solution $\vec{w}^\*$ will be somewhere on the surface of that ball. We also know that there are ellipsoids, all with the same mean and rotation, describing the equal error surfaces. The optimum solution is where the "smallest" of these ellipsoids just touches the
$L_1$ ball.

![Intersection of the L1 ball and the cost ellipses](/images/ml/ball-ellipse.png)

Due to the geometry of this ball this point is more likely to be on one of the "corner" points. In turn, sparsity is desirable, since it leads to a "simple" model.

## Model selection
As we've seen in ridge regression, we have a *regularization parameter* $\lambda > 0$ that can be tuned to reduce overfitting by reducing model complexity. We say that the parameter $\lambda$  is a **hyperparameter**.

We've also seen ways to enrich model complexity, like [polynomial feature expansion](#extended-feature-vectors), in which the degree $M$ is also a hyperparameter.

We'll now see how best to choose these hyperparameters; this is called the **model selection** problem.

### Probabilistic setup
We assume that there is an (unknown) underlying distribution $\mathcal{D}$ producing the dataset, with range $\mathcal{X}\times\mathcal{Y}$. The dataset $S$ we see is produced from samples from $\mathcal{D}$:

$$
S = \set{
    (\vec{x}_n, y_n) \overset{\text{i.i.d}}{\sim} \mathcal{D}
}_{n=1}^N
$$

Based on this, the *learning algorithm* $\mathcal{A}$ choses the "best" model using the dataset $S$, under the parameters of the algorithm. The resulting prediction function is $f_s = \mathcal{A}(S)$. To indicate that $f_s$ sometimes depend on hyperparameters, we can write the prediction function as $f_{s, \lambda}$.

### Training Error vs. Generalization Error
Given a model $f$, how can we assess if $f$ is any good? We already have the loss function, but its result is highly dependent on the error in the data, not to how good the model is. Instead, we can compute the *expected error* over all samples chosen according to $\mathcal{D}$.

$$
L_\mathcal{D}(f) = \expectsub{\mathcal{D}}{\mathcal{l}(y, f(\vec{x}))}
$$

Where $\mathcal{l}(\cdot, \cdot)$ is our loss function; e.g. for ridge regression, $\mathcal{l}(y, f(\vec{x})) = \frac{1}{2}(y-f(\vec{x}))^2$.

The quantity $L_\mathcal{D}(f)$ has many names, including **generalization error** (or true/expected error/risk/loss). This is the quantity that we are fundamentally interested in, but we cannot compute it since $\mathcal{D}$ is unknown.

What we do know is the data subset[^data-subset-training-data] $S$. It's therefore natural to compute the equivalent *empirical* quantity, which is the average loss:

[^data-subset-training-data]: We say "data subset" here, because, as [we'll see later](#splitting-the-data), the data available to the learning algorithm $\mathcal{A}$ is often a subset of the whole dataset, called the training set. In this subsection, $S$ actually corresponds to $\Strain$.

$$
L_S(f) = \frac{1}{\abs{S}} \sum_{(\vec{x}_n, y_n)\in S} {\mathcal{l}(y_n, f(\vec{x}_n))}
$$

But again, we run into trouble. The function $f$ is itself a function of the data $S$, so what we really do is to compute the quantity:

$$
L_S(f_S) = \frac{1}{\abs{S}} \sum_{(\vec{x}_n, y_n)\in S} {\mathcal{l}(y_n, f_S(\vec{x}_n))}
$$

$f_S$ is the trained model. This is called the **training error**. Usually, the training error is smaller than the generalization error, because overfitting can happen (even with regularization, because the hyperparameter may still be too low).

### Splitting the data
To avoid validating the model on the same data subset we trained it on (which is conducive to overfitting), we can split the data into a **training set** and a **test set** (aka *validation set*), which we call $\Strain$ and $\Stest$, so that $S = \Strain \oplus \Stest$. A typical split could be 80% for training and 20% for testing.

We apply the learning algorithm $\mathcal{A}$ on the training set $\Strain$, and compute the function $f_{\Strain}$. We then compute the error on the test set, which is the **test error**:

$$
L_{\Stest}(f_{\Strain}) = \frac{1}{\abs{\Stest}} \sum_{(\vec{x}_n, y_n)\in \Stest} {\mathcal{l}(y_n, f_{\Strain}(\vec{x}_n))}
$$

If we have duplicates in our data, then this could be a bit dangerous. Still, in general, this really helps us with the problem of overfitting since $\Stest$ is a "fresh" sample, which means that we can hope that $L_{\Stest}(f_{\Strain})$ defined above is close to the quantity $L_\mathcal{D}(f_{\Strain})$. Indeed, *in expectation* both are the same:

$$
L_\mathcal{D}(f_{\Strain}) 
= \expectsub{\Stest\sim\mathcal{D}}{
    L_{\Stest}(f_{\Strain})
}
$$

The subscript on the expectation means that the expectation is over samples of the test set, and not for a particular test set (which could give a different result due to the randomness of the selection of $\Stest$).

This is a quite nice property, but we paid a price for this. We had to split the data and thus reduce the size of our training data. But we will see that this can be mediated using cross-validation.

### Generalization error vs test error
Assume that we have a model $f$ and that our loss function $\mathcal{l}(\cdot, \cdot)$ is bounded in $[a, b]$. We are given a test set $\Stest$ chosen i.i.d. from the underlying distribution $\mathcal{D}$. 

How far apart is the empirical test error from the true generalization error? As we've seen above, they are the same in expectation. But we need to worry about the variation, about how far off from the true error we typically are:

We claim that:

$$
\mathbb{P}\left[
    \abs{L_\mathcal{D}(f) - L_{\Stest}(f)}
    \ge
    \sqrt{\frac{(b-a)^2 \ln{(2/\delta)}}{2\abs{\Stest}}}
\right]
\le \delta
\label{eq:loss-bound}
\tag{loss-bound}
$$

Where $\delta > 0$ is a quality parameter. This gives us an upper bound on how far away our empirical loss is from the true loss.

This bound gives us some nice insights. Error decreases in the size of the test set as $\mathcal{O}(1/\sqrt{\abs{\Stest}})$, so the more data points we have, the more confident we can be in the empirical loss being close to the true loss.

We'll prove $\ref{eq:loss-bound}$. We assumed that each sample in the test set is chosen independently. Therefore, given a model $f$, the associated losses $\mathcal{l}(y_n, f(\vec{x}_n))$ are also i.i.d. random variables, taking values in $[a, b]$ by assumption. We can call each such loss $\Theta_n$:

$$
\Theta_n = \mathcal{l}(y_n, f(\vec{x}_n))
$$

This is just a naming alias; since the underlying value is that of the loss function, the expected value of $\Theta_n$ is simply that of the loss function, which is the true loss:

$$
\expect{\Theta_n} = \expect{\mathcal{l}(y_n, f(\vec{x}_n))} = L_\mathcal{D}(f)
$$

The empirical loss on the other hand is equal to the average of $\abs{\Stest}$ such i.i.d. values. 

The formula of $\ref{eq:loss-bound}$ gives us the probability that empirical loss $L_{\Stest}(f)$ diverges from the true loss by more than a given constant, which is a classical problem addressed in the following lemma (which we'll just assert, not prove).

**Chernoff Bound**: Let $\Theta_1, \dots, \Theta_N$ be a sequence of i.i.d random variables with mean $\expect{\Theta}$ and range $[a, b]$. Then, for any $\epsilon > 0$:

$$
\mathbb{P}\left[
    \abs{\frac{1}{N}\sum_{n=1}^N {\Theta_n - \expect{\Theta}}}
    \ge
    \epsilon
\right]
\le
2\exp{\left(\frac{-2N\epsilon^2}{(b-a)^2}\right)}
\label{eq:Chernoff}
\tag{Chernoff}
$$

Using $\ref{eq:Chernoff}$ we can show $\ref{eq:loss-bound}$. By setting $\delta = 2\exp{\left(\frac{-2N\epsilon^2}{(b-a)^2}\right)}$, we find that $\epsilon = \sqrt{\frac{(b-a)^2 \ln{(2/\delta)}}{2\abs{\Stest}}}$ as claimed.

### Method and criteria for model selection

#### Grid search on hyperparameters
Our main goal was to look for a way to select the hyperparameters of our model. Given a finite set of values $\lambda_k$ for $k=1, \dots, K$ of a hyperparameter $\lambda$, we can run the learning algorithm $K$ times on the same training set $\Strain$, and compute the $K$ prediction functions $f_{\Strain, \lambda_k}$. For each such prediction function we compute the test error, and choose the $\lambda_k$ which minimizes the test error.

![Grid search on lambda](/images/ml/cross-validation.png)

This is essentially a grid search on $\lambda$ using the test error function.

#### Model selection based on test error
How do we know that, for a fixed function $f$, $L_{\Stest}(f)$ is a good approximation to $L_\mathcal{D}(f)$? If we're doing a grid search on hyperparameters to minimize the test error $L_{\Stest}(f)$, we may pick a model that obtains a lower test error, but that may increase $\abs{L_\mathcal{D}(f) - L_{\Stest}(f)}$. 

We'll therefore try to see how much the bound increases if we pick a false positive, a model that has lower test error but that actually strays further away from the generalization error.

The answer to this follows the same idea as when we talked about [generalization vs test error](#generalization-error-vs-test-error), but we now assume that we have $K$ models $f_k$ for $k=1, \dots, K$. We assume again that the loss function is bounded in $[a, b]$, and that we're given a test set whose samples are chosen i.i.d. in $\mathcal{D}$.

How far is each of the $K$ (empirical) test errors $L_{\Stest}(f_k)$ from the true $L_\mathcal{D}(f_k)$? As before, we can bound the deviation for all $k$ candidates, by:

$$
\mathbb{P}\left[
    \max_k {\abs{L_\mathcal{D}(f_k) - L_{\Stest}(f_k)}}
    \ge
    \sqrt{\frac{(b-a)^2 \ln{(2K/\delta)}}{2\abs{\Stest}}}
\right]
\le \delta
$$

A bit of intuition of where this comes from: for a general $K$, we check the deviations for $K$ independent samples and ask for the probability that for at least one such sample we get a deviation of at least $\epsilon$ (this is what the $\ref{eq:Chernoff}$ bound answers). Then by the [union bound](https://en.wikipedia.org/wiki/Boole%27s_inequality) this probability is at most $K$ times as large as in the case where we are only concerned with a single instance. Thus the upper bound in Chernoff becomes $2K\exp{\left(\frac{-2N\epsilon^2}{(b-a)^2}\right)}$, which gives us $\epsilon = \sqrt{\frac{(b-a)^2 \ln{(2K/\delta)}}{2\abs{\Stest}}}$ as above.

As before, this tells us that error decreases in $\mathcal{O}(1/\sqrt{\abs{\Stest}})$.

However, now that we test $K$ hyperparameters, our error only goes up by a tiny amount of $\sqrt{\ln{(K)}}$. This follows from $\ref{eq:loss-bound}$, which we proved for the special case of $K = 1$. So we can reasonably do grid search, knowing that in the worst case, the error will only increase by a tiny amount.

### Cross-validation
Splitting the data once into two parts (one for training and one for testing) is not the most efficient way to use the data. Cross-validation is a better way.

K-fold cross-validation is a popular variant. We randomly partition the data into $K$ groups, and train $K$ times. Each time, we use one of the $K$ groups as our test set, and the remaining $K−1$ groups for training. 

To get a common result, we average out the $K$ results. This means we'll use  the average weights to get the average test error over the $K$ folds.

Cross-validation returns an unbiased estimate of the generalization error and its variance.

### Bias-Variance decomposition
When we perform model selection, there is an inherent [bias&ndash;variance](https://en.wikipedia.org/wiki/Bias%E2%80%93variance_tradeoff) trade-off.

<figure>
    <img src="/images/ml/bias-variance.png" alt="Bullseye representation of bias vs variance">
    <figcaption>Graphical illustration of bias and variance. Taken from <a href="http://scott.fortmann-roe.com/docs/BiasVariance.html">Scott Fortmann-Roe's website</a></figcaption>
</figure>

If we were to build the same model over and over again with re-sampled datasets, our predictions would change because of the randomness in the used datasets. Bias tells us how far off from the correct value our predictions are in general, while variance tells us about the variability in predictions for a given point in-between realizations of the models.

For now, we'll just look at "high-bias & low-variance" models, and "high-variance & low-bias" models.

- **High-bias & low-variance**: the model is too simple. It's underfit, has a large bias, and and the variance of $L_\mathcal{D}(f_S)$ is small (the variations due to the random sample $S$).
- **High-variance & low-bias**: the model is too complex. It's overfit, has a small bias and large variance of $L_\mathcal{D}(f_S)$ (the error depends largely on the exact choice of $S$; a single addition of a data point is likely to change the prediction function $f_S$ considerably)

Consider a linear regression with one-dimensional input and [polynomial feature expansion](#extended-feature-vectors) of degree $d$. The former can be achieved by picking a too low value for $d$, while the latter by picking $d$ too high. The same principle applies for other parameters, such as ridge regression with hyperparameter $\lambda$.

#### Data generation model
Let's assume that our data is generated by some arbitrary, unknown function $f$, and a noise source $\epsilon$ with distribution $\mathcal{D}_\epsilon$ (i.i.d. from sample to sample, and independent from the data). We can think of $f$ representing the precise, hypothetical function that perfectly produced the data. We assume that the noise has mean zero (without loss of generality, as a non-zero mean could be encoded into $f$).

$$
y = f(\vec{x}) + \epsilon
$$

We assume that $\vec{x}$ is generated according to some fixed but unknown distribution $\mathcal{D}_{\vec{x}}$. We'll be working with square loss $\mathcal{l}(y, f(\vec{x})) = \frac{1}{2}(y-f(\vec{x}))^2$. We will denote the joint distribution on pairs $(\vec{x}, y)$ as $\mathcal{D}$.

$$
\begin{align}
\epsilon     & \sim \mathcal{D}_\epsilon \\
\vec{x}      & \sim \mathcal{D}_x \\
(\vec{x}, y) & \sim \mathcal{D} \\
\end{align}
$$

#### Error Decomposition
As always, we have a training set $\Strain$, which consists of $N$ i.i.d. samples from $\mathcal{D}$. Given our learning algorithm $\mathcal{A}$, we compute the prediction function $f_{\Strain} = \mathcal{A}(\Strain)$. The square loss of a single prediction for a fixed element $\vec{x}_0$ is given by the computation of:

$$
\mathcal{l}(y_0, f_{\Strain}(\vec{x}_0))
=
\bigl( y_0 - f_{\Strain}(\vec{x}_0) \bigr)^2
= 
\bigl( f(\vec{x}_0) + \epsilon - f_{\Strain}(\vec{x}_0) \bigr)^2
$$

Our experiment was to create $\Strain$, learn $f_{\Strain}$, and then evaluate the performance by computing the square loss for a fixed element $\vec{x}_0$. If we run this experiment many times, the expected value is written as:

$$
\expectsub{\Strain \sim \mathcal{D},\ \epsilon\sim\mathcal{D}_\epsilon}{
    \left( f(\vec{x}_0) + \epsilon - f_{\Strain}(\vec{x}_0) \right)^2
}
$$

This expectation is over randomly selected training sets of size $N$, and over noise sources. We will now show that this expression can be rewritten as a sum of three non-negative terms:

$$
\newcommand{\otherconstantterm}{\expectsub{\Strain'\sim\mathcal{D}}{f_{\Strain'}(\vec{x}_0)}}

\begin{align}
& \expectsub{\Strain \sim \mathcal{D},\ \epsilon\sim\mathcal{D}_\epsilon} {
    \left( f(\vec{x}_0) + \epsilon - f_{\Strain}(\vec{x}_0) \right)^2
} \\

\overset{(a)}{=}\  & 
    \expectsub{\epsilon\sim\mathcal{D}_\epsilon} {
        \epsilon^2
    }
    + \expectsub{\Strain \sim \mathcal{D}} {
        \bigl(f(\vec{x}_0) - f_{\Strain}(\vec{x}_0)\bigl)^2
    } \\

\overset{(b)}{=}\ & 
    \text{Var}_{\epsilon\sim\mathcal{D}_\epsilon}\left[\epsilon\right]
    + \expectsub{\Strain \sim \mathcal{D}}{
        \bigl(f(\vec{x}_0) - f_{\Strain}(\vec{x}_0)\bigl)^2
    } \\

\overset{(c)}{=}\ &
    \underbrace{
        \text{Var}_{\epsilon\sim\mathcal{D}_\epsilon}\left[\epsilon\right]
    }_\text{noise variance} \\
& + \underbrace{
    \left( f(\vec{x}_0) - \otherconstantterm \right)^2
}_\text{bias} \\
& + \expectsub{\Strain\sim\mathcal{D}} {
        \underbrace{
            \left( \otherconstantterm - f_{\Strain(\vec{x}_0)} \right)^2
        }_\text{variance}
    } \\
\end{align}
$$

Note that here, $S\'\_\text{train}$ is a second training set, also sampled from $\mathcal{D}$, that is independent of the training set $\Strain$. It has the same expectation, but it is different and thus produces a different trained model $f_{S'}$.

Step $(a)$ uses $(u+v)^2 = u^2 + 2uv + v^2$ as well as linearity of expectation to produce $\expect{(u+v)^2} = \expect{u^2} + 2\expect{uv} + \expect{v^2}$. Note that the $2uv$ part is zero as the noise $\epsilon$ is independent from $\Strain$.

Step $(b)$ uses the definition of variance as:

$$
\text{Var}(X) = \expect{(X - \expect{X})^2} = \expect{X^2} - \expect{X}^2
$$

Seeing that our noise $\epsilon$ has mean zero, we have $\expect{\epsilon}^2 = 0$ and therefore $\text{Var}(\epsilon) = \expect{\epsilon^2}$. 

In step $(c)$, we add and subtract the constant term $\otherconstantterm$ to the expression like so:

$$
\expectsub{\Strain \sim \mathcal{D}}{\left(
    \underbrace{f(\vec{x}_0) - \otherconstantterm}_u 
+   \underbrace{\otherconstantterm - f_{\Strain}(\vec{x}_0)}_v
\right)^2}
$$

We can then expand the square $(u+v)^2 = u^2 + 2uv + v^2$, where $u^2$ becomes the bias, and $v^2$ the variance. We can drop the expectation around $u^2$ as it is over $\Strain$, while $u^2$ is only defined in terms of $\Strain'$, which is independent from $\Strain$. The $2uv$ part of the expansion is zero, as we show below:

$$
\begin{align}
& 2 \cdot \expectsub{\Strain\sim\mathcal{D}} {
    \left( 
        f(\vec{x}_0) - \otherconstantterm 
    \right) \cdot \left(
        \otherconstantterm - f_{\Strain}(\vec{x}_0)
    \right)
} \\
& = 2 \cdot \left(
    f(\vec{x}_0) - \otherconstantterm 
\right) \cdot \expectsub{\Strain\sim\mathcal{D}} {
    \otherconstantterm - f_{\Strain}(\vec{x}_0)
} \\
& = 2 \cdot \left(
    f(\vec{x}_0) - \otherconstantterm 
\right) \cdot \left(
    \otherconstantterm - \expectsub{\Strain\sim\mathcal{D}}{f_{\Strain}(\vec{x}_0)}
\right) \\
& = 0 \\
\end{align} 
$$

In the first step, we can pull $u$ out of the expectation as it is a constant term with regards to $\Strain$. The same reasoning applies to $\otherconstantterm$ in the second step. Finally, we get zero in the third step by realizing that:

$$
\otherconstantterm = \expectsub{\Strain\sim\mathcal{D}}{f_{\Strain}(\vec{x}_0)}
$$

#### Interpretation of the decomposition
Each of the three terms in non-negative, so each of them is a lower bound on the expected loss when we predict the value for the input $\vec{x}_0$.

- When the data contains **noise**, then that imposes a strict lower bound on the error we can achieve.
- The **bias term** is a non-negative term that tells us how far we are from the true value, in expectation. It's the square loss between the true value $f(\vec{x}_0)$ and the expected prediction $\otherconstantterm$, where the expectation is over the training sets. As [we discussed above](#bias-variance-decomposition), with a simple model we will not find a good fit on average, which means the bias will be large, which adds to the error we observe.
- The **variance term** is the variance of the prediction function. For complex models, small variations in the data set can produce vastly different models, and our prediction will vary widely, which also adds to our total error.

## Classification
When we did regression, our data was of the form:

$$
\Strain = \set{(\vec{x}_n, y_n)}_{n=1}^N,
\qquad \vec{x}_n \in \mathbb{R}^d,\ y_n \in\mathbb{R}
$$

With **classification**, our prediction is no longer discrete. Now, $y_n\in\set{\mathcal{C}\_0, \dots, \mathcal{C}_{K-1}}$. If it can only take two values (i.e. $K=2$), then it is called **binary classification**. If it can take more than two values, it is **multi-class classification**.

There is no ordering among these classes, so we may sometimes denote these labels as $y\in\set{0, 1, 2, \dots, K-1}$.

If we knew the underlying distribution $\mathcal{D}$, then it would be clear how we could measure the probability of error. We have a correct prediction when $y - f(\vec{x}) = 0$, and an incorrect one otherwise, so:

$$
\expectsub{\mathcal{D}}{\mathbb{I}\set{y-f(\vec{x}) \ne 0}} = \mathbb{P}(y-f(\vec{x}) \ne 0)
$$

Where $\mathbb{I}$ is an indicator function that returns 1 when the condition is correct, and 0 otherwise. If we don't know the distribution, we could just take an empirical sum, and use that instead.

A classifier will divide the input space into a collection of regions belonging to each class; the boundaries are called **decision boundaries**.

### Linear classifier

A linear classifier splits the input with a line in 2D, a plane in 3D, or more generally, a hyperplane. But a linear classifier can also classify more complex shapes if we allow for [feature augmentation](#extended-feature-vectors). For instance (in 2D), if we augment the input to degree $M=2$ and a constant factor, our linear classifier can also detect ellipsoids. So without loss of generality, we'll simply study linear classifiers and allow feature augmentation, without loss of generality.

### Is classification a special case of regression?
From the initial definition of classification, we see that it is a special case of regression, where the output $y$ is restricted to a small discrete set instead of a continuous spectrum.

We could construct classification from regression by simply rounding to the nearest $\mathcal{C}\_i$ value. For instance, if we have $y\in\left\\{0, 1\right\\}$, we can use (regularized) least-squares to learn a prediction function $f_{\Strain}$ for this regression problem. We can then convert the regression to a classification by rounding: we decide on $\mathcal{C}\_1=0$ if $f_{\Strain}(\vec{x})<0.5$ and $\mathcal{C}\_2=1$ if $f_{\Strain}(\vec{x})>0.5$.

But this is somewhat questionable as an approach. MSE penalizes points that are far away from the result **before rounding**, even though they would be correct **after rounding**. 

This means that if we have a small loss with MSE, we can guarantee a small classification error (as before), but crucially, the opposite is not true: a regression function can have very high MSE though the classification error is very very small.

It also means that the regression line will likely not be very good. With MSE, the "position" of the line defined by $f_{\Strain}$ will depend crucially on how many points are in each class, and where the points lie. This is not desirable for classification: instead of minimizing the cost function, we'd like for the fraction of misclassified cases to be small. The mean-squared error turns out to be only loosely related to this.

![Example of a regression being skewed by the number of points in each class](/images/ml/regression-for-classification.png)

So instead of building classification as a special case of regression, let's take a look at some basic alternative ideas to perform classification.

### Nearest neighbor
In some cases it is reasonable to postulate that there is some spatial correlations between points of the same class: inputs that are "close" are also likely to have the same label. Closeness may be measured by Euclidean distance, for instance.

This can be generalized easily: instead of taking the single nearest neighbor, a process very prone to being swayed by outliers, we can take the $k$ nearest neighbors (which we'll talk about [later in the course](#k-nearest-neighbor-knn)), or a weighted linear combination of elements in the neighborhood ([smoothing kernels](https://en.wikipedia.org/wiki/Kernel_smoother), which we won't talk about).

But this idea fails miserably in high dimensions, where the geometry renders the idea of "closeness" meaningless. High-dimensional space is a very lonely place; in a high-dimensional space, if we grow the area around a point, we're likely to see no one for a very long time, and then once we get close to the boundaries of the space, 💥, everyone is there at once. This is known as the [curse of dimensionality](https://en.wikipedia.org/wiki/Curse_of_dimensionality). 

The idea also fails when we have too little data, especially in high dimensions, where the closest point may actually be far away and a very bad indicator of the local situation.

### Linear decision boundaries 
As a starting point, we can assume that decision boundaries are linear (hyperplanes). To keep things simple, we can assume that there is a separating hyperplane, i.e. a hyperplane so that no point in the training set is misclassified.

There may be many such lines, so which one do we pick? This may be a little hand-wavy, but the intuition is the most "robust", or the one that offers the greatest "margin": we want to be able to "wiggle" the inputs (by changing the training set) as much as possible while keeping the numbers of misclassifications low. This idea will lead us to [*support vector machines* (SVMs)](#support-vector-machines).

But the linear decision boundaries are limited, and in many cases too strong of an assumption. We can augment the feature vector with some non-linear functions, which is what we do with [the kernel trick](#kernel-trick), which we will talk about later. Another option is to use neural networks to find an appropriate non-linear transform of the inputs.

### Optimal classification for a known generating model
To find a solution, we can gain some insights if we assume that we know the joint distribution $p(\vec{x}, y)$ that created the data (where $y$ takes values in a discrete set $\mathcal{y}$). In practice, we don't know the model, but this is just a thought experiment. We can assume that the data was generated from a model $(\vec{x}, y)\sim\mathcal{D}$, where $y=g(\vec{x})+\epsilon$, where $\epsilon$ is noise.

Given the fact that there is noise, a perfect solution may not always be possible. But if we see an input $\vec{x}$, how can we pick an optimal choice $\hat{y}(\vec{x})$ for this distribution? We want to maximize the probability of guessing the correct label, so we should choose according to the rule:

$$
\hat{y}(\vec{x}) = \argmax_{y\in\mathcal{Y}}{p(y\mid\vec{x})}
$$

This is known as the maximum a-posteriori (MAP) criterion, since we maximize the posterior probability (the probability of a class label *after* having observed the input).

The probability of a correct guess is thus the average over all inputs of the MAP, i.e.:

$$
\mathbb{P}(\hat{y}(\vec{x}) = y) = \int{p(\vec{x})p(\hat{y}(\vec{x})\mid \vec{x})dx}
$$

In practice we of course do not know the joint distribution, but we could use this approach by using the data itself to learn the distribution (perhaps under the assumption that it is Gaussian, and just fitting the $\mu$ and $\sigma$ parameters).

## Logistic regression
Recall that [we discussed](#is-classification-a-special-case-of-regression) what happens if we look at binary classification as a regression. We also discussed that it is tempting to look at the predicted value as a probability (i.e. if the regression says 0.8, we could interpret it as 80% certainty of $\mathcal{C}\_1 = 1$ and 20% probability of $\mathcal{C}\_0 = 0$). But this leads to problems, as the predicted values may not be in $[0, 1]$, even largely surpassing these bounds, and this contributes to the error in MSE even though they indicate high certainty.

So the natural idea is to *transform* the prediction, which can take values in $(-\infty, \infty)$, into a true probability in $[0, 1]$. This is done by applying an appropriate function[^squishification-function], one of which is the *logistic function*, or *sigmoid function*[^logistic-implementation]:

[^squishification-function]: Because this function squeezes inputs in $(-\infty, \infty)$ into a true probability in $[0, 1]$, I like the name "squishification function" that [3Blue1Brown uses](https://www.youtube.com/watch?v=aircAruvnKk), but other people also call it a "squashing" function.

[^logistic-implementation]: Note that this function applies the exponential function to rather large values, so we should be careful when implementing this.

$$
\sigma(z) := \frac{e^z}{1+e^z} = \frac{1}{1+e^{-z}}
$$

How do we use this? Let's consider binary classification, with labels 0 and 1. Given a training set, we learn a weight vector $\vec{w}$. Given a new feature vector $\vec{x}$, the *probability* of the class labels given $\vec{x}$ are:

$$
\begin{align}
p(1 \mid \vec{x}) & = \sigma(\vec{x}^T\vec{w}) \\
p(0 \mid \vec{x}) & = 1 - \sigma(\vec{x}^T\vec{w}) \\
\end{align}
$$

This allows us to predict a certainty, which is a real value and not a label, which is why logistic regression is called regression, even though it is still part of a classification scheme. The second step of the scheme would be to quantize this value to a binary value. For binary classification, we'd pick 0 if the value is less than 0.5, and 1 otherwise.

### Training
To train the classifier, the intuition is that we'd like to maximize the likelihood of our weight vector explaining the data:

$$
\argmax_{\vec{w}}{p(\vec{y}, \vec{X} \mid \vec{w})}
$$

We know that [maximizing the likelihood](#properties-of-mle) is **consistent**, it gives us the correct model assuming we have enough data. Using the chain rule for probabilities, the probability becomes:

$$
p(\vec{y}, \vec{X} \mid \vec{w}) = p(\vec{X}\mid\vec{w})p(\vec{y} \mid \vec{X}, \vec{w}) = p(\vec{X})p(\vec{y} \mid \vec{X}, \vec{w})
$$

As we're trying to get the argmax over the weights, we can discard $p(\vec{X})$ as it doesn't depend on $\vec{w}$. Therefore:

$$
\argmax_{\vec{w}}{p(\vec{y}, \vec{X} \mid \vec{w})} = \argmax_{\vec{w}}{p(\vec{y} \mid \vec{X}, \vec{w})}
$$

Using the fact that the samples in the dataset are independent, and given the above formulation of the prior, we can express the maximum likelihood criterion (still for the binary case $K=2$)

$$
\begin{align}
p(\vec{y} \mid \vec{X}, \vec{w})
    & = p(y_1, \dots, y_N \mid \vec{x}_1, \dots, \vec{x}_N, \vec{w}) \\
    & = \prod_{n=1}^N{p(y_n \mid \vec{x}_n, \vec{w})} \\
    & = \prod_{n=1}^N{\sigma(\vec{x}_n^T \vec{w})^{y_n} (1-\sigma(\vec{x}_n^T \vec{w}))^{1-y_n}} \\
\end{align}
$$

But this product is nasty, so we'll remove it by taking the log. We also multiply by $-1$, which means we also need to be careful about taking the minimum instead of the maximum. The resulting cost function is thus:

$$
\begin{align}
\cost{\vec{w}}
    & = -\sum_{n=1}^N{\left[
        y_n \log{(\sigma(\vec{x}_n^T \vec{w}))} + (1-y_n)\log{(1-\sigma(\vec{x}_n^T \vec{w}))}
    \right]} \\
    & = \sum_{n=1}^N{\log{(1+\exp{(\vec{x}_n^T \vec{w})})} - y_n \vec{x}_n^T \vec{w}}
    \tag{Log-Likelihood}\label{eq:log-likelihood}
\end{align}
$$

### Conditions of optimality
As we discuss above, we'd like to minimize the cost $\cost{\vec{w}}$. Let's look at the stationary points of our cost function by computing its gradient and setting it to zero.

It just turns out that taking the derivative of the logarithm in the inner part of the sum above gives us the logistic function:

$$
\diff{\log{(1+\exp{(\vec{x}_n^T \vec{w})})}}{\vec{x}_n} = \sigma(\vec{x}_n)
$$

Therefore, the whole derivative is:

$$
\begin{align}
\nabla\cost{\vec{w}} 
    & = \sum_{n=1}^N {\vec{x}_n (\sigma(\vec{x}_n^T\vec{w}) - y_n)} \\
    & = \vec{X}^T \left[ \sigma(\vec{Xw}) - \vec{y} \right]
\end{align}
$$

The matrix $\vec{X}$ is $N\times N$; both $\vec{y}$ and $\vec{w}$ are column vectors of length $N$. Therefore, to simplify notation, we let $\sigma(\vec{Xw})$ represent element-wise application of the sigmoid function on the size $N$ vector resulting from $\vec{Xw}$.

There is no closed-form solution for this, so we'll discuss how to solve it in an iterative fashion by using gradient descent or the Newton method.

### Gradient descent
$\ref{eq:log-likelihood}$ is convex in the weight vector $\vec{w}$. We can therefore do gradient descent on this cost function as we've always done:

$$
\vec{w}^{(t+1)} := \vec{w}^{(t)} - \gamma^{(t)}\nabla\cost{\vec{w}^{(t)}}
$$

### Newton's method
Gradient descent is a *first-order* method, using only the first derivative of the cost function. We can get a more powerful optimization algorithm using the second derivative. This is based on the idea of Taylor expansions. The 2<sup>nd</sup> order Taylor expansion of the cost, around $\vec{w}^*$, is:

$$
\cost{\vec{w}} \approx \cost{\vec{w}^*}^T(\vec{w}-\vec{w}^*) + \frac{1}{2}(\vec{w}-\vec{w}^*)^T \vec{H}(\vec{w}^*)(\vec{w}-\vec{w}^*)
$$

Where $\vec{H}$ denotes the Hessian, the $D\times D$ symmetric matrix with entries:

$$
\vec{H}_{i, j} = \frac{\partial^2\cost{\vec{w}}}{\partial w_i \partial w_j}
$$

#### Hessian of the cost
Let's compute this Hessian matrix. We've already computed the gradient of the cost function [in the section above](#conditions-of-optimality), where saw that the gradient of a single term is:

$$
\vec{x}_n \sigma(\vec{x}_n^T\vec{w}) - y_n
$$

Each term only depends on $\vec{w}$ in the $\sigma(\vec{x}_n^T w)$ term. Therefore, the Hessian associated to one term is:

$$
\vec{x}_n(\nabla\sigma(\vec{x}_n^T\vec{w}))^T
$$

Given that the derivative of the sigmoid is $\sigma'(x) = \sigma(x)(1-\sigma(x))$, by the [chain rule](https://en.wikipedia.org/wiki/Chain_rule), each term of the sum gives rise to the Hessian:

$$
\vec{x}_n\vec{x}_n^T\sigma(\vec{x}_n^T \vec{w})(1 - \sigma(\vec{x}_n^T \vec{w}))
$$

This is the Hessian for a single term; if we sum up over all terms, we get to the following matrix product:

$$
\begin{align}
\vec{H}(\vec{w}) 
    & = \sum_{n=1}^N{\nabla^2\mathcal{L}_n(\vec{w})} \\
    & = \sum_{n=1}^N{
        \underbrace{\vec{x}_n \vec{x}_n^T}_{D\times D}
        \sigma(\vec{x}_n^T \vec{w})
        \bigl(1 - \sigma(\vec{x}_n^T \vec{w}) \bigr)
    } \\
    & = \underbrace{\ \vec{X}^T \ }_{D\times N} \ 
        \underbrace{\ \vec{S}   \ }_{N\times N} \ 
        \underbrace{\ \vec{X}   \ }_{N\times D} \\
\end{align}
$$

The $\vec{S}$ matrix is diagonal, with positive entries, which means that the Hessian is positive semi-definite, and therefore that the problem indeed is convex. The entries are:

$$
S_{n, n} = \sigma(\vec{x}_n^T \vec{w})\bigl(1 - \sigma(\vec{x}_n^T \vec{w}) \bigr)
$$

#### Closed form for Newton's method
In this model, we'll assume that the Taylor expansion above denotes the cost function exactly instead of approximately. In other words, we're assuming strict equality $=$ instead of approximation $\approx$ as above. This is only an assumption; it isn't strictly true, but it's a decent approximation. Where does this take minimum value? To know that, let's set the gradient of the Taylor expansion to zero. This yields:

$$
H(\vec{w}^*)^{-1} \nabla\cost{\vec{w}^*} = \vec{w}^* - \vec{w}
$$

If we solve for $\vec{w}$, this gives us an iterative algorithm for finding the optimum:

$$
\vec{w}^{(t+1)} = \vec{w}^{(t)} - \vec{H}\left(\vec{w}^{(t)}\right)^{-1} \nabla\cost{\vec{w}^{(t)}} \gamma^{(t)}
$$

The trade-off for the Newton method is that while we need fewer iterations, each of them is more costly. In practice, which one to use depends, but at least we have another option with the Newton method.

### Regularized logistic regression
If the data is linearly separable, there is no finite-weight vector. Running the iterative algorithm will make the weights diverge to infinity. To avoid this, we can regularize with a penalty term.

$$
\argmin_w{-\sum_{n=1}^N{\log{p(y_n \mid \vec{x}_n^T\vec{w})}} + \frac{\lambda}{2}\norm{\vec{w}}^2}
$$

## Generalized Linear Models
Previously, with [least squares](#a-probabilistic-model-for-least-squares), we assumed that our data was of the form:

$$
y = x^T \vec{w} + z, \quad \text{with } z\sim\normal{0, \sigma^2}
$$

This is a D-linear model. When talking about generalized linear models, we're still talking about something linear, but we allow the noise $z$ to be something else than a Gaussian distribution.

### Motivation
The motivation for this is that while standard logistic regression only allows for binary outputs[^binary-logistic-regression], we may want to have something equivalently computationally efficient for, say, $y\in\mathbb{N}$. To do so, we introduce a different class of distributions, called the *exponential family*, with which we can revisit logistic regression and get other properties.

[^binary-logistic-regression]: We have only studied binary logistic regression, which is the basic form of logistic regression. Generalized linear models will lead us to more complex extensions, such as [multinomial logistic regression](https://en.wikipedia.org/wiki/Multinomial_logistic_regression).

This will be useful in adding a degree of freedom. Previously, we most often used linear models, in which we model the data as a line, plus zero-mean Gaussian noise. As we saw, this leads to least squares. When the data is more complex than a simple line, we saw that we could augment the features (e.g. with $x^2$, $x^3$), and still use a linear model. The idea was to augment the feature space $x$. This gave us an added degree of freedom, and allowed us to use linear models for higher-degree problems.

These linear models predicted the mean of the distribution from which we assumed the data to be sampled. When talking about mean here, we mean what we assume the data to be modeled after, without the noise. In this section, we'll see how we can use the linear model to predict a different quantity than the mean. This will allow us to add another degree of freedom, and use linear models to get other predictions than just the shape of the data.

We've actually already done this, without knowing it. In [(binary) logistic regression](#logistic-regression), the probability of the classes was:

$$
\begin{align}
p(y = 1 \mid \eta) & = \sigma(\eta) \\
p(y = 0 \mid \eta) & = 1 -  \sigma(\eta) \\
\end{align}
$$

We're using $\eta$ as a shorthand for $\vec{x}^T\vec{w}$, and will do so in this section. More compactly, we can write this in a single formula:

$$
p(y\mid\eta) = \frac{e^{\eta y}}{1 + e^\eta} = \exp{\left[
    \eta y - \log{(1 + e^\eta)}
\right]}, \qquad y\in\set{0, 1}
$$

Note that the linear model $\vec{x}^T\vec{w}$ does not predict the mean, which we'll denote $\mu$ (don't get confused by this notation; in this section, $\mu$ is not a scalar, but represents the "real values" that the data is modeled after, without the noise). Instead, our linear model predicts $\eta = \vec{x}^T\vec{w}$, which is transformed into the mean by using the $\sigma$ function:

$$
\mu = \sigma(\eta)
$$

This relation between $\mu$ and $\sigma$ is known as the **link function**. It is a nonlinear function that makes it possible to use a linear model to predict something else than the mean $\mu$.

### Exponential family
In general, the form of a distribution in the exponential family is:

$$
p(y\mid\pmb{\eta}) = h(y)\exp{\left[\pmb{\eta}^T\pmb{\phi}(y) - A(\pmb{\eta})\right]}
$$

Let's take a look at the various components of this distribution:

- $\pmb{\phi}(y)$ is called a **sufficient statistic**. It's usually a vector. Its name stems from the fact that its empirical average is all we need to estimate $\pmb{\eta}$
- $A(\pmb{\eta})$ is the **log-partition function**, or the **cumulant**.

The domain of $y$ can be vary: we could choose $y\in\mathbb{R}$, $y\in\left\\{0, 1\right\\}$, $y\in\mathbb{N}$, etc. Depending on this, we may have to do sums or integrals in the following. 

We require that the probability be non-negative, so we need to ensure that $h(y) \ge 0$. Additionally, a probability distribution needs to integrate to 1, so we also require that that:

$$
\int_y{h(y)\exp{\left[\pmb{\eta}^T\pmb{\phi}(y) - A(\pmb{\eta})\right]}} dy = 1
$$

This can be rewritten to:

$$
\int_y{h(y)\exp{\left[\pmb{\eta}^T\pmb{\phi}(y)\right]}} dy = \exp{A(\pmb{\eta})}
$$

The role of $A(\pmb{\eta})$ is thus only to ensure a proper normalization. To create a member of the exponential family, we can choose the factor $h(y)$, the vector $\pmb{\phi}(y)$ and the parameter $\pmb{\eta}$; the cumulant $A(\pmb{\eta})$ is then determined for each such choice, and ensures that the expression is properly normalized. From the above, it follows that $A(\pmb{\eta})$ is defined as:

$$
A(\pmb{\eta}) = \log{\left[\int_y{h(y)\exp{\left[\pmb{\eta}^T\pmb{\phi}(y) - A(\pmb{\eta})\right]}} dy\right]}
$$

We exclude the case where the integral is infinite, as we cannot compute a real $A(\pmb{\eta})$ for that case.

#### Link function
There is a relationship between the mean $\pmb{\mu}$ and $\pmb{\eta}$ using the link function $g$:

$$
\pmb{\eta} = g(\pmb{\mu}) \iff \pmb{\mu} = g^{-1}(\pmb{\eta})
$$

The link function is a 1-to-1 transformation from the **usual parameters** $\pmb{\mu}$ (e.g. $\pmb{\mu} = \set{\mu, \sigma^2}$ for Gaussian distributions) to the **natural parameters** $\pmb{\eta}$ (e.g. $\pmb{\eta} = \set{\frac{\mu}{\sigma^2}, -\frac{1}{2\sigma^2}}$ for Gaussian distributions).

For a list of such functions, consult the chapter on Generalized Linear Models in [the KPM book](https://www.cs.ubc.ca/~murphyk/MLbook/).

#### Example: Bernoulli
The Bernoulli distribution is a member of the exponential family. Its probability density is given by:

$$
\begin{align}
p(y\mid\mu) 
    & = \mu^y(1-\mu)^{1-y}, \quad \text{where } \mu\in(0, 1) \\
    & = \exp{\left[
        \left( \log{\frac{\mu}{1-\mu}} \right) y +
        \log{(1 - \mu)}
     \right]} \\
    & = \exp{\left[\eta \phi(y) - A(\eta)\right]}
\end{align}
$$

The parameters are thus:

$$
\begin{align}
h(y)    & = 1 \\
\phi(y) & = y \\
\eta    & = \log{\frac{\mu}{1-\mu}} \\
A(\eta) & = -\log{(1-\mu)}=\log{(1 + e^{\eta})} \\
\end{align}
$$

Here, $\phi(y)$ is a scalar, which means that the family only depends on a single parameter. Note that $\eta$ and $\mu$ are linked:

$$
\eta 
= g(\mu) 
= \log{\frac{\mu}{1-\mu}} 
\iff 
\mu
= g^{-1}(\eta)
= \log{\frac{e^{\eta}}{1+e^{\eta}}} 
= \sigma(\eta)
$$

The link function is the same sigmoid function we encountered in logistic regression.

#### Example: Poisson
The Poisson distribution with mean $\mu$ is given by:

$$
p(y\mid\mu) = \frac{\mu^y e^{-\mu}}{y!} = \frac{1}{y!}\exp{\left[
    y \log{(\mu)} - \mu
\right]} = h(y)\exp{\left[
    \eta \phi(y) - A(\eta)
\right]}
$$

Where the parameters of the exponential family are given by:

$$
\begin{align}
h(y)    & = \frac{1}{y!} \\
\phi(y) & = y \\
\eta    & = g(\mu) = \log{(\mu)} \\
A(\eta) & = \mu = g^{-1}(\eta) = e^\eta
\end{align}
$$

#### Example: Gaussian
Notation for Gaussian distributions can be a little confusing, so we'll make sure to distinguish the notation of the usual parameter vectors $\pmb{\mu}$ (in bold), from the parameters themselves, which are the Gaussian mean $\mu$ and variance $\sigma^2$. 

The density of a Gaussian $\normal{\mu, \sigma^2}$ is:

$$
p(y\mid\mu,\sigma^2) = \frac{1}{\sqrt{2\pi\sigma^2}}\exp{-\frac{(y-\mu)^2}{2\sigma^2}},
\qquad \mu\in\mathbb{R}, 
\quad \sigma\in\mathbb{R}^+
$$

There are two parameters to choose in a Gaussian, $\mu$ and $\sigma$, so we can expect something of degree 2 in exponential form. Let's rewrite the above:

$$
\begin{align}
p(y\mid\mu,\sigma^2) & = \exp{\left[
    - \frac{y^2}{2\sigma^2}
    + \frac{\mu y}{\sigma^2}
    - \underbrace{
        \frac{\mu^2}{2\sigma^2} - \frac{1}{2}\log{(2\pi\sigma^2)}
    }_{A(\pmb{\eta})}
\right]} \\
& = \exp{\left[
    \pmb{\eta}^T \pmb{\phi}(y) - A(\pmb{\eta})
\right]}
\end{align}
$$

Where:

$$
\begin{align}
h(y) & = 1 \\

\pmb{\phi}(y) & = \begin{bmatrix}
    y   \\
    y^2 \\
\end{bmatrix} \\

\pmb{\eta} & = \begin{bmatrix}
    \eta_1 \\
    \eta_2 \\
\end{bmatrix} = \begin{bmatrix}
    \frac{\mu}{\sigma^2} \\
    -\frac{1}{2\sigma^2} \\
\end{bmatrix} \\

A(\pmb{\eta}) & = \frac{\mu^2}{2\sigma^2} - \frac{1}{2}\log{(2\pi\sigma^2)}
    = \frac{\eta_1^2}{4\eta_2} - \frac{1}{2}\log{(-\eta_2/\pi)}
\end{align}
$$

Indeed, this time $\pmb{\phi}(y)$ is a vector of dimension 2, which reflects that the distribution depends on 2 parameters. As the formulation of $\pmb{\eta}$ shows, we have a 1-to-1 correspondence to $\pmb{\eta}=(\eta_1, \eta_2)$ and the $(\mu, \sigma^2)$ parameters:

$$
\eta_1 = \frac{\mu}{\sigma^2},\ \eta_2 = -\frac{1}{2\sigma^2}
\quad \iff \quad
\mu = -\frac{\eta_1}{2\eta_2},\ \sigma^2 = -\frac{1}{2\eta_2}
$$

#### Properties
1. $A(\pmb{\eta})$ is convex
2. $\nabla_{\pmb{\eta}}   A(\pmb{\eta}) = \expect{\pmb{\phi}(y)}$
3. $\nabla_{\pmb{\eta}}^2 A(\pmb{\eta}) = \expect{\pmb{\phi}(y)^T\pmb{\phi}(y)} - \expect{\pmb{\phi}(y)}^T\expect{\pmb{\phi}(y)}$
4. $\pmb{\mu} := \expect{\pmb{\phi}(y)}$

Proofs for the first 3 properties are in the lecture notes. The last property is given without proof.

### Application in ML

We use $\eta_n = \vec{x}_n^T\vec{w}$, or equivalently,  $\pmb{\eta} = \vec{X}^T\vec{w}$.

#### Maximum Likelihood Parameter Estimation
Assume that we have samples composing our training set, $\Strain = \set{(\vec{x}\_n, y_n)}_{n=1}^N$ i.i.d. from some distribution, which we assume is some exponential family. Assume we have picked a model, i.e. that we fixed $h(y)$ and $\pmb{\phi}(y)$, but that $\pmb{\eta}$ is unknown. How can we find an optimal $\pmb{\eta}$?

We said previously that $\pmb{\phi}(y)$ is a sufficient statistic, and that we could find $\pmb{\eta}$ from its empirical average; this is what we'll do here. We can use the maximum likelihood principle to find this parameter, meaning that we want to minimize log-likelihood:

$$
\begin{align}
\mathcal{L}_{LL}(\pmb{\eta})
    & = -\log{(p(y \mid \pmb{\eta}))} \\
    & = \sum_{n=1}^N{\left(
        -\log{\left[h(y_n)\right] - \eta_n^T\pmb{\phi}(y_n) + A(\eta_n)}
    \right)}
\end{align}
$$

This is a convex function in $\pmb{\eta}$: the $h(y)$ term does not depend on $\pmb{\eta}$, $\pmb{\eta}^T\pmb{\phi}(y_n)$ is linear, $A(\pmb{\eta})$ has the [property of being convex](#properties-1).

If we assume that we have the link function already, we can get $\pmb{\eta}$ by setting the gradient of our exponential family to 0. We also multiply by $\frac{1}{N}$ to get a more convenient form, i.e. with $\expect{\pmb{\phi}(y)}$ instead of $N\cdot\expect{\pmb{\phi}(y)}$:

$$
\begin{align}
\frac{1}{N} \nabla\cost{\pmb{\eta}}
  & = -\frac{1}{N}\sum_{n=1}^N{\bigl[\pmb{\phi}(y_n) 
      - \nabla A(\eta_n)\bigr]} \\
  & = -\frac{1}{N}\left( \sum_{n=1}^N{\pmb{\phi}(y_n)} \right)
      + \expect{\pmb{\phi}(y)}  \\
  & = 0
\end{align}
$$

Since $\pmb{\mu} := \expect{\pmb{\phi}(y)}$, we get:

$$
\pmb{\mu} := \expect{\pmb{\phi}(y)} = \frac{1}{N} \sum_{n=1}^N{\pmb{\phi}(y_n)}
$$

Therefore, we can get $\pmb{\eta}$ by using the link function:

$$
\pmb{\eta} 
    = g^{-1}(\pmb{\mu}) 
    = g^{-1}\left( \frac{1}{N}\sum_{n=1}^N{\pmb{\phi}(y_n)} \right) \\
$$

With this, we can see the justification for calling $\pmb{\phi}(y)$ a sufficient statistic.

#### Conditions of optimality
If we assume that our samples follow the distribution of an exponential family, we can construct a *generalized linear model*. As we've explained previously, this is a generalization of the model we used for logistic regression.

For such a model, the maximum likelihood problem, as described above, is easy to solve. As we've noted above, the cost function is convex, so a greedy, iterative algorithm should work well. Let's look at the gradient of the cost in terms of $\vec{w}$ (instead of $\pmb{\eta} = \vec{x}^T\vec{w}$ as previously):

$$
\begin{align}
\cost{\vec{w}} 
    & = -\sum_{n=1}^N{
        \log{(h(y_n))} + \vec{x}_n^T\vec{w} \pmb{\phi}(y_n) - A(\vec{x}_n^T\vec{w})
    } \\

\nabla_{\vec{w}}\cost{\vec{w}} 
    & = -\sum_{n=1}^N{
        \vec{x}_n \pmb{\phi}(y_n) - \nabla_{\vec{w}} A(\vec{x}_n^T\vec{w})
    }
\end{align}
$$

Let's recall that the derivative of the cumulant is:

$$
\frac{\partial A(\pmb{\eta})}{\partial \pmb{\eta}} = \expect{\pmb{\phi}(y)} = g^{-1}(\pmb{\eta})
$$

Hence the gradient of the cost function is:

$$
\nabla_{\vec{w}}\cost{\vec{w}} 
= - \sum_{n=1}^N {\vec{x}_n \pmb{\phi}(y_n) 
  - \vec{x}_n g^{-1}(\vec{x}_n^T\vec{w})}
$$

Setting this to zero gives us the condition of optimality. Using matrix notation, we can rewrite this sum as follows:

$$
\nabla_{\vec{w}}\cost{\vec{w}} 
= \vec{X}^T\left( g^{-1}(\vec{Xw}) - \pmb{\phi}(\vec{y}) \right) 
= 0
$$

Note that this is a more general form of the formula we had [for logistic regression](#conditions-of-optimality). At this point, seeing that the function is convex, we can use a greedy iterative algorithm like gradient descent to find the minimum.

## Nearest neighbor classifiers and the curse of dimensionality
For simplicity, let's assume that we're operating in a d-dimensional box, that is, in the domain $\chi = [0, 1]^d$. As always, we have a training set $\Strain=\set{(\vec{x}_n, y_n)}$. 

### K Nearest Neighbor (KNN)
Given a "fresh" input $\vec{x}$, we can make a prediction using $\text{nbh}\_{\Strain,\ k}(\vec{x})$. This is a set of the $k$ inputs in the training set that are closest to $\vec{x}$.

For the regression problem, we can take the average of the k nearest neighbors:

$$
f(\vec{x}) = \frac{1}{k}\sum_{n\in\text{nbh}_{\Strain,\ k}(\vec{x})}{y_n}
$$

For binary classification, we take the majority element in the $k$-neighborhood. It's a good idea to pick $k$ to be odd so that there is a clear winner.

$$
f(\vec{x}) = \text{maj}\set{y_n : n \in \text{nbh}_{\Strain, k}(\vec{x})}
$$

If we pick a large value of $k$, then we are smoothing over a large area. Therefore, a large $k$ gives us a simple model, with simpler boundaries, while a small $k$ is a more complex model. In other words, complexity is inversely proportional to $k$. As we saw when we talked about [bias and variance](#bias-variance-decomposition), if we pick a small value of $k$ we can expect a small bias but huge variance. If we pick a large $k$ we can expect large bias but small variance.

### Analysis
We'll analyze the simplest setting, a binary KNN model (that is, there are only two output labels, 0 and 1). Let's start by simplifying our notation. We'll introduce the following function:

$$
\eta(\vec{x}) = \mathbb{P}\left\{y=1\mid\vec{x}\right\}
$$

This is the conditional probability that the label is 1, given that the input is $\vec{x}$. If this probability is to be meaningful at all, we must have some correlation between the "position" x and the associated label; knowing the labels close by must give us some information. This means that we need an assumption on the distribution $\mathcal{D}$:

$$
\abs{\eta(\vec{x}) - \eta(\vec{x}')} \le \mathcal{c}\norm{\vec{x} - \vec{x}'}
\label{eq:lipschitz-bound}\tag{Lipschitz bound}
$$

On the right-hand side we have Euclidean distance. In other words, we ask that the conditional probability $\mathbb{P}\left\\{y=1\mid\vec{x}\right\\}$, denoted by $\eta(x)$, be [Lipschitz continuous](https://en.wikipedia.org/wiki/Lipschitz_continuity) with Lipschitz constant $\mathcal{c}$. We will use this assumption later on to prove a performance bound for our KNN model.

Let's assume for a moment that we know the actual underlying distribution. This is not something that we actually know in practice, but is useful for deriving a formulation for the optimal model. Knowing the distribution probability distribution, our optimum decision rule is given by the classifier:

$$
f_*(\vec{x}) = \mathbb{I}\left[ \eta(\vec{x}) > \frac{1}{2} \right]
$$

The idea of this classifier is that with two labels, we'll pick the label that is likely to happen more than half of the time. The intuition is that if we were playing heads or tails and knew the probability in advance, we would always pick the option that has probability more than one half, and that is the best strategy we can use. This is known as the **Bayes classifier**, also called **maximum a posteriori (MAP) classifier**. It is optimal, in that it has the smallest probability of misclassification of any classifier, namely:

$$
\cost{f_*} = \expectsub{\vec{x}\sim\mathcal{D}}{
    \min{\set{ \eta(\vec{x}), 1-\eta(\vec{x}) }}
}
$$

Let's compare this to the probability of misclassification of the real model:

$$
\cost{f_{\Strain,\ k=1}} = \expect{\mathbb{I}\left[ f_{\Strain}(\vec{x}) \ne y \right]}
$$

This tells us that the risk (that is, the error probability of our $k=1$ nearest neighbor classifier) is the above expectation. It's hard to find a closed form for that expectation, but we can place a bound on it by comparing the ideal, theoretical model to the actual model. We'll state the following lemma:

$$
\begin{align}
\cost{f_{\Strain}}
    & \le 2 \cost{f_*} + \mathcal{c} \expectsub{\Strain, \vec{x}\sim\mathcal{D}}{\norm{\vec{x} - \text{nbh}_{\Strain, 1}(\vec{x})}} \\
    
    & \le 2 \cost{f_*} + 4\mathcal{c}\sqrt{d} N^{-\frac{1}{d+1}} \\
\end{align}
$$

Before we see where this comes from, let's just interpret it. The above gives us a bound on the real classifier, compared to the optimal one. The actual classifier is upper bounded by twice the risk of the optimal classifier (this is good), plus a geometric term reflecting dimensionality (it depends on $d$: this will cause us some trouble).

This second term of the sum is the average distance of a randomly chosen point to the nearest point in the training set, times the Lipschitz constant $\mathcal{c}$. It intuitively makes sense to incorporate this factor into our bound: if we are basing our prediction on a point that is very close, we're more likely to be right, and if it's far away, less so. If we're in a box of $[0, 1]^d$, then the distance between two corners would be $\sqrt{d}$ (by Pythagoras' theorem). The term $N^{-\frac{1}{d+1}}$ indicates that the closest data point may be closer than the opposite corner of the cube: if we have more data, we'll probably not have to go that far. However, for large dimensions, we need much more data to have something that'll probably be close.

Let's prove where this geometric term comes from by considering the cube $[0, 1]^d$, the space of inputs containing $\vec{x}$. We can cut this large cube into small cubes of side length $\epsilon$. Consider the small cube containing $\vec{x}$. If we are lucky, this small cube also contains a neighboring data point at distance at most $\sqrt{d}\epsilon$ (at the opposite corner of the small cube; we use Pythagoras' theorem as above). However, if we're less lucky, the closest neighbor may be at the other corner of the big cube, at distance $\sqrt{d}$. So what is the probability of a point not having a neighbor in its small $\epsilon$ cube?

Let's denote the probability of $\vec{x}$ landing in a particular box by $\mathbb{P}_i$. The chance that none of the N training points are in the box is $(1-\mathbb{P}_i)^N$. We don't know the distribution $\mathcal{D}$, so we can't really express $\mathbb{P}_i$ in a closed form, but that doesn't matter, this notation allows us to abstract over that. The rest of the proof is calculus, carefully choosing the right scaling for $\epsilon$ in order to get a good bound.

Now, let's understand where the term $2\cost{f_*}$ comes from. If we flip two coins, $y$ and $y'$, what is the probability of the outcome being different?

$$
\mathbb{P}\left\{y \ne y' \right\} = 2p(1-p)
$$

Now, let's consider two points $\vec{x}$ and $\vec{x}'$, both elements of $[0, 1]^d$. Their labels are $y$ and $y'$, respectively. The probability of these two labels being different is roughly the same as above (although the probabilities of the two events may not be the same in general):

$$
\begin{align}
\mathbb{P}\left\{ y \ne y'\right\}
    =   & \eta(\vec{x})(1-\eta(\vec{x}')) + \eta(\vec{x}')(1-\eta(\vec{x})) \\
    =   & 2\eta(\vec{x})(1-\eta(\vec{x})) + (2\eta(\vec{x})-1)(\eta(\vec{x})-\eta(\vec{x}')) \\
    \le & 2\eta(\vec{x})(1-\eta(\vec{x})) + (\eta(\vec{x}) - \eta(\vec{x}')) \\
    \le & 2\eta(\vec{x})(1-\eta(\vec{x})) + \mathcal{c}\norm{\vec{x}-\vec{x}'}
\end{align}
$$

The second to last step uses the fact that $\eta$ is a probability distribution, so $-1 \le 2\eta(\vec{x})-1 \le 1$. The last step uses the $\ref{eq:lipschitz-bound}$.

Therefore, we can confirm the following bound:

$$
\mathbb{P}\left\{ y\ne y' \right\} \le  2\eta(\vec{x})(1-\eta{\vec{x}}) + \mathcal{c}\norm{\vec{x} - \vec{x}'}
$$

But we are still one step away from explaining how we can compare this to the optimal estimator. In the above, we derived a bound for two labels being different. How is this related to our KNN model? The probability of getting a wrong prediction from KNN with $k=1$ (which we denoted $\expectsub{\Strain}{\cost{f_{\Strain}}}$) is the probability of the predicted label being different from the solution label. 

We get to our lemma by the following reasoning:

$$
2\eta(\vec{x})(1-\eta{\vec{x}}) 
    \le 2\min{\left\{ \eta(\vec{x}), 1-\eta(\vec{x}) \right\}}
    = 2\cost{f_*}
$$

Additionally, the average of the term $\mathcal{c}\norm{\vec{x} - \vec{x}'}$ is $\mathcal{c}\expectsub{\Strain, \vec{x}\sim\mathcal{D}}{\norm{\vec{x} - \text{nbh}_{\Strain, 1}(\vec{x})}}$

If we had assumed that it was a ball instead of a cube, we would've gotten slightly different results. But that's besides the point: the main insight from this is that it depends on the dimension, and that for low dimensions at least, we still have a fairly good classifier. But finding a closest neighbor in high dimension can quickly become meaningless.


## Support Vector Machines
### Definition
Let's re-consider binary classification. In the following it will be more convenient to consider $y_n\in\set{\pm 1}$. This is equivalent to what we've done previously, under the mapping $0 \mapsto -1$ and $1\mapsto 1$. Note that this mapping can be done continuously in the range $[0, 1] \mapsto [-1, 1]$ by computing $\tilde{y}_n = 2y_n - 1$, and back with $y_n = \frac{1}{2}(\tilde{y}_n + 1)$.

Previously, we used MSE or logistic loss. MSE is symmetric, so something being positive or negative is punished at an equal rate. With logistic regression, we always have a loss, but its value is asymmetric, shrinking the further we go right.

If we instead use hinge loss (as defined below), with an additional regularization term, we get **Support Vector Machines** (SVM).

$$
\text{Hinge}(z, y) =  [1-yz]_+ = \max{\left\{ 0, 1-yz \right\}}
$$

Here, we use $z$ as shorthand for $\vec{x}^T \vec{w}$. The function multiplies the prediction with the actual label, which produces a positive result if they are of the same sign, and a negative result if they have different signs (this is why we wanted our labels in $\set{\pm 1}$). When the prediction is correct and above one, $1-yz$ becomes negative, and hinge loss returns 0. This makes hinge loss a linear function when predictions are incorrect or below one; it does not punish correct predictions above one, which pushes us to give predictions that we can be very confident about (above one).

![Graph of hinge loss, MSE and logistic](/images/ml/hinge-mse-logistic.png)

SVMs correspond to the following optimization problem:

$$
\min_{\vec{w}}{\sum_{n=1}^N{\left[ 1 - y_n \vec{x}_n^T \vec{w}\right]_+} + \frac{\lambda}{2}\norm{\vec{w}}^2}
$$

What does this optimization problem correspond to, intuitively?

![Margin of a dataset](/images/ml/margin.png)

In the figure above, the pink region represents the "margin" created by the SVM. The center of the margin is the separating hyperplane; its direction is perpendicular to $\vec{w}$, the normal vector defining the hyperplane. The margin's total width is $2/\norm{\vec{w}}$.

Points inside the margin are feature vectors $\vec{x}$ for which $\abs{\vec{x}^T\vec{w}} < 1$. These points incur a cost with hinge loss. Any points outside the margin, for which $\abs{\vec{x}^T\vec{w}} \ge 1$, do not incur any cost, as long as they're on the correct side. Thus, depending on the $\vec{w}$ that we choose, the orientation and size of the margin will change; there will be a different number of points in it, and the cost will change.

How can we pick a good margin? Let's assume $\lambda$ is small; we won't define that further, the main point is just we pick one with the following priorities (in order):

1. We want a separating hyperplane
2. We want a scaling of $\vec{w}$ so that no point of the data is in the margin
3. We want the margin to be as wide as possible

With conditions 1 and 2, we can ensure that there is no cost incurred in the first expression (the sum over $[1 - y\_n \vec{x}\_n^T \vec{w}]\_+$). The third condition is ensured by the fact that we're minimizing $\norm{\vec{w}}^2$. Since the size of the margin is inversely proportional to that, we're maximizing the margin.

We've introduced SVMs for the general case, where the data is not necessarily linearly separable, which is the *soft-margin* formulation. In the *hard-margin* formulation, the data is linearly separable by a separating hyperplane. Maximizing the margin size in the hard-margin formulation implies that some points will lie exactly on the margin boundary (on the correct side). These points are called **essential support vectors**. For the soft-margin case, this interpretation becomes a little more muddled.


### Alternative formulation: Duality
Now that we know what function we're optimizing, let's look at how we can optimize it efficiently. The function is convex, and has a subgradient in $\vec{w}$, which means we can use SGD with subgradients. This is good news! We'll discuss an alternative, but equivalent formulation via the concept of *duality*, which can lead us to a more efficient implementation in some cases. More importantly though, the dual problem can point us to a more general formulation, called the [kernel trick](#kernel-trick).

Let's say that we're interested in minimizing a cost function $\cost{\vec{w}}$. Let's assume this can be defined through an auxiliary function $G$, such that:

$$
\cost{\vec{w}} = \max_{\pmb{\alpha}}{G(\vec{w}, \pmb{\alpha})}
$$

The minimization in question is thus:

$$
\min_{\vec{w}}{\cost{\vec{w}}}
= \min_{\vec{w}}{\max_{\pmb{\alpha}}{G(\vec{w}, \pmb{\alpha})}}
$$

We call this the **primal problem**. In some cases though, it may be easier to find this in the other direction:

$$
\max_{\pmb{\alpha}}{\min_{\vec{w}}{G(\vec{w}, \pmb{\alpha})}}
$$

We call this the **dual problem**. This leads us to a few questions:

#### How do we find a suitable function G?
There's a general theory on this topic (see [Nonlinear Programming](http://www.athenasc.com/nonlinbook.html) by Dimitri Bertsekas). In the case of SVMs though, the finding the function G is rather straightforward, once we restate the hinge loss as follows:

$$
[z]_+ = \max{\left\{ 0, z \right\}} = \max_{\alpha}{\alpha z}, \qquad \text{with } \alpha\in[0, 1]
$$

The SVM problem then becomes:

$$
\min_{\vec{w}}{\max_{\pmb{\alpha}\in[0, 1]^N}{
    \underbrace{
        \sum_{n=1}^N{
            \alpha_n (1 - y_n \vec{x}_n^T \vec{w})
        } + \frac{\lambda}{2}\norm{\vec{w}}^2
    }_{G(\vec{w}, \pmb{\alpha})}
}}
\label{eq:svm-primal}\tag{Primal problem}
$$

Note that G is convex in $\vec{w}$, and linear, hence concave, in $\pmb{\alpha}$.

#### When is it OK to switch min and max? 
It is always true that:

$$
\max_{\pmb{\alpha}}{\min_{\vec{w}}{G(\vec{w}, \pmb{\alpha})}}
\le
\min_{\vec{w}}{\max_{\pmb{\alpha}}{G(\vec{w}, \pmb{\alpha})}}
$$

This is proven by:

$$
\begin{align}
\min_{\vec{w}'}{G(\vec{w}', \pmb{\alpha})} 
& \le G(\vec{w}, \pmb{\alpha}) 
  \quad \forall \vec{w}, \pmb{\alpha} 
& \iff \\

\max_{\pmb{\alpha}}{\min_{\vec{w}'}{G(\vec{w}', \pmb{\alpha})}} 
& \le \max_{\pmb{\alpha}}{G(\vec{w}, \pmb{\alpha})} 
  \quad \forall \vec{w} 
& \iff \\

\max_{\pmb{\alpha}}{\min_{\vec{w}'}{G(\vec{w}', \pmb{\alpha})}} 
& \le \min_{\vec{w}} \max_{\pmb{\alpha}}{G(w, \pmb{\alpha})} 
& \\
\end{align}
$$

Equality is achieved when the function looks like a saddle: when $G$ is a continuous function that is convex in $\vec{w}$, concave in $\pmb{\alpha}$, and the domains of both are compact and convex.

![Saddle function](/images/ml/saddle.png)

For SVMs, this condition is fulfilled, and the switch between min and max can be done. The alternative formulation of SVMs is:

$$
\max_{\pmb{\alpha}\in[0, 1]^N}{\min_{\vec{w}}{
    \underbrace{
        \sum_{n=1}^N{
            \alpha_n (1 - y_n \vec{x}_n^T \vec{w})
        } + \frac{\lambda}{2}\norm{\vec{w}}^2
    }_{G(\vec{w}, \pmb{\alpha})}
}}
\label{eq:svm-dual}\tag{Dual problem}
$$

We can take the derivative with respect to $\vec{w}$:

$$
\nabla_{\vec{w}}G(\vec{w}, \pmb{\alpha}) 
    = -\sum_{n=1}^N{\alpha_n y_n \vec{x}_n + \lambda\vec{w}}
$$

We'll set this to zero to find a formulation of $\vec{w}$ in terms of $\alpha$. We get:

$$
\vec{w}(\pmb{\alpha}) = \frac{1}{\lambda}\sum_{n=1}^N{\alpha_n y_n \vec{x}_n} = \frac{1}{\lambda}\vec{X}^T\vec{Y}\pmb{\alpha}
$$

Where $\vec{Y} := \text{diag}(\vec{y})$. If we plug this into $\ref{eq:svm-dual}$, we get the following dual problem, in quadratic form:

$$
\begin{align}
&   \max_{\pmb{\alpha}\in[0, 1]^N}{
    \sum_{n=1}^N \alpha_n(1 - \frac{1}{\lambda}y_n \vec{x}_n^T \vec{X}^T\vec{Y}\pmb{\alpha}) + \frac{\lambda}{2}\norm{\frac{1}{\lambda}\vec{X}^T\vec{Y}\pmb{\alpha}}^2
} \\
& = \max_{\pmb{\alpha}\in[0, 1]^N}{
    \pmb{\alpha}^T\vec{1} - \frac{1}{2\lambda}\pmb{\alpha}^T\vec{YXX}^T\vec{Y}\pmb{\alpha}
} \label{eq:svm-quadratic-form} \tag{Quadratic form}
\end{align}
$$

#### When is the dual easier to optimize than the primal? 
1. When the dual is a differentiable quadratic problem (as SVM is). This is a problem that takes the same $\ref{eq:svm-quadratic-form}$ as above. In this case, we can optimize by using **coordinate descent** (or more precisely, ascent, as we're searching for the maximum). Crucially, this method only changes one $\alpha_n$ variable at a time.
2. In the $\ref{eq:svm-quadratic-form}$ above, the data enters the formula in the form $\vec{K} = \vec{XX}^T$. This is called the **kernel**. We say this formulation is *kernelized*. Using this representation is called the *kernel trick*, and gives us some nice consequences that we'll discuss later.
3. Typically, the solution $\pmb{\alpha}$ is sparse, being non-zero only in the training examples that are instrumental in determining the decision boundary. If we recall how we defined $\alpha$ in [an alternative formulation](#how-do-we-find-a-suitable-function-g) of $[z]_+$, we can see that there are three distinct cases to consider:
    1. Examples that lie on the correct side, and outside the margin, for which $\alpha_n = 0$. These are **non-support vectors**
    2. Examples that are on the correct side and just on the margin, for which $y_n \vec{x}_n^T \vec{w} = 1$, so $\alpha_n \in (0, 1)$. These $\vec{x}_n$ are **essential support vectors**
    3. Examples that are strictly within the margin, or on the wrong side have $\alpha_n = 1$, and are called **bound support vectors**

### Kernel trick
We saw previously that our data only enters $\ref{eq:svm-quadratic-form}$ in the form of a kernel, $\vec{K} = \vec{XX}^T$. We'll see now that when we're using the kernel, we can easily go to a much larger dimensional space (even infinite dimensional space) without adding any complexity. This isn't always applicable though, so we'll also see which kernel functions are admissible for this trick.

#### Alternative formulation of ridge regression
Let's recall that least squares is a special case of ridge regression (where $\lambda = 0$). Ridge regression corresponds to the following optimization problem:

$$
\vec{w}^* = \min_{\vec{w}}{\sum_{n=1}^N{(y_n - \vec{x}_n^T w)^2 + \frac{\lambda}{2}\norm{\vec{w}}^2}}
$$

We saw that the solution has a closed form:

$$
\vec{w}^* = (\vec{X}^T\vec{X} + \lambda\vec{I}_D)^{-1} \vec{X}^T y
$$

We claim that this can be alternatively written as:

$$
\vec{w}^* = 
    \vec{X}^T
    (\underbrace{\vec{XX}^T\vec{X} +  \lambda\vec{I}_N}_{N\times N})^{-1}
    y
$$

The original formulation's runtime is $\mathcal{O}(D^3 + ND^2)$, while the alternative is $\mathcal{O}(N^3 + DN^2)$. Which is more efficient depends on $D$ and $N$.

{% details Proof %}
We can prove this formulation by using the following identity. If we let $\vec{P}$ be an $N\times M$ matrix, and $\vec{Q}$ be $M\times N$. Then:

$$
\vec{P}(\vec{QP} + \vec{I}_M) = \vec{PQP} + \vec{P} = (\vec{PQ} + \vec{I}_N)\vec{P}
$$

Assuming that $(\vec{QP} + \vec{I}_M)$ and $(\vec{PQ} + \vec{I}_N)$ are invertible, we have the identity:

$$
(\vec{PQ}+\vec{I}_N)^{-1}\vec{P} = \vec{P}(\vec{QP}+\vec{I}_M)^{-1}
$$

To derive the formula, we can let $\vec{P} = \vec{X}^T$ and $\vec{Q} = \frac{1}{\lambda}\vec{X}$.
{% enddetails %}

#### Representer theorem
The representer theorem generalizes what we just saw about ridge regression. For a $\vec{w}^*$ minimizing the following, for any cost $\mathcal{L}_n$,

$$
\min_{\vec{w}}{\sum_{n=1}^N{
    \mathcal{L}_n(\vec{x}_n^T \vec{w}, y_n) + \frac{\lambda}{2}\norm{\vec{w}}^2
}}
$$

there exists $\pmb{\alpha^\*}$ such that $\vec{w}^\* = \vec{X}^T \pmb{\alpha}^\*$.

#### Kernelized ridge regression
The above theorem gives us a new way of searching for $\vec{w}^\*$: we can first search for $\pmb{\alpha^\*}$, which might be easier, and then get back to the optimal weights by using the identity $\vec{w}^\* = \vec{X}^T \pmb{\alpha}^\*$.

Therefore, for ridge regression, we can equivalently optimize our alternative formula in terms of $\alpha$:

$$
\pmb{\alpha}^* = \argmin_{\pmb{\alpha}}{
    \frac{1}{2}\pmb{\alpha}^T(\vec{XX}^T + \lambda \vec{I}_N)\pmb{\alpha} 
    - \pmb{\alpha}^T \vec{y}}
$$

We see that our data enters in kernel form. How do we get the solution to this minimization problem? We can, as always, take the gradient of the cost function according to $\pmb{\alpha}$ and set it to zero:

$$
\nabla_{\pmb{\alpha}}\cost{\pmb{\alpha}} 
= (\vec{XX}^T + \lambda \vec{I}_N)\pmb{\alpha} - \vec{y} = 0 
$$

Solving for $\alpha$ results in:

$$
\begin{align}
\pmb{\alpha}^*  & = (\vec{XX}^T + \lambda \vec{I}_N)^{-1} \vec{y} \\
\vec{w}^*       & = \vec{X}^T\pmb{\alpha}^* 
                  = \vec{X}^T(\vec{XX}^T + \lambda \vec{I}_N)^{-1} \vec{y}
\end{align}
$$

We've effectively gotten back to our claimed alternative formulation for the optimal weights.

#### Kernel functions
The kernel is defined as $\vec{K} = \vec{XX}^T$. We'll call this the **linear kernel**. The elements are defined as:

$$
\vec{K} = \vec{XX}^T = \begin{bmatrix}
\vec{x}_1^T\vec{x}_1 & \vec{x}_1^T\vec{x}_2 & \cdots & \vec{x}_1^T\vec{x}_N \\
\vec{x}_2^T\vec{x}_1 & \vec{x}_2^T\vec{x}_2 & \cdots & \vec{x}_2^T\vec{x}_N \\
\vdots               & \vdots               & \ddots & \vdots               \\
\vec{x}_N^T\vec{x}_1 & \vec{x}_N^T\vec{x}_2 & \cdots & \vec{x}_N^T\vec{x}_N \\  
\end{bmatrix}
$$

The kernel matrix is a $N\times N$ matrix. Now, assume that we had first augmented the feature space with $\phi(\vec{x})$; the elements of the kernel would then be:

$$
\vec{K} = \pmb{\Phi}\pmb{\Phi}^T = \begin{bmatrix}
\phi(\vec{x}_1)^T\phi(\vec{x}_1) & \phi(\vec{x}_1)^T\phi(\vec{x}_2) & \cdots & \phi(\vec{x}_1)^T\phi(\vec{x}_N) \\
\phi(\vec{x}_2)^T\phi(\vec{x}_1) & \phi(\vec{x}_2)^T\phi(\vec{x}_2) & \cdots & \phi(\vec{x}_2)^T\phi(\vec{x}_N) \\
\vdots & \vdots & \ddots & \vdots \\
\phi(\vec{x}_N)^T\phi(\vec{x}_1) & \phi(\vec{x}_N)^T\phi(\vec{x}_2) & \cdots & \phi(\vec{x}_N)^T\phi(\vec{x}_N) \\
\end{bmatrix}
$$

Using this formulation allows us to keep the size of $\vec{K}$ the same, regardless of how much we augment. In other words, we can now solve a problem where the size is independent of the feature space.

The feature augmentation goes from $\vec{x}_n \in \mathbb{R}^D$ to $\phi(\vec{x}_n) \in \mathbb{R}^{D'}$ with $D' \gg D$, or even to an infinite dimension.

The big advantage of using kernels is that rather than first augmenting the feature space and then computing the kernel by taking the dot product, we can do both steps together, and we can do it more efficiently.

Let's define a kernel function $\kappa(\vec{x}, \vec{x}')$. We'll let entries in the kernel $K$ be defined by:

$$
K_{i, j} = \kappa(\vec{x}_i, \vec{x}_j)
$$

We can pick different kernel functions and get some interesting results. If we pick the right kernel, it can be equivalent to augmenting the features with some $\phi(\vec{x})$, and then computing the inner product:

$$
\kappa(\vec{x}, \vec{x}') = \phi(\vec{x})^T\phi(\vec{x}')
$$

Hopefully, $\kappa$ is simple enough of a function that it'll still be easier to compute than going to the higher dimensional space via $\phi$ and then computing the dot product.

Let's take a look at a few examples of choices for $\kappa$ and see what happens. In the following, we'll go the other way around, picking a $\kappa$ and showing that it's equivalent to a particular feature augmentation $\phi$.

##### Trivial kernels
This is the trivial example, in which there is no feature augmentation. The following definition of $\kappa$ is equivalent to the identity "augmentation":

$$
\kappa(\vec{x}_1, \vec{x}_2) = \vec{x}_1^T\vec{x}_2 \implies \phi(\vec{x}) = \vec{x}
$$

Another trivial example assumes that $x_1, x_2 \in \mathbb{R}$. We'll define the following kernel function, which is equivalent to the feature augmentation that takes the square:

$$
\kappa(x_1, x_2) = (x_1 \cdot x_2)^2 \implies \phi(x) = x^2
$$

##### Polynomial kernel 
Let's assume that $\vec{x}', \vec{x}' \in\mathbb{R}^3$. Let's define the kernel function as follows:

$$
\begin{align}
\kappa(\vec{x}, \vec{x}') 
    & = \left(x_1 x'_1 + x_2 x'_2 + x_3 x'_3\right)^2 \\
    & = \left( x_1 x'_1 \right)^2
      + \left( x_2 x'_2 \right)^2
      + \left( x_3 x'_3 \right)^2
      + 2 x_1 x'_1 x_2 x'_2
      + 2 x_1 x'_1 x_3 x'_3
      + 2 x_2 x'_2 x_3 x'_3
\end{align}
$$ 

What is the $\phi$ corresponding to this? The inner product that would produce the above would is produced by taking the inner product $\phi(\vec{x})^T\phi(\vec{x}')$, where $\phi$ is defined as follows:

$$
\phi(\vec{x}) = \begin{bmatrix}
\sqrt{2} x_1 x_2 &
\sqrt{2} x_1 x_3 &
\sqrt{2} x_3 x_3 &
x_1^2 &
x_2^2 &
x_3^2
\end{bmatrix}
$$

##### Radial basis function kernel
The following kernel corresponds to an infinite feature map:

$$
\kappa(\vec{x}, \vec{x}') = \exp{\left[-(\vec{x} - \vec{x}')^T(\vec{x} - \vec{x}')\right]}
$$

This is called the *radial basis function* (RBF) kernel.

Consider the special case in which $\vec{x}$ and $\vec{x}'$ are scalars; we'll look at the Taylor expansion of the function:

$$
\begin{align}
\kappa(x, x')
& = \exp{\left[-(x - x')^2\right]} \\
& = \exp{\left[-(x^2 + (x')^2 - 2xx')\right]} \\
& = e^{-x^2} e^{-(x')^2} e^{2xx'} \\
& = e^{-x^2} e^{-(x')^2} 
    \sum_{k=0}^\infty{\frac{2^k(x)^k(x')^k}{k!}}
\end{align}
$$

We can think of this infinite sum as the dot-product of two infinite vectors, whose $k$-th components are equal to, respectively:

$$
e^{-x^2} \sqrt{\frac{2^k}{k!}} x^k
\quad \text{and} \quad
e^{-(x')^2} \sqrt{\frac{2^k}{k!}} (x')^k
$$

Although it isn't obvious, we'll state that this kernel cannot be represented as an inner product in finite-dimensional space; it is inherently the product of infinite dimensional vectors.

##### New kernel functions from old ones
We can simply construct a new kernel as a linear combination of old kernels:

$$
\begin{align}
\kappa(\vec{x}, \vec{x'})
     & = a\kappa_1(\vec{x}, \vec{x'}) + b\kappa_2(\vec{x}, \vec{x'}),
     & \quad \forall a, b \ge 0 \\

\kappa(\vec{x}, \vec{x'})
    & = \kappa_1(\vec{x}, \vec{x'}) \kappa_2(\vec{x}, \vec{x'}) \\

\kappa(\vec{x}, \vec{x'}) 
    & = \kappa_1(f(\vec{x}), f(\vec{x'})),
    & \quad f: \mathbb{R}^D \rightarrow \mathbb{R}^D \\

\kappa(\vec{x}, \vec{x}') 
    & = f(\vec{x})f(\vec{x}'),
    & \text{in which case } \phi(\vec{x}) = f(\vec{x}) \\
\end{align}
$$

Proofs are in the lecture notes. If we accept these, we can combine them to prove much more complex kernel functions.

### Classifying with the kernel
So far, we've seen how to compute the optimal parameter $\pmb{\alpha}$ using only the kernel, without having to go to the extended feature space. This also allows us to have infinite feature spaces. Now, let's see how to use all of this to create predictions using only the kernel.

Recall that the classifier predicts $y_n = \phi(\vec{x}_n)^T\vec{w}^\*$, and that $\vec{w}^\* = \vec{X}^T \pmb{\alpha}^\*$. This leads us to:

$$
y_m = \phi(\vec{x}_m)^T \phi(\vec{X})^T \pmb{\alpha} 
  = \sum_{n=1}^N{\kappa(\vec{x}_m, \vec{x}_n)\pmb{\alpha}}
$$

### Properties of kernels
How can we ensure that there exists a feature augmentation $\phi$ corresponding to a given kernel $\vec{K}$? A kernel function must be an inner-product in some feature space. Mercer's condition states that we have this iff the following conditions are fulfilled:

1. $K$ is symmetric, i.e. $\kappa(\vec{x}, \vec{x}') = \kappa(\vec{x}', \vec{x})$
2. For any arbitrary input set $\set{\vec{x}_n}$ and all $N$, $K$ is positive semi-definite

## Unsupervised learning
So far, all we've done is supervised learning: we've gone from a training set with features vectors and labels, and we wanted to output a classification or a regression.

There is a second very important framework in ML called *unsupervised* learning. Here, the training set is only composed of the feature vectors; there are no associated labels:

$$
\Strain = \set{(\vec{x}_n)}_{n=1}^N
$$

We would then like to learn from this dataset without having access to the training labels. The two main directions in unsupervised learning are:

- Representation learning & feature learning
- Density estimation & generative models 

Let's take a bird's eye view of the existing techniques through some examples.

1. **Matrix factorization**: can be used for both supervised and unsupervised. We'll give an example for each
    1. **Netflix, collaborative filtering**: this is an example of supervised learning. We have a large, sparse matrix with rows of users, columns of  movies, containing ratings. If we can approximate the matrix reasonably well by a matrix of rank one (i.e. outer product of two vectors), then this extracts useful features both for the users and the movies; it might group movies by genres, and users by type.
    2. **word2vec**: this is an example of unsupervised learning. The idea is to map every word from a large corpus to a vector $w_i \in \mathbb{R}^K$, where K is relatively large. This would allow us to represent natural language in some numeric space. To get this, we build a matrix $N\times N$, with $N$ being the number of words in the corpus. We then factorize the matrix by means of two matrices of rank $K$ to give us the desired representation. The results are pretty astounding, as [this article](https://www.tensorflow.org/tutorials/representation/word2vec) shows; closely related words are close in the vector space, and it's easy to get a mapping from concepts to associated concepts (say, countries to capitals).
2. **PCA and SVD** (Principle Component Analysis and Singular Value Decomposition): Features are vectors in $\mathbb{R}^d$ for some d. If we wanted to "compress" this down to one dimension (this doesn't have to be an existing feature, it could be a newly generated one from the existing ones), we could ask that the variance of the projected data be as large as possible. This will lead us to PCA, which we compute using SVD.
3. **Clustering**: to reveal structure in data, we can cluster points given some similarity measure (e.g. Euclidean distance) and the number of clusters we want. We can also ask clusters to be hierarchical (clusters within clusters).
4. **Generative models**: a generative model models the distribution of the data
    1. **Auto-encoders**: these are a form of compression algorithm, trying to find good weights for encoding and compressing the data
    2. **Generative Adversarial Networks** (GANs): the idea is to use two neural nets, one that tries to generate samples that look like the data we get, and another that tries to distinguish the real samples from the fake ones. The aim is that after sufficient training, a classifier cannot distinguish real samples from artificial ones. If we achieve that, then we have built a good model.

### K-Means
A common algorithm for unsupervised learning is called K-means (also called vector quantization in signal processing, or the Baum-Welch algorithm for hidden Markov models). The aim of this algorithm is to cluster the data: we want to find a partition such that every point is exactly one group, such that within a group, the (Euclidean) distance between points is much smaller than across the groups.

In K-means, we find these clusters in terms of cluster centers $\pmb{\mu}$ (also called means). Each center dictates the partition: which cluster a point belongs to depends on which center is closest to the point. In other words, we're minimizing the distance over all $N$ points and $K$ clusters:

$$
\min_{\pmb{\mu}, \vec{z}}{\mathcal{L}_{\text{K-means}}(\vec{z}, \pmb{\mu})}
= \min_{\set{\pmb{\mu}_k}, \set{z_{nk}}}{
    \sum_{n=1}^N{\sum_{k=1}^K{
        z_{nk} \norm{\vec{x}_n - \pmb{\mu}_k}^2
    }}
}
$$

The $z_{nk}$ is the k<sup>th</sup> number in the $\vec{z}_n$ vector, which is a one-hot vector encoding the cluster assignment. Every datapoint $\vec{x}_n$ has an associated vector $\vec{z}_n$ of length K, that takes value 1 in the index of the cluster to which $\vec{x}_n$ belongs, and 0 everywhere else. Mathematically, we can write this constraint as:

$$
z_{nk} \in \set{0, 1}, \quad \sum_{k=1}^K{z_{nk}} = 1
$$

To recap, we have the following vectors:

$$
\begin{align}
\vec{z}_n & = \left[z_{n1}, z_{n2}, \dots, z_{nK}  \right]^T \\
\vec{z}   & = \left[\vec{z}_1, \vec{z}_2, \dots, \vec{z}_N\right]^T \\ 
\pmb{\mu} & = \left[\pmb{\mu}_1, \pmb{\mu}_2, \dots, \pmb{\mu}_K\right]^T \\
\end{align}
$$

This formulation of the problem gives rise to two conditions, which will give us an intuitive algorithm for solving this iteratively. We see that there are two sets of variables to optimize under: $\pmb{\mu}\_k$ and $z_{nk}$. The idea is to fix one and optimize the other.

First, let's fix the centers $\set{\pmb{\mu}_k}$ and work on the assignments. To minimize the sum:

$$
z_{nk} = \begin{cases}
    1, & k = \argmin_{k'}{\norm{\vec{x}_n - \pmb{\mu}_{k'}}^2} \\
    0, & \text{otherwise}
\end{cases}
$$

Intuitively, this means that we're grouping the points by the closest center.

Having computed this, we can fix the assignments $z_{nk}$ to compute optimal centers $\pmb{\mu}_k$. These centers should correspond to the center of the cluster. This minimizes the distance that all points can have to the center.

$$
\pmb{\mu}_k = \frac{\sum_{n=1}^N{z_{nk} \vec{x}_n}}{\sum_{n=1}^N{z_{nk}}}
$$

Note that in this formulation, $k$ is fixed by $\pmb{\mu}_k$, and $n$ varies in the sum. This gives us some kind of average: the sum of all the positions of the points in the cluster, divided by the number of points in the cluster.

How did we get to this formulation? If we take the derivative of the cost function and set it to zero, and then solve it for $\pmb{\mu}_k$, we get to the above.

$$
\nabla_{\pmb{\mu}_k}\mathcal{L}_{\text{K-means}} 
= \sum_{n=1}^N{2 z_{nk} \pmb{\mu}_k - 2 z_{nk} \vec{x}_n}
= 0 
$$

Solving this confirms that taking the average position in the cluster indeed is the best way to optimize our cost.

These observations give rise to an algorithm:

1. Initialize the centers $\set{\pmb{\mu}_k^{(0)}}$. In practice, the algorithm's convergence may depend on this choice, but there is no general best strategy. As such, they can in general be initialized randomly.
2. Repeat until convergence:
    1. Choose $\vec{z}^{(t+1)}$ given $\pmb{\mu}^{(t)}$
    2. Choose $\pmb{\mu}^{(t+1)}$ given $\vec{z}^{(t+1)}$

Each of these two steps will only make the partitioning better, if possible. Still, this may get stuck at a local minimum, there's no guarantee of it converging to the global optimum; it's a greedy algorithm.

#### Coordinate descent interpretation
There are other ways to look at K-means. One way is to think of it as a coordinate descent, minimizing a cost function by finding parameters $\pmb{\mu}$ and $\vec{z}$ iteratively:

$$
\begin{align}
\vec{z}^{(t+1)}   & = \argmin_{\vec{z}} \cost{\vec{z}, \pmb{\mu}^{(t)}} \\
\pmb{\mu}^{(t+1)} & = \argmin_{\pmb{\mu}} \cost{\vec{z}^{(t+1)}, \pmb{\mu}}
\end{align}
$$

This doesn't actually give us much new insight, but it's a nice way to think about it.

#### Matrix factorization interpretation
Another way to think about it is as a matrix factorization. We can rewrite K-means as the following minimization:

$$
\min_{\pmb{\mu}, \vec{z}}{\mathcal{L}_{\text{K-means}}(\vec{z}, \pmb{\mu})} 
= \min_{\vec{M}, \vec{Z}}{\frobnorm{\vec{X}^T - \vec{M} \vec{Z}^T}}^2
$$

A few notes on this notation:

- $\vec{X}$ is, as always, the $N\times D$ data matrix
- $\vec{M}$ is a $D\times K$ matrix representing the mean, the $\pmb{\mu}_k$ vectors; each column represents a different center
- $\vec{Z}^T$ is the $K\times N$ assignment matrix containing the $\vec{z}_n$ vectors. This means that the columns of $\vec{Z}^T$ are one-hot vectors, i.e. that exactly one element of each column of $\vec{Z}^T$ is 1
- $\vec{X}^T - \vec{M} \vec{Z}^T$ computes a matrix whose rows are vectors from each point to its corresponding cluster center.
- The $\frobnorm{\cdot}$ norm here is the [Frobenius norm](https://en.wikipedia.org/wiki/Matrix_norm#Frobenius_norm), the sum of the squares of all elements in matrix. Using the Frobenius norm allows us to get a sum of errors squared, which should be reminiscent of most loss functions we've used so far

This is indeed a matrix factorization as we're trying to find two matrices $\vec{M}$ and $\vec{Z}$ that minimize the above criterion.

#### Probabilistic interpretation
A probabilistic interpretation of K-means will lead us to [Gaussian Mixture Models (GMMs)](#gaussian-mixture-model-gmm). Having a probabilistic approach is useful because it allows us to account for the model that we think generated the data.

The assumption is that we have generated the data by using $K$ separate $D$-dimensional Gaussian distributions. Each sample $\vec{x}_n$ comes from one of the $K$ distributions uniformly at random. These distributions are assumed to have means $\set{\pmb{\mu}_k}$, and the identity matrix as their covariance matrix (that is, variance 1 in each dimension, and the dimensions are i.i.d).

Let's write down the likelihood of a sample $\vec{x}_n$. It's the Gaussian density function of the cluster to which the sample belongs:

$$
p(\vec{x}_n \mid \pmb{\mu}, \vec{z}) = \prod_{k=1}^K{\left(
    \frac{1}{(2\pi)^{D/2}} \exp{\frac{-\norm{\vec{x}_n - \pmb{\mu}_k}^2}{2}}
\right)^{z_{nk}}}
$$

The density assuming that we know that the points are from a given $k$ is what's inside of the large parentheses. We use $z_{nk}$ in the exponent to cancel out the contributions of the clusters to which $\vec{x}_n$ does not belong, keeping only the contribution of its cluster.

Now, if we want the likelihood for the whole set instead of for a single sample, assuming that the samples are i.i.d, we can take the product over all samples:

$$
p(\vec{X}\mid\pmb{\mu},\vec{z}) 
= \prod_{n=1}^N{p(\vec{x}_n \mid \pmb{\mu}, \vec{z})} 
= \prod_{n=1}^N{\prod_{k=1}^K{\left(
    \frac{1}{(2\pi)^{D/2}} \exp{\frac{-\norm{\vec{x}_n - \pmb{\mu}_k}^2}{2}}
\right)^{z_{nk}}}}
$$

This is the likelihood, which we want to maximize. We could equivalently minimize the log-likelihood. We'll also remove the constant factor as it has no influence on our minimization.

$$
\begin{align}
-\log{p(\vec{X}\mid\pmb{\mu},\vec{z})} 
    & = -\log{\prod_{n=1}^N{p(\vec{x}_n \mid \pmb{\mu}, \vec{z})}} \\
    & = -\log{\prod_{n=1}^N{\prod_{k=1}^K{\left(
        \exp{\frac{-\norm{\vec{x}_n - \pmb{\mu}_k}^2}{2}}
    \right)^{z_{nk}}}}} \\
    & = \sum_{n=1}^N{\sum_{k=1}^K{z_{nk} \norm{\vec{x}_n - \pmb{\mu}_k}^2}}
\end{align}
$$

And this is of course the cost function we were optimizing before.

#### Issues with K-means
1. Computation may be heavy for large values of $N$, $D$ and $K$
2. Clusters are forced to be spherical (and cannot be elliptical for instance)
3. Each input can belong to only one cluster (this is known as "hard" cluster assignment, as opposed to "soft" assignment which allows for weighted memberships in different clusters)

### Gaussian Mixture Model (GMM)
So now that we've expressed K-means from a probabilistic view, let's view the probabilistic generalization, which is called a Gaussian Mixture Model.

#### Clustering with Gaussians
To generalize the previous, what if our data comes from Gaussian sources that aren't perfectly circularly symmetric[^isotropic], that don't have the identity matrix as variance? A more general solution is to allow for an arbitrary covariance matrix $\pmb{\Sigma}_k$. This will add another parameter that we need optimize over, but can help us more accurately model the data.

[^isotropic]: The word that expresses this idea is *isotropic*, meaning "uniform in all directions".

#### Soft clustering
Another extension is that we were previously forced to be either from one or another distribution. This is called hard clustering. We can generalize this to soft clustering, where a point can be associated to multiple clusters. In soft clustering, we model $z_n$ as a random variable taking values in $\set{1, \dots, K}$, instead of a one-hot vector $\vec{z}_n$. 

This assignment is given by a certain distribution. We denote the prior probability that the sample comes from the k<sup>th</sup> Gaussian $\normal{\pmb{\mu}_k, \pmb{\Sigma}_k}$, by $\pi_k$:

$$
p(z_n = k) = \pi_k,
\quad \text{where } \pi_k > 0 \, \forall k \text{ and } \sum_{k=1}^K{\pi_k} = 1
$$

#### Likelihood
What we're trying to minimize in this extended model is then (still under the assumption that the data is independently distributed from $K$ samples):

$$
\begin{align}
p(\vec{X}, \vec{z} \mid \pmb{\mu}, \pmb{\Sigma}, \pmb{\pi}) 
    & = \prod_{n=1}^N{p(z_n \mid \pmb{\pi}) \normal{\vec{x}_n \mid z_n, \pmb{\mu}, \pmb{\Sigma}}} \\
    & = \prod_{n=1}^N{
        \prod_{k=1}^K{\left(\pi_k \normal{\vec{x}_n\mid\pmb{\mu}_k, \pmb{\Sigma}_k}\right)^{z_{nk}}}
    } \\
\end{align}
$$

Our notation here maybe isn't the best; we're still using $z_{nk}$ as an indicator, but also $z_n$ as a random variable, and not a one-hot vector anymore. Therefore, to be clear, we should define $z_{nk} = \mathbb{I}\set{z_n = k}$.

This is the model that we'll use. It's not something that we aim to prove or not prove, it's just what we chose to base ourselves on. We'll want to optimize over $\pmb{\mu}$ and $\pmb{\Sigma}$. 

The $\vec{z}_n$ variable is what's known asf a **latent variable**; it's not something that we observe directly, it's just something that we use to make our model more complex. The parameters of the model are $\pmb{\theta} := \set{\pmb{\mu}, \pmb{\Sigma}, \pmb{\pi}}$.

#### Marginal likelihood
The advantage of treating $z_n$ are latent variables instead of parameters is that we can marginalize them out to get a cost function that doesn't depend on them. If we're not interested in these latent variables, we can integrate over the latent variables to get the **marginal likelihood**:

$$
p(\vec{X}\mid\pmb{\theta}) = 
\prod_{n=1}^N{p(\vec{x}_n \mid \pmb{\theta})} =
\prod_{n=1}^N{\sum_{k=1}^K{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}}
$$

<figure>
    <img alt="2D view of weighted gaussians forming a single distribution" src="/images/ml/gmm-multiple-gaussians.png"/>
    <figcaption>Multiple Gaussians form a single distribution in GMM</figcaption>
</figure>

This is a weighted sum of all the models. The weights sum up to one, so we have a valid density. In other words, we are now able to model much more complex distribution functions by building up our distribution from $K$ Gaussian distributions.

<figure>
    <img alt="Weighted Gaussian bell curves" src="/images/ml/weighted-gaussians.svg"/>
    <figcaption>The $\pi_k$ factors allow us to weigh multiple Gaussian distributions</figcaption>
</figure>

Assuming that $D, K \ll N$, the number of parameters in the model was $\mathcal{O}(N)$, because we had an assignment $\vec{z}_n$ for each of the $N$ datapoints. Now, assignments are no longer a parameter, so the number of parameters grows in $\mathcal{O}(D^2 K)$, since we have $K$ covariance matrices, which are $D \times D$, and $K$ $D$-dimensional clusters. Under our assumption that $D, K \ll N$, having $\mathcal{O}(D^2 K)$ parameters is much better.

#### Maximum likelihood
We can optimize the fit of the model by changing the parameters of $\pmb{\theta}$ and optimizing the log likelihood of the above, which is:

$$
\hat{\pmb{\theta}} = \max_{\pmb{\theta}}{
    \sum_{n=1}^N{
        \log{\left(
            \sum_{k=1}^K{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
        \right)}
    }
}
$$

This can be optimized over $\pi_k, \pmb{\mu}_k, \pmb{\Sigma}_k$. Unfortunately, we now have the log of a sum of Gaussians (which are exponentials), which isn't a very nice formula. We'll use this as an excuse to talk about another algorithm, the EM algorithm.

### EM algorithm
In GMM, we had the following set of parameters:

$$
\pmb{\theta}^{(t)} := \set{
    \set{\pmb{\mu}_k^{(t)}}_{k=1}^K, 
    \set{\pmb{\Sigma}_k^{(t)}}_{k=1}^K, 
    \set{\pi_k^{(t)}}_{k=1}^K
}
$$

We wanted to optimize these parameters under the following maximization problem: 

$$
\max_{\pmb{\theta}} \cost{\pmb{\theta}} = 
\max_{\pmb{\theta}}{
    \sum_{n=1}^N{
        \log{\left(
            \sum_{k=1}^K{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
        \right)}
    }
}
$$

Note that in this problem, we're maximizing the cost function instead of minimizing it as we're used to. This is strictly equivalent to minimizing the negative of this, and we're using maximizing and minimizing the negative equivalently.

This is not an easy optimization problem, because wee need to optimize the logarithm of a sum over all choices of $\pmb{\theta}$. 

The **expectation-maximization (EM) algorithm** provides with a general method to tackle this kind of problem. It uses an iterative two-step algorithm: at every step, we try to go from a set of parameters $\pmb{\theta}^{(t)}$ to a better set of parameters $\pmb{\theta}^{(t+1)}$.

In the following, we'll consider an arbitrary probability distribution $q_n^{(t)}$ over $K$ members. Since it is a probability distribution, we have:

$$
q_{nk}^{(t)} \ge 0, \quad \sum_{k=1}^K{q_{nk}^{(t)}} = 1
$$

The EM algorithm consists of optimizing for $q_{nk}$ and $\pmb{\theta}$ alternatively. Note that while every step improves the cost, there is no guarantee that this will converge to the global optimum.

We start by initializing $\pmb{\mu}^{(0)}, \pmb{\Sigma}^{(0)}, \pmb{\pi}^{(0)}$. Then, we iterate between the E and M steps until $\cost{\pmb{\theta}}$ stabilizes. 

#### Expectation step
In the expectation step, we compute how well we're doing:

$$
\cost{\pmb{\theta}^{(t)}} = 
\sum_{n=1}^N{\log{\left(
    \sum_{k=1}^K{\pi_k^{(t)} \normal{\vec{x}_n \mid \pmb{\mu}_k^{(t)}, \pmb{\Sigma}_k^{(t)}}}
\right)}}
$$

We can then choose the new $q_{nk}^{(t)}$ values:

$$
q_{nk}^{(t)} = \frac{
    \pi_k^{(t)} \normal{\vec{x}_n \mid \pmb{\mu}_k^{(t)}, \pmb{\Sigma}_k^{(t)}}
}{
    \sum_{k=1}^K{\pi_k^{(t)} \normal{\vec{x}_n \mid \pmb{\mu}_k^{(t)}, \pmb{\Sigma}_k^{(t)}}}
}
$$

This gives us a new lower bound on the cost:

$$
\cost{\pmb{\theta}^{(t+1)}} 
\ge
\sum_{n=1}^N{\sum_{k=1}^K}{q_{nk}^{(t+1)} \log{\left(
    \frac{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}{q_{nk}^{(t+1)}}
\right)}}
$$

Getting a lower bound means that we have a monotonically non-decreasing cost over the steps $t$. Again, this is a good guarantee because we're maximizing over the cost: it tells us that our E-step improves at every step.

This value is actually the expected value, hence the name of the E-step. We'll see this in the interpretation section below.

{% details Derivation %}
Due to the concavity of the log function, we can apply [Jensen's inequality](https://en.wikipedia.org/wiki/Jensen%27s_inequality) recursively to the cost function to get:

$$
\begin{align}
\log{\left( \sum_{k=1}^K{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}} \right)} 
    & = \log{\left(
        \sum_{k=1}^K{
            q_{nk}^{(t)}
            \frac{
                \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
            }{
                q_{nk}^{(t)}
            }
        } \right)} \\
    
    & \ge \sum_{k=1}^K{
        q_{nk}^{(t)} 
        \log{\frac{
            \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
        }{
            q_{nk}^{(t)}
        }}
    } \\
\end{align}
$$

Just like in the [log-sum inequality](https://en.wikipedia.org/wiki/Log_sum_inequality), we have equality when the terms in the log are equal for all members of the sum. If that is the case, it means that all these terms are the same scalar, and therefore that the numerator and denominator are proportional:

$$
q_{nk}^{(t)} \propto \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
$$

Since $q_{nk}$ is a probability, it must sum up to 1 so we have:

$$
q_{nk}^{(t)} = \frac{
    \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
}{
    \sum_{k=1}^K{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
}
$$
{% enddetails %}

#### Maximization step
We update the parameters $\pmb{\theta}$ as follows:

$$
\begin{align}
\pmb{\mu}_k^{(t+1)} & := \frac{\sum_n{q_{nk}^{(t)} \vec{x}_n}}{\sum_n{q_{nk}^{(t)}}} \\ \\

\pmb{\Sigma}_k^{(t+1)} & := \frac{
    \sum_n{q_{nk}^{(t)} (\vec{x}_n - \pmb{\mu}_k^{(t+1)}) (\vec{x}_n - \pmb{\mu}_k^{(t+1)})^T}
}{
    \sum_n{q_{nk}^{(t)}}
} \\ \\

\pi_k^{(t+1)} & := \frac{1}{N}\sum_n{q_{nk}^{(t)}}
\end{align}
$$

{% details Derivation %}
We had previously let $q_{nk}$ be an abstract, undefined distribution. We now freeze the $q_n^{(t)}$ assignments, and optimize over $\pmb{\theta}$.

In the E step, we derived a lower bound for the cost function. In general, the lower bound is not equal to the original cost. We can however carefully choose $q_{nk}$ to achieve equality. And since we want to maximize the original cost function, it makes sense to maximize this lower bound. Thus, we'll work under this locked assignment of $q_{nk}$ (thus achieving equality for the lower bound). Seeing that we have equality, our objective function (which we want to maximize) is:

$$
\prod_{n=1}^N \sum_{k=1}^K{
    q_{nk}^{(t)} 
    \log{\frac{
        \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
    }{
        q_{nk}^{(t)}
    }}
}
$$

This leads us to maximizing the expression:

$$
\sum_{n=1}^N{\sum_{k=1}^K}{
    q_{nk}^{(t)} \left[
        \log{\pi_k} - \log{q_{nk}^{(t)}} + \log{\normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
    \right]
}
$$

The $\pi_k$ should sum up to one, so we're dealing with a constrained optimization problem. We therefore add a term to turn it into an unconstrained problem. We therefore want to maximize the following over $\pmb{\theta}$:

$$
\sum_{n=1}^N{\sum_{k=1}^K}{
    q_{nk}^{(t)} \left[
        \log{\pi_k} - \log{q_{nk}^{(t)}} + \log{\normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
    \right] + \lambda \sum_{k=1}^K{\pi_k}
}
$$

Differentiating with respect to $\pi_k$, and setting the result to 0 yields:

$$
\sum_{n=1}^N{q_{nk}^{(t)} \frac{1}{\pi_k} + \lambda} = 0
$$

Solving for $\pi_k$ gives us:

$$
\pi_k = -\frac{1}{\lambda} \sum_{n=1}^N{q_{nk}^{(t)}}
$$

We can choose $\lambda$ so that this leads to a proper normalization ($\pi_k$ summing up to 1); this leads us to $\lambda = -N$. Hence, we have:

$$
\pi_k^{(t+1)} := \frac{1}{N}\sum_{n=1}^N {q_{nk}^{(t)}}
$$

This is our first update rule. Let's see how to derive the others. The term $\log{\normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}$ has the form:

$$
-\frac{D}{2}\log{(2\pi)}
+\frac{1}{2}\log{\abs{\pmb{\Sigma}^{-1}}}
-\frac{1}{2}(\vec{x} - \pmb{\mu}_k)^T\pmb{\Sigma}^{-1}(\vec{x} - \pmb{\mu}_k)
$$

We used the fact that for an invertible matrix, $\abs{\pmb{\Sigma}} = 1/\abs{\pmb{\Sigma}^{-1}}$. Differentiating the cost function with respect to $\pmb{\mu}_k$ and setting the result to 0 yields:

$$
\sum_{n=1}^N {q_{nk}^{(t)} \pmb{\Sigma}^{-1}(\vec{x}_n - \pmb{\mu}_k)} = 0
$$

We can multiply this by $\pmb{\Sigma}$ on the left to get rid of the $\pmb{\Sigma}^{-1}$, and solve for $\pmb{\mu}_k$ to get:

$$
\pmb{\mu}_k^{(t+1)} := \frac{
    \sum_n q_{nk}^{(t)}\vec{x}_n
}{
    \sum_n{q_{nk}^{(t)}}
}
$$

Finally, for the $\pmb{\Sigma}$ update rule, we take the derivative with respect to $\pmb{\Sigma}_k^{-1}$ and set the result to 0, yielding:

$$
\sum_{n=1}^N{q_{nk}^{(t)} \frac{1}{2} \pmb{\Sigma}^T_k}
- \frac{1}{2}\sum_{n=1}^N{q_{nk}^{(t)}(\vec{x}_n - \pmb{\mu}_k)(\vec{x}_n - \pmb{\mu}_k)^T}
= 0
$$

Solving for $\pmb{\Sigma}$ yields:

$$
\pmb{\Sigma}_k^{(t+1)} := \frac{
    \sum_n{q_{nk}^{(t)} (\vec{x}_n - \pmb{\mu}_k^{(t+1)}) (\vec{x}_n - \pmb{\mu}_k^{(t+1)})^T}
}{
    \sum_n{q_{nk}^{(t)}}
}
$$

We're using the following fact, which I won't go into details to prove:

$$
\frac{\partial}{\partial \vec{A}} \log{\abs{\vec{A}}} = \vec{A}^{-T}
$$
{% enddetails %}

#### Interpretation
The original model for GMM was that our data points are i.i.d. from a mixture model with $K$ Gaussian components. This led us to the following choice of prior distribution:

$$
\begin{align}
p(\vec{x}_n \mid \pmb{\theta}) 
& = \sum_{k=1}^K {p(\vec{x}_n, z_n = k \mid \pmb{\theta})}
  = \sum_{k=1}^K {p(z_n = k \mid \pmb{\theta}) p(\vec{x}_n \mid z_n = k, \pmb{\theta})} \\ 
& = \sum_{k=1}^K {\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}
\end{align}
$$

Note that we can generalize the EM algorithm to other choices of $p(\vec{x}_n, z_n = k \mid \pmb{\theta})$, but that this is the one we used here.

This probability is an expectation based on the prior $\pi_k$. Let's now look at the posterior distribution of $z_n$, given the datapoints $\vec{x}_n$:

$$
\begin{align}
p(z_n = k \mid \vec{x}_n, \pmb{\theta})
    & = \frac{p(z_n = k, \vec{x}_n, \pmb{\theta})}
             {p(\vec{x}_n, \pmb{\theta})}
      = \frac{p(z_n = k, \vec{x}_n \mid \pmb{\theta})}
             {p(\vec{x}_n \mid \pmb{\theta})} \\
    & = \frac{p(z_n = k, \mid \pmb{\theta})p(\vec{x}_n \mid z_n = k, \pmb{\theta})}
             {p(\vec{x}_n \mid \pmb{\theta})} \\ 
    & = \frac{p(z_n = k, \mid \pmb{\theta})p(\vec{x}_n \mid z_n = k, \pmb{\theta})}
             {\sum_{j=1}^K p(z_n = j\mid\pmb{\theta})p(\vec{x}_n\mid z_n = j, \pmb{\theta})} \\ 
    & = \frac{\pi_k \normal{\vec{x} \mid \mu_k, \pmb{\Sigma}_k}}
             {\sum_{j=1}^K{\pi_j \normal{\vec{x} \mid \mu_j, \pmb{\Sigma}_j}}} =: q_{nk}
\end{align}
$$

The distribution that we previously just explained as an abstract, unknown distribution is in fact the posterior $p(z_n = k \mid \vec{x}_n, \pmb{\theta})$.

We can now explain why the E step is the *expectation* step. Assume that we know the $q_{nk}$ (as a thought experiment, imagine a genie told us the assignment probabilities of each sample $\vec{x}\_n$ to a component $k$, which is exactly what the $q_{nk}$ quantities are). 

As a reminder, the log-likelihood is:

$$
\begin{align}
\log{p(\vec{x}_n, z_n = k \mid \pmb{\theta})} 
& = \log{\left(
    p(z_n = k \mid \pmb{\theta}) p(\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k)
\right)} \\
& = \log{\left(
    \pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}
\right)}
\end{align}
$$

Given the parameters $\pmb{\theta}$, the expected value of the above log-likelihood, over the distribution of $z_n$, is:

$$
\expectsub{z_n}{\log{p(\vec{x}_n, z_n = k \mid \pmb{\theta})}} =
\sum_{k=1}^K{q_{nk} \log{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}}
$$

Summing this over all samples $\vec{x}_n$, we find the cost

$$
\sum_{n=1}^N{\sum_{k=1}^K{q_{nk} \log{\pi_k \normal{\vec{x}_n \mid \pmb{\mu}_k, \pmb{\Sigma}_k}}}}
$$

This is almost the same as the expression we maximized in the derivation for the M step, modulo the terms $-q_{nk} \log{(q_{nk})}$, which are just constants for the maximization.

With this probabilistic interpretation, can write the whole EM algorithm compactly as:

$$
\pmb{\theta}^{(t+1)} = \argmax_{\pmb{\theta}}{\expectsub{p\left(z_n \mid \vec{x}_n, \pmb{\theta}^{(t)}\right)}{\log{p(\vec{x}_n, z_n \mid \pmb{\theta})}}}
$$

## Matrix Factorization
Matrix factorization is a form of unsupervised learning. A well-known example in which matrix factorization was used is the Netflix prize. The goal was to predict ratings of users for movies, given a very sparse matrix of ratings. We'll study the method that achieved the best error.

Let's describe the data a little more formally. Given movies $d = 1, 2, \dots, D$ and users $n = 1, 2, \dots, N$, we define $\vec{X}$ as the $D\times N$ matrix[^inverted-matrix-notation] containing all rating entries; that is, $x_{dn}$ is the rating of the n<sup>th</sup> user for the d<sup>th</sup> movie. We don't have any additional information on the users or on the movies, apart from the ID that's been assigned to them. In practice, the matrix was $D=20'000$ and $N=500'000$, and 99.98% unobserved.

[^inverted-matrix-notation]: Usually, the data matrix is $N \times D$, but here, we define it as the transpose, a $D \times N$ matrix. Don't ask me why, because I have no clue 🤷‍♂️

We want to give a prediction for all the unobserved entries, so that we can give the top entries (say, top 10 movies) for each user.

### Prediction using a matrix factorization
We will aim to find $\vec{W}$ and $\vec{Z}$ such that:

$$
\vec{X} \approx \vec{W}\vec{Z}^T
$$

The hope is to "explain" each rating $x_{dn}$ by a numerical representation of the corresponding movie and user.

Here, we have a "tall" matrix $W\in\mathbb{R}^{D\times K}$, and $\vec{Z}\in\mathbb{R}^{N\times K}$, forming a "flat matrix" $\vec{Z}^T \in \mathbb{R}^{K\times N}$. In practice, compared to the size of $N$ or $D$, $K$ will be relatively small (maybe 50 or so).

We'll assign a cost function that we're trying to optimize:

$$
\min_{\vec{W}, \vec{Z}} \cost{\vec{W}, \vec{Z}} 
:= \min_{\vec{W}, \vec{Z}} \frac{1}{2} \sum_{(d, n)\in\Omega}{\left[
    x_{dn} - (\vec{WZ}^T)_{dn}
\right]^2}
$$

Here, $\Omega\subseteq [D]\times[N]$ is given. It collects the indices of the observed ratings of the input matrix $\vec{X}$. Our cost function here compares the number of stars $x_{dn}$ a user assigned to a movie, to the prediction of our model $\vec{WZ}^T$, by using mean squares.

To optimize this cost function, we need to know whether it is jointly *convex* with respect to $\vec{W}$ and $\vec{Z}$, and whether it is *identifiable* (there is a unique minimum).

We won't go into the full proof, but the answer is the minimum is not unique. Since $\vec{WZ}^T$ is a product, we could just divide one by 10 and multiply the other by 10 to get a different solution with the same cost.

And in fact, it's not even convex. We could compute the Hessian, which is:

$$
\begin{bmatrix}
0 & 1 \\
1 & 0 
\end{bmatrix}$$

This isn't positive semi-definite, and therefore the product isn't convex. 

If we think of $W$ and $Z$ as numbers (or as $1\times 1$ matrices), we can give a simpler explanation, that also gives us the intuition for why this isn't convex.  The function $w\cdot z$ [looks like a saddle function](https://www.wolframalpha.com/input/?i=xy), and therefore isn't convex.

### Choosing K
$K$ is the number of *latent features*. This is comparable to the K we chose in K-means, defining the number of clusters. Large values of K facilitate overfitting.

### Regularization
We can add a regularizer and minimize the following cost:

$$
\cost{\vec{W}, \vec{Z}} =
\frac{1}{2} \sum_{(d, n)\in\Omega}{\left[
    x_{dn} - (\vec{WZ}^T)_{dn}
\right]^2} 
    + \frac{\lambda_w}{2}\frobnorm{\vec{W}}^2
    + \frac{\lambda_z}{2}\frobnorm{\vec{Z}}^2
$$

With scalars $\lambda_w, \lambda_z > 0$.

### Stochastic gradient descent 
With our cost functions in place, we can look at our standard algorithm for minimization. We'll define loss as a sum of many individual loss functions:

$$
\cost{\vec{W}, \vec{Z}} =
\sum_{(d, n)\in\Omega}{f_{d, n}(\vec{W}, \vec{Z})}
= \sum_{(d, n)\in\Omega}{\frac{1}{2}\left[
    x_{dn} - (\vec{WZ}^T)_{dn}
\right]^2}
$$

Let's derive the stochastic gradient for an individual loss function (which is what we need to compute when doing SGD). Matrix calculus is not easy, but understanding it starts with understanding the following sentence: *a gradient with respect to a matrix is a matrix of gradients*. If we compute the gradient of a function $f$ with respect to a matrix $\vec{X}\in\mathbb{R}^{D\times N}$, we get a gradient matrix $\vec{g}\in\mathbb{R}^{D\times N}$, where each element $g_{a, b}$ is the derivative of $f$ with respect to the $(a, b)$ element of $\vec{X}$:

$$
g_{a, b} = \diff{f}{x_{a, b}}
$$

Before we find the stochastic gradient, let's start by just looking at the dimensions of what we're going to compute:

$$
\begin{align}
\nabla_{\vec{W}}  f_{d, n} & \in \mathbb{R}^{D\times K} \\
\nabla_{\vec{Z}}  f_{d, n} & \in \mathbb{R}^{N\times K}
\end{align}
$$

Luckily, we're not doing the full gradient here, but only the *stochastic* gradient, which only requires computing a single entry in the gradient matrix. Therefore, for a fixed pair $(d, n)$ (that is, a rating from user $n$ of movie $d$), we will compute a single entry $(d', k)$ in the $\vec{W}$ derivative:

$$
\left(\nabla_{\vec{W}} f_{d, n}\right)_{(d', k)}
= \diff{f_{d, n}}{w_{d', k}}(\vec{W}, \vec{Z})
= \begin{cases}
    - \left[x_{dn} - (\vec{WZ}^T)_{dn} \right] z_{n, k} & \text{if } d' = d \\
    0 & \text{otherwise}
\end{cases}
$$

The same goes for the derivative by $\vec{Z}$. We'll compute a single entry $(n', k)$ in $\nabla_{\vec{W}} f_{d, n}$:

$$
\left(\nabla_{\vec{Z}} f_{d, n}\right)_{(n', k)}
= \diff{f_{d, n}}{z_{n', k}}(\vec{W}, \vec{Z})
= \begin{cases}
    - \left[x_{dn} - (\vec{WZ}^T)_{dn} \right] w_{d, k} & \text{if } n' = n \\
    0 & \text{otherwise}
\end{cases}
$$

With these, we have the formulation for the whole matrices.

It turns out that computing this is very cheap: $\mathcal{O}(K)$. This is the greatest advantage of using SGD for this. There are no guarantees that this works though; this is still an open research question. But in practice, it works really well.

The update step is then:

$$
\vec{W}^{(t+1)} = \vec{W}^{(t)} - \gamma \nabla_{\vec{W}} f_{d, n} \\
\vec{Z}^{(t+1)} = \vec{Z}^{(t)} - \gamma \nabla_{\vec{Z}} f_{d, n} \\
$$

With stochastic gradient descent, we only compute the gradient of a single $f_{d, n}$ instead of the whole cost $\mathcal{L}$. Therefore, each step only updates the d<sup>th</sup> row of $\vec{W}$, and the n<sup>th</sup> row of $\vec{Z}$.

### Alternating least squares (ALS)
The alternating minimization algorithm alternates between optimizing $\vec{Z}$ and $\vec{W}$. ALS is a special case of this, with square error.

#### No missing entries
For simplicity, let's just assume that there are no missing entries in the data matrix, that is $\Omega = [D]\times[N]$ (instead of $\subseteq$). This makes our life a little easier, and we'll be able to find a closed form solution (indeed, if $\Omega$ is the whole set, the problem is pretty easy to solve; if it's an arbitrary subset, it becomes a NP-hard problem). Our cost is then:

$$
\begin{align}
\cost{\vec{W}, \vec{Z}}

& = \frac{1}{2}\sum_{d=1}^D\sum_{n=1}^N{\left[
        x_{dn} - (\vec{WZ}^T)_{dn}
    \right]^2}
    + \frac{\lambda_w}{2} \frobnorm{\vec{W}}^2 
    + \frac{\lambda_z}{2} \frobnorm{\vec{Z}}^2 \\

& = \frac{1}{2}\frobnorm{\vec{X} - \vec{WZ}^T}^2 
    + \frac{\lambda_w}{2} \frobnorm{\vec{W}}^2 
    + \frac{\lambda_z}{2} \frobnorm{\vec{Z}}^2
\end{align}
$$

ALS then does a **coordinate descent** to minimize the cost (plus a regularizer). First, we fix $\vec{W}$ and compute the minimum with respect to $\vec{Z}$ (we ignore the other regularizer, as minimization is the same with or without an added constant):

$$
\min_{\vec{Z}}{
    \frac{1}{2} \frobnorm{\vec{X} - \vec{WZ}^T}^2} 
    + \frac{\lambda_z}{2} \frobnorm{\vec{Z}}^2
$$

Then, we alternate, minimizing $\vec{W}$ and fixing $\vec{Z}$: 

$$
\min_{\vec{W}}{
    \frac{1}{2}\frobnorm{\vec{X} - \vec{WZ}^T}^2} 
    + \frac{\lambda_w}{2} \frobnorm{\vec{W}}^2
$$

These are two least squares problems. The only difference is that we're searching for a whole matrix in this case, unlike in least squares where we searched for a vector. Still, we can find a closed form for it by setting the gradient with respect to $\vec{W}$ and then $\vec{Z}$ to 0, which will give:

$$
\begin{align}
(\vec{Z}^*)^T & := (\vec{W}^T \vec{W} + \lambda_z \vec{I}_K)^{-1} \vec{W}^T \vec{X} \\
(\vec{W}^*)^T & := (\vec{Z}^T \vec{Z} + \lambda_w \vec{I}_K)^{-1} \vec{Z}^T \vec{X}^T \\
\end{align}
$$

Note that the regularization helps us make sure that problem indeed is invertible (since we're adding an identity matrix). This means that we can find a closed form solution if we don't have any missing entries. 

The cost of finding the solution in each step is then per column, $\mathcal{O}(N)$ and $\mathcal{O}(D)$, which is not quite as good as the $\mathcal{O}(K)$ with SGD. Additionally, we need to construct $\vec{W}^T\vec{W}$ and $\vec{Z}^T\vec{Z}$, which is $\mathcal{O}(D^2)$. The inversion isn't too bad: we're only inverting a $K\times K$ matrix, which is much nicer than dealing with $D$ or $N$. Also note that there is no step size to tune, which makes it easier to deal with (though slower!).

#### Missing entries
As before, we can derive the ALS updates for the more general setting, where we only have certain ratings $(d, n)\in\Omega$. The idea is to compute the gradient with respect to each group of variables, and set it to zero.

### Text representation learning

#### Co-occurrence matrix 
To attempt to get the meaning of words, we can start by constructing co-occurrence counts from a big corpus or text. This is a matrix $\vec{N}$ in which $n_{ij}$ is the number of contexts where word $w_i$ occurs together with word $w_j$. A context is a window of words occurring together (it could be a document, paragraph, sentence, or a window of $n$ words). 

For a vocabulary $\nu = \set{w_1, \dots, w_D}$ and context words $w_n = 1, 2, \dots N$, the co-occurrence matrix is a very sparse $D\times N$.


#### Motivation
We can't plug string-encoded words directly into our learning models. Can we find a meaningful numerical representation for all of our data? We'd like to find a mapping, or **embedding**, for each word $w_i$:

$$
w_i \mapsto \vec{w}_i \in \mathbb{R}^K
$$

To construct a word embedding, we want to find a factorization of the co-occurrence matrix $\vec{N}$. Typically, we actually use $\vec{X} = \log{\vec{N}}$ as the element-wise log of the co-occurrence matrix, i.e. $x_{dn} := \log{(n_{dn})}$. We'll find a factorization such that:

$$
\vec{X} \approx \vec{W}\vec{Z}^T
$$

As before, we let $\Omega\subseteq [D] \times [N]$ collect the indices of non-zero counts in $\vec{X}$. In other words, $\Omega$ contains indices of word pairs that have been observed in the same context.

For each pair of observed words $(w_d, w_n) \in \Omega$, we'll try to explain their co-occurrence count by a numerical representation of the two words; the d<sup>th</sup> row of $\vec{W}$ is the representation of a word $w_d$, and n<sup>th</sup> row of $\vec{Z}$ is the representation of a context word $w_n$.


#### Bag of words
The naive approach would be to pick $K$ to be the size of the vocabulary, $K = \abs{\nu}$. We can then encode words $w_i$ as one-hot vectors taking value 1 at index $i$. This works nicely, but has high dimensionality, and cannot capture the order of the words, which is why it's called the **bag of words** approach.

But we can do this in smarter way. The idea is to pick a much lower $K$, and try to group semantically similar words in this $K$-dimensional space.

![Words with different semantic meanings in different areas of hyperspace](/images/ml/semantic-hyperspace.png)

#### Word2vec 
[word2vec](https://code.google.com/archive/p/word2vec/) is an implementation of the skip-gram model. This model uses binary classification (like logistic regression) to separate real word pairs $(w_d, w_n)$ appearing together in a context window, from fake word pairs $(w_d, w_{n'})$.

It does so by computing the inner product score of the words; $\vec{w}\_d^T \vec{w}\_n$ is real, and must be distinguished from the fake $\vec{w}\_d^T \vec{w}\_{n'}$.

#### GloVe
In the following, we'll give an overview of the method known as [GloVe (Global Vectors)](https://nlp.stanford.edu/projects/glove/), which offers an alternative to word2vec.

To do this, we do the following cost minimization:

$$
\min_{\vec{W}, \vec{Z}} \cost{\vec{W}, \vec{Z}}
:= \min_{\vec{W}, \vec{Z}} \frac{1}{2} \sum_{(d, n)\in\Omega} f_{dn} \left( x_{dn} - (\vec{W}\vec{Z}^T)_{dn} \right)^2
$$

The GloVe embedding uses a little trick to weight the importance of each entry. It computes a weight $f_{dn}$ used in the cost above, according to the following function:

$$
f_{dn} = \min\set{1, \left(\frac{n_{dn}}{ n_{\text{max}} }\right)^\alpha},
\quad \alpha\in[0, 1], \text{ e.g. } \alpha = \frac{3}{4}
$$

Where $n_{\text{max}}$ is a parameter to be tuned, and $n_{dn}$ is the count of $w_d$ and $w_n$ appearing together (not the log, just the normal count). This is a carefully chosen function by the GloVe creators; we can also choose $f_{dn} := 1$ if we don't want to weigh the vectors, but GloVe achieves good results with this choice. 

![Glove weight function](/images/ml/glove-weight-function.png)

For $K$, we can just choose a value, say 50, 100 or 200. Trial and error will serve us well here. 

We can train the factorization with [SGD](#stochastic-gradient-descent) or [ALS](#alternating-least-squares-als).

#### FastText
This is another matrix factorization approach to learn document or sentence representations. Unlike the two previous approaches, [FastText](https://github.com/facebookresearch/fastText) is a supervised algorithm.

A sentence $s_n$ is composed of $m$ words: $s_n = \set{w_1, w_2, \dots, w_m}$. We try to optimize over the following cost function:

$$
\min_{\vec{W}, \vec{Z}} \cost{\vec{W}, \vec{Z}} :=
\min_{\vec{W}, \vec{Z}} \sum_{s_n \text{ a sentence}} f(y_n \vec{WZ}^T\vec{x}_n)
$$

Where:

- $\vec{W}\in\mathbb{R}^{1\times K}$ and $\vec{Z}\in\mathbb{R}^{\abs{\nu}\times K}$ are the factorization
- $\vec{x}_n\in\mathbb{R}^{\abs{\nu}}$ is the bag-of-words representation of sentence $s_n$
- $f$ is a linear classifier loss function, such as the logistic function or hinge loss
- $y_n\in\set{\pm 1}$ is the classification label for sentence $s_n$

## SVD and PCA

### Motivation
**Principal Component Analysis** (PCA) is a popular *dimensionality reduction* method. Given a data matrix, we're looking for a way to linearly map the original $D$ dimensions into $K$ dimensions, with $K \le D$. The criteria for a good such mapping is that the $K$-dimensional representation should represent the original data well.

There are different ways to think of PCA:

- It *compresses data* from $K$ to $D$ dimensions
- It *decorrelates data*, finding a $K$-dimensional space with maximum variance

For machine learning, it's often best not to compress data in this manner, but it may be necessary in certain situations (for reasons of interpretability for example).

In our subsequent discussion, $\vec{X}$ is the $D \times N$ data matrix, whose $N$ columns represent the feature vectors in $D$-dimensional space. 

The PCA will be computed from the data matrix $\vec{X}$ using singular value decomposition.

### SVD
The **singular value decomposition** (SVD) of a $D \times N$ matrix $\vec{X}$ is:

$$
\vec{X} = \vec{USV}^T
$$

The matrices

- $\vec{U}$ is a $D \times D$ orthonormal[^orthonormal] matrix
- $\vec{V}$ is a $N \times N$ orthonormal matrix
- $\vec{S}$ is a $D\times N$ diagonal matrix (with $D$ diagonal entries)

[^orthonormal]: The columns of an orthonormal matrix are orthogonal and unitary (they have have norm 1). The transpose is equal to the inverse, meaning that if $\vec{U}$ is orthogonal, then $\vec{U}^T\vec{U} = \vec{UU}^T = \vec{I}$

One useful property about unitary matrices (like $\vec{U}$ and $\vec{V}$, which are orthonormal, a stronger claim) is that they preserve the norms (they don't change the length of the vectors being transformed), meaning that we can think of them as a rotation. A small proof of this follows:

$$
\frobnorm{\vec{Ux}}^2 = \vec{x}^T\vec{U}^T\vec{Ux} = \vec{x}^T\vec{I}\vec{x} = \frobnorm{\vec{x}}^2 
$$

We'll assume $D < N$ without loss of generality (we could just take the transpose of $\vec{X}$ otherwise). This is an arbitrary choice, but helps us tell the dimensions apart.

The diagonal entries in $\vec{S}$ are the *singular values* in descending order: 

$$
s_1 \ge s_2 \ge \dots \ge s_D \ge 0
$$

The columns of $\vec{U}$ and $\vec{V}$ are the *left* and *right singular vectors*.

### SVD and dimensionality reduction
Suppose we want to compress a $D\times N$ data matrix $\vec{X}$ to a $K\times N$ matrix $\tilde{\vec{X}}$, where $1 \le K \le D$. We'll define this transformation from $\vec{X}$ to $\tilde{\vec{X}}$ by the $K\times D$ compression matrix $\vec{C}$. The decompression (or reconstruction) from $\tilde{\vec{X}}$ to $\vec{X}$ is $\vec{R}$.

Can we find good matrices? Our criteria is that the error introduced when compressing and reconstructing should be small, over all choices of compression and reconstruction matrices:

$$
\frobnorm{\vec{X} - \vec{R}\vec{C}\vec{X}}^2
$$

There are other ways of measuring the quality of a compression and reconstruction, but for the sake of simplicity, we'll stick to this one. 

We can actually place a bound on the reconstruction error using the following lemma.

***

**Lemma**: For any $D \times N$ matrix $\vec{X}$ and any $D\times N$ rank-K matrix $\hat{\vec{X}}$:

$$
\frobnorm{\vec{X} - \hat{\vec{X}}}^2 \ge \frobnorm{\vec{X} - \vec{U}_K \vec{U}_K^T \vec{X}} = \sum_{i \ge K+1}{s_i^2}
$$

Where:

- $\vec{X} = \vec{U}\vec{S}\vec{V}^T$ is the SVD of $\vec{X}$
- $s_i$ are the singular values of $\vec{X}$
- $\vec{U}_K$ is the $D\times K$ matrix of the first $K$ rows of $\vec{U}$

***

If we use $\vec{C} = \vec{U}_K^T$ as our compression matrix, and $\vec{R} = \vec{U}_K$ as the reconstruction matrix, we get a better (or equal) error than  any other choice of reconstruction $\hat{\vec{X}}$. This tells us that the best compression to dimension $K$ is a projection onto the first $K$ columns of $\vec{U}$, which are the first $K$ left singular vectors.

Note that the reconstruction error is the sum of the singular values after the cut-off $K$; intuitively, we can think of the error as coming from the singular values we ignored.

This also tells us that the left singular vectors are ordered in decreasing order of importance. In other words, the above choice of compression uses the *principal* components, the most important ones. This is what really defines PCA.

The term $\vec{U}_K \vec{U}_K^T \vec{X}$ has another simple interpretation. Let $\vec{S}^{(K)}$ be the $D\times N$ diagonal matrix corresponding to a truncated version of $\vec{S}$. It is of the same size, but only has the $K$ first diagonal values of $\vec{S}$, and is zero everywhere else. We claim that:

$$
\vec{U}_K \vec{U}_K^T \vec{X} = \vec{U}_K \vec{U}_K^T \vec{USV}^T = \vec{US}^{(K)}\vec{V}^T
$$

> 👉 It's okay to drop the $K$ subscript on the $\vec{U}$ matrix because $\vec{S}^{(K)}$ already takes care of selecting the first $K$ rows

This tells us that the *best* rank $K$ approximation of a matrix is obtained by computing its SVD, and truncating it at $K$.

#### SVD and matrix factorization
Expressing $\vec{X}$ as an SVD allows us to easily get a matrix factorization.

$$
\vec{X} 
= \vec{USV}^T 
= \underbrace{\vec{U}}_{\vec{W}} \underbrace{\vec{SV}^T}_{\vec{Z}^T} 
= \vec{WZ}^T
$$

This is clearly a special case of the matrix factorization as we saw it previously. In this form, the matrix factorization is perfect equality, and not an approximation&mdash;though in all fairness, this one uses $K = D$. We get a less perfect (but still optimal) factorization with lower values of $K$.

There are two differences from the general case:

- We don't need to preselect the rank $K$ from the start. We can compute the full SVD, and control $K$ at any time later, letting it range from 1 to $\min(D, N)$.
- Matrix factorization started with a $\vec{X}$ with many missing entries; the idea was that the factorization should model the existing entries well, so that we can predict the missing values. This is not something that the SVD can do.

As we've discussed previously, this is the *best* rank K approximation that we can find, as the Frobenius norm of the difference between the approximation and the true value is the smallest possible (sum of the squares of the singular values).

In response to the first point above, note that we still can preselect $K$ and compute the matrix factorization that defines our dimensionality reduction:

$$
\vec{X}_K 
= \vec{U}_K \vec{S}^{(K)} \vec{V}^T 
= \underbrace{\vec{U}_K}_{\vec{W}}
  \underbrace{\vec{S}^{(K)}\vec{V}^T}_{\vec{Z}^T} 
= \vec{W}\vec{Z}^T 
$$


### PCA and decorrelation
Assume that we have $N$ $D$-dimensional points in a $D\times N$ matrix $\vec{X}$. We can compute the empirical mean and covariance by:

$$
\begin{align}
\bar{\vec{x}} & = \frac{1}{N} \sum_{n=1}^N {\vec{x}_n} \\
\vec{K} & = \frac{1}{N} \sum_{n=1}^N (\vec{x}_n - \bar{\vec{x}}) (\vec{x}_n - \bar{\vec{x}})^T
\end{align}
$$

The covariance matrix $\vec{K}$ is a $D \times D$ rank-1 matrix. If our data is from i.i.d. samples then these empirical values will converge to the true values when $N \rightarrow \infty$.

Before we do PCA, we need to *center the data around the mean*. Let's assume our data matrix $\vec{X}$ has been preprocessed as such. Using the SVD, we can rewrite the empirical covariance matrix as: 

$$
N\vec{K} 
= \sum_{n=1}^N {(\vec{x}_n \vec{x}_n^T)} 
= \vec{X}\vec{X}^T 
= \vec{U}\vec{S}\vec{V}^T \vec{V}\vec{S}^T \vec{U}^T 
= \vec{U}\vec{S}\vec{S}^T \vec{U}^T 
= \vec{U}\vec{S}_D^2 \vec{U}^T
$$

This works because $\vec{V}$ is an orthogonal matrix, so $\vec{V}^T\vec{V} = I_N$, and $\vec{S}$ is diagonal, so $\vec{SS}^T = S_D^2$, where $S_D^2$ is a $D\times D$ diagonal matrix consisting of the D first columns of $\vec{S}$.

PCA finds orthogonal axes centered at the mean, that represent the most variance, in decreasing order of variance. Starting with orthogonal axes, it finds the rotation $\vec{U}^T$ so that the axes point in the direction of maximum variance. This can be seen in [this visual explanation of PCA](http://setosa.io/ev/principal-component-analysis/). 

With this intuition about PCA in mind, let's try to decompose the covariance again, but this time considering the transformed, compressed data $\tilde{\vec{X}} = \vec{U}_K^T\vec{X}$. The empirical covariance of along this transformed axis is:

$$
N \tilde{\vec{K}} 
= \tilde{\vec{X}} \tilde{\vec{X}}^T 
= \vec{U}^T\vec{X}\vec{X}^T\vec{U} 
= \vec{U}^T\vec{US}_D^2\vec{U}^T\vec{U} 
= \vec{S}_D^2
$$

Here, the empirical co-variance is *diagonal*. This means that through PCA, we've transformed our data to make the various components **uncorrelated**. This gives us some intuition of why it may be useful to first transform the data with the rotation $\vec{U}^T\vec{X}$.

Additionally, by the definition of SVD, the singular values are in decreasing order (so the first one, $s_1$, is the greatest one). Since we have a diagonal matrix as our empirical variance, it means that the variance of the first component is $s_1^2$, which proves the property of PCA's axes being in decreasing order of variance.

Assume that we're doing classification. Intuitively, it makes sense that classifying features with a larger variance would be easier (when the variance is 0, all data is the same and it becomes impossible to classify using that component). From this point of view, it makes intuitive sense to only keep the first $K$ rows of $\tilde{\vec{X}}$ when we perform dimensionality reduction; we keep the features that have high variance and are uncorrelated, and we discard all features with variance close to 0 as they're hard to classify.

### Computing the SVD efficiently
To compute the SVD of a matrix $\vec{X}$, we must compute the matrices $\vec{U}$ and $\vec{S}$ Let's see how we can do this efficiently. 

Let's consider the $D\times D$ matrix $\vec{XX}^T$. As before, since $\vec{V}$ is orthogonal, we can use the SVD to get:

$$
\vec{X}\vec{X}^T 
= \vec{USV}^T\vec{VS}^T\vec{U} 
= \vec{USS}^T\vec{U}^T 
= \vec{U} \vec{S}_D^2 \vec{U}^T
$$


Let $\vec{u}_j$ denote the j<sup>th</sup> column of $\vec{U}$.

$$
\vec{XX}^T \vec{u}_j = \vec{U}\vec{S}_D^2 \vec{U}^T \vec{u}_j = s_j^2 \vec{u}_j
$$

We see that the the j<sup>th</sup> column of $\vec{U}$ is the j<sup>th</sup> eigenvector of $\vec{XX}^T$, with eigenvalue $s_j^2$. Therefore, finding the eigenvalues and eigenvectors for $\vec{XX}^T$ gives us a way to compute $\vec{U}$ and $\vec{S}$.

There's a subtle point to be made here about the sign of the eigenvector. If $\vec{u}_j$ is an eigenvector, then so is $-\vec{u}_j$. But if our goal is simply to use that decomposition to do PCA, then it doesn't matter as the sign of the columns of $\vec{U}_K^T$ disappear when computing $\vec{U}_K\vec{U}_K^T$. However, if the goal is simply to do SVD, we must fix some choice of signs, and be consistent in $\vec{V}$.

To compute this decomposition, we can either work with $\vec{X}^T\vec{X}$ or $\vec{XX}^T$. This is practical, as it allows us to pick the smaller of the two and work in dimension $D$ or $N$.

### Pitfalls of PCA
Unfortunately, PCA is no miracle cure. The SVD is not invariant under scalings of the features in the original matrix $\vec{X}$. This is why it's so important to normalize features. But there are many ways of doing this, and the result of PCA is highly dependent on how we do this, and there is a large degree of arbitrariness. 

Still, the conventional approach for PCA is to remove the mean and normalize the variance to 1.

## Neural Networks

### Motivation
We've seen that simple linear classification schemes like logistic regression can work well, but also have their limitations. They work best when we add well chosen features to the original data matrix, but this can be a difficult task: a priori, we don't know which features are useful.

We could add a ton of polynomial features and hope that some of them are useful, but this quickly becomes computationally infeasible, and leads to overfitting. To mediate the computational complexity, we can use the kernel trick; to solve the feature selection task, we could collaborate with domain experts to pick just a few good features.

But what if we could *learn* the features instead of having to construct them manually? This is what neural networks allow us to do.

### Structure
As always in supervised learning, we start with a dataset $\Strain = \set{(\vec{x}_n, y_n)}$, with $\vec{x}_n \in\mathbb{R}^D$.

Let's take a look at a simple multilayer perceptron neural network. It has an **input layer** of size $D$ (one for each dimension of the data), $L$ **hidden layers** of size $K$, and one **output layer**.

![Fully connected multilayer perceptron](/images/ml/nn.svg)

This is a *feedforward* network: the computation is performed from left to right, with no feedback loop. Each node in the hidden layer $l$ is connected to all nodes in the previous layer $l-1$ via a weighted edge $w_{i, j}^{(l)}$. The number $L$ and size $K$ of hidden layers are hyperparameters to be tuned.

A node outputs a non-linear function of a weighted sum of all the nodes in the previous layer, plus a bias term. For instance, the output of node $j$ at layer $l$ is given by: 

$$
x_j^{(l)} = \phi\left( \sum_{i=1}^K w_{i, j}^{(l)} x_i^{(l - 1)} + b_j^{(l)} \right)
$$

The actual learning consists of choosing all these weights appropriately for the task. The $\phi$ function is called the **activation function**. It's very important that this is non-linear; otherwise, the whole neural net's global function is just a linear function, which defeats the idea of having a complicated, layered function.

A typical choice for this function is the sigmoid function:

$$
\phi(x) = \frac{1}{1+e^{-x}}
$$

The layered structured of our neural net means that there are $K^2 L$ parameters.

### How powerful are neural nets? 
This chapter somewhat follows [Chapter 4 of Nielsen's book](http://neuralnetworksanddeeplearning.com/chap4.html). See that for a more in-depth explanation of this argument.

We'll state the following lemma without proof. Let $f: \mathbb{R}^D \rightarrow \mathbb{R}$, where its Fourier transform is: 

$$
\tilde{f}(w) = \int_{\mathbb{R}^D} {f(\vec{x}) e^{-j\omega^T\vec{x}}} d\vec{x}
$$

We also assume that:

$$
\int_{\mathbb{R}^D} {\abs{\omega} \abs{\tilde{f}(\omega)}} d\omega \le C
$$

Essentially, these assumptions just say that our function is "sufficiently smooth" (the $C$ has to do with the smoothness; as long as it is real, the function can be shown to be continuously differentiable). Then, for all $n \ge 1$, there exists a function $f_n$ of the form:

$$
f_n(\vec{x}) = \sum_{j=1}^n {c_j \phi(\vec{x}^T\vec{w}_j + b_j)} + c_0
$$

This is a function that is representable by a neural net with one hidden layer with $n$ nodes and "sigmoid-like" activation functions (this is more general than just sigmoid, but includes sigmoid) such that:

$$
\int_{\abs{\vec{x}} \le r} {(f(\vec{x}) - f_n(\vec{x}))^2} d\vec{x}
\le
\frac{(2Cr)^2}{n}
$$

This tells us that the error goes down with a rate of $\frac{1}{n}$. Note that this only guarantees us a good approximation in a ball of radius $r$ around the center. The larger the bounded domain, the more nodes we'll need to approximate a function to the same level (the upper bound grows in terms of $r^2$).

In fact, we'll see that if we have enough nodes in the network, then we can approximate the underlying distribution function. There is no limit, and no real lower bounds, but we do have the property that neural nets have significant expressive power provided that they're large enough; we'll give an intuitive explanation of this below.

### Approximation in average
We'll give a simple and intuitive, albeit a little hand-wavy explanation as to why neural nets with sigmoid activation function and at most two hidden layers already have a large expressive power. We're searching for an approximation "in average", i.e. so that the integral over the absolute value of the difference is small.

In the following, we let $f: \mathbb{R} \rightarrow \mathbb{R}$ be a scalar function on a bounded domain. This discussion generalizes to functions that are $\mathbb{R}^D \rightarrow \mathbb{R}$, but in these notes we'll just cover the simple scalar function case (see Nielsen book and lecture notes for the generalization).

$f$ is Riemann integrable, meaning that it can be approximated arbitrarily precisely (with error at most $\epsilon$, for arbitrary $\epsilon > 0$) by a finite number of rectangles.

<figure>
    <img src="/images/ml/riemann.png" alt="Riemann integrals of a function">
    <figcaption>Lower and upper Riemann sums</figcaption>
</figure>

It follows that a finite number of hidden nodes can approximate any such function arbitrarily closely, since we can model rectangles with the function:

$$
f(x) = \phi(w(x-b))
$$

Indeed, this function takes on value $\frac{1}{2}$ at $x=b$; we can think of this as the "transition point". The larger the value of the weight $w$, the faster the transition from 0 to 1 happens. So if we set $b=0$, the transition from 0 to 1 happens at $x=0$. At this point, the derivative of $f$ if $w/4$, to the width of the transition is of the order of $4/w$. 

All of the above says that we can create a rectangle that jumps from 0 to 1 at $x=a$ and jumps back to 0 at $x=b$, with $a < b$, with the following, taking a very large value for $w$:

$$
\phi(w(x-a)) - \phi(w(x-b))
$$

A few of these rectangles are graphed below:

<figure>
    <img src="/images/ml/nn-rectangles.png" alt="Plots of rectangles produced by different values of w">
    <figcaption>Approximate rectangles for $w=10, 20, 50$, respectively</figcaption>
</figure>

This special rectangle formula has a simple representation in the form of a neural net. This network creates a rectangle from $a$ to $b$ with transition weight $w$ and height $h$: the output of the nodes in the hidden layer is $\phi(w(x - a))$ and $\phi(w(x - b))$, respectively. 

![A neural net implementation of the above rectangle function](/images/ml/small-nn.svg)

Scaling this up, we can create the number of rectangles we need to do a Riemann approximation of the function.

Note that doing the Riemann integral is rarely, if ever, the best way to approximate a function. We wouldn't want to approximate a smooth function with horrible squares. The argument here isn't that this is an efficient approach, just that NNs are *capable* of doing this.

#### Other activation functions
The same argument also holds under other activation functions. For instance, let's try to work it out with the rectified linear unit (ReLU) function:

$$
(x)_+ = \max{\set{0, x}}
$$

Let $f(x)$ be the function we're trying to approximate. The Stone-Weierstrass theorem tells us that for every $\epsilon > 0$, there's a polynomial $p(x)$ locally approximating it arbitrarily precisely; that is, for all $x\in[0, 1]$, we have:

$$
\abs{f(x) - p(x)} < \epsilon
$$

This function $f(x)$ can also be approximated in $L_\infty$ norm by piecewise linear function of the form:

$$
q(x) = \sum_{i=1}^m (a_i x + b_i) \mathbb{I}_{\set{r_{i-1} \le x < r_i}}
$$

Where $0 = r_0 < r_1 < \dots < r_m = 1$ is a suitable partition of $[0, 1]$. This continuity imposes the constraint:

$$
a_i r_i + b_i = a_{i+1}r_i + b_{i+1}, \quad i = 1, \dots, m-1
$$

This allows us to rewrite the $q(x)$ function as follows:

$$
q(x) = \tilde{a}_1 x + \tilde{b}_1 + \sum_{i = 2}^m{\tilde{a}_i(x - \tilde{b}_i)_+}
$$

Where:

$$
a_1 = \tilde{a}_1, 
\quad
a_i = \sum_{j=1}^m{\tilde{a}_i},
\quad
\tilde{b}_i = r_{i - 1}
$$

### Popular activation functions

#### Sigmoid
The sigmoid function $\sigma(x)$ has a domain of $[0, 1]$. The main problem with sigmoid is the gradient for large values of $x$, which goes very close to zero. This is known as the "vanishing gradient problem", which may make learning slow.

$$
\phi(x) = \sigma(x) = \frac{1}{1+e^{-x}}
$$

#### Tanh
The hyperbolic tangent has a domain of $[-1, 1]$. It suffers from the same "vanishing gradient problem".

$$
\phi(x) = \tanh(x) = \frac{e^x - e^{-x}}{e^x + e^{-x}} = 2\sigma(2x) - 1
$$

#### ReLU
Rectified linear unit (ReLU) is a very popular choice, and is what works best in most cases.

$$
\phi(x) = (x)_+ = \max{\set{0, x}}
$$

ReLu is always positive, and is unbounded. A nice property about it is that its derivative is 1 (and does not vanish) for positive values of $x$ It has 0 derivative for negative values, though.

#### Leaky ReLU
Leaky ReLu solves the 0-derivative problem of ReLU by adding a very small slope $\alpha$ (a hyper-parameter that can be optimized) for negative values:

$$
\phi(x) = \max{\set{\alpha x, x}}
$$

#### Maxout
Finally, maxout is a generalization of ReLU and leaky ReLU. Again, the constants can be optimized. Note that this is quite different from previous cases, where we computed the activation function of a weighted sum. Here, we compute $k \ge 2$ different weighted sums, and then choose the maximum.

$$
\phi(\vec{x}) = \max{\set{\vec{x}^T \vec{w}_1 + b_1, \dots, \vec{x}^T \vec{w}_k + b_k}}
$$

### SGD and Backpropagation
Remember that the value of every node is computed by:

$$
x_j^{(l)} = \phi\left( \sum_{i=1}^K w_{i, j}^{(l)} x_i^{(l - 1)} + b_j^{(l)} \right)
$$

We'd like to optimize this process. Let's assume that we want to do a regression. Let's denote the output of the neural net by the function $f$. Our cost function would then simply be:

$$
\mathcal{L} = \frac{1}{N} \sum_{n=1}^N{(y_n - f(\vec{x}_n))^2}
$$

We'll omit regularization for the simplicity of our explanation, but it can trivially be added in, without loss of generality. 

To optimize our cost, we'd like to do a gradient descent. Unfortunately, this problem is not convex[^convexity-nn], and we expect it to have many local minima, so there is no guarantee of finding an optimal solution. But the good news is that SGD is *stable* when applied to a neural net, which means that the outcome won't be too dependent on the training set. SGD is still the state-of-the art in neural nets.

[^convexity-nn]: The cost function is no longer convex as $f$ is now a forward pass through a neural net, including multiple applications of the non-linear activation function

Let's do a stochastic gradient descent on a single data point. We need to compute the derivative of the cost of this single point, which is:

$$
\frac{\partial \mathcal{L}_n}{\partial w_{i, j}^{(l)}},
\qquad
\frac{\partial \mathcal{L}_n}{\partial b_j^{(l)}}
$$

We can gain a more general formula by restating the problem in vector form. Generally, a layer of neurons is computed by:

$$
\vec{x}^{(l)} 
= f^{(l)}(\vec{x}^{(l - 1)}) 
= \phi\left(
    \left(\vec{W}^{(l)}\right)^T \vec{x}^{(l - 1)} + \vec{b}^{(l)}
\right)
$$

The overall function of the neural net is thus something taking the input layer $\vec{x}^{(0)}$, and passing it through all hidden layers:

$$
\vec{y} = f(\vec{x}^{(0)}) = f^{(L+1)} \circ \dots \circ f^{(2)} \circ f^{(1)}(\vec{x}^{(0)})
$$

To make things more convenient, we'll introduce notation for the linear part of the computation of a layer. The computation below corresponds to our **forward pass**.

$$
\begin{align}
\vec{z}^{(l)} & = \left(\vec{W}^{(l)}\right)^T \vec{x}^{(l - 1)} + \vec{b}^{(l)} \\
\vec{x}^{(l)} & = \phi(\vec{z}^{(l)})
\end{align}
$$

To be formal, we'll just quickly state that our notation here means that we're applying $\phi$ component-wise. We see that to compute a $\vec{x}^{(l)}$, we need $\vec{x}^{(l - 1)}$; we therefore need to start from the input layer and compute our way forward, until the last layer, which is why this is called the forward path.

Note that the full chain of computation that gets us to the output in $\mathcal{O}(K^2 L)$, which is not too bad.

For the **backwards pass**, let's remember that the cost of a single data-point is:

$$
\mathcal{L}_n = (y_n - f^{(L+1)} \circ \dots \circ f^{(2)} \circ f^{(1)}(\vec{x}^{(0)}))^2
$$

we'll want to compute the following, which is a derivative over both $\partial w_{i, j}^{(l)}$ and $\partial b_j^{(l)}$.

$$
\begin{align}
\delta_j^{(l)} 
& = \frac{\partial\mathcal{L}_n}{\partial z_j^{(l)}} \\
& = \sum_k 
    \frac{\partial\mathcal{L}_n}{\partial z_k^{(l+1)}}
    \frac{\partial z_k^{(l+1)}}{\partial z_j^{(l)}}  \\
& = \sum_k \delta_k^{(l+1)} \vec{W}_{j, k}^{(l+1)} \phi'\left( z_j^{(l)} \right)
\end{align}
$$

We can write this more compactly using $\odot$, which is the [Hadamard product](https://en.wikipedia.org/wiki/Hadamard_product_(matrices)) (element-wise multiplication of vectors):

$$
\pmb{\delta}^{(l)} = \left(\vec{W}^{(l+1)} \pmb{\delta}^{(l+1)}\right) \odot \phi'\left(\vec{z}^{(l)}\right)
$$

Here, to compute a $\pmb{\delta}^{(l)}$, we need $\pmb{\delta}^{(l+1)}$; we must therefore start from the output, and compute our way back to layer 0, which is why we call this a backwards pass. Speaking of which, we will need a $\delta^{(L+1)}$ to start with on the the right side. Therefore, we set:

$$
\delta^{(L+1)} = -2\left(y_n - x^{(L+1)}\right) \phi'\left(z^{(L+1)}\right)
$$

Note that $z^{(L+1)}$, $\delta^{(L+1)}$ and $x^{(L+1)}$ are denoted as scalars because we assumed that our neural net only had a single output node.

Now that we have both $\vec{z}^{(l)}$ and $\pmb{\delta}^{(l)}$, let's go back to our initial goal, which is to compute the following:

$$
\frac{\partial \mathcal{L}_n}{\partial w_{i, j}^{(l)}}

= \sum_k 
    \frac{\partial\mathcal{L}_n}{\partial z_k^{(l)}}
    \frac{\partial z_k^{(l)}}{\partial w_{i, j}^{(l)}}

= \frac{\partial\mathcal{L}_n}{\partial z_k^{(l)}}
  \frac{\partial z_k^{(l)}}{\partial w_{i, j}^{(l)}}

= \delta_j^{(l)} \vec{x}_i^{(l - 1)}
$$

We were able re-express this as a product of these elements that we already have. We were able to drop the sum because changing a single weight $w_{i, j}^{(l)}$ *only* changes the single sum $z_j$; all other sums stay unchanged, and therefore do not enter into the derivative with respect to $w_{i, j}^{(l)}$. In other words, the term $\frac{\partial z_k^{(l)}}{\partial w_{i, j}^{(l)}}$ is only non-zero when $j=k$.

We've thus found the result of the two derivatives we wanted to originally find:

$$
\frac{\partial \mathcal{L}_n}{\partial w_{i, j}^{(l)}}
= \delta_j^{(l)} \vec{x}_i^{(l - 1)},
\qquad
\frac{\partial \mathcal{L}_n}{\partial b_j^{(l)}}
= \delta_j^{(l)}
$$

### Regularization
To regularize the weights, we can add $\Omega(\vec{W})$ to the cost function. Typically, we don't include bias terms in the regularization (experience shows that it just doesn't work quite as well). Therefore, the regularization term is expressed as something like:

$$
\Omega(\vec{W}) = \frac{1}{2} \mu^{(l)} \sum_{l=1}^{L+1} \frobnorm{\vec{W}^{(l)}}^2
$$

We have different weights $\mu^{(l)} \ge 0$ for each layer. With the right constants $\mu^{(l)}$, this regularization will favor small weights and can help us avoid overfitting.

Let $\Theta = w_{i, j}^{(l)}$ denote the weight that we're updating, and let $\eta$ be the step size. Assuming that we use the same weight $\mu^{(l)} = \mu$ for all layers $l$, the gradient descent rule becomes:

$$
\Theta^{(t+1)} = \Theta^{(t)} - \eta (\nabla_{\Theta}\mathcal{L} + \mu \Theta^{(t)}) = \Theta^{(t)} (1 - \eta\mu) + \eta \nabla_{\Theta}\mathcal{L}
$$

Usual GD deducts the step size $\eta$ times the gradient from the variable, but here, we also decrease the weights by a factor $(1 - \eta\mu)$; we call this *weight decay*.

### Dataset augmentation
The more data we have, the better we can train. In some instances we can generate new data from the data we are given. For instance, with the classic [MNIST database of handwritten digits](https://en.wikipedia.org/wiki/MNIST_database), we could generate new data by generating rotated characters from the existing dataset. That way, we can also train our network to become invariant to these transformations. We could also add a small amount of noise to our data (by means of compression to degree $K$ with PCA, for instance). 

### Dropout
We define the probability $p_i^{(l)}$ to be the probability of whether or not to keep node $i$ in layer $l$ in the network at a given step. A typical value would be $p_i^{(l)} = 0.8$, which means 80% chance of keeping a given node. This defines a different *subnetwork* at every step of SGD.

There are many variations of dropout; we talked about dropping nodes, but one could also drop edges. To predict, we can generate $K$ subnets and take the average prediction. Alternatively, we could use the whole network for the prediction, but scaling the output of node $i$ at layer $l$ by $p_i^{(l)}$, which guarantees that the expected input at each node stays the same as during training.

Dropout is a method to avoid overfitting, as nodes cannot "rely" on other nodes being present. It allows us to do a kind of model averaging, as there's an exponential number of subnetworks, and we're averaging the training over several of them. Averaging over many models is a standard ML trick, that's usually called *bagging*, which usually leads to improved performance.

### Convolutional nets
The basic idea in convolutions is to slide a small window (called a *filter*) over an array, and computing the dot product between the filter and the elements it overlaps for every position in the array. A good introduction to the subject can be found on [Eli Bendersky's website](https://eli.thegreenplace.net/2018/depthwise-separable-convolutions-for-machine-learning/).

#### Structure
Classically, we've defined our networks as fully connected graphs, where every node in layer $l$ is connected to every node in layer $l-1$. This means that if we have $K$ nodes in each of the two layers, we have $K^2$ edges, and thus parameters, between them. Convolutional nets allow us to have somewhat more sparse networks.

In some scenarios, it makes sense that a more local processing of data should suffice. For instance, convolutions are commonly used in signal processing, were we have a discrete-time system (e.g. audio samples forming an audio stream), which is denoted by $x^{(0)}[n]$. To process the stream we run it through a linear filter $f[n]$, which produces an output $x^{(1)}[n]$. This filter is often "local", looking at a window of size $k$ around a central value:

$$
x^{(1)}[n] = \sum_k f[k]x^{(0)}[n - k]
$$

We have the same scenario if we think of a 2D picture, where the signal is $x^{(0)}[n, m]$. The filter can bring out various aspects, either smoothing features by averaging, or enhancing them by taking a so-called "high-pass" filter.

$$
x^{(1)}[n, m] = \sum_{k, l} f[k, l]x^{(0)}[n-k, m-l]
$$

The output $x^{(1)}$ of the filter at position $[n, m]$ only depends on the values of the input $x^{(0)}$ at positions close to $[n, m]$. This is more sparse and local than a fully connected network. This also implies that we use the *same filter* at every position, which drastically reduces the number of parameters.

In ML, we do something similar. We have a filter with a fixed size $K_1 \times K_2$ with coefficients for every item in the filter. We move the filter over the input matrix, and compute a weighted sum for every position in the matrix.

#### Padding
To handle border cases, we can either do:

- *Zero padding*, where give the filter a default value (usually 0) when going over the edges.
- *Valid padding*, where we are careful only to run the filter within the bounds of the matrix. This results in a smaller output matrix.

#### Channels
A picture naturally has at least three channels: every pixel has a red, green and blue component. So a 2D picture can actually be represented as a 3D cube with a depth of 3. Each layer in the depth represents the same 2D image in red, green and blue, respectively. Each such layer is called a *channel*.

Channels can also stem from the convolution itself. If we're doing a convolution on a 2D picture, we may want to use multiple filters in the same model. Each of them produces a different output; these outputs are also *channels*. If we produce multiple 2D outputs with multiple filters, we can stack them into a 3D cube.

As we get deeper and deeper into a CNN, we tend to add more and more channels, but the 2D size of the picture typically gets smaller and smaller, either due to valid padding or subsampling. This leads to a pyramid shaped structure, as below.

![Example of a CNN getting deeper and deeper](/images/ml/cnn.svg)

#### Training
CNNs are different from fully connected neural nets in that only some of the edges are present, and in that they use weight sharing. The former makes our weight matrices sparser, but doesn't require any changes in SGD or backpropagation; the latter requires a small modification in the backpropagation algorithm.

With CNNs, we run backpropagation ignoring that some weights are shared, considering each weight on each edge to be an independent variable. We then sum up the gradients of all edges that share the same weight, which gives us the gradient for the network with weight sharing.

Why we do this may seem a little counterintuitive at first, but we'll attempt to give the mathematical intuition for it. Let's consider a simple example, in which we let $f(x, y, z)$ be a function from $\mathbb{R}^3 \rightarrow \mathbb{R}$. If we let $g(x, y) = f(x, y, x)$, then $z$ is no longer an independent variable, but is instead fixed to $z = x$. The gradients of $g$ and $f$ are given by:

$$
\begin{align}
\nabla g(x, y) & = \left(
    \diff{g(x, y)}{x}, \quad
    \diff{g(x, y)}{y}
\right) \\

\nabla f(x, y, z) & = \left(
    \diff{f(x, y, z)}{x}, \quad
    \diff{f(x, y, z)}{y}, \quad
    \diff{f(x, y, z)}{z} 
\right) \\
\end{align}
$$

To compute the gradient of $g$, we can first compute that of $f$, and then realize that:

$$
\left(
    \diff{g(x, y)}{x}, \;
    \diff{g(x, y)}{y}
\right)
= 
\left(
    \diff{f(x, y, z)}{x} + \diff{f(x, y, z)}{z}, \;
    \diff{f(x, y, z)}{y}
\right) \\
$$

This is a general property: we can add up the derivatives of the shared weights to compute the value of a single derivative.

## Bayes Nets
We've often seen in this course that there are multiple ways of thinking of the same things; for instance, we've often seen different models as variations of least squares, and seen different ways of getting back to least squares (e.g. the probabilistic approach assuming linear model with Gaussian noise, in which we maximize likelihood, or the approach in which we try to minimize MSE, etc).

But these have often been based on very simple assumptions. To model more complex models of causality, we turn to *graphical models*. They allow to use a graphical depiction of the relationships between random variables. The most prominent ones are *Bayes Nets*, *Markov Random Fields* and *Factor Graphs*.

### From distribution to graphs
Assume that we're given a large set of random variables $X_1, \dots, X_D$ and that we're interested in their relationships (e.g. whether $X_1$ and $X_2$ are independent given $X_3$). It doesn't matter if these are discrete or continuous; we'll just think of them as being discrete, and consider $p(\cdot)$ to be the density.

The most generic way to write down this model is to write it as a generic distribution over a vector of random variables. The chain rule tells us:

$$
p(X_1, \dots, X_D) = p(X_1)p(X_2 \mid X_1) \cdots p(X_D \mid X_1, \dots, X_{D-1})
$$

In the above, we used the natural ordering $X_1, X_2, \dots, X_D$, but we could just as well have used any of the $D!$ orders: this degree of freedom will be important later. Each variable in this chain rule formulation is conditioned on other variables. For instance, for $D=4$, we have:

$$
p(X_1, X_2, X_3, X_4) = p(X_1)p(X_2 \mid X_1)p(X_3 \mid X_1, X_2)p(X_4 \mid X_1, X_2, X_3)
$$

A way to represent this expansion of the chain rule is to draw which variables are conditioned on which. In Bayes nets, we draw an arrow from each variable to the variables that are conditioned on it.

![The Bayes net corresponding to the above](/images/ml/bayes-net-1.svg)

It's important not to interpret this as causality, because the ordering that we picked chain rule is arbitrary, and could lead to many kind of arrows in the Bayes nets representation. If we just have $D=2$, we could have an arrow from $X_1$ to $X_2$ just as well as the other way around. The arrows are sufficient condition to guarantee dependence, but not a necessary one: they allow for dependence, but don't guarantee it.

Still, when we know that two variables are (conditionally) independent, we can remove edges from the graph. Perhaps we have $p(X_3 \mid X_1, X_2) = p(X_3 \mid X_2)$, in which case we can draw the same graph, but without the edge from $X_1$ to $X_3$.

![The Bayes net where X1 is independent from X3 conditional on X2](/images/ml/bayes-net-2.svg)

This is suddenly much more interesting. Allowing to remove edges between independent variables means that we can have many different graphs. If we couldn't do that, we would always generate the same graph with the chain rule, in the sense that it would always have the same topology; the exact ordering could still change depending on how we apply the chain rule. This is what will allow us to get information on independence from a graph.

### Cyclic graphs
![Bayes net with a cycle](/images/ml/bayes-net-3.svg)

The above net would correspond to the factorization:

$$
p(X_1 \mid X_2) p(X_2 \mid X_3) p(X_3 \mid X_1)
$$

This is clearly not something that could stem from the chain rule, and therefore, the graph is not valid. In fact, we can state a stronger assertion:

Valid Bayes nets are always DAGs (directed acyclic graphs). There exists a valid distribution (a valid chain rule factorization) **iff** there are no cycles in the graph.

### Conditional independence
Now, assume that we are given an acyclic graph. We'd like to find an appropriate ordering in the chain rule in order to find the distribution. A few things to note before we start:

- Every acyclic graph has at least one *source*, that is, a node that has no incoming edges
- Two random variables $X$ and $Y$ are independent if $p(X, Y) = p(X)p(Y)$
- $X$ is independent of $Y$ given $Z$ (which we denote by $X \bot Y \mid Z$) if $p(X, Y \mid Z) = p(X \mid Z) p(Y \mid Z)$
- When we talk about *path* in the following, we mean an undirected path

Let's look at some simple graphs involving three variables, which will help us clarify the concept of **D-separation**. We'll always ask the two same questions:

- Is $X_1 \bot X_2$ ?
- Is $X_1 \bot X_2 \mid X_3$ ?

These examples have names describing whether we're comparing the head (source) or tail (sink) of the graph when asking about (conditional) independence of $X_1$ and $X_2$.

#### Tail-to-tail
<figure>
    <img alt="Tail-to-tail Bayes net" src="/images/ml/bayes-net-4.svg">
    <figcaption>$X_3$ is tail-to-tail with respect to the path from $X_1$ to $X_2$</figcaption>
</figure>

$X_3$ is the source of this graph, so the factorization is:

$$
p(X_1, X_2, X_3) = p(X_3)p(X_1 \mid X_3)p(X_2 \mid X_3)
$$

Intuitively, $X_1$ and $X_2$ are not independent here, as $X_3$ influences them both; it would be easy to construct something where they are both correlated (e.g. if we let them be fully dictated by $X_3$).

To know if they are conditionally independent, let's look at the conditioned quantity $p(X_1, X_2 \mid X_3)$:

$$
\begin{align}
p(X_1, X_2 \mid X_3) 
& = \frac{p(X_1, X_2, X_3)}{p(X_3)} \\
& = \frac{p(X_3)p(X_1 \mid X_3)p(X_2 \mid X_3)}{p(X_3)} \\
& = p(X_1 \mid X_3) p(X_2 \mid X_3)
\end{align}
$$

This proves $X_1 \bot X_2 \mid X_3$.

Let's try to look at it in more general terms. We have a path between $X_1$ and $X_2$, which in general is worrisome as it may indicate some kind of relationship. But if we know what the value of $X_3$ is, then the knowledge of $X_3$ "blocks" that dependence.

#### Head-to-tail
<figure>
    <img alt="Head-to-tail Bayes net" src="/images/ml/bayes-net-5.svg">
    <figcaption>$X_3$ is head-to-tail with respect to the path from $X_1$ to $X_2$</figcaption>
</figure>

$X_1$ is the source of the graph, so the factorization is:

$$
p(X_1, X_2, X_3) = p(X_1) p(X_3 \mid X_1) p(X_2 \mid X_3)
$$

We can clearly construct a case where $X_1$ and $X_2$ are dependent (e.g. if we pick $X_1 = X_3 = X_2$). So again, $X_1$ and $X_2$ are not independent.

To know if they are conditionally independent, let's look at the conditioned quantity $p(X_1, X_2 \mid X_3)$:

$$
\begin{align}
p(X_1, X_2 \mid X_3)
& = \frac{p(X_1, X_2, X_3)}{p(X_3)} \\
& = \frac{p(X_1) p(X_3 \mid X_1) p(X_2 \mid X_3)}{p(X_3)} \\
& = \frac{p(X_1) p(X_3) p(X_1 \mid X_3) p(X_2 \mid X_3)}{p(X_1) p(X_3)} \\
& = p(X_1 \mid X_3) p(X_2 \mid X_3)
\end{align}
$$

This proves $X_1 \bot X_2 \mid X_3$. Again, conditioned on $X_3$ we block the path from $X_1$ to $X_2$.

#### Head-to-head
<figure>
    <img alt="Head-to-head Bayes net" src="/images/ml/bayes-net-6.svg">
    <figcaption>$X_3$ is head-to-head with respect to the path from $X_1$ to $X_2$</figcaption>
</figure>

Here, $X_3$ is the source of the graph, and the factorization is:

$$
p(X_1, X_2, X_3) = p(X_1) p(X_2) p(X_3 \mid X_1, X_2)
$$

In this example, $X_1$ and $X_2$ are independent. But if we condition on $X_3$, they become dependent. So contrary, to the two previous cases, conditioning on $X_3$ creates a dependence. This phenomenon is called [*explaining away*](https://www.eecs.qmul.ac.uk/~norman/BBNs/The_notion_of__explaining_away__evidence.htm).

#### D-separation
Instead of determining independence manually as we did above, we can use the two following criteria to decide on (conditional) independence graphically. We'll give a series of nested definitions that will eventually lead to the criteria. Note that these definitions talk about sets of random variables, but this also applies to single random variables (which we can consider as a set of one).

- Let $X$, $Y$ and $Z$ be sets of random variables. $X \bot Y \mid Z$ if $X$ and $Y$ are *D-separated* by $Z$.
- We say that $X$ and $Y$ are **D-separated** by $Z$ **iff** every path from any element of $X$ to any element of $Y$ is *blocked by* $Z$.
- We say that a path from node $X$ to node $Y$ is **blocked** by $Z$ **iff** it contains a variable $U$ such that either:
    + $U$ is in $Z$ and is [head-to-tail](#head-to-tail)
    + $U$ is in $Z$ and is [tail-to-tail](#tail-to-tail)
    + The node is [head-to-head](#head-to-head) and *neither* this node nor any of its *descendants* are in $Z$

**Descendant** means that there exist a *directed* path from parent to descendant.

#### Examples
Let's do lots of examples to make sure that we understand this. We'll be working on the following graph, and ask about different combinations of random variables. 

![Example of a Bayes net containing all 3 kinds of relationship](/images/ml/bayes-net-7.svg)

- Is $X_1 \bot X_3 \mid X_2$?
  
  First, let's try to understand the idea of *paths*. There is only one path between $X_1$ and $X_3$: from $X_1$ to $X_2$ to $X_3$. In general, it doesn't have to be a directed path, although this one happens to be so.

  For every such path&mdash;and in this case, there is just one, so it's easy&mdash;, we'll check if it contains is a variable that is head-tail in $Z = \set{X_2}$. This is the case, and $X_2$ is head-to-tails with respect to this path. This means that the only path is *blocked* by $X_2$, and therefore that $X_1 \bot X_3 \mid X_2$.

- Is $X_3 \bot X_1 \mid X_2$?
  
  This is the same as above, except that the independence is stated in reverse. We know that independence is commutative, and it also follows from the D-separation lemma, since paths are not directed.

- Is $X_4 \bot X_1 \mid X_2$? 
  
  There's only one path from $X_4$ to $X_1$. We'll check if it contains a variable $U\in Z = \set{X_2}$: the only node that fits this is quite trivially $U = X_2$, which is head-to-tail with respect to the path. It therefore blocks the path, and we have $X_4 \bot X_1 \mid X_2$.

- Is $X_4 \bot X_1 \mid X_3$?
  
  There's only one path from $X_4$ to $X_1$, and it doesn't contain any head-to-tail or tail-to-tail nodes in $Z$. It does however contain a head-to-head node, $X_3$. While $X_3$ has no descendants, we still have $X_3 \in Z = \set{X_3}$, and therefore, the lemma does not apply. The answer is therefore no.

- Is $X_4 \bot X_1 \mid X_3, X_2$?

  In this case, we have $Z = \set{X_2, X_3}$. There's still only one path from $X_4$ to $X_1$. We saw previously that we cannot apply the lemma with $X_3$, so let's try with $X_2$: this node is head-to-tail with respect to the path, and belongs to $Z$. Therefore, $X_2$ blocks the path, and we have a D-separation, which means that the answer is yes.

- Is $X_4 \bot X_1$?
  
  There's only one path between them, which is blocked by $X_3$ which is head-to-head, and $X_3 \notin Z = \emptyset$, and it has no descendants (so none of them are in $Z$). Therefore, the answer is yes.

### Markov blankets
Given a node $X_i$, we can ask if there is a minimal set so that every random variable outside this set is conditionally independent of $X_i$. The answer to this is the Markov blanket. 

The **Markov blanket** of $X_1$ is the set of parents, children, and co-parents of $X_i$. By co-parent, we mean other parents of the children of $X_i$.

<figure>
    <img src="/images/ml/markov-blanket.svg" alt="Example of a Markov blanket">
    <figcaption>The Markov blanket of $X_1$ is colored in gray</figcaption>
</figure>

### Sampling and marginalizing
So far we've seen how to recognize independence relationships from a Bayes net. Another possible task is to sample given a Bayes net, or to compute marginals from a Bayes net. As it turns out, these two tasks are related.

First, let's assume we know how to sample from a Bayes net. Let's assume that we have a set of $D$ binary random variables, $X_i \in \set{0, 1}$. We can then generate $N$ independent samples $\set{\vec{x}\_n}\_{n=1}^N = \set{(X\_{1n}, \dots, X\_{Dn})}\_{n=1}^N$. To get the marginal for $X\_i$, we estimate $\expect{X\_i}$ by computing the empirical quantity $\frac{1}{N}\sum\_{n=1}^N x\_{in}$. As $N\rightarrow\infty$, we know that this converges to the true mean.

Conversely, assume we know how to efficiently compute marginals from any Bayes net, and that we'd like to sample from the joint distribution. We can then compute the marginal of the net with respect to a certain variable $X_i$, and then flip a coin according to the marginal probability we've computed.

The problem is that neither of these can be done efficiently, except for some special cases. The chain rule tells us that $X_i$ is conditioned on $X_1, \dots, X_{i-1}$, which means we'd need to have a table of $2^{i-1}$ conditional probabilities. In general, the storage requirement is exponential in the largest number of parents any node in the Bayes net has.

### Factor graphs
Assume we have a function $f$ that can be factorized as follows:

$$
f(X_1, X_2, X_3, X_4) = f_a(X_1) f_b(X_2, X_3) f_c(X_3, X_4)
$$

A very natural representation is another graphical representation. Each variable $X_i$ gets a node, and each factor $f_j$ gets a factor node.

![Factor graph of the above function](/images/ml/factor-graph.svg)

If the factor graph is a bipartite tree (i.e. no cycles), then we can marginalize very efficiently with a [message-passing algorithm](https://en.wikipedia.org/wiki/Factor_graph#Message_passing_on_factor_graphs), which runs in linear time in the number of edges, instead of exponential complexity in the size of the network.

Sadly, very few probability distributions do us the favor of producing a tree in the factor graph. But it turns out that there many probability distributions where the factorization's terms are fairly small, and despite cycles in the graph, we can still run the algorithm and it works approximately.
