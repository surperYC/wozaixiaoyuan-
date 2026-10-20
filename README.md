# 我在校园自动打卡（NewWoZaiXiaoYuan）

「我在校园」小程序（合并后的新版）**归寝自动打卡**工具：支持定位打卡、蓝牙打卡、多账号、JWSESSION 本地缓存、节假日定位方案自动切换，以及邮件 / Server 酱结果推送。可部署在本地（Windows / Linux 服务器）或 GitHub Actions 上，无需一直开着电脑。

> 本项目基于 [LinChiQ/NewWoZaiXiaoYuan](https://github.com/LinChiQ/NewWoZaiXiaoYuan) 二次开发，在原版基础上新增了**节假日自动切换定位方案**、**本地定位数据兜底**、**Windows 定时任务脚本**等改动。

> [!WARNING]
> 本项目仅供 **Python 学习与接口研究** 使用，与「我在校园」官方及各学校无关。使用自动化脚本代打卡可能违反学校管理规定，也可能因第三方接口变更而随时失效，由此产生的一切后果由使用者自行承担。仓库中不包含任何真实账号、密码、身份证号或位置信息，请勿向仓库提交个人隐私数据。

---

## ✨ 功能特性

- ✅ **归寝定位打卡**：自动查询待签到任务，按配置的定位数据提交打卡（本地版 `doSignByLocation`）
- ✅ **蓝牙打卡**：通过宿舍蓝牙设备信息提交打卡（`By Mudea661`）
- ✅ **多账号支持**：`config.yaml` 中用 `---` 分隔多段配置，一次运行依次打卡
- ✅ **JWSESSION 持久化**：SQLite 缓存登录态，失效时自动重新登录，避免频繁登录
- ✅ **地址自动解析**：腾讯位置服务把「省 市 区 街道 路」解析为经纬度，无需抓包
- ✅ **节假日定位方案**：`--profile auto` 根据国务院法定节假日自动切换「工作日 / 节假日」定位数据
- ✅ **多级兜底**：节假日接口不可用 → 本地缓存 → 内置节假日表；腾讯地图 Key 失效 → 本地 `punchdata` 兜底
- ✅ **结果推送**：邮件（SMTP）/ Server 酱（ServerChan）二选一或同时使用
- ✅ **GitHub Actions**：无需服务器，定时在云端自动执行
- ✅ **Windows 一键脚本**：配合「任务计划程序」即可托管运行

## 🧭 工作原理

```
读取 cache/config.yaml
        │
        ▼
选择定位方案（--profile auto / normal / holiday）
        │
        ▼
登录（AES-128-ECB 加密密码）→ 获取 JWSESSION
        │  （已缓存且未失效则跳过登录）
        ▼
查询待签到任务 → 确定定位数据（punchdata → 数据库缓存 → 腾讯地图解析）
        │
        ▼
提交打卡 → 邮件 / Server 酱推送结果
```

## 📁 目录结构

```
NewWoZaiXiaoYuan/
├── WoZaiXiaoYuan.py             # 本地 / 服务器版入口
├── actionVersion.py             # GitHub Actions 版入口（从环境变量读取配置）
├── blueTooth.py                 # 独立的蓝牙打卡脚本（By Mudea661）
├── requirements.txt             # Python 依赖
├── auto_sign.bat                # Windows 定时任务：静默运行并追加日志
├── 手动打卡.bat                  # Windows 双击运行（控制台有输出）
├── cache/
│   ├── config.example.yaml      # 配置模板（复制为 config.yaml 后填写）
│   ├── config.yaml              # 你的真实配置（已在 .gitignore 中忽略，不会上传）
│   ├── punchdata.json           # 可选：工作日定位数据兜底（.gitignore 已忽略）
│   ├── punchdata_holiday.json   # 可选：节假日定位数据兜底（.gitignore 已忽略）
│   ├── userdata.db              # 运行后自动生成，缓存 JWSESSION 和上次打卡数据
│   └── holiday_calendar_<年>.json # 运行后自动生成的节假日缓存
└── .github/workflows/punch.yml  # GitHub Actions 定时任务
```

## 🚀 快速开始

### 1. 环境要求

- Python 3.7+（在 Python 3.12 上测试通过）
- 能正常访问 `gw.wozaixiaoyuan.com`

### 2. 安装依赖

```bash
git clone <你的仓库地址>
cd NewWoZaiXiaoYuan
pip install -r requirements.txt
```

### 3. 复制并填写配置

```bash
# Windows (PowerShell)
Copy-Item cache\config.example.yaml cache\config.yaml

# Linux / macOS
cp cache/config.example.yaml cache/config.yaml
```

然后编辑 `cache/config.yaml`，各字段含义见下文「配置说明」。

### 4. 运行

```bash
# 自动判断今天是否为法定节假日（默认）
python WoZaiXiaoYuan.py

# 强制使用工作日定位方案
python WoZaiXiaoYuan.py --profile normal

# 强制使用节假日定位方案
python WoZaiXiaoYuan.py --profile holiday
```

> 💡 首次运行会登录并生成 `cache/userdata.db`；之后若 JWSESSION 未失效，将直接复用，不会反复登录。

## ⚙️ 配置说明

`cache/config.yaml` 是 **YAML 多文档** 格式：

- **第一段**（第一个 `---` 之前）是全局配置（邮箱、学校、腾讯地图 Key）；
- **之后每一段** 是 **一个账号**，用 `---` 分隔，可以写多个。

### 全局配置

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `mail_address` | 否 | 发送通知邮件的邮箱地址，如 `xxx@163.com`；不用邮件推送则留空 |
| `password` | 否 | 上面邮箱的 **SMTP 授权码**（不是邮箱登录密码） |
| `host` | 否 | 邮箱 SMTP 服务器，如 `smtp.163.com`、`smtp.qq.com` |
| `school` | **是** | 学校名称，必须与「我在校园」登录页学校列表中的名称 **完全一致** |
| `tencent_map` | 否 | 腾讯位置服务 WebService API Key，用于把 `location` 解析成经纬度；留空或失效时使用本地 `punchdata` 兜底 |

### 账号配置（可多段）

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `username` | **是** | 我在校园登录账号（通常为学号或身份证号），**建议用引号包起来** |
| `password` | **是** | 我在校园登录密码，建议用引号包起来（含 `@` `#` `:` 等字符时必须加引号） |
| `receive` | 否 | 接收通知的邮箱地址，留空则不接收邮件 |
| `sct_ftqq` | 否 | [Server 酱](https://sct.ftqq.com) 的 SendKey，留空则表示不使用 |
| `blue_sign` | 否 | 是否进行蓝牙打卡：`yes` / `no` |
| `dorm_sign` | 否 | 是否进行归寝定位打卡：`yes` / `no`（建议 `yes`） |
| `location` | 否 | 打卡地址，按「省 市 区(县) 街道 路」五级填写；使用本地 `punchdata` 时忽略此项 |

### 多账号示例

```yaml
# 全局配置
mail_address: your_mail@163.com
password: "你的SMTP授权码"
host: smtp.163.com
school: 你的学校名称
tencent_map: 你的腾讯地图Key

---
# 账号 1
username: "你的账号"
password: "你的密码"
receive: 接收通知的邮箱@qq.com
sct_ftqq:
blue_sign: no
dorm_sign: yes
location: 省 市 区 街道 路

---
# 账号 2：复制上一段即可，用 --- 与上面隔开
username: "第二个账号"
password: "第二个密码"
receive:
sct_ftqq:
blue_sign: no
dorm_sign: yes
location: 省 市 区 街道 路
```

> ⚠️ YAML 小坑：以 `0` 开头的数字、含 `@` `#` `:` 的密码、纯数字账号建议一律加双引号，避免被 YAML 解析成数字或注释。

## 🗓️ 节假日定位方案（本项目新增）

`WoZaiXiaoYuan.py` 支持 `--profile` 参数（`actionVersion.py` 无此参数，始终使用腾讯地图 + 签到区域解析）：

| 取值 | 行为 |
| --- | --- |
| `auto`（默认） | 判断今天是否为国务院公布的法定节假日（含调休放假），是则用 `cache/punchdata_holiday.json`，否则用 `cache/punchdata.json` |
| `normal` | 强制使用工作日定位方案（`punchdata.json`） |
| `holiday` | 强制使用节假日定位方案（`punchdata_holiday.json`），文件不存在时自动回退 `normal` |

节假日数据采用三级兜底：

1. 在线接口 `https://timor.tech/api/holiday/year/<年份>`，成功后写入 `cache/holiday_calendar_<年份>.json`；
2. 接口不可用时读取本地缓存；
3. 缓存也没有时使用代码内置的 `FALLBACK_HOLIDAY_DATES`（目前内置 2026 年）。

> 📌 每年国务院办公厅公布次年放假安排后，请记得更新 `WoZaiXiaoYuan.py` 中的 `FALLBACK_HOLIDAY_DATES`（通常在线接口会自动更新，内置表只是最后的兜底）。

### 定位数据优先级

1. `cache/punchdata.json` / `cache/punchdata_holiday.json`（存在则直接使用）；
2. `cache/userdata.db` 中该账号上一次成功打卡的定位数据；
3. 调用腾讯地图接口，用 `location` 解析出经纬度（需要 `tencent_map` Key 及对应接口配额）。

`punchdata` 文件格式（字段可直接从腾讯地图「逆地址解析」结果或抓包结果复制，不需要全部字段都填）：

```json
{
  "latitude": 30.0,
  "longitude": 120.0,
  "nationcode": "",
  "country": "中国",
  "province": "某省",
  "citycode": "",
  "city": "某市",
  "adcode": "000000",
  "district": "某区",
  "towncode": "0",
  "township": "某街道",
  "streetcode": "",
  "street": "某路"
}
```

> 建议把 `punchdata*.json` 放在 `.gitignore` 中（本仓库已默认忽略），避免把真实宿舍 / 家庭位置提交到 GitHub。

## 🧩 附：`blueTooth.py` 独立蓝牙脚本

`blueTooth.py` 是原项目中的独立蓝牙打卡脚本，通过环境变量读取账号（本仓库已去掉硬编码学校名）：

- `wzxy`：账号密码，格式 `账号#密码`，多个账号之间用 `&` 分隔；
- `wzxy_school`：学校名称，必须与「我在校园」中的名称一致。

```bash
# Linux / macOS 示例
export wzxy="13800000000#password"
export wzxy_school="你的学校名称"
python blueTooth.py
```

## ⏰ 定时运行

### Windows（任务计划程序）

1. 确保 `python` 已加入系统 `PATH`（命令行执行 `python -V` 能输出版本号）；
2. 右键「任务计划程序」→「创建基本任务」→ 触发器选「每天」→ 设置时间（如 22:00）；
3. 操作选「启动程序」，程序填 `cmd.exe`，参数填 `/c "D:\path\to\NewWoZaiXiaoYuan\auto_sign.bat"`；
4. 勾选「不管用户是否登录都要运行」和「使用最高权限运行」更稳定。

`auto_sign.bat` 会把运行日志追加到 `cache/run.log`（该文件已在 `.gitignore` 中忽略）。

### Linux（crontab）

```bash
# 每天 22:00 打卡（注意服务器时区）
0 22 * * * /usr/bin/python3 /path/to/NewWoZaiXiaoYuan/WoZaiXiaoYuan.py >> /path/to/NewWoZaiXiaoYuan/cache/run.log 2>&1
```

## 🤖 GitHub Actions 部署（无需服务器）

1. **Fork** 本仓库（或把代码 push 到你自己的公开仓库）；
2. 在仓库 `Settings → Environments` 中新建环境 `CONFIG_01`；
3. 在 `CONFIG_01` 的 `Environment secrets` 中添加以下 Secrets：

| Secret | 说明 |
| --- | --- |
| `school_name` | 学校名称 |
| `wzxy_username` | 我在校园账号 |
| `wzxy_password` | 我在校园密码 |
| `punch_location` | 打卡地址（省 市 区 街道 路） |
| `tencentKey` | 腾讯地图 WebService API Key |
| `dorm_sign` | 是否归寝打卡：`yes` / `no` |
| `blue_sign` | 是否蓝牙打卡：`yes` / `no` |
| `receive_mail` | 接收通知的邮箱（可留空） |
| `mail_address` | 发送通知的邮箱（可留空） |
| `mail_password` | 发送通知邮箱的 SMTP 授权码（可留空） |
| `mail_host` | SMTP 服务器（可留空） |
| `sct_ftqq` | Server 酱 SendKey（可留空） |

4. 编辑 `.github/workflows/punch.yml`，取消 `cron` 那一行的注释并设置时间（**cron 使用 UTC 时间**，北京时间 22:00 = UTC 14:00，即 `0 14 * * *`）；
5. 打开仓库 `Actions` 页面 → 选择「我在校园打卡」→ `Run workflow` 手动测试一次；
6. 多账号：复制 `User01` 整个 job 为 `User02`，把 `environment` 改为 `CONFIG_02`，并在 `Settings → Environments` 中新建 `CONFIG_02` 填入同样的 Secrets。

> ⚠️ 公开仓库的定时工作流在 **连续 60 天无仓库活动** 后会被 GitHub 自动停用，建议每 1~2 个月手动 `Run workflow` 一次，或做一次空提交。Fork 仓库默认不会自动运行上游的 Actions，需要自行配置。

## 🔐 安全与隐私

- 本仓库 **不包含** 任何真实账号、密码、身份证号、手机号或位置数据；
- 请在 **本地** 或 **GitHub Secrets** 中保存账号信息，**不要** 提交 `cache/config.yaml`；
- 本仓库的 `.gitignore` 已默认忽略以下文件，请勿强制添加：

| 文件 | 原因 |
| --- | --- |
| `cache/config.yaml` | 真实账号、密码 |
| `cache/punchdata*.json` | 真实定位坐标 |
| `cache/userdata.db` | JWSESSION 登录态 + 历史打卡数据 |
| `cache/*.log`、`cache/*.bak*` | 运行日志、备份中的个人信息 |

- 提交前建议执行 `git status` 和 `git diff --cached` 自查；
- 如果账号使用身份证号登录，请特别注意：18 位身份证号属于敏感个人信息，任何情况下都不要写入代码或提交到仓库；
- 怀疑账号信息已泄露时：立即修改我在校园密码，删除 `cache/userdata.db` 后重新登录。

## ❓ 常见问题

**Q1：登录失败 / 提示「账号或密码错误」？**

- 检查 `username` / `password` 是否加引号、是否有多余空格；
- 我在校园修改密码后，请删除 `cache/userdata.db`（或其中对应用户的记录）再运行，让程序重新登录；
- 密码建议为「字母 + 数字」，部分特殊字符可能导致登录接口加密后校验失败。

**Q2：提示「用户已打过卡」但确实没打？**

- 说明服务端已有当天签到记录（`signStatus != 1`），程序会跳过，属于正常现象。

**Q3：邮件收不到 / 报 535 错误？**

- `password` 必须填邮箱的 **SMTP 授权码**，不是邮箱登录密码；
- 163 邮箱需在设置中开启 SMTP 服务并生成授权码；
- GitHub Actions 的 IP 被部分邮箱风控时，可改用 Server 酱推送。

**Q4：腾讯地图 Key 失效 / 地址解析失败？**

- 检查 Key 是否分配了「地址解析 / 逆地址解析」配额；
- 或者手工准备 `cache/punchdata.json`（工作日）与 `cache/punchdata_holiday.json`（节假日），程序会优先使用本地文件中的数据。

**Q5：打卡提示不在签到区域？**

- 定位数据与学校要求的签到区域不一致，请核对 `location` 或 `punchdata` 中的经纬度；
- GitHub Actions 版会根据签到任务返回的 `areaList` 自动匹配签到区域，与本地版逻辑略有不同。

**Q6：GitHub Actions 到点没有执行？**

- 定时任务使用 UTC，且高峰期可能排队延迟；
- 公开仓库 60 天无活动会被停用，手动运行一次即可恢复；
- 检查 workflow 中 `cron` 是否已取消注释、Secrets 名称是否拼写正确。

## 🗒️ 更新日志

- [x] 2026.10 新增 `--profile` 节假日/工作日定位方案自动切换；节假日接口 + 本地缓存 + 内置表三级兜底；新增本地 `punchdata` 定位兜底；新增 Windows 定时脚本；清理仓库敏感信息、补充配置模板与 README。
- [x] 2025.5.11 本校我在校园更新打卡参数，已同步更新服务器代码并修复检验登录 URL 过期问题。（上游）
- [x] 2024.9.15 我在校园更新新打卡方式，已同步更新服务器代码与 GitHub Action 代码。（上游）
- [x] 2024.8.20 重构代码，使用 SQLite 存储 JWSESSION 与打卡数据，使用腾讯地图 API 解析打卡地址，新增蓝牙签到模块（By Mudea661）。（上游）
- [x] 2024.5.2 新增 GitHub Actions 部署方式。（上游）
- [x] 2024.2.27 我在校园登录功能更新，增加 AES 加密与学校选择。（上游）
- [x] 2023.11.1 我在校园取消 JWSESSION，修改为 Cookie。（上游）

## 🙏 致谢

- [LinChiQ/NewWoZaiXiaoYuan](https://github.com/LinChiQ/NewWoZaiXiaoYuan)：原始项目与主要打卡逻辑；
- Mudea661：蓝牙签到模块；
- [timor.tech](https://timor.tech/api/holiday)：节假日查询接口；
- [腾讯位置服务](https://lbs.qq.com/)：地址解析 / 逆地址解析。

## 📄 免责声明

本项目仅供 **Python 学习与接口研究** 使用，与「我在校园」官方及各学校无关。使用自动化脚本代打卡可能违反学校管理规定，请自行评估并承担风险；因接口变更、脚本失效、账号异常等造成的任何后果，作者不承担任何责任。请勿将本项目用于任何商业用途或代他人打卡牟利。

如果这个项目对你有帮助，欢迎点个 Star ⭐
