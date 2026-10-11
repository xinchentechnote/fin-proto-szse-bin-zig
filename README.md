# fin-proto-szse-bin-zig

深交所 Binary 交易数据接口规范(Ver1.29)的 Zig 消息库(模块名 `szse_binary`),
基于 [fin-proto-runtime-bin-zig](../fin-proto-runtime-bin-zig) 运行时。
对应 Rust 版本:[fin-proto-szse-bin-rs](https://github.com/xinchentechnote/fin-proto-szse-bin-rs)。

`src/` 下的全部 `.zig` 文件由 [fin-protoc](https://github.com/xinchentechnote/fin-protoc)
从 `proto/szse_bin_v1.29.pdsl` 生成(`-z` 指定输出目录),请勿手改:

```bash
make compile    # fin-protoc -f proto/szse_bin_v1.29.pdsl -z src/
```

## 协议要点

- 全部大端;字符串/数组长度前缀为 `u32`
- 根包 `SzseBinary`:`MsgType` → 14 种 `Body` 消息(部分 `MsgType` 为 `[100101, ...]`
  多值列表键,共 77 个键),
  `BodyLength` 由 `@lengthOf` 回填,`int32 Checksum` 用 `SZSE_BIN` 算法
  (逐字节 i32 累加 mod 256,可为负)
- `NewOrder`/`ExecutionConfirm`/`ExecutionReport` 内含 `match ApplID as ApplExtend`
  字符串键多态分发(生成 54 种 Extend 扩展体,其中 NewOrder 19 种、
  ExecutionConfirm 19 种、ExecutionReport 11 种经 match 引用,其余为规范预留),
  对应 Zig tagged union
- `ReportSynchronization`/`PlatformInfo` 含 `repeat` 对象列表

## 使用

```bash
zig build test      # 运行生成代码自带的 round-trip 测试(72 个)
zig build example   # 编码一条 Logon 报文打印线上字节并回读解码
```

与 fin-proto-szse-bin-rs 逐字节兼容:相同输入编码出相同报文(Logon、NewOrder
已与 Rust 版做过字节级对比)。

依赖通过 `build.zig.zon` 的 path 依赖引入运行时:

```zig
.dependencies = .{
    .binary_codec = .{ .path = "../fin-proto-runtime-bin-zig" },
},
```
