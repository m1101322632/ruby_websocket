<?php session_start(); ?>
<!DOCTYPE html>
<html>
<head>
	<meta charset="UTF-8">
	<title>小聊天室</title>
	<link rel="stylesheet" type="text/css" href="statics/css/chat.css" />
</head>
<body>
	<div id="chat-content-div"></div>
	<div class="chat-input-div">
		<input type="text" />
		<input type="button"  id="addMessage" value="发送">
	</div>
</body>
<script type="text/javascript" src="statics/js/swfobject.js"></script>
<script type="text/javascript" src="statics/js/web_socket.js"></script>
<script type="text/javascript" src="statics/js/jquery.js"></script>
<script type="text/javascript" src="statics/js/jquery.cookie.js"></script>
<script type="text/javascript" src="statics/js/chat.js"></script>
<script type="text/javascript">
        // Set URL of your WebSocketMain.swf here:
        WEB_SOCKET_SWF_LOCATION = "statics/js/WebSocketMain.swf";
        // Set this to dump debug message from Flash to console.log:
        WEB_SOCKET_DEBUG = true;
        
        var oChat  = new Chat("ws://127.0.0.1:8001"); 
</script>
</html>