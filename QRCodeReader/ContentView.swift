//
//  ContentView.swift
//  QRCodeReader
//
//  Created by 宮本光直 on 2022/01/06.
//

import SwiftUI

struct ContentView: View {
    
    @State var canScan = true
    @State var isShowAlert: ScanAlert? = nil
    
    var body: some View {
        ZStack {
            QRReader(
                canScan: $canScan,
                completion: { result in
                    switch result {
                    case .success(let code):
                        isShowAlert = ScanAlert(result: .success(message: code))
                        print(":::: code: \(code.debugDescription)")
                    case .failure(let error):
                        isShowAlert = ScanAlert(result: .failure)
                        print(":::: error: \(error)")
                    }
                }
            )
            .ignoresSafeArea(.all)
        }
        .alert(item: $isShowAlert) {
            switch $0.result {
            case .success(let message):
                return Alert(title: Text("scan success!!!"),
                             message: Text("\(message)"),
                             dismissButton: .default(Text("close"), action: {
                                canScan = true
                             }))
            case .failure:
                return Alert(title: Text("scan failure!!!"),
                             dismissButton: .default(Text("close"), action: {
                                canScan = true
                             }))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
