*** Settings ***
Library         ../../Libs/RequestsRF.py   ../../Resources/TestData/Yapi
Library         ../../Libs/CommonTools.py
Library         ../../Libs/MysqlRF.py      10.197.236.190      root        123456      edl_private
Library         ../../Libs/RedisRF.py      10.197.236.197
Resource        ../../Resources/Keywords/PubKeywords.robot

*** Variables ***
${pvt-base-url}      http://testbmcpvtapp.hikcreate.com
${pub-base-url}      http://testbmcapp.hikcreate.com
${id_card-unactivated}        520101199608018458
${phone-unactivated}          17128240042
${username-unactivated}       赵日天
${id_card-activated}          520101198709015411
${phone-activated}            17128240047
${username-activated}       叶良辰
${new-user-phone}           17134025271
${encodeKeyboardPwd}                   4468a7a344ec6fc239753fe4758ef1e2
${encodedGesture}       67e6d10010533eed4bbe9659863bf6ee
${deviceId}         14b4ae557e8746d1b72a0a0a02b54e2a
${token}            ${None}
${Pvt-Token}        ${None}
&{post-header}      version=1.7.2      Device-Type=Android      Content-Type=application/json;charset=utf-8       Device-Name=OPPO+A83      Device-Model=OPPO OPPO A83   City-Code=520100       Device-Code=ffffffffc2c1b527ffffffffc2c1b527
&{get-header}       Device-Name=OPPO+A83        Device-Model=OPPO OPPO A83          City-Code=520100        version=1.7.1       Device-Type=Android     Device-Code=ffffffffc2c1b527ffffffffc2c1b527

*** Keywords ***
init environment
    ${encrypted-token}      ${Pvt-Token}        login with keyboardPwd      ${phone-activated}        ${encodeKeyboardPwd}        ${deviceId}
    log     ${encrypted-token},${Pvt-Token}
    set suite variable      &{get-header}        &{get-header}       Token=${encrypted-token}      Pvt-Token=${Pvt-Token}
    set suite variable      &{post-header}       &{post-header}       Token=${encrypted-token}      Pvt-Token=${Pvt-Token}
    &{vehicles}             get vehicle ids
    set suite variable      &{vehicles}

send post
    [arguments]     ${path}     ${headers}=&{post-header}     &{params}
    [Return]        ${response}
    log             请求参数：${path},${headers},&{params}
    ${response}=    run keyword if       ${path.__contains__("公网")}     POST    ${pub-base-url}     ${path.replace("公网","edl-公网-移动端")}     ${headers}       params=${params}
    ...             ELSE IF              ${path.__contains__("专网")}     POST    ${pvt-base-url}     ${path.replace("专网","edl-专网-移动端")}     ${headers}       params=${params}
    ...             ELSE                 POST    ${path}     headers=${headers}       params=${params}
    should be equal     ${response.status_code}     ${200}      msg=${response.text}

send get
    [arguments]     ${path}     ${headers}=&{get-header}      &{params}
    [Return]        ${response}
    log             请求参数：${path},${headers},${params}
    ${response}=    run keyword if       ${path.__contains__("公网")}     GET    ${pub-base-url}     path=${path.replace("公网","edl-公网-移动端")}     headers=${headers}       params=${params}
    ...             ELSE IF              ${path.__contains__("专网")}     GET    ${pvt-base-url}     path=${path.replace("专网","edl-专网-移动端")}     headers=${headers}       params=${params}
    ...             ELSE                 GET    ${path}     headers=${headers}       params=${params}
    should be equal     ${response.status_code}     ${200}      msg=${response.text}

get vehicle ids
    [Documentation]  获取车牌号对应的车辆ID
    [Return]    &{vehicles}
    ${response}     send get    专网》获取卡片信息
    @{vehicleLicenses}     json paser      data》vehicleLicenses     ${response.json()}
    &{vehicles}     create dictionary       &{EMPTY}
    :FOR     ${vehicle}      IN     @{vehicleLicenses}
             &{vehicles}        create dictionary       &{vehicles}       ${vehicle}[plateNum]=${vehicle}[id]
    END
login with keyboardPwd
    [Documentation]  登录，并获取公网和专网token
    [arguments]     ${phone}        ${encodeKeyboardPwd}        ${deviceId}
    [Return]        ${encrypted-token}      ${Pvt-Token}
    ${response_login}       send post    公网》【手机号登陆】字符密码登录    phone=${phone}       encodeKeyboardPwd=${encodeKeyboardPwd}      deviceId=${deviceId}
    log     ${response_login.json()}
    ${token}    json paser      data》token      ${response_login.json()}
    ${encrypted-token}      aes encrypt    ../../Libs     ${token}
    &{data_pvt_token}     create dictionary    &{get-header}     Token=${encrypted-token}
    ${response_pvt_token}       send get    公网》获取专网token    headers=&{data_pvt_token}
    ${Pvt-Token}    json paser      data》token      ${response_pvt_token.json()}

