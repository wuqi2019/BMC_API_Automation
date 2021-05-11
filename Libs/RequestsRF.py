import requests
import json,os,time
from robot.api import logger
import jpype

class RequestsRF:
    def __init__(self,interface_file_path):
        super().__init__()
        with open(interface_file_path,encoding='utf8') as fs:
            self.interfaces=json.load(fs)

    def aes_encrypt(self,class_path,token):
        if not os.path.exists(os.path.join(class_path,"CloneEncryptStringAes.class")):
            logger.error("指定目录{}无法找到文件{}".format(class_path,"CloneEncryptStringAes.class"))
            return
        #对公网token加密
        # 加密规则：将公网token+时间戳(13位)进行拼接，然后使用aes加密
        token_plus_timestamp=token+str(int(round(time.time() * 1000)))
        # 启动jvm,注意class_path是目录，不用带上class文件名
        if not jpype.isJVMStarted():
            jpype.startJVM(jpype.getDefaultJVMPath(),"-ea","-Djava.class.path={}".format(os.path.realpath(class_path)),convertStrings=True)
        aes_class=jpype.JClass("CloneEncryptStringAes")
        aes_instance=aes_class()
        encrypted_token=aes_instance.encryptAes(token_plus_timestamp)
        #关闭JVM
        #jpype.shutdownJVM()
        return encrypted_token

    def json_paser(self,path,target):
        try:
            locators = path.split('》')
            for l in locators:
                target = target[l]
            return target
        except Exception as ex:
            logger.error("解析{}失败：无法找到指定的值{}\n{}".format(target,path,ex))

    def POST(self,base_url,path=None,headers=None,params=None):
        if path:
            full_url=base_url+self.json_paser(path,self.interfaces)
        else:
            full_url=base_url
        return  requests.post(full_url,headers=headers,json=params)

    def GET(self,base_url,path=None,headers=None,params=None):
        if path:
            full_url=base_url+self.json_paser(path,self.interfaces)
        else:
            full_url=base_url
        return requests.get(full_url,headers=headers,params=params)

if __name__=="__main__":
    r=RequestsRF(r'D:\自动化\Projects\Banma\Resources\Yapi')
    target={'a':{'b':"2"},"c":[]}
    print(r.check_dict(target))