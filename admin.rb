module Adminable
    

    @@user_cmds = {"admin" => :become_admin, "init" => :init_admin}
    @@admin_cmds = {}
    @@super_admin_cmds = {"add_admin" => :add_admin_cmd, "is_admin" => :is_admin, "ls" => :ls_admin,
                            "rm_admin" => :rm_admin, "rm_invitation" => :rm_invitation, "revoke" => :revoke}
  
    def usage(chat_id)
        usage_txt = user_usage
        usage_txt += admin_usage if admin? chat_id
        usage_txt += super_admin_usage if super_admin? chat_id
        <<~HEREDOC
                Help for <b>#{name}</b> :
                #{usage_prefix}
                #{usage_txt}
        HEREDOC
    end

    def admin_usage
        get_admin_cmds.map{ |k, v| 
            "<code>#{k}</code>\n#{get_method_help(v)}"
        }.drop(1).join("\n")
    end  

    def super_admin_usage
        get_super_admin_cmds.map{ |k, v| 
            "<code>#{k}</code>\n#{get_method_help(v)}"
        }.drop(1).join("\n")
    end  

    def admin?(chat_id)
        get_config["admins"].value?(chat_id.to_s)
    end

    def super_admin?(chat_id)
        get_config["super_admin"] == (chat_id.to_s)
    end

    def username_admin?(username)
        get_config["admins"].key?(username)
    end

    def invited_admin?(username)
        get_config["invited_admin"].key?(username)
    end

    def has_super_admin?
        not get_config["super_admin"].empty?
    end

    def set_super_admin(chat_id)
        get_config["super_admin"] = chat_id.to_s
    end

    def get_super_admin_cmds
        @super_admin_cmds
    end

    def get_admin_cmds
        @admin_cmds
    end


    def match_admin(chat_id, username, password)
        if get_config["invited_admin"].key?(username) && get_config["invited_admin"][username] == password
            get_config["invited_admin"].delete(username)
            get_config["admins"][username] = chat_id
            true
        else
            false # return you aren't invited       
        end
    end

    def add_admin(username, password)
        get_config["invited_admin"][username] = password
    end

    def remove_admin(username)
        if username_admin?(username)
            get_config["admins"].delete(username)
            true
        else
            false #return this username isn't admin
        end
    end

    def remove_super_admin
        get_config["super_admin"] = ""
    end

    def remove_invited_admin(username)
        if invited_admin?(username)
            get_config["invited_admin"].delete(username)
            true
        else
            false #return this username isn't invited
        end
    end

    def list_admins()
        get_config["admins"]
    end

    def list_invited_admin()
        get_config["invited_admin"]
    end

#============Command to Functions
#user
    @@become_admin_usage = ""
    def become_admin(message, args)
        chat_id = message.chat.id.to_s
        if admin?(chat_id)
            reponse(chat_id, "You already are an admin for this bot ;) !")
        else
            if !args.empty? && match_admin(chat_id, message.from.username.to_s, args[0].to_s)
                reponse(chat_id, "Congrats! You're now a admin of this bot.")
            else
                reponse(chat_id, "Sorry, but you were not invited to become an admin of this bot.")
            end
        end
    end

    @@init_admin_usage = ""
    def init_admin(message, args)
        chat_id = message.chat.id
        unless has_super_admin?
            set_super_admin(chat_id)
            get_config["admins"][message.from.username.to_s] = chat_id.to_s
            reponse(chat_id, "Congrats! You're now the super admin of this bot.")
        else
            reponse(chat_id, "This bot has already been initialize.")
        end
    end

#super admin
    @@add_admin_cmd_usage = "- return a key to promote \"USER\" (without @) as admin"
    def add_admin_cmd(message, args)
        unless args.empty?
            o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
            password = (0...8).map { o[rand(o.length)] }.join
            add_admin(args[0],password)
            reponse(message.chat.id, "#{args[0]} invited with key #{password.to_s}.")
        end
    end

    @@is_admin_usage = "- tell if \"USER\" (without @) is admin or not" 
    def is_admin(message, args)
        chat_id = message.chat.id
        unless args.empty?
            case args[0]
            when /^(\d+)$/
                reponse(chat_id, admin?($1))
            when /^(\w{4,})$/ # test with username
                reponse(chat_id, username_admin?($1))
            end
        end
    end

    @@ls_admin_usage = "- \"PARAM\" can take \"admins\" to lists all admins\n- or \"invitations\" to lists all invitations\n- see <code>ls</code> form <i>user usage</i>"
    def ls_admin(message, args)
        chat_id = message.chat.id
        unless args.empty?
            case args[0] 
            when 'admins'
                text = "Admins list:\nusername\tchat_id\n"
                list_admins().each{|admin| text+= admin.first + "\t" + admin.last + "\n"}
                reponse(chat_id, text)
            when 'invitations'
                text = "Admins invitations list:\nusername\tchat_id\n" + list_invited_admin().to_s
                reponse(chat_id, text)
            end
        end
    end

    @@rm_admin_usage = "- remove \"USER\" (without @) from admin list"
    def rm_admin(message, args)
        chat_id = message.chat.id
        unless args.empty?
            if remove_admin(args[0]) 
                reponse(chat_id, "#{args[0]} is not an admin anymore.")
            else
                reponse(chat_id, "#{args[0]} wasn't on the admins list!")
            end
        end
    end

    @@rm_invitation_usage = "- remove the invitation for \"USER\" (without @)"
    def rm_invitation(message, args)
        unless args.empty?
            if remove_invited_admin($1) 
                reponse(chat_id, "#{args[0]} invitation removed.")
            else
                reponse(chat_id, "#{args[0]} wasn't on the list!")
            end
        end
    end

    @@revoke_usage = "- revoke the current super admin\n- see <code>init</code> from <i>user usage</i>"
    def revoke(message, args)
        remove_super_admin
    end
end
