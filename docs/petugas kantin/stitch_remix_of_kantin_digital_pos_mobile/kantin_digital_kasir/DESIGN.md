---
name: Kantin Digital Kasir
colors:
  surface: '#f9f9fe'
  surface-dim: '#d9dade'
  surface-bright: '#f9f9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f8'
  surface-container: '#ededf2'
  surface-container-high: '#e8e8ed'
  surface-container-highest: '#e2e2e7'
  on-surface: '#1a1c1f'
  on-surface-variant: '#3d4949'
  inverse-surface: '#2e3034'
  inverse-on-surface: '#f0f0f5'
  outline: '#6d7979'
  outline-variant: '#bdc9c8'
  surface-tint: '#006a6a'
  primary: '#006767'
  on-primary: '#ffffff'
  primary-container: '#008282'
  on-primary-container: '#f3fffe'
  inverse-primary: '#72d6d6'
  secondary: '#8c5000'
  on-secondary: '#ffffff'
  secondary-container: '#fe9400'
  on-secondary-container: '#633700'
  tertiary: '#bc000a'
  on-tertiary: '#ffffff'
  tertiary-container: '#e2241f'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8ff3f2'
  primary-fixed-dim: '#72d6d6'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#004f50'
  secondary-fixed: '#ffdcbf'
  secondary-fixed-dim: '#ffb874'
  on-secondary-fixed: '#2d1600'
  on-secondary-fixed-variant: '#6a3b00'
  tertiary-fixed: '#ffdad5'
  tertiary-fixed-dim: '#ffb4aa'
  on-tertiary-fixed: '#410001'
  on-tertiary-fixed-variant: '#930005'
  background: '#f9f9fe'
  on-background: '#1a1c1f'
  surface-variant: '#e2e2e7'
typography:
  nav-title-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.4px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 25px
    letterSpacing: -0.2px
  body-main:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.4px
  body-semibold:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.4px
  label-caps:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.1px
  price-display:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  nav-title-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-main: 16px
  gutter-grid: 12px
  stack-gap-sm: 8px
  stack-gap-md: 16px
  touch-target-min: 44px
---

## Brand & Style
The design system is engineered for the fast-paced environment of a school canteen, focusing on high legibility, rapid interaction, and a clean, institutional-yet-friendly aesthetic. It draws heavily from **Minimalist iOS (Cupertino)** principles, prioritizing functional clarity and spatial breathing room over decorative elements.

The target audience consists of canteen staff (canteen ladies/men) and student assistants who require a reliable, professional tool that feels like a native part of their device ecosystem. The emotional response should be one of **efficiency, trust, and cleanliness**, mirroring the hygiene standards expected in food service.

Key visual pillars:
- **Clarity first:** Large, bold titles and high-contrast labeling.
- **Native feel:** Familiar iOS patterns to reduce the learning curve.
- **Transactional focus:** Using color strategically to highlight financial actions and cart status.

## Colors
The palette is rooted in the functional color language of mobile operating systems, adapted for a professional POS environment.

- **Primary Teal (#0E8A8A):** Used for the main branding, primary action buttons (e.g., *Bayar*, *Proses*), and active states. It conveys professional stability and cleanliness.
- **Accent Orange (#FF9500):** Reserved for high-visibility transactional elements like the *Keranjang* (Cart) count, pending alerts, and "Cek Kartu" prompts.
- **System Red (#FF3B30):** Strictly for destructive actions, errors, or *Refund* operations.
- **Neutral Stack:** A foundation of **#F2F2F7** for the main canvas to provide depth against **#FFFFFF** cards. Surface borders use a thin **#E5E5EA** to define boundaries without adding visual weight.

## Typography
This design system utilizes **Inter** for its neutral, highly legible characteristic that mimics the clarity of SF Pro. 

- **Large Navigation Titles:** Following iOS patterns, screens start with a `nav-title-lg` (34px) which collapses to a standard header on scroll.
- **Transactional Text:** Prices (*Harga*) should always use `price-display` or `body-semibold` to ensure no ambiguity during checkout.
- **Indonesian Context:** Copywriting should be concise. For example, use "Total Tagihan" instead of "Jumlah total yang harus dibayar".
- **Hierarchy:** Use `label-caps` in a secondary grey color for section headers like "KATEGORI JAJANAN" or "RIWAYAT TRANSAKSI".

## Layout & Spacing
The layout follows a **Fixed Grid** philosophy typical of mobile applications, ensuring critical POS controls are always within thumb-reach.

- **Safe Areas:** A standard 16px horizontal margin is maintained globally.
- **Grid System:** Product cards (*Jajanan*) are arranged in a 2-column or 3-column fluid grid depending on screen width, with 12px gutters.
- **Interaction Zones:** All buttons and tap areas (like *Tap Kartu Siswa*) must adhere to a minimum 44px height to prevent mis-taps during busy recess hours.
- **Reflow:** On tablets (often used as fixed cash registers), the layout should adopt a split-view: Categories/Items on the left (60%) and the active Cart (*Keranjang*) on the right (40%).

## Elevation & Depth
In line with modern iOS aesthetics, this design system avoids heavy drop shadows.

- **Flat Hierarchy:** Depth is created through **Tonal Layers** rather than elevation. White cards (#FFFFFF) sit atop the light grey system background (#F2F2F7).
- **Outlines:** Instead of shadows, use a **0.5px solid border** (#E5E5EA) to define card edges and input fields.
- **Modals:** Use the "Page Sheet" style for overlays (e.g., adding a new menu item), where the modal slides up and leaves the dimmed parent view visible at the top.
- **Active States:** When a button is pressed, it should reduce in opacity (to 0.7) rather than changing elevation, providing immediate tactile feedback.

## Shapes
The shape language is friendly and approachable, utilizing large corner radii to soften the industrial nature of a POS app.

- **Cards & Containers:** Use a 12px or 16px radius. This applies to product cards, the checkout summary, and modal containers.
- **Buttons:** Primary action buttons should use a 12px radius to match the cards.
- **Segmented Controls:** Use a fully rounded pill shape (3) for toggle-like interactions, such as switching between "Makanan" and "Minuman".
- **Search Bars:** Rounded corner of 10px to align with the system-standard iOS search input.

## Components
Consistent component behavior ensures the speed of service.

- **Primary Button (Bayar):** Solid Teal (#0E8A8A) background with white text. Height 50px.
- **Secondary/Cart Button:** Solid Orange (#FF9500) with white text.
- **Jajanan Cards:** White background, 0.5px border, 12px radius. Image at top, title and price below.
- **Segmented Control:** A background of #E3E3E8 with a white sliding "thumb" to switch categories.
- **Grab Handles:** For bottom sheets (e.g., student balance check), include a 36x5px rounded bar at the top center.
- **List Items:** Use for "Riwayat Transaksi" (Transaction History). 44px minimum height, chevron-right icon for drill-downs, and 0.5px hair-line separators.
- **Input Fields:** Inset styling with clear "X" buttons to wipe text quickly during search.