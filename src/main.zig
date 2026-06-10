const std = @import("std");
const Io = std.Io;
const c = @import("c");

const Chip8 = @import("Chip8.zig");

pub fn main() !void {
    const chip8 = Chip8.init();
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const done: bool = false;

    const window = c.SDL_CreateWindow("CHIP-8", 640, 360, 0);
    // var renderer: *SDL_Renderer = c.SDL_CreateRenderer(window, -1, 0);
    _ = chip8;
    _ = done;
    _ = window;
}
