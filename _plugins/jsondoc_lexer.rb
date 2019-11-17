# -*- coding: utf-8 -*- #
# frozen_string_literal: true

require 'rouge'

module Rouge
  module Lexers
    load_lexer 'json.rb'
    
    class JSONDOC < JSON
      desc "JavaScript Object Notation with extensions for documentation"
      tag 'json-doc'

      state :comments do
        rule %r(/[*].*?[*]/), Comment
        rule %r(//.*?$), Comment::Single
        rule %r/(\.\.\.)/, Comment::Single
      end

      prepend :value do
        mixin :comments
      end

    end
  end
end
