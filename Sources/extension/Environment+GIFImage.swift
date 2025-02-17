//
//  File.swift
//  
//
//  Created by Igor Ferreira on 05/04/2022.
//

import SwiftUI

struct GIFImageEnvironment: EnvironmentKey {
    static var defaultValue: ImageLoader = {
        return ImageLoader()
    }()
}

public extension EnvironmentValues {
    var imageLoader: ImageLoader {
        get { self[GIFImageEnvironment.self] }
        set { self[GIFImageEnvironment.self] = newValue }
    }
}
