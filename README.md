# wechat-gateway-plugin

wechat api support
实现语言lua
技术平台Kong/openResty
部署模型：kong plugin

包括plugin源码和部分修改定制的lua公共包（为了满足wechat api 加解密需求）

存储使用redis

对wechat  api的技术功能（token绑定，支付网关签名/加密/回包验签，推送回包验签/解密）的封装
网关后的业务应用可以无感知使用wechat api

支持wechat 支付接口v2/v3（v2版支付对nginx/openResty版本有要求）

