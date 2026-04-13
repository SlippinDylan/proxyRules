# Mihomo OpenWrt 配置说明

本文档说明普通 Mihomo 内核下，如何理解和维护 `configFile/mihomo.yaml` 这类 OpenWrt 透明代理配置。

这里的“普通 Mihomo”指 MetaCubeX/mihomo 官方内核支持的通用能力，例如 `select`、`url-test`、`fallback`、`load-balance`、`rule-providers`、`tun`、`listeners`、`dns`、`sniffer` 等。它不包含 `type: smart` 这类 Smart Core 扩展策略组。

## 配置定位

`mihomo.yaml` 是面向 OpenWrt 网关环境的配置，和移动端 Stash 配置不同，它需要承担局域网透明代理职责。

当前配置重点包括：

- 通过 `tun`、`redir`、`tproxy` 入站承接 OpenWrt 上的透明代理流量。
- 通过 `allow-lan: true` 和 `bind-address: "*"` 服务局域网设备。
- 使用 Fake-IP DNS 与规则集配合分流。
- 使用 `rule-providers` 远程规则集合减少本地规则体积。
- 通过业务策略组把 AI、开发、Apple、Microsoft、Google、Telegram、流媒体等服务分开管理。

## 普通 Mihomo 与 Smart Mihomo 的区别

普通 Mihomo 官方策略组主要使用：

- `select`
- `url-test`
- `fallback`
- `load-balance`
- `relay`

如果你的内核不是 Smart Core，不要使用：

```yaml
type: smart
first-test: true
uselightgbm: false
collectdata: false
policy-priority: ...
```

这些字段应放到 Smart 专用配置里。普通 Mihomo 配置建议把 Smart 节点池替换为 `url-test` 或 `fallback`。

例如当前 Smart 写法：

```yaml
- {name: 🇯🇵 日本Smart, type: smart, use: *mainUse, first-test: true, interval: 60, filter: *jp_filter}
```

普通 Mihomo 可改为：

```yaml
- {name: 🇯🇵 日本, type: url-test, use: *mainUse, interval: 180, tolerance: 10, filter: *jp_filter}
```

同时需要把上游策略组里的引用一起改掉，例如从 `🇯🇵 日本Smart` 改成 `🇯🇵 日本`。

## 入站与 OpenWrt 透明代理

`mihomo.yaml` 里同时保留了 `tun` 和 `listeners`：

```yaml
tun: {enable: true, stack: mixed, dns-hijack: ["any:53", "tcp://any:53"], auto-route: true, auto-redirect: true, auto-detect-interface: true}
listeners: [{name: redir-in, type: redir, port: 7891, udp: false}, {name: tproxy-in, type: tproxy, port: 7892, udp: true}, {name: tun-in, type: tun, device: immortalwrt, stack: mixed, auto-route: false, auto-redirect: false, auto-detect-interface: false}]
```

这类写法适合 OpenWrt 网关，因为局域网设备的 TCP/UDP 流量需要被路由器接管。

维护建议：

- `redir` 主要处理 TCP 透明代理。
- `tproxy` 适合处理 UDP 和更完整的透明代理场景。
- `tun` 可以承接系统路由与 DNS 劫持。
- 如果 OpenWrt 插件已经自动管理防火墙、路由和 TUN，不要重复开启冲突的 auto-route 逻辑。

## DNS 设计

当前配置的 DNS 是网关配置的核心之一：

```yaml
dns:
  enable: true
  listen: 0.0.0.0:1053
  respect-rules: true
  enhanced-mode: fake-ip
  fake-ip-range: 198.18.0.1/16
```

关键点：

- `listen: 0.0.0.0:1053` 适合被 OpenWrt 本机 DNS 转发到 Mihomo。
- `respect-rules: true` 表示 DNS 查询会尽量跟随规则路径，避免代理域名被错误直连解析。
- `enhanced-mode: fake-ip` 能提升代理场景下的分流稳定性。
- `fake-ip-filter` 用于排除时间同步、内网、本地域名、国内规则集等不适合 Fake-IP 的对象。

当前配置还区分了：

- `default-nameserver`：解析 DNS 服务器域名时使用。
- `proxy-server-nameserver`：解析代理节点域名时使用。
- `direct-nameserver`：直连出口域名解析使用。
- `nameserver-policy`：按规则集或域名指定 DNS。

在 OpenWrt 上，如果发现国内 App 异常、NTP 时间失败、局域网服务不可达，应优先检查 `fake-ip-filter` 和 `nameserver-policy`。

## Sniffer

`sniffer` 用于从 HTTP/TLS/QUIC 流量中嗅探真实域名，帮助规则命中：

```yaml
sniffer:
  enable: true
  sniff:
    HTTP: {ports: [80, 8080-8880], override-destination: true}
    TLS: {ports: [443, 8443], override-destination: true}
    QUIC: {ports: [443, 8443], override-destination: true}
```

维护建议：

