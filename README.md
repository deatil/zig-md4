## Zig-MD4 

Zig-MD4 是一个使用 zig 语言编写的 MD4 库


### 环境要求

 - Zig >= 0.12


### 开始使用

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


### 开源协议

*  本软件包遵循 `Apache2` 开源协议发布，在保留本软件包版权的情况下提供个人及商业免费使用。


### 版权

*  本软件包所属版权归 deatil(https://github.com/deatil) 所有。
