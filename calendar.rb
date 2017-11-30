require 'icalendar'

class Calendar
    # CONSTANTS
    ALL_PARAMS = [:description, :ip_class] #legal optional args
    CALENDAR_FOLDER = "ressources/calendars/" #folder containing the .ics files

    # class variables accessors
    attr_accessor :name
    attr_accessor :cal
    attr_accessor :file

    def initialize(name, parents)
        @name = name
        @parents = parents
        @file = CALENDAR_FOLDER + name + ".ics"
        if File.file?(@file)
            @cal = Icalendar::Calendar.parse(File.open(@file)).first
            @cal = Icalendar::Calendar.new if @cal.nil? # if file exists but is empty: create new icalendar
        else
            @cal = Icalendar::Calendar.new
        end
        @def_duration = 45
    end

    # update the .ics file
    def push(calendar)
        File.open(calendar.file, 'w') do |f|
            f.puts calendar.cal.to_ical
        end
    end

    # start and summary are mandatories args, **args contains the optional ones    
    def add(start: Date.new(2001,9,11), summary: "Twin towers", duration: @def_duration,  **args)
        if (args.keys - ALL_PARAMS).empty? # check if args contains no illegal arguments
            dtend = start.clone
            dtend += Rational(duration, 1440) # define event end datetime
            e = Icalendar::Event.new
            e.dtstart = Icalendar::Values::DateOrDateTime.new(start).call
            e.dtend = Icalendar::Values::DateOrDateTime.new(dtend).call 
            e.summary = summary
            e.description = args[:description] if args.has_key? :description
            if args.has_key?(:ip_class)
                e.ip_class = args[:ip_class]
            else
                e.ip_class = "PUBLIC"
            end
            add_event(e)
        else
            raise "Invalid parameter(s)!"
        end


    end

    def add_event(event)
        @cal.add_event(event)
        push(self)
        
        @parents.each{ |p| 
            p.add_event(event)
        }
    end

    def remove()
    end

    def list()
        events = @cal.events.collect{ |e|
            e.dtstart.strftime("<b>%d.%m.%Y at %R</b>") +  " " +  e.summary.to_s
        }
        events.sort.join("\n")
    end

    def get(name)
    end
end

def calendar_concat()
end
