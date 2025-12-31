import Foundation

struct WindowModel: Codable, Identifiable {
    var id: Int
    var app: String
    var title: String?
    var frame: CGRect?
}

struct SpaceModel: Codable, Identifiable {
    var id: Int
    var index: Int
    var label: String?
}













