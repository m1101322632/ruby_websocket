/**
 * 
 */
var Chat = function (sWsUrl) 
{
        this.fInit(sWsUrl);
};

Chat.prototype = 
{
        oConf: {
                sWsUrL: null,
                sAddMsgUrL: "action.php?type=addMsg"
        },
        
        oWebSocket: null,
        
        fInit: function(sWsUrL) 
        {
                oSelf = this;
                this.oConf.sWsUrL = sWsUrL;
                this.fCreateWebScokct();
                //给body添加自定义事件, websocket关闭时触发重新链接.
                $('body').on('websoket_closed', function() { window.setTimeout( function () { oSelf.fCreateWebScokct(); }, 1000);  });
                $('#addMessage').bind('click', function(e) { oSelf.fAddMessage(); })
        },
        
        fCreateWebScokct: function() {
                this.oWebSocket = new WebSocket(this.oConf.sWsUrL);
                this.oWebSocket.onopen = this.fWebSocketOpenListener;
                this.oWebSocket.onmessage = this.fWebSocketMessageListener;
                this.oWebSocket.onclose = this.fWebSocketCloseListener;
        }, 
        
        fWebSocketOpenListener: function(oEvent) 
        {                
                var login_data = JSON.stringify({"type":"connect",  "session_id": $.cookie('PHPSESSID') });
                console.log("websocket握手成功，发送登录数据:"+login_data);
                 this.send(login_data);
        },
        
        fWebSocketMessageListener: function(oEvent) 
        {
                var oData = JSON.parse(oEvent.data);
                switch (oData.type) {
                        case 'say':
                                this.fDisplayMsg(oData);
                                break;
                }
        },
        
        fWebSocketCloseListener: function(oEvent) 
        {
                $('body').trigger('websoket_closed');
        },
        
        fAddMessage: function(oTriggerButton) 
        {
                var oDate = new Date();
                var sMsg = $('.chat-input-div input[type=text]').val();
                $('.chat-input-div input[type=text]').val('');
                var oMsgData = {
                        username: "我",
                        time: oDate.getHours()+ ':' +oDate.getMinutes()+ ':' +oDate.getSeconds(),
                        content: sMsg
                };
                this.fDisplayMsg(oMsgData);
                
                $.post(
                        this.oConf.sAddMsgUrL,
                        {msg: sMsg},
                        function(oData) {
                                if (oData.code == 1) {
                                        console.log('发送成功');
                                }
                        },
                        'json'
                );
        },
        
        fDisplayMsg: function(oData) {
                var oChatContentDiv = document.getElementById('chat-content-div');
                var sMsgHtml = "<div><label>"+ oData.username +" "+ oData.time +":</label>"+oData.content+"</div>";
                $(sMsgHtml).appendTo(oChatContentDiv);
                oChatContentDiv.scrollTop = oChatContentDiv.scrollHeight
        }
       
}