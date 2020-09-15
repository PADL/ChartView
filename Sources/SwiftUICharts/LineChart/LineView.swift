//
//  LineView.swift
//  LineChart
//
//  Created by András Samu on 2019. 09. 02..
//  Copyright © 2019. András Samu. All rights reserved.
//

import SwiftUI

public struct LineView: View {
    @ObservedObject var data: ChartData
    public var title: String?
    public var legend: String?
    public var style: ChartStyle
    public var darkModeStyle: ChartStyle
    public var valueSpecifier:String
    public var increments: Int

    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State private var showLegend = false
    @State private var dragLocation:CGPoint = .zero
    @State private var indicatorLocation:CGPoint = .zero
    @State private var closestPoint: CGPoint = .zero
    @State private var opacity:Double = 0
    @State private var currentDataNumber: Double = 0
    @State private var currentDataLabel: String = ""
    @State private var hideHorizontalLines: Bool = false
    private var currentDataIndex: Binding<Int>? = nil
    private var currentIndicatorColor: Binding<Color>? = nil
    
    public init(data: ChartData,
                title: String? = nil,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                valueSpecifier: String? = "%.1f",
                increments: Int = 4,
                currentDataIndex: Binding<Int>? = nil,
                currentIndicatorColor: Binding<Color>? = nil) {
        self.data = data
        self.title = title
        self.legend = legend
        self.style = style
        self.valueSpecifier = valueSpecifier!
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.increments = increments
        self.currentDataIndex = currentDataIndex
        self.currentIndicatorColor = currentIndicatorColor
    }
    
    public init(data: [Double],
                title: String? = nil,
                legend: String? = nil,
                style: ChartStyle = Styles.lineChartStyleOne,
                valueSpecifier: String? = "%.1f",
                increments: Int = 4,
                currentDataIndex: Binding<Int>? = nil,
                currentIndicatorColor: Binding<Color>? = nil) {
        self.data = ChartData(points: data)
        self.title = title
        self.legend = legend
        self.style = style
        self.valueSpecifier = valueSpecifier!
        self.darkModeStyle = style.darkModeStyle != nil ? style.darkModeStyle! : Styles.lineViewDarkMode
        self.increments = increments
        self.currentDataIndex = currentDataIndex
        self.currentIndicatorColor = currentIndicatorColor
    }
    
    public var body: some View {
        GeometryReader{ geometry in
            VStack(alignment: .leading, spacing: 5) {
                Group{
                    if (self.title != nil){
                        Text(self.title!)
                            .font(.title)
                            .bold().foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.textColor : self.style.textColor)
                    }
                    if (self.legend != nil){
                        Text(self.legend!)
                            .font(.callout)
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.legendTextColor : self.style.legendTextColor)
                    }
                }.offset(x: 0, y: 0)
                ZStack{
                    GeometryReader{ reader in
                        Rectangle()
                            .foregroundColor(self.colorScheme == .dark ? self.darkModeStyle.backgroundColor : self.style.backgroundColor)
                        ZStack {
                            if self.showLegend {
                                Legend(data: self.data,
                                       frame: .constant(reader.frame(in: .local)), hideHorizontalLines: self.$hideHorizontalLines,
                                       valueSpecifier: .constant(valueSpecifier),
                                       increments: .constant(increments))
                                    .transition(.opacity)
                                    .animation(Animation.easeOut(duration: 1).delay(1))
                            }
                            Line(data: self.data,
                                 frame: .constant(CGRect(x: 0, y: 0, width: reader.frame(in: .local).width - 30, height: reader.frame(in: .local).height)),
                                 touchLocation: self.$indicatorLocation,
                                 showIndicator: self.$hideHorizontalLines,
                                 indicatorColor: self.currentIndicatorColor == nil ? .constant(Colors.IndicatorKnob) : currentIndicatorColor!,
                                 showBackground: false,
                                 gradient: self.style.gradientColor)
                                .offset(x: 30, y: 0)
                        .onAppear(){
                            self.showLegend = true
                        }
                        .onDisappear(){
                            self.showLegend = false
                        }
                        }
                    }
                    .frame(width: geometry.frame(in: .local).size.width, height: 240)
                    .offset(x: 0, y: 30 )
                    if self.style.magnifierRect {
                        MagnifierRect(currentNumber: self.$currentDataNumber,
                                      valueSpecifier: self.valueSpecifier)
                            .opacity(self.opacity)
                            .offset(x: self.dragLocation.x - geometry.frame(in: .local).size.width/2, y: 36)
                    }
                }
                .frame(width: geometry.frame(in: .local).size.width, height: 240)
                .gesture(DragGesture()
                .onChanged({ value in
                    self.dragLocation = value.location
                    self.indicatorLocation = CGPoint(x: max(value.location.x-30,0), y: 32)
                    self.opacity = 1
                    self.closestPoint = self.getClosestDataPoint(toPoint: value.location, width: geometry.frame(in: .local).size.width-30, height: 240)
                    self.hideHorizontalLines = true
                })
                    .onEnded({ value in
                        self.opacity = 0
                        self.hideHorizontalLines = false
                        if let currentDataIndex = self.currentDataIndex {
                            currentDataIndex.wrappedValue = -1
                        }
                    })
                )
                if self.hideHorizontalLines && !currentDataLabel.isEmpty {
                    Text(currentDataLabel)
                        .multilineTextAlignment(.leading)
                        .font(.footnote)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity,
                               maxHeight: geometry.frame(in: .local).size.height - 330,
                               alignment: .topLeading)
                        .offset(x: 0, y: 40)
                }
            }
        }
    }
    
    func getClosestDataPoint(toPoint: CGPoint, width:CGFloat, height: CGFloat) -> CGPoint {
        let points = self.data.onlyPoints()
        let labels = self.data.points.map { $0.0 }
        let stepWidth: CGFloat = width / CGFloat(points.count-1)
        let stepHeight: CGFloat = height / CGFloat(data.scaleMin + data.scaleMax)
        
        let index:Int = Int(floor((toPoint.x-15)/stepWidth))
        if (index >= 0 && index < points.count){
            self.currentDataNumber = points[index]
            self.currentDataLabel = labels[index]
            if let currentDataIndex = self.currentDataIndex {
                currentDataIndex.wrappedValue = index
            }
            return CGPoint(x: CGFloat(index)*stepWidth, y: CGFloat(points[index])*stepHeight)
        }
        return .zero
    }    
}

struct LineView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LineView(data: [8,23,54,32,12,37,7,23,43], title: "Full chart", legend: "Legend", style: Styles.lineChartStyleOne)

            let chartData = ChartData(points: [275.00, 282.502, 284.495, 283.51, 285.019, 285.197, 286.118, 288.737, 288.455, 289.391, 287.691, 285.878, 286.46, 286.252, 285.000, 284.129, 300],
                                      scale: (min: 250.0, max: 300.0))
            let style = Styles.lineChartStyleTwo
            LineView(data: chartData, title: "Custom scale", legend: "Legend", style: style,
                     valueSpecifier: "%.0f",
                     increments: 10)
            
            let chartDataFlat = ChartData(points: [0.0, 0.0, 0.5, 0.5, 0.5, 0.5, 1.0, 1.0, 1.0, 1.0])
            LineView(data: chartDataFlat, legend: "Legend only", style: style,
                     valueSpecifier: "%.02f",
                     increments: 4)

        }
    }
}
