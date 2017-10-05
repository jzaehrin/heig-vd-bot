require 'icalendar'

class Calendar
    MANDAT_PARAMS = %w[start summary]
    ALL_PARAMS = %w[start end summary description ip_class]
    CALENDAR_FOLDER = "ressources/calendars/"
    attr_reader :name
    attr_reader :cal
    attr_reader :file

    def initialize(name)
        @name = name
        @file = CALENDAR_FOLDER + name + ".ics"
        @cal = File.file?(@file)? Icalendar::Calendar.parse(@file).first : @cal = Icalendar::Calendar.new
    end

    # update the .ics file
    def update()
        puts @cal.to_ical
        File.open(@file, 'w') do |f|
            f.puts @cal.to_ical
        end
    end

    # **args contains infos to add a VEVENT     
    def add(**args) 
        #if (MANDAT_PARAMS & args.keys == MANDAT_PARAMS) && (ALL_PARAMS | args.keys == ALL_PARAMS)
            @cal.event do |e|
                e.dtstart = Icalendar::Values::Date.new('20050428')
                e.summary = args["summary"]

                args.has_key? :end
                    e.dtend = Icalendar::Values::Date.new('20050429')

                args.has_key? :description
                    e.description = args["description"]

                args.has_key?("ip_class") ?
                    e.ip_class = args["ip_class"] : e.ip_class = "PUBLIC"
            end
            @cal.publish
            puts "test"
        #else
            # bad params
        #end


    end

    def remove()
    end

    def list()
    end

    def get(name)
    end
end

def calendar_concat(list)
end
