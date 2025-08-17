pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lc4k = b.dependency("lc4k", .{}).module("lc4k");

    const exe = b.addExecutable(.{
        .name = "supercard",
        .root_source_file = b.path("supercard.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("lc4k", lc4k);
    b.installArtifact(exe);
    b.getInstallStep().dependOn(&b.addRunArtifact(exe).step);
}

const std = @import("std");
