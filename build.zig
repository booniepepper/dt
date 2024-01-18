const std = @import("std");
const LazyPath = if (@hasDecl(std.Build, "LazyPath")) std.Build.LazyPath else std.Build.FileSource;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = LazyPath.relative("src/main.zig");

    // Dt executable
    const dt_step = b.step("dt", "Install dt executable");

    const dt = b.addExecutable(.{
        .name = "dt",
        .root_source_file = root_source_file,
        .optimize = optimize,
        .target = target,
    });

    const dt_install = b.addInstallArtifact(dt, .{});
    dt_step.dependOn(&dt_install.step);
    b.default_step.dependOn(dt_step);

    // Dt cross-compiled executables
    const cross_step = b.step("cross", "Install cross-compiled executables");

    inline for (TRIPLES) |TRIPLE| {
        const exe = "dt-" ++ TRIPLE;

        const query = try std.zig.CrossTarget.parse(.{ .arch_os_abi = TRIPLE });

        const cross: *std.Build.Step.Compile = b.addExecutable(.{
            .name = exe,
            .root_source_file = root_source_file,
            .optimize = optimize,
            .target = if (comptime @hasDecl(std.zig.system, "resolveTargetQuery"))
                // Zig 0.12
                .{ .query = query, .result = try std.zig.system.resolveTargetQuery(query) }
            else
                // Zig 0.11
                query,
        });

        const cross_install = b.addInstallArtifact(cross, .{});

        const exe_filename = if (query.cpu_arch == .wasm32) exe ++ ".wasm" else if (query.os_tag == .windows) exe ++ ".exe" else exe;

        const cross_tar = b.addSystemCommand(&.{
            "tar", "--transform", "s|" ++ exe ++ "|dt|", "-czvf", exe ++ ".tgz", exe_filename,
        });

        if (comptime @hasDecl(@TypeOf(cross_tar.*), "setCwd")) {
            // Zig 0.12.0
            cross_tar.setCwd(.{ .path = "./zig-out/bin/" });
        } else {
            // Zig 0.11.0
            cross_tar.cwd = "./zig-out/bin/";
        }

        cross_tar.step.dependOn(&cross_install.step);
        cross_step.dependOn(&cross_tar.step);
    }

    // Tests
    const test_step = b.step("test", "Run tests");

    const test_exe = b.addTest(.{
        .root_source_file = root_source_file,
        .optimize = optimize,
        .target = target,
    });

    const test_run = b.addRunArtifact(test_exe);
    test_run.step.dependOn(dt_step);
    test_step.dependOn(&test_run.step);
    b.default_step.dependOn(test_step);
}

const TRIPLES = .{
    "aarch64-linux-gnu",
    "aarch64-linux-musleabi",
    "aarch64-macos-none",
    "arm-linux-musleabi",
    "arm-linux-musleabihf",
    "mips-linux-gnu",
    "mips-linux-musl",
    "mips64-linux-gnuabi64",
    "mips64-linux-musl",
    "mips64el-linux-gnuabi64",
    "mips64el-linux-musl",
    "mipsel-linux-gnu",
    "mipsel-linux-musl",
    "powerpc-linux-gnu",
    "powerpc-linux-musl",
    "powerpc64le-linux-gnu",
    "powerpc64le-linux-musl",
    "riscv64-linux-gnu",
    "riscv64-linux-musl",
    "wasm32-wasi-musl",
    "x86_64-linux-gnu",
    "x86_64-linux-musl",
    "x86_64-macos-none",
    "x86-linux-gnu",
    "x86-linux-musl",
    "x86-windows-gnu",
    "x86_64-windows-gnu",
};
