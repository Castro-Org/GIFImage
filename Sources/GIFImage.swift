import SwiftUI

/// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
/// into frames and stream them based in the "Delay" key packaged on which frame item. The view will use the `ImageLoader` from the environment
/// to convert the fetch the `Data`
public struct GIFImage: View {
    public let source: GIFSource
    public let placeholder: RawImage
    public let errorImage: RawImage?
    private let presentationController: PresentationController
    private let width: CGFloat?
    private let height: CGFloat?
    private var imageTapped: (() -> Void)?
    private let contentMode: ContentMode

    @Environment(\.imageLoader) var imageLoader
    @State @MainActor private var frame: RawImage?
    @Binding public var loop: Bool
    @Binding public var animate: Bool
    @State private var presentationTask: Task<(), Never>?

    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - source: Source of the image. If the source is remote, the response is cached using `URLCache`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    public init(
        source: GIFSource,
        animate: Bool,
        loop: Bool,
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            source: source,
            animate: .constant(animate),
            loop: .constant(loop),
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - source: Source of the image. If the source is remote, the response is cached using `URLCache`
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    public init(
        source: GIFSource,
        animate: Binding<Bool> = Binding.constant(true),
        loop: Binding<Bool> = Binding.constant(true),
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        contentMode: ContentMode = .fit,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in },
        imageTapped: (() -> Void)? = nil
    ) {
        self.source = source
        self._animate = animate
        self._loop = loop
        self.placeholder = placeholder
        self.errorImage = errorImage
        self.width = width
        self.height = height
        self.imageTapped = imageTapped
        self.contentMode = contentMode
        
        self.presentationController = PresentationController(
            source: source,
            frameRate: frameRate,
            animate: animate,
            loop: loop,
            action: loopAction
        )
    }

    public var body: some View {
        ZStack {
            Image.loadImage(with: frame ?? placeholder)
                .resizable()
                .aspectRatio(contentMode: contentMode)
                .frame(maxHeight: height ?? nil)
                .scaleEffect(1.0001) // Needed because of SwiftUI sometimes incorrectly displaying landscape images.
                .clipped()
                .allowsHitTesting(false)
                .onChange(of: loop, perform: handle(loop:))
                .onChange(of: animate, perform: handle(animate:))
                .task(id: source, load)
            
            if let imageTapped {
                // NOTE: needed because of bug with SwiftUI.
                // The click area expands outside the image view (although not visible).
                Rectangle()
                    .opacity(0.000001)
                    .frame(width: width, height: height)
                    .clipped()
                    .allowsHitTesting(true)
                    .highPriorityGesture(
                        TapGesture()
                            .onEnded { _ in
                                imageTapped()
                            }
                    )
            }
        }
    }

    private func handle(animate: Bool) {
        if animate {
            load()
        } else {
            presentationTask?.cancel()
        }
    }
    
    private func handle(loop: Bool) {
        if loop { load() }
    }
    
    @Sendable private func load() {
        presentationTask?.cancel()
        presentationTask = Task { await presentationController.start(
            imageLoader: imageLoader,
            fallbackImage: errorImage ?? placeholder,
            frameUpdate: setFrame(_:)
        )}
    }
    
    @MainActor
    @Sendable private func setFrame(_ frame: RawImage) async {
        self.frame = frame
    }
}

struct GIFImage_Previews: PreviewProvider {
    static let gifURL = "https://raw.githubusercontent.com/igorcferreira/GIFImage/main/Tests/test.gif"
    static let placeholder = RawImage.create(symbol: "photo.circle.fill")!
    static let error = RawImage.create(symbol: "xmark.octagon")
    
    static var previews: some View {
        Group {
            GIFImage(url: gifURL, placeholder: placeholder, errorImage: error)
                .frame(height: 175.0, alignment: .center)
            GIFImage(url: gifURL, placeholder: placeholder, errorImage: error, frameRate: .limited(fps: 5))
                .frame(height: 175.0, alignment: .center)
            GIFImage(url: gifURL, placeholder: placeholder, errorImage: error, frameRate: .static(fps: 30))
                .frame(height: 175.0, alignment: .center)
        }
    }
}
