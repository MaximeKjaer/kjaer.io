require 'rouge'

module Rouge
	module Lexers
		class DAPseudo < RegexLexer
			title 'Distributed Algorithms Pseudocode'
			desc 'Pseudocode format used in the Distributed Algorithms CS-451 class at EPFL'
			tag 'dapseudo'

			def self.keywords
				@keywords ||= %w(
					upon event do trigger 
					if else while for forall any
					exists such that					
				)
			end

			def self.builtins
				@builtins ||= %w(
					Implements Uses Events Properties
					Request Indication
				)
			end

			def self.builtins_pseudo
				@builtins_pseudo ||= %w(
					true false nil ∅ Π self
				)
			end

			identifier = /[a-z_][a-z0-9_]*/i
			digits = /[0-9]+/
			whitespace = /\s+/

			state :root do
				rule /[^\S\n]+/, Text

				rule /(:)(#{whitespace})(<)/ do 
					groups Punctuation, Text::Whitespace, Punctuation
					push :eventname
				end

				rule /(event|trigger)(#{whitespace})(<)/ do
					groups Keyword, Text::Whitespace, Punctuation
					push :eventname
				end

				rule /(def)(#{whitespace})(#{identifier})/ do
					groups Keyword, Text::Whitespace, Name::Function
				end
				
				rule digits, Num::Integer

				rule /[\[\]{}:(),\.;\>]/, Punctuation

				rule %r(#(.*)?\n?), Comment::Single

				rule /(in|is|and|or|not)\b/, Operator::Word
				rule /(\\|:=|!=|<=)/, Operator
				rule /[∉∈∪⊆⊂=\-\+\*\/]/, Operator

				rule identifier do |m|
					if self.class.keywords.include? m[0]
						token Keyword
					elsif self.class.builtins_pseudo.include? m[0]
						token Name::Builtin::Pseudo
					elsif self.class.builtins.include? m[0]
					 	token Name::Builtin
					else
						token Name
					end
				end

			end

			state :eventname do
				rule identifier, Name::Class, :pop!
			end
		end
	end
end

