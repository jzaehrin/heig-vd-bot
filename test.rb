require 'calendar'

test = Calendar.new("test")
puts test.cal
test.add(start: "20050428",end: "20050429",summary: "test")
test.update