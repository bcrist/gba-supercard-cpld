pub const FLASH_SRAM_nWE = Chip.pins._55.pad();
pub const FLASH_SRAM_nOE = Chip.pins._57.pad();

pub const SRAM = struct {
    // A15..0 are directly connected to the GP bus AD15..0
    pub const A16 = Chip.pins._87.pad();

    // SRAM data bus is directly connected to the GP bus AD23..16
    
    // nCE is directly connected to cart's CS2 and never connected to the CPLD
    // (assume CS and CS2 are never simultaneously asserted :P)
    pub const nWE = FLASH_SRAM_nWE;
    pub const nOE = FLASH_SRAM_nOE;
};

pub const SDRAM = struct {
    pub const A: [13]Chip.Signal = .{
        Chip.pins._124.pad(),
        Chip.pins._119.pad(),
        Chip.pins._116.pad(),
        Chip.pins._109.pad(),
        Chip.pins._111.pad(),
        Chip.pins._118.pad(),
        Chip.pins._121.pad(),
        Chip.pins._126.pad(),
        Chip.pins._128.pad(),
        Chip.pins._14.pad(),
        Chip.pins._127.pad(),
        Chip.pins._15.pad(),
        Chip.pins._18.pad(),
    };

    pub const BA: [2]Chip.Signal = .{
        Chip.pins._6.pad(),
        Chip.pins._4.pad(),
    };

    pub const nRAS = Chip.pins._9.pad();
    pub const nCAS = Chip.pins._11.pad();
    pub const nWE = Chip.pins._13.pad();
    pub const CLK = Chip.pins._114.pad(); // 50MHz
    pub const CKE = Chip.pins._7.pad();

    // Output/input data signals (DQ15..0) are connected to the GP bus as well (AD15..0)
    // nCS is always asserted, DQML & DQMH are always asserted (always write a full 16 bit word)

    // Goes low 2 SDRAM clock cycles after either nRD or nWR signals are asserted by the bus (classic 2-flop synchronizer)
    pub const n_bus_req = Chip.Signal.mc_H14;
    pub const n_bus_req_sync1 = Chip.Signal.mc_H15;
};

pub const FLASH = struct {
    pub const A: [16]Chip.Signal = .{
        Chip.pins._36.pad(),
        Chip.pins._20.pad(),
        Chip.pins._27.pad(),
        Chip.pins._21.pad(),
        Chip.pins._26.pad(),
        Chip.pins._28.pad(),
        Chip.pins._23.pad(),
        Chip.pins._35.pad(),
        Chip.pins._44.pad(),
        Chip.pins._52.pad(),
        Chip.pins._37.pad(),
        Chip.pins._45.pad(),
        Chip.pins._39.pad(),
        Chip.pins._42.pad(),
        Chip.pins._25.pad(),
        Chip.pins._47.pad(),
    };
    // A20..16 are directly connected to the GP bus (AD20..16)

    pub const nCE = Chip.pins._54.pad(); // independent from SRAM!
    pub const nWE = FLASH_SRAM_nWE;
    pub const nOE = FLASH_SRAM_nOE;
};

pub const GP = struct {
    pub const nCS = Chip.pins._48.pad();
    pub const nRD = Chip.pins._34.pad();
    pub const nWR = Chip.pins._50.pad();

    pub const AD: [24]Chip.Signal = .{
        Chip.pins._60.pad(),
        Chip.pins._62.pad(),
        Chip.pins._63.pad(),
        Chip.pins._64.pad(),
        Chip.pins._68.pad(),
        Chip.pins._70.pad(),
        Chip.pins._71.pad(),
        Chip.pins._73.pad(),
        Chip.pins._75.pad(),
        Chip.pins._77.pad(),
        Chip.pins._78.pad(),
        Chip.pins._79.pad(),
        Chip.pins._82.pad(),
        Chip.pins._84.pad(),
        Chip.pins._85.pad(),
        Chip.pins._89.pad(),
        Chip.pins._16.pad(),
        Chip.pins._29.pad(),
        Chip.pins._80.pad(),
        Chip.pins._90.pad(),
        Chip.pins._91.pad(),
        Chip.pins._92.pad(),
        Chip.pins._93.pad(),
        Chip.pins._98.pad(),
    };

    // These macrocells drive SD data onto AD15..0 when reading from the SD card
    // Note there is some ORM usage here
    pub const output_mc: [16]Chip.Signal = .{
        .mc_E8,
        .mc_E10,
        .mc_E12,
        .mc_E14,
        .mc_F2,
        .mc_F3,
        .mc_F4,
        .mc_F6,
        .mc_F8,
        .mc_F10,
        .mc_F12,
        .mc_F13,
        .mc_G4,
        .mc_G12,
        .mc_G10,
        .mc_G6
    };
};

