<?php
namespace Mingche\Lib;
/**
 * redis控制类
 * 
 * @author mingche
 * @since 2016-04-21
 */
class MyRedis {
        
        static private $instances;

        //redis实例
        private $redis = null;

        //reddis连接配置
        private $redis_cfg = null;

        private function __construct($cfg)
        {
                $this->redis = new \Redis();
                $this->redis_cfg = $cfg;
        }

        /**
         * 获取redis实例
         * @param array $cfg redis连接配置
         */
        public static function getInstance($cfg) 
        {
                $key = md5(join('', $cfg));
                if (empty(self::$instances[$key]) ) {
                        self::$instances[$key] = new MyRedis($cfg);
                }
                return self::$instances[$key];
        }

        /**
         * 给redis添加方法调用处理程序
         *
         * @param string  $name 调用的方法名
         * @param array $params 传入的参数
         */
        public function __call($name, $params)
        {
                $result = null;
                $connect_flag = 1;
                //判定redis是否正常链接
                try {
                        $this->redis->ping() != 'PONG';
                        $connect_flag = 0;
                } catch ( \RedisException $e) {
                        $connect_flag = 0;        
                }
                finally {
                        if ($connect_flag == 0) {
                                $this->redis->connect($this->redis_cfg['ip'], $this->redis_cfg['port'], $this->redis_cfg['timeout']);
                                
                                if ($this->redis_cfg['password']) {
                                        $this->redis->auth($this->redis_cfg['password']);
                                }
                        }
                       
                        switch (count($params)) {
                                case 0:
                                        $result = $this->redis->$name();
                                        break;
                                case 1:
                                        $result = $this->redis->$name($params[0]);
                                        break;
                                case 2:
                                        $result = $this->redis->$name($params[0], $params[1]);
                                        break;
                                case 3:
                                        $result = $this->redis->$name($params[0], $params[1], $params[2]);
                                        break;
                                case 4:
                                        $result = $this->redis->$name($params[0], $params[1], $params[2], $params[3]);
                                        break;
                                case 5:
                                        $result = $this->redis->$name($params[0], $params[1], $params[2], $params[3], $params[4]);
                                        break;
                        }
                        return $result;
                }

        }
}
