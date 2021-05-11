*** Settings ***
Library         ../Libs/AppiumRF.py  ../Resources/Android元素定位器
Library         ../Libs/CommonTools.py
Library         ../Libs/MysqlRF.py      10.197.236.190      root        123456      edl_private
Library         ../Libs/RedisRF.py      10.197.236.195

*** Test Cases ***
验证码激活信用
    clear data        ${id_card}      ${phone}
    login       ${phone}     ${password}
    click element       首页》立即激活按钮
    ${permission}       visible or not      激活信用》授权按钮
    run keyword if      ${permission}       click element       激活信用》授权按钮
    run keyword if      ${permission}       go back
    run keyword if      ${permission}       click element       首页》立即激活按钮
    sleep  2
    click element at coordinates    357     1303
    input value       激活信用》姓名输入框      ${name}
    input value       激活信用》身份证号输入框    ${id_card}
    click element       激活信用》身份验证下一步按钮
    ${permission}       visible or not      激活信用》授权按钮
    run keyword if      ${permission}       click element       激活信用》授权按钮
    wait until element is visible      激活信用》超时验证码认证按钮      timeout=20
    click element       激活信用》超时验证码认证按钮
    sleep       3
    ${verify_code}      get redis value  edl:sms_value:${phone}:active_credit
    should not be equal      ${verify_code}     ${None}     msg=获取验证码失败
    input value       激活信用》验证码输入框     ${verify_code}
    click element       激活信用》验证码认证确认按钮
    click element       激活信用》立即使用按钮
    wait until element is visible      首页》语音播报       timeout=10      error=激活信用失败
    click element          首页》业务区》我的车辆》我的车辆入口按钮
    element should be visible   首页》业务区》我的车辆》车辆列表》车辆信息框

添加车辆
    login       ${phone_activated}     ${id_card_activated}
    click element          首页》业务区》我的车辆》我的车辆入口按钮
    ${has_cars}     visible or not      首页》业务区》我的车辆》车辆列表》添加车辆按钮
    run keyword if      ${has_cars}            click element   首页》业务区》我的车辆》车辆列表》添加车辆按钮
    ...     ELSE        click element       首页》业务区》我的车辆》车辆列表》没有车时的添加车辆按钮
    click element       首页》业务区》我的车辆》添加车辆》手动添加按钮
    click element   首页》业务区》我的车辆》添加车辆》车牌类型选择按钮
    click text      小型汽车
    #click element   首页》业务区》我的车辆》添加车辆》号牌号码输入框
    #input text      首页》业务区》我的车辆》添加车辆》号牌号码输入矩形框1      贵
    input text       首页》业务区》我的车辆》添加车辆》车主姓名输入框       test

测试
    clear data      ${id_card}        ${phone}
*** Variables ***
${platformName}     Android
${appium_server}    http://localhost:4723/wd/hub
${appPackage}      com.hikcreate.elecdrivlic
${appActivity}     .ui.comm.WelcomeActivity
${name}             zhaoritian
${id_card}          520101199608018458
${phone}            17128240042
${id_card_activated}          520101198709015411
${phone_activated}            17128240047
${password}         hik123456
*** Keywords ***
clear data
    [arguments]     ${id_card}      ${phone}
    [Documentation]  清除专网数据》清除公网数据》清除redis缓存
    execute sql     delete from edl_private.user where id_card in ('${id_card}')
    execute sql     delete from edl_private.vehicle_bind_his where vehicle_bind_id in (select id from edl_private.vehicle_bind where id_card in ('${id_card}'))
    execute sql     delete from edl_private.vehicle_bind where id_card in ('${id_card}')
    execute sql     delete from edl_private.drv_veh_bind_count where id_card in ('${id_card}')
    execute sql     delete from edl_private.drv_veh_other_city_bind_count where user_id in (select id from edl_private.user where id_card in ('${id_card}'))

    execute sql     delete from edl_public.user_face where user_id in (select id from edl_public.user where phone in ('${phone}'))
    execute sql     update edl_public.user set name=NULL,id_card=NULL,city_id=NULL,bind_edl_flag=0,has_face_image_flag=0,sex=0 where phone='${phone}'

    ${pvt_user_info}          query     select id,unq_key from edl_private.user where id_card='${id_card}'
    ${pub_user_info}          query     select id from edl_public.user where phone='${phone}'
    delete redis value    bmc:c1:dl:idCard:${id_card}
    delete redis value    bmc:c1:user:idCard:${id_card}
    run keyword if      ${pvt_user_info}        delete redis value    bmc:c1:user:uid:${pvt_user_info}[0][0]
    run keyword if      ${pvt_user_info}        delete redis value    bmc:c1:user:unqKey:${pvt_user_info}[0][1]
    run keyword if      ${pub_user_info}        delete redis value    bmc:c2:userById:a:${pub_user_info}[0][0]
    run keyword if      ${pub_user_info}        delete redis value    edl:pub:token:${pub_user_info}[0][0]:mobile
    delete redis value    bmc:c2:userByPhone:a:${phone}
    delete redis value    bmc:c2:userByIdCard:a:${id_card}
    delete redis value    edl:sms_total:${phone}

login
    [arguments]     ${phone}        ${password}
    open app
    close popup window      首页》弹窗》应急劵广告
    ${private_center_visible}   visible or not      我的》我的按钮
    run keyword if  ${private_center_visible}    click element   我的》我的按钮
    ${already_login}    visible or not      我的》设置按钮
    run keyword if      ${already_login}        run keyword and return      click element   首页》首页按钮
    ${phone_value}  get text  账号输入》手机号码输入框
    run keyword if  "${phone_value}"!="${phone}"    clear and intput    账号输入》手机号码输入框    ${phone}
    click element   账号输入》下一步按钮
    ${gesture}      visible or not      手势登陆》字符密码登陆入口
    run keyword if  ${gesture}      click element   手势登陆》字符密码登陆入口
    input value   密码登录》密码输入框       hik123456
    click element   密码登录》登录按钮
    close popup window      首页》弹窗》应急劵广告
    click element   我的》我的按钮
    element should be visible   我的》设置按钮
    click element   首页》首页按钮

open app
    &{device}   get device info     ${platformName}
    open application        ${appium_server}    platformName=${platformName}    platformVersion=&{device}[version]  deviceName=&{device}[name]  appPackage=${appPackage}    appActivity=${appActivity}

close popup window
    [Documentation]  删除广告弹窗+引导页
    [arguments]     ${locator}
     ${window}           visible or not   首页》弹窗》应急劵广告
    run keyword if      ${window}       click element   首页》弹窗》应急劵广告
    ${guid_page}        visible or not    首页》弹窗》引导页跳过按钮
    run keyword if      ${guid_page}    click element   首页》弹窗》引导页跳过按钮