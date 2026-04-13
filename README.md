# proxyRules

这个仓库用于维护个人代理规则与配置文件。

## 内容

- [configFile/](configFile/)：可直接导入或参考的配置文件。
- [ruleProvider/](ruleProvider/)：个人自定义规则集合，例如开发、代理、直连、BT、AI 相关规则。
- [docs/](docs/)：配置说明文档，记录 Stash、Mihomo、Smart Core 等配置的设计思路和维护注意事项。

## 当前重点

- [configFile/mihomo.yaml](configFile/mihomo.yaml)：面向 OpenWrt 网关环境的 Mihomo 配置。
- [configFile/stash.yaml](configFile/stash.yaml)：面向 iPhone / iPad Stash 的移动端配置。
- [ruleProvider/](ruleProvider/)：给远程规则集引用的个人规则目录。

## 说明文档

- [Stash 配置说明](docs/stash-config-guide.md)
- [Mihomo OpenWrt 配置说明](docs/mihomo-openwrt-config-guide.md)
- [Mihomo Smart Core 配置说明](docs/mihomo-smart-core-guide.md)

配置中订阅链接使用占位文本，实际使用前需要替换为自己的订阅地址。
