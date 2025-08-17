const Chip = lc4k.LC4128V_TQFP128;
const naming = @import("naming.zig");
const jedec_data_from_chip = @embedFile("read_from_chip.jed");

fn configure_magic(chip: *Chip, names: *const Chip.Names, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = names;
    _ = lp;
}

fn configure_sdram(chip: *Chip, names: *const Chip.Names, lp: *Chip.Logic_Parser) !void {
    // n_bus_req is active (low) when a read or write request begins on the GP bus.
    // it is reclocked into the 50MHz SDRAM clock domain so it is delayed by 20-40ns
    // TODO: likely this signal forces the SDRAM out of refresh mode and begins activating the relevant bank/row
    // TODO: is there a reason they're using a shared PT clock for this instead of just BCLK0?  Perhaps they want the few ns of added delay for some reason?
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

    // TODO: I expect CKE is deasserted during an SDRAM read once the FSM reaches the state
    // where the SDRAM is currently outputting the data.  Otherwise the data would only be valid
    // for ~20ns, and it would be nearly impossible to sync that up to the rising edge of nCS/nRD
    {
        const mcref = names.lookup_mc("SDRAM.CKE").?;
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        std.debug.assert(chip.glb[mcref.glb].bclock1 == .clk0_neg);

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic(
            \\   (!mc_A5 | !mc_B5 | !mc_B6 | !nSDRAM_SEL | SDRAM_COUNTER[8])
            \\ & (!mc_A5 | !mc_B5 | !mc_B6 | !nSDRAM_SEL | SDRAM_COUNTER[7])
            , .{});
        mc.func = .{ .d_ff = .{
            .clock = .bclock1,
        }};
        mc.output.oe = .output_only;
    }

    // TODO: unknown control signal
    {
        const mcref = naming.SDRAM_CTRL1.mc();
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        std.debug.assert(chip.glb[mcref.glb].bclock1 == .clk0_neg);

        // SDRAM_CTRL1.T = !mc_A5 & SDRAM_CTRL0 & mc_B5 & !mc_B6 & !mc_B9
        // SDRAM_CTRL1.CLK = GP.nCS // GLB 0 (A) BCLK 1
    }


    // TODO: SDRAM address outputs
    {
        const mcref = names.lookup_mc("SDRAM.A[2]").?;
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        std.debug.assert(chip.glb[mcref.glb].bclock1 == .clk0_neg);

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic(
            \\ (
            \\      $SDRAM.A[2] & mc_A5 & !mc_B6 & !mc_B9
            \\    | !mc_A5 & !mc_B5 & !mc_B6 & mc_B9 & IADDR[11]
            \\    | !mc_A5 & !mc_B5 & mc_B6 & mc_B9 & IADDR[2]
            \\ ) ^ ($SDRAM.A[2] & !mc_A5 & !mc_B5 & mc_B9)
            , .{});
        mc.func = .{ .t_ff = .{
            .clock = .bclock1,
        }};
        mc.output.oe = .output_only;
    }
    {
        const mcref = names.lookup_mc("SDRAM.A[5]").?;
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        std.debug.assert(chip.glb[mcref.glb].bclock1 == .clk0_neg);

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic(
            \\  $SDRAM.A[5] & mc_A5 & mc_B6
            \\| !mc_A5 & !mc_B5 & !mc_B6 & mc_B9 & IADDR[14]
            \\| !mc_A5 & !mc_B5 & mc_B6 & mc_B9 & IADDR[5]
            \\| mc_A5 & mc_B5 & !mc_B6 & !mc_B9
            \\| $SDRAM.A[5] & !mc_A5 & !mc_B9
            \\| $SDRAM.A[5] & mc_B5
            \\| $SDRAM.A[5] & mc_A5 & mc_B9
            , .{});
        mc.func = .{ .t_ff = .{
            .clock = .bclock1,
        }};
        mc.output.oe = .output_only;
    }
    {
        const mcref = names.lookup_mc("SDRAM.A[7]").?;
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        std.debug.assert(chip.glb[mcref.glb].bclock1 == .clk0_neg);

        const mc = chip.mc(mcref);
        mc.logic = try lp.logic(
            \\ (
            \\      $SDRAM.A[7] & mc_A5 & !mc_B6 & !mc_B9
            \\    | GP.AD[16] & !mc_A5 & !mc_B5 & !mc_B6 & mc_B9
            \\    | !mc_A5 & !mc_B5 & mc_B6 & mc_B9 & IADDR[7]
            \\ ) ^ ($SDRAM.A[7] & !mc_A5 & !mc_B5 & mc_B9)
            , .{});
        mc.func = .{ .t_ff = .{
            .clock = .bclock1,
        }};
        mc.output.oe = .output_only;
    }
}

fn configure_flash(chip: *Chip, names: *const Chip.Names, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = names;
    _ = lp;
}

fn configure_sram(chip: *Chip, names: *const Chip.Names, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = names;
    _ = lp;
}

fn configure_sdcard(chip: *Chip, names: *const Chip.Names, lp: *Chip.Logic_Parser) !void {
    _ = chip;
    _ = names;
    _ = lp;
}

pub fn main() !void {
    const bitstream_from_chip = try Chip.parse_jed(gpa, jedec_data_from_chip);
    const disassembly_results = try Chip.disassemble(gpa, bitstream_from_chip);

    var names: Chip.Names = .init(gpa);
    //names.fallback = null;
    names.allow_multiple_names = true;
    try names.add_names(naming, .{});
    try disassembly_results.config.propagate_names(gpa, &names);

    {
        var f = try std.fs.cwd().createFile("read_from_chip.html", .{});
        defer f.close();

        try Chip.write_report(7, bitstream_from_chip, f.writer(), .{
            .design_name = "GBA Supercard CPLD (from chip)",
            .names = &names,
            .skip_timing = true,
        });
    }

    var lp: Chip.Logic_Parser = .{
        .gpa = gpa,
        .arena = .init(gpa),
        .names = &names,
    };

    var chip: Chip = .{};
    chip.default_bus_maintenance = .pullup;

    for (0..7) |glb| {
        std.debug.assert(naming.SDRAM.CLK == .clk0);
        chip.glb[glb].bclock1 = .clk0_neg;

        std.debug.assert(naming.GP.nWR == .clk2);
        chip.glb[glb].bclock2 = .clk2_pos;
    }

    std.debug.assert(naming.GP.nCS == .clk1);
    chip.glb[2].bclock0 = .clk1_neg;

    try configure_magic(&chip, &names, &lp);
    try configure_sdram(&chip, &names, &lp);
    try configure_flash(&chip, &names, &lp);
    try configure_sram(&chip, &names, &lp);
    try configure_sdcard(&chip, &names, &lp);

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

    try Chip.write_diff_summary(gpa, bitstream_from_chip, bitstream_generated, std.io.getStdOut().writer(), .{
        .names = &names,
        .skip_gis = true,
        .skip_pts = true,
        .skip_mcs = true,
        .skip_ios = true,
        // .single_glb = 7,
    });
}

const gpa = std.heap.smp_allocator;

const lc4k = @import("lc4k");
const std = @import("std");
