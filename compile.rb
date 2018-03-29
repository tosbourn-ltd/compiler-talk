# Lexer (Tokenizer) (turns strings into tokens)
class Tokenizer

  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:identifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:open_paren, /\(/],
    [:close_paren, /\)/],
    [:comma, /\,/]
  ]

  def initialize(code)
    @code = code
  end

  def tokenize
    tokens = []
    tokens << grab_one_token until @code.empty?
    tokens
  end

  def grab_one_token
    @code = @code.strip
    TOKEN_TYPES.each do |type, re|
      if @code =~ /\A(#{re})/
        @code = @code[$1.length..-1]
        return Token.new(type, $1)
      end
    end
    raise RuntimeError.new("Couldn't find token for #{@code.inspect}")
  end
end

Token = Struct.new(:type, :value)

tokens = Tokenizer.new(File.read('source')).tokenize
puts tokens

# Parser (takes the tokens and turns them into an intermediate representation)
class Parser
end

# tree = Parser.new(tokens).parse
# puts tree

# Code Generator (takes the intermediate representation and generates new code from it)
class Generator
  def generate(node)
    case node
    when DefNode
      "function %s(%s) { return %s }" % [
        node.name,
        node.argument_names.join(','),
        generate(node.body)
      ]
    when CallNode
      "%s(%s)" % [
        node.name,
        node.argument_expressions.map do |arg_exp|
          generate(arg_exp)
        end.join(",")
      ]
    when VariableNode
      node.value
    when IntegerNode
      node.value
    else
      raise RuntimeError.new("Unexpected Node Type #{node.class}")
    end
  end
end

# puts Generator.new.generate(tree)
