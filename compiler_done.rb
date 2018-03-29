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

# puts tokens

# Parser (takes the tokens and turns them into an AST)

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    consume(:def)
    name = consume(:identifier).value
    argument_names = parse_arguments
    body = parse_body
    consume(:end)
    DefNode.new(name, argument_names, body)
  end

  def parse_arguments
    argument_names = []
    consume(:open_paren)
    if peek(:identifier)
      argument_names << consume(:identifier).value
      while peek(:comma)
        consume(:comma)
        argument_names << consume(:identifier).value
      end
    end
    consume(:close_paren)
    argument_names
  end

  def parse_body
    if peek(:integer)
      parse_integer
    elsif peek(:identifier) && peek(:open_paren, 1)
      parse_call
    else
      parse_variable
    end
  end

  def parse_variable
    VariableNode.new(consume(:identifier).value)
  end

  def parse_call
    name = consume(:identifier).value
    argument_expressions = parse_argument_expressions
    CallNode.new(name, argument_expressions)
  end

  def parse_argument_expressions
    argument_expressions = []
    consume(:open_paren)
    if !peek(:close_paren)
      argument_expressions << parse_body
      while peek(:comma)
        consume(:comma)
        argument_expressions << parse_body
      end
    end

    consume(:close_paren)
    argument_expressions
  end

  def parse_integer
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def consume(expected_token)
    token = @tokens.shift
    if token.type == expected_token
      token
    else
      raise RuntimeError.new("expected token type #{expected_token.inspect} but got #{token.type.inspect}")
    end
  end

  def peek(expected_token, index=0)
    @tokens[index].type == expected_token
  end
end

DefNode = Struct.new(:name, :argument_names, :body)
IntegerNode = Struct.new(:value)
CallNode = Struct.new(:name, :argument_expressions)
VariableNode = Struct.new(:value)

tree = Parser.new(tokens).parse

# puts tree

# Code Generator (takes the AST and generates new code from it)

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

puts "function add(x,y) { return x + y };" + Generator.new.generate(tree) + " console.log(method(1,2));"
