//
//  TagSelectionView.swift
//  Pawse
//
//  Reusable tag selection component for preferences
//

import SwiftUI

struct TagSelectionView: View {
    // Binding to the selected tags
    @Binding var selectedTags: Set<String>
    
    // Available options to choose from - default to all 12 tags
    var options: [String] = ["cat lover", "dog lover", "no-insects", "small-pets", "bird lover", "reptile lover", "aquatic pets", "farm animals", "exotic pets", "outdoor pets", "indoor pets", "multi-pet"]
    
    // Optional customization
    var isScrollable: Bool = false
    var maxHeight: CGFloat? = nil
    var selectedColor: Color = .pawseOrange
    var unselectedBackgroundColor: Color = Color(hex: "FAF7EB")
    var unselectedTextColor: Color = .pawseBrown
    
    var body: some View {
        Group {
            if isScrollable {
                ScrollView {
                    tagGrid
                        .padding(.top, 4)
                        .padding(.bottom, 12)
                }
                .frame(maxHeight: maxHeight)
            } else {
                tagGrid
            }
        }
    }
    
    private var tagGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    if selectedTags.contains(option) {
                        selectedTags.remove(option)
                    } else {
                        selectedTags.insert(option)
                    }
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selectedTags.contains(option) ? .white : unselectedTextColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(selectedTags.contains(option) ? selectedColor : unselectedBackgroundColor)
                        .cornerRadius(20)
                }
            }
        }
    }
}

// Preview
#Preview {
    @Previewable @State var selectedTags: Set<String> = ["cat lover"]
    
    VStack {
        Text("Select your preferences:")
            .font(.headline)
        
        TagSelectionView(
            selectedTags: $selectedTags,
            options: ["cat lover", "dog lover", "no-insects", "small-pets", "bird lover", "reptile lover"]
        )
        
        Text("Selected: \(selectedTags.sorted().joined(separator: ", "))")
            .font(.caption)
            .padding()
    }
    .padding()
}
