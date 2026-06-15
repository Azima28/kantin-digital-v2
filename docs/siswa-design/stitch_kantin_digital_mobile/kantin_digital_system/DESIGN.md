---
name: Kantin Digital System
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
  label-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0px
  caption-xs:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '400'
    lineHeight: 13px
    letterSpacing: 0.1px
  nav-title-mobile:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.2px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  margin-page: 16px
  gutter-stack: 12px
  padding-card: 16px
  radius-main: 12px
  radius-lg: 16px
---

## Brand & Style

The design system for this digital canteen app is built upon **Modern iOS Minimalism**, prioritizing clarity, efficiency, and a friendly Indonesian service tone. It bridges the gap between a utilitarian utility and an inviting culinary marketplace. 

The aesthetic is characterized by high legibility, generous negative space, and a refined tactile feel. By utilizing a "Card-on-Canvas" approach, the interface remains organized even when displaying complex menu data. The emotional response should be one of "effortless reliability"—making the process of ordering food as smooth as a native system interaction.

**Design Principles:**
- **Clarity First:** Prioritize content (food imagery and pricing) over decorative elements.
- **Native Familiarity:** Leverage established iOS patterns to reduce cognitive load for Indonesian students and staff.
- **Micro-delight:** Use subtle transitions and soft haptics to make digital transactions feel physical and secure.

## Colors

The palette is rooted in a professional **Primary Teal**, evoking cleanliness and digital trust. This is balanced by a vibrant **Accent Orange** used exclusively for "value-added" actions like wallet top-ups and active order statuses.

- **Primary Teal (#0E8A8A):** Used for primary buttons, active navigation states, and branding elements.
- **Accent Orange (#FF9500):** Reserved for "Saldo" (Balance) indicators and "Proses" (Processing) statuses.
- **System Red (#FF3B30):** Strictly for destructive actions (Hapus) or critical errors.
- **System Background (#F2F2F7):** The canvas color that provides depth behind white cards.
- **Card Background (#FFFFFF):** High-contrast surface for all interactive content blocks.
- **Border (#E5E5EA):** A subtle 0.5pt hairline used to define boundaries without adding visual weight.

## Typography

This design system uses **Inter** for its neutral, highly legible characteristics that mimic SF Pro's systematic feel. The hierarchy follows a strict iOS-inspired scale.

- **Large Navigation Titles:** Use `nav-title-lg` for top-level views (e.g., "Pesan Makan"). These should collapse into standard 17px centered titles upon scroll.
- **Food Headings:** Use `headline-md` for menu item names to ensure they stand out against prices.
- **Readability:** Body text utilizes standard 17px sizing for optimal comfort on mobile devices.
- **Currency:** Price points should use `body-semibold` to ensure the "Rp" (Rupiah) values are immediately identifiable.

## Layout & Spacing

The layout follows a **Fluid Grid** model with fixed 16px horizontal safe-area margins. 

- **The Card Model:** All content is grouped into cards. Cards should have a 16px internal padding (`padding-card`) and a bottom margin of 12px to maintain a rhythmic vertical stack.
- **Vertical Rhythm:** Use an 4px/8px-based system for internal component spacing.
- **Safe Areas:** Ensure all bottom-fixed elements (like the "Keranjang" / Cart summary) account for the iOS home indicator safe area.
- **Breakpoints:** This design system is mobile-first, targeting standard smartphone widths (375px - 430px). On larger screens, the maximum content width should be capped at 600px and centered.

## Elevation & Depth

This design system eschews heavy shadows in favor of **Tonal Layering** and **Hairline Outlines**.

- **Level 0 (Background):** `#F2F2F7` - The furthest back layer.
- **Level 1 (Cards):** `#FFFFFF` - Placed on Level 0. These cards feature a 0.5pt border of `#E5E5EA` instead of a shadow to maintain a crisp, minimalist look.
- **Level 2 (Modals/Sheets):** White surfaces with a soft, 15% opacity black shadow (0px 4px 20px) to indicate they are floating above the main UI.
- **Backdrop Blur:** Use system-standard background blurs (frosted glass) for the Top Navigation Bar and Bottom Tab Bar to provide context of content scrolling beneath.

## Shapes

The shape language is friendly and ergonomic, utilizing "Continuous Corner" (Squircle) geometry where possible.

- **Containers:** Standard cards and menu items use `rounded-lg` (12px-16px).
- **Interactive Elements:** Buttons and input fields should match the card's roundedness for a cohesive look.
- **Segmented Controls:** These use a pill-shaped (fully rounded) inner toggle to contrast against the more rectangular outer containers.
- **Sheet Handles:** Top-centered grab handles on bottom sheets must have a height of 5px and a width of 36px with fully rounded caps.

## Components

- **Buttons:** 
  - *Primary:* Filled with Primary Teal, white text, 12px-16px radius. 
  - *Secondary:* Ghost style with 0.5pt Teal border or light Teal background (10% opacity).
- **Cart Summary:** A floating bottom bar with a blurred background, featuring a Primary Teal button that displays "Lihat Keranjang" and the total "Rp" value.
- **Segmented Control:** A pill-shaped toggle used for switching between "Menu" and "Riwayat" (History). Use a light gray background with a white sliding selector.
- **Cards:** White containers with a 0.5pt border. Food cards should feature a square image on the left (rounded 8px) and text content on the right.
- **Quantity Selector:** A minimalist "+" and "-" layout with the number in the center, using Primary Teal for the icons to encourage interaction.
- **Status Chips:** Small, rounded-full badges. "Tersedia" (Available) uses a soft Teal tint; "Habis" (Sold Out) uses a light gray.
- **Input Fields:** Inset fields with a light gray background (#E9E9EB) and 10px roundedness for the "Cari Menu" (Search) bar, including a glass icon prefix.