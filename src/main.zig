const std = @import("std");
const Io = std.Io;
const c = @import("c");

const Chip8 = @import("Chip8.zig");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var chip8: Chip8 = .{};
    if (!c.SDL_Init(c.SDL_INIT_VIDEO)) {
        return error.SDLInitFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("CHIP-8", // window title
        640, // width, in pixels
        320, // height, in pixels
        0 // flags - see below
    );

    var it = init.minimal.args.iterate();
    _ = it.next(); // skip program name
    const first = it.next() orelse {
        std.debug.print("no argument provided\n", .{});
        return;
    };
    const renderer: *c.SDL_Renderer = c.SDL_CreateRenderer(window, 0).?;
    try chip8.load_game(io, first);

    var done: bool = false;
    while (!done) {
        var event: c.SDL_Event = undefined;

        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT) {
                done = true;
            }
            // set_keys(&chip8, &event);
        }
        chip8.emulate_cycle();
        chip8.draw_graphics(renderer);
    }

    // var renderer: *SDL_Renderer = c.SDL_CreateRenderer(window, -1, 0);
}
