# 授权（UID 白名单）

## 当前可用方式

1. 用 MT 管理器（或任何 root 文件管理器）创建：

```
/data/adb/ksu/ksu_uids.txt
```

2. 内容（一行一个 UID，只写数字）：

```
10302
10123
```

3. 回到 SukiSU Nova，重新打开管理器（触发 allowlist 热加载）

4. 验证：`adb shell su -c id` → `uid=0`

## 查 UID

```bash
adb shell pm list packages -U | grep <包名>
# 例：package:bin.mt.plus uid:10302
```

## 注意

- 不要写注释；解析器只认数字，注释里的数字会被当成 UID
- 文件不要超过 1023 字节
- 权限 0644，属主 root
