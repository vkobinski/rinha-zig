const pg = @import("pg");
const std = @import("std");

pub const Saldo = struct {
    saldo_id: i32,
    total: i32,
    limite: i32,
    data_extrato: i64,

    pub fn init(row: pg.Row) !Saldo {
        return Saldo{
            .saldo_id = row.get(i32, 0),
            .total = row.get(i32, 1),
            .limite = row.get(i32, 2),
            .data_extrato = 0,
        };
    }

    pub fn print(self: Saldo) void {
        std.debug.print("Saldo \nId: {d}\nTotal: {d}\nLimite: {d}\n", .{ self.saldo_id, self.total, self.limite });
    }
};
