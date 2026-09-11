import Foundation

/// Modelos que espelham o JSON retornado por GET /srorastro/v1/objetos/{codigo}.
struct MCRastroResponse: Decodable {
    let objetos: [MCRastroObjeto]
}

struct MCRastroObjeto: Decodable {
    let codObjeto: String
    let eventos: [MCRastroEvento]
}

struct MCRastroEvento: Decodable {
    let codigo: String
    let dtHrCriado: String
    let descricao: String
    let unidade: MCRastroUnidade?
}

struct MCRastroUnidade: Decodable {
    let endereco: MCRastroEndereco?
}

struct MCRastroEndereco: Decodable {
    let uf: String?
    let cidade: String?
}
