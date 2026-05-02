const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "png",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const root = lib.root_module;

    if (target.result.os.tag == .linux) {
        root.linkSystemLibrary("m", .{});
    }

    const zlib_dep = b.dependency("zlib", .{ .target = target, .optimize = optimize });

    root.linkLibrary(zlib_dep.artifact("z"));

    root.addIncludePath(b.path("upstream"));
    root.addIncludePath(b.path("include"));

    var flags = std.ArrayListUnmanaged([]const u8).empty;
    defer flags.deinit(b.allocator);
    try flags.appendSlice(b.allocator, &.{
        "-DPNG_ARM_NEON_OPT=0",
        "-DPNG_POWERPC_VSX_OPT=0",
        "-DPNG_INTEL_SSE_OPT=0",
        "-DPNG_MIPS_MSA_OPT=0",
    });
    if (target.result.os.tag != .windows) {
        // Hide symbols so a process that also pulls in system libpng via
        // dlopen (e.g. through GTK/Cairo) does not mix the two copies.
        try flags.append(b.allocator, "-fvisibility=hidden");
    }
    root.addCSourceFiles(.{
        .root = b.path("upstream"),
        .files = srcs_relative,
        .flags = flags.items,
    });

    lib.installHeader(b.path("include/pnglibconf.h"), "pnglibconf.h");

    inline for (headers) |header| {
        lib.installHeader(b.path("upstream/" ++ header), header);
    }

    b.installArtifact(lib);
}

const headers = &.{
    "png.h",
    "pngconf.h",
    "pngdebug.h",
    "pnginfo.h",
    "pngpriv.h",
    "pngstruct.h",
};

const srcs_relative = &.{
    "png.c",
    "pngerror.c",
    "pngget.c",
    "pngmem.c",
    "pngpread.c",
    "pngread.c",
    "pngrio.c",
    "pngrtran.c",
    "pngrutil.c",
    "pngset.c",
    "pngtrans.c",
    "pngwio.c",
    "pngwrite.c",
    "pngwtran.c",
    "pngwutil.c",
};
