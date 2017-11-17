module Adminable
    
    def admin?(chat_id)
        @config["admins"].value?(chat_id)
    end

    def super_admin?(chat_id)
        @config["super_admin"] == (chat_id)
    end

    def username_admin?(username)
        @config["admins"].key?(username)
    end

    def invited_admin?(username)
        @config["invited_admin"].key?(username)
    end

    def has_super_admin?
        not @config["super_admin"].empty?
    end

    def set_super_admin(chat_id)
        @config["super_admin"] = chat_id
    end

    def match_admin(chat_id, username, password)
        if @config["invited_admin"].key?(username) && @config["invited_admin"][username] == password
            @config["invited_admin"].delete(username)
            @config["admins"][username] = chat_id
            true
        else
            false # return you aren't invited       
        end
    end

    def add_admin(username, password)
        @config["invited_admin"][username] = password
    end

    def remove_admin(username)
        if username_admin?(username)
            @config["admins"].delete(username)
            true
        else
            false #return this username isn't admin
        end
    end

    def remove_invited_admin(username)
        if invited_admin?(username)
            @config["invited_admin"].delete(username)
            true
        else
            false #return this username isn't invited
        end
    end

    def list_admins()
        @config["admins"]
    end

    def list_invited_admin()
        @config["invited_admin"]
    end
end