- 对常见 HTTPS 流量，TLS/QUIC 嗅探有助于域名规则命中。
- 对内网、时间同步、Apple Push、微信、本地设备等，建议放入 `skip-domain`，避免错误改写目标。
- `force-domain` 可以强制某些域名或规则集参与嗅探，但不要把混合 IP 的 `classical` 规则集随便放进去。

## Proxy Providers

`proxy-providers` 用来拉取机场订阅：

```yaml
proxy-providers:
  wd-gold:
    <<: *directProvider
    url: "订阅链接"
  guar:
    <<: *directProvider
    url: "订阅链接"
```

模板里包含：

- `type: http`
- `interval: 3600`
- `health-check`
- `header`
- `override`
- `proxy`

`proxy` 字段决定订阅更新通过哪个出口下载。OpenWrt 网关上如果订阅更新失败，优先检查这里是走直连还是代理。

## Rule Providers

普通 Mihomo 支持 `rule-providers`，官方字段重点是：

- `type`
- `url`
- `interval`
- `proxy`
- `behavior`
- `format`

`behavior` 可用：

- `domain`
- `ipcidr`
- `classical`

`format` 可用：

- `yaml`
- `text`
- `mrs`

当前 `mihomo.yaml` 使用了 MRS 规则集：

```yaml
rule-anchor:
  domain: &domain {type: http, interval: 21600, behavior: domain, format: mrs}
  class: &class {type: http, interval: 21600, behavior: classical, format: text}
  ip: &ip {type: http, interval: 21600, behavior: ipcidr, format: mrs}
```

这套设计的含义是：

- MetaCubeX `geosite/*.mrs` 使用 `domain + mrs`。
- MetaCubeX `geoip/*.mrs` 使用 `ipcidr + mrs`。
- 自己维护的 `ruleProvider/*.list` 是 Clash 文本规则行，使用 `classical + text`。

注意：`mrs` 只适合 `domain` 和 `ipcidr`。如果规则内容是 `DOMAIN-SUFFIX,...`、`IP-CIDR,...` 这种 Clash 规则行，应继续使用 `classical + text`。

## Proxy Groups

普通 Mihomo 推荐把节点池写成标准策略组：

```yaml
- {name: 🇭🇰 港澳台, type: url-test, use: *mainUse, interval: 180, tolerance: 10, filter: *gmt_filter}
- {name: 🇯🇵 日本, type: url-test, use: *mainUse, interval: 180, tolerance: 10, filter: *jp_filter}
- {name: 🧩 备份节点, type: fallback, use: *backupUse, interval: 180, tolerance: 10, filter: *all_filter}
- {name: 🛰 所有节点, type: select, use: *allUse, filter: *all_filter}
```

建议分层：

- 顶层入口：`🚀 代理主线`、`🔗 直连主线`。
- 业务策略组：Apple、Microsoft、Google、AI、开发、Telegram、流媒体等。
- 节点池：按地区、家宽、全量节点分类。

这种结构比直接在 `rules` 里写具体节点更容易维护。

## Rules 顺序

当前规则顺序适合 OpenWrt 网关：

1. 内网设备源地址规则先处理，例如 `SRC-IP-CIDR`。
2. 时间同步和 NTP 优先处理。
3. 私有地址和个人规则前置。
4. AI、开发、Apple、Microsoft、Google 等业务规则。
5. 社交、流媒体、金融、测速等服务规则。
6. `proxy_domain`、`gfw_domain`、`geolocation_notcn_domain` 作为国际代理兜底。
7. `cn_domain`、`cn_ip` 作为国内直连兜底。
8. IP 规则尽量加 `no-resolve`。
9. 最后用 `MATCH` 收尾。

不要把 `MATCH` 放到中间，也不要把大范围代理规则放在个人直连规则之前。

## 普通 Mihomo 迁移清单

如果要从当前 Smart 写法迁移到普通 Mihomo：

- 把所有 `type: smart` 改为 `url-test`、`fallback` 或 `select`。
- 删除 `first-test`、`uselightgbm`、`collectdata`、`policy-priority` 等 Smart 字段。
- 把 `🇭🇰 港澳台Smart` 这类名称改成普通名称，或保留名称但改掉类型。
- 确保 `proxymain` 里的节点池名称和实际 `proxy-groups` 一致。
- 保留 `rule-providers` 的 `format: mrs/text`，不要因为改策略组而改规则集格式。
- 修改后用 Mihomo/OpenClash 日志确认每个 provider 和 proxy-provider 都能正常更新。

## 官方参考

- Mihomo 配置文档：https://wiki.metacubex.one/en/config/
- DNS：https://wiki.metacubex.one/en/config/dns/
- TUN：https://wiki.metacubex.one/en/config/inbound/tun/
- Listeners：https://wiki.metacubex.one/en/config/inbound/listeners/
- Proxy Providers：https://wiki.metacubex.one/en/config/proxy-providers/
- Proxy Groups：https://wiki.metacubex.one/en/config/proxy-groups/
- Route Rules：https://wiki.metacubex.one/en/config/rules/
- Rule Providers：https://wiki.metacubex.one/en/config/rule-providers/
