module Adminable
    
    def admin?(chat_id)
        @config["admins"].value?(chat_id)
    end

    def id_admin?(id)
        @config["admins"].key?(id)
    end

    def match_admin(chat_id, id, password)
        if @config["invited_admin"].key?(id) && @config["invited_admin"][id] == password
            @config["invited_admin"].delete(id)
            @config["admin"][id] = chat_id
        else
         #return you aren't invited       
        end
    end

    def add_admin(id, password)
        @config["invited_admin"][id] = password
    end

    def remove_admin(id)
        if id_admin?(id)
            @config["admin"].delete(id)
        else
            #return this id isn't admin
        end
    end
end
