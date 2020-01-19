---
title: CS-525 Foundations and tools for tree-structured data
description: "My notes from the CS-525 course given at EPFL, in the 2018 autumn semester (MA1)"
date: 2018-09-18
course: CS-525
---

* TOC
{:toc}

<!-- More --> 

## XML
Traditional database systems rely on the relational model, which was initially developed in the 1970's and 1980's. But the Internet brought new challenges for data management, and provided incentives for developing new storage systems. There has been a movement of NoSQL databases since, exploring a variety of data models (key-value stores with Redis, column stores with Cassandra or Google Cloud Bigtable, graph stores with Neo4j, or document stores with MongoDB or Exist-db).

Many of these were not standardized, and essentially were tied to a specific implementation. This can pose a problem for data that needs to be kept for a long time (in the banking or aeronautical industries, for instance). Indeed, the life cycle of data is often much longer than that of programs.

How can we ensure long-term access to data? How can we ensure that it can still be read in 15 or 50 years? One information representation format that hasn't changed for 50+ years is ASCII (1963), so for long-term data access, this is probably the best bet.

But we still need a standard format: otherwise, the ASCII encoding of our data is still tied to a particular file parser. This means that data exchange is reduced to a program exchange, which is expensive and doesn't scale.

This is what XML was originally invented for: to have one language to describe and exchange data. It isn't the first in its field, though; its ancestor is SGML, invented in 1974 at IBM. Tim Berners-Lee invented HTML in 1989, and and founded the W3C in 1994. XML was first drafted in 1996.