pub const SD = struct {
    pub const DAT: [4]Chip.Signal = .{
        Chip.pins._100.pad(),
        Chip.pins._99.pad(),
        Chip.pins._108.pad(),
        Chip.pins._106.pad(),
    };

    pub const CMD = Chip.pins._103.pad();
    pub const CLK = Chip.pins._101.pad();

    pub const reg1: [7]Chip.Signal = .{
        .mc_F7,
        .mc_F9,
        .mc_F11,
        .mc_E15,
        .mc_E13,
        .mc_H13,
        .mc_H7,
    };

    pub const reg2: [8]Chip.Signal = .{
        .mc_F5,
        .mc_E0,
        .mc_E2,
        .mc_E0,
        .mc_E2,
        .mc_F1,
        .mc_F0,
        .mc_F15,
    };
};


// Goes high when the 0xFFFFFF address goes in the bus (combinational)
pub const MAGICADDR = Chip.Signal.mc_C11;

// Internal magic reg (0x1FFFFFE), has 3 bits (LSB) plus some other weird/complex bits too

// 1 for SDRAM, 0 for flash
pub const MAP_REG = Chip.Signal.mc_B12;

// Enable SD driver via the top mem space
pub const SD_ENABLE = Chip.Signal.mc_B11;

// Bit that enables writing to DDR (and other stuff?) as well as SRAM bankswitch?
pub const WRITE_ENABLE = Chip.Signal.mc_G8;



// Signal to load the magic reg. Checks for magic sequence.
pub const LOAD_IREG = Chip.Signal.mc_C12;

// SDRAM related logic:
// (N) The DDR is selected, asserted for the lower space or when the SD is disabled (and the DDR is mapped)
pub const nSDRAM_SEL = Chip.Signal.mc_E4;


// SD specific logic
// negative signal that goes down when the SD card driver is enabled
pub const nSDOUT = Chip.Signal.mc_E1;

// Internal Flash/SDRAM address generation (auto-increment adder magic)
// Note there are some weird remappings here (the memory is not really linear)
pub const IADDR: [16]Chip.Signal = .{
    .mc_C5,   // FLASH-A4
    .mc_D3,   // FLASH-A1
    .mc_C2,   // FLASH-A5
    .mc_D11,  // FLASH-A8
    .mc_C3,   // FLASH-A7
    .mc_C7,   // FLASH-A3
    .mc_C4,   // FLASH-A2
    .mc_D15,  // FLASH-A0
    .mc_D4,   // FLASH-A6
    .mc_D5,   // FLASH-A9
    .mc_D14,  // FLASH-A10
    .mc_D6,   // FLASH-A11
    .mc_D13,  // FLASH-A12
    .mc_D12,  // FLASH-A13
    .mc_D7,   // FLASH-A14
    .mc_D8,   // FLASH-A15
};

// Used to load address (instead of incrementing it)
pub const IADDR_LOAD = Chip.Signal.mc_H12;

// Some internal counter/FSM, 9 bits, used for SDRAM signals it seems!
pub const SDRAM_COUNTER: [9]Chip.Signal = .{
    .mc_A12,
    .mc_A10,
    .mc_G7,
    .mc_G5,
    .mc_G13,
    .mc_G0,
    .mc_G15,
    .mc_G11,
    .mc_G9,
};

pub const SDRAM_CTRL0 = Chip.Signal.mc_A7;
pub const SDRAM_CTRL1 = Chip.Signal.mc_A3;
pub const SDRAM_CTRL2 = Chip.Signal.mc_A9;
pub const SDRAM_CTRL3 = Chip.Signal.mc_A11;

const Chip = lc4k.LC4128V_TQFP128;
const lc4k = @import("lc4k");
