import SwiftUI
import PictoCore

/// Square crop: pinch to zoom, drag to move. The white square is the pictogram.
struct CropView: View {
    let image: UIImage
    let onDone: (UIImage) -> Void
    let onCancel: () -> Void

    @State private var zoom: CGFloat = 1
    @State private var baseZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseOffset: CGSize = .zero
    @State private var side: CGFloat = 300

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let square = max(100, min(geometry.size.width, geometry.size.height) - 40)
                let scale = CropMath.baseScale(imageSize: image.size, side: square) * zoom

                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .frame(width: image.size.width * scale, height: image.size.height * scale)
                        .offset(offset)
                        .frame(width: square, height: square)
                        .clipped()
                        .overlay(Rectangle().stroke(Color.white, lineWidth: 2))
                        .contentShape(Rectangle())
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        zoom = min(max(baseZoom * value, CropMath.zoomRange.lowerBound), CropMath.zoomRange.upperBound)
                                        offset = CropMath.clampedOffset(offset, imageSize: image.size, side: square, zoom: zoom)
                                    }
                                    .onEnded { _ in
                                        baseZoom = zoom
                                        baseOffset = offset
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        let proposed = CGSize(
                                            width: baseOffset.width + value.translation.width,
                                            height: baseOffset.height + value.translation.height
                                        )
                                        offset = CropMath.clampedOffset(proposed, imageSize: image.size, side: square, zoom: zoom)
                                    }
                                    .onEnded { _ in
                                        baseOffset = offset
                                    }
                            )
                        )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear { side = square }
                .onChange(of: square) { _, newValue in
                    side = newValue
                    offset = CropMath.clampedOffset(offset, imageSize: image.size, side: newValue, zoom: zoom)
                    baseOffset = offset
                }
            }
            .navigationTitle("Recadrer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Utiliser") {
                        let rect = CropMath.cropRect(imageSize: image.size, side: side, zoom: zoom, offset: offset)
                        onDone(ImageTools.crop(image, to: rect))
                    }
                }
            }
        }
    }
}
