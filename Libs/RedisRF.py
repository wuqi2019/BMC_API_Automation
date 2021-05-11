import redis

class RedisRF:
    def __init__(self, host = '127.0.0.1', port = '6379', password = "123456", db = 0):
        self.redis_obj = redis.Redis(host = host, port = port, password = password, db = db, charset="utf8")

    def get_redis_value(self, *key):
        result = self.redis_obj.get(*key)
        if result:
            return result.decode()

    def delete_redis_value(self, *key):
        self.redis_obj.delete(*key)

if __name__=="__main__":
    red=RedisRF(host="10.197.236.195")
    h=red.get_redis_value("edl:sms_value:18224045273:active_credit")
    print(h)