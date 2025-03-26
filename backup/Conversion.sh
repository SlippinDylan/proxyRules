# mrs类型ruleset，目前仅支持domain和ipcidr(即不支持classical），
#
# 对于behavior=domain:
#  - format=yaml 可以通过“mihomo convert-ruleset domain yaml XXX.yaml XXX.mrs”转换到mrs格式
#  - format=text 可以通过“mihomo convert-ruleset domain text XXX.text XXX.mrs”转换到mrs格式
#  - XXX.mrs 可以通过"mihomo convert-ruleset domain mrs XXX.mrs XXX.text"转换回text格式（暂不支持转换回yaml格式）
#
# 对于behavior=ipcidr:
#  - format=yaml 可以通过“mihomo convert-ruleset ipcidr yaml XXX.yaml XXX.mrs”转换到mrs格式
#  - format=text 可以通过“mihomo convert-ruleset ipcidr text XXX.text XXX.mrs”转换到mrs格式
#  - XXX.mrs 可以通过"mihomo convert-ruleset ipcidr mrs XXX.mrs XXX.text"转换回text格式（暂不支持转换回yaml格式）


mihomo convert-ruleset domain text XXX.yaml XXX.mrs

mihomo convert-ruleset ipcidr text XXX.yaml XXX.mrs

mihomo convert-ruleset domain text Direct.txt Direct.mrs
mihomo convert-ruleset domain text Proxy-Develop.txt Proxy-Develop.mrs
mihomo convert-ruleset domain text Proxy-Download.txt Proxy-Download.mrs
mihomo convert-ruleset domain text Proxy-Intelligence.txt Proxy-Intelligence.mrs
mihomo convert-ruleset domain text Proxy-Media.txt Proxy-Media.mrs
mihomo convert-ruleset domain text Proxy-Network.txt Proxy-Network.mrs
mihomo convert-ruleset domain text Proxy-Tools.txt Proxy-Tools.mrs


mihomo convert-ruleset ipcidr text Direct-IP.txt Direct-IP.mrs
mihomo convert-ruleset ipcidr text Proxy-Develop-IP.txt Proxy-Develop-IP.mrs
mihomo convert-ruleset ipcidr text Proxy-Tools-IP.txt Proxy-Tools-IP.mrs



mihomo convert-ruleset domain text Direct.txt Direct.mrs
mihomo convert-ruleset domain text Proxy-Develop.txt Proxy-Develop.mrs
mihomo convert-ruleset domain text Proxy-Intelligence.txt Proxy-Intelligence.mrs
mihomo convert-ruleset domain text Proxy-Media.txt Proxy-Media.mrs
mihomo convert-ruleset domain text Proxy.txt Proxy.mrs
mihomo convert-ruleset ipcidr text Direct-IP.txt Direct-IP.mrs
mihomo convert-ruleset ipcidr text Proxy-Develop-IP.txt Proxy-Develop-IP.mrs
mihomo convert-ruleset ipcidr text Proxy-IP.txt Proxy-IP.mrs