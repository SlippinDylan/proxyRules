# Mihomo Smart Core 配置说明

本文档说明 `configFile/mihomo.yaml` 中 Smart 内核相关的配置设计。它和普通 Mihomo 文档配套阅读：普通 Mihomo 使用 `url-test` / `fallback` / `select`，Smart Core 则使用 `type: smart` 作为节点池策略。

重要说明：`type: smart` 不是 MetaCubeX/mihomo 官方通用策略组列表里的标准策略类型。它通常来自带 Smart Core 的客户端或定制内核，例如部分 Mihomo Party / OpenClash Smart Core 环境。因此这份配置必须运行在支持 Smart 策略组的内核上，不能直接拿去普通 Mihomo 使用。

## 当前 Smart 配置定位

当前 `mihomo.yaml` 面向 OpenWrt 网关，并默认使用 Smart 节点池：

- `🇭🇰 港澳台Smart`
- `🇯🇵 日本Smart`
- `🇸🇬 新加坡Smart`
- `🇺🇸 美国Smart`
- `🧩 备份Smart`

顶层代理入口 `🚀 代理主线` 和业务策略组会优先引用这些 Smart 节点池，再回落到家宽、环球、所有节点和直连。

这种结构适合“不想频繁手选节点，但又希望按地区和服务类型自动挑节点”的场景。

## Smart 与普通策略组的差异

普通 Mihomo 的自动选择通常依赖：

- `url-test`：按延迟自动选择。
- `fallback`：按顺序选择首个可用节点。
- `load-balance`：负载均衡。

Smart Core 的目标更偏“基于节点历史表现、策略优先级、测试结果自动选择更合适的节点”。因此当前配置使用：

```yaml
- {name: 🇯🇵 日本Smart, type: smart, use: *mainUse, first-test: true, interval: 60, uselightgbm: false, collectdata: false, filter: *jp_filter}
```

这些字段里，`type: smart` 是关键差异。普通 Mihomo 不认识这个类型时，会导致策略组不可用。

## Smart 节点池字段

当前 Smart 节点池常见字段如下：

- `name`：策略组名称，会被上层策略组引用。
- `type: smart`：启用 Smart 选择逻辑。
- `use`：引用哪些 `proxy-providers`。
- `first-test: true`：首次使用前先进行测试。
- `interval: 60`：测试或更新间隔。
- `uselightgbm: false`：是否使用 LightGBM 相关智能模型能力，取决于 Smart 内核实现。
- `collectdata: false`：是否采集数据用于智能选择，取决于 Smart 内核实现。
- `policy-priority`：节点命中优先级规则。
- `filter`：按节点名称筛选地区或类型。

由于这些字段依赖 Smart 内核实现，不同客户端可能支持程度不同。遇到启动失败时，先看日志中是否提示 unknown group type 或 unknown field。

## 节点筛选器

`filters` 通过正则把机场订阅节点分桶：

- `gmt`：港澳台。
- `jp`：日本。
- `sj`：新加坡。
- `us`：美国。
- `home`：家宽。
- `global`：排除常见地区、家宽、订阅信息后的全球节点。
- `all`：排除订阅信息和异常名称后的全部节点。

Smart 节点池依赖这些过滤器。如果某个 Smart 组为空，优先检查：

- 订阅是否成功更新。
- 节点名称是否包含地区关键字。
- `filter` 是否过严。
- 节点名中是否被误判为 `Traffic`、`Expire`、倍率、官网、频道等伪节点。

## policy-priority

当前配置定义了港澳台相关优先级：

```yaml
policy-priorities:
  gmt: &gmt_priority "...香港...:1.5;...澳门...:1.4;...日本...:1.3;...新加坡...:1.2;...台湾...:1.1;"
```

它被用于：

```yaml
- {name: 🇭🇰 港澳台Smart, type: smart, ..., policy-priority: *gmt_priority, filter: *gmt_filter}
- {name: 🧩 备份Smart, type: smart, ..., policy-priority: *gmt_priority, filter: *all_filter}
```

含义是：在 Smart 内核支持的前提下，对特定地区或关键词赋予不同优先级，让自动选择时更偏向符合偏好的节点。

维护建议：

- 优先级规则要和机场节点命名习惯匹配。
- 权重不要过度复杂，否则后续很难判断 Smart 实际为什么选择某个节点。
- 如果 Smart 选择结果不符合预期，先临时去掉 `policy-priority` 做对照测试。

## 上层策略组设计

当前上层模板是：

