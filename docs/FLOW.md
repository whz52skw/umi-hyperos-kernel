# 项目流程图（FLOW）

> 两张图：**总览** 与 **UI 授权攻坚路线**。配合 [HANDOVER.md](HANDOVER.md) 使用。

## 图 1：项目总览状态

```mermaid
flowchart LR
    subgraph 已完成["✅ 已完成（可信）"]
        A1[编译链<br/>31步workflow<br/>4.19兼容补丁]
        A2[root可用<br/>uid=0, ksu域]
        A3[su拦截+会话fd<br/>dmesg实证]
        A4[管理器识别<br/>30000-6 ManualHook]
        A5[开源仓库+文档<br/>+全部工具]
    end
    subgraph 未完成["❌ 未完成（两个尾巴）"]
        B1[管理器UI授权<br/>超级用户开关失败]
        B2[文本白名单加载<br/>EACCES -13 已改路径未验证]
    end
    subgraph 外因["⚠️ 外部约束"]
        C1[builtin分支官方停更<br/>2026-11-15]
        C2[管理器官方升35000系<br/>30000 APK绝版→已备份]
        C3[SUSFS 2.x 需移植<br/>周级工程]
    end
    A1 --> A2 --> A3 --> A4 --> A5
    A5 --> B1
    A5 --> B2
    B1 -.受制于.-> C1
    B1 -.受制于.-> C2
    B2 -.受制于.-> C3
```

## 图 2：UI 授权攻坚路线（阶段 0→3）

```mermaid
flowchart TD
    S[起点<br/>UI授权失败<br/>无SET_APP_PROFILE]<] --> P0
    P0["阶段0 静态分析<br/>JADX反编译30000管理器<br/>找10003/SET_APP_PROFILE<br/>守卫逻辑"] --> P1
    P1["阶段1 动态证据<br/>编8o内核 → 一键诊断<br/>ksu_f10003遍历1/2/3/MAX<br/>+strace +dmesg"] --> P2
    P2{"证据指向？"}
    P2 -- 10003数值不对 --> P2A["改默认值<br/>收工 🎉"]
    P2 -- 缺ioctl命令 --> P2B["dispatch.c补handler<br/>映射ksu_set_app_profile"]
    P2 -- 签名/包名校验 --> P2C["内核侧放行<br/>ksu_verify_manager_apk_signature"]
    P2 -- 全对仍不发 --> P2D["查sulog/事件通道"]
    P2A --> P2B
    P2B --> P3{"首攻结果"}
    P3 -- 失败 --> P4["阶段3 终招<br/>伪造版本号35106/41150<br/>或移植main协议面<br/>或改装管理器+签名白名单"]
    P3 -- 成功 --> DONE["✅ UI授权可用"]
    P4 --> DONE
```

## 图 3：白名单验证（接手者第一步）

```mermaid
flowchart TD
    W1[编31步workflow内核<br/>含8m v2] --> W2[刷机]
    W2 --> W3[建文件<br/>/data/adb/ksu/ksu_uids.txt<br/>内容10302]
    W3 --> W4[重启<br/>让init上下文读取]
    W4 --> W5{看dmesg}
    W5 -- uid list loaded bytes=N applied=N --> W6["✅ 白名单通了<br/>管理器显示已授权"]
    W5 -- open failed EACCES --> W7["SELinux拦截<br/>试override_creds/换路径/改sepolicy"]
    W7 --> W4
```
