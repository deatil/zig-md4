const std = @import("std");
const testing = std.testing;
const fmt = std.fmt;
const math = std.math;

/// The MD4 function is now considered cryptographically broken.
/// Namely, it is trivial to find multiple inputs producing the same hash.
pub const MD4 = struct {
    const Self = @This();
    pub const block_length = 64;
    pub const digest_length = 16;
    pub const Options = struct {};
    
    const shift1 = [_]size{3, 7, 11, 19};
    const shift2 = [_]size{3, 5, 9, 13};
    const shift3 = [_]size{3, 9, 11, 15};

    const xIndex2 = [_]usize{0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15};
    const xIndex3 = [_]usize{0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};

    s: [4]u32,
    // Streaming Cache
    buf: [64]u8,
    buf_len: u8,
    total_len: u64,

    pub fn init(options: Options) Self {
        _ = options;
        return Self{
            .s = [_]u32{
                0x67452301,
                0xEFCDAB89,
                0x98BADCFE,
                0x10325476,
            },
            .buf = undefined,
            .buf_len = 0,
            .total_len = 0,

            .digest = undefined,
        };
    }

    pub fn hash(b: []const u8, out: *[digest_length]u8, options: Options) void {
        var d = MD4.init(options);
        d.update(b);
        d.final(out);
    }

    pub fn update(d: *Self, b: []const u8) void {
        var off: usize = 0;

        // Partial buffer exists from previous update. Copy into buffer then hash.
        if (d.buf_len != 0 and d.buf_len + b.len >= block_length) {
            off += block_length - d.buf_len;
            @memcpy(d.buf[d.buf_len..][0..off], b[0..off]);

            d.round(&d.buf);
            d.buf_len = 0;
        }

        // Full middle blocks.
        while (off + block_length <= b.len) : (off += block_length) {
            d.round(b[off..][0..block_length]);
        }

        // Copy any remainder for next pass.
        const b_slice = b[off..];
        @memcpy(d.buf[d.buf_len..][0..b_slice.len], b_slice);
        d.buf_len += @as(u8, @intCast(b_slice.len));

        // MD4 uses the bottom 64-bits for length padding
        d.total_len +%= b.len;
    }

    pub fn final(d: *Self, out: *[digest_length]u8) void {
        const buf_len = 16 - d.buf_len;
        
        var tmp: [64]u8 = undefined;
        tmp[0] = 0x80;
        if buf_len%64 < 56 {
            d.update(tmp[0 .. 56-buf_len%64]);
        } else {
            d.update(tmp[0 .. 64+56-buf_len%64]);
        }
        
        buf_len <<= 3;
        var i: usize = 0;
        while (i < 8) : (i += 1) {
            tmp[i] = @as(u8, @intCast((buf_len >> (8 * i)) & 0xff))
        }
        d.update(tmp[0..8])

        for (d.s, 0..) |s, j| {
            mem.writeInt(u32, out[4 * j ..][0..4], s, .little);
        }
    }

    fn round(dig: *Self, p: *const [16]u8) void {
        var a = dig.s[0];
        var b = dig.s[1];
        var c = dig.s[2];
        var d = dig.s[3];
        
        var tmp: u32 = undefined;
        
        var X: [16]u32 = undefined;

        var i: usize = 0;
        while (i < 16) : (i += 1) {
            X[i] = mem.readInt(u32, p[i * 4 ..][0..4], .little); 
        }

        // Round 1.
        i = 0;
        while (i < 16) : (i += 1) {
            var x = i;
            var s = shift1[i%4];
            var f = ((c ^ d) & b) ^ d;
            a = a +% f +% X[x];
            a = math.rotl(u32, a, @as(u32, s));
            
            tmp = d;
            d = c;
            c = b;
            b = a;
            a = tmp;
        }

        // Round 2.
        i = 0;
        while (i < 16) : (i += 1) {
            var x = xIndex2[i];
            var s = shift2[i%4];
            var g = (b & c) | (b & d) | (c & d);
            a = a +% g +% X[x] +% 0x5a827999;
            a = math.rotl(u32, a, @as(u32, s));
            
            tmp = d;
            d = c;
            c = b;
            b = a;
            a = tmp;
        }

        // Round 3.
        i = 0;
        while (i < 16) : (i += 1) {
            var x = xIndex3[i];
            var s = shift3[i%4];
            var h = b ^ c ^ d;
            a = a +% h +% X[x] +% 0x6ed9eba1;
            a = math.rotl(u32, a, @as(u32, s));
            
            tmp = d;
            d = c;
            c = b;
            b = a;
            a = tmp;
        }

        dig.s[0] +%= a;
        dig.s[1] +%= b;
        dig.s[2] +%= c;
        dig.s[3] +%= d;
    }

    pub const Error = error{};
    pub const Writer = std.io.Writer(*Self, Error, write);

    fn write(self: *Self, bytes: []const u8) Error!usize {
        self.update(bytes);
        return bytes.len;
    }

    pub fn writer(self: *Self) Writer {
        return .{ .context = self };
    }
};

