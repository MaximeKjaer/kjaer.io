# -*- coding: utf-8 -*- #
# frozen_string_literal: true

require 'rouge'

module Rouge
  module Lexers
    class XPath < RegexLexer
      title 'XPath'
      desc 'XML Path Language (XPath) 3.1'
      tag 'xpath'
      filenames '*.xpath'

      # Terminal literals:
      # https://www.w3.org/TR/xpath-31/#terminal-symbols

      digits = /[0-9]+/
      decimalLiteral = /\.#{digits}|#{digits}\.[0-9]*/
      doubleLiteral = /(\.#{digits})|#{digits}(\.[0-9]*)?[eE][+-]?#{digits}/
      stringLiteral = /("(("")|[^"])*")|('(('')|[^'])*')/

      ncName = /[a-z_][a-z_\-.0-9]*/i
      qName = /(?:#{ncName})(?::#{ncName})?/
      uriQName = /Q{[^{}]*}#{ncName}/
      eqName = /(?:#{uriQName}|#{qName})/

      commentStart = /\(:/
      openParen    = /\((?!:)/

      # Terminal symbols:
      # https://www.w3.org/TR/xpath-30/#id-terminal-delimitation

      kindTest = Regexp.union(%w(
        element attribute schema-element schema-attribute
        comment text node document-node namespace-node
      ))
      kindTestForPi = Regexp.union(%w(processing-instruction))
      axes = Regexp.union(%w(
        child descendant attribute self descendant-or-self
        following-sibling following namespace
        parent ancestor preceding-sibling preceding ancestor-or-self
      ))
      operators = Regexp.union(%w(, => = := : >= >> > <= << < - * != + // / || |))
      keywords = Regexp.union(%w(let for some every if then else return in satisfies))
      word_operators = Regexp.union(%w(
        and or eq ge gt le lt ne is
        div mod idiv
        intersect except union
        to
      ))
      constructorTypes = Regexp.union(%w(function array map empty-sequence))

      # Lexical states:
      # https://www.w3.org/TR/xquery-xpath-parsing/#XPath-lexical-states
      # https://lists.w3.org/Archives/Public/public-qt-comments/2004Aug/0127.html
      # https://www.w3.org/TR/xpath-30/#id-revision-log
      # https://www.w3.org/TR/xpath-31/#id-revision-log

      state :root do
        # Comments
        rule commentStart, Comment, :comment

        # Literals
        rule doubleLiteral, Num::Float
        rule decimalLiteral, Num::Float
        rule digits, Num
        rule stringLiteral, Literal::String

        # Variables
        rule /\$/, Name::Variable, :varname

        # Operators
        rule operators, Operator
        rule /\b#{word_operators}\b/, Operator::Word
        rule /\b#{keywords}\b/, Keyword
        rule /[?,{}()\[\]]/, Punctuation

        # Functions
        rule /(function)(\s*)(#{openParen})/ do # function declaration
          groups Keyword, Text, Punctuation
        end
        rule /(map|array|empty-sequence)/, Keyword # constructors
        rule /(#{kindTest})(\s*)(#{openParen})/ do  # kindtest
          push :kindtest
          groups Keyword, Text, Punctuation
        end
        rule /(#{kindTestForPi})(\s*)(#{openParen})/ do # processing instruction kindtest
          push :kindtestforpi
          groups Keyword, Text, Punctuation
        end
        rule /(#{eqName})(\s*)(#{openParen})/ do # function call
          groups Name::Function, Text, Punctuation
        end
        rule /(#{eqName})(\s*)(#)(\s*)(#{digits})/ do # namedFunctionRef
          groups Name::Function, Text, Name::Function, Text, Name::Function
        end

        # Type commands
        rule /(cast|castable)(\s+)(as)/ do
          goto :singletype
          groups Keyword, Text, Keyword
        end
        rule /(treat)(\s+)(as)/ do
          goto :itemtype
          groups Keyword, Text, Keyword
        end
        rule /(instance)(\s+)(of)/ do
          goto :itemtype
          groups Keyword, Text, Keyword
        end
        rule /\b(as)\b/ do
          token Keyword
          goto :itemtype
        end

        # Paths
        rule /\.\.|\.|\*/, Operator
        rule /(#{ncName})(\s*)(:)(\s*)(\*)/ do
          groups Name::Tag, Text, Punctuation, Text, Keyword::Reserved
        end
        rule /(\*)(\s*)(:)(\s*)(#{ncName})/ do
          groups Keyword::Reserved, Text, Punctuation, Text, Name::Tag
        end
        rule /(#{axes})(\s*)(::)/ do
          groups Keyword, Text, Operator
        end
        rule /@/, Name::Attribute, :attrname
        rule eqName, Name::Tag

        # Whitespace
        rule /(\s+)/m, Text
      end

      state :singletype do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Type name
        rule eqName do
          token Keyword::Type
          goto :root
        end
      end

      state :itemtype do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Type tests
        rule /(#{kindTest})(\s*)(#{openParen})/ do
          groups Keyword::Type, Text, Punctuation
          # go to kindtest then occurrenceindicator
          goto :occurrenceindicator
          push :kindtest
        end
        rule /(#{kindTestForPi})(\s*)(#{openParen})/ do
          groups Keyword::Type, Text, Punctuation
          # go to kindtestforpi then occurrenceindicator
          goto :occurrenceindicator
          push :kindtestforpi
        end
        rule /(item)(\s*)(#{openParen})(\s*)(\))/ do
          goto :occurrenceindicator
          groups Keyword::Type, Text, Punctuation, Text, Punctuation
        end
        rule /(#{constructorTypes})(\s*)(#{openParen})/ do
          groups Keyword::Type, Text, Punctuation
        end

        # Type commands
        rule /(cast|castable)(\s+)(as)/ do
          groups Keyword, Text, Keyword
          goto :singletype
        end
        rule /(treat)(\s+)(as)/ do
          groups Keyword, Text, Keyword
          goto :itemtype
        end
        rule /(instance)(\s+)(of)/ do
          groups Keyword, Text, Keyword
          goto :itemtype
        end
        rule /\b(as)\b/, Keyword

        # Operators
        rule operators do
          token Operator
          goto :root
        end
        rule /\b#{word_operators}\b/ do
          token Operator::Word
          goto :root
        end
        rule /\b#{keywords}\b/ do
          token Keyword
          goto :root
        end
        rule /[\[),]/ do
          token Punctuation
          goto :root
        end

        # Other types (e.g. xs:double)
        rule eqName do
          token Keyword::Type
          goto :occurrenceindicator
        end
      end

      # For pseudo-parameters for the KindTest productions
      state :kindtest do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Pseudo-parameters:
        rule /[?*]/, Operator
        rule /,/, Punctuation
        rule /(element|schema-element)(\s*)(#{openParen})/ do
          push :kindtest
          groups Keyword::Type, Text, Punctuation
        end
        rule eqName, Name::Tag

        # End of pseudo-parameters
        rule /\)/, Punctuation, :pop!
      end

      # Similar to :kindtest, but recognizes NCNames instead of EQNames
      state :kindtestforpi do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Pseudo-parameters
        rule ncName, Name
        rule stringLiteral, Literal::String

        # End of pseudo-parameters
        rule /\)/, Punctuation, :pop!
      end

      state :occurrenceindicator do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Occurrence indicator
        rule /[?*+]/ do
          token Operator
          goto :root
        end

        # Otherwise, lex it in root state:
        rule /(?![?*+])/ do
          goto :root
        end
      end

      state :varname do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Function call
        rule /(#{eqName})(\s*)(#{openParen})/ do
          groups Name::Variable, Text, Punctuation
          pop!
        end

        # Variable name
        rule eqName, Name::Variable, :pop!
      end

      state :attrname do
        # Whitespace and comments
        rule /\s+/m, Text
        rule commentStart, Comment, :comment

        # Attribute name
        rule eqName, Name::Attribute, :pop!
        rule /\*/, Operator, :pop!
      end

      state :comment do
        # Comment end
        rule /:\)/, Comment, :pop!

        # Nested comment
        rule commentStart, Comment, :comment

        # Comment contents
        rule /[^:(]+/m, Comment
        rule /[:(]/, Comment
      end
    end
  end
end


module Rouge
  module Lexers
    class XQuery < XPath
      title 'XQuery'
      desc 'XQuery 3.1: An XML Query Language'
      tag 'xquery'
      filenames '*.xquery', '*.xq'
      mimetypes 'application/xquery'

      # Terminal literals:
      ncName = /[a-z_][a-z_\-.0-9]*/i
      qName = /(?:#{ncName})(?::#{ncName})?/
      uriQName = /Q{[^{}]*}#{ncName}/
      eqName = /(?:#{uriQName}|#{qName})/
      commentStart = /\(:/

      keywords = Regexp.union(%w(
        xquery encoding version declare module
        namespace copy-namespaces boundary-space construction
        default collation base-uri preserve strip
        ordering ordered unordered order empty greatest least
        preserve no-preserve inherit no-inherit
        decimal-format decimal-separator grouping-separator
        infinity minus-sign NaN percent per-mille
        zero-digit digit pattern-separator exponent-separator
        import schema at element option
        function external context item
        typeswitch switch case
        try catch
        validate lax strict type
        document element attribute text comment processing-instruction
        for let where order group by return
        allowing tumbling stable sliding window
        start end only when previous next count collation
        ascending descending
      ))

      state :tags do
        rule /<#{qName}/, Name::Tag, :start_tag
        rule /<!--/, Comment, :xml_comment
        rule /<\?.*?\?>/, Comment::Preproc
        rule /<!\[CDATA\[.*?\]\]>/, Comment::Preproc
        rule /&\S*?;/, Name::Entity
      end

      prepend :root do
        mixin :tags

        rule /{/, Punctuation, :root
        rule /}(`)?/ do
          token Punctuation
          if stack.length > 1
            pop!
          end
        end

        rule /(namespace)(\s+)(#{ncName})/ do
          groups Keyword, Text, Name::Namespace
        end

        rule /\b(#{keywords})\b/, Keyword
        rule /;/, Punctuation
        rule /%/, Keyword::Declaration, :annotation

        rule /(\(#)(\s*)(#{eqName})/ do
          push :pragma
          groups Comment::Preproc, Text, Name::Tag
        end

        rule /``\[/, Str, :str_constructor
      end

      state :annotation do
        rule /\s+/m, Text
        rule commentStart, :comment
        rule eqName, Keyword::Declaration, :pop!
      end

      state :pragma do
        rule /\s+/m, Text
        rule commentStart, :comment
        rule /#\)/, Comment::Preproc, :pop!
        rule /./, Comment::Preproc
      end

      # https://www.w3.org/TR/xquery-31/#id-string-constructors
      state :str_constructor do
        rule /`{/, Punctuation, :root
        rule /\]``/, Str, :pop!
        rule /[^`\]]+/m, Str
        rule /[`\]]/, Str
      end

      state :xml_comment do
        rule /[^-]+/m, Comment
        rule /-->/, Comment, :pop!
        rule /-/, Comment
      end

      state :start_tag do
        rule /\s+/m, Text
        rule /([\w.:-]+\s*=)(")/m do
          push :quot_attr
          groups Name::Attribute, Str
        end
        rule /([\w.:-]+\s*=)(')/m do
          push :apos_attr
          groups Name::Attribute, Str
        end
        rule />/, Name::Tag, :tag_content
        rule %r(/>), Name::Tag, :pop!
      end

      state :quot_attr do
        rule /"/, Str, :pop!
        rule /{{/, Str
        rule /{/, Punctuation, :root
        rule /[^"{>]+/m, Str
      end

      state :apos_attr do
        rule /'/, Str, :pop!
        rule /{{/, Str
        rule /{/, Punctuation, :root
        rule /[^'{>]+/m, Str
      end

      state :tag_content do
        rule /\s+/m, Text
        mixin :tags

        rule /({{|}})/, Text
        rule /{/, Punctuation, :root

        rule /[^{}<&]/, Text

        rule %r(</#{qName}(\s*)>) do
          token Name::Tag
          pop! # pop self
          pop! # pop tag_start
        end
      end
    end
  end
end