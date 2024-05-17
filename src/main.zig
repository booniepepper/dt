const std = @import("std");
const Allocator = std.mem.Allocator;
const osExit = if (@hasDecl(std, "posix")) std.posix.exit else std.os.exit;

const builtins = @import("builtins.zig");

const interpret = @import("interpret.zig");
const DtMachine = interpret.DtMachine;

// TODO: Change to @import when it's supported for zon
pub const version = "2.0.0-rc"; // Update in build.zig.zon as well.

const stdlib = @embedFile("stdlib.dt");
const dtlib = @embedFile("dt.dt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var dt = try DtMachine.init(arena.allocator());

    try builtins.defineAll(&dt);
    try dt.loadFile(stdlib);
    try dt.loadFile(dtlib);

    const stdinPiped = !std.io.getStdIn().isTty();
    const stdoutPiped = !std.io.getStdOut().isTty();

    if (@import("builtin").os.tag == .windows) {
        _ = std.os.windows.kernel32.SetConsoleOutputCP(65001);
    }

    const firstArgMaybe = try readFirstArg(arena.allocator());

    if (firstArgMaybe) |firstArg| {
        if (try readShebangFile(arena.allocator(), firstArg)) |fileContents| {
            return dt.loadFile(fileContents) catch |e| return doneOrDie(&dt, e);
        } else if ((std.mem.eql(u8, firstArg, "--stream") or std.mem.startsWith(u8, firstArg, "--stream ")) and (stdinPiped or stdoutPiped)) {
            dt.handleCmd("dt/run-args") catch |e| return doneOrDie(&dt, e);
        }
    }

    if (stdinPiped) {
        dt.handleCmd("dt/pipe-thru-args") catch |e| return doneOrDie(&dt, e);
    } else {
        dt.handleCmd("dt/run-args") catch |e| return doneOrDie(&dt, e);
    }
}

fn readFirstArg(allocator: Allocator) !?[]const u8 {
    var args = try std.process.argsWithAllocator(allocator);
    _ = args.skip(); // Discard process name
    return if (args.next()) |arg| try allocator.dupe(u8, arg) else null;
}

fn doneOrDie(dt: *DtMachine, reason: anyerror) !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("\n", .{});
    switch (reason) {
        error.EndOfStream => {},
        error.BrokenPipe => {},
        else => {
            try dt.red();
            try stderr.print("\nRIP: {any}\n", .{reason});
            try dt.norm();

            osExit(1);
        },
    }
}

fn readShebangFile(allocator: Allocator, maybeFilepath: []const u8) !?[]const u8 {
    // We get a Dir from CWD so we can resolve relative paths
    const theCwdPath = try std.process.getCwdAlloc(allocator);
    var theCwd = try std.fs.openDirAbsolute(theCwdPath, .{});

    const file = theCwd.openFile(maybeFilepath, .{}) catch return null;
    defer file.close();

    const contents = try file.readToEndAlloc(allocator, std.math.pow(usize, 2, 16));

    if (std.mem.startsWith(u8, contents, "#!")) {
        return contents;
    }

    return null;
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("tests/bool_tests.zig");
    _ = @import("tests/dt_args_basic.zig");
    _ = @import("tests/dtsh_run_basic.zig");
    _ = @import("tests/def_scope_tests.zig");
    _ = @import("tests/project_euler_tests.zig");
    _ = @import("tests/dtsh_interactive_basic.zig");
}