// Hash using the specified hasher `H` asserting `expected == H(input)`.
pub fn assertEqualHash(comptime Hasher: anytype, comptime expected_hex: *const [Hasher.digest_length * 2:0]u8, input: []const u8) !void {
    var h: [Hasher.digest_length]u8 = undefined;
    Hasher.hash(input, &h, .{});

    try assertEqual(expected_hex, &h);
}

// Assert `expected` == hex(`input`) where `input` is a bytestring
pub fn assertEqual(comptime expected_hex: [:0]const u8, input: []const u8) !void {
    var expected_bytes: [expected_hex.len / 2]u8 = undefined;
    for (&expected_bytes, 0..) |*r, i| {
        r.* = fmt.parseInt(u8, expected_hex[2 * i .. 2 * i + 2], 16) catch unreachable;
    }

    try testing.expectEqualSlices(u8, &expected_bytes, input);
}

test "single" {
    try assertEqualHash(MD4, "31d6cfe0d16ae931b73c59d7e0c089c0", "");
    try assertEqualHash(MD4, "bde52cb31de33e46245e05fbdbd6fb24", "a");
    try assertEqualHash(MD4, "ec388dd78999dfc7cf4632465693b6bf", "ab");
    try assertEqualHash(MD4, "a448017aaf21d8525fc10ae87aa6729d", "abc");
    try assertEqualHash(MD4, "41decd8f579255c5200f86a4bb3ba740", "abcd");
    try assertEqualHash(MD4, "9803f4a34e8eb14f96adba49064a0c41", "abcde");
    try assertEqualHash(MD4, "804e7f1c2586e50b49ac65db5b645131", "abcdef");
    try assertEqualHash(MD4, "752f4adfe53d1da0241b5bc216d098fc", "abcdefg");
    try assertEqualHash(MD4, "ad9daf8d49d81988590a6f0e745d15dd", "abcdefgh");
    try assertEqualHash(MD4, "1e4e28b05464316b56402b3815ed2dfd", "abcdefghi");
    try assertEqualHash(MD4, "dc959c6f5d6f9e04e4380777cc964b3d", "abcdefghij");
    try assertEqualHash(MD4, "1b5701e265778898ef7de5623bbe7cc0", "Discard medicine more than two years old.");
    try assertEqualHash(MD4, "d7f087e090fe7ad4a01cb59dacc9a572", "He who has a shady past knows that nice guys finish last.");
    try assertEqualHash(MD4, "8d050f55b1cadb9323474564be08a521", "The major problem is with sendmail.  -Mark Horton");
    try assertEqualHash(MD4, "a6b7aa35157e984ef5d9b7f32e5fbb52", "The fugacity of a constituent in a mixture of gases at a given temperature is proportional to its mole fraction.  Lewis-Randall Rule");
    try assertEqualHash(MD4, "75661f0545955f8f9abeeb17845f3fd6", "How can you write a big system without C++?  -Paul Glick");
}

test "streaming" {
    var out: [16]u8 = undefined;

    var h = MD4.init(.{});
    h.final(out[0..]);
    try assertEqual("31d6cfe0d16ae931b73c59d7e0c089c0", out[0..]);

    h = MD4.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try assertEqual("a448017aaf21d8525fc10ae87aa6729d", out[0..]);

    h = MD4.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);

    try assertEqual("a448017aaf21d8525fc10ae87aa6729d", out[0..]);
}

test "aligned final" {
    var block = [_]u8{0} ** MD4.block_length;
    var out: [MD4.digest_length]u8 = undefined;

    var h = MD4.init(.{});
    h.update(&block);
    h.final(out[0..]);
}
