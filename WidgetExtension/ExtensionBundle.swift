import SwiftUI
import WidgetKit

@main
struct ExtensionBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        #if canImport(AppIntents)
        if #available(iOS 18.0, *) {
            ServiceToggleControl()
        }
        #endif
    }
}
