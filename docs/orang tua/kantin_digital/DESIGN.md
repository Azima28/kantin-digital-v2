---
name: Kantin Digital
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
  on-surface-variant: '#3e4948'
  inverse-surface: '#303030'
  inverse-on-surface: '#f2f0ef'
  outline: '#6f7979'
  outline-variant: '#bec9c8'
  surface-tint: '#066969'
  primary: '#004d4d'
  on-primary: '#ffffff'
  primary-container: '#006767'
  on-primary-container: '#94e2e2'
  inverse-primary: '#86d4d3'
  secondary: '#904d00'
  on-secondary: '#ffffff'
  secondary-container: '#fca558'
  on-secondary-container: '#713b00'
  tertiary: '#005027'
  on-tertiary: '#ffffff'
  tertiary-container: '#026b36'
  on-tertiary-container: '#90e9a6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#a2f0ef'
  primary-fixed-dim: '#86d4d3'
  on-primary-fixed: '#002020'
  on-primary-fixed-variant: '#004f4f'
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
  display-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Be Vietnam Pro
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Be Vietnam Pro
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
  title-md:
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
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 1.25rem
  stack-gap: 1rem
  bento-gap: 0.75rem
  section-margin: 2rem
---

## Brand & Style
The design system is anchored in a **Minimalist Modern** aesthetic with a distinct **iOS/Cupertino** influence. It is designed to bridge the gap between a vibrant student-facing utility and a reliable, professional parental monitoring tool. 

The visual narrative prioritizes clarity and trust. It utilizes a "Bento-grid" architecture to organize complex transactional data into digestible, high-contrast modules. By leaning into Apple’s Human Interface Guidelines (HIG) patterns—such as large corner radii and systemic spacing—the interface feels native, dependable, and effortless to navigate. The emotional response is one of organized calm, ensuring that financial management for schools feels secure rather than stressful.

## Colors
The color strategy employs a sophisticated palette that balances utility with warmth.

- **Primary Teal (#006767):** Used for structural brand elements, primary navigation, and high-level headers. It provides a grounded, academic feel.
- **Accent Orange (#904D00):** Reserved exclusively for financial growth actions, such as "Top-up" and displaying active balances, ensuring high visibility for the app's core value proposition.
- **Success Green (#006A35):** Utilized for transaction confirmations and positive status indicators.
- **System Background (#FBF9F8):** A warm, off-white grey that reduces eye strain and provides a soft canvas for cards.
- **Card Background (#FFFFFF):** Pure white is used for elevated "Bento" cards to create a crisp "stacked" appearance against the warm background.

## Typography
The system exclusively uses **Be Vietnam Pro** to maintain a contemporary and approachable character. 

Hierarchy is established through weight shifts (SemiBold to Regular) rather than excessive size changes. For iOS parity, the system follows a 17pt base for body text. Headings use tighter letter-spacing and heavier weights to create an editorial feel within the Bento layout. Captions and labels use Medium or SemiBold weights to ensure legibility at small sizes, particularly for transaction timestamps and item categories.

## Layout & Spacing
The layout follows a **Fluid Grid** model optimized for mobile viewports. 

- **Bento Structure:** Content is organized into modular cards. These cards should span the full width of the container or split into a 2-column grid (50/50) for smaller metrics.
- **Margins:** A standard 20px (1.25rem) horizontal margin is maintained globally.
- **Rhythm:** An 8px base unit is used for all internal padding and gaps. Use a 12px (0.75rem) gap between Bento cards to maintain a tight, organized appearance while allowing the background to breathe.
- **Safe Areas:** Adhere strictly to iOS safe-area insets for home indicators and notches.

## Elevation & Depth
This design system utilizes **Tonal Layers** combined with **Ambient Shadows** to create a sense of organized physical space.

- **Background:** The base layer is the System Background (#FBF9F8), which is flat.
- **Cards:** White cards are elevated using a very subtle, large-radius shadow (0px 4px 20px, 4% opacity black). This mimics the soft depth seen in modern iOS widgets.
- **Interactions:** When pressed, cards and buttons should slightly scale down (0.98x) rather than increasing shadow depth, emphasizing a tactile, physical feel.
- **Dividers:** Use 1px hairlines (#E5E5E5) within cards for list items, but avoid using them between primary layout sections to keep the "Bento" blocks distinct.

## Shapes
In alignment with the Cupertino aesthetic, this design system uses **Rounded** geometry with high-curvature values.

- **Standard Cards:** Use `rounded-xl` (1.5rem / 24px) to create the soft, friendly Bento look.
- **Buttons:** Primary buttons use `rounded-lg` (1rem / 16px) for a modern, reachable feel.
- **Small Elements:** Chips, badges, and input fields use `rounded-md` (0.5rem / 8px).
- **Avatars:** Strictly circular (50% radius) to contrast against the rectangular grid.

## Components

- **Bento Cards:** The foundational container. Always white with a 24px corner radius. Internal padding is consistently 16px or 20px.
- **Buttons:** 
  - *Primary:* Teal background, white text. Bold weight.
  - *Action (Top-up):* Orange background, white text. Often paired with a "+" icon.
- **Segmented Controls:** Follow the standard iOS style—a grey recessed track with a white sliding "thumb" to switch between views (e.g., Daily vs. Monthly history).
- **Input Fields:** Minimalist design with a light grey background tint or a simple bottom border. Labels stay above the field in a `label-sm` style.
- **Toggle Switches:** Native iOS style using the Primary Teal for the "on" state.
- **Chips/Badges:** Used for transaction categories (e.g., "Snack," "Lunch"). Low-intensity backgrounds (10% opacity of the category color) with high-contrast text.
- **Transaction Lists:** Clean rows within cards. The amount is SemiBold; the description is Regular. Use a vertical hairline divider only if the list exceeds 5 items.