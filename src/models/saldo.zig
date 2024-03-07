const pg = @import("pg");
const std = @import("std");
const transacao = @import("transacao.zig");

const TipoTransacaoError = error{
    TransacaoError,
};

pub const SaldoResponse = struct {
    limite: i32,
    saldo: i32,

    pub fn init(limite: i32, saldo: i32) !SaldoResponse {
        return SaldoResponse{
            .limite = limite,
            .saldo = saldo,
        };
    }
};

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

    pub fn create_transacao(pool: *pg.Pool, cliente_id: i32, t: transacao.TransacaoReq) !SaldoResponse {
        const saldo = try get_saldo_for_cliente(pool, cliente_id);

        const tipo = try transacao.Transacao.parseTransacao(t.tipo);
        var novo_saldo: i32 = 0;

        switch (tipo) {
            transacao.TipoTransacao.c => {
                novo_saldo = saldo.total + t.valor;
            },
            transacao.TipoTransacao.d => {
                if ((saldo.total - t.valor) < -saldo.limite) {
                    return TipoTransacaoError.TransacaoError;
                }

                novo_saldo = saldo.total - t.valor;
            },
        }

        var result = try pool.query(
            \\INSERT INTO transacao (cliente_id, valor, tipo, descricao, realizada_em)
            \\VALUES ($1, $2, $3, $4, NOW())
            \\RETURNING cliente_id
        , .{ cliente_id, t.valor, t.tipo, t.descricao });

        defer result.deinit();

        var result_update = try pool.query(
            \\UPDATE saldo
            \\SET total = $1
            \\WHERE saldo_id = $2
            \\RETURNING saldo_id
        , .{ novo_saldo, saldo.saldo_id });

        defer result_update.deinit();

        return SaldoResponse{
            .limite = saldo.limite,
            .saldo = novo_saldo,
        };
    }

    pub fn get_saldo_for_cliente(pool: *pg.Pool, cliente_id: i32) !Saldo {
        var result = try pool.query(
            \\SELECT saldo_id, total, limite
            \\FROM saldo
            \\WHERE cliente_id = $1
            //\\FOR UPDATE
        , .{cliente_id});

        defer result.deinit();

        while (try result.next()) |row| {
            return try init(row);
        }

        return TipoTransacaoError.TransacaoError;
    }
};
