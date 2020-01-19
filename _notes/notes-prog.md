---
title: CS-108 Pratique de la programmation orientée-objet
description: "Mes notes de CS-108 pendant le semestre de printemps 2015 à l'EPFL."
date: 2015-02-16
image: /images/hero/interlaken.jpg
fallback-color: "#9ea98f"
course: CS-108
---

* TOC
{:toc}

<!-- More --> 

# [Le projet Imhof](http://cs108.epfl.ch/archive/15/p00_intro.html)

Le but du projet de cette année est de dessiner des cartes topographiques au 1:50'000 dont le style s'inspire de celui des cartes suisses. Ce projet est nommé Imhof en l'honneur d'[Eduard Imhof](http://en.wikipedia.org/wiki/Eduard_Imhof) (1895–1986), cartographe suisse célèbre — entre autres — pour ses magnifiques cartes en relief.

[Voir slides](http://cs108.epfl.ch/archive/15/files/ppo15_01a_intro-cours-projet.pdf) pour un aperçu rapide du projet et de ses règles.

## Rendu du projet
Le rendu se fera [sur cette page](http://cs108.epfl.ch/archive/15/submit.html); le jeton a été envoyé par e-mail.

# [Test unitaire](http://cs108.epfl.ch/archive/15/files/ppo15_01b_test-unitaire.pdf)
Le test unitaire est un petit programme qui vérifie automatiquement que les classes se comportent comme on veut. Cela permet de rapidement détecter d'éventuels problèmes dans les petites parties isolées du programme.

La bibliothèque utilisée dans le cadre de ce cours est JUnit.


## Utilisation de JUnit
Pour utiliser JUnit, on doit marquer sa méthode avec la notation `@Test`.

{% highlight java linenos %}
@Test
public void addition() {
    assertEquals(2, 1 + 1);
}
{% endhighlight %}

Ci-dessous des exemples des méthodes de JUnit.

<!-- More -->

- `assertTrue(boolean b)` vérifie que `b` est vrai
- `assertNull(Object o)` vérifie que `o` est nul
- `assertEquals(Object e, Object a)` vérifie que `a` est égal à `e` au moyen de la méthode `equals`
- `assertEquals(long e, long a)` vérifie que `e` et `a` sont égaux
- `assertEquals(double e, double a, double d)` vérifie que la différence entre `e` et `a` est inférieure à `d`
- etc.

**Le premier argument est la valeur attendue, la seconde est la valeur obtenue.** Lors de la rédaction de tests pour une unité, il y a trois types principaux de tests auxquels il convient de penser :

- Les tests de **cas d'erreur**, qui vérifient que les erreurs qui
doivent être signalées le sont bien, p.ex. lorsqu'un argument invalide est fourni
- Les tests de **cas aux limites**, qui vérifient que l'unité se comporte bien dans les situations délicates, p.ex. qu'une méthode qui accepte un tableau de taille quelconque fonctionne correctement s'il est vide
- Les tests de **cas normaux**, qui vérifient que l'unité se comporte bien dans les situations « normales ».

**Attention**: Passer les tests ne signifie pas que le code est correct!

> Program testing can be used to show the presence of bugs, but never to show their absence!
>
> [Edsger Dijkstra](https://en.wikiquote.org/wiki/Edsger_W._Dijkstra#1970s)

### Exemple d'un test JUnit
{% highlight java linenos %}
import org.junit.Test;
import static org.junit.Assert.*;

public class SortTest {
    @Test
    public void sortsEmptyArray() {
        int[] a1 = new int[0];
        int[] a2 = new int[0];
        sort(a2);
        assertArrayEquals(a1, a2);
    }

    boolean isSorted(int[] array) {
        for (int i = 1; i < array.length; ++i)
        if (array[i] < array[i - 1])
        return false;
        return true;
    }

    @Test
    public void sortsNontrivialArray() {
        int[] a = new int[]{ 4,3,6,1,5,6,4,-1 };
        sort(a);
        assertTrue(isSorted(a));
    }
}
{% endhighlight %}

# [Immuabilité](http://cs108.epfl.ch/archive/15/files/ppo15_01c_immuabilite.pdf)

## Exemple

On crée ci-dessous les classes Date et Person de façon assez classique, avec des getters et des setters.

{% highlight java linenos %}
public final class Date {
    private int y, m, d;
    public Date(int y, int m, int d) {
        // La vérification des arguments est omise
        this.y = y;
        this.m = m;
        this.d = d;
    }
    
    public int year() {
        return y;
    }
    
    public void setYear(int y2) {
        this.y = y2;
    }
    
    // … idem pour month/setMonth, day/setDay
    
    @Override
    public String toString() {
        return y + "-" + m + "-" + d;
    }
}

public final class Person {
    private final String name;
    private final Date bdate;
    public Person(String name, Date bdate) {
        this.name = name;
        this.bdate = bdate;
    }

    public String name() {
        return name;
    }
    
    public Date birthdate() {
        return bdate;
    }
}
{% endhighlight %}

Ayant écrit ces classes, on peut les utiliser dans un petit programme qui sauvegarde la date de naissance de deux informaticiens célèbres nés le même jour.

{% highlight java linenos %}
Date d = new Date(1903, 12, 28);
Person j = new Person("John Von Neumann",d);
d.setYear(1969);
Person l = new Person("Linus Torvalds", d);
System.out.println(j.name() + " est né le " + j.birthdate());
System.out.println(l.name() + " est né le " + l.birthdate());
{% endhighlight %}

L'intention est de changer la date de naissance de Linus Torvalds uniquement, mais le programme affiche que les deux sont nés en 1969! Le fait d'avoir changé l'objet `Date d` a effectué un changement pour les deux personnes, pas uniquement pour Torvalds, ce qui peut être une faille de sécurité, mais aussi une complication pour ceux qui souhaitent utiliser les classes que l'on a créé.

Pour se protéger de ce problème, il faudrait faire une copie défensive.

Tout cela commence dans le constructeur de `Date`. On doit pouvoir copier la date vers un nouvel objet dont tous les champs sont identiques mais dont la référence est différente. Pour ce faire, on écrit un constructeur de copie dans `Date`: 

{% highlight java linenos %}
public final class Date {
    // … comme avant
    public Date(Date that) {
        this(that.y, that.m, that.d);
    }
}
{% endhighlight %}

On effectue ensuite un second changement dans le constructeur de `Person` pour avoir:

{% highlight java linenos %}
public final class Person {
    // … comme avant
    public Person(String name, Date bdate) {
        this.name = name;
        this.bdate = new Date(bdate); // copie au lieu de l'original!
    }
} 
{% endhighlight %}

et dans le getter de `Person`:

{% highlight java linenos %}
public final class Person {
    // … comme avant
    public Date birthdate() {
        return new Date(birthdate); // copie au lieu de l'original!
    }
}
{% endhighlight %}

### Quelques autres types de variables
- On n'a pas besoin de protéger la variable `name` car les variables de type  `String` sont **immuables**. 
- Les tableaux, quant à eux, son **non-immuables**, donc il faut avoir recourt aux copies défensives. 
- Les tableaux dynamiques `ArrayList<>` sont **non-modifiables** si ils sont *"enrobés"* dans `Collections.unmodifiableList();`:

{% highlight java linenos %}
ArrayList<String> m = new ArrayList<>();
m.add("un");
m.add("deux");
m.add("trois");
List<String> u = Collections.unmodifiableList(m);
u.add("quatre"); // lève l'exception UOE
{% endhighlight %}

Ici, `u` est un objet par lequel on passe pour accéder à `m`, et qui bloque les changements en levant une exception. C'est ce qu'on appelle une *vue* (*a view*)

**Note:** La méthode `unmodifiableList` de la classe `java.util.Collections` permet d'obtenir une version non modifiable d'un tableau dynamique, dont toutes les méthodes de modification lèvent l'exception `UnsupportedOperationException` (abrégée UOE). Quiconque qui ait accès à la variable `m` peut cependent encore modifier l'`ArrayList`. C'est pourquoi on parle de liste **non-modifiable** plutôt qu'**immuable** (c'est le mieux qu'on puisse faire pour les tableaux).

## Règle de l'immuabilité
> Dans la mesure du possible, écrivez des classes immuables.

## Inconvénients de l'immuabilité
- Si on change beacoup de variables, le fait de recréer un gros objet à chaque changement alourdit beacoup le programme.
- Parfois, on veut qu'une modification à un endroit soit prise en compte à un autre, ce qui devient lourd à écrire.

## Terminologie
- Une classe est immuable si ses instances ne peuvent pas changer d'état une fois créées.
- Une classe est non modifiable si un morceau de code ayant accès à l'une de ses instances n'a pas la possibilité d'appeler des méthodes modifiant son état.

**Attention** : même si une classe immuable n'est jamais modifiable, l'inverse n'est pas forcément vrai

## Pour faire une classe immuable
1. Tous les champs doivent être déclarés en `final`, initialisés lors de la construction, et jamais modifiées par la suite.
2. Toute valeur non immuable fournie à son constructeur doit être copiée en profondeur avant d'être stockée dans un des champs.
3. Aucune valeur non immuable stockée dans un des champs ne doit être fournie de l'extérieur (soit la rendre non modifiable au préalable, soit fournir une copie profonde).


## Tableaux et immuabilité
1. Les tableaux reçus à la construction sont copiés défensivement, rendus non modifiables par unmodifiableList puis stockés ainsi dans des champs.
2. Ces tableaux non modifiables sont directement retournés par les méthodes d'accès 

# [Bâtisseurs](http://cs108.epfl.ch/archive/15/files/ppo15_01c_immuabilite.pdf)
Un défaut de l'immuabilité est qu'il devient difficile de construire des classes immuables (du fait de la finalité de ses champs). Il faut le faire d'un seul coup, et trouver soi-même une façon de stocker les données entre temps...

C'est pourquoi on a des bâtisseurs.

## Exemple
{% highlight java linenos %}
public final class DateBuilder {
    private int y, m, d;
    public DateBuilder(int y, int m, int d) {
        this.y = y; this.m = m; this.d = d;
    }
    public int year() {
        return y;
    }
    public void setYear(int y2) {
        y = y2;
    }
    // … idem pour month/setMonth et day/setDay
    public Date build() {
        return new Date(y, m, d);
    }
}
{% endhighlight %}

La méthode `.build()` construit et retourne l'objet créé.

## Appels chaînés
Plûtot que de retourner un `void`, les setters peuvent retourner le constructeur lui-même, c'est-à-dire `this`. On peut alors chaîner les appels:

{% highlight java linenos %}
Date d = new Date.Builder(1903, 12, 28)
    .setYear(1969)
    .build(); // 1969-12-28
{% endhighlight %}


## Règle du bâtisseur
>S'il peut être utile de construire par étapes des instances d'une classe immuable, attachez-lui un bâtisseur

En plus de cela (par convention):

- Appeler la classe bâtisseur `Builder`
- L'imbriquer statiquement dans la classe dont elle bâtit les instances
- Nommer sa classe de construction `build`
- Retourner `this` pour les méthodes de modification (voir [appels chaînés](#appels-chaînés))

# Classes imbriquées statiques
On met les builders dans les classes qu'elles instantient (parce qu'un builder n'a pas de raison d'être sans).

{% highlight java linenos %}
public final class Date {
    // …
    public final static class Builder {
        // …
    }
}
{% endhighlight %}

Une classe imbriquée statique a accès aux membres privés **statiques** de sa classe englobante, et peut être déclarée privée (`private`) ou protégée (`protected`).

# [Généricité](http://cs108.epfl.ch/archive/15/files/ppo15_02_genericite.pdf)
Admettons que l'on désire écrire une classe très simplemodélisant ce que nous appellerons une cellule(immuable), dont le but est de stocker un — et un seul — objet.

Intuitivement, on utiliserait alors le type `Object` pour que la cellule fonctionne avec tous les types d'objets.

{% highlight java linenos %}
final class ObjectCell {
    private final Object o;
    public ObjectCell(Object o) {
        this.o = o;
    }
    public Object get() {
        return o;
    }
} 
{% endhighlight %}

Cela peut demander un grand nombre de transtypage à son utilisation, car la classe retourne un type `Object`.

Introduit dans Java 5, la notion de généricité (*genericity*), aussi appelée polymorphisme paramétrique (*parametric polymorphism*), résoud ce problème.

{% highlight java linenos %}
final class Cell<E> {
    private final E e;
    public Cell(E e) {
        this.e = e;
    }
    public E get() { 
        return e;
    }
}
{% endhighlight %}

Ceci est une classe **générique**. On utilise le **paramètre de type** `E`.

## Utilisation

En pratique, on peut remplacer le paramètre `e` par le type d'objet que l'on veut utiliser:

{% highlight java linenos %}
Cell<Object> a = new Cell<Object>;
Cell<String> b = new Cell<String>;
Cell<Cell<String>> c = new Cell<Cell<String>>;

Cell<String> o = new Cell<String>("hello");
char c = o.get().charAt(0); // Aucun probleme avec la généricité

Cell<String> o = new Cell<>("hello"); // Le type est inféré par Java. Permis depuis Java 7
{% endhighlight %}

## Paires
Si on veut utiliser plus d'un type dans une classe générique:

{% highlight java linenos %}
final class Pair<F,S> {
    private F f;
    private S s;
    public Pair(F f, S s) { this.f = f; … }
    public F getF() { return f; }
    public S getS() { return s; }
}
{% endhighlight %}

Si on veut utiliser plus d'un type dans les méthodes d'une classe générique:

{% highlight java linenos %}
final class Cell<E> {
    private final E e;
    // … comme avant
    public <S> Pair<E, S> pairWith(S s) {
        return new Pair<>(e, s);
    }
}

// Utilisation de cette classe:
Cell<String> c = new Cell<>("hello");
Pair<String, Integer> p = c.pairWith(12);

// On l'écrit ainsi uniquement si le compilateur n'arrive pas à inférer le type
Pair<String, Integer> p = c.<Integer>pairWith(12);
{% endhighlight %}

## [Généricité et types de base](http://cs108.epfl.ch/archive/15/files/ppo15_02_genericite.pdf)

### Emballage & déballage
Jusqu'à présent, on ne pouvait qu'utiliser la généricité avec des types évolués. La solution est celle de *l'emballage*, c'est-à-dire utiliser les types évolués correspondant aux types de base. Il est aussi possible de déballer.

{% highlight java linenos %}
Cell<Integer> c = new Cell<>(new Integer(1));
int succ = c.get().intValue() + 1; 
{% endhighlight %}

Le compilateur Java peut le faire à la place du programmeur; c'est ce qu'on appelle le *déballage automatique* (*autoboxing*).

{% highlight java linenos %}
Cell<Integer> c = new Cell<>(1);
int succ = c.get() + 1;
{% endhighlight %}

### [Limitations de la généricité en Java](http://cs108.epfl.ch/archive/15/files/ppo15_02_genericite.pdf)

Pour des raisons historiques, la généricité en Java possède
les limitations suivantes:

- La création de tableaux dont les éléments ont un type générique est interdite
- Les tests d'instance impliquant des types génériques sont interdits
- Les transtypages (casts) sur des types génériques ne sont pas sûrs, c-à-d qu'ils produisent un avertissement lors de la compilation et un résultat éventuellement incorrect à l'exécution
- La définition d'exceptions génériques est interdite

Sont alors interdits:

{% highlight java linenos %}
static <T> T[] newArray(T x) {
    return new T[]{ x }; // interdit
}

<T> int printIfStringCell(Cell<T> c) {
    if (c instanceof Cell<String>) // interdit
    System.out.println(c);
} 

Cell<Integer> c = new Cell<>(1);
Object o = c;
Cell<String> c2 = (Cell<String>)o; 

class BadException<T> // interdit
    extends Exception {}
{% endhighlight %}

# [Collections](http://cs108.epfl.ch/archive/15/files/ppo15_03_listes.pdf)

Une collection est un objet contenant d'autres objets. Nous étudierons ici:

1. Les **listes** (*lists*), collection ordonnée pour laquelle un élément donné peut apparaître plusieurs fois.
2. Les **ensembles** (*sets*), collection non ordonnée dans laquelle un élément donné peut apparaître au plus une fois.
3. Les **tables associatives** (*maps*) ou **dictionnaires** (*dictionaries*), collection associant des valeurs à des clef. 

## Collections dans l'API Java
L'API Java fournit un certain nombre de collections (*Java Collections Framework (JCF)*). Son contenu est dans `java.util`.

![Graphe d'héritanche des collections dans l'API Java](/images/notes-prog/heritance-collections.png)

## Règle des collections

> Program to an interface, not an implementation.

En dehors des énoncés new, il faut toujours utiliser les interfaces (List, Set, Map, etc.) plutôt que les mises en œuvre (ArrayList, LinkedList, etc.).


{% highlight java linenos %}
List<String> l = new ArrayList<>(); // oui
ArrayList<String> l = new ArrayList<>(); // non
{% endhighlight %}

## L'interface `Collection` (sans `s`)

`Collection` est la super-interface commune à `List` et `Set`. C'est une interface générique.

### Méthodes importantes de `Collection`

#### Méthodes de consultation

- `boolean isEmpty()`: retourne vrai ssi la collection est vide.
- `int size()`: retourne le nombre d'éléments contenus dans la collection.
- `boolean contains(Object e)`: retourne vrai ssi la collection contient l'élément donné. Le type de l'argument est malheureusement Object et non pas E pour des raisons historiques.
- `boolean containsAll(Collection<E> c)` : retourne vrai ssi la collection contient tous les éléments
de la collection donnée.

#### Méthodes d'ajout

- `boolean add(E e)`: ajoute l'élément donné à la collection, et retourne vrai ssi la collection a été modifiée
- `boolean addAll(Collection<E> c)`: ajoute à la collection tous les éléments de la collection donnée, et retourne vrai ssi la collection a été modifiée

#### Méthodes de suppression

- `void clear()`: supprime tous les éléments de la collection
- `boolean remove(E e)`: supprime l'élément donné, s'il se trouve dans la collection
- `boolean removeAll(Collection<E> c)`: supprime tous les éléments de la collection donnée
- `boolean retainAll(Collection<E> c)`: supprime tous les éléments qui ne se trouvent pas dans la collection donnée

## Listes

![Graphe d'héritance des listes dans l'API Java](/images/notes-prog/heritance-listes.png)

Listes et tableaux sont très similaires, mais la principale différence est:

- **Taille**: Fixe pour les tableaux, variable pour les listes
- **Accès**: Aléatoire O(1) pour les tableaux, séquentiel O(n) pour les listes

Les listes ajoutent les méthodes suivantes:

- `E get(int i)`
- `int indexOf(E e)`
- `int lastIndexOf(E e)`
- `void add(int i, E e)`
- `boolean addAll(int i, Collection<E> c) `
- `E remove(int i)`
- `E set(int i, E e)`
- `List<E> subList(int b, int e)`

La méthode `subList(int b, int e)` retourne une vue sur la sous-liste entre `b` (inclus) et `e` (exclusif).

La classe `Collections` offre également des méthodes pour les listes:

- `<T> void sort(List<T> l)`
- `<T> void shuffle(List<T> l)`
- `<T> List<T> asList(T... a)` (nbre variable d'éléments dans une liste immuable)
- `<T> List<T> emptyList()` (liste vide immuable)
- `<T> List<T> singletonList(T e)` (liste immuable de longueur 1)
- `<T> List<T> nCopies(int n, T e)` (liste immuable de longueur `n` contenant uniquement `e`)

### Règle des listes immuables

>Pour obtenir une liste immuable à partir d'une liste quelconque, obtenez une vue non modifiable d'une copie de cette liste.  

{% highlight java linenos %}
List<…> immutableList = Collections.unmodifiableList(new ArrayList<>(list));
{% endhighlight %}

### Complexité des listes

#### `ArrayList`

- **Accès**: O(1)
- **Insertion**: O(n)

#### `LinkedList`

- **Accès**: O(n)
- **Insertion**: O(1)

## Piles, Deques & Queues

![Différence entre pile, deque et queue](/images/notes-prog/piles-deques-queues.png)

Voir [les slides](http://cs108.epfl.ch/archive/15/files/ppo15_03_listes.pdf) pour la liste des méthodes implémentées par l'interface `Queue`.

### Règle des listes

>Pour représenter une pile, une queue ou un « deque », utilisez ArrayDeque. Pour représenter une liste dans toute sa généralité, utilisez ArrayList si les opérations d'indexation (get, set) dominent, sinon LinkedList.

**Note:** ArrayList peut également s'utiliser comme une pile, pour peu que les ajouts/suppressions se fassent toujours à la fin de la liste et pas au début.

# Itérateurs - parcours d'une collection

Pour les `LinkedList`, une boucle `for` contenant un `.get(i)` est une mauvaise idée parce que l'accès se fait en O(n). On utilise alors une boucle for-each avec un itérateur.

{% highlight java linenos %}
List<String> l = …;
Iterator<String> i = l.iterator();
while (i.hasNext()) {
    String s = i.next();
    System.out.println(s);
}
{% endhighlight %}

L'interface `Iterator` a 3 méthodes:

- `boolean hasNext()`
- `E next()`
- `void remove()`

# [Tables Associatives](http://cs108.epfl.ch/archive/15/files/ppo15_04_tables-associatives.pdf)
Une collection qui associe des **valeurs** à des **clés**.

![Graphe d'héritance des Maps dans l'API Java](/images/notes-prog/heritance-map.png)

## Règle des tables immuables

>Pour obtenir une table associative immuable à partir d'une table associative quelconque, obtenez une vue non modifiable d'une copie de cette table.

**Exemple**:

{% highlight java linenos %}
Map<…> immutableMap = Collections.unmodifiableMap(new HashMap<>(map));
{% endhighlight %}

Dans une map, l'ordre d'itération est souvent aléatoire, et peut donc varier entre deux exécutions.

**Exemple d'utilisation**: 

{% highlight java linenos %}
Map<String, String> s = new HashMap<>();
s.put("printemps", "spring");
s.put("été", "summer");
s.put("automne", "autumn");
s.put("hiver", "winter");

for (Map.Entry<String,String> e: s.entrySet())
    System.out.println("En anglais, " + e.getKey() + " se dit " + e.getValue();
{% endhighlight %}

## `HashMap`
Une fonction de hachage prend une donnée et retourne un entier dans un intervalle borné (un hash value, ou *valeur de hachage*). On peut ensuite prendre cette valeur modulo `n`, et ensuite aller chercher dans la `hash mod n`<sup>ieme</sup> liste. C'est ce qui se fait de mieux en termes de tables associatives, et les `HashMap` sont par conséquent plus utilisées.

![Fonctionnement d'une HashMap](/images/notes-prog/hashmap.png)

- **Fonction de hachage**: O(1)
- **Insertion**: O(1)
- **Recherche**: O(1)


## `TreeMap`
Elle est organisée comme ceci: 

![Organisation d'une TreeMap](/images/notes-prog/treemap.png)

Les éléments plus petits sont à gauche, plus grands à droite. La recherche est donc assez simple, puisqu'il s'agit d'une série de comparaisons.

## Règle `HashMap` / `TreeMap`

>Utilisez HashMap comme mise en œuvre des tables associatives en Java, sauf lorsqu'il est utile de parcourir les clefs en ordre croissant, auquel cas vous pourrez leur préférer TreeMap.

## Egalité des clés
Pour une table associative, il est important de pouvoir comparer la clé donnée à celle qui est stockée. Pour ce faire, deux formes d'identité existent:

1. **Egalité par référence**: deux objets sont égaux ssi il s'agit du même objet. On utilise `==`.
2. **Egalité par structure**: deux objets sont égaux ssi leurs champs ont la même valeur. On utilise le `.equals()`.


### Egalité et immuabilité
Lors d'une redéfinition de equals, il est important de s'assurer que celle-ci est stable, dans le sens où deux objets considérés comme égaux à un instant donné le sont aussi à n'importe quel instant futur. Le seul moyen de garantir qu'une mise en œuvre de equals soit stable est qu'elle ne se base que sur des attributs immuables de la classe.

### Règle de `equals`
>Toute redéfinition de equals ne doit se baser que sur des attributs immuables de la classe.

### Règle de `hashCode`
>Si vous redéfinissez hashCode dans une classe, redéfinissez également equals — et inversement — afin que ces deux méthodes restent compatibles. 

et

>Lorsque vous redéfinissez hashCode, utilisez la méthode statique hash de la classe Objects pour la mettre en œuvre, en lui passant tous les attributs à hacher

L'écriture de fonctions de hachage de qualité étant très difficile, il est préférable de laisser cette tâche à des spécialistes. Heureusement, depuis peu la bibliothèque Java offre dans la classe Objects une méthode statique permettant de calculer une valeur de hachage pour une combinaison arbitraire d'objets :

{% highlight java linenos %}
public int hashCode() {
    return Objects.hash(firstName, lastName, birthDate);
}
{% endhighlight %}

# Ordre en Java
La possibilité d'ordonner les valeurs d'un type donné n'est pas prédéfinie en Java. Au lieu de cela, deux interfaces sont fournies pour ordonner des valeurs d'un type donné. L'une permet aux valeurs de se comparer elle-mêmes, tandis que l'autre permet à un objet externe de comparer deux valeurs

## L'interface `Comparable`
L'interface `Comparable` peut être implémentée par toute classe dont les instances sont comparables entre elles. Elle contient une seule méthode qui compare deux objets. 

{% highlight java linenos %}
public interface Comparable<T> {
    int compareTo(T that);
} 
{% endhighlight %}

La méthode `compareTo` retourne un entier négatif si  l'objet auquel on l'applique est inférieur à l'argument, nul si les deux sont égaux, et positif dans les autres cas.

On peut l'implémenter de la façon suivante (le type de comparaison est défini par le type donné en argument):

{% highlight java linenos %}
public interface Comparable<T> {
    int compareTo(T that);
} 
{% endhighlight %}

### Exemples

- `"le".compareTo("la")` retourne un entier positif
- `"le".compareTo("le")` retourne zéro
- `"mont".compareTo("montagne")` retourne un entier
négatif

### Règle de `Comparable`
Lorsque vous définissez une classe qui implémente l'interface `Comparable`, assurez-vous que sa méthode `compareTo` soit compatible avec sa méthode `equals`.

## L'interface `Comparator`
Cette interface décrit un comparateur, un objet capable de comparer deux objets.

{% highlight java linenos %}
public interface Comparator<T> {
    int compare(T o1, T o2);
}
{% endhighlight %}

La méthode compare doit retourner un entier négatif si le premier objet est  inférieur au second, nul si les deux sont égaux et positif dans les autres cas.


### Différence entre `Comparator` et `Comparable`
Voir le code ci-dessous: la première variante ne prend qu'un seul argument — la liste à trier — et la trie selon l'ordre naturel de ses éléments, qui doivent donc en posséder un (voir page suivante) : 

{% highlight java linenos %}
<T> void sort(List<T> l)
{% endhighlight %}

La seconde variante prend deux arguments — la liste à trier et un comparateur  et la trie selon l'ordre du comparateur : 

{% highlight java linenos %}
<T> void sort(List<T> l, Comparator<T> c)
{% endhighlight %}

Cette variante est utilisable que les éléments aient un ordre naturel ou pas, car seul le comparateur est utilisé !


## Règle des ensembles immuables
>Pour obtenir un ensemble immuable à partir d'un ensemble quelconque, obtenez une vue non modifiable d'une copie de cet ensemble. 

**Note**: *Je ne prendrai pas de notes. Le tout est assez simple et bien expliqué dans les slides*.

## `ListSet`
- **Insertion**: O(n) (parce qu'il faut tout parcourir pour éviter les doublons)
- **Recherche**: O(n)

## `HashSet`
- **Hachage**: O(1)
- **Insertion**: O(1)
- **Recherche**: O(1)

## `TreeSet`
- **Insertion**: O(log(n))
- **Recherche**: O(log(n))

*La classe `TreeSet` est surtout intéressante dans le cas où il est important de pouvoir parcourir les éléments dans l'ordre.*


## Règle `HashSet`/`TreeSet`
> Utilisez HashSet comme mise en œuvre des ensembles en Java, sauf lorsqu'il est utile de parcourir les éléments en ordre croissant, auquel cas vous pourrez préférer TreeSet


## Enumérations
Exemple ci-dessous.

{% highlight java linenos %}
public final class Card {
    public enum Suit {
        SPADES, DIAMONDS, CLUBS, HEARTS
    }
    public String frenchSuitName() {
        switch (suit) {
            case SPADES: return "piques";
            case DIAMONDS: return "carreaux";
            case CLUBS: return "trèfles";
            case HEARTS: return "cœurs";
            default: throw new Error();
        }
    }
}
{% endhighlight %}


# [Input/Output](http://cs108.epfl.ch/archive/15/files/ppo15_06_entrees-sorties.pdf)

Deux paquetages Java: `java.io` et `java.nio`.  
Dans `java.io`, l'abstraction de base est le **flot** (*stream*); dans `java.nio`, c'est surtout la **mémoire tampon** (*buffer*). Nous nous intéresserons aux flots.

Les flots d'octets sont les *streams*, alors que les flots de caractères sont les *readers* ou *writers*.

## `InputStream`

Il y a 3 variantes de la méthode `read`:

- `int read()`: lit et retourne le prochain octet sous la forme d'une valeur comprise entre 0 et 255 inclus, ou -1 si la fin a été atteinte.
- `int read(byte[] b, int o, int l)`:  lit au plus `l` octets du flot, les place dans le tableau `b` à partir de la position `o` et retourne le nombre d'octets lus
- `int read(byte[] b)` équivalent à `read(b, 0, b.length)`

La classe offre aussi une méthode `skip`:

- `long skip(long n)`:  ignore au plus `n` octets du flot et retourne le nombre d'octets ignorés

Ces deux méthodes sont **bloquantes** (*blocking*), càd si le flot est plus lent que le programme, alors le programme est bloqué jusqu'à ce que le prochain byte soit disponible. C'est un problème pour la performance et/ou l'interactivité du programme: d'où le paquet `java.nio`, qui donne des méthodes non-bloquantes. Entre temps, `java.io` offre tout de même la méthode suivante:

- `int available()`: retourne une estimation du nombre d'octets qu'il est possible de lire ou d'ignorer sans bloquer. 


On peut fermer le flot quand on a terminé (utile pour l'optimisation).

- `void close()`: ferme le flot, libérant ainsi les éventuelles resources associées et rendant par là même le flot inutilisable.

### Octets `int` ou `byte`

`byte` stocke un entier entre -128 et +127, et il y a pour cela deux variantes de la méthode `read`:

- Celle qui retourne le prochain octet comme un `int` entre 0 et 255, et -1 signifie la fin.
- Celle qui retourne un octet comme un `byte[]` (entre -128 et +127), et -1 est une valeur valide.

### Sous-classes de `InputStream`

On peut soit avoir un flot d'entrée primaire (=brut), ou alors un flot d'entrée filtrant, dont les données proviennent d'un **flot sous-jacent**
(*underlying stream*). Exemples ci-dessous:

- `FileInputStream`: primaire
- `ByteArrayInputStream`: primaire, octets proviennent d'un `byte[]`
- `BufferedInputStream`: filtrant (qui ne filtre rien: rajoute juste une mémoire tampon)
- `GZIPInputStream`: filtrant (décompresse à la volée)

### Sous-classes de `OutputStream`

Comme `InputStream`, il y a deux sortes de sorties: primaires et filtrantes. Offre une méthode `write`:

- `void write(int b)`: écrit l'octet `b` — compris entre 0 et 255 — dans le flot, 
- `void write(byte[] b, int o, int l)`: écrit les `l` octets obtenus du tableau `b` à partir de la position `o` dans le flot
- `void write(byte[] b)`: équivalent à `write(b, 0, b.length)`

Il y a aussi `close` (comme pour l'input), et une méthode `flush`:

- `void flush()` force les données du flot à être écrites effectivement, p.ex. sur le disque ou sur la console


### Exemple

{% highlight java linenos %}
InputStream s = new GZIPInputStream(new BufferedInputStream(new FileInputStream("in.gz")));
int b, c = 0;
while ((b = s.read()) != -1) {
    if (b == 0)
    c += 1;
}
s.close();
System.out.println(c);
{% endhighlight %}

## Resources
Les objets liés à une resource du système et quoi doivent être fermés en fin d'utilisations (comme les flots, par exemple).

### Try-with-resource

Depuis peu, on a des blocs try qui marchent avec des resources, qui "close" en cas d'exception.

{% highlight java linenos %}
try (InputStream i = new FileInputStream("in.bin");
     OutputStream o = new FileOutputStream("out.bin")) {
    // … code utilisant les flots i et o
} catch (IOException e) {
    // … code gérant l'exception
} finally {
    System.out.println("done!");
}
{% endhighlight %}

Pour pouvoir être utilisée dans un énoncé try-with-resource, une valeur doit implémenter l'interface AutoCloseable du paquetage java.lang, définie ainsi :


{% highlight java linenos %}
public interface AutoCloseable {
    void close();
}
{% endhighlight %}

## Représentation de caractères

### ASCII

*American Standard Code for Information Interchange*: représente un caractère par un entier de 7 bits, donc 2<sup>7</sup> = 128 caractères différents. Inclut toutes les lettres non accentuées de l'alphabet anglais.

#### Extensions d'ASCII
De nombreuses extensions d'ASCII à 8 bits ont donc été inventées, utilisant la plage des valeurs de 128 à 255 pour ces caractères manquants.

Par exemple, on peut maintenant écire les € et les œ.

- **ISO 8859–1**, ou ISO latin 1, malheureusement incapable de représenter les caractères €, œ ou Œ
- **ISO 8859–15**, variante de 8859–1 résolvant ce problème
- **Mac Roman**, utilisé sur Mac OS
- **Windows 1252**, variante de ISO 8859–1 utilisée sur
Windows

Heureusement, Unicode est un standard à but universel, et offre plus d'un million de caractères. **UTF-8** et **UTF-16** sont à longueur variable, alors qu'**UTF-32** est à longueur fixe (le chiffre donne la longueur minimale de la longueur d'un caractère en bits).

## Readers / Writers: lecture textuelle

`Reader` et `Writer` sont des classes abstraites:

{% highlight java linenos %}
abstract public class Reader {
    void close();
    int read();
    int read(char[] c, int o, int l);
    int read(char[] c);
    long skip(long n);
    boolean ready();
    boolean markSupported();
    void mark(l);
    void reset();
}

abstract public class Writer {
    void write(int c);
    void write(char[] a);
    void write(char[] a, int o, int l);
    void write(String s);
    Writer append(char c);
    Writer append(CharSequence c);
    Writer append(CharSequence c, int s, int e);
    void flush();
    void close();
}
{% endhighlight %}

### Quelques détails d'implémentation

#### Terminaison des lignes
Il existe plusieurs types de fin de lignes:

1. CR (retour de chariot)
2. LF (saut de ligne)
3. CR puis LF

Avec les writers, il est donc sage d'utiliser l'appel suivant: `System.getProperty("line.separator");`

#### Encodage
Ci-dessous un programme qui fait la conversion d'UTF-8 en UTF-16:

{% highlight java linenos %}
try (Reader i = new InputStreamReader(new FileInputStream(fi), StandardCharsets.UTF_16);
     Writer o = new OutputStreamWriter(new FileOutputStream(fo),StandardCharsets.UTF_8)) {
    int c;
    while ((c = i.read()) != -1)
    o.write(c);
}
{% endhighlight %}

# [Fonctions anonymes (lambdas)](http://cs108.epfl.ch/archive/15/files/ppo15_07_fonctions.pdf)

Voici comment on trierait une liste par ordre lexiquographique inverse avec une fonction anonyme


{% highlight java linenos %}
public static void sortInv(List<String> l) {
    Collections.sort(l, new Comparator<String>() {
       @Override
       public int compare(String s1, String s2) {
          return s2.compareTo(s1);
       }
    });
} 
{% endhighlight %}

Mais depuis Java 8, cette syntaxe équivalente est correcte:

{% highlight java linenos %}
public static void sortInv(List<String> l) {
    Collections.sort(l, (String s1, String s2) -> {
        return s2.compareTo(s1);
    });
}
{% endhighlight %}

C'est ce qu'on appelle une **fonction anonyme** ou une **lambda expression**.

Mais ce n'est pas fini!! On peut encore simplifier, puisque:

- Le type des paramètres est optionnel car inféré
- Si le corps de la fonction est composé d'une seule expression, elle peut être écrite telle quelle, sans accolades englobantes ni `return`. 


{% highlight java linenos %}
public static void sortInv(List<String> l) {
    Collections.sort(l, (s1, s2) -> s2.compareTo(s1));
}
{% endhighlight %}

## Interface fonctionnelle
Une **interface fonctionnelle** (*functional interface*) ne possède qu'une seule méthode abstraite. `Comparator` est alors une interface fonctionnelle puisqu'elle ne contient que la méthode `compare`.

## Fonction anonyme
Une **lambda expression** est une expression créant une instance d'une classe anonyme qui implémente une interface fonctionnelle, en utilisant la syntaxe `arguments -> corps`.

{% highlight java linenos %}
// Légal car Comparator est une interface fonctionnelle:
Comparator<Integer> c = (x, y) -> x.compareTo(y); 
// Illégal car Object n'est pas une interface fonctionnelle:
Object c = (x, y) -> x.compareTo(y); 
{% endhighlight %}

*Note*: Lorsque la méthode ne prend qu'un seul paramètre, les parenthèses peuvent être omises.

### Méthodes par défaut
Depuis Java 8, les interfaces peuvent avoir des méthodes par défaut, non-statiques, héritées par toutes les classes qui implémentent l'interface.

{% highlight java linenos %}
public interface Comparator<T> {
    public int compare(T o1, T o2);
    public default Comparator<T> reversed() {
        return (o1, o2) -> compare(o2, o1);
    }
    // … autres méthodes par défaut/statiques
}
{% endhighlight %}


## Interfaces fonctionnelles de Java
Il est utile d'avoir à disposition un certain nombre d'interfaces fonctionnelles, couvrant les principaux cas d'utilisation.

### L'interface `Function`
Une fonction à un argument. Le type de cet argument et le type de retour de la fonction sont les paramètres de type de cette interface, nommés respectivement T et R:

{% highlight java linenos %}
// Définition de l'interface
public interface Function<T, R> {
    public R apply(T x);
}

// Exemple d'utilisation
Function<String, Integer> stringLength = s -> s.length();
stringLength.apply("bonjour"); // → 7
{% endhighlight %}

### Composition de fonctions

{% highlight java linenos %}
Function<Integer,Integer> f = x -> x + x;
Function<Integer,Integer> g = x -> x + 1;
Function<Integer,Integer> fg = f.compose(g);

fg.apply(10); // → 22
{% endhighlight %}

### L'interface `UnaryOperator`
Le type de retour est le même que celui d'entrée

{% highlight java linenos %}
UnaryOperator<Double> abs = x -> Math.abs(x);

abs.apply(-1.2); // → 1.2
abs.apply(Math.PI); // → 3.1415…
{% endhighlight %}

### L'interface `BiFunction`
2 arguments de types donnés par les paramêtres de la fonction générique.

{% highlight java linenos %}
BiFunction<String,Integer,Character> charAt = (s, i) -> s.charAt(i);
charAt.apply("hello", 2); // → l
{% endhighlight %}

### L'interface `Predicate`
Retourne un booléen:

{% highlight java linenos %}
Predicate<String> stringIsEmpty = x -> x.isEmpty();

stringIsEmpty.test("not empty!"); // → false
stringIsEmpty.test(""); // → true
{% endhighlight %}

### Composition de prédicats
On a les méthodes `and`, `or` et `negate`:
{% highlight java linenos %}
Predicate<Integer> p = x -> x >= 0;
Predicate<Integer> q = x -> x <= 5;
Predicate<Integer> r = p.and(q);
Predicate<Integer> s = p.or(q);
Predicate<Integer> t = s.negate();
{% endhighlight %}



Et:
- `BinaryOperator` (double UnaryOperator)
- `BiPredicate` (double prédicat)
- `Consumer` (ne retourne rien, mais peut par exemple faire un print)
- `Supplier` (aucun argument, retourne une valeur)

## Fonctions et collections
- `Iterable.forEach` prend un consommateur en argument et l'applique à chaque élément de l'entité itérable.
- `Collection.removeIf` prend un prédicat en argument et supprime tous les éléments de la collection qui le satisfont. 
- `List.replaceAll` prend un opérateur unaire en argument et remplace chaque élément de la liste par le résultat de cet opérateur appliqué à l'élément en question.
- `Map.computeIfAbsent` retourne la valeur associée à une clef, si elle existe ; sinon, elle utilise la fonction qu'on lui a passée pour déterminer la valeur associée à la clef, l'ajoute à la table, puis la retourne.

L'intérêt de ces fonctions est clair:

{% highlight java linenos %}
m.computeIfAbsent(k, k1 -> new HashSet<>()).add(v); 
// Est équivalent à:
if (!m.containsKey(k))
    m.put(k, new HashSet<>());
m.get(k).add(v);
{% endhighlight %}

## Programmation par flots
Le paquetage `java.util.stream` — nouveauté de la version 8 de Java — définit plusieurs classes et interfaces permettant de faire de la programmation par flots.

### Exemple: Conversion °F en °C

1. Obtenir le flot des lignes du fichier d'entrées
2. Filtrer ce flot pour ne garder que les lignes non vides
3. Convertir le flot de lignes — des chaînes de caractères — en un flot de températures en °F — des nombres réels
4. Convertir le flot des températures en °F en flot des températures en °C, au moyen de la formule de conversion [°C = (°F − 32) × 5/9]
5. Ecrire chaque valeur du flot dans le fichier de sortie, une par ligne. 



{% highlight java linenos %}
try(BufferedReader r = new BufferedReader(
    new FileReader("f.txt"));
    PrintWriter w = new PrintWriter(new FileWriter("c.txt"))) {
        r.lines()
            .filter(l -> !l.isEmpty())
            .map(l -> Double.parseDouble(l))
            .map(f -> (f - 32d) * (5d / 9d))
            .forEach(c -> { w.println(c);
    });
}
{% endhighlight %}

### Types de méthodes travaillant sur les flots

1. Les **méthodes sources**, qui produisent un flot de valeurs à partir d'une source qui peut p.ex. être une collection, un fichier, etc.
2. Les **méthodes intermédiaires**, qui transforment les valeurs du flot
3. Les **méthodes terminales**, qui consomment les valeurs du flot, p.ex. en les écrivant dans un fichier, en les réduisant à une valeur unique, etc.

### Pipelines
Une pipeline est formée de:

- *Une* méthode source, qui produit un flot de valeurs
- *Zero ou plusieurs méthodes* intermédiaires, qui transforment les valeurs
- *Une* méthode terminale, qui consomme les valeurs

### Méthodes de `Stream`
- `Stream.of`: prend un nombre arbitraire d'arguments et en crée un flot.
- `Stream.iterate`: produit un flot infini. Exemple:

{% highlight java linenos %}
Stream<Integer> posInts = Stream.iterate(1, i -> i + 1); // 1, 2, …
{% endhighlight %}

- `Stream.filter`: Méthode intermédiaire qui produit un flot filtré contenant uniquement les valeurs satisfaisant un prédicat:

{% highlight java linenos %}
Stream<Integer> multiplesOfThree = posInts.filter(x -> x % 3 == 0); // 3,6,…
{% endhighlight %}

- `Stream.map`: méthode intermédiaire qui applique une fonction à un argument aux éléments du flot et produit le flot des résultats:

{% highlight java linenos %}
Stream<Integer> posSqrs = posInts.map(i -> i * i); // 1, 4, 9, 16, …
{% endhighlight %}

- `Stream.limit`: limite le nombre maximal de valeurs que peut produire un flot (`posInts.limit(10)`).

- `Stream.reduce`: méthode terminale qui réduit à une valeur unique les  valeurs du flot, au moyen d'une valeur initiale et d'un opérateur binaire:

{% highlight java linenos %}
int posInts10Sum = posInts10.reduce(0, (x, y) -> x + y);
int posInts10Prod = posInts10.reduce(1, (x, y) -> x * y);
{% endhighlight %}

#### Ponts vers les flots

- `Collection.stream`: La méthode stream de l'interface Collection retourne un flot avec les éléments de la collection. Elle sert donc de pont entre le monde des collections et celui des flots. 

- `BufferedReader.lines`: La méthode lines de BufferedReader retourne le flot des lignes du lecteur auquel on l'applique. Elle sert donc de pont entre le monde des lecteurs et celui des flots.

## Références de méthodes
Il arrive souvent que l'on veuille écrire une fonction anonyme qui se contente d'appeler une méthode en lui passant les arguments qu'elle a reçus.

Il y a une notation plus concise:

{% highlight java linenos %}
// Méthode anonyme qui renvoie simplement ses arguments:
Comparator<Integer> c = (i1, i2) -> Integer.compare(i1, i2);
// Est équivalent à:
Comparator<Integer> c = Integer::compare;
{% endhighlight %}

Il y a trois types de références:

- les références de méthodes statiques,
- les références de constructeurs,
- les références de méthodes non statiques, dont il existe
deux variantes

### Références statiques
Une référence à une méthode statique s'obtient simplement en séparant le nom de la classe et celui de la méthode par un double deux-points. 


{% highlight java linenos %}
Comparator<Integer> c = Integer::compare;
// Equivalent:
Comparator<Integer> c = (s1, s2) -> Integer.compare(s1, s2);
{% endhighlight %}

### Références à un constructeur
On utilise le mot-clef new en lieu et place du nom de méthode statique.

{% highlight java linenos %}
Supplier<List> lists = ArrayList::new;
Supplier<List> lists = () -> new ArrayList();
{% endhighlight %}

### Références non-statiques
**Exemple**: un comparateur sur les chaînes ne faisant rien d'autre qu'utiliser la méthode (non statique !) `compareTo` des chaînes peut s'écrire :

{% highlight java linenos %}
Comparator<String> c = String::compareTo;
Comparator<String> c = (s1, s2) -> s1.compareTo(s2);
{% endhighlight %}

*Note*: l'objet auquel on applique la méthode devient le premier argument de la fonction anonyme !

La différence entre une référence statique et non-statique est:

- une référence à une méthode statique produit une fonction anonyme ayant le même nombre d'arguments que la méthode,
- une référence à une méthode non statique produit une fonction anonyme ayant un argument de plus que la méthode, cet argument supplémentaire étant le récepteur, c-à-d l'objet auquel on applique la méthode.



{% highlight java linenos %}
// Equivalents:
Function<Integer, Character> alphabetChar = i -> "abcdefghijklmnopqrstuvwxyz".charAt(i);
Function<Integer, Character> alphabetChar = "abcdefghijklmnopqrstuvwxyz"::charAt;


// Compilent tous les 2:
BiFunction<Integer, Integer, Integer> c1 = Integer::compare; // statique
BiFunction<Integer, Integer, Integer> c2 = Integer::compareTo; // non statique
{% endhighlight %}

#### Reprise de [l'exemple de conversion](#exemple-conversion-f-en-c)
{% highlight java linenos %}
try(BufferedReader r = new BufferedReader(new FileReader("f.txt"));
    PrintWriter w = new PrintWriter(
    new FileWriter("c.txt"))) {
        r.lines()
        .filter(l -> !l.isEmpty()) // X
        .map(Double::parseDouble)
        .map(f -> (f - 32d) * (5d / 9d))
        .forEach(w::println);
}
{% endhighlight %}

*Note:* A l'endroit marqué X, on pourrait réécrire avec `l::isEmpty` (ou un truc du genre) **si** on ne faisait pas un `!`.

# [Généricité avancée](http://cs108.epfl.ch/archive/15/files/ppo15_08_genericite-avancee.pdf)

## Sous-types
Lorsqu'une classe implémente ou étend une autre, alors son type est un sous-type de l'autre (String est un sous-type d'Object, par exemple).

La relation de sous-typage est:

- **Réflexive**: tout type est sous-type de lui-même.
- **Transitive**: le sous-type du sous-type d'un type est sous-type du type (c'est logique).
- **Anti-symétrique**: Si T1 est sous-type de T2 et vice versa alors T1 = T2.

(En maths, on parle *d'ordre partiel*).

### Polymorphisme d'inclusion
On peut substituer un sous-type à un type (exemple: utiliser un `Integer` et un `Double` lorsqu'une méthode demande deux `Number`s).

Ceci est alors permis:

{% highlight java linenos %}
List<Number> l = new LinkedList<>();
Integer i = 1;
l.add(i);
Double d = 3.14;
l.add(d); 
{% endhighlight %}

Cependant, ceci ne l'est pas (!!):

{% highlight java linenos %}
List<Number> l = new LinkedList<>();
List<Integer> li = new LinkedList<>();
Integer i = 1;
li.add(i);
l.addAll(li); // refusé !
{% endhighlight %}

Pourquoi? Parce que `List<Integer>` n'est pas un sous-type de `List<Number>` (par contre, `LinkedList<Integer>` est un sous-type de `List<Integer>`).

Voici ce qu'on peut faire pour y remédier:

{% highlight java linenos %}
interface List<E> {
    …
    <F extends E> void addAll(List<F> other);
}
{% endhighlight %}

Ceci donne une borne supérieure au type; tous les sous-types de E, sous-sous-types de E, ..., sont acceptés.

## Jokers (*wildcards*)
On peut utiliser un `?` au lieu de nommer un nouveau type qui n'est utilisé qu'une fois. La solution précédente serait alors:

{% highlight java linenos %}
public interface List<E> {
    …
    void addAll(List<? extends E> other);
}

// ?> Because of my stupid IDE.
{% endhighlight %}


Si jamais on voulait faire l'inverse:

**Attention**: La notation `super` n'est uniquement valide en combinaison avec le joker `?`.
{% highlight java linenos %}
public interface List<E> {
    …
    void addAllInto(List<? super E> other);
    // ?>
}
List<Number> l = new LinkedList<>();
List<Integer> li = new LinkedList<>();
Integer i = 1;
li.add(i);
li.addAllInto(l);
{% endhighlight %}

## Règle des bornes
>Lorsqu'on désire uniquement lire dans une structure, on utilise une borne supérieure (avec `extends`);  
>lorsqu'on désire uniquement y écrire, on utilise une borne inférieure (avec `super`);  
>lorsqu'on désire à la fois y lire et y écrire, on n'utilise aucune borne.

En anglais, on s'en souvient avec l'acronyme **PECS** (*Producer `Extends`, Consumer `Super`*).

# [Types bruts](http://cs108.epfl.ch/archive/15/files/ppo15_08_genericite-avancee.pdf)

L'introduction de généricité a été faite de façon *backwards-compatible*. `List` n'était pas générique avant, et pour que l'ancien code continue à être valide, alors `List` a été accepté comme un **type brut**.

## Règle des types bruts
>N'utilisez jamais les types bruts dans votre code, ils n'existent que pour faciliter la migration du code écrit avant l'introduction de la généricité.


# [Entiers et manipulation de bits](http://cs108.epfl.ch/archive/15/files/ppo15_09_entiers.pdf)

## Types entiers
En Java, les entiers peuvent être représentés par `byte`, `short`, `int` et `long`, mais ils sont limités (puisque numériques).

### Complément à deux
1. Inverser tous les bits
2. Ajouter 1
3. On a le complément à deux

- 2<sup>n-1</sup>-1 valeurs >0
- 2<sup>n-1</sup> valeurs <0
- zéro


#### Exemple
1. 00001100
2. 11110011
3. 11110100

### Notation de grands nombres
- Pour faciliter la lecture, on peut écrire les nombres avec un `_`.
- On utilise le suffixe `L` pour les `long`
- On utilise le préfixe `0b` pour le binaire
- On utilise le préfixe `0x` pour l'héxadécimal
- On utilise le préfixe `0` pour l'octal (base 8)

{% highlight java linenos %}
int earthRadius = 6371;
int earthRadius = 6_371;

long earthPopulation = 7_130_000_000L;

int twelve = 0b1100; // vaut 12
int maxInt = 0b01111111_11111111_11111111_11111111;

long twelveAsLong = 0b1100L;
int twelve = 0xC
long minusOne = 0xFFFF_FFFF_FFFF_FFFFL; // vaut -1 (long)

int thirty = 30; // vaut 30
int notThirty = 030; // vaut 24 (!)
{% endhighlight %}

## Opérations arithmétiques
La plupart des opérations peuvent produire des valeurs non représentables dans le type entier concerné. On dit alors qu'il y a dépassement de *capacité* (**overflow**).

Cela cause une multitude de problèmes:

- De sécurité, si on donne le mauvais index du tableau.
- Mathématiques, puisque `Math.abs` peut retourner un nombre négatif (il ne peut pas inverser `Integer.MIN_VALUE`).

# Opérations bit à bit (*bitwise operations*)
- `~x`: **inversion (ou complément)**: retourne l'inverse d'un bit
- `x << y` : **décalage à gauche**: on rajoute `y` 0 du coté du poids faible de `x`, et on perd les bits de poids fort de `x` (attention, les valeurs de `y` sont prises en modulo 32). Equivalent à une multiplication par 2<sup>y</sup>.
- `x >> y`: **décalage à droite arithmétique**: copie le bit de poids fort dans toutes les positions laissées libres par le décalage. Equivalent à une division **entière** par 2<sup>y</sup>, lorsque `x >= 0`.
- `x >>> y` : **décalage à droite logique**: comme pour le décalage à gauche, on rajoute `y` 0 du coté du poids fort de `x`, et on perd les bits de poids faible de `x` (attention, les valeurs de `y` sont prises en modulo 32)
- `x & y` : conjonction (et) bit à bit,
- `x | y` : disjonction (ou) bit à bit,
- `x ^ y` : disjonction exclusive (ou exclusif) bit à bit.

{% highlight java linenos %}
int a = 0b00001100 << 3; // vaut 0b01100000
int b = 0b11110000 >> 2; // vaut 0b11111100
int c = 0b11110000 >>> 2; // vaut 0b00111100
int d = 0b11110000 & 0b00111100; // vaut 0b00110000
int e = 0b11110000 | 0b00111100; // vaut 0b11111100
int f = 0b11110000 & 0b00111100; // vaut 0b11001100
{% endhighlight %}

`&`, `|` et `^` peuvent être utilisés sur des `boolean`: la différence avec `&&` et `||` est que ces-derniers n'évaluent que le deuxième argument si c'est strictrement nécessaire.

## Masques
Il est souvent utile de manipuler un ou plusieurs bits d'un entier sans toucher aux autres. Pour ce faire, on construit tout d'abord un entier — appelé le masque (mask) — dont seuls les bits à manipuler sont à 1. Ensuite, on utilise l'opération bit à bit appropriée (`&`, `|` ou `^`), appliquée au masque et à la valeur. Un masque peut soit s'écrire directement sous forme d'entier littéral — généralement en base 2 ou 16 — soit se construire en combinant décalages et disjonctions :

{% highlight java linenos %}
int mask13 = 1 << 13; // uniquement bit 13
int mask17 = 1 << 17; // uniquement bit 17
int mask13_17 = mask13 | mask17; // bits 13 et 17

// Pour tester si les bits 13 et 17 de l'entier x sont à 1, on écrit:
boolean bits13_17Set = (x & mask13_17) == mask13_17;

// Pour tester si tous ces bits sont à 0, on écrit:
boolean bits13_17Cleared = (x & mask13_17) == 0;

// Pour tester si au moins l'un de ces bits est à 1, on écrit:
boolean bit13OrBit17Set = (x & mask13_17) != 0;

// Pour mettre à 1 les bits 13 et 17 de l'entier x,on écrit:
int xWithBits13_17Set = x | mask13_17;

// Pour mettre à 0 les bits 13 et 17 de l'entier x, on écrit:
int xWithBits13_17Cleared = x & ~mask13_17;

// Pour inverser les bits 13 et 17 de l'entier x, on écrit:
int xWithBits13_17Toggled = x ^ mask13_17;
{% endhighlight %}

## Mathématiques et opérations bitwise
{% highlight java linenos %}
// x * 2^n:
int multiplyWith2PowN =  x << n;

// x / 2^n (pour x>=0):
int integerDivisionBy2PowN = x >> n;

// x % 2^n
int mod2PowN = x & ((1 << n) - 1);

// Tests de parité
boolean isXEven = (x & 1) == 0;
boolean isXOdd = (x & 1) == 1;
{% endhighlight %}

## Entiers dans l'API Java
Il y a dans l'API Java des classes qui correspondent à chaque type d'entier (`Byte` pour `byte`, `Integer` pour `int`...), que l'on peut utiliser dans les `List<>`, par exemple. Elles ont 2 buts:

1. Servir de "classes d'emballage" pour la généricité.
2. Offrir, sous forme de méthodes statiques, des opérations sur les valeurs du type qu'elles représentent (`MIN_VALUE` et `MAX_VALUE`, `SIZE`, `BYTES`...)

### Auto-emballage (rappel)
{% highlight java linenos %}
List<int> l = Arrays.asList(4); // incorrect !
List<Integer> = Arrays.asList(new Integer(4));
List<Integer> l = Arrays.asList(1); // Equivalent
{% endhighlight %}

### API Java
`Integer` offre :

- `int bitCount(int i)`: retourne le nombre de bits à 1 dans i;
- `int numberOfLeadingZeros(int i)`: retourne le nombre de bits à 0 en tête (à gauche) de i;
- `int numberOfTrailingZeros(int i)` : retourne le nombre de bits à 0 en queue (à droite) de i.
- `int lowestOneBit(int i)`: retourne 0 si i vaut 0, ou une valeur ayant un seul bit à 1, dont la position est celle du bit à 1 de poids de plus faible de i,
- `int highestOneBit(int i)`: idem, mais pour le bit de poids le plus fort.
- `int rotateLeft(int i, int d)`: retourne l'entier obtenu par rotation des bits de i de d positions vers la gauche; Une rotation est similaire à un décalage, mais les bits qui sont éjectés d'un côté sont réinjectés de l'autre.
- `int rotateRight(int i, int d)`: idem, mais vers la droite.
- `int reverse(int i)`: retourne l'entier obtenu en inversant l'ordre des bits de i;
- `int reverseBytes(int i)`: retourne l'entier obtenu en inversant l'ordre des octets de i.

(`Long` aussi, mais les arguments sont des `long`)


## Somme de bits

{% highlight java linenos %}
public static int bitCount(byte b) {
    int s1 = ((b & 0b10101010) >>> 1) + (b & 0b01010101);
    int s2 = ((s1 & 0b11001100) >>> 2) + (s1 & 0b00110011);
    int s3 = ((s2 & 0b11110000) >>> 4) + (s2 & 0b00001111);
    return s3;
}
{% endhighlight %}

Voir [les slides](http://cs108.epfl.ch/archive/15/files/ppo15_09_entiers.pdf) pour une description plus détaillée!


# [Patrons](http://cs108.epfl.ch/archive/15/files/ppo15_10_patrons_builder-iterator-strategy-factory.pdf)

Des modèles de programmation pour résoudre des problèmes récurrents (Cependant, attention à ne pas les surutiliser.)

## Attributs d'un patron
- son nom,
- une description du problème résolu,
- une description de la solution à ce problème,
- une présentation des conséquences liées à l’utilisation du patron.

## Diagrammes de classes
Décrit visuellement un ensemble de classes ou d'interfaces. Il y a 3 types de relations entre les classes:

- **héritage**: lorsqu'une classe hérite d'une autre ou implémente une interface,
- **association**: lorsqu'une classe utilise une ou plusieurs instances d'une autre classe,
- **instanciation**: lorsqu'une classe créée des instances d'une autre classe.

Voir les slides 13-15 pour les règles utilisées dans le cadre de ce cours.

## Builder
Pas de surprise.

### Builder intelligent
Construit un objet différent en fonction de l'input (par exemple, en fonction de la densité d'une matrice).



Honnêtement, voir les [slides](http://cs108.epfl.ch/archive/15/files/ppo15_10_patrons_builder-iterator-strategy-factory.pdf). Je ne prendrai pas plus de notes cette semaine. Cependant, une liste est présentée ci-dessous.

- *Builder*
- *Iterator*
- *Strategy* (le tout petit bout de code réutilisable, voir comparateurs)
- *Factory*
- *Abstract Factory* (revoir ceci)

## Adapter

### Problème
Comment peut-on utiliser `public static void shuffle(List<?> list)` sur un tableau d'entiers?

### Solution
Une classe qui adapte le tableau en le présentant comme une liste en implémentant l'interface `List`

{% highlight java linenos %}
public final class ArrayAdapter<E>
    implements List<E> {
        private final E[] array;
        public ArrayAdapter(E[] array) {
        this.array = array;
    }
    public E get(int i) { return array[i]; }
    public E set(int i, E e) {
        E curr = array[i];
        array[i] = e;
        return curr;
    }
    // … les 21 autres méthodes de List
}
{% endhighlight %}

## Decorator

### Problème
On veut dessiner et manipuler des formes géométriques, en offrant la possibilité d'appliquer des transformations de base (translation, rotation, symétrie, ...)

### Solution
On définit des pseudos-formes qui en transforment d'autres.

## Composite

### Problème
Souvent, il est difficile de grouper plusieurs éléments et les reclasser; par exemple, pour un groupe de formes, on veut les grouper pour former une grande forme.

### Solution
On définit une pseudo-forme qui représente un groupe.

## Composite / Decorator
La différence entre Composite et Decorator est minime et se résume au fait que le premier référence plusieurs objets de son propre type, le second un seul.

Le reste est compliqué et est dans les slides.

## MVC
En général, on découpe l'organisation d'une interface graphique en trois ensembles de classes:

- le **modèle**, qui contient la totalité du code propre à
l'application et qui n'a aucune notion d'interface
graphique,
- la **vue**, qui contient la totalité du code permettant de
représenter le modèle à l'écran,
- le **contrôleur**, qui contient la totalité du code gérant les
entrées de l'utilisateur et les modifications du modèle
correspondantes

MVC est qualifié de **modèle architectural**; il ne résoud pas des petits problèmes locaux, mais permet d'organiser l'ensemble de l'application. 

### Modèle
Ensemble du code qui gère les données propres à l'application (par exemple, dans un browser, le code qui gère la connexion au réseau, la décompression d'images...)

### Vue
Ensemble du code responsable de l'affichage des données à l'écran (par exemple, transformer l'HTML en quelque chose de visible).

### Contrôleur
Ensemble du code responsable de la gestion des entrées de l'utilisateur (gérer les clics sur les liens, entrées de texte...)

### Avantages de MVC
- **Réutilisable**: avec d'autres interfaces (mobile, desktop, ...)
- **Facile à tester**: car les parties sont indépendantes.


# [Interfaces graphiques](http://cs108.epfl.ch/archive/15/files/ppo15_13_interfaces-graphiques.pdf)
Les principales librairies sont AWT, Swing et JavaFX.

## Composants
Dans Swing, il y a 2 types de composants:

- **Composants de base**: ne contiennent pas d'autres composants (boutons, zones de texte, ...)
   - Etiquette, textuelle ou graphique (`JLabel`)
   - Boutons: à un état (`JButton`), à deux états (`JToggleButton`), radio (`JRadioButton`), à cocher (`JCheckBox`)
   - ...
- **Conteneurs**: regroupent et organisent un certain nombre de composants (une fenêtre, par exemple).
    - De *niveau supérieur*, pas contenu dans les autres
    - De *niveau intermédiaire*, contenus dans les autres
       - Panneau sans représentation graphique (`JPanel`)
       - Panneau séparé en deux parties redimensionnables (`JSplitPane`)
       - Panneau à onglets (`JTabPane`)
       - ...

### Conteneurs intermiédiaires
- `JSplitPane`  permet de diviser le composant en deux parties, chacune affichant un composant fils. La division peut être verticale ou horizontale, et est redimensionnable, éventuellement par l'utilisateur.
- `JTabbedPane` un panneau composé d'un certain nombre d'onglets affichant chacun un composant fils différent. Un seul onglet est visible à un instant donné.
- `JScrollPane` donne accès à une sous-partie d'un composant trop grand pour tenir à l'écran et permet de déplacer la zone visualisée de différentes manières, p.ex. au moyen de barres de défilement.
- `JLayeredPane` permet de superposer plusieurs composants, ce qui peut être utile pour dessiner au-dessus de composants existants ou pour intercepter les clics de souris qui leur sont destinés. Normalement, il n'y a pas de chevauchement; il faut utiliser un `JLayeredPane` pour le faire.

#### `JPanel`
C'est un panneau, un conteneur intermédiaire sans représentation graphique propre. `JPanel` donne les méthodes suivantes:
– `void add(JComponent c, Object l, int i)`: insère le composant `c` à la position `i` dans les fils (`–1` signifiant la fin) et lui associe l'information d'agencement `l` (voir plus loin),
– `void add(JComponent c, Object l)`, équivalent à `add(c, l, -1)`
– `void add(JComponent c)`, équivalent à `add(c, null)`
– `void remove(JComponent c)`: supprime le composant c des fils,
– `void remove(int i)`: supprime le fils d'index `i`.

L'agencement des fils — leur positionnement à l'intérieur du rectangle de leur parent — peut se faire de deux manières: 

1. « manuellement », en changeant leurs bornes au moyen de la méthode setBounds
2. via un **gestionnaire d'agencement** (*layout manager*) attaché au parent et responsable de l'agencement de ses fils et de son dimensionnement. 

#### Gestionnaire d'agencement
L'interface LayoutManager représente un gestionnaire d'agencement. Ces gestionnaires agencent chacun les fils en fonction d'une technique qui leur est propre.

- `BorderLayout`: agencement en lignes successives.
- `BoxLayout`: agencement en ligne verticale, centrée.
- `GridLayout`: en grille de n*m éléments.

{% highlight java linenos %}
JPanel p = new JPanel(new BorderLayout());
JFormattedTextField display = …;

// … configuration de display
p.add(display, BorderLayout.PAGE_START);
JPanel keyboard = new JPanel(new GridLayout(4, 4));

// … configuration de keyboard (boutons, …)
p.add(keyboard, BorderLayout.CENTER);
JFrame frame = new JFrame("RPN Calc");
frame.setContentPane(panel);
{% endhighlight %}


#### Fermeture des fenêtres
Pour fermer l'application lorsque l'on ferme la fenêtre (vs. juste rendre la fenêtre invisible), il faut faire:

{% highlight java linenos %}
JFrame f = …;
frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
{% endhighlight %}

#### Boîte de dialogue `JDialog`
Elle est liée à la fenêtre principale, n'est pas une fenêtre à part entière. En fermant la fenêtre, on ferme aussi la boîte de dialogue.

### Composants de base.
- `JLabel` pour les étiquettes 
- `JButton` pour les boutons
- `JCheckBox` pour un checkbox
- `JRadioButton` pour un bouton radio
- `Combo box` pour un `<select></select>`.


# Modèles

Voir slides -- je préfère me concentrer sur ce qui est dit.



{% highlight java linenos %}
{% endhighlight %}
