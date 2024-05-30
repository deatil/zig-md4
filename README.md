## Zig-MD4 

zig-md4 is a MD4 hash function for Zig.


### Env

 - Zig >= 0.12


### Get Starting

~~~zig
const std = @import("std");
const MD4 = @import("zig-md4").MD4;

pub fn main() !void {
    var out: [16]u8 = undefined;
    
    h = MD4.init(.{});
    h.update("abc");
    h.final(out[0..]);
    
    // output: a448017aaf21d8525fc10ae87aa6729d
    std.debug.print("output: {s}\n", .{out});
}
~~~


### LICENSE

*  The library LICENSE is `Apache2`, using the library need keep the LICENSE.


### Copyright

*  Copyright deatil(https://github.com/deatil).
