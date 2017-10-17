module Adminable
    
    def is_admin(user_id)
        @config["admins"].include(user_id)
    end

    def add_admin
    end
end
