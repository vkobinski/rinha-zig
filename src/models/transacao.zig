const pg = @import("pg");
const std = @import("std");

const TipoTransacaoError = error{
    ParseError,
};

pub const TipoTransacao = enum { c, d };

pub const TransacaoReq = struct {
    valor: i32,
    tipo: []u8,
    descricao: []u8,
};

pub const Transacao = struct {
    valor: i32,
    tipo: TipoTransacao,
    descricao: []u8,
    realizada_em: i64,

    pub fn init(row: pg.Row) !Transacao {
        const desc = row.get([]u8, 3);
        const len = desc.len;
        const s_desc = desc[0..len];

        return Transacao{
            .valor = row.get(i32, 1),
            .tipo = try parseTransacaoByRow(row, 2),
            .descricao = s_desc,
            .realizada_em = row.get(i64, 4),
        };
    }

    pub fn find_transacoes_by_cliente(alloc: std.mem.Allocator, pool: *pg.Pool, cliente_id: i32) ![]Transacao {
        var result = try pool.query(
            \\SELECT transacao_id, valor, tipo, descricao, realizada_em
            \\FROM transacao
            \\WHERE cliente_id = $1
            \\ORDER BY realizada_em DESC
            \\LIMIT 10
            \\FOR UPDATE
        , .{cliente_id});

        defer result.deinit();

        var transacoes: []Transacao = try alloc.alloc(Transacao, 10);

        var i: usize = 0;

        while (try result.next()) |row| {
            const c_transacao = try init(row);
            transacoes[i] = c_transacao;

            i += 1;
        }

        return transacoes[0..i];
    }

    pub fn parseTransacaoByRow(row: pg.Row, pos: usize) !TipoTransacao {
        const tipo = row.get([]const u8, pos);

        if (tipo[0] == 'd') return TipoTransacao.d;
        if (tipo[0] == 'c') return TipoTransacao.c;

        return TipoTransacaoError.ParseError;
    }

    pub fn parseTransacao(tipo: []u8) !TipoTransacao {
        if (tipo[0] == 'd') return TipoTransacao.d;
        if (tipo[0] == 'c') return TipoTransacao.c;

        return TipoTransacaoError.ParseError;
    }
};
