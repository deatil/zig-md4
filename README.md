## Zig-MD4 

zig-md4 is a MD4 hash function for Zig.


### Env

 - Zig >= 0.15.1


### Adding zig-md4 as a dependency

Add the dependency to your project:

```sh
zig fetch --save=zig-md4 git+https://github.com/deatil/zig-md4#main
```

or use local path to add dependency at `build.zig.zon` file

```zig
.{
    .dependencies = .{
        .@"zig-md4" = .{
            .path = "./lib/zig-md4",
        },
        ...
    },
    ...
}
```

And the following to your `build.zig` file:

```zig
    const zig_md4_dep = b.dependency("zig-md4", .{});
    exe.root_module.addImport("zig-md4", zig_md4_dep.module("zig-md4"));
```

The `zig-md4` structure can be imported in your application with:

```zig
const zig_md4 = @import("zig-md4");
```


### Get Starting

~~~zig
const std = @import("std");
const MD4 = @import("zig-md4").MD4;

pub fn main() !void {
    var out: [16]u8 = undefined;
    
    var h = MD4.init(.{});
    h.update("abc");
    h.final(out[0..]);
    
    // output: a448017aaf21d8525fc10ae87aa6729d
    std.debug.print("output: {x}\n", .{out});
}
~~~


### LICENSE

*  The library LICENSE is `Apache2`, using the library need keep the LICENSE.


### Copyright

*  Copyright deatil(https://github.com/deatil).
