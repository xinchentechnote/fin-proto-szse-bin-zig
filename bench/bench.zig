//! Encode/decode benchmarks for the SZSE binary library, mirrored by
//! examples/bench.rs in fin-proto-szse-bin-rs: both sides use the same
//! methodology (10k warmup iterations, then 10 batches of 100k operations;
//! the fastest batch is reported), so the numbers are directly comparable.
//!
//! Output is one TSV line per case on stderr (std.debug.print):
//!   lib \t lang \t op \t ns_per_op \t frame_bytes
//!
//! Run with: zig build bench -Doptimize=ReleaseFast

const std = @import("std");
const codec = @import("binary_codec");
const szse = @import("szse_binary");

const LIB = "szse";
const LANG = "zig";
const ITERS: usize = 100_000;
const BATCHES: usize = 10;
const WARMUP: usize = 10_000;

const gettime = @extern(*const fn (c_int, *std.c.timespec) callconv(.c) c_int, .{ .name = "clock_gettime" });

fn nowNs() u64 {
    var ts: std.c.timespec = undefined;
    _ = gettime(@backingInt(std.c.CLOCK.MONOTONIC), &ts);
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

fn report(op: []const u8, best_ns: u64, bytes: usize) void {
    const ns_per_op = @as(f64, @floatFromInt(best_ns)) / @as(f64, @floatFromInt(ITERS));
    std.debug.print("{s}\t{s}\t{s}\t{d:.1}\t{d}\n", .{ LIB, LANG, op, ns_per_op, bytes });
}

fn benchEncode(allocator: std.mem.Allocator, msg: *const szse.NewOrder) !usize {
    var buf = codec.Buffer.init(allocator, .big);
    defer buf.deinit();
    var sink: usize = 0;
    for (0..WARMUP) |_| {
        buf.reset();
        try msg.encode(&buf);
    }
    var best: u64 = std.math.maxInt(u64);
    for (0..BATCHES) |_| {
        const t0 = nowNs();
        for (0..ITERS) |_| {
            buf.reset();
            try msg.encode(&buf);
            sink += buf.len;
        }
        best = @min(best, nowNs() - t0);
    }
    std.mem.doNotOptimizeAway(sink);
    report("encode", best, buf.len);
    return buf.len;
}

fn benchDecode(allocator: std.mem.Allocator, raw: []const u8) !void {
    var sink: usize = 0;
    for (0..WARMUP) |_| {
        var r = codec.Reader.init(raw, .big);
        const m = try szse.NewOrder.decode(allocator, &r);
        sink += @abs(m.transact_time) % 65536;
    }
    var best: u64 = std.math.maxInt(u64);
    for (0..BATCHES) |_| {
        const t0 = nowNs();
        for (0..ITERS) |_| {
            var r = codec.Reader.init(raw, .big);
            const m = try szse.NewOrder.decode(allocator, &r);
            sink += @abs(m.transact_time) % 65536;
        }
        best = @min(best, nowNs() - t0);
    }
    std.mem.doNotOptimizeAway(sink);
    report("decode", best, raw.len);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const msg = szse.NewOrder{
        .appl_id = "010",
        .submitting_pbuid = "PBU001",
        .security_id = "600000",
        .security_id_source = "101",
        .owner_type = 1,
        .clearing_firm = "01",
        .transact_time = 2026_0109_0930_00123,
        .user_info = "user01",
        .cl_ord_id = "ORD000001",
        .account_id = "ACC000000001",
        .branch_id = "0001",
        .order_restrictions = "R",
        .side = "1",
        .ord_type = "2",
        .order_qty = 100,
        .price = 10500,
        .appl_extend = .{ .extend_100101 = .{
            .stop_px = -123456789,
            .min_qty = -123456789,
            .max_price_levels = 1234,
            .time_in_force = "a",
            .cash_margin = "a",
        } },
    };

    const bytes = try benchEncode(allocator, &msg);

    var buf = codec.Buffer.init(allocator, .big);
    defer buf.deinit();
    try msg.encode(&buf);
    try benchDecode(allocator, buf.written()[0..bytes]);
}
