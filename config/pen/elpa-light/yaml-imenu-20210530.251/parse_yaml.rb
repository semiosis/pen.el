require 'yaml'
require 'json'

def main
  parsed =
    begin
      parse(YAML.parse(ARGF).children.first) || {}
    rescue => e
      STDERR.puts e.message
      {}
    end

  puts JSON.pretty_generate(parsed)
end

def parse(node, current_path = nil)
  case node
  when Psych::Nodes::Scalar, Psych::Nodes::Alias
    nil
  when Psych::Nodes::Mapping
    initial =
      if current_path
        { current_path => node.start_line }
      else
        {}
      end

    node.children.each_slice(2).reduce(initial) { |hash, (ykey, yvalue)|
      key =
        case ykey
        when Psych::Nodes::Scalar
          case o = ykey.value
          when Symbol
            ":#{o}"
          else
            o.to_s
          end
        else
          next hash
        end

      if value = parse(yvalue, "#{current_path}#{'.' if current_path}#{key}")
        hash.merge(value)
      else
        hash
      end
    }
  when Psych::Nodes::Sequence
    initial =
      if current_path
        { current_path => node.start_line }
      else
        {}
      end

    node.children.each_with_index.reduce(initial) { |hash, (yvalue, i)|
      if value = parse(yvalue, "#{current_path}[#{i}]")
        hash.merge(value)
      else
        hash
      end
    }
  end
end

main
