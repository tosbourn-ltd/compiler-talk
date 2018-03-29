## Tokenizer

1. Start with commented out Tokenizer, Parser, Code Generator
2. Show `source` of

```
def method()
  1
end
```
3. Create empty Tokenizer class
4. Create a debug line `tokens = Tokenizer.new(File.read('source')).tokenize`
5. Watch it fail
6. Create initialize method to store @code away
7. Create tokenize method
```
def tokenize
  tokens = []
  tokens << grab_one_token until @code.empty?
  tokens
end
```
8. Create TOKEN_TYPES **explain why order is important and regex**
```
TOKEN_TYPES = [
  [:def, /\bdef\b/],
  [:end, /\bend\b/],
  [:identifier, /\b[a-zA-Z]+\b/],
  [:integer, /\b[0-9]+\b/],
  [:oparen, /\(/],
  [:cparen, /\)/],
]
```
9. Create grab_one_token
```
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
```
10. **explain the \A super hat (that basically) we don't want start of line, we want start of string**
11. We construct a Token so we need `Token = Struct.new(:type, :value)`
12. Run through the tokenizer code, showing the output

## Parser

1. Write `tree = Parser.new(tokens).parse` as debug code
2. Before writing `parse` method, reiterate that we care about making sense of the tokens now
3. Point out in our example source files will only ever have one def function
4. Write out the main things we care about (name, arguments, body)
5. ```
def parse
  consume(:def)
  name = consume(:identifier).value
  argument_names = parse_arguments
  body = parse_body
  consume(:end)
  DefNode.new(name, argument_names, body)
end
```
6. Write consume method
```
def consume(expected_token)
  token = @tokens.shift
  if token.type == expected_token
    token
  else
    raise RuntimeError.new("expected token type #{expected_token.inspect} but got #{token.type.inspect}")
  end
end
```
7. Parse some argument_names
```
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
```
8. Create the peek method.
```
def peek(expected_token, index=0)
  @tokens[index].type == expected_token
end
```
9. Go back and add comma as into regex
10. Parse method_body
```
def parse_body
  if peek(:integer)
    parse_integer
  elsif peek(:identifier) && peek(:open_paren, 1)
    parse_call
  else
    parse_variable
  end
end
```
11. Note that the struct we get out `DefNode = Struct.new(:name, :argument_names, :body)` contains all our tokens, we don't want that, use `.value` and `IntegerNode` to fix.
12. Now lets make our method body do something interesting
13. Create a call node `CallNode = Struct.new(:name, :argument_expressions)`, set it in `parse_call`. Name will be the call name, argument_expressions will be result of `parse_argument_expressions`
```
def parse_call
  name = consume(:identifier).value
  argument_expressions = parse_argument_expressions
  CallNode.new(name, argument_expressions)
end
```
14. Create a `parse_argument_expressions` method to parse the arguments.
```
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
```
15. We need to be able to handle variables being passed in, lets edit our `parse_body` to suit
```
def parse_body
  if peek(:integer)
    parse_integer
  elsif peek(:identifier) && peek(:open_paren, 1)
    parse_call
  else
    parse_variable
  end
end
```
16. This needs
```
def parse_variable
  VariableNode.new(consume(:identifier).value)
end
```

## Code Generator

0. Lets set our source to

```
def method(x,y,z)
  test(x, 1, x())
end
```

1. Time to generate our code `puts Generator.new.generate(tree)`
```

class Generator
  def generate(node)
    case node
    when 1
      1
    else
      raise RuntimeError.new("Unexpected Node Type #{node.class}")
    end
  end
end
```

2. Now lets handle the DefNode

```
when DefNode
  "function %s(%s) { return %s}" % [
    node.name,
    node.argument_names.join(','),
    generate(node.body)
  ]
```

3. Now we need a CallNode

```
when CallNode
"%s(%s)" % [
  node.name,
  node.argument_expressions.map do |arg_exp|
    generate(arg_exp)
  end.join(",")
]
```

4. Finally we need Variable and Integer Nodes

```
when VariableNode
  node.value
when IntegerNode
  node.value

```
