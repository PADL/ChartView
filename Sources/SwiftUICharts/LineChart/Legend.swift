//
//  Legend.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 02..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

struct Legend: View {
    @ObservedObject var data: ChartData
    @Binding var frame: CGRect
    @Binding var hideHorizontalLines: Bool
    @Binding var valueSpecifier: String
    @Binding var increments: Int

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let padding:CGFloat = 0

    var stepWidth: CGFloat {
        if data.points.count < 2 {
            return 0
        }
        return frame.size.width / CGFloat(data.points.count-1)
    }
    
    var stepHeight: CGFloat {
        var divisor = self.data.scaleMax - self.data.scaleMin
        
        if divisor == 0 {
            return 0
        } else if self.data.scaleMin > self.data.scaleMax {
            divisor.negate()
        }
        
        return (frame.size.height - padding) / CGFloat(divisor)
    }

    var body: some View {
        ZStack(alignment: .topLeading){
            ForEach((0...increments), id: \.self) { height in
                HStack(alignment: .center){
                    Text("\(self.getYLegend(height: height), specifier: valueSpecifier)").offset(x: 0, y: self.getYposition(height: height) )
                        .foregroundColor(Colors.LegendText)
                        .font(.caption)
                    self.line(atHeight: self.getYLegend(height: height), width: self.frame.width)
                        .stroke(self.colorScheme == .dark ? Colors.LegendDarkColor : Colors.LegendColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5,height == 0 ? 0 : 10]))
                        .opacity((self.hideHorizontalLines && height != 0) ? 0 : 1)
                        .rotationEffect(.degrees(180), anchor: .center)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .animation(.easeOut(duration: 0.2))
                        .clipped()
                }
               
            }
            
        }
    }
    
    func getYLegend(height:Int)->CGFloat{
        return CGFloat(getYLegend()[height])
    }
    
    func getYposition(height: Int)-> CGFloat {
        let legend = getYLegend()
        return (self.frame.height-((CGFloat(legend[height] - self.data.scaleMin))*self.stepHeight))-(self.frame.height/2)
    }
    
    func line(atHeight: CGFloat, width: CGFloat) -> Path {
        var hLine = Path()
        hLine.move(to: CGPoint(x:5, y: (atHeight-CGFloat(self.data.scaleMin))*self.stepHeight))
        hLine.addLine(to: CGPoint(x: width, y: (atHeight-CGFloat(self.data.scaleMin))*self.stepHeight))
        return hLine
    }
    
    func getYLegend() -> [Double] {
        precondition(increments > 0)
        
        let step = (self.data.scaleMax - self.data.scaleMin) / Double(increments)
        var legend = [Double]()
        
        for i in 0 ... increments {
            legend.append(self.data.scaleMin + step * Double(i))
        }
        
        return legend
    }
}

struct Legend_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader{ geometry in
            Legend(data: ChartData(points: [0.2,0.4,1.4,4.5], scale: (min:0, max: 5)), frame: .constant(geometry.frame(in: .local)), hideHorizontalLines: .constant(false),
                   valueSpecifier: .constant("%.2f"),
                   increments: .constant(5))
        }.frame(width: 320, height: 200)
    }
}
