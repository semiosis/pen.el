#!/usr/bin/ruby -w

# https://stackoverflow.com/q/4078906

class String
  def naturalized
    scan(/[^\d\.]+|[\d\.]+/).collect { |f| f.match(/\d+(\.\d+)?/) ? f.to_f : f }
  end
end

# This actually produces a vector which the sort_by! function uses
# irb:
#     "https://stackoverflow.com/q/4078906".scan(/[^\d\.]+|[\d\.]+/).collect { |f| f.match(/\d+(\.\d+)?/) ? f.to_f : f }
#     ["https://stackoverflow", ".", "com/q/", 4078906.0]

lines = STDIN.read.split("\n")
lines.sort_by! { |line| line.naturalized }
lines.each do |l|
    puts l
end
