//
//  Line.swift
//  LineChart
//
//  Created by András Samu on 2019. 08. 30..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct Line: View {
    @ObservedObject var data: ChartData
    @Binding var frame: CGRect
    @Binding var touchLocation: CGPoint
    @Binding var showIndicator: Bool
    @Binding var indicatorColor: Color
    @State private var showFull: Bool = false
    @State var showBackground: Bool = true
    var gradient: GradientColoring
    
    var index:Int = 0
    let padding:CGFloat = 0
    var curvedLines: Bool = true
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
    var path: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: data.scaleMin) : Path.linePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: data.scaleMin)
    }
    var closedPath: Path {
        let points = self.data.onlyPoints()
        return curvedLines ? Path.quadClosedCurvedPathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: data.scaleMin) : Path.closedLinePathWithPoints(points: points, step: CGPoint(x: stepWidth, y: stepHeight), globalOffset: data.scaleMin)
    }
    
    public var body: some View {
        let pathGradient = gradient.getGradient()
        
        ZStack {
            if(self.showFull && self.showBackground){
                self.closedPath
                    .fill(LinearGradient(gradient: Gradient(colors: [Colors.GradientUpperBlue, .white]), startPoint: .bottom, endPoint: .top))
                    .rotationEffect(.degrees(180), anchor: .center)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .transition(.opacity)
                    .animation(.easeIn(duration: 1.6))
            }
            self.path
                .trim(from: 0, to: self.showFull ? 1:0)
                .stroke(LinearGradient(gradient: pathGradient, startPoint: .leading, endPoint: .trailing), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                .rotationEffect(.degrees(180), anchor: .center)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .animation(Animation.easeOut(duration: 1.2).delay(Double(self.index)*0.4))
                .onAppear {
                    self.showFull = true
            }
            .onDisappear {
                self.showFull = false
            }
            .drawingGroup()
            // XXX this seems to cause it to undraw itself
            //.id(pathGradient.stops.map { $0.color })
            if self.showIndicator && getClosestPointOnPath(touchLocation: self.touchLocation).y > 0 {
                IndicatorPoint(color: indicatorColor)
                    .position(self.getClosestPointOnPath(touchLocation: self.touchLocation))
                    .rotationEffect(.degrees(180), anchor: .center)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
    }
    
    func getClosestPointOnPath(touchLocation: CGPoint) -> CGPoint {
        let closest = self.path.point(to: touchLocation.x)
        return closest
    }
}

struct Line_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReader{ geometry in
            Line(data: ChartData(points: [12,-230,10,54]),
                 frame: .constant(geometry.frame(in: .local)),
                 touchLocation: .constant(CGPoint(x: 100, y: 12)),
                 showIndicator: .constant(true),
                 indicatorColor: .constant(Colors.IndicatorKnob),
                 gradient: GradientColor(start: Colors.GradientPurple,
                                                   end: Colors.GradientNeonBlue))
        }.frame(width: 320, height: 160)
    }
}
