const Chip = lc4k.LC4128V_TQFP128;
const naming = @import("naming.zig");
const jedec_data_from_chip = @embedFile("read_from_chip.jed");

fn configure_magic(chip: *Chip, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = lp;
}

fn configure_sdram(chip: *Chip, lp: *Chip.Logic_Parser) !void {
    // n_bus_req is active (low) when a read or write request begins on the GP bus.
    // it is reclocked into the 50MHz SDRAM clock domain so it is delayed by 20-40ns
    // TODO: likely this signal forces the SDRAM out of refresh mode and begins activating the relevant bank/row
    {
        const mcref = naming.SDRAM.n_bus_req_sync1.mc();
        chip.glb[mcref.glb].shared_pt_clock = try lp.pt_with_polarity("SDRAM.CLK", .{});

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic("GP.nWR & GP.nRD", .{});
        mc.func = .{ .d_ff = .{
            .clock = .shared_pt_clock,
        }};
    }
    {
        const mcref = naming.SDRAM.n_bus_req.mc();
        std.debug.assert(mcref.glb == naming.SDRAM.n_bus_req_sync1.mc().glb);

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic("SDRAM.n_bus_req_sync1", .{});
        mc.func = .{ .d_ff = .{
            .clock = .shared_pt_clock,
        }};
    }
}

fn configure_flash(chip: *Chip, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = lp;
}

fn configure_sram(chip: *Chip, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = lp;
}

fn configure_sdcard(chip: *Chip, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = lp;
}

pub fn main() !void {
    var names: Chip.Names = .init(gpa);
    //names.fallback = null;
    names.allow_multiple_names = true;
    try names.add_names(naming, .{});

    var lp: Chip.Logic_Parser = .{
        .gpa = gpa,
        .arena = .init(gpa),
        .names = &names,
    };

    var chip: Chip = .{};
    chip.default_bus_maintenance = .pullup;

    try configure_magic(&chip, &lp);
    try configure_sdram(&chip, &lp);
    try configure_flash(&chip, &lp);
    try configure_sram(&chip, &lp);
    try configure_sdcard(&chip, &lp);

    const assembly_results = try chip.assemble(gpa, .{ .use_lattice_false_pt = true });
    const bitstream_generated = assembly_results.jedec;
    {
        var f = try std.fs.cwd().createFile("generated.html", .{});
        defer f.close();

        try Chip.write_report(7, bitstream_generated, f.writer(), .{
            .design_name = "GBA Supercard CPLD (generated)",
            .names = &names,
            .skip_timing = true,
        });
    }
    {
        var f = try std.fs.cwd().createFile("generated.jed", .{});
        defer f.close();

        try Chip.write_jed(bitstream_generated, f.writer(), .{});
    }
    {
        var f = try std.fs.cwd().createFile("generated.svf", .{});
        defer f.close();

        try Chip.write_svf(bitstream_generated, f.writer(), .{});
    }

    const bitstream_from_chip = try Chip.parse_jed(gpa, jedec_data_from_chip);
    {
        var f = try std.fs.cwd().createFile("read_from_chip.html", .{});
        defer f.close();

        try Chip.write_report(7, bitstream_from_chip, f.writer(), .{
            .design_name = "GBA Supercard CPLD (from chip)",
            .names = &names,
            .skip_timing = true,
        });
    }

    try Chip.write_diff_summary(gpa, bitstream_from_chip, bitstream_generated, std.io.getStdOut().writer(), .{
        .names = &names,
        .skip_gis = true,
        .skip_pts = true,
        .skip_mcs = true,
        .skip_ios = true,
        .single_glb = 7,
    });
}

const gpa = std.heap.smp_allocator;

const lc4k = @import("lc4k");
const std = @import("std");
