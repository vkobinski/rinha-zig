//{
//  "saldo": {
//    "total": -9098,
//    "data_extrato": "2024-01-17T02:34:41.217753Z",
//    "limite": 100000
//  },
//  "ultimas_transacoes": [
//    {
//      "valor": 10,
//      "tipo": "c",
//      "descricao": "descricao",
//      "realizada_em": "2024-01-17T02:34:38.543030Z"
//    },
//    {
//      "valor": 90000,
//      "tipo": "d",
//      "descricao": "descricao",
//      "realizada_em": "2024-01-17T02:34:38.543030Z"
//    }
//  ]
//}
//

const saldo = @import("saldo.zig");
const transacao = @import("transacao.zig");
const std = @import("std");
const pg = @import("pg");

pub const SaldoRes = struct {
    total: i32,
    data_extrato: []u8,
    limite: i32,
};

pub const Extrato = struct {
    saldo: SaldoRes,
    ultimas_transacoes: []transacao.Transacao,

    pub fn get_extrato(alloc: std.mem.Allocator, pool: *pg.Pool, cliente_id: i32) !Extrato {
        const saldo_cliente = try saldo.Saldo.get_saldo_for_cliente(pool, cliente_id);
        const transacoes = try transacao.Transacao.find_transacoes_by_cliente(alloc, pool, cliente_id);

        const saldo_resp = SaldoRes{
            .total = saldo_cliente.total,
            .data_extrato = "",
            .limite = saldo_cliente.limite,
        };

        return Extrato{
            .saldo = saldo_resp,
            .ultimas_transacoes = transacoes,
        };
    }
};
