//
//  SecondView.swift
//  JumpBar
//
//  Created by oanhof on 22.04.22.
//

import SwiftUI

struct SecondView: View {
    @State
    private var isView1Active = false
    
    @State
    private var isView2Active = false
    
    @State
    private var isView3Active = false
    
    var body: some View {
        List {
            NavigationLink("View 1", isActive: $isView1Active) {
                Text("View 1")
            }
            
            NavigationLink("View 2", isActive: $isView2Active) {
                Text("View 2")
            }
        }
        .sheet(isPresented: $isView3Active) {
            Text("View 3")
        }
        .route(debugName: "SecondView") { info in
            guard info.pathComponents.count > 1,
                  info.pathComponents[0] == "view" else { return info }
            
            switch info.pathComponents[1] {
            case "1":
                isView1Active = true
            case "2":
                isView2Active = true
            case "3":
                isView3Active = true
            default:
                break
            }
            
            var info = info
            info.pathComponents.removeFirst(2)
            return info
        }
    }
}

struct SecondView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SecondView()
        }
    }
}
