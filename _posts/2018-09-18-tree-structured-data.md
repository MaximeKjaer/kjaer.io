---
title: CS-525 Foundations and tools for tree-structured data
description: "My notes from the CS-525 course given at EPFL, in the 2018 autumn semester (MA1)"
edited: true
unlisted: true
---

## XPath
XPath is the W3C standard language for traversal and navigation in XML trees.

For navigation, we use the **location path** to identify nodes or content. A location path is a sequence of location steps separated by a `/`:

{% highlight xpath linenos %}
child::chapter/descendant::section/child::para
{% endhighlight %}

Every location step has an axis, `::` and then a node test. Starting from a context node, a location returns a node-set. Every selected node in the node-set is used as the context node for the next step. 

You can start an XPath expression with `/` start from the root, which is known as an **absolute path**.

XPath defines 13 axes allowing navigation, including `self`, `parent`, `child`, `following-sibling`, `ancestor-or-self`, etc. There is a special `attribute` axis to select attributes of the context node, which are not really in the child hierarchy. Similarly, `namespace` selects namespace nodes.

A nodetest filters nodes:

| Test     | Semantics     |
| :------------- | :------------- |
| `node()`       | let any node pass       |
| `text()`      | select only text nodes  |
| `comment()`   | preserve only comment nodes |
| `name`         | preserves only **elements/attributes** with that name |
| `*` | `*` preserves every **element/attribute** |

At each navigation step, nodes can be filtered using qualifiers. 

{% highlight xpath linenos %}
axis::nodetest[qualifier][qualifier]
{% endhighlight %}

For instance:

{% highlight xpath linenos %}
following-sibling::para[position()=last()]
{% endhighlight %}

A qualifier filters a node-set depending on the axis. Each node in a node-set is kept only if the evaluation of the qualifier returns true.

Qualifiers may include comparisons (`=`, `<`, `<=`, ...). The comparison is done on the `string-value()`, which is the concatenation of all descendant text nodes in *document order*. But there's a catch here! Comparison between node-sets is under existential semantics: there only needs to be one pair of nodes for which the comparison is true. Thus, when negating, we can get universal quantification.  

XPaths can be a union of location paths separated by `|`. Qualifiers can include boolean expressions (`or`, `not`, `and`, ...). 

XPath also has support for for variables, denoted `$x` (which are more like constants):



{% highlight xpath linenos %}
let $FREvents := /RAS/Events/Event[Canton/text() = "FR"],
    $FRTopics := $FREvents/TopicRef/text() 

return /RAS/Members/Member[Topics/TopicRef/text() = $FRTopics]/Email
{% endhighlight %}

> 👉 This gives us the email addresses of reporters who may deal with events in the canton of Fribourg. See exercises 01 for more context.

There are a few basic functions: `last()`, `position()`, `count(node-set)`, `concat(string, string, ...string`), `contains(str1, str2)`, etc. These can be used within a qualifier.

XPath also supports abbreviated syntax. For instance, `child::` is the default axis and can be omitted, `@` is a shorthand for `attribute::`, `[4]` is a shorthand for `[position()=4]` (note that positions start at 1).

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

Document Type Definitions (DTDs) are XML’s native schema system. It allows to define document classes, using a declarative approach to define the logical structure of a document.

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

This defines a Prolog type containing a sequence of a `series`, `author`, and `Characters`, which is `character+`. 

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

There have been some criticisms addressed to XML Schema:

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

In addition to datatypes, we can also express admissible XML *content* using regexes, but (and this is important!) **we cannot exprain cardinality constraints or uniqueness constraints**. 

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
The purpose of [XML Information Set](https://msdn.microsoft.com/en-us/library/aa468561.aspx), or Infoset, is to "purpose is to provide a consistent set of definitions for use in other specifications that need to refer to the information in a well-formed XML document[^infoset-spec]".

[^infoset-spec]: [XML Information Set specification](https://www.w3.org/TR/xml-infoset/), W3C Recommendation

It specifies a standardized, abstract model to represent the properties of XML trees. The goal is to provide a standardized viewpoint for the implementation and description of various XML technologies.

It functions like an AST for XML documents. It's abstract in the sense that it abstract away from the concrete encoding of data, and just retains the meaning. For instance, it doesn't distinguish between the two forms of the empty element; the following pairs are considered equivalent.

{% highlight xml linenos %}
<element></element>
<element/>

<element attr="example"/>
<element attr='example'/>
{% endhighlight %}

The Information Set is described as a tree of information items, which are simply blocks of information about a node in the tree; every information item is an abstract representation of a component in an XML document. 

As such, at the root we have a document information item, which, most importantly, contains a list of children, which is a list of information items, in document order. Information items for elements contain a local name, the name of the namespace, a list of attribute information items, which contain the key and value of the attribute, etc.



