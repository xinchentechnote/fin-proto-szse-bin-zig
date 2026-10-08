//! Basic example: encode a SzseBinary carrying a Logon body, print the wire
//! bytes as hex, then decode them back.

const std = @import("std");
const codec = @import("binary_codec");
const szse = @import("szse_binary");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    const msg = szse.SzseBinary{
        .msg_type = 1, // Logon
        .body_length = 0,
        .body = .{ .logon = .{
            .sender_comp_id = "SENDER0000000000000001",
            .target_comp_id = "TARGET0000000000000001",
            .heart_btint = 30,
            .password = "pass1234",
            .default_appl_ver_id = "1.29",
        } },
        .checksum = 0,
    };

    var buf = codec.Buffer.init(allocator, .big);
    defer buf.deinit();
    try msg.encode(&buf);

    std.debug.print("encoded {} bytes:", .{buf.len});
    for (buf.written()) |b| std.debug.print("{x:0>2}", .{b});
    std.debug.print("\n", .{});

    var reader = codec.Reader.init(buf.written(), .big);
    const decoded = try szse.SzseBinary.decode(allocator, &reader);
    std.debug.print("msg_type={} body_length={} checksum={} sender={s}\n", .{
        decoded.msg_type, decoded.body_length, decoded.checksum, decoded.body.logon.sender_comp_id,
    });
}
