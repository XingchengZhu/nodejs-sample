# nodejs-sample

一个极简的 Node.js 示例应用（见 [`app.js`](./app.js)），配有容器化构建（见 [`Dockerfile`](./Dockerfile)）与可复制到 CI 的流水线命令。

## 目录

* [环境要求](#环境要求)
* [快速开始（本地）](#快速开始本地)
* [测试与报告](#测试与报告)
* [容器化（Podman）](#容器化podman)
* [CI/流水线示例命令](#ci流水线示例命令)
* [项目结构](#项目结构)
* [常见问题](#常见问题)

---

## 环境要求

* Node.js（建议 16+，与 [`package.json`](./package.json) 的依赖匹配）
* npm 或 yarn（以下以 npm 为例）
* （可选）Podman 4.x+ 或 Docker 20.10+（本项目示例以 **Podman** 为主）

---

## 快速开始（本地）

```bash
# 1) 安装依赖
npm install

# 2) 启动（参考 package.json 的 scripts）
npm start
# 或（如果有定义）
# npm run dev

# 3) 访问
# 默认常见端口为 3000，如 app.js 指定了其他端口，请以代码为准
# http://localhost:3000
```

如需更改端口，通常可通过环境变量或直接修改 [`app.js`](./app.js)。

---

## 测试与报告

如果定义了测试脚本（如 `npm test`），可在本地与 CI 中执行：

```bash
npm test
```

在 Jenkins 等 CI 中收集报告时，常用的 JUnit/XML 格式需要测试框架配合（例如 `jest-junit`、`mocha-junit-reporter`）。若已配置为输出到 `**/test-results/*.xml` 或 `**/reports/*.xml`，请在 Jenkins “JUnit test result report” 中填写对应的通配符。

> 若项目暂未配置单测或报告插件，可先跳过测试阶段，后续再补齐。

---

## 容器化（Podman）

本仓库提供了一个简单的 [`Dockerfile`](./Dockerfile)。以下命令使用 **私有镜像仓库** 示例地址 `10.29.230.150:31381`；请按需替换仓库、命名空间与镜像名/标签。

```bash
# 登录（HTTP/自签名示例，加 --tls-verify=false）
podman login --tls-verify=false 10.29.230.150:31381 -u <USER> -p <PASS>

# 构建镜像
podman build --tls-verify=false \
  -t 10.29.230.150:31381/library/nodejs-sample:latest .

# 推送镜像
podman push --tls-verify=false 10.29.230.150:31381/library/nodejs-sample:latest
```

运行容器示例：

```bash
podman run --rm -p 3000:3000 10.29.230.150:31381/library/nodejs-sample:latest
# 打开 http://localhost:3000
```

> 具体对外端口以 [`app.js`](./app.js) 中绑定的端口为准（常见是 3000）。如有 `PORT` 环境变量支持，可用 `-e PORT=xxxx` 覆盖。

---

## CI/流水线示例命令

以下片段可直接放到 Jenkins Pipeline（Shell 步骤）中使用；按需裁剪。

### 1) 拉取依赖 + 单元测试（可失败不阻断）

```bash
set -euxo pipefail

npm ci || npm install

# 开启测试；若不希望失败阻断后续步骤，可加上 || true
npm test || true

# 打印当前目录，方便排查
echo "PWD=$(pwd)"

# 如使用 JUnit 报告插件，请确保测试框架已输出 XML 报告到下述路径之一，
# 然后在 Jenkins 的 JUnit 配置里填同样的通配符
# **/test-results/*.xml 或 **/reports/*.xml
```

### 2) 构建与推送镜像（Podman）

```bash
# 登录私有仓库
podman login --tls-verify=false 10.29.230.150:31381 -u admin -p Admin123

# 构建镜像（镜像名可参数化）
IMG="10.29.230.150:31381/library/nodejs-sample:latest"
podman build --tls-verify=false -t "$IMG" .

# 推送
podman push --tls-verify=false "$IMG"
```

> 如果你需要与 Java 项目那套“先宿主机测试，再构建镜像”的流程一致，上述分两步执行即可：**先测试**，**再容器化**。

---

## 项目结构

* [`app.js`](./app.js) — 核心应用入口（HTTP 服务/路由）
* [`package.json`](./package.json) — 依赖、脚本命令（`npm start`, `npm test` 等）
* [`Dockerfile`](./Dockerfile) — 容器构建脚本（基于 Linux 发行版 + Node 运行时）

> 如需前端打包（`npm run build`）并用 Nginx 托管静态资源，可参考你之前的**两阶段**方案：第一阶段用 Node 构建产物，第二阶段用 Nginx 仅拷贝 `dist/` 静态文件运行。

---

## 常见问题

**Q1：公司网络限制导致 npm 慢/失败？**
A：可在 CI 环境中配置内部 npm 仓库（如 Nexus/verdaccio）：

```bash
npm config set registry http://<your-npm-registry>
```

**Q2：容器内外端口不一致？**
A：确保运行时 `-p 宿主端口:容器端口` 与应用监听端口一致。若支持 `PORT` 环境变量，记得在运行时设置。

**Q3：如何把测试报告让 Jenkins 识别？**
A：选择一个测试框架（Jest、Mocha 等）+ JUnit 报告插件，把输出路径统一到如 `**/test-results/*.xml`，在 “Publish JUnit test result report” 中填写同样通配符。
