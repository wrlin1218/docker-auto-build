#!/bin/sh
# Check if runtime config exists
if [ -f /config/config_runtime.json ]; then
  echo "Found existing config_runtime.json, using it."
  cp /config/config_runtime.json /config.json
  # Also print the info if available
  if [ -f /config/config_info.txt ]; then
    cat /config/config_info.txt
  fi
else
  # No runtime config, start fresh initialization
  echo "No existing config found. Starting initialization..."
  
  IPV6=$(curl -6 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  IPV4=$(curl -4 -sSL --connect-timeout 3 --retry 2  ip.sb || echo "null")
  
  # 自动生成UUID
  UUID="$(/xray uuid)"
  echo "UUID: $UUID"

  # 设置默认端口
  if [ -z "$EXTERNAL_PORT" ]; then
    echo "EXTERNAL_PORT is not set. default value 443"
    EXTERNAL_PORT="443"
  fi

  # 设置DEST默认值
  if [ -z "$DEST" ]; then
    echo "DEST is not set. default value www.apple.com:443"
    DEST="www.apple.com:443"
  fi

  # 设置SERVERNAMES默认值
  if [ -z "$SERVERNAMES" ]; then
    echo "SERVERNAMES is not set. use default value [\"www.apple.com\",\"images.apple.com\"]"
    SERVERNAMES="www.apple.com images.apple.com"
  fi

  # 自动生成密钥对
  echo "Generating new key pair"
  /xray x25519 >/key
  # 新版 xray 输出格式: PrivateKey / Password (客户端公钥) / Hash32
  PRIVATEKEY=$(cat /key | grep "PrivateKey" | awk -F ': ' '{print $2}')
  PUBLICKEY=$(cat /key | grep "Password" | awk -F ': ' '{print $2}')
  echo "Private key: $PRIVATEKEY"
  echo "Public key: $PUBLICKEY"

  # 设置默认网络类型
  NETWORK="tcp"

  # 修改配置
  jq ".inbounds[1].settings.clients[0].id=\"$UUID\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[1].streamSettings.realitySettings.dest=\"$DEST\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  SERVERNAMES_JSON_ARRAY="$(echo "[$(echo $SERVERNAMES | awk '{for(i=1;i<=NF;i++) printf "\"%s\",", $i}' | sed 's/,$//')]")"
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.inbounds[1].streamSettings.realitySettings.serverNames = $serverNames' /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq --argjson serverNames "$SERVERNAMES_JSON_ARRAY" '.routing.rules[0].domain = $serverNames' /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  jq ".inbounds[1].streamSettings.realitySettings.privateKey=\"$PRIVATEKEY\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json
  jq ".inbounds[1].streamSettings.network=\"$NETWORK\"" /config.json >/config.json_tmp && mv /config.json_tmp /config.json

  FIRST_SERVERNAME=$(echo $SERVERNAMES | awk '{print $1}')
  # 生成配置信息
  echo -e "\033[32m" >/config/config_info.txt
  echo "IPV6: $IPV6" >>/config/config_info.txt
  echo "IPV4: $IPV4" >>/config/config_info.txt
  echo "UUID: $UUID" >>/config/config_info.txt
  echo "DEST: $DEST" >>/config/config_info.txt
  echo "PORT: $EXTERNAL_PORT" >>/config/config_info.txt
  echo "SERVERNAMES: $SERVERNAMES (任选其一)" >>/config/config_info.txt
  echo "PRIVATEKEY: $PRIVATEKEY" >>/config/config_info.txt
  echo "PUBLICKEY: $PUBLICKEY" >>/config/config_info.txt
  echo "NETWORK: $NETWORK" >>/config/config_info.txt
  if [ "$IPV4" != "null" ]; then
    SUB_IPV4="vless://$UUID@$IPV4:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV4}-Reality"
    echo "IPV4 订阅连接: $SUB_IPV4" >>/config/config_info.txt
    echo -e "IPV4 订阅二维码:\n$(echo "$SUB_IPV4" | qrencode -o - -t UTF8)" >>/config/config_info.txt
  fi
  if [ "$IPV6" != "null" ];then
    SUB_IPV6="vless://$UUID@$IPV6:$EXTERNAL_PORT?encryption=none&security=reality&type=$NETWORK&sni=$FIRST_SERVERNAME&fp=chrome&pbk=$PUBLICKEY&flow=xtls-rprx-vision#${IPV6}-Reality"
    echo "IPV6 订阅连接: $SUB_IPV6" >>/config/config_info.txt
    echo -e "IPV6 订阅二维码:\n$(echo "$SUB_IPV6" | qrencode -o - -t UTF8)" >>/config/config_info.txt
  fi

  echo -e "\033[0m" >>/config/config_info.txt
  
  # Show config info
  cat /config/config_info.txt

  # Save the generated config for persistence
  echo "Persisting configuration to /config/config_runtime.json"
  cp /config.json /config/config_runtime.json
fi

# 运行xray
exec /xray -config /config.json