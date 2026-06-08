const std = @import("std");
const fontset = [80]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};
const Chip8 = struct {
    const Self = @This();

    opcode: u16 = 0,
    memory: [4096]u8 = fontset ++ @as([4096 - fontset.len]u8, @splat(0)),
    V: [16]u8 = 0,
    I: u16 = 0,
    pc: u16 = 0x200,
    gfx: [64 * 32]u8 = @splat(0),
    delay_timer: u8 = 0,
    sound_timer: u8 = 0,
    stack: [16]u16 = @splat(0),
    sp: u16 = 0,
    key: [16]u8 = 0,

    pub fn load_game(self: *Self, [:0]const u8) void {
        // // Load ROM (Technically not a ROM) into memory
        //     FILE *rom = fopen(name, "rb"); // open in read binary mode
        //     if (rom == NULL)
        //     {
        //         printf("Failed to open ROM!\n");
        //         return;
        //     }

        //     // Read ROM into memory starting at 0x200
        //     fread(&pChip8->memory[0x200], 1, 4096, rom);
        //     fclose(rom);
    }
    pub fn emulate_cycle(self: *Self) void {
        // chip8 opcodes are 2 bytes so need to offset then bit mask
        self.opcode = self.memory[self.pc] << 8 | self.memory[self.pc + 1];
        std.debug.print("0x{x}\n", .{self.opcode});

        // Isolate the opcode fields so we can use them individually
        const x: u4 = (self.opcode & 0x0F00) >> 8;
        const y: u4 = (self.opcode & 0x00F0) >> 4;
        switch (self.opcode & 0xF000) {
            0x0000 => switch (self.opcode & 0x00FF) {
                // Clear screen
                0x00E0 => {
                    @memset(self.gfx, 0);
                    self.pc += 2;
                },
                0x00EE => {
                    self.sp -= 1;
                    self.pc = self.stack[self.sp];
                    self.pc += 2;
                },
            },
            // 1NNN
            // Jump to address NNN
            0x1000 => self.pc = self.opcode & 0x0FFF,
            // 2NNN
            0x2000 => {
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = self.opcode & 0x0FFF;
            },
            // 3XNN
            // Skip next instruction if the value in VX == NN
            0x3000 => {
                if (self.V[(0x0F00 & self.opcode) >> 8] == (0x00FF & self.opcode)) {
                    self.pc += 4;
                } else {
                    self.pc += 2;
                }
            },
            // 4XNN
            // Skip next instruction if the value in VX != NN
            0x4000 => {
                if (self.V[(0x0F00 & self.opcode) >> 8] != (0x00FF & self.opcode)) {
                    self.pc += 4;
                } else {
                    self.pc += 2;
                }
            },
            // 5XY0
            // Skip next instruction if registers are equal
            0x5000 => {
                if (self.V[(0x0F00 & self.opcode) >> 8] == self.V[(0x0F00 & self.opcode) >> 4]) {
                    self.pc += 4;
                } else {
                    self.pc += 2;
                }
            },
            // 6XNN
            // Set register X to number NN
            0x6000 => {
                self.V[x] = self.opcode & 0x00FF;
                self.pc += 2;
            },
            // 7XNN
            // Add number NN to register X
            0x7000 => {
                self.V[x] += self.opcode & 0x00FF;
                self.pc += 2;
            },
            0x8000 => {
                // switch statement
            },
            // 9XY0
            // Skip next instruction if registers are not equal
            0x9000 => {
                if (self.V[(0x0F00 & self.opcode) >> 8] != self.V[(0x0F00 & self.opcode) >> 4]) {
                    self.pc += 4;
                } else {
                    self.pc += 2;
                }
            },
            // ANNN
            // Add NNN at ANNN to I register
            0xA000 => {
                self.I = self.opcode & 0x0FFF;
                self.pc += 2;
            },
            // Unimplemented
            0xB000 => {
                // Something idk
            },
            // CXNN
            // Random
            0xC000 => {
                // self.V[x] = (self.opcode & 0x00FF) & (random something zig)
            },
            // DXYN
            // Display
            0xD000 => {
                // Grab the coordinates in registers X and Y
                const xPos: usize = self.V[x] % 64;
                const yPos: usize = self.V[y] % 32;
                // Set VF to 0
                self.V[0xF] = 0;
                // For N rows
                for (0..(self.opcode & 0x000F)) |row| {
                    // Get the Nth (row) byte of sprite data
                    const sprite_row = self.memory[self.I + row];
                    // 0x80 is 10000000 which is the first in the sprite row
                    for (0..8) |bit| {
                        if (sprite_row & (0x80 >> bit) != 0) {
                            const index = (yPos + row) * 64 + (xPos + bit);
                            if (self.gfx[index] == 1) {
                                self.V[0xF] = 1;
                            }
                            // XOR the pixel
                            self.gfx[index] ^= 1;
                        }
                    }
                }
                self.pc += 2;
            },
            0xE000 => {
                // Switch here
            },
            0xF000 => {
                // Switch here
            },
        }
    }
};
