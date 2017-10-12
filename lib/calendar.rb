require 'icalendar'

class Calendar
    # CONSTANTS
    ALL_PARAMS = [:end, :description, :ip_class, :duration] #legal optional args
    CALENDAR_FOLDER = "ressources/calendars/" #folder containing the .ics files

    # class variables accessors
    attr_accessor :name
    attr_accessor :cal
    attr_accessor :file

    def initialize(name)
        @name = name
        @file = CALENDAR_FOLDER + name + ".ics"
        File.file?(@file)? @cal = Icalendar::Calendar.parse(File.open(@file)).first : @cal = Icalendar::Calendar.new
        @cal = Icalendar::Calendar.new if @cal.nil? # if file exists but is empty: create new icalendar
        @def_duration = 45
    end

    # update the .ics file
    def push()
        File.open(@file, 'w') do |f|
            f.puts @cal.to_ical
        end
    end

    # start and summary are mandatories args, **args contains the optional ones    
    def add(start: Date.new(2001,9,11), summary: "Twin towers", **args)
        if (args.keys - ALL_PARAMS).empty? # check if args contains no illegal arguments
            args[:end] = (start.to_time + 60*(args[:duration]-120)).to_datetime if args.has_key? :duration #to_time to add minutes (-1 hour offset)
            @cal.event do |e| # creation of the event
                e.dtstart = Icalendar::Values::DateOrDateTime.new(start).call
                e.summary = summary
                # optional args
                if args.has_key? :end
                    e.dtend = Icalendar::Values::DateOrDateTime.new(args[:end]).call 
                else # if no :end and no :duration, default duration
                    e.dtend = Icalendar::Values::DateOrDateTime.new((start.to_time + 60*(@def_duration-120)).to_datetime).call 
                end
                e.description = args[:description] if args.has_key? :description
                args.has_key?(:ip_class) ?
                    e.ip_class = args[:ip_class] : e.ip_class = "PUBLIC"
            end
            @cal.publish
            push
        else
            raise "Invalid parameter(s)!"
        end


    end

    def remove()
    end

    def list()
    end

    def get(name)
    end
end

def calendar_concat()
end
