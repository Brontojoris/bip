import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {

    // MARK: - Complication Descriptors
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(
                identifier: "BipComplication",
                displayName: "Bip",
                supportedFamilies: [
                    .modularSmall,
                    .modularLarge,
                    .utilitarianSmall,
                    .utilitarianLarge,
                    .circularSmall,
                    .extraLarge,
                    .graphicCorner,
                    .graphicCircular,
                    .graphicRectangular,
                    .graphicBezel,
                    .graphicExtraLarge
                ]
            )
        ]
        handler(descriptors)
    }

    // MARK: - Current Timeline Entry
    func getCurrentTimelineEntry(for complication: CLKComplication,
                                  withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let state = loadCurrentState()
        let template = makeTemplate(for: complication.family, state: state)
        let entry = template.map { CLKComplicationTimelineEntry(date: Date(), complicationTemplate: $0) }
        handler(entry)
    }

    // MARK: - Timeline entries
    func getTimelineEntries(for complication: CLKComplication, after date: Date,
                             limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        handler(nil)
    }

    // MARK: - Privacy
    func getPrivacyBehavior(for complication: CLKComplication,
                             withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }

    // MARK: - Template Builder
    private func makeTemplate(for family: CLKComplicationFamily, state: BipSessionState?) -> CLKComplicationTemplate? {
        let phaseText = state?.currentPhaseLabel ?? "Bip"
        let timeText = state.map { timeString($0.timeRemaining) } ?? "--:--"

        switch family {
        case .modularLarge:
            return CLKComplicationTemplateModularLargeStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Bip"),
                body1TextProvider: CLKSimpleTextProvider(text: phaseText),
                body2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .utilitarianLarge:
            return CLKComplicationTemplateUtilitarianLargeFlat(
                textProvider: CLKSimpleTextProvider(text: "\(phaseText) \(timeText)")
            )

        case .graphicRectangular:
            return CLKComplicationTemplateGraphicRectangularStandardBody(
                headerTextProvider: CLKSimpleTextProvider(text: "Bip"),
                body1TextProvider: CLKSimpleTextProvider(text: phaseText),
                body2TextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .graphicCorner:
            return CLKComplicationTemplateGraphicCornerStackText(
                innerTextProvider: CLKSimpleTextProvider(text: phaseText),
                outerTextProvider: CLKSimpleTextProvider(text: timeText)
            )

        case .circularSmall, .modularSmall:
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: timeText)
            )

        default:
            return CLKComplicationTemplateModularSmallSimpleText(
                textProvider: CLKSimpleTextProvider(text: timeText)
            )
        }
    }

    // MARK: - Helpers
    private func loadCurrentState() -> BipSessionState? {
        guard let defaults = UserDefaults(suiteName: APP_GROUP_ID),
              let data = defaults.data(forKey: "currentSessionState"),
              let state = try? JSONDecoder().decode(BipSessionState.self, from: data),
              state.isRunning else { return nil }
        return state
    }

    private func timeString(_ t: TimeInterval) -> String {
        let m = Int(max(0, t)) / 60
        let s = Int(max(0, t)) % 60
        return String(format: "%d:%02d", m, s)
    }
}
