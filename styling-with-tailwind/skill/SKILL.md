---
name: styling-with-tailwind
description: Creates UIs using Tailwind CSS utility classes and shadcn/ui patterns. Covers CSS variables with OKLCH colors, component variants with CVA, responsive design, dark mode, and Tailwind v4 features. Use when building interfaces with Tailwind, styling shadcn/ui components, implementing themes, or working with utility-first CSS.
---

# Styling with Tailwind CSS

Build accessible UIs using Tailwind utility classes and shadcn/ui component patterns.

## Core Patterns

### CSS Variables for Theming

shadcn/ui uses semantic CSS variables mapped to Tailwind utilities:

```css
/* globals.css - Light mode */
:root {
  --background: oklch(1 0 0);
  --foreground: oklch(0.145 0 0);
  --primary: oklch(0.205 0 0);
  --primary-foreground: oklch(0.985 0 0);
  --muted: oklch(0.97 0 0);
  --muted-foreground: oklch(0.556 0 0);
  --border: oklch(0.922 0 0);
  --radius: 0.5rem;
}

/* Dark mode */
.dark {
  --background: oklch(0.145 0 0);
  --foreground: oklch(0.985 0 0);
  --primary: oklch(0.922 0 0);
  --primary-foreground: oklch(0.205 0 0);
}

/* Tailwind v4: Map variables */
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-primary: var(--primary);
}
```

**Usage in components:**
```tsx
// Background colors omit the "-background" suffix
<div className="bg-primary text-primary-foreground">
<div className="bg-muted text-muted-foreground">
<div className="bg-destructive text-destructive-foreground">
```

### Component Variants with CVA

Use `class-variance-authority` for component variants:

```tsx
import { cva } from "class-variance-authority"

const buttonVariants = cva(
  "inline-flex items-center justify-center gap-2 rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-primary text-primary-foreground shadow hover:bg-primary/90",
        destructive: "bg-destructive text-destructive-foreground hover:bg-destructive/90",
        outline: "border border-input bg-background hover:bg-accent",
        ghost: "hover:bg-accent hover:text-accent-foreground",
        link: "text-primary underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 px-3 text-xs",
        lg: "h-10 px-8",
        icon: "size-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

// Usage
<Button variant="outline" size="sm">Click me</Button>
```

### Responsive Design

Mobile-first breakpoints:

```tsx
// Stack on mobile, grid on tablet+
<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">

// Hide on mobile
<div className="hidden md:block">

// Different layouts per breakpoint
<div className="flex flex-col md:flex-row lg:gap-8">
  <aside className="w-full md:w-64">
  <main className="flex-1">
</div>

// Responsive text sizes
<h1 className="text-3xl md:text-4xl lg:text-5xl">
```

### Dark Mode

```tsx
// Use dark: prefix for dark mode styles
<div className="bg-white dark:bg-black text-black dark:text-white">

// Theme toggle component
"use client"
import { Moon, Sun } from "lucide-react"
import { useTheme } from "next-themes"

export function ThemeToggle() {
  const { theme, setTheme } = useTheme()

  return (
    <button onClick={() => setTheme(theme === "dark" ? "light" : "dark")}>
      <Sun className="rotate-0 scale-100 dark:-rotate-90 dark:scale-0" />
      <Moon className="absolute rotate-90 scale-0 dark:rotate-0 dark:scale-100" />
    </button>
  )
}
```

## Common Component Patterns

### Card

```tsx
<div className="rounded-xl border bg-card text-card-foreground shadow">
  <div className="flex flex-col space-y-1.5 p-6">
    <h3 className="font-semibold leading-none tracking-tight">Title</h3>
    <p className="text-sm text-muted-foreground">Description</p>
  </div>
  <div className="p-6 pt-0">Content</div>
  <div className="flex items-center p-6 pt-0">Footer</div>
</div>
```

### Form Field

