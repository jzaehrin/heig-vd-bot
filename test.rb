require 'calendar'

test = Calendar.new("test")

test.add(start: DateTime.new(2001,2,3,0,0,0), summary: "test", duration: 130, description: "Bla bla bla")
test.push