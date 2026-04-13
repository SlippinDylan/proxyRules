# Stash 配置说明

本文档说明当前项目中的 `configFile/stash.yaml`。它综合了 `stash/stash.from_mihomoai.md` 的配置解释和 `stash/stash 规则说明.md` 中与本配置有关的 Stash 官方规则、规则集合、策略组、远程代理集、DNS 要点。

这份文档只解释当前仓库里实际使用的能力，不展开 MitM、HTTP rewrite、脚本、面板、覆写等暂未接入的功能。

## 配置定位

`configFile/stash.yaml` 是给 iPhone / iPad 上的 Stash 使用的移动端配置。它继承了 `mihomo.yaml` 的主要分流思路，但去掉了更适合路由器或桌面代理环境的内容。

当前配置的目标是：

- 国内服务、私有地址、指定直连服务走 `🔗 直连主线`。
- 国外服务、GFW、非中国区服务走 `🌐 国际代理` 或对应业务策略组。
- Apple、Microsoft、Google、Telegram、流媒体、AI、开发、金融、测速等服务独立分流。
- 所有未命中的连接最终走 `🐠 漏网之鱼`。

这符合 Stash 的规则模式：`rules` 从上到下依次匹配，命中后交给对应的代理、策略组或内置出站处理。

## 文件结构

当前 `stash.yaml` 的主要结构如下：

- `filters`：节点筛选正则，供策略组的 `filter` 使用。
- `group-template`：策略组锚点模板，减少重复写法。
- `rule-providers-template`：规则集合锚点模板，统一 `behavior` / `format`。
- `proxy-providers`：远程机场订阅。
- `proxies`：本地静态代理，目前只有 `直接连接`。
- `mode` / `log-level` / `ipv6`：基础运行参数。
- `dns`：Stash 内置 DNS 配置。
- `proxy-groups`：业务策略组和节点池。
- `rules`：最终分流规则顺序。
- `rule-providers`：远程规则集合来源。

## YAML 锚点

当前配置大量使用 YAML 锚点，目的是减少重复字段。

`group-template` 定义了两个策略组模板：

- `*proxyMain`：默认优先选择代理链路，适合国际服务。
- `*directMain`：默认优先选择直连链路，适合国内或本地优先服务。

业务策略组通过 `<<: *proxyMain` 或 `<<: *directMain` 继承模板，再单独指定 `name`。

`rule-providers-template` 定义了规则集合模板。这里的重点不是扩展名，而是 Stash 解析规则集合时需要 `behavior` 和 `format` 同时正确。

当前模板是：

```yaml
domain:      &domain      {type: http, interval: 21600, behavior: domain, format: text}
domain-text: &domainText  {type: http, interval: 21600, behavior: domain, format: text}
classical:   &classical   {type: http, interval: 21600, behavior: classical, format: text}
ipcidr:      &ipcidr      {type: http, interval: 21600, behavior: ipcidr, format: text}
ipcidr-text: &ipcidrText  {type: http, interval: 21600, behavior: ipcidr, format: text}
```

这里保留 `domain-text` 和 `ipcidr-text` 只是为了让 provider 名称读起来更直观；实际 Stash 官方字段仍然是 `behavior: domain/ipcidr` 加 `format: text`。

## Rule Providers

Stash 的 `rule-providers` 用来引用大量远程规则，并通过 `rules` 里的 `RULE-SET` 调用。官方格式核心是：

```yaml
rule-providers:
  example:
    type: http
    behavior: domain
    format: text
    url: https://example.com/rules.txt
    interval: 86400
```

本配置的对应关系如下：

| 来源 | 文件形式 | 内容形态 | 使用模板 |
| --- | --- | --- | --- |
| MetaCubeX `geo/geosite/*.list` | `.list` | 域名、域名通配符，例如 `+.github.com` | `*domain` |
| MetaCubeX `geo/geoip/*.list` | `.list` | IPv4/IPv6 CIDR，例如 `8.8.8.0/24` | `*ipcidr` |
| peiyingyao `*_Domain.txt` | `.txt` | 域名、域名通配符 | `*domainText` |
| peiyingyao `*_IP.txt` | `.txt` | IPv4/IPv6 CIDR | `*ipcidrText` |
| SlippinDylan `ruleProvider/*.list` | `.list` | Clash 规则行，例如 `DOMAIN-SUFFIX,...` / `IP-CIDR,...` | `*classical` |

这也是当前配置里必须显式写 `format: text` 的原因。Stash 支持 `yaml`、`text`、`mrs` 等格式，默认行为不能依赖文件扩展名推断。`.list` 不等于 MRS；当前这些 `.list` 都是文本规则集合。

### 什么时候用 `domain`

用在纯域名或域名通配符列表，例如：

```text
github.com
+.github.com
```

当前 MetaCubeX `geosite` 和 peiyingyao `Domain.txt` 属于这一类。此类规则匹配性能较好，适合大量域名。

### 什么时候用 `ipcidr`

用在纯 IP CIDR 列表，例如：

```text
8.8.8.0/24
1.1.1.1/32
```

当前 MetaCubeX `geoip` 和 peiyingyao `IP.txt` 属于这一类。引用这些规则时，`rules` 里可以根据场景加 `no-resolve`，避免额外 DNS 解析。

### 什么时候用 `classical`

用在 Clash 规则行或混合类型规则，例如：

```text
DOMAIN-SUFFIX,example.com
DOMAIN,api.example.com
DOMAIN-KEYWORD,example
IP-CIDR,192.0.2.0/24,no-resolve
```

当前 `ruleProvider/develop.list`、`proxy.list`、`direct.list`、`torrent.list` 都属于这一类，因为它们不是纯域名列表，也不是纯 CIDR 列表。

`classical` 灵活但匹配成本更高。大量规则优先拆成 `domain` 或 `ipcidr` 更合适。

## Proxy Providers

`proxy-providers` 定义远程机场订阅，当前有：

- `wd-gold`
- `guar`

这些 provider 被节点池通过 `use` 引用。例如日本、新加坡、美国等 `url-test` 节点池目前主要使用 `wd-gold`，备份节点池同时使用 `wd-gold` 和 `guar`。

Stash 的远程代理集负责定时拉取订阅、解析节点，并交给 `proxy-groups` 使用。订阅 URL 当前在公开配置中用占位文本表示，实际使用时需要替换为有效订阅链接。

## Proxy Groups

`proxy-groups` 是策略选择的核心。本配置分三层：

### 顶层通道

- `🚀 代理主线`：代理流量的主入口。
- `🔗 直连主线`：直连流量的主入口。

顶层通道用于给业务策略组提供统一出口，避免每条规则直接绑定具体节点。

### 业务策略组

业务策略组按服务类型分流：

- `🌐 国际代理`
- `🐠 漏网之鱼`
- `🍎 Apple`
- `🍎 ApplePxy`
- `☁️ MicrosoftCN`
- `Ⓜ️ Microsoft`
- `🅖 Google`
- `🦑 Develop`
- `🧠 Intelligence`
- `🛩️ Telegram`
- `📺 流媒体`
- `🎵 Spotify`
- `🎬 TikTok`
- `💰 Wallet`
- `⏱ Speedtest`

其中大部分组继承 `*proxyMain`，国内优先或直连优先的组继承 `*directMain`。

### 节点池

节点池负责实际选择节点：

- `🇭🇰 港澳台`
- `🇯🇵 日本`
- `🇸🇬 新加坡`
- `🇺🇸 美国`
- `🧩 备份节点`
- `🏠 家宽节点`
- `🌍 环球节点`
- `🛰 所有节点`

当前使用的 Stash 策略类型包括：

- `url-test`：定时测试延迟，自动选择延迟较低节点。
- `fallback`：按列表顺序选择第一个可用节点。
- `select`：手动选择。

这里没有使用 Mihomo 的 `smart`，因为 Stash 官方策略组类型不包含该类型。

## DNS 设计

当前 DNS 使用 Stash 内置 DNS，并开启：

- `enhanced-mode: fake-ip`
- `fake-ip-range: 198.18.0.1/16`
- `skip-cert-verify: true`

`default-nameserver` 用国内公共 DNS IP 引导解析 DoH 域名：

- `119.29.29.29`
- `223.5.5.5`

`nameserver` 使用两个国内 DoH：

- `https://doh.pub/dns-query`
- `https://dns.alidns.com/dns-query`

`nameserver-policy` 对常见国内域名指定国内 DNS，避免国内域名被污染或绕远。

`fake-ip-filter` 排除以下类型：

- NTP / time 时间同步域名。
- STUN 相关实时通信域名。
- Microsoft 连通性检测域名。
- 常见国内服务域名。
- 开发镜像站。

这些排除项的目标是避免 Fake-IP 影响系统时间、网络探测、国内 App 和部分实时通信。

## Rules 匹配顺序

Stash 规则按从上到下匹配，命中第一条后停止继续匹配。当前顺序是：

1. 时间同步优先：`DST-PORT,123` 和 NTP 规则集先处理。
2. 私有地址直连。
3. 个人自定义规则前置，包括代理、直连、BT。
4. AI 服务规则。
5. 开发工具规则。
6. Apple、Microsoft、Google、YouTube。
7. 社交、Telegram、论坛。
8. 流媒体、Spotify、TikTok、成人内容、全球媒体。
9. 群晖、银行、PayPal、测速。
10. 全局代理兜底域名：`proxy_domain`、`gfw_domain`、`geolocation_notcn_domain`。
11. 国内域名直连：`cn_domain`。
12. IP 规则，包括 AI、Apple、流媒体、Google、Telegram、中国 IP。
13. 最终 `MATCH,🐠 漏网之鱼`。

这个顺序的原则是：小范围、确定性强、个人自定义的规则放前面；大范围兜底规则放后面；IP 类规则靠后并尽量使用 `no-resolve`。

## 规则类型速查

当前项目最常见的规则类型是：

- `DOMAIN`：完整域名匹配。
- `DOMAIN-SUFFIX`：域名后缀匹配。
- `DOMAIN-KEYWORD`：域名关键词匹配。
- `IP-CIDR` / `IP-CIDR6`：CIDR 匹配。
- `DST-PORT`：目标端口匹配。
- `RULE-SET`：引用 `rule-providers` 中声明的规则集合。
- `MATCH`：最终兜底。

iOS / tvOS 上不要依赖 `PROCESS-NAME` 或 `PROCESS-PATH`，因为 Network Extension 环境下进程相关规则不可用或会被忽略。

## 从 Mihomo 配置迁移时的取舍

这份 Stash 配置不是 `mihomo.yaml` 的一比一复制。它刻意删除或避免了这些内容：

- `tun`
- `listeners`
- 局域网设备源地址规则，例如 `SRC-IP-CIDR`
- 主路由专用 `hosts`
- Mihomo 专属 `smart`
- 路由器网关模式相关逻辑

保留的是移动端 Stash 可运行且有价值的部分：

- 分流规则顺序。
- 远程规则集合。
- 机场订阅和策略组。
- DNS 与 Fake-IP。
- 自定义规则列表。

## 维护建议

维护这份配置时优先检查以下几点：

- 新增规则集合时先看内容形态，再决定 `behavior` 和 `format`，不要只看扩展名。
- `MetaCubeX geosite` 这类域名列表优先用 `domain + text`。
- `MetaCubeX geoip` 这类 CIDR 列表优先用 `ipcidr + text`。
- 混合了 `DOMAIN-SUFFIX`、`IP-CIDR` 等 Clash 规则行时用 `classical + text`。
- `rules` 中个人自定义规则继续放在通用规则前面，避免被大范围规则提前命中。
- `MATCH` 必须保留在最后。
- 如果规则集拉取数量为 0，优先检查 `format` 是否写成了实际内容格式。
- 如果节点池为空，优先检查订阅是否可拉取，再检查节点名是否被 `filter` 排除了。
- iOS 上 DNS 和规则集数量不要过度膨胀，避免耗电和内存压力。

## 官方参考

- Stash 首页：https://stash.wiki/
- 规则类型：https://stash.wiki/rules/rule-types
- 规则集合：https://stash.wiki/rules/rule-set
- 策略组：https://stash.wiki/proxy-protocols/proxy-groups
- 远程代理集：https://stash.wiki/proxy-protocols/proxy-providers
- 配置样例：https://stash.wiki/configuration/example-config
- 编写高效配置：https://stash.wiki/faq/effective-stash
