---
name: Kantin Digital Master Control
colors:
  surface: '#fbf9f8'
  surface-dim: '#dbdad9'
  surface-bright: '#fbf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f2'
  surface-container: '#efedec'
  surface-container-high: '#e9e8e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1b'
  on-surface-variant: '#3f4848'
  inverse-surface: '#303030'
  inverse-on-surface: '#f2f0ef'
  outline: '#6f7978'
  outline-variant: '#bfc8c8'
  surface-tint: '#296767'
  primary: '#003434'
  on-primary: '#ffffff'
  primary-container: '#004d4d'
  on-primary-container: '#80bdbc'
  inverse-primary: '#94d1d1'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#fca558'
  on-secondary-container: '#713b00'
  tertiary: '#003718'
  on-tertiary: '#ffffff'
  tertiary-container: '#005026'
  on-tertiary-container: '#6dc485'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b0eeed'
  primary-fixed-dim: '#94d1d1'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#044f4f'
  secondary-fixed: '#ffdcc3'
  secondary-fixed-dim: '#ffb77c'
  on-secondary-fixed: '#2f1500'
  on-secondary-fixed-variant: '#6e3900'
  tertiary-fixed: '#9df6b2'
  tertiary-fixed-dim: '#81d998'
  on-tertiary-fixed: '#00210c'
  on-tertiary-fixed-variant: '#005228'
  background: '#fbf9f8'
  on-background: '#1b1c1b'
  surface-variant: '#e4e2e1'
typography:
  display:
    fontFamily: Be Vietnam Pro
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Be Vietnam Pro
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 25px
  body-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Be Vietnam Pro
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Be Vietnam Pro
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Be Vietnam Pro
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 13px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-margin: 20px
  stack-gap: 16px
  bento-gap: 12px
  inline-padding: 16px
  section-padding: 24px
---

## Brand & Style
The design system is engineered for a high-stakes "Super Admin" environment, balancing the urgency of real-time monitoring with a premium, executive aesthetic. The brand personality is authoritative yet approachable, utilizing a **Cupertino-inspired Minimalism** that prioritizes clarity and precision. 

The visual narrative is driven by a **Bento-Grid architecture**, organizing complex data into digestible, modular units. The interface should feel like a high-end physical control deck—tactile, responsive, and impeccably organized. It targets administrators who require rapid cognitive processing of financial and operational data without the fatigue associated with typical enterprise dashboards.

## Colors
This design system utilizes a sophisticated, high-contrast palette designed for functional segmentation:

- **Primary Teal (#004D4D):** Used for the "Command Layer"—navigation bars, primary action buttons, and structural identity.
- **Accent Orange (#904D00):** Reserved exclusively for "Value Layers"—financial balances, transaction totals, and global currency indicators to ensure immediate visual anchoring.
- **Success Green (#006A35):** Applied to "Status Layers"—indicating system health, completed transactions, and positive growth metrics.
- **System Background (#FBF9F8):** A warm, off-white neutral that reduces eye strain and provides a softer canvas than pure white.
- **Surface/Card (#FFFFFF):** Pure white used for Bento containers to create a distinct elevation break from the system background.

## Typography
The typography system leverages **Be Vietnam Pro** to achieve a contemporary, legible, and professional feel. 

- **Weight Usage:** Use **Bold (700)** for primary totals and display titles. Use **SemiBold (600)** for card headings and primary buttons. Use **Medium (500)** for interactive labels and segmented control text. Use **Regular (400)** for descriptive body text and secondary metadata.
- **Scale:** The hierarchy follows a strict mobile-first approach. Large display sizes are reserved for financial totals, while small, uppercase labels are used for category tags and technical status indicators.
- **Tight Kerning:** Slightly negative letter spacing is applied to larger headlines to maintain the dense, "tech" aesthetic of a control panel.

## Layout & Spacing
The layout follows a **Fluid Bento-Grid** model optimized for the verticality of iOS devices.

- **Bento Structure:** Content is housed in modular cards. The grid typically follows a single-column stack or a 2-column "equal split" depending on the data density.
- **Margins:** A consistent 20px horizontal margin is applied to the main viewport.
- **Rhythm:** Use a 4px baseline grid. Internal card padding should be a minimum of 16px to ensure touch targets remain accessible while maintaining a dense information display.
- **Reflow:** On smaller devices, 2-column grids reflow into a single column. On larger iOS devices (Pro Max), 2-column layouts are preferred to maximize information density.

## Elevation & Depth
Depth is communicated through **Tonal Layering** and **Soft Ambient Shadows** rather than aggressive bevels.

- **Level 0 (System Background):** The base canvas (#FBF9F8).
- **Level 1 (Bento Cards):** Pure white surfaces (#FFFFFF) with a very soft, diffused shadow (0px 4px 20px rgba(0, 0, 0, 0.04)). This creates a "floating" effect.
- **Level 2 (Modals/Bottom Sheets):** Higher elevation with a more pronounced shadow (0px 10px 30px rgba(0, 0, 0, 0.08)) and a backdrop blur (20px) on the obscured content.
- **Interactive States:** Buttons and cards should subtly "sink" (scale 0.98) on press, providing haptic-like visual feedback consistent with iOS standards.

## Shapes
The shape language is defined by **Wide, Generous Radii** that contrast with the precise typography.

- **Bento Cards:** Use a fixed **24px (rounded-xl)** corner radius. This is the signature of the system and creates a soft, modern container.
- **Buttons & Inputs:** Follow a **12px (rounded-md)** radius for a more functional, tool-like appearance within the soft cards.
- **Chips/Status Badges:** Use **Pill-shaped** (fully rounded) geometry to distinguish them from interactive buttons.
- **Consistency:** All containers must use "continuous corner" smoothing (squircular) to align with the native iOS aesthetic.

## Components
Consistent implementation of these components ensures the "Super Admin" experience remains cohesive:

- **Bento Cards:** The primary container. Headlines inside cards should be `headline-md`. Support for "Small," "Medium," and "Large" card heights is required.
- **Primary Buttons:** Solid fill using Primary Teal. Text should be `label-md` in white. High-impact financial actions may use Accent Orange.
- **Segmented Controls:** Standard iOS-style toggle for switching views (e.g., "Daily / Weekly / Monthly"). Background should be a light tint of the primary teal or a neutral gray.
- **Financial Indicators:** Always display the currency symbol in a lighter weight than the value. Values should be SemiBold.
- **Status Badges:** Small pill shapes. Success uses Success Green with 10% opacity background and 100% opacity text.
- **Bottom Sheets:** Use for complex filtering or quick-edit admin tasks. Include a "grabber" handle at the top.
- **Switches:** Use native iOS styling, but tinted with Primary Teal for the 'On' state.