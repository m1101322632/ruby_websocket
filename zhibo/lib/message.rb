# websockt服务器-> 消息处理类
# @author xuxiaozhou
# @since 2016-04-26

require "digest/md5"

class Message

    class << self

        attr_accessor(:debug)

    end

    class Error < RuntimeError

    end

    #------------------------------------------------------------
    # 获取登录用户列表
    # @param array invalid_mids  要排除的用户mid
    #------------------------------------------------------------
    def self.getLoginUserList(userlist, exclude_mids = nil)
        login_users = Array.new()
        for user in userlist
            next if exclude_mids != nil && exclude_mids.include?(user[1]['mid']) != nil
            login_users.push(user[1])
        end
        return login_users
    end

    #---------------------------------------------------------
    # 发送消息到客户端,发送逻辑
    #   1.say-shstatus:0   发给管理员
    #   2.say-shstatus:1 tomid=all  发给除了 审核者 发送者 之外的人
    #   3.say-shstatus:1 tomid=3  发给 tomid 非审核的管理员 
    #   4.login: 发送登录消息给所有人
    #   5.logout: 发送给所有人
    #   6.deleteliaotian: 发送给除了发送者之外的人
    #   7.pubclear：发送给除了发送者 管理员 之外的人
    # @param Hash msg
    # @param Hash client_msg_queues
    # @param Hash userlist 用户列表
    # @param Hash adminlist 管理员列表
    # @param Hash mid_to_sessionid mid到sessionid的映射
    #----------------------------------------------------------
    def self.sendMsgToClient(msg, client_msg_queues, userlist, adminlist, mid_to_sessionid)
        clients = Array.new();
        msg_owner_session_id = mid_to_sessionid[msg['mid']]
        case msg['type']
            when 'logout', 'login'
                clients = userlist.keys()
            when 'deleteliaotian'
                clients = userlist.keys() - [mid_to_sessionid[msg['mid']]]
                msg.delete('mid')
            when 'pubclear'
                clients = userlist.keys() - adminlist.keys() - [mid_to_sessionid[msg['mid']]]
                msg.delete('mid')
            when 'say'
                if msg['shstatus'] == 1 && msg['tomid'].to_s == 'all'
                    exclude_clients = Array.new()
                    exclude_clients.push(mid_to_sessionid[msg['mid']])
                    exclude_clients.push(mid_to_sessionid[msg['shmid']])
                    clients = userlist.keys() - exclude_clients
                elsif  msg['shstatus'] == 1 && msg['tomid.to_s'] != 'all'
                    clients = [mid_to_sessionid[msg['tomid']]] + adminlist.keys() - [mid_to_sessionid[msg['shmid']]]
                else
                    clients = adminlist.keys()
                end
        end

        #删除需要隐藏的信息
        msg.delete('shmid')
        msg.delete('ws_login_time')
        msg.delete('connected_ws')

        for client in clients
	        next if client_msg_queues[client.to_s] == nil #如果ws客户端连接不存在则跳过

            if msg['type'] == 'login' && client == msg_owner_session_id #用户登陆时发给自己的消息中带有当前登陆用户列表信息
				msg['client_list'] = Message::getLoginUserList(userlist)
			end
            client_msg_queues[client.to_s].push(JSON.dump(msg))
        end
    end

    #-------------------------------------
    # 验证消息有效性
    # @return bool
    #-------------------------------------
    def self.checkMsgValid(msg, ws)
        #从sign、ip来判定
        check_result = true
        key = 'wb@#!Vb*&df'
        sign = Digest::MD5.hexdigest(key + msg['mid'].to_s)
        ip = ws.tcp_socket.remote_address().ip_address()

        if ip != '127.0.0.1'
            check_result = false
        elsif sign != msg['sign']
            check_result = false
        end
        return check_result
    end
end
