require 'calendar'

test = Calendar.new("test")

test.add(start: DateTime.new(2017,10,7,12,0,0), summary: "test 1", duration: 120, description: "Bla bla bla")
test.add(start: DateTime.new(2017,10,7,12,0,0), summary: "test 2", description: "Bla bla bla")