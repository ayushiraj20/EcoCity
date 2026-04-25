import SwiftUI

struct SpringyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

func getAQIColor(_ aqi: Double) -> Color {
    if aqi > 400 { return Color(red: 0.55, green: 0.0, blue: 0.0) }   // Severe — dark red
    if aqi > 300 { return .red }                                        // Very Poor — red
    if aqi > 200 { return .orange }                                     // Poor — orange
    if aqi > 100 { return .yellow }                                     // Moderate — yellow
    if aqi > 50  { return Color(red: 0.6, green: 0.8, blue: 0.2) }     // Satisfactory — yellow-green
    return .green                                                       // Good — green
}
