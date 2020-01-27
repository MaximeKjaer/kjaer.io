module Jekyll
    class BlockTag < Liquid::Block
        def initialize(tag_name, text, tokens)
            @type, @title = text.match(/\s*(\w+)\s+(?:\"(.*)\".*)?/im).captures
            super
        end

        def render(context)
            text = super
            if @title
                id = @type.downcase() + ':' + Jekyll::Utils.slugify(@title)
                "<div class=\"block #{@type}\" id=\"#{id}\" markdown=\"block\">" +
                    "<a class=\"header\" href=\"##{id}\">#{@type.capitalize()}: #{@title} </a>\n" + 
                    text +
                "\n</div>"
            else
                "<div class=\"block #{@type}\" markdown=\"block\"><span class=\"header\">#{@type.capitalize()}</span>\n#{text}\n</div>"
            end
        end
        
    end
end

Liquid::Template.register_tag('block', Jekyll::BlockTag)
