//
//  CassetteView.swift
//  PocketLog
//
//  Created by Kai Quan Tay on 22/11/26.
//

import SwiftUI

struct CassetteView: View {
    var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // background
            Color(white: 0.3)

            // screws
            let screw = Circle().fill(Color(white: 0.2))
                .frame(width: 16, height: 16)
                .overlay {
                    Rectangle().fill(Color(white: 0.1)).frame(width: 4)
                    Rectangle().fill(Color(white: 0.1)).frame(height: 4)
                }
            VStack {
                HStack {
                    screw
                    Spacer()
                    screw
                }
                Spacer()
                HStack {
                    screw
                    Spacer()
                    screw
                }
            }
            .padding(4)

            // main body
            VStack(spacing: 12) {
                VStack {
                    Spacer()
                        .frame(height: 40)

                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 4)

                    let tapeSpool = Circle()
                        .fill(Color(white: 0.7))
                        .background {
                            Circle()
                                .fill(Color(white: 0.1))
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(.white)
                                .frame(width: 80, height: 80)
                            Circle()
                                .fill(.red)
                                .frame(width: 80, height: 80)
                                .mask {
                                    Rectangle().frame(height: 20)
                                }
                        }
                        .overlay {
                            CircularTickers(count: 6, length: 8)
                                .stroke(Color.white, lineWidth: 6)
                            CircularTickers(count: 6, length: 7)
                                .stroke(Color.gray, lineWidth: 4)
                        }
                        .rotationEffect(.radians(phase))

                    // the dials
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.black)
                        .frame(height: 60)
                        .overlay {
                            HStack(spacing: 10) {
                                tapeSpool

                                Spacer()

                                tapeSpool
                            }
                            .background {
                                Color(white: 0.4)
                            }
                            .mask {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(.white)

                                    Rectangle()
                                        .fill(.white)

                                    Circle()
                                        .fill(.white)
                                }
                            }
                            .padding(10)
                        }
                        .padding(.horizontal, 50)
                        .padding(.vertical, 15)

                    Spacer()

                    Rectangle()
                        .fill(Color.green)
                        .frame(height: 10)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.890, green: 0.867, blue: 0.832))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black, lineWidth: 4)
                }

                Trapezium(deltaWidth: 10)
                    .stroke(Color.black, lineWidth: 4)
                    .frame(height: 55)
                    .padding(.horizontal, 40)
                    .padding(.bottom, -2)
            }
            .padding([.horizontal, .top], 24)
        }
        .frame(width: cassetteWidth, height: cassetteHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct CircularTickers: Shape {
    /// Number of tickers
    var count: Int
    /// Length of tickers
    var length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let outerRadius = min(rect.width, rect.height)/2
        let innerRadius = outerRadius - length
        let angleSegmentRad = CGFloat.pi * 2 / CGFloat(count)

        for index in 0..<count {
            let angle = angleSegmentRad * CGFloat(index)
            path.move(
                to: .init(
                    x: rect.midX + outerRadius * sin(angle),
                    y: rect.midY + outerRadius * cos(angle)
                )
            )
            path.addLine(
                to: .init(
                    x: rect.midX + innerRadius * sin(angle),
                    y: rect.midY + innerRadius * cos(angle)
                )
            )
        }

        return path
    }
}
