import SwiftUI
import Cocoa

struct ProgressBarView: View {
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color(.systemTeal))
                
                Rectangle().frame(width:min(CGFloat(self.value / 100.0) * geometry.size.width, geometry.size.width), height: geometry.size.height).foregroundColor(Color(.systemBlue))
                    .animation(.linear)
            }
        }.cornerRadius(45.0)
    }
}

struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(value: Binding.constant(10.0))
    }
}
