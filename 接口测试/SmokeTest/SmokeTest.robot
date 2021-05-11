*** Settings ***
Library         ../../Libs/RequestsRF.py   ../../Resources/TestData/Yapi
Library         ../../Libs/CommonTools.py
Library         ../../Libs/MysqlRF.py      10.197.236.190      root        123456      edl_private
Library         ../../Libs/RedisRF.py      10.197.236.197
Resource        ../../Resources/Keywords/PubKeywords.robot
Resource        Keywords&Variables.robot
Suite Setup     init environment

*** Test Cases ***
注册登录
    [setup]     run keyword and ignore error    clear new user data     ${new-user-phone}   #清除已注册用户信息
    #验证用户协议
    send post request and verify     公网》【手机号登陆】获取用户登录类型     phone=${new-user-phone}
    send get request and verify     http://testbmcapp.hikcreate.com/h5/#/RegisterProtocol   #获取注册协议

    #设置手势密码
    ${response}     send get request and verify     公网》获取图形验证码                      #获取拼图
    ${captcha_percent}      get redis value     bmc:captcha:${response.json()}[data][jtId]    #redis获取拼图有效值
    send post request and verify     公网》【手机号登陆】效验图形验证码&获取短信验证码      phone=${new-user-phone}     bizType=1   horPercent=${captcha_percent}   jtId=${response.json()}[data][jtId]
    ${verify_code}      get redis value  edl:sms_value:${new-user-phone}:mobile_register     #redis读取验证码
    should be true      ${verify_code}  msg=读取验证码失败
    ${response}     send post request and verify    公网》【手机号登陆】短信验证      phone=${new-user-phone}   bizType=1   verifyCode=${verify_code}
    ${response}     send post request and verify    公网》【手机号登陆】设置手势-登录   phone=${new-user-phone}   oneTimeToken=${response.json()}[data][oneTimeToken]   encodedGesture=${encodedGesture}     deviceId=${deviceId}
    ${encrypted-token}      aes encrypt    ../../Libs     ${response.json()}[data][token]
    &{get-header-just-activated}        create dictionary      &{get-header}       Token=${encrypted-token}
    send get request and verify     公网》获取用户个人信息                                   #验证是否登录成功
    ${response}     send post     公网》退出登录    headers=&{get-header-just-activated}     #退出登录
    should be equal     ${response.json()}[msg]     登出成功

    #设置字符密码
    ${response}     send get request and verify     公网》获取图形验证码                      #获取拼图
    ${captcha_percent}      get redis value     bmc:captcha:${response.json()}[data][jtId]    #redis获取拼图有效值
    send post request and verify     公网》【手机号登陆】效验图形验证码&获取短信验证码      phone=${new-user-phone}     bizType=4   horPercent=${captcha_percent}   jtId=${response.json()}[data][jtId]
    ${verify_code}      get redis value  edl:sms_value:${new-user-phone}:set_keyboard_pwd     #redis读取验证码
    should be true      ${verify_code}  msg=读取验证码失败
    ${response}     send post request and verify    公网》【手机号登陆】短信验证      phone=${new-user-phone}   bizType=4   verifyCode=${verify_code}
    ${response}     send post request and verify    公网》【手机号登陆】设置字符密码-登录    phone=${new-user-phone}      oneTimeToken=${response.json()}[data][oneTimeToken]     encodedKeyboardPwd=${encodeKeyboardPwd}     deviceId=${deviceId}
    ${encrypted-token}      aes encrypt    ../../Libs     ${response.json()}[data][token]
    &{get-header-just-activated}        create dictionary      &{get-header}       Token=${encrypted-token}
    send get request and verify     公网》获取用户个人信息                                   #验证是否登录成功

激活交通信用-短信
    clear data      ${id_card-unactivated}      ${phone-unactivated}
    ${encrypted-token}      ${Pvt-Token}       login with keyboardPwd      ${phone-unactivated}        ${encodeKeyboardPwd}        ${deviceId}
    &{get-header-unactivated}   create dictionary      &{get-header}       Token=${encrypted-token}      Pvt-Token=${Pvt-Token}
    send get request and verify     公网》身份证校验    headers=&{get-header-unactivated}        idCard=${id_card-unactivated}       realName=${username-unactivated}
    send get        公网》发送短信验证码      headers=&{get-header-unactivated}
    ${verify_code}      get redis value  edl:sms_value:${phone-unactivated}:active_credit
    should be true      ${verify_code}      msg=获取验证码失败
    send get request and verify     公网》激活信用        verifyCode=${verify_code}    headers=&{get-header-unactivated}

首页刷新
    [Template]  send get request and verify
    公网》公告弹出
    公网》【消息中心】未读消息数
    公网》获取首页业务列表     cityCode=520100
    公网》获取广告     type=index
    公网》获取首页资讯
    公网》获取用户个人信息
    公网》【意见反馈】是否未读
    公网》限行语音播报
    专网》获取卡片信息
    专网》获取部分信用优享信息
    专网》我的信用
    专网》用户信息
    专网》获取驾驶证图片      bizType=1

