const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const codec_dep = b.dependency("binary_codec", .{
        .target = target,
        .optimize = optimize,
    });
    const codec_mod = codec_dep.module("binary_codec");

    const mod = b.addModule("szse_binary", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("binary_codec", codec_mod);

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    const bench = b.addExecutable(.{
        .name = "bench",
        .root_module = b.createModule(.{
            .root_source_file = b.path("bench/bench.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "szse_binary", .module = mod },
                .{ .name = "binary_codec", .module = codec_mod },
            },
        }),
    });
    bench.root_module.link_libc = true;
    b.installArtifact(bench);
    const run_bench = b.addRunArtifact(bench);
    const bench_step = b.step("bench", "Run encode/decode benchmarks");
    bench_step.dependOn(&run_bench.step);

    const example = b.addExecutable(.{
        .name = "basic",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "szse_binary", .module = mod },
                .{ .name = "binary_codec", .module = codec_mod },
            },
        }),
    });
    const run_example = b.addRunArtifact(example);
    const example_step = b.step("example", "Run the basic example");
    example_step.dependOn(&run_example.step);
}
