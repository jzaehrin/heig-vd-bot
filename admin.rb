module Adminable
    
    def admin?(chat_id)
        @config["admins"].value?(chat_id)
    end

    def username_admin?(username)
        @config["admins"].key?(username)
    end

    def match_admin(chat_id, username, password)
        if @config["invited_admin"].key?(username) && @config["invited_admin"][username] == password
            @config["invited_admin"].delete(username)
            @config["admin"][username] = chat_id
        else
         #return you aren't invited       
        end
    end

    def add_admin(username, password)
        @config["invited_admin"][username] = password
    end

    def remove_admin(username)
        if id_admin?(username)
            @config["admin"].delete(username)
        else
            #return this username isn't admin
        end
    end

    def list_admins()
        @config["admins"]
    end

    def list_invited_admin()
        @config["invited_admin"]
    end
end
