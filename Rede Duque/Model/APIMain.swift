import Foundation

// MARK: - APIMain
struct APIMain: Codable {
    let estilosApp: EstilosApp
    let navegacao: Navegacao
    let intro: Intro
    let app: Apps
    let recuperacaoSenha, validaDados: RecuperacaoSenha
    let novoMenu: NovoMenu

    enum CodingKeys: String, CodingKey {
        case estilosApp = "EstilosApp"
        case navegacao, intro, app, recuperacaoSenha, validaDados, novoMenu
    }
}

// MARK: - Apps
struct Apps: Codable {
    let pagina, parent, tituloPagina: String
    let desLogo: String
    let corBotao, corBotaoon: String
    let links: AppLinks

    enum CodingKeys: String, CodingKey {
        case pagina, parent, tituloPagina
        case desLogo = "DES_LOGO"
        case corBotao = "COR_BOTAO"
        case corBotaoon = "COR_BOTAOON"
        case links
    }
}

// MARK: - AppLinks
struct AppLinks: Codable {
    let cadastreSE, esqueciMinhaSenha: String

    enum CodingKeys: String, CodingKey {
        case cadastreSE = "CADASTRE_SE"
        case esqueciMinhaSenha = "Esqueci_minha_senha"
    }
}

// MARK: - EstilosApp
struct EstilosApp: Codable {
    let desLogo: String
    let desImgback, corBackbar, corBackpag, corTitulos: String
    let corTextos, corBotao, corBotaoon, corFullpag: String
    let corTextfull: String

    enum CodingKeys: String, CodingKey {
        case desLogo = "DES_LOGO"
        case desImgback = "DES_IMGBACK"
        case corBackbar = "COR_BACKBAR"
        case corBackpag = "COR_BACKPAG"
        case corTitulos = "COR_TITULOS"
        case corTextos = "COR_TEXTOS"
        case corBotao = "COR_BOTAO"
        case corBotaoon = "COR_BOTAOON"
        case corFullpag = "COR_FULLPAG"
        case corTextfull = "COR_TEXTFULL"
    }
}

// MARK: - Intro
struct Intro: Codable {
    let pagina, background: String
    let logotipo: String
    let corbotao, corbotaoOn, textoContraste: String
    let backgroundImg: String
    let links: IntroLinks

    enum CodingKeys: String, CodingKey {
        case pagina, background, logotipo, corbotao, corbotaoOn, textoContraste
        case backgroundImg = "background_img"
        case links
    }
}

// MARK: - IntroLinks
struct IntroLinks: Codable {
    let cadastreSE, faleConosco, sejaNossoParceiro: String

    enum CodingKeys: String, CodingKey {
        case cadastreSE = "CADASTRE_SE"
        case faleConosco = "FALE_CONOSCO"
        case sejaNossoParceiro = "SEJA_NOSSO_PARCEIRO"
    }
}

// MARK: - Navegacao
struct Navegacao: Codable {
    let desLogo: String
    let corBackbar, textoContraste: String
    let links: NavegacaoLinks

    enum CodingKeys: String, CodingKey {
        case desLogo = "DES_LOGO"
        case corBackbar = "COR_BACKBAR"
        case textoContraste, links
    }
}

// MARK: - NavegacaoLinks
struct NavegacaoLinks: Codable {
    let intro, novoMenu: String

    enum CodingKeys: String, CodingKey {
        case intro = "INTRO"
        case novoMenu
    }
}

// MARK: - NovoMenu
struct NovoMenu: Codable {
    let pagina, parent: String
    let desLogo: String
    let tituloPagina, colunasDuplas: String
    let links: NovoMenuLinks
    let menu: Menu

    enum CodingKeys: String, CodingKey {
        case pagina, parent
        case desLogo = "DES_LOGO"
        case tituloPagina, colunasDuplas, links, menu
    }
}

// MARK: - NovoMenuLinks
struct NovoMenuLinks: Codable {
    let validacaoDados, ofertas, jornal, minhasCompras: String
    let meusDados, mensagens, premios, parceiros: String
    let faleConosco, logout, cashback, historico: String
    let enderecos, enderecosDuque: String

    enum CodingKeys: String, CodingKey {
        case validacaoDados = "validacao_dados"
        case ofertas, jornal
        case minhasCompras = "minhas_compras"
        case meusDados = "meus_dados"
        case mensagens, premios, parceiros
        case faleConosco = "fale_conosco"
        case logout, cashback, historico, enderecos
        case enderecosDuque = "enderecos_duque"
    }
}

// MARK: - Menu
struct Menu: Codable {
    let logColunas, logOfertas, logJornal, logHabito: String
    let logDados, logExtrato, logPremios, logEnderecos: String
    let logParceiros, logComunica, logMensagem, logBannerhome: String
    let logBannerlista, logToken, logVeiculo: String

    enum CodingKeys: String, CodingKey {
        case logColunas = "LOG_COLUNAS"
        case logOfertas = "LOG_OFERTAS"
        case logJornal = "LOG_JORNAL"
        case logHabito = "LOG_HABITO"
        case logDados = "LOG_DADOS"
        case logExtrato = "LOG_EXTRATO"
        case logPremios = "LOG_PREMIOS"
        case logEnderecos = "LOG_ENDERECOS"
        case logParceiros = "LOG_PARCEIROS"
        case logComunica = "LOG_COMUNICA"
        case logMensagem = "LOG_MENSAGEM"
        case logBannerhome = "LOG_BANNERHOME"
        case logBannerlista = "LOG_BANNERLISTA"
        case logToken = "LOG_TOKEN"
        case logVeiculo = "LOG_VEICULO"
    }
}

// MARK: - RecuperacaoSenha
struct RecuperacaoSenha: Codable {
    let pagina, parent, tituloPagina: String
    let desLogo: String
    let links: RecuperacaoSenhaLinks?

    enum CodingKeys: String, CodingKey {
        case pagina, parent, tituloPagina
        case desLogo = "DES_LOGO"
        case links
    }
}

// MARK: - RecuperacaoSenhaLinks
struct RecuperacaoSenhaLinks: Codable {
    let validacaoToken, validacaoDados: String

    enum CodingKeys: String, CodingKey {
        case validacaoToken = "validacao_token"
        case validacaoDados = "validacao_dados"
    }
}