response should be correct
    [Arguments]     ${response}     ${expected_value}
    ${contentType}     set variable    ${response.headers['Content-Type']}
    run keyword if      ${contentType.__contains__('json')}     json should contains    ${response.json()}      ${expected_value}   #判断请求是否包含指定值
    ...    ELSE         should not be equal     ${response.headers['Content-Length']}     0   msg=请求图片失败  #图片不能为空

send get request and verify
    [arguments]     ${path}     ${expected}=操作成功     &{params}
    [Return]    ${response}
    ${response}=    send get    ${path}     &{params}
    response should be correct  ${response}     expected_value=${expected}

send post request and verify
    [arguments]     ${path}     ${expected}=操作成功     &{params}
    [Return]    ${response}
    ${response}=    send post    ${path}     &{params}
    response should be correct  ${response}     expected_value=${expected}

clear data
    [Documentation]  清除专网数据》清除公网数据》清除redis缓存
    [arguments]     ${id_card}      ${phone}
    #获取用户信息，以便删除相关redis
    ${pvt_user_info}          query     select id,unq_key from edl_private.user where id_card='${id_card}'
    ${pub_user_info}          query     select id from edl_public.user where phone='${phone}'
    #删除专网数据
    execute sql     delete from edl_private.user where id_card in ('${id_card}')    #删除专网user表数据
    execute sql     delete from edl_private.vehicle_bind_his where vehicle_bind_id in (select id from edl_private.vehicle_bind where id_card in ('${id_card}'))#删除绑车历史数据
    execute sql     delete from edl_private.vehicle_bind where id_card in ('${id_card}')    #删除绑车数据
    execute sql     delete from edl_private.drv_veh_bind_count where id_card in ('${id_card}')  #删除本市绑车数量
    execute sql     delete from edl_private.drv_veh_other_city_bind_count where user_id in (select id from edl_private.user where id_card in ('${id_card}'))    #删除非本市车辆
    #删除公网数据
    execute sql     delete from edl_public.user_face where user_id in (select id from edl_public.user where phone in ('${phone}'))  #删除人脸数据
    execute sql     update edl_public.user set name=NULL,id_card=NULL,city_id=NULL,bind_edl_flag=0,has_face_image_flag=0,sex=0 where phone='${phone}'   #清空user激活数据
    #删除redis
    delete redis value    bmc:c1:dl:idCard:${id_card}
    delete redis value    bmc:c1:user:idCard:${id_card}
    run keyword if      ${pvt_user_info}        delete redis value    bmc:c1:user:uid:${pvt_user_info}[0][0]
    run keyword if      ${pvt_user_info}        delete redis value    bmc:c1:user:unqKey:${pvt_user_info}[0][1]
    run keyword if      ${pub_user_info}        delete redis value    bmc:c2:userById:a:${pub_user_info}[0][0]
    run keyword if      ${pub_user_info}        delete redis value    edl:pub:token:${pub_user_info}[0][0]:mobile
    delete redis value    bmc:c2:userByPhone:a:${phone}
    delete redis value    bmc:c2:userByIdCard:a:${id_card}
    delete redis value    edl:sms_total:${phone}

clear new user data
    [arguments]  ${phone}
    #查询公网用户id
    ${pub_user_id}          query     select id from edl_public.user where phone='${phone}'
    #删除已注册用户
    execute sql     delete from edl_public.user where phone='${new-user-phone}'
    #删除redis信息
    delete redis value    bmc:c2:userById:a:${pub_user_id}
    delete redis value    bmc:c2:userByPhone:a:${phone}

clear insurance data
    [arguments]   ${vehicle_identify_num}
    ${vehicle_id}   query   SELECT vehicle_id FROM edl_private.vehicle_bind where vehicle_identify_num=${vehicle_identify_num}
    delete redis value      bmc:c1:veh:compulsory:${vehicle_id}[0][0]
    delete redis value      bmc:c1:veh:commercial:${vehicle_id}[0][0]
    execute sql  delete from edl_private.compulsory_ins_info where plate_num=${vehicle_identify_num}
    execute sql  delete from edl_private.commercial_ins_info where plate_num=${vehicle_identify_num}