The initial [W3C goals of XML](https://www.w3.org/TR/WD-xml-961114#sec1.1) were:

1. XML shall be straightforwardly usable over the Internet.
2. XML shall support a wide variety of applications.
3. XML shall be compatible with SGML.
4. It shall be easy to write programs which process XML documents.
5. The number of optional features in XML is to be kept to the absolute minimum, ideally zero.
6. XML documents should be human-legible and reasonably clear.
7. The XML design should be prepared quickly.
8. The design of XML shall be formal and concise.
9. XML documents shall be easy to create.
10. Terseness is of minimal importance.  

The last point is perhaps the biggest con about XML: it's extremely verbose, and has lots of repetitive markup, which makes for large files.

But there are many pros about XML: it's a long-standing, standardized format, and one of the pillars of the web. If you use XML, you shouldn't ever have to write a parser.

XML is a meta-language: it makes it possible to create markup languages: concrete implementations of XML are known as "XML dialects". They describe all the admissible structures (legal element names, how they can be composed, and perhaps even the data types they can contain). To define such a dialect, one must write a schema with DTD, XML Schema or Relax NG &mdash; more on this later. Some widespread dialects are XHTML, SVG, SOAP, MathML, WSDL, XForms.

There are therefore two levels of correctness with XML. The first is the minimal requirement that XML files should be well-formed XML. The second is optional and stricter: the XML can conform to a given XML dialect.

## XPath
XPath is the [W3C standard language](https://www.w3.org/TR/xpath/all/) for traversal and navigation in XML trees.

For navigation, we use the **location path** to identify nodes or content. A location path is a sequence of location steps separated by a `/`:

{% highlight xpath linenos %}
(: The following XPath expression has three location paths :)
(:     1    :) (:       2       :) (:   3   :)
child::chapter/descendant::section/child::para
{% endhighlight %}

Every location step has an axis, `::` and then a node test. Starting from a context node, a location returns a node-set. Every selected node in the node-set is used as the context node for the next step. 

You can start an XPath expression with `/` start from the root, which is known as an **absolute path**.

XPath defines 13 axes allowing navigation, including `self`, `parent`, `child`, `following-sibling`, `ancestor-or-self`, etc. There is a special `attribute` axis to select attributes of the context node, which are not really in the child hierarchy. Similarly, `namespace` selects namespace nodes.

A nodetest filters nodes:

| Test           | Semantics                                             |
| :------------- | :---------------------------------------------------- |
| `node()`       | let any node pass                                     |
| `text()`       | select only text nodes                                |
| `comment()`    | preserve only comment nodes                           |
| `name`         | preserves only **elements/attributes** with that name |
| `*`            | `*` preserves every **element/attribute**             |

At each navigation step, nodes can be filtered using qualifiers. For instance:

{% highlight xpath linenos %}
(: axis::nodetest[qualifier1] :)
following-sibling::para[position()=last()]
{% endhighlight %}

A qualifier filters a node-set depending on the axis. Each node in a node-set is kept only if the evaluation of the qualifier returns true.

Qualifiers may include comparisons (`=`, `<`, `<=`, ...). When comparing nodes, the comparison is done on the `string-value()`, which is the concatenation of all descendant text nodes in *document order*. But there's a catch here! Comparison between node-sets is under existential semantics: there only needs to be one pair of nodes for which the comparison is true:

{% highlight text linenos %}
node-set1 eq node-set2
iff
∃n1 ∈ node-set1, ∃n2 ∈ node-set1 | string-value(n1) eq string-value(n2)

where eq ∈ {=, !=, <, >, <=, >=}
{% endhighlight %}

Thus, when negating, we can get universal quantification.

XPaths can be a union of location paths separated by `|`. Qualifiers can include boolean expressions (`or`, `not`, `and`, ...). 

We can use variables `$x`, but these cannot be set in XPath; they are constants, set by the host language executing the XPath expression.

There are a few basic functions: `last()`, `position()`, `count(node-set)`, `concat(string, string, ...string`), `contains(str1, str2)`, etc. These can be used within a qualifier.

XPath also supports abbreviated syntax:

| Abbreviated | Full form                      |
| :---------- | :----------------------------- |
| `child::`   | Default axis, can be omitted   |
| `@`         | `attribute::`                  |
| `//`        | `/descendant-or-self::node()`/ |
| `.`         | `self::node()`                 |
| `..`        | `parent::node()`               |
| `[4]`       | `[position() = 4]`[^pos-one]   |

[^pos-one]: Note that positions start at 1

XPath is used in XSLT, XQuery, XPointer, XLink, XML Schema, XForms, ...

### Evaluation
To evaluate an XPath expression, we have in our state:

- The context node
- Context size: number of nodes in the node-set
- Context position: index of the context node in the node-set
- A set of variable bindings

## XML Schemas
There are three classes of languages that constraint XML content:

- Constraints expressed by **a description** of each element, and potentially related attributes (DTD, XML Schema)
- Constraints expressed by **patterns** defining the admissible elements, attributes and text nodes using regexes (Relax NG)
- Constraints expressed by **rules** (Schematron)

### DTD

Document Type Definitions (DTDs) are XML's native schema system. It allows to define document classes, using a declarative approach to define the logical structure of a document.

{% highlight xml linenos %}
<!ELEMENT recipe (title, comment*, item+, picture?, nbPers)>
<!ATTLIST recipe difficulty (easy|medium|difficult) #IMPLIED>
<!ELEMENT title (#PCDATA)>
<!ELEMENT comment (#PCDATA)>
<!ELEMENT item (header?,((ingredient+, step+) | (ingredient+, step)+))>
<!ELEMENT header (#PCDATA)>
<!ELEMENT ingredient (#PCDATA)>
<!ELEMENT step (#PCDATA)>
<!ELEMENT picture EMPTY>
<!ATTLIST picture source CDATA #REQUIRED format (jpeg | png) #IMPLIED >
<!ELEMENT nbPers (#PCDATA)>
{% endhighlight %}

### XML Schema

XML Schemas are a [W3C standard](http://www.w3.org/TR/xmlschema-0/) that go beyond the native DTDs. XML Schema descriptions are valid XML documents themselves.

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <xsd:element name="RecipesCollection">
        <xsd:complexType>
            <xsd:sequence minOccurs="0" maxOccurs="unbounded">
                <xsd:element name="Recipe" type="RecipeType"/>
            </xsd:sequence>
        </xsd:complexType>
    </xsd:element>
    ...
</xsd:schema>

{% endhighlight %}

To declare an element, we do as follows; by default, the author element as defined below may only contain string values:

{% highlight xml linenos %}
<xsd:element name="author"/>
{% endhighlight %}

But we can define other types of elements, that aren’t just strings. Types include `string`, 
`boolean`, `number`, `float`, `duration`, `time`, `date`, `AnyURI`, … The types are still string-encoded and must be extracted by the XML application, but this helps verify the consistency.

{% highlight xml linenos %}
<xsd:element name="year" type="xsd:date"/>
{% endhighlight %}

We can bound the number of occurrences of an element. Below, the `character` element may be repeated 0 to &infin; times (this is equivalent to something like `character*` in a regex). Absence of `minOccurs` and `maxOccurs` implies exactly once (like in a regex).

{% highlight xml linenos %}
<xsd:element name="character" minOccurs="0" maxOccurs="unbounded"/>
{% endhighlight %}

We can define more complex types using **type constructors**. 

{% highlight xml linenos %}
<xsd:complexType name="Characters">
    <xsd:sequence>
        <xsd:element name="character" minOccurs="1" maxOccurs="unbounded"/>
    </xsd:sequence>
</xsd:complexType>
<xsd:complexType name="Prolog">
    <xsd:sequence>
        <xsd:element name="series"/>
        <xsd:element name="author"/>
        <xsd:element name="characters" type="Characters"/>
    </xsd:sequence>
</xsd:complexType>

<xsd:element name="prolog" type="Prolog"/>
{% endhighlight %}

This defines a Prolog type containing a sequence of a `series`, `author`, and `characters` of type `Characters`, which is defined as a sequence of `character+` elements. 

Using the `mixed="true"` attribute on an `xsd:complexType` allows for mixed content: attributes, elements, and text can be mixed (like we know in HTML, where you can do `<p>hello <em>world</em>!</p>`).

There are more type constructor primitives that allow to do much of what regexes do: `xsd:sequence`, which we’ve seen above, but also `xsd:choice` (for enumerated elements) and `xsd:all` (for unordered elements).

Attributes can also be declared within their owner element:

{% highlight xml linenos %}
<xsd:element name="strip">
    <xsd:attribute name="copyright"/>
    <xsd:attribute name="year" type="xsd:gYear"/>
</xsd:element>
{% endhighlight %}

Because writing complex types can be tedious, complex types can be derived by extension or restriction from existing base types:

{% highlight xml linenos %}
<xsd:complexType name="BookType">
    <xsd:complexContent>
        <xsd:extension base="Publication">
            <xsd:sequence>
                <xsd:element name ="ISBN" type="xsd:string"/>
                <xsd:element name ="Publisher" type="xsd:string"/>
            </xsd:sequence>
        </xsd:extension>
    </xsd:complexContent>
</xsd:complexType>
{% endhighlight %}

Additionally, it is possible to define user-defined types:

{% highlight xml linenos %}
<xsd:simpleType name="Car">
    <xsd:restriction base="xsd:string">
        <xsd:enumeration value="Audi"/>
        <xsd:enumeration value="BMW"/>
        <xsd:enumeration value="VW"/>
    </xsd:restriction>
</xsd:simpleType>

<xsd:simpleType name="WeakPasswordType">
    <xsd:restriction base="xsd:string">
        <xsd:pattern value="[a-z A-Z 0-9{8}]"/>
    </xsd:restriction>
</xsd:simpleType>
{% endhighlight %}

#### Criticism

There [have been some criticisms](http://xml.coverpages.org/Clark-Jelliffe-Schemas20020604.html) addressed to XML Schema:

- The specification is very difficult to understand
- It requires a high level of expertise to avoid surprises, as there are many complex and unintuitive behaviors
- The choice between element and attribute is largely a matter of the taste of the designer, but XML Schema provides separate functionality for them, distinguishing them strongly
- There is only weak support for unordered content. In SGML, there was support for the `&` operator. `A & B` means that we must have `A` followed by `B` or vice-versa (order doesn't matter). But we could enforce `A & B*` such that there would have to be a sequence of `B` which would have to be grouped. XML Schema is too limited to enforce such things.
- The datatypes (strings, dates, etc) are tied to [a single collection of datatypes](https://www.w3.org/TR/xmlschema-2/), which can be a little too limited for certain domain-specific datatypes. 
  
  But XML Schema 1.1 addressed this with two new features, co-occurrences constraints and assertions on simple types.

  Co-occurrences are constraints which make the presence of an attribute, element or values allowable for it, depend on the value or presence of other attributes or elements.

  Assertions on simple types introduced a new facet for simple types, called an assertion, to precise constraints using XPath expressions.

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xs:element name="NbOfAttempts">
        <xs:complexType>
            <xs:attribute name="min" type="xs:int"/>
            <xs:attribute name="max" type="xs:int"/>
            <xs:assert test="@min le @max"/>
        </xs:complexType>
    </xs:element>
</xs:schema>
{% endhighlight %}

Therefore, some of the original W3C XML Schema committee have gone on to create alternatives, some of which we will see below.

### Relax NG
Pronounced "relaxing". Relax NG's goals are:

- Be easier to learn and use
- Provide an XML syntax that is more readable and compact
- Provide a theoretical sound language (based on tree automata, which we'll talk about later)
- The schema follows the structure of the document. 

The reference book for Relax NG is [Relax NG by Eric van der Vlist](http://books.xmlschemata.org/relaxng/).

As the example below shows, Relax NG is much more legible:

{% highlight xml linenos %}
<element name="AddressBook">
    <zeroOrMore>
        <element name="Card">
            <element name="Name">
                <text/>
            </element>
            <element name="Email">
                <text/>
            </element>
            <optional>
                <element name="Note">
                    <text/>
                </element>
            </optional>
        </element>
    </zeroOrMore>
</element>
{% endhighlight %}

Another example shows a little more advanced functionality; here, a card can either contain a single `Name`, or (exclusive or) both a `GivenName` and `FamilyName`.

{% highlight xml linenos %}
<element name="Card">
    <choice>
        <element name="Name">
            <text/>
        </element>
        <group>
            <element name="GivenName">
                <text/>
            </element>
            <element name="FamilyName">
                <text/>
            </element>
        </group>
    </choice>
</element>
{% endhighlight %}

Some other tags include:

- `<choice>` allows only one of the enumerated children to occur
- `<interleave>` allows child elements to occur in any order (like `xsd:all` in XML Schema)
- `<attribute>` inside an `<element>` specifies the schema for attributes. By itself, it's considered required, but it can be wrapped in an `<optional>` too.
- `<group>` allows to, as the name implies, logically group elements. This is especially useful inside `<choice>` elements, as in the example above.

The Relax NG book has a more detailed overview of these in [Chapter 3.2](http://books.xmlschemata.org/relaxng/relax-CHP-3-SECT-2.html)

Relax NG allows to reference externally defined datatypes, such as [those defined in XML Schema](https://www.w3.org/2001/XMLSchema-datatypes). To include such a reference, we can specify a `datatypeLibrary` attribute on the root `<grammar>` element:

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0"
xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
    <start>
        ...
    </start>
</grammar>
{% endhighlight %}

In addition to datatypes, we can also express admissible XML *content* using regexes, but (and this is important!) **we cannot express cardinality constraints or uniqueness constraints**. 

If we need to express those, we can make use of Schematron.

### Schematron
[Schematron](http://schematron.com) is an assertion language making use of XPath for node selection and for encoding predicates. It is often used *in conjunction* with Relax NG to express more complicated constraints, that aren't easily expressed (or can't be expressed at all) in Relax NG. The common pattern is to build the structure of the schema in Relax NG, and the business logic in Schematron.

They can be combined in the same file by declaring different namespaces. For instance, the example below allows us to write a Relax NG schema as usual, and some Schematron rules rules under the `sch` namespace.

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<grammar xmlns="http://relaxng.org/ns/structure/1.0"
    xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    datatypeLibrary="http://www.w3.org/2001/XMLSchema-datatypes">
    
    ...

</grammar>
{% endhighlight %}

As we can see in the example below, a Schematron schema is built from a series of assertions:

{% highlight xml linenos %}
<schema xmlns="http://purl.oclc.org/dsdl/schematron" >
    <title>A Schema for Books</title>
    <ns prefix="bk" uri="http://www.example.com/books" />
    <pattern id="authorTests">
        <rule context="bk:book">
            <assert test="count(bk:author)!= 0">
                A book must have at least one author
            </assert>
        </rule>
    </pattern>
    <pattern id="onLoanTests">
        <rule context="bk:book">
            <report test="@on-loan and not(@return-date)">
                Every book that is on loan must have a return date
            </report>
        </rule>
    </pattern>
</schema>
{% endhighlight %}

A short description of the different Schematron elements follows:

- `<ns>`: specifies to which namespace a prefix is bound. In the above example, the `bk` prefix, used as `bk:book`, is bound to `http://www.example.com/books`. This prefix is used by XPath in the elements below.
- `<pattern>`: a pattern contains a list of rules, and is used to group similar assertions. This isn't just for better code organization, but also allows to execute groups at different stages in the validation
- `<rule>`: a rule contains `<assert>` and `<report>` elements. It has a `context` attribute, which is an XPath specifying the element on which we're operating; all nodes matching the XPath expression are tested for all the assertions and reports of a rule
- `<assert>`: provides a mechanism to check if an assertion is true. If it isn't, a validation error occurs
- `<report>`: same as an assertion, but the validation doesn't fail; instead, a warning is issued.

## XML Information Set
The purpose of [XML Information Set](https://msdn.microsoft.com/en-us/library/aa468561.aspx), or Infoset, is to "provide a consistent set of definitions for use in other specifications that need to refer to the information in a well-formed XML document"[^infoset-spec].

[^infoset-spec]: [XML Information Set specification](https://www.w3.org/TR/xml-infoset/#intro), W3C Recommendation

It specifies a standardized, abstract model to represent the properties of XML trees. The goal is to provide a standardized viewpoint for the implementation and description of various XML technologies.

It functions like an AST for XML documents. It's abstract in the sense that it abstract away from the concrete encoding of data, and just retains the meaning. For instance, it doesn't distinguish between the two forms of the empty element; the following are considered equivalent (pairwise):

{% highlight xml linenos %}
<element></element>
<element/>

<element attr="example"/>
<element attr='example'/>
{% endhighlight %}

The Information Set is described as a tree of information items, which are simply blocks of information about a node in the tree; every information item is an abstract representation of a component in an XML document. 

As such, at the root we have a document information item, which, most importantly, contains a list of children, which is a list of information items, in document order. Information items for elements contain a local name, the name of the namespace, a list of attribute information items, which contain the key and value of the attribute, etc.


## XSLT

### Motivation
XSLT is part of a more general language, XSL. The hierarchy is as follows:

- **XSL**: eXtensible Stylesheet Language
    - **XSLT**: XSL Transformation
    - **XLS-FO**: XSL Formatting Objects

An XSLT Stylesheet allows us to transform XML input into other formats. An XSLT Processor takes an XML input, and an XSLT stylesheet and produces a result, either in XML, XHTML, LaTeX, ...

XSLT is a **declarative** and **functional** language, which uses XML and XPath. It's a [W3C recommendation](https://www.w3.org/TR/xslt/all/), often used for generating HTML views of XML content.

The XSLT Stylesheet consists of a set of templates. Each of them matches specific elements in the XML input, and participates to the generation of data in the resulting output.

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xd="http://oxygenxml.com/ns/doc/xsl" version="1.0">
    <xsl:template match="a">...</xsl:template>
    <xsl:template match="b">...</xsl:template>
    <xsl:template match="c">...</xsl:template>
    <xsl:template match="d">...</xsl:template>
</xsl:stylesheet>
{% endhighlight %}

Let's take a look at an individual XSLT template:

{% highlight xml linenos %}
<xsl:template match="e">
    <!-- Template body goes here -->
    <xsl:apply-templates/>
</xsl:template>
{% endhighlight %}

- `e` is an XPath expression that selects the nodes the XSLT processor will apply the template to
- The body of the `xsl:template` specifies the content to be produces in the output for each node selected by `e`
- `xsl:apply-templates` indicates that templates are to be applied on the selected nodes, in document order; to select nodes, it may have a `select` attribute, which is an XPath expression defaulting to `child::node()`.

The XSLT execution is roughly as follows:

{% highlight python linenos %}
def process(node):
    find most specific pattern
    # instantiate template:
    create result fragment
    for (instruction selecting other nodes) in template:
        for new_node in instruction:
            process(new_node)

process(xml.root)
{% endhighlight %}  

Recursion stops when no more source nodes are selected.

### Default templates
XSLT Stylesheets contain **default templates**:

{% highlight xml linenos %}
<xsl:template match="/ | *">
    <xsl:apply-templates/>
</xsl:template>
{% endhighlight %}

This recursively drives the matching process, starting from the root node. If templates are associated to the root node, then this default template is overridden; if the overridden version doesn't contain any `<xml: >` elements, then the matching process is stopped.

Another default template is:

{% highlight xml linenos %}
<xsl:template match="text()|@*">
    <xsl:value-of select="self::node()"/>
</xsl:template>
{% endhighlight %}

This copies text and attribute nodes in the output.

A third default is: 

{% highlight xml linenos %}
<xsl:template match="processing-instruction()|comment()"/>
{% endhighlight %}

This is a template that specifically matches processing instructions and comments; it is empty, so it does not generate anything for them. 

### Example
To get an idea of what XSLT could do, let's consider the following example of XML data representing a catalog of books and CDs:

{% highlight xml linenos %}
<Catalog>
    <!-- Book Sample -->
    <Product>
        <ProductNo>bk-005</ProductNo>
        <Book Language="FR">
            <Price>
                <Value>19</Value>
                <Currency>EUR</Currency>
            </Price>
            <Title>Profecie</Title>
            <Authors>
                <Author>
                    <FirstName>Jonathan</FirstName>
                    <LastName>Zimmermann</LastName>
                </Author>
            </Authors>
            <Year>2015</Year>
            <Cover>profecie</Cover>
        </Book>
    </Product>

    <!-- CD sample -->
    <Product>
        <ProductNo>cd-003</ProductNo>
        <CD>
            <Price>
                <Value>18.90</Value>
                <Currency>EUR</Currency>
            </Price>
            <Title>Witloof Bay</Title>
            <Interpret>Witloof Bay</Interpret>
            <Year>2010</Year>
            <Sleeve>witloof</Sleeve>
            <Opinion>
                <Parag>Original ce groupe belge.</Parag>
                <Parag>Une véritable prouesse technique.</Parag>
            </Opinion>
        </CD>
    </Product>
</Catalog>
{% endhighlight %}

For our example of books and CDs, we can create the following template:

{% highlight xml linenos %}
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xs="http://www.w3.org/2001/XMLSchema"
exclude-result-prefixes="xs"
version="2.0">
    <xsl:output method="html"/>

    <xsl:template match="/">
        <html>
        <head>...</head>
        <body>
            <h2>Welcome to our catalog</h2>
            <h3>Books</h3>
            <ul>
                <xsl:apply-templates select="Catalog/Product/Book/Title">
                    <xsl:sort select="."/>
                </xsl:apply-templates>
            </ul>
        </body>
        </html>
    </xsl:template>

    <xsl:template match="Title">
        <li>
            <xsl:value-of select="."/>
        </li>
    </xsl:template>
</xsl:stylesheet>
{% endhighlight %}

In the above, the `xsl:sort` element has the following possible attributes:

- `select`: here, the attribute is `.`, which refers to the title in this context
- `data-type`: gives the kind of order (e.g. text or number)
- `order`: `ascending` or `descending`

## XQuery
XQuery is a **strongly typed** and **functional** language that offers features to operate on XML input for searching, selecting, filtering, transforming, restructuring information, etc. It is an SQL-like language for XML. It wasn't defined with the same goals as XSLT, but has some overlap that we'll discuss later.

It does not use the XML syntax. Instead, it offers a general purpose (Turing-complete) language that can be used for developing XML based applications.

XQuery is a [W3C Recommendation](https://www.w3.org/TR/xquery/all/), and is therefore closely linked to [XML Schema](#xml-schema), as it uses the XML Schema type system. Note that for now, there is no support for XQuery with Relax NG or other non-W3C schema languages. A nice book on XQuery is [available at O'Reily](http://shop.oreilly.com/product/0636920035589.do).

### Syntax
A query is made up of three parts:

{% highlight xquery linenos %}
(: Comments are written in these smiley-like delimiters :)

(: 1. Optional version declaration :)
xquery version "3.0"; 

(: 2. Optional query prolog :)
(: This contains declarations such as namespaces, variables, etc. :)
declare namespace html = "http://www.w3.org/1999/xhtml"; 

(: 3. Query body :)
substring("Welcome to the world of XML", 1, 7)
{% endhighlight %}

A query takes some kind of XML content: an XML file, an XML fragment retrieved online, a native XML database, etc. The output is a sequence of values, which are often XML elements (this is important: not a document, but elements). But it could also be an XML Schema type, such as a string, a list of integers, etc.

The output can be serialized to a document, or just kept in-memory in the application for further processing.

Queries are evaluated by an XQuery processor, which works in two phases. First, the analysis phase may raise errors (that do not depend on the input, only on the query). Then, there is an evaluation phase, which may raise dynamic errors (e.g. missing input).

A query consists of one or more comma-separated **XQuery expressions**, which are composed of the following:

- Primary expressions (literals, variables, function calls, etc)
- Arithmetic expressions
- Logical expressions
- XPath (with `collection` and `doc` functions used to access resources)
- XML constructors
- Sequence constructors
- [FLWOR statements](https://en.wikipedia.org/wiki/FLWOR) (pronounced "flower": for, let, where, order by, return). 
- Conditional expressions
- Quantified expressions

### Creating XML content
To build XML content, we can embed "escaped" XQuery code using curly brackets, within our template file, as follows:

{% highlight xquery linenos %}
<report year="2018">
    The value is {round (3.14)}
</report>
{% endhighlight %}

### Sequences
A sequence is an ordered collection of items, which may be of any type (atomic value, node, etc). Duplicates are allowed. A sequence can contain zero (empty), one (singleton) or many items. Sequences are comma-separated. We can add parentheses for clarity, but not for nesting; a sequence is always flat (even if we nest parentheses):

{% highlight xquery linenos %}
1, 2, <example/>
(1, 2, <example/>)
{% endhighlight %}

### FLWOR
A FLWOR expression is constructed as follows:

{% highlight antlr linenos %}
flwor ::=  ((for | let) expr)+ (where expr)? (order by expr)? return expr
{% endhighlight %}

For instance:

XQuery also has support for for variables, denoted `$x` (which are more like constants):

{% highlight xquery linenos %}
let $FREvents := /RAS/Events/Event[Canton/text() = "FR"],
    $FRTopics := $FREvents/TopicRef/text() 

return /RAS/Members/Member[Topics/TopicRef/text() = $FRTopics]/Email
{% endhighlight %}

> 👉 This gives us the email addresses of reporters who may deal with events in the canton of Fribourg. See exercises 01 for more context.

Let's take a look at another XQuery expression: 

{% highlight xquery linenos %}
for $book in /Catalog/Product/Book
where $book/@Language = "EN"
return $book/Title

(: equivalently written as :)

for $book in /Catalog/Product/Book[@Language = "EN"]
return $book/Title
{% endhighlight %}

This returns the book titles in the document:

{% highlight xml linenos %}
<Title>XSLT</Title>
<Title>Electronic Publishing</Title>
<Title>Making Sense of NoSQL</Title>
{% endhighlight %}

As we can see above, there is some overlap between XQuery and XPath; the `where` condition can also be written as an XPath selection condition. Which to use is a question of style; there is no difference in performance.

The `order by` and `where` keywords work just like in SQL, so I won't go into details here.

### Conditional expressions
Like in any templating language, we can create conditional statements. It is mandatory to specify an `else` to every `if`, but if we do not want to return anything, we can return the empty sequence `()`.

The condition of an `if` must be a boolean or a sequence. Empty sequences are falsey, and sequences of one or more elements are truthy.

{% highlight xquery linenos %}
for $book in /catalog/product/book
order by $book/title
return
    <title>
        {$book/title/text()}
        {if ($book/@Language = 'EN') then '[English]' else ()}
    </title>
{% endhighlight %}

This returns:

{% highlight xml linenos %}
<title>Electronic Publishing [English]</title>
<title>Making Sense of NoSQL [English]</title>
<title>Profecie</title>
<title>XML - le langage et ses applications</title>
<title>XSLT [English]</title>
{% endhighlight %}

### Quantified expressions
A quantified expression allows us to express universal or existential quantifiers using `some` and `every`. The predicate is given with the keyword `satisfies`, as below:

{% highlight xquery linenos %}
some $dept in doc("catalog.xml")//product/@dept
satisfies ($dept = "ACC")
{% endhighlight %}

### Functions
User defined functions can be declared as follows:

{% highlight xquery linenos %}
declare function local:discountPrice(
    $price as xs:decimal?,
    $discount as xs:decimal?,
    $maxDiscountPct as xs:integer?) as xs:decimal? 
{
    let $maxDiscount := ($price * $maxDiscountPct) div 100
    let $actualDiscount := min(($maxDiscount, $discount))
    return ($price - $actualDiscount)
};
{% endhighlight %}

The types are sequence types, with both the number and types of items. For instance, `xs:string?` means a sequence of zero or one string. The return type is optional, but is strongly encouraged for readability, error checking and optimization.

Functions can be overloaded with a different number of parameters.

The body is enclosed in curly braces. It does not have to contain a `return` clause, it just needs to be an XQuery expression.

### Modules
Functions can be grouped into modules, which declare the target namespace and bind it to a prefix (here, the `strings` prefix):

{% highlight xquery linenos %}
module namespace strings = "https://example.com/strings"
{% endhighlight %}

Anything declared under that prefix can be accessed from the outside, when importing the module.

Modules can be imported at a location using the `at` clause:

{% highlight xquery linenos %}
import module namespace search = "https://example.com/search" at "search.xqm"
{% endhighlight %}

### Updating XML Content
Unlike SQL, standard XQuery only offers ways of querying data, and not of inserting, deleting or updating data. That's why the W3C developed an extension to XQuery called the [XQuery Update Facility](https://www.w3.org/TR/xquery-update-10/).

Like SQL, the implementation of this Update Facility is often tied to specific database systems. In this course, we will use the [eXist-db](http://exist-db.org/exist/apps/homepage/index.html) variant. Updates are executed by specifying the `update` keyword in the `return` clause.

{% highlight xquery linenos %}
let $catalog := doc('db/catalog.xml')

return update insert
    <product>...</product>
into $catalog
{% endhighlight %}

The keyword `into` places content after the last child of the element. We can also use `following`, placing it as the next sibling, or `preceding` to place it as the previous sibling.

Instead of `update insert`, we can also do an `update delete`, or a `update replace XPATH with ELEMENT`.

Updates can be chained as a sequence: 

{% highlight xquery linenos %}
let $cd := doc('db/catalog.xml')/Product[ProductNo = $no]/CD
return
(
    update replace $cd/Price/Value with <value>18</value>,
    update replace $cd/Year with <year>2010</year>
)
{% endhighlight %}

### Advanced features
As we mentionned earlier, XQuery is Turing complete. You can define your own functions, which may be grouped into modules, and may be higher-order functions.

Schema awareness is an optional feature; if it is supported, the `validate` expression may be used, which is useful for optimization and error checking. However, as we mentioned earlier, there is only support for W3C standardized schemas, not Relax NG.

While XQuery is mainly associated with XML, it is possible in newer versions to deal with text documents (like CSV, name/value config files, etc. since 3.0) and even JSON (since 3.1).

### Coding guidelines
MarkLogic has some [XQuery coding guidelines](https://developer.marklogic.com/blog/xquery-coding-guidelines) that are good to follow.

For robustness, it is important to handle missing values (empty sequences) and data variations.

## XML Based Webapps
We've now learned to model (with schemas), transform (with XSLT), and query and process (with XQuery). How can we develop an XML based webapp combining these?

We will take a look at the [Oppidum framework](https://github.com/ssire/oppidum), which targets the development of XML-REST-XQuery (XRX) applications, using the eXist-db XML database.

### XML Databases
An XML database looks quite a lot like a normal database; for instance, it uses a traditional, B-tree based indexing system, has a querying language, etc. The main difference is simply that data is XML instead of a table, and that we use XQuery instead of SQL.

### REST
REST stands for REpresentational State Transfer. It's an architectural style created by Roy Fielding in [his PhD thesis](https://www.ics.uci.edu/~fielding/)

In REST, we have resources, located by a URL on Web-based REST, that may be processed by a client. A collection is simply a set of resources. Interaction with a REST API happens with classical CRUD (Create, Read, Update, Delete) on URLs, which in HTTP are the `POST`, `GET`, `PUT` and `DELETE` requests.

### Oppidum
[Oppidum](https://github.com/ssire/oppidum) is an open source framework to build XML Web-based applications with an MVC approach. The [documentation](https://ssire.github.io/oppidum/docs/fr/guide.html) is only in French, but the core idea is as follows: HTTP requests are handed to Oppidum by eXist. The application logic is then detailed in a pipeline consisting of:

- **Model**: XQuery script (`*.xql`) returning relevant XML content
- **View**: XSLT transformation (`*.xsl`)
- **Epilogue**: XQuery script (`epilogue.xql`) for templating common content in HTML pages; this works using tags with the `site` namespace

To specify the REST architecture, Oppidum has a DSL that allows us to define the set of resources and actions, determine the URLs and associated HTTP verbs (`GET`, `POST`, etc) recognized by the application, and so on.

Oppidum has its own DSL to specify the REST architecture of a webapp:

{% highlight xml linenos %}
<site>
    <item name="contact"/>
    <item name="home" epilogue="standard">
        <model src="modules/home/home.xql"/>
        <view src="modules/home/home.xsl"/>
    </item>
    <item name="books" epilogue="standard"
        collection="topics/home" resource="home.xml"/>
    <collection name="workspaces">
        <item name="foo">
            ...
        </item>
    </collection>
    <collection name="projects" supported="search create"
        method="POST" epilogue="standard"
        collection="workspaces/$2" resource="projcets.xml">
        ...
    </collection>
</site>
{% endhighlight %}

The `item` elements refer to a single resource, with the `name` attribute indicating an URL segment pointing to the resource. We can associate HTTP verbs to the URLs; `GET` is the default.

Longer URLs can be constructed by `collection` elements. In the above, we have a `workspaces/foo` item.

Oppidum also allows us to associate models and views to items, as well as an epilogue (which serves as the template in which we should serve the view). A shortcut is to, instead of defining an XQuery model, just bind the item directly to the XPath of the information we want to send back, as in the `books` element

The `projects` collection shows a more complete example of the fields that can be used for a collection. The positional variable `$2` will be replaced by the 2<sup>nd</sup> segment of the URL.

An epilogue may look like this:

{% highlight xml linenos %}
<html>
    <head> ... </head>
    <body>
        <site:navigation>NAVIGATION</site:navigation>
        <site:content>RESULT OF TRANSFORMATION</site:content>
    </body>
</html>
{% endhighlight %}

All elements in the `site:X` namespace are inserted into the generated page. 

## Foundations of XML types
We've seen seen XML tools for validation (DTD, XML Schema, Relax NG), navigation and extraction (XPath) and transformation (XQuery, XSLT).

Some essential questions about these tools are:

- **Expressive power**: can I express requirement X using XML type language Y?
- **Operations over XML types**: can I check forward-compatibility when my XML file format evolves? Type inclusion?
- **Static type-checking**: can we make my XML manipulating programs will never output an invalid document?

To answer this, we must know more about XML types, and dive into the theoretical foundations of XML types.

### Tree Grammars
XML documents can be modelled by finite, ordered, labeled trees of unbounded depth and arity. To describe a tree, we use a tree language, which can be specified by a tree grammar:

{% highlight antlr linenos %}
Person = person[Name, Gender, Children?]
Name = name[String]
Gender = gender[Male | Female]
Male = male[]
Female = female[]
Children = children[Person+]
{% endhighlight %}

By convention, capitalized variables are **type variables** (non-terminals), and non-capitalized are terminals.

A tree grammar defines a set of legal trees. As any grammar, tree grammars are defined within an alphabet $\Sigma$, with a set of type variables $E := \left\\{X_1 ::= T_1, \dots, X_n ::= T_n\right\\}$. A tree grammar is defined by the pair $(E, X)$, where $X$ represents the starting type variable in $E$. Each $T_i$ is a tree type expression:

{% highlight antlr linenos %}
T ::=
      l[T]     // l ∈ Σ with content model T
    | ()       // empty sequence
    | T1, T2   // concatenation
    | T1 | T2  // choice
    | X        // reference
{% endhighlight %}

The usual regex operators `?`, `+` and `*` are syntactic sugar.

To ensure that our tree grammar remains regular, we must introduce a syntactic restriction: every recursive use of a type variable $X$ (unless it is within the content model) must be in the tail. For instance, the following grammars are not acceptable:

$$
\left\{ X = a, X, b \right\} \\
\left\{ X = a, Y, b; \quad Y = X \right\} \\
$$

But the following are fine:

$$
\left\{ X = a, c[X], b \right\} \\
\left\{ X = a, Y; \quad Y = b, X | \epsilon \right\} \\
$$

A small reminder on regular vs. context-free grammars: regular grammars are decidable (we can check for inclusion with a DFA), while context-free grammars may be undecidable (we cannot check for inclusion in $a^n b^n$ with a DFA, for instance).

Note that regular grammars are a subset of context-free grammars; checking whether a context-free grammar is regular is undecidable.

Within the class of regular grammars, there are three subclasses of interest. Therefore, we have four classes, which are, in order of increasing specificity (each of these is a subset of the classes above):

1. Context-free
2. Regular
3. Single Type
4. Local

Each subclass is defined by additional restrictions compared to its parent. The more restrictions we add, the more expressive power we lose. It turns out that these classes correspond to different XML technologies:

1. **Context-free**: None
2. **Regular**: Relax NG
3. **Single Type**: XML Schema 
4. **Local**: DTD

#### DTD & Local tree grammars
As we said previously, the expressive power of a grammar class is defined by which restriction have been imposed. In DTD, the restriction is that each element name is associated with a regex. This means that for each $a[T_1]$ and $a[T_1]$ occuring in $E$, the content models are identical: $T_1 = T_2$.

In other words, in DTDs, the content of an XML tag cannot depend on the context of the tag. This removes some expressive power.

To construct a DTD validator, we just use a word automaton associated with each terminal. This automaton is a DFA, as DTD requires regular expressions to be deterministic. That is, the matched regexp must be able to be determined without lookahead to the next symbol. `a(bc | bb)` is not deterministic, but `ab(c | b)` is.

As a corollary, the union of two DTDs may not be a DTD. Indeed, the two DTDs could define different content models for the same terminal, which would be illegal. We say that the class is not closed composition (here, we showed that it isn't closed under union).

#### XML Schema & Single-Type tree grammars
In XML Schema, it is possible to have different content models for elements of the same name when they are in different contexts (unlike for DTD). But still, for each $a[T_1]$ and $a[T_2]$ occuring *under the same parent*, the content models must be identical ($T_1 = T_2$).

Still, this bring us more expressive power, so we have $\mathcal{L}\_{\text{DTD}} \subset \mathcal{L}\_{\text{xmlschema}}$. This inclusion is strict, as we can construct grammars that are single-type (and not local) in XML Schema:

{% highlight antlr linenos %}
Dealer = dealer[Used, New]
Used = used[UsedCar]
New = new[NewCar]
UsedCar = car[Model, Year] // here, car can have different content models
NewCar  = car[Model]       // this is allowed as they have different parents
...
{% endhighlight %}

But XML schemas also have weaknesses: we cannot encode more advanced restrictions in it. For instance, with our car dealership example, we cannot encode something like "at least one car has a discount", as it is not a *single-type*; we would require two different content models for a car within the same parent.

Consequently, this class is still not closed under union.

#### Relax NG & Regular tree grammars
Relax NG does not have any of the previously discussed restrictions. The content model does not have to depend on the label of the parent; it can also depend on the ancestor's siblings, for instance. This allows us to have much more expressive power. Relax NG places itself in the class of regular tree grammars, and $\mathcal{L}\_{\text{xmlschema}} \subset \mathcal{L}\_{\text{r}}$.

For instance, we can now encode what we couldn't with XML Schema:

{% highlight antlr linenos %}
Dealer = dealer[Used, New]
Used = used[UsedCar]
New = new[NewCar, DNewCar]
UsedCar = car[Model, Year]
NewCar  = car[Model]  // the same terminal used within 'new'
DNewCar = car[Model, Discount] // but with different content models
...
{% endhighlight %}

Regular tree grammars are more robust (closed under set operations like union and intersection), give us high expressive power, while still remaining simply defined and well-characterized (inclusion can still be verified in linear time by DFA).

### Tree automata

#### Definition
A tree automaton (plural automata) is a state machine dealing with tree structure instead of strings (like a word automaton would). Introducing these will allow us to provide a general framework for XML type languages by giving us a tool with which we can reason about regular tree languages.

A ranked tree can be thought of as the AST representation of a function call. For instance, `f(a, b)` can be represented as a tree with parent node `f` and two children `a` and `b` (in that order). We can also represent more complex trees with these notations (`f(g(a, b, c), h(i))` gives us the full structure of a tree, for instance).

We define a ranked alphabet symbol as a formalization of a function call. It is a symbol $a$, associated with an integer representing the number of children, $\text{arity}(a)$. We write $a^{(k)}$ for the symbol $a$ with $\text{arity}(a) = k$. 

This allows us to fix an arity to different tree symbols. Our alphabet could then be, for instance, $\left\\{ a^{(2)}, b^{(2)}, c^{(3)}, \sharp^{(0)} \right\\}$. In this alphabet, `#` would always be the leaves.

A ranked tree automaton A consists of:

- $F$, a finite ranked alphabet of symbols
- $Q$, a finite set of states
- $\Delta$, a finite set of transition rules
- $Q_f \subseteq Q$, a finite set of final states

In a word automaton, we write transitions as $\text{even} \overset{1}{\rightarrow} \text{odd}$. In a (bottom-up) tree automaton, the transitions are from the children's state to the parents' state. If a tree node has arity 2, a transition could be $(q_0, q_1) \overset{a}{\rightarrow} q_0$. If the arity is $k=0$, we write $\epsilon \overset{a^{(0)}}{\rightarrow} q$. 

#### Example
As an example, we can think of a tree of boolean expressions. Let's consider the following:

$$
((0 \land 1) \lor (1 \lor 0)) \land ((0 \lor 1) \land (1 \land 1))
$$

We can construct this as a binary tree by treating the logical operators as infix notation of a function call:

$$
\land(\lor(\land(0, 1), \lor(1, 0)), \land(\lor(0, 1), \land(1, 1)))
$$

In this case, our alphabet is $F = \left\\{\land, \lor, 0, 1\right\\}$. Our states are $Q = \left\\{ q_0, q_1\right\\}$ (either true or false). The accepting state is $Q_f = \left\\{ q_1 \right\\}$. Our transition rules are:

$$
\begin{align}
\epsilon   \overset{0}{\rightarrow}     q_0 & \quad & \epsilon   \overset{1}{\rightarrow} q_0 \\
(q_1, q_1) \overset{\land}{\rightarrow} q_1 & \quad & (q_1, q_1) \overset{\lor}{\rightarrow} q_1 \\
(q_0, q_1) \overset{\land}{\rightarrow} q_0 & \quad & (q_0, q_1) \overset{\lor}{\rightarrow} q_1 \\
(q_1, q_0) \overset{\land}{\rightarrow} q_0 & \quad & (q_1, q_0) \overset{\lor}{\rightarrow} q_1 \\
(q_0, q_0) \overset{\land}{\rightarrow} q_0 & \quad & (q_0, q_0) \overset{\lor}{\rightarrow} q_0 \\
\\
\end{align}
$$

With these rules in place, we can evaluate binary expressions with a tree automaton.

#### Properties
The language of A is the set of trees accepted by A. For a tree automaton, the language is a **regular tree language**.

A tree automaton is **deterministic** as long as there aren't too rules pointing us to different states:

$$
(q_1, \dots q_k) \overset{a^{(k)}}{\rightarrow} q, \quad
(q_1, \dots q_k) \overset{a^{(k)}}{\rightarrow} q'
\qquad q \ne q'
$$

With word automata, we know that we can build a DFA from any NFA. The same applies to tree automata: from a given non-deterministic (bottom-up) tree automaton, we can build a deterministic tree automaton.

As a corollary, this tells us that non-deterministic tree automata do not give us more expressive power; deterministic and non-deterministic automata recognize the same languages. However, non-deterministic automata tend to allow us to represent languages more compactly (conversion can turn a non-deterministic tree automaton of size $N$ into a deterministic tree automaton of size $\mathcal{O}(2^N$), so we'll use those freely.

### Validation

#### Inclusion
Given a tree automaton A and a tree t, how do we check $t\in\text{Language}(A)$?

What we do is to just mechanically apply the transition rules. If the automaton is non-deterministic, we can keep track of the set of possible states, and see if the root of the tree contains a finishing state. 

This mechanism of membership checking is linear in the size of the tree.

#### Closure
Tree automata are closed under set theoretic operations (we can just compute the union/intersection/product of the tuples defining the trees).


#### Emptiness
We can also do emptiness checking with tree automata (that is, checking if $\text{Language}(A) = \emptyset$). To do so, we compute the set of reachable states, and see if any of them are in $Q_f$. This process is linear in the size of the automaton.

#### Type inclusion
Given two automata $A_1$ and $A_2$, how can we check $\text{Language}(A_1) \subseteq \text{Language}(A_2)$? 

Containment of a non-deterministic automata can be decided in exponential time. We do this by checking whether $\text{Language}(A_1 \cap \bar{A_2}) = \emptyset$. For this, we must make $A_2$ deterministic (which is an exponential process).

## Dealing with non-textual content
So far, we've just been dealing with text. In the following, we'll see how we can deal with images, graphics, sound, video, animations, etc. For these types of data, semi-structured tree data is commonly used for its flexibility, while retaining rigorous structures and data typing. 

For instance, there are many application-specific markup languages (MathML, CML for chemistry, GraphML, SVG tables, etc).

### MathML
MathML actually has two possible structures: a presentation structure, telling us how to display math, and a mathematical structure, telling us how to apply or compute the result of a mathematical expression. It's possible to go from mathematical to presentation structure, but not the other way (the other way is too ambiguous, it's not a bijection).

### Tables
This distinction between content and presentation also exists within tables. For instance, creating the presentation and layout of a calendar, or of a complex table, is quite difficult because of the discrepancy between the presentation and structural forms.

The main issues with tables are:

- How can we model it in such a way that variations in presentation only depends on values of the formatting attributes? 
- How can we edit a table? (How do we modify the structure and update the backing content?)

From a logical point of view, we can view a table as a d-dimensional space. A simple row-column table is 2D, but we can "add dimensions" by adding subdivision headers. Each cell in the table is described by a d-dimensional tuple of coordinates. How can we use a tree model to represent this? 

We can use tree of height d, but more efficiently (or at least, flatly), we could encode each dimension as a direct child of the root, and link each data point to the relevant axes.

This is what HTML 4 proposes:

{% highlight html linenos %}
<tr>
    <th></th>
    <th id="a2" axis="expenses">Meals</th>
    <th id="a3" axis="expenses">Hotels</th>
    <th id="a4" axis="expenses">Transport</th>
    <td>subtotals</td>
</tr>
<tr>
    <th id="a6" axis="location">San Jose</th>
    <th></th>
    <th></th>
    <th></th>
    <td></td>
</tr>
<tr>
    <td id="a7" axis="date">25-Aug-97</td>
    <td headers="a6 a7 a2">37.74</td>
    <td headers="a6 a7 a3">112.00</td>
    <td headers="a6 a7 a4">45.00</td>
    <td></td>
</tr>
{% endhighlight %}

## XML Processing
When working with XML, there's no need to write a parser. General-purpose XML parsers are widely available (e.g. Apache Xerces). Incidentally, an XML parser can be validating or non-validating.

XML parsers can communicate the XML tree structure to applications using it; there are two approaches for this:

- DOM: the parser stores the XML input to a fixed data structure, and exposes an API
- SAX: parser trigger events. The input isn't stored, the application must specify how to store and process events triggered by the parser.

### DOM
DOM (Document Object Model) is a W3C standard. An application generates DOM library calls to manipulate the parsed XML input. There are multiple DOM levels, that have been introduced successively to expand the capabilities of DOM.

- DOM Level 1 provided basic API to access and manipulate tree structures (`getParentNode()`, `getFirstChild()`, `insertBefore()`, `replaceChild()`, ...)
- DOM Level 2 introduces specialized interfaces dedicated to XM Land namespace-related methods, dynamic access and update of the content of style sheets, an event system, ...
- DOM Level 3 introduces the ability to dynamically load the content of an XML document into a DOM document, serialize DOM into XML, dynamically update the content while ensureing validation, access the DOM using XPath, ...

DOM allows us to abstract away from the syntactical details of the XML structure, and allows us to ensure well-formedness (no missing tags, non-matching tags, etc). Thanks to that, document manipulation is considerably simplified.

However, the DOM approach is not without its flaws. The main disadvantage is that we must maintain a data structure representing the whole XML input, which can be problematic for big documents. To remedy this situation, we can preprocess to filter the document, reducing its overall size, but that only takes us so far. Alternatively, we can use a different approach for XML processing: SAX.

### SAX
SAX, the [Simple API for XML](http://www.saxproject.org/) is not a W3C standard; it's more of a de facto standard that started out as a Java-only API.

It's very efficient, using only constant space, regardless of the XML input size. However, it means that we must also write more code. Indeed, we must specify callbacks for certain events, write our own code to store what we need, etc.

The SAX processor reads the input sequentially (while the DOM afforded us with random access), and once only. It sends events like `startDocument`, `startElement`, `characters`, etc. White spaces and tabs are reported too, so this also potentially means more code to write.

### DOM and web applications
DOM is language and platform independent, with DOM APIs for all major programming languages. Most common though, is the DOM API used with JavaScript. 

### XForms: an alternative to HTML forms
XForms give us a declarative approach to capture information from the user, and place it into XML documents, with constraint checking. XForms are a W3C standard, but are not implemented in the browsers.

## Web Services
Service oriented applications (SOA) is an architectural pattern in software design, in which each component provides services to other components via communication protocols. XML has an answer to this:

### Web Service Description Language (WSDL)
WSDL is a language to create descriptions of a web service. That is, describe the operations it can perform, the structure of its messages, communication mechanisms it understands, etc. This is a [W3C recommendation](https://www.w3.org/TR/2007/REC-wsdl20-20070626/) since 2007.

Inside a `<wsdl:description>` tag, we can use:

- Optional documentation (`<wsdl:documentation/>`), with a human readable description of the web service
- Definition of data types (`<wsdl:types/>`) exchanged between client and web service 
- Description of the interface (`<wsdl:interface/>`), i.e. what operations and messages are defined
- Binding (`<wsdl:binding/>`) describing how the web service is accessed over the network
- Service tag (`<wsdl:service`) describing where the service can be accessed

Here's an example from IBM:

{% highlight xml linenos %}
<application xmlns="http://wadl.dev.java.net/2009/02">
    <resources base="http://example.com/api">
        <resource path="books">
            <method name="GET"/>
            <resource path="{bookId}">
                <param required="true" style="template" name="bookId"/>
                <method name="GET"/>
            </resource>
        </resource>
    </resources>
</application>
{% endhighlight %}

### Simple Object Access Protocol (SOAP)
SOAP is a W3C standard protocolSOAP is a W3C standard protocol, with strict rules and advanced security features. However, it comes with substantial complexity, leading to slow page load times.

{% highlight plain linenos %}
POST /Quotation HTTP/1.0
Host: www.xyz.org
Content-Type: text/xml; charset = utf-8
Content-Length: nnn

<?xml version = "1.0"?>
<SOAP-ENV:Envelope
    xmlns:SOAP-ENV = "http://www.w3.org/2001/12/soap-envelope"
    SOAP-ENV:encodingStyle = "http://www.w3.org/2001/12/soap-encoding">
        <SOAP-ENV:Body xmlns:m = "http://www.xyz.org/quotations">
            <m:GetQuotation>
                <m:QuotationsName>MiscroSoft</m:QuotationsName>
            </m:GetQuotation>
        </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
{% endhighlight %}

Note that while REST is an architectural style, and SOAP is a protocol. REST allows using any format (HTML, JSON, XML, plain text, ...), while SOAP explicitly only allows XML. 

In the days of web apps (instead of web services), the idea of WDSL may be a little outdated. But WADL (Web **Application** Description Language) may be an answer to WSDL; this is a more concise language, with support for Relax NG, but which also has a slightly different goal. [Open API](https://www.openapis.org/) is another contender in this field, specifying a way to describe web services in JSON or YAML, with documentation in Markdown.

### Universal Description, Discovery and Integration (UDDI)
UDDI defines a standard method for **publishing** and **discovering** the software components of a service-oriented architecture. This mechanism still exists, although it never had the success people had been hoping for. Nowadays, it's mostly just used internally for some XML based applications, instead of in public UDDI repositories of components.
