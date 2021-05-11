import os,re
import redis
import pymongo
import json
import shutil
import requests
from robot.api import logger

class CommonTools:
    ROBOT_EXIT_ON_FAILURE = True
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    def get_device_info(self,device_type='Android'):
        if device_type.lower().strip() == 'android':
            while True:
                output = os.popen('adb devices').read()
                devices = re.findall('\n(\w+)\t', output, re.IGNORECASE)
                if len(devices) > 1:
                    input('请先拔出多余的设备后,按确认键')
                elif len(devices) == 0:
                    input('检测不到任何测试设备，请插入设备后按确认键')
                else:
                    device={}
                    device["name"] = devices[0]
                    device["version"] = re.findall('[\d\.]+', os.popen('adb shell getprop ro.build.version.release').read(), re.IGNORECASE)[0]
                    return device
    def get_yapi_interface(self,host,port,database,project_names,yapi_file):
        try:
            mongodb=pymongo.MongoClient(host=host,port=port)
            yapi=mongodb[database]
            project_ids={}
            for name in project_names:
                _projects=yapi['project'].find({'name':name})
                try:
                    if _projects.count() > 1:
                        raise Exception("yapi中查询到多个project:{}".format(name))
                    elif _projects.count() == 0:
                        raise Exception("yapi中查不到指定project:{}".format(name))
                    else:
                        project_ids[name] = _projects.next()['_id']
                except DeprecationWarning:
                    pass
            interfaces={}
            for key in project_ids:
                interfaces[key]={}
                _interfaces=yapi['interface'].find({'project_id':project_ids[key]})
                for _interface in _interfaces:
                    title=_interface['title']
                    title=re.sub('(？)|(\?)|(\d\. ?)','',title)
                    if '废弃' in title or "已移"  in title:
                        continue
                    if title in interfaces[key]:
                        raise Exception("{}项目中的接口命名{}重复".format(key,title))
                    interfaces[key][title]=_interface['query_path']['path']
            #备份原有的yapi文件
            path=os.path.dirname(yapi_file)
            file_name=os.path.basename(yapi_file)
            shutil.copyfile(yapi_file,"{}/{}".format(path,file_name+'_backup.json'))
            with open(yapi_file,mode='w',encoding='utf8') as yapi_fs:
                json.dump(interfaces,yapi_fs,ensure_ascii=False)
        except Exception as es:
            raise es
        finally:
            mongodb.close()
    def json_contains_or_not(self,source,target):
        if type(source)==dict:
            source=source.values()
        for value in source:
            if type(value)==dict or type(value)==list:
                if self.json_contains_or_not(value,target):
                    return True
            elif target==str(value):
                return True
        return False
    def json_should_contains(self,source,target):
        if  not  self.json_contains_or_not(source,target):
            raise Exception("{}中无法查到'{}'".format(source,target))

    def json_should_not_contains(self,source,target):
        if  self.json_contains_or_not(source,target):
            raise Exception("{}中含有'{}'".format(source,target))

    def json_should_contains_many(self,source,*targets):
        result_msg=""
        for item in targets:
            if not json_should_contains(source,item):
                result_msg+=str(item)+","
        if result_msg:
            raise Exception("无法在{}中查找到{}".format(source,result_msg.rstrip(',')))

    def check_dict(self,target):
        if not target:
            return False
        if type(target)==dict:
            target=target.values()
        for item in target:
            if type(item) == dict or type(item) == list:
                if not self.check_dict(item):
                    return False
            if not str(item):
                return False
        return True
if __name__=='__main__':
    tools=CommonTools()
    tools.get_yapi_interface("10.197.236.152",27017,'yapi',('edl-专网-移动端','edl-公网-移动端'),'../Resources/TestData/Yapi')