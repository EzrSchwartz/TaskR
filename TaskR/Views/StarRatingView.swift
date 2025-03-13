//
//  StarRatingView.swift
//  TaskR
//
//  Created by Ezra Schwartz on 3/14/25.
//

import SwiftUI



struct StarRatingView: View {
    let rating: Double  // Rating from 0 to 5
    let maxRating: Int
    let size: CGFloat
    let color: Color
    let onTap: ((Int) -> Void)?  // Optional callback when a star is tapped
    
    init(
        rating: Double,
        maxRating: Int = 5,
        size: CGFloat = 20,
        color: Color = .yellow,
        onTap: ((Int) -> Void)? = nil
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.size = size
        self.color = color
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: self.starType(for: star))
                    .font(.system(size: size))
                    .foregroundColor(color)
                    .onTapGesture {
                        if let onTap = onTap {
                            onTap(star)
                        }
                    }
            }
            
            if rating > 0 {
                Text(String(format: "%.1f", rating))
                    .font(.system(size: size * 0.8))
                    .foregroundColor(.gray)
                    .padding(.leading, 4)
            }
        }
    }
    
    private func starType(for position: Int) -> String {
        if Double(position) <= self.rating {
            return "star.fill"
        } else if Double(position) - 0.5 <= self.rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}
