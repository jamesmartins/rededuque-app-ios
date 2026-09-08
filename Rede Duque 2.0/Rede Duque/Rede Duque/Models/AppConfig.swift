import Foundation

struct AppConfigResponse: Codable {
    let novoMenu: NovoMenuConfig?
}

struct NovoMenuConfig: Codable {
    let pagina: String?
    let tituloPagina: String?
    let links: [String: String]?
}
