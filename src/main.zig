const std = @import("std");
const pg = @import("pg");
const httpz = @import("httpz");
const saldo = @import("models/saldo.zig");
const transacao = @import("models/transacao.zig");
const extrato = @import("models/extrato.zig");

const Global = struct {
    pool: *pg.Pool,
    alloc: std.mem.Allocator,
};

fn post_transacao(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("POST /cliente/{0u}/transacoes", .{req.param("id").?});
    const id = try std.fmt.parseInt(i32, req.param("id").?, 10);

    var saldo_return: saldo.SaldoResponse = undefined;

    if (try req.json(transacao.TransacaoReq)) |t| {
        const create_saldo = saldo.Saldo.create_transacao(global.pool, id, t) catch {
            res.status = 422;
            res.body = "";
            return;
        };

        saldo_return = create_saldo;
    }

    try res.json(saldo_return, .{});
}

fn select_transacoes_by_cliente(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("GET /cliente/{0u}/transacoes", .{req.param("id").?});

    const id = try std.fmt.parseInt(i32, req.param("id").?, 10);

    const transacoes = try transacao.Transacao.find_transacoes_by_cliente(global.alloc, global.pool, id);

    try res.json(.{ .transacoes = transacoes }, .{});
}

fn get_extrato(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    std.log.info("GET /cliente/{0u}/extrato", .{req.param("id").?});
    const id = try std.fmt.parseInt(i32, req.param("id").?, 10);

    const extrato_res = try extrato.Extrato.get_extrato(global.alloc, global.pool, id);

    try res.json(extrato_res, .{});
}

fn notFound(_: *Global, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 404;

    res.body = "Not found";
}

fn errorHandler(_: *Global, req: *httpz.Request, res: *httpz.Response, err: anyerror) void {
    res.status = 500;
    res.body = "Internal Server Error";
    std.log.warn("httpz: Unhandled exception for request: {s}\nErr: {}", .{ req.url.raw, err });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var pool = try pg.Pool.init(allocator, .{ .size = 5, .connect = .{
        .port = 5432,
        .host = "192.168.2.101",
    }, .auth = .{
        .username = "rinha",
        .database = "rinha",
        .password = "rinha",
        .timeout = 10_000,
    } });

    defer pool.deinit();

    var global = Global{ .alloc = allocator, .pool = pool };

    const port = 9999;
    var server = try httpz.ServerCtx(*Global, *Global).init(allocator, .{ .port = port }, &global);
    server.notFound(notFound);
    server.errorHandler(errorHandler);

    var router = server.router();

    // use get/post/put/head/patch/options/delete
    // you can also use "all" to attach to all methods
    router.post("/clientes/:id/transacoes", post_transacao);
    router.get("/clientes/:id/extrato", get_extrato);

    // start the server in the current thread, blocking.
    std.debug.print("Staring Server at Port: {}\n", .{port});
    try server.listen();
}
