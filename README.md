# 豆包语音 for 微信

微信里长按文字 → 弹菜单 → 念出来。

---

## 上传清单

根目录必须是这 5 个文件 + 3 个文件夹：

```
Makefile
control
DoubaoVoiceWeChat.plist
Tweak.xm
README.md
TTS/     (10 个文件)
UI/      (7 个文件)
Prefs/   (4 个文件)
.github/workflows/build-dylib.yml
```

## 编译

1. 新建仓库 → Add file → Upload files
2. 进到 `DoubaoVoice3\` **里面**再 Ctrl+A 全选拖进去
3. Commit
4. Actions 左侧 `build-dylib` → Run workflow
5. 绿勾后进记录 → 页面最底 Artifacts → 下载 `DoubaoVoiceWeChat`

## 注入

TrollFools → 微信 → **先删掉旧的同名 dylib** → 注入新的 → 重启微信。

## 填配置

微信 → 任意聊天 → ➕ → 面板最后一格橙色「声」→

| 项 | 值 |
| --- | --- |
| API Key | 火山引擎控制台复制 |
| 资源 ID | `seed-tts-2.0`（2.0）或 `seed-icl-2.0`（1.0） |
| 音色 | 必须和资源 ID 同代 |

2.0 音色后缀 `_uranus_bigtts`，1.0 音色后缀 `_moon_bigtts`。配错报 55000000。

## 这版改了什么

| 项 | 说明 |
| --- | --- |
| nullability 警告 | Makefile 加 `-Wno-nullability-completeness -Wno-error`，所有头文件去掉 nullable 标注 |
| 音频格式 | `AVAudioPCMFormatFloat32` 非交错，PCM16 手动转换，避开 Int16+interleaved 兼容问题 |
| `finish` 完成回调 | 去掉 `AVAudioPlayerNodeCompletionDataPlayedBack` 枚举依赖，改 `dispatch_after` |
| `DVStore` | 不在 `init` 里写盘，读取时兜底 |
| `DVHUD` | 延迟 0.15 秒再上屏，避开启动早期的 window 为空 |
| `DVMoreInjector` | 加 `isViewLoaded` 判断，不主动触发 `loadView` |
| 所有 hook | 全部 `@try/@catch` 包裹 |

## 排错

| 现象 | 原因 |
| --- | --- |
| `No files were found with the provided path: out` | 编译失败，看 `5. 编译` 那步的 `error:` |
| `-Wnullability-completeness` | Makefile 的 CFLAGS 没生效 |
| `code=55000000` | 音色和资源 ID 不同代 |
| 有提示没声音 | 微信占着 audio session，杀掉微信重开 |
