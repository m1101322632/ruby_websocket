#=======================================================
#  日期 2016年5月4日
#  版本version 1.1
#  websocket 服务端程序
#     从redis中聊天数据队列中获取要发送的聊天数据发送给对应
#  的用户.
#========================================================

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require "web_socket"
require "thread"
require 'json'
require 'message'
require 'rubygems'
require 'redis'

Thread.abort_on_exception = true

if ARGV.size != 2
    $stderr.puts("need two params: ACCEPTED_DOMAIN and PORT")
    exit(1)
end

#函数:依据session_id清理对应的用户的数据
def clear_by_session_id(session_id,userlist, admin_list, mid_to_sessionid, client_msg_queues)
    userlist.delete(session_id)
    admin_list.delete(session_id)
    client_msg_queues.delete(session_id)
    mid_to_sessionid.delete_if{|key, value| value == session_id }
end

#创建websocket监听服务器
server = WebSocketServer.new(
    :accepted_domains => [ARGV[0]],
    :port => ARGV[1].to_i())
puts("Server is running at port %d" % server.port)

#ws客户端对应的消息队列列表,session_id做键名
client_msg_queues = Hash.new()
#用户列表(包含管理员),session_id做键名 
userlist = Hash.new() 
#管理员列表,session_id做键名
admin_list = Hash.new() 
#mid到sessionid的映射
mid_to_sessionid = Hash.new() 

#子线程:从redis中获取消息,并发送给各个登陆用户对应的消息队列
thread_send_msg_to_que = Thread.new() do
    begin 
        o_redis = Redis.new(:host => "192.168.83.57", :port => 6379)
        while msg = o_redis.brpop('wb_message')
            tmp_data = JSON.parse msg[1]

            rq_session_id = tmp_data['session_id'].to_s
            tmp_data.delete('session_id')
            
            #记录登陆用户,创建消息队列,但是不发送登陆消息,在ws客户端连接时发送登陆消息
            if tmp_data['type'] == 'login'
                userlist[rq_session_id] = tmp_data.clone
                userlist[rq_session_id]['ws_login_time'] = Time.new.to_i

                if tmp_data['adminid'].to_i == 1 || tmp_data['adminid'].to_i == 3
                    admin_list[rq_session_id] = userlist[rq_session_id]
                end
                mid_to_sessionid[tmp_data['mid']] = rq_session_id
                #创建指定用户存放消息的队列
                client_msg_queues[rq_session_id] = Queue.new() if !client_msg_queues[rq_session_id]
                next
            end

            #发送消息到队列
            Message::sendMsgToClient(tmp_data, client_msg_queues, userlist, admin_list, mid_to_sessionid)
            #用户退出时清理该用户的登陆/队列等数据
            if tmp_data['type'] == 'logout'
                clear_by_session_id(rq_session_id,userlist, admin_list, mid_to_sessionid, client_msg_queues)
            end
        end
    rescue 
        puts("线程:thread_send_msg_to_que发生错误:#{$@}行出错, 错误信息为:#{$!}")
    end
end

#子线程:每30秒检测一次userlist表,将登陆到ws时间超过30秒且对应的用户没有从浏览器以websocket方式连接到ws服务器
#的用户数据清除掉.主要应对用户只登陆,但不发送type=connect数据的请求
thread_clear_invalid_user = Thread.new() do
    while true 
        sleep_time = 30
        sleep(sleep_time)
        for user in userlist
            if userlist[user[0]]['connected_ws'] == nil && userlist[user[0]]['ws_login_time']+sleep_time < Time.new.to_i
                clear_by_session_id(user[0], userlist, admin_list, mid_to_sessionid, client_msg_queues)
            end
        end
    end
end

#开始监听并接收websocket连接
server.run() do |ws|
    begin
        puts("Connection accepted")
        ws.handshake()

        thread_send_ping = Thread.new() do
            while true
                sleep(5)
                ws.send('{"type":"ping"}')
            end
        end

        session_id = nil
        thread_send_msg_to_ws = nil

        #接收ws客户端发送的消息
        while data = ws.receive()
            puts("Received: #{data}")
            tmp_data = JSON.parse data
	        case tmp_data['type']
                #连接的时候按sessoin_id识别身份
                when 'connect' 
                    session_id = tmp_data['session_id'].to_s
                    if userlist[session_id] != nil
                        userlist[session_id]['connected_ws'] = true
                        Message::sendMsgToClient(userlist[session_id].clone, client_msg_queues, userlist, admin_list, mid_to_sessionid)                       
                        puts("#{tmp_data['session_id']} login")
                        #子线程:发送消息
                        thread_send_msg_to_ws.terminate() if thread_send_msg_to_ws
                        thread_send_msg_to_ws = Thread.new() do
                            while true
                                #从redis中读取到logout记录时,对应的队列会被删除掉
                                break if client_msg_queues[session_id] == nil 
                                t_msg = client_msg_queues[session_id].pop()
                                ws.send(t_msg)
                            end
                        end
                    end
                #断开ws客户端连接
                when 'connect_close'
                    break

                when 'pong'
                    next
            end
        end
    ensure
        #更新当前websocket对应用户登陆ws服务器的时间,重置用户连接状态
        if userlist[session_id] != nil
            userlist[session_id]['ws_login_time'] = Time.new.to_i
            userlist[session_id]['connected_ws'] = nil
        end

        thread_send_msg_to_ws.terminate() if thread_send_msg_to_ws
        thread_send_ping.terminate() if thread_send_ping
        puts("Connection closed")
    end
end

#关闭子线程
thread_send_msg_to_que.terminate() if thread_send_msg_to_que
thread_clear_invalid_user.terminate() if thread_clear_invalid_user

