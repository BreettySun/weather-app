---
name: Vibrant Morning
colors:
  surface: "#f9f9fe"
  surface-dim: "#d9dade"
  surface-bright: "#f9f9fe"
  surface-container-lowest: "#ffffff"
  surface-container-low: "#f3f3f8"
  surface-container: "#ededf2"
  surface-container-high: "#e8e8ed"
  surface-container-highest: "#e2e2e7"
  on-surface: "#1a1c1f"
  on-surface-variant: "#57423b"
  inverse-surface: "#2e3034"
  inverse-on-surface: "#f0f0f5"
  outline: "#8b7169"
  outline-variant: "#dec0b6"
  surface-tint: "#a43c12"
  primary: "#a43c12"
  on-primary: "#ffffff"
  primary-container: "#ff7f50"
  on-primary-container: "#6c2000"
  inverse-primary: "#ffb59c"
  secondary: "#0060ac"
  on-secondary: "#ffffff"
  secondary-container: "#68abff"
  on-secondary-container: "#003e73"
  tertiary: "#705d00"
  on-tertiary: "#ffffff"
  tertiary-container: "#c0a200"
  on-tertiary-container: "#453900"
  error: "#ba1a1a"
  on-error: "#ffffff"
  error-container: "#ffdad6"
  on-error-container: "#93000a"
  primary-fixed: "#ffdbcf"
  primary-fixed-dim: "#ffb59c"
  on-primary-fixed: "#380c00"
  on-primary-fixed-variant: "#822800"
  secondary-fixed: "#d4e3ff"
  secondary-fixed-dim: "#a4c9ff"
  on-secondary-fixed: "#001c39"
  on-secondary-fixed-variant: "#004883"
  tertiary-fixed: "#ffe16d"
  tertiary-fixed-dim: "#e9c400"
  on-tertiary-fixed: "#221b00"
  on-tertiary-fixed-variant: "#544600"
  background: "#f9f9fe"
  on-background: "#1a1c1f"
  surface-variant: "#e2e2e7"
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: "800"
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-h1:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: "700"
    lineHeight: 38px
    letterSpacing: -0.01em
  headline-h2:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: "700"
    lineHeight: 30px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: "500"
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: "400"
    lineHeight: 24px
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: "700"
    lineHeight: 16px
    letterSpacing: 0.05em
  button:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: "600"
    lineHeight: 20px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 16px
  md: 24px
  lg: 32px
  xl: 48px
  safe-margin: 20px
---

## Brand & Style

The design system is built on the intersection of utility and warmth. It targets fashion-conscious individuals who value efficiency and style in their daily routines. The brand personality is optimistic, proactive, and "sunny," regardless of the actual weather forecast.

The aesthetic is **Modern Minimalist** with a strong **iOS-style** influence. It prioritizes clarity and whitespace to prevent information overload. By combining high-end typography with tactile, soft-edged components, the design system creates an interface that feels like a friendly personal stylist rather than a raw data utility.

## Colors

The palette is anchored by a vibrant Coral/Orange, which serves as the primary action color and brand signature. This color is used for call-to-actions, active states, and high-importance weather alerts.

- **Primary (#FF7F50):** Energy, warmth, and brand identity.
- **Secondary (#4A90E2):** A cool blue used sparingly for rain indicators or cold-weather accents to provide visual balance.
- **Background (#FFFFFF):** Pure white is mandatory to maintain a "clean slate" feel for the outfit photography.
- **Neutral (#F2F2F7):** An iOS-standard light grey used for secondary card backgrounds and grouping elements.
- **Text (#1C1C1E):** Deep off-black for optimal legibility.

## Typography

This design system utilizes **Plus Jakarta Sans** for its friendly, modern, and slightly rounded geometric proportions. It mimics the accessibility of SF Pro while offering a more distinctive, "bubbly" personality that matches the 20px+ corner radii.

Hierarchy is established through significant weight shifts (Bold for headlines, Medium for body). Display sizes are used for the current temperature to create a clear focal point.

## Layout & Spacing

The layout follows a **fluid grid** model optimized for mobile-first consumption. It uses a standard 12-column grid but relies heavily on safe-area margins of 20px to prevent components from feeling cramped against the screen edges.

Rhythm is maintained through 8px increments. Generous vertical spacing (32px+) is used between distinct sections (e.g., between "Today's Weather" and "Recommended Outfit") to ensure the minimal aesthetic remains breathable.

## Elevation & Depth

To maintain a minimal and clean appearance, depth is created through **Tonal Layers** rather than heavy shadows.

- **Level 0:** Pure white background.
- **Level 1:** Secondary Neutral (#F2F2F7) containers for grouped content (e.g., a forecast list).
- **Level 2:** Pure white cards with very soft, extra-diffused shadows (Opacity: 5%, Blur: 20px) to signify interactivity or the "Outfit of the Day."
- **Backdrop Blurs:** Used on the navigation bar and modal overlays to maintain the iOS-style glassmorphism effect.

## Shapes

The shape language is the core of this design system's "approachable" feel. All primary containers, buttons, and image cards must use a **minimum corner radius of 20px**.

Small elements like tags or chips should be fully **pill-shaped**. This extreme roundedness removes any visual "sharpness," making the app feel safe and welcoming.

## Components

- **Primary Buttons:** High-saturation Coral (#FF7F50) with white text. Height should be 56px for a comfortable touch target, with 28px (pill) or 20px rounded corners.
- **Outfit Cards:** Large-scale containers with a 24px radius. Use the tonal layer strategy: a white card on a light grey background or a light grey card on a white background.
- **Weather Chips:** Small pill-shaped tags (e.g., "Windy," "UV High") using a light tint of the primary color or secondary blue with high-contrast text.
- **Segmented Controls:** iOS-style toggle for switching between "Daily" and "Weekly" views, with rounded backgrounds and a subtle sliding indicator.
- **Input Fields:** Pure white backgrounds with a subtle grey border or a light grey fill, using 16px-20px corner radii.
- **Outfit Carousels:** Horizontal scrolling containers for alternative clothing items, featuring large, high-quality images with rounded corners.