```tsx
<div className="space-y-2">
  <label className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
    Email
  </label>
  <input
    type="email"
    className="flex h-9 w-full rounded-md border border-input bg-transparent px-3 py-1 text-sm shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50"
  />
  <p className="text-sm text-muted-foreground">Helper text</p>
</div>
```

### Badge

```tsx
const badgeVariants = cva(
  "inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors",
  {
    variants: {
      variant: {
        default: "border-transparent bg-primary text-primary-foreground shadow",
        secondary: "border-transparent bg-secondary text-secondary-foreground",
        destructive: "border-transparent bg-destructive text-destructive-foreground",
        outline: "text-foreground",
      },
    },
  }
)
```

### Alert

```tsx
<div className="relative w-full rounded-lg border px-4 py-3 text-sm [&>svg]:absolute [&>svg]:left-4 [&>svg]:top-4 [&>svg+div]:translate-y-[-3px] [&:has(svg)]:pl-11">
  <AlertCircle className="size-4" />
  <div className="font-medium">Alert Title</div>
  <div className="text-sm text-muted-foreground">Description</div>
</div>
```

### Loading Skeleton

```tsx
<div className="space-y-2">
  <div className="h-4 w-[250px] animate-pulse rounded bg-muted" />
  <div className="h-4 w-[200px] animate-pulse rounded bg-muted" />
</div>
```

## Layout Patterns

### Centered Layout

```tsx
<div className="flex min-h-screen items-center justify-center">
  <div className="w-full max-w-md space-y-8 p-8">
    {/* Content */}
  </div>
</div>
```

### Sidebar Layout

```tsx
<div className="flex h-screen">
  <aside className="w-64 border-r bg-muted/40">Sidebar</aside>
  <main className="flex-1 overflow-auto">Content</main>
</div>
```

### Dashboard Grid

```tsx
<div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
  <Card className="col-span-2">Wide card</Card>
  <Card>Regular</Card>
  <Card>Regular</Card>
  <Card className="col-span-4">Full width</Card>
</div>
```

### Container with Max Width

```tsx
<div className="container mx-auto px-4 md:px-6 lg:px-8">
  <div className="max-w-2xl mx-auto">
    {/* Centered content */}
  </div>
</div>
```

## Accessibility Patterns

### Focus Visible

```tsx
<button className="focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2">
```

### Screen Reader Only

```tsx
<span className="sr-only">Close dialog</span>
```

### Disabled States

```tsx
<button className="disabled:cursor-not-allowed disabled:opacity-50" disabled>
```

### ARIA-friendly Alert

```tsx
<div role="alert" className="rounded-lg border p-4">
  <div className="flex items-start gap-3">
    <AlertCircle className="size-5 text-destructive" />
    <div className="flex-1 space-y-1">
      <h5 className="font-medium">Error</h5>
      <p className="text-sm text-muted-foreground">Message</p>
    </div>
  </div>
</div>
```

## Tailwind v4 Features

### Size Utility

```tsx
// New syntax (replaces w-* h-*)
<div className="size-4">
<div className="size-8">
<div className="size-full">
```

### @theme Directive

```css
/* Tailwind v4 syntax */
@theme {
  --color-primary: oklch(0.205 0 0);
  --font-sans: "Inter", system-ui;
}

/* With CSS variables */
@theme inline {
  --color-primary: var(--primary);
}
```

### Animation

```css
/* globals.css */
@import "tw-animate-css";
```

```tsx
<div className="animate-fade-in">
<div className="animate-slide-in-from-top">
<div className="animate-spin">
```

### Tailwind v4.1 Features (April 2025)

**Text Shadow:**
```tsx
// Subtle text shadows for depth
<h1 className="text-shadow-sm text-4xl font-bold">
<h2 className="text-shadow-md text-2xl">
<div className="text-shadow-lg text-xl">

// Custom text shadows
<div className="text-shadow-[0_2px_4px_rgb(0_0_0_/_0.1)]">
```

**Mask Utilities:**
```tsx
// Gradient masks for fade effects
<div className="mask-linear-to-b from-black to-transparent">
  Fades to transparent at bottom
</div>

// Image masks
<div className="mask-[url('/mask.svg')]">
  Masked content
</div>

// Common patterns
<div className="mask-radial-gradient">Spotlight effect</div>
```

**Colored Drop Shadow:**
```tsx
// Brand-colored shadows
<div className="drop-shadow-[0_4px_12px_oklch(0.488_0.243_264.376)]">

// Use with semantic colors
<Button className="drop-shadow-lg drop-shadow-primary/50">
  Glowing button
</Button>
```

**Overflow Wrap:**
```tsx
// Break long words
<p className="overflow-wrap-anywhere">
  verylongwordthatneedstowrap
</p>

<p className="overflow-wrap-break-word">
  URLs and long strings
</p>
```

## OKLCH Colors

Use OKLCH for better color perception:

```css
/* Format: oklch(lightness chroma hue) */
--primary: oklch(0.205 0 0);
--destructive: oklch(0.577 0.245 27.325);

/* Benefits: perceptually uniform, consistent lightness across hues */
```

## Base Color Palettes

shadcn/ui provides multiple base colors:

```css
/* Neutral (default) - pure grayscale */
--primary: oklch(0.205 0 0);

/* Zinc - cooler, blue-gray */
--primary: oklch(0.21 0.006 285.885);

/* Slate - balanced blue-gray */
--primary: oklch(0.208 0.042 265.755);

/* Stone - warmer, brown-gray */
--primary: oklch(0.216 0.006 56.043);
```

## Best Practices

### Prefer Semantic Colors

```tsx
// Good - uses theme
<div className="bg-background text-foreground">

// Avoid - hardcoded
<div className="bg-white text-black dark:bg-zinc-950">
```

### Group Related Utilities

```tsx
<div className="
  flex items-center justify-between
  rounded-lg border
  bg-card text-card-foreground
  p-4 shadow-sm
  hover:bg-accent
">
```

### Avoid Arbitrary Values

```tsx
// Prefer design tokens
<div className="p-4 text-sm">

// Avoid when unnecessary
<div className="p-[17px] text-[13px]">
```

## Installation

```bash
# Initialize shadcn/ui
pnpm dlx shadcn@latest init

# Add components
pnpm dlx shadcn@latest add button card form

# Add all components
pnpm dlx shadcn@latest add --all
```

## Troubleshooting

**Colors not updating:**
1. Check CSS variable in globals.css
2. Verify @theme inline includes variable
3. Clear build cache

**Dark mode not working:**
1. Verify ThemeProvider wraps app
2. Check suppressHydrationWarning on html tag
3. Ensure dark: variants defined

**Tailwind v4 migration:**
1. Run `@tailwindcss/upgrade@next` codemod
2. Update CSS variables with hsl() wrappers
3. Change @theme to @theme inline
4. Install tw-animate-css

## Component Patterns

For detailed component patterns see [components.md](components.md):
- **Composition**: asChild pattern for wrapping elements
- **Typography**: Heading scales, prose styles, inline code
- **Forms**: React Hook Form with Zod validation
- **Icons**: Lucide icons integration and sizing
- **Inputs**: OTP, file, grouped inputs
- **Dialogs**: Modal patterns and composition
- **Data Tables**: TanStack table integration
- **Toasts**: Sonner notifications
- **CLI**: Complete command reference

## Resources

See [theming.md](theming.md) for complete color system reference and examples.

## Summary

Key concepts:
- Use semantic CSS variables for theming
- Apply CVA for component variants
- Follow mobile-first responsive patterns
- Implement dark mode with next-themes
- Use OKLCH for modern color handling
- Prefer Tailwind v4 features (size-*, @theme)
- Always ensure accessibility with focus-visible, sr-only

This skill focuses on shadcn/ui patterns with Tailwind CSS. For component-specific examples, refer to the official shadcn/ui documentation.
