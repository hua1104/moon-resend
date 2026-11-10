# 比赛展示说明

## 项目解决的问题

MoonBit 应用接入事务邮件时，不应重复处理 Resend 的 JSON、鉴权、幂等、错误解析和邮件生命周期。`moon-resend` 将这些工作封装为类型化 API，并通过独立 adapter 完成真实 HTTPS 请求。

## 当前可展示闭环

- 单封与最多 100 封批量发送；
- HTML、纯文本、抄送、密送、回复地址、附件、标签和定时发送；
- 查询投递状态、修改发送时间和取消发送；
- 输入错误、Resend API 错误、异常响应与网络错误分层；
- 基于 moonfetch 的真实 HTTP adapter；
- 无密钥、无外网副作用的常规测试；
- 通过环境变量运行的可选真实发信示例。

## 90 秒演示流程

1. 展示 `SendEmailParams` 和一行 `@adapter.send`。
2. 运行 `moon test`，说明测试不会真实发信。
3. 在不显示密钥值的情况下配置 `RESEND_API_KEY`、`RESEND_FROM`、`RESEND_TO`。
4. 运行 `moon run cmd/send-live --target native`，展示 Resend 返回的邮件 ID。
5. 展示架构图，说明核心 SDK 与 HTTP 实现分离，后续可以增加其他运行时适配。

## 边界说明

11 月版本不宣称覆盖 Resend 全部资源。Webhook 验签安排在 12 月，Domains 与 Contacts 安排在 1 月；Inbound、Inboxes、Audiences、Templates 等根据真实用户需求再决定，避免为了接口数量制造维护负担。