绑定车辆然后解绑
    [Setup]     run keyword and ignore error    send post request and verify    专网》解绑机动车备案      vehicleId=${vehicles}[贵A66666]      type=1
    [Teardown]    run keyword and ignore error    send post request and verify    专网》解绑机动车备案      vehicleId=${vehicles}[贵A66666]      type=1
    send get request and verify     公网》绑定机动车-发送验证码    ownerName=${username-unactivated}     plateNum=贵A66666       plateType=02        vehicleIdentifyNum=A66666
    ${verify_code}      get redis value  edl:sms_value:${phone-unactivated}:bind_vehicle
    should be true      ${verify_code}      msg=获取验证码失败
    send post request and verify    公网》绑定机动车-提交     ownerName=${username-unactivated}     plateNum=贵A66666       plateType=02        vehicleIdentifyNum=A66666       verifyCode=${verify_code}
    ${response}=        send get    专网》车辆管理列表
    json should contains    ${response.json()}      贵A66666
    &{vehicles}             get vehicle ids
    send post request and verify    专网》解绑机动车备案      vehicleId=${vehicles}[贵A66666]      type=1
    ${response}=        send get    专网》车辆管理列表
    json should not contains    ${response.json()}      贵A66666

查看违法信息
    send get request and verify    专网》机动车详情（列表进入详情时调用）
    ${vehicle_id}   set variable  ${vehicles}[贵A77777]
    ${untreated}    send get    专网》违法列表     vehicleId=${vehicle_id}     status=0        #未处理
    ${unpaid}    send get    专网》违法列表     vehicleId=${vehicle_id}      status=2           #未缴费
    ${processed}    send get    专网》违法列表     vehicleId=${vehicle_id}      status=1        #已处理
    should be equal     ${untreated.json()}[data][list][0][address]        待处理违法
    should be equal     ${unpaid.json()}[data][list][0][address]           待缴费违法
    should be equal     ${processed.json()}[data][list][0][address]        已完成违法处理
    ${untreated_vioID}      set variable    ${untreated.json()}[data][list][0][id]
    ${untreated_vioImage}      set variable    ${untreated.json()}[data][list][0][vioImage]
    ${response}     send get    ${untreated_vioImage}
    should not be equal     ${response.headers}[Content-Length]     0                                #验证违法列表中的图片能否访问
    ${untreated_detail}     send get    专网》违法详情     vioId=${untreated_vioID}
    ${detail_vioImage}      set variable    ${untreated_detail.json()}[data][vioImages][0]
    ${response}     send get    ${detail_vioImage}
    should not be equal     ${response.headers}[Content-Length]     0                                #验证违法详情中的图片能否访问

查看事故信息
    send get request and verify     专网》机动车详情（列表进入详情时调用）
    ${response}     send get        专网》事故列表
    ${acd_count}    set variable    ${response.json()}[data][list]
    length should be    ${acd_count}    ${10}
    ${acd_detail}   send get          专网》事故详情       acdId=${response.json()}[data][list][0][id]
    ${check_result}     check dict      ${acd_detail.json()}[data]
    should be true      ${check_result}
    ${acd_image}    send get        ${acd_detail.json()}[data][vehicleImage]
    should not be equal     ${acd_image.headers}[Content-Length]     0

管理我的车辆测试
    [setup]     run keyword and ignore error    clear insurance data    A77777
    ${response}     send get    专网》车辆管理列表
    should be true      check dict      ${response.json()}              #检查数据是否有遗漏
    should be true  ${response.json()}[data][list][0][isDefault]        #检查第一个是否为默认车辆
    &{vehicles}             get vehicle ids
    ${response}     send get    专网》机动车详情（列表进入详情时调用）     vehicleId=${vehicles}[贵A77777]
    ${car_detail}   set variable  ${response.json()}
    should be true      check dict      ${car_detail}              #检查车俩详情数据是否有遗漏
    json should contains many  ${car_detail}    尾号限行   违法信息    事故信息    电子行驶证
    FOR     ${icon}     IN      ${car_detail}[data][item]          #检查四个图标能否正常访问
            send get request and verify     ${icon}[icon]
    END
    send get request and verify     ${car_detail}[data][vehicleImage]      #检查车辆图片能否访问
    should be equal     ${car_detail}[data][insuranceStatus]    ${0}       msg=保险信息不正确：${car_detail}[data][insuranceStatus]
    send get request and verify     专网》查询强制险    vehicleId=${vehicles}[贵A77777]
    send get request and verify     专网》查询商业险    vehicleId=${vehicles}[贵A77777]
    send get request and verify     专网》保险公司列表
    &{CompulsoryIns}    create dictionary  insCompany=中国太平洋财产保险股份有限公司  policyNo=1  insAmount=1  insBuyTime=2019-10-24  gmtExpiryStart=2019-10-24
    ...     gmtExpiryEnd=2020-10-23  img=/group1/M00/00/82/CsXsuV2xhNyACcZvAADQjpf0xAk304.jpg  vehicleId=${vehicles}[贵A77777]
    send post request and verify    专网》添加强制保险   &{CompulsoryIns}
    &{CommercialIns}    create dictionary  insCompany=中国太平洋财产保险股份有限公司  policyNo=2  insAmount=2  insBuyTime=2019-10-24  gmtExpiryStart=2019-10-24  gmtExpiryEnd=2020-10-23
    ...     img=/group1/M00/00/82/CsXsuV2xhuOAUe8jAADQjpf0xAk103.jpg    loss=1  glass=1     selfIgnition=1  exFranchise=1  noFault=1  vehPersonNum=1  scratch=1  thirdPart=5  robbery=1  vehicleId=4294
    send post request and verify    专网》添加商业保险   &{CommercialIns}
    ${response}     send get    专网》机动车详情（列表进入详情时调用）     vehicleId=${vehicles}[贵A77777]
    should be equal     ${car_detail}[data][insuranceStatus]    ${1}       msg=保险信息不正确：${car_detail}[data][insuranceStatus]
    send get request and verify     专网》查询强制险    vehicleId=${vehicles}[贵A77777]      中国太平洋财产保险股份有限公司
    send get request and verify     专网》查询商业险    vehicleId=${vehicles}[贵A77777]      中国太平洋财产保险股份有限公司