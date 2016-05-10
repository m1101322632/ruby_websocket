<?php
ini_set('display_errors', false);
session_start();
include 'lib/MyRedis.php';

$redis_cfg = array(
        'ip' => '',
        'port' => '',
        'timeout' => 86400,
        'password' => ''
);
$redis_cli = Mingche\Lib\MyRedis::getInstance($redis_cfg);

if ($_GET['type'] == 'addMsg') {
        $msg = array(
                'type' => 'say',
                'username' => $_SESSION['username'],
                'content' => $_POST['msg'],
                'time'  => date('H:i:s'),
                'mid' => $_SESSION['mid'],
                'session_id' => session_id(),
                'tomid' => 'all',
                'shstatus' => 1
        );
} elseif ($_GET['type'] == 'login') {
        $_SESSION['username'] = $_GET['username'];
        $_SESSION['mid'] = time();
        $msg = array(
                'type' => 'login',
                'username' => $_SESSION['username'],
                'mid' => $_SESSION['mid'],
                'content' => $_POST['msg'],
                'time'  => date('H:i:s'),
                'session_id' => session_id()
        );
}
if ($msg) {
        $redis_cli->lpush('wb_message', json_encode($msg));
}