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

mihomo convert-ruleset domain text develop_domain.txt develop_domain.mrs  && \
mihomo convert-ruleset ipcidr text develop_ip.txt develop_ip.mrs  && \
mihomo convert-ruleset domain text direct_domain.txt direct_domain.mrs  && \
mihomo convert-ruleset domain text intelligence_domain.txt intelligence_domain.mrs  && \
mihomo convert-ruleset domain text proxy_domain.txt proxy_domain.mrs  && \
mihomo convert-ruleset ipcidr text proxy_ip.txt proxy_ip.mrs  && \
mihomo convert-ruleset domain text torrent_domain.txt torrent_domain.mrs  && \
mihomo convert-ruleset ipcidr text torrent_ip.txt torrent_ip.mrs