```yaml
proxymain: &proxymain {type: select, proxies: [🚀 代理主线, 🇭🇰 港澳台Smart, 🇯🇵 日本Smart, 🇸🇬 新加坡Smart, 🇺🇸 美国Smart, 🏠 家宽节点, 🌍 环球节点, 🛰 所有节点, 🔗 直连主线]}
directmain: &directmain {type: select, proxies: [🔗 直连主线, 🚀 代理主线, 🌍 环球节点, 🛰 所有节点]}
```

这表示：

- 国际服务默认先走 `🚀 代理主线`，也可以手动切到具体 Smart 地区组。
- 国内或直连优先服务默认走 `🔗 直连主线`，但保留手动切代理的能力。
- 业务策略组不直接绑定单个节点，而是绑定上层模板，方便统一调整。

## OpenWrt 网关相关配置

Smart Core 不改变 OpenWrt 透明代理的基础要求。当前配置仍然依赖：

- `tun`
- `listeners`
- `allow-lan`
- `bind-address`
- `dns.listen`
- `dns-hijack`
- `redir` / `tproxy`

也就是说，Smart 只影响“选哪个节点”，不替代 OpenWrt 上流量如何进入 Mihomo 的配置。

如果出现“节点能测通但局域网设备不能上网”，通常不是 Smart 选择问题，而是入站、DNS、OpenWrt 防火墙或插件透明代理链路问题。

## Rule Providers 与 Smart 的关系

Smart 节点池负责选节点，`rule-providers` 负责决定哪些流量进入哪个业务策略组。

当前 `mihomo.yaml` 的规则集合使用：

- MetaCubeX `.mrs`：`domain/ipcidr + format: mrs`。
- SlippinDylan `.list`：`classical + format: text`。

Smart 不改变这些规则集合格式。不要因为启用 Smart 就把 `.mrs` 改成 `.list`，也不要把混合规则行误写成 `domain` 或 `ipcidr`。

## 规则顺序

当前规则顺序适合 Smart 使用：

1. 内网设备直连。
2. NTP 时间同步优先。
3. 私有地址与个人规则优先。
4. AI、开发、Apple、Microsoft、Google 等业务规则。
5. 社交、流媒体、金融、测速等服务规则。
6. 全球代理规则兜底。
7. 中国域名/IP 直连兜底。
8. `MATCH` 交给 `🐠 漏网之鱼`。

Smart 的价值在于业务策略组命中后自动选择节点；规则顺序仍然决定流量是否进入正确业务组。

## 适合保留 Smart 的场景

建议保留 Smart 写法的场景：

- 使用的 OpenWrt 插件或客户端明确支持 Smart Core。
- 机场节点数量多，手动选择成本高。
- 需要按地区自动挑选表现更好的节点。
- 愿意通过日志观察 Smart 选择行为并调整过滤器。

建议改回普通 Mihomo 的场景：

- 内核日志提示不支持 `type: smart`。
- OpenWrt 插件只内置普通 Mihomo。
- 节点数量较少，`url-test` 已经足够。
- 希望配置最大兼容 Stash、Clash Verge、普通 Mihomo 等客户端。

## 排错顺序

Smart 配置异常时，建议按这个顺序排查：

1. 看内核是否支持 `type: smart`。
2. 看 Smart 组是否有节点，若为空检查 `proxy-providers` 和 `filter`。
3. 看订阅是否成功更新，尤其是 `proxy` 下载路径是否可用。
4. 看 DNS 是否正常，特别是 `proxy-server-nameserver`。
5. 看 `rule-providers` 是否成功加载，避免规则没有命中业务组。
6. 临时把某个 Smart 组改成 `url-test` 做对照测试。
7. 临时删除 `policy-priority`，确认是不是优先级干扰选择。

## 与普通 Mihomo 文档的关系

如果你想维护两套配置，建议：

- 普通 Mihomo 版：使用 `url-test` / `fallback`，命名不带 `Smart`。
- Smart Core 版：保留 `type: smart`、`policy-priority`、`first-test` 等字段。
- 两者共享同一套 `rules`、`rule-providers`、DNS 思路。
- 两者不要混用策略组名称，避免上层引用错组。

## 参考资料

- Mihomo 官方配置文档：https://wiki.metacubex.one/en/config/
- Proxy Groups：https://wiki.metacubex.one/en/config/proxy-groups/
- Proxy Providers：https://wiki.metacubex.one/en/config/proxy-providers/
- Rule Providers：https://wiki.metacubex.one/en/config/rule-providers/
- DNS：https://wiki.metacubex.one/en/config/dns/
- TUN：https://wiki.metacubex.one/en/config/inbound/tun/
- Listeners：https://wiki.metacubex.one/en/config/inbound/listeners/
- Mihomo Party Smart Core 说明可参考其发布说明：https://github.com/mihomo-party-org/mihomo-party/releases
