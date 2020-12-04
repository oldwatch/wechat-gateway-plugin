#/bin/bash

cd commons
luarocks make --local
cd ..
cd wechat-app-plugin
luarocks make --local
cd ..
cd wechat-callback-plugin
luarocks make --local
cd ..
cd wechat-pay-plugin
luarocks make --local
cd ..
cd mock-redirect
luarocks make --local
cd ..
cd cache-maintain-plugin
luarocks make --local
cd ..
sudo /usr/local/bin/kong restart
