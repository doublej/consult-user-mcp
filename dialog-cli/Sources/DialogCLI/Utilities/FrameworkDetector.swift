import Foundation

enum DetectedFramework: String, CaseIterable {
    case svelte = "Svelte"
    case react = "React"
    case vue = "Vue"
    case css = "CSS"
    case vanilla = "Vanilla"

    var hmrPattern: String {
        switch self {
        case .svelte:
            return """
            // HMR animation replay (Svelte 5)
            let animationKey = $state(0);
            if (import.meta.hot) {
                const thisModule = import.meta.url;
                import.meta.hot.on('vite:beforeUpdate', (payload) => {
                    if (payload.updates.some((u) => thisModule.endsWith(u.acceptedPath))) {
                        animationKey++;
                    }
                });
            }
            """
        case .react:
            return """
            // HMR animation replay (React)
            const [animationKey, setAnimationKey] = useState(0);
            useEffect(() => {
                if (import.meta.hot) {
                    import.meta.hot.accept(() => setAnimationKey(k => k + 1));
                }
            }, []);
            """
        case .vue:
            return """
            // HMR animation replay (Vue 3)
            const animationKey = ref(0);
            if (import.meta.hot) {
                const thisModule = import.meta.url;
                import.meta.hot.on('vite:beforeUpdate', (payload) => {
                    if (payload.updates.some((u) => thisModule.endsWith(u.acceptedPath))) {
                        animationKey.value++;
                    }
                });
            }
            """
        case .css, .vanilla:
            return ""
        }
    }
}

struct FrameworkDetector {
    /// Detect framework from a list of file paths
    static func detect(from files: [String]) -> DetectedFramework? {
        let extensions = Set(files.compactMap { URL(fileURLWithPath: $0).pathExtension.lowercased() })

        // Priority order: specific frameworks first, then generic
        if extensions.contains("svelte") { return .svelte }
        if extensions.contains("vue") { return .vue }
        if extensions.contains("tsx") || extensions.contains("jsx") { return .react }
        if extensions.contains("css") || extensions.contains("scss") || extensions.contains("sass") {
            // Pure CSS files without component files
            let hasComponents = extensions.contains("ts") || extensions.contains("js")
            return hasComponents ? .vanilla : .css
        }
        if extensions.contains("ts") || extensions.contains("js") { return .vanilla }

        return nil
    }

    /// Detect from tweak parameters
    static func detect(from parameters: [TweakParameter]) -> DetectedFramework? {
        detect(from: parameters.map(\.file))
    }
}
