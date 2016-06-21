//
//  main.swift
//  LazyJun
//
//  Created by tangjr on 6/21/16.
//  Copyright © 2016 saitjr. All rights reserved.
//

import AppKit

let fromPath = "/Users/tangjr/Desktop/中文"
let iconSizes: [CGSize] = [CGSize(width: 10, height: 10),
                           CGSize(width: 20, height: 20)]

generateSize(iconSizes)
    ==> run(fromPath)


rename(.SubSuffix, string: "@3x")
    >|< generate2x()
    >|< even()
    >|< rename(.AppendSuffix, string: "@2x")
    => run(fromPath)