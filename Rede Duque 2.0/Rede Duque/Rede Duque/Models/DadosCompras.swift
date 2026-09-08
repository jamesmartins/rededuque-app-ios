import Foundation

// MARK: - DadosComprasResponse
struct DadosComprasResponse: Codable {
    let msgerro: String
    let coderro: Int
    let cliente: DadosComprasCliente?
    let saldo: DadosComprasSaldo?
    let compras: [DadosComprasMovimento]?
    let paginacao: DadosComprasPaginacao?
}

struct DadosComprasCliente: Codable {
    let codigoCliente: Int
    let nome: String
    let primeiroNome: String?
    let numCgcecpf: String
    let cartao: String?
    let email: String?
    let celular: String?
    let ativo: Bool?

    enum CodingKeys: String, CodingKey {
        case codigoCliente = "codigo_cliente"
        case nome
        case primeiroNome = "primeiro_nome"
        case numCgcecpf = "num_cgcecpf"
        case cartao, email, celular, ativo
    }
}

struct DadosComprasSaldo: Codable {
    let tipoRetorno: Int
    let tipoCampanha: Int
    let unidade: String
    let casasDecimais: Int
    let disponivel: Double
    let resgatado: Double
    let expirado: Double
    let ganho: Double
    let aLiberar: Double
    let bloqueado: Double

    enum CodingKeys: String, CodingKey {
        case tipoRetorno = "tipo_retorno"
        case tipoCampanha = "tipo_campanha"
        case unidade
        case casasDecimais = "casas_decimais"
        case disponivel, resgatado, expirado, ganho
        case aLiberar = "a_liberar"
        case bloqueado
    }
}

struct DadosComprasMovimento: Codable, Identifiable {
    let codigoMovimento: Int
    let tipoMovimento: String
    let lancamento: String
    let ocorrencia: String
    let unidade: String
    let formaPagamento: String
    let codigoStatusCredito: Int
    let status: String
    let dataMovimento: String
    let dataMovimentoBr: String
    let dataExpiracao: String?
    let dataExpiracaoBr: String?
    let codigoVendaPdv: String?
    let parametro2: String?
    let possuiItemExcluido: Bool
    let tipoSaldo: String
    let valores: DadosComprasValores

    var id: Int { codigoMovimento }

    enum CodingKeys: String, CodingKey {
        case codigoMovimento = "codigo_movimento"
        case tipoMovimento = "tipo_movimento"
        case lancamento, ocorrencia, unidade
        case formaPagamento = "forma_pagamento"
        case codigoStatusCredito = "codigo_status_credito"
        case status
        case dataMovimento = "data_movimento"
        case dataMovimentoBr = "data_movimento_br"
        case dataExpiracao = "data_expiracao"
        case dataExpiracaoBr = "data_expiracao_br"
        case codigoVendaPdv = "codigo_venda_pdv"
        case parametro2 = "parametro_2"
        case possuiItemExcluido = "possui_item_excluido"
        case tipoSaldo = "tipo_saldo"
        case valores
    }
}

struct DadosComprasValores: Codable {
    let totalProdutos: Double
    let desconto: Double
    let venda: Double
    let cashbackOuPontos: Double
    let creditoExtra: Double
    let resgate: Double

    enum CodingKeys: String, CodingKey {
        case totalProdutos = "total_produtos"
        case desconto, venda
        case cashbackOuPontos = "cashback_ou_pontos"
        case creditoExtra = "credito_extra"
        case resgate
    }
}

struct DadosComprasPaginacao: Codable {
    let paginaAtual: Int
    let porPagina: Int
    let totalRegistros: Int
    let totalPaginas: Int
    let temAnterior: Bool
    let temProxima: Bool

    enum CodingKeys: String, CodingKey {
        case paginaAtual = "pagina_atual"
        case porPagina = "por_pagina"
        case totalRegistros = "total_registros"
        case totalPaginas = "total_paginas"
        case temAnterior = "tem_anterior"
        case temProxima = "tem_proxima"
    }
}
