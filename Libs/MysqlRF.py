import pymysql
import datetime,re

class MysqlRF:
    def __init__(self, host, user , password, db):
        self.connection = pymysql.connect(host=host,
                                     user=user,
                                     password=password,
                                     db=db,
                                     charset='utf8mb4',
                                     cursorclass=pymysql.cursors.DictCursor)

    def execute_sql(self, sql):
        with self.connection.cursor() as cursor:
            cursor.execute(sql)
        self.connection.commit()

    def execute_sqls(self, sql):
        sqls = [s.strip() for s in re.split(";|；", sql) if s.strip()]
        if sqls:
            try:
                for sql in sqls:
                    with self.connection.cursor() as cursor:
                        cursor.execute(sql)
            except:
                self.connection.rollback()
                return False
            finally:
                self.connection.commit()
                return True

    def query(self, sql):
        with self.connection.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            if rows:
                rows = [list(row.values()) for row in rows]
                for r in rows:
                    for index, value in enumerate(r):
                        if type(value) is datetime.date or type(value) is datetime.datetime:
                            r[index] = value.strftime('%Y-%m-%d %H:%M:%S')
                        elif value is None:
                            r[index] = 'NULL'
                return rows
    def close_connection(self):
        self.connection.close()

if __name__ == "__main__":
    con=MysqlRF(host="10.197.236.190",user="root",password="123456",db="edl_private")
    d=con.execute_sql("delete from edl_private.user where id_card in ('520101199608018458')")
    con.close_connection()
    print(d)