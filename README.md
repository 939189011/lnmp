​                                                                         **一键部署lnmp**

------

1. 一键YUM部署LNMP版本：

```shell
适合Centos7_x86_64以上系统  #纯净系统                         
Nginx version: nginx/1.20.2                         
Mysql version: Distrib 5.7.36                       
PHP version: PHP 7.1.33 
```

2. 一键命令：(部署完成MYSQL root密码为：qdx20211210)

   ```shell
   yum install git -y && git clone https://github.com/939189011/lnmp.git && cd lnmp && chmod +x lnmp.sh && bash lnmp.sh
   ```

3. 一键命令：(MYSQL root密码可以自定义输入)

   ```shell
   yum install git -y && git clone https://github.com/939189011/lnmp.git && cd lnmp && chmod +x lnmp-zdymima.sh && bash lnmp-zdymima.sh
   ```
