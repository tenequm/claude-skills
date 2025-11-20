# Component Patterns Reference

## Composition with asChild

Use `asChild` to compose components without wrapper divs:

```tsx
// Button as a Link (Next.js)
import Link from "next/link"

<Button asChild>
  <Link href="/login">Login</Link>
</Button>

// Renders: <a href="/login" class="...button classes">Login</a>
// No wrapper div!

// Button as a custom component
<Button asChild variant="outline">
  <a href="https://example.com" target="_blank">
    External Link
  </a>
</Button>

// Dialog trigger with custom element
<DialogTrigger asChild>
  <div className="cursor-pointer">
    Custom trigger element
  </div>
</DialogTrigger>
```

**When to use:**
- Wrapping navigation links
- Custom interactive elements
- Avoiding nested buttons
- Semantic HTML (button → link when navigating)

## Typography Patterns

shadcn/ui typography scales using Tailwind utilities:

```tsx
// Headings with responsive sizing
<h1 className="scroll-m-20 text-4xl font-extrabold tracking-tight lg:text-5xl">
  Taxing Laughter: The Joke Tax Chronicles
</h1>

<h2 className="scroll-m-20 border-b pb-2 text-3xl font-semibold tracking-tight first:mt-0">
  The People of the Kingdom
</h2>

<h3 className="scroll-m-20 text-2xl font-semibold tracking-tight">
  The Joke Tax
</h3>

<h4 className="scroll-m-20 text-xl font-semibold tracking-tight">
  People stopped telling jokes
</h4>

// Paragraph
<p className="leading-7 [&:not(:first-child)]:mt-6">
  The king, seeing how much happier his subjects were, realized the error of his ways.
</p>

// Blockquote
<blockquote className="mt-6 border-l-2 pl-6 italic">
  "After all," he said, "everyone enjoys a good joke."
</blockquote>

// Inline code
<code className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold">
  @radix-ui/react-alert-dialog
</code>

// Lead text (larger paragraph)
<p className="text-xl text-muted-foreground">
  A modal dialog that interrupts the user with important content.
</p>

// Small text
<small className="text-sm font-medium leading-none">Email address</small>

// Muted text
<p className="text-sm text-muted-foreground">
  Enter your email address.
</p>

// List
<ul className="my-6 ml-6 list-disc [&>li]:mt-2">
  <li>1st level of puns: 5 gold coins</li>
  <li>2nd level of jokes: 10 gold coins</li>
  <li>3rd level of one-liners: 20 gold coins</li>
</ul>
```

## Icons with Lucide

```tsx
import { ChevronRight, Check, X, AlertCircle, Loader2 } from "lucide-react"

// Icon sizing with components
<Button>
  <ChevronRight className="size-4" />
  Next
</Button>

// Icons automatically adjust to button size
<Button size="sm">
  <Check className="size-4" />
  Small Button
</Button>

<Button size="lg">
  <Check className="size-4" />
  Large Button
</Button>

// Icon-only button
<Button size="icon" variant="outline">
  <X className="size-4" />
</Button>

// Loading state
<Button disabled>
  <Loader2 className="size-4 animate-spin" />
  Please wait
</Button>

// Icon with semantic colors
<AlertCircle className="size-4 text-destructive" />
<Check className="size-4 text-green-500" />

// In alerts
<Alert>
  <AlertCircle className="size-4" />
  <AlertTitle>Error</AlertTitle>
  <AlertDescription>
    Your session has expired.
  </AlertDescription>
</Alert>
```

**Icon sizing reference:**
- `size-3` - Extra small (12px)
- `size-4` - Small/default (16px)
- `size-5` - Medium (20px)
- `size-6` - Large (24px)

## Form with React Hook Form

Complete form example with validation:

```tsx
"use client"

import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import { z } from "zod"

import { Button } from "@/components/ui/button"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { Input } from "@/components/ui/input"
import { toast } from "sonner"

// Define schema
const formSchema = z.object({
  username: z.string().min(2, {
    message: "Username must be at least 2 characters.",
  }),
  email: z.string().email({
    message: "Please enter a valid email address.",
  }),
  bio: z.string().max(160).min(4),
})

export function ProfileForm() {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      username: "",
      email: "",
      bio: "",
    },
  })

  function onSubmit(values: z.infer<typeof formSchema>) {
    toast.success("Profile updated successfully")
    console.log(values)
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Username</FormLabel>
              <FormControl>
                <Input placeholder="shadcn" {...field} />
              </FormControl>
              <FormDescription>
                This is your public display name.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input type="email" placeholder="m@example.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="bio"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Bio</FormLabel>
              <FormControl>
                <Textarea
                  placeholder="Tell us about yourself"
                  className="resize-none"
                  {...field}
                />
              </FormControl>
              <FormDescription>
                You can write up to 160 characters.
              </FormDescription>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit">Update profile</Button>
      </form>
    </Form>
  )
}
```

## Input Variants

### Input OTP

```tsx
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSeparator,
  InputOTPSlot,
} from "@/components/ui/input-otp"

<InputOTP maxLength={6}>
  <InputOTPGroup>
    <InputOTPSlot index={0} />
    <InputOTPSlot index={1} />
    <InputOTPSlot index={2} />
  </InputOTPGroup>
  <InputOTPSeparator />
  <InputOTPGroup>
    <InputOTPSlot index={3} />
    <InputOTPSlot index={4} />
    <InputOTPSlot index={5} />
  </InputOTPGroup>
</InputOTP>
```

### Input with Icon

```tsx
import { Search } from "lucide-react"

<div className="relative">
  <Search className="absolute left-2 top-2.5 size-4 text-muted-foreground" />
  <Input placeholder="Search" className="pl-8" />
</div>
```

### File Input

```tsx
<Input
  type="file"
  className="cursor-pointer file:mr-4 file:rounded-md file:border-0 file:bg-primary file:px-4 file:py-2 file:text-sm file:font-semibold file:text-primary-foreground hover:file:bg-primary/90"
/>
```

### Input Group

```tsx
import { InputGroup, InputGroupText } from "@/components/ui/input-group"

<InputGroup>
  <InputGroupText>https://</InputGroupText>
  <Input placeholder="example.com" />
</InputGroup>

<InputGroup>
  <Input placeholder="Amount" />
  <InputGroupText>USD</InputGroupText>
</InputGroup>
```

## Data-Slot Composition

Components use `data-slot` attributes for styling child elements:

```tsx
// Button automatically styles icons with data-slot
<Button>
  <CheckIcon data-slot="icon" />
  Save Changes
</Button>

// Custom component using data-slot pattern
function CustomCard({ children }: { children: React.ReactNode }) {
  return (
    <div className="rounded-lg border p-4 [&>[data-slot=icon]]:size-5 [&>[data-slot=icon]]:text-muted-foreground">
      {children}
    </div>
  )
}

// Usage
<CustomCard>
  <AlertCircle data-slot="icon" />
  <p>This icon is automatically styled</p>
</CustomCard>
```

**Common data-slot values:**
- `icon` - Icons within components
- `title` - Heading elements
- `description` - Descriptive text
- `action` - Action buttons or triggers

## Select Component

```tsx
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"

<Select>
  <SelectTrigger className="w-[180px]">
    <SelectValue placeholder="Select a fruit" />
  </SelectTrigger>
  <SelectContent>
    <SelectItem value="apple">Apple</SelectItem>
    <SelectItem value="banana">Banana</SelectItem>
    <SelectItem value="blueberry">Blueberry</SelectItem>
  </SelectContent>
</Select>

// With form
<FormField
  control={form.control}
  name="fruit"
  render={({ field }) => (
    <FormItem>
      <FormLabel>Fruit</FormLabel>
      <Select onValueChange={field.onChange} defaultValue={field.value}>
        <FormControl>
          <SelectTrigger>
            <SelectValue placeholder="Select a fruit" />
          </SelectTrigger>
        </FormControl>
        <SelectContent>
          <SelectItem value="apple">Apple</SelectItem>
          <SelectItem value="banana">Banana</SelectItem>
        </SelectContent>
      </Select>
      <FormMessage />
    </FormItem>
  )}
/>
```

## Checkbox and Radio Groups

```tsx
// Checkbox
import { Checkbox } from "@/components/ui/checkbox"

<div className="flex items-center space-x-2">
  <Checkbox id="terms" />
  <label
    htmlFor="terms"
    className="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
  >
    Accept terms and conditions
  </label>
</div>

// Radio Group
import { Label } from "@/components/ui/label"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"

<RadioGroup defaultValue="comfortable">
  <div className="flex items-center space-x-2">
    <RadioGroupItem value="default" id="r1" />
    <Label htmlFor="r1">Default</Label>
  </div>
  <div className="flex items-center space-x-2">
    <RadioGroupItem value="comfortable" id="r2" />
    <Label htmlFor="r2">Comfortable</Label>
  </div>
  <div className="flex items-center space-x-2">
    <RadioGroupItem value="compact" id="r3" />
    <Label htmlFor="r3">Compact</Label>
  </div>
</RadioGroup>
```

## Dialog Pattern

```tsx
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
  DialogFooter,
} from "@/components/ui/dialog"

<Dialog>
  <DialogTrigger asChild>
    <Button variant="outline">Edit Profile</Button>
  </DialogTrigger>
  <DialogContent className="sm:max-w-[425px]">
    <DialogHeader>
      <DialogTitle>Edit profile</DialogTitle>
      <DialogDescription>
        Make changes to your profile here. Click save when you're done.
      </DialogDescription>
    </DialogHeader>
    <div className="grid gap-4 py-4">
      <div className="grid grid-cols-4 items-center gap-4">
        <Label htmlFor="name" className="text-right">
          Name
        </Label>
        <Input id="name" value="Pedro Duarte" className="col-span-3" />
      </div>
    </div>
    <DialogFooter>
      <Button type="submit">Save changes</Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

## Dropdown Menu

```tsx
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"

<DropdownMenu>
  <DropdownMenuTrigger asChild>
    <Button variant="outline">Open</Button>
  </DropdownMenuTrigger>
  <DropdownMenuContent>
    <DropdownMenuLabel>My Account</DropdownMenuLabel>
    <DropdownMenuSeparator />
    <DropdownMenuItem>Profile</DropdownMenuItem>
    <DropdownMenuItem>Billing</DropdownMenuItem>
    <DropdownMenuItem>Team</DropdownMenuItem>
    <DropdownMenuItem>Subscription</DropdownMenuItem>
  </DropdownMenuContent>
</DropdownMenu>
```

## Toast Notifications

```tsx
import { toast } from "sonner"

// Success
toast.success("Event created successfully")

// Error
toast.error("Something went wrong")

// Info
toast.info("Be aware that...")

// Warning
toast.warning("Proceed with caution")

// Loading
toast.loading("Uploading...")

// Custom
toast("Event created", {
  description: "Monday, January 3rd at 6:00pm",
  action: {
    label: "Undo",
    onClick: () => console.log("Undo"),
  },
})

// Promise
toast.promise(promise, {
  loading: "Loading...",
  success: (data) => `${data.name} created`,
  error: "Error creating event",
})
```

## Data Table Pattern

```tsx
"use client"

import {
  ColumnDef,
  flexRender,
  getCoreRowModel,
  useReactTable,
} from "@tanstack/react-table"

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"

interface DataTableProps<TData, TValue> {
  columns: ColumnDef<TData, TValue>[]
  data: TData[]
}

export function DataTable<TData, TValue>({
  columns,
  data,
}: DataTableProps<TData, TValue>) {
  const table = useReactTable({
    data,
    columns,
    getCoreRowModel: getCoreRowModel(),
  })

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableHead key={header.id}>
                  {flexRender(
                    header.column.columnDef.header,
                    header.getContext()
                  )}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows?.length ? (
            table.getRowModel().rows.map((row) => (
              <TableRow key={row.id}>
                {row.getVisibleCells().map((cell) => (
                  <TableCell key={cell.id}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          ) : (
            <TableRow>
              <TableCell colSpan={columns.length} className="h-24 text-center">
                No results.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  )
}
```

## CLI Commands Reference

```bash
# Initialize project
pnpm dlx shadcn@latest init

# Add specific components
pnpm dlx shadcn@latest add button
pnpm dlx shadcn@latest add card form input

# Add all components
pnpm dlx shadcn@latest add --all

# Update/overwrite existing components
pnpm dlx shadcn@latest add button --overwrite
pnpm dlx shadcn@latest add --all --overwrite

# Show component diff (see what changed)
pnpm dlx shadcn@latest diff button

# List available components
pnpm dlx shadcn@latest add

# Use canary release (for Tailwind v4 + React 19)
pnpm dlx shadcn@canary init
pnpm dlx shadcn@canary add button
```

## Field Component (October 2025)

Simplified form field wrapper without React Hook Form:

```tsx
import { Field, FieldLabel, FieldDescription, FieldError } from "@/components/ui/field"

<Field>
  <FieldLabel>Email address</FieldLabel>
  <Input
    type="email"
    placeholder="m@example.com"
    aria-describedby="email-description email-error"
  />
  <FieldDescription id="email-description">
    We'll never share your email.
  </FieldDescription>
  <FieldError id="email-error">
    {errors.email?.message}
  </FieldError>
</Field>

// With validation state
<Field invalid={!!errors.password}>
  <FieldLabel required>Password</FieldLabel>
  <Input type="password" />
  <FieldError>{errors.password?.message}</FieldError>
</Field>

// Inline field
<Field orientation="horizontal">
  <FieldLabel>Subscribe</FieldLabel>
  <Checkbox />
  <FieldDescription>Get updates via email</FieldDescription>
</Field>
```

## Item Component (October 2025)

Flex container for list items with consistent spacing:

```tsx
import { Item, ItemIcon, ItemLabel, ItemDescription } from "@/components/ui/item"

// List item with icon
<Item>
  <ItemIcon>
    <FileIcon className="size-4" />
  </ItemIcon>
  <div>
    <ItemLabel>document.pdf</ItemLabel>
    <ItemDescription>2.4 MB</ItemDescription>
  </div>
</Item>

// Card-style items
<Item asChild>
  <a href="/dashboard" className="rounded-lg border p-4 hover:bg-accent">
    <ItemIcon>
      <LayoutDashboard className="size-5" />
    </ItemIcon>
    <div>
      <ItemLabel>Dashboard</ItemLabel>
      <ItemDescription>View your analytics</ItemDescription>
    </div>
  </a>
</Item>

// Navigation items
<nav className="space-y-1">
  <Item asChild>
    <a href="/home" className="px-3 py-2 rounded-md hover:bg-accent">
      <ItemIcon><Home className="size-4" /></ItemIcon>
      <ItemLabel>Home</ItemLabel>
    </a>
  </Item>
</nav>
```

## Spinner Component (October 2025)

Dedicated loading spinner component:

```tsx
import { Spinner } from "@/components/ui/spinner"

// Default spinner
<Spinner />

// With size variants
<Spinner size="sm" />
<Spinner size="md" />
<Spinner size="lg" />

// In buttons
<Button disabled>
  <Spinner size="sm" />
  Loading...
</Button>

// Full page loading
<div className="flex min-h-screen items-center justify-center">
  <Spinner size="lg" />
</div>

// With custom colors
<Spinner className="text-primary" />
```

## Button Group (October 2025)

Grouped buttons with consistent styling:

```tsx
import { ButtonGroup, ButtonGroupButton } from "@/components/ui/button-group"

// Basic button group
<ButtonGroup>
  <ButtonGroupButton>Left</ButtonGroupButton>
  <ButtonGroupButton>Center</ButtonGroupButton>
  <ButtonGroupButton>Right</ButtonGroupButton>
</ButtonGroup>

// With active state
<ButtonGroup>
  <ButtonGroupButton active>Day</ButtonGroupButton>
  <ButtonGroupButton>Week</ButtonGroupButton>
  <ButtonGroupButton>Month</ButtonGroupButton>
</ButtonGroup>

// With icons
<ButtonGroup>
  <ButtonGroupButton>
    <Bold className="size-4" />
  </ButtonGroupButton>
  <ButtonGroupButton>
    <Italic className="size-4" />
  </ButtonGroupButton>
  <ButtonGroupButton>
    <Underline className="size-4" />
  </ButtonGroupButton>
</ButtonGroup>

// Vertical orientation
<ButtonGroup orientation="vertical">
  <ButtonGroupButton>Top</ButtonGroupButton>
  <ButtonGroupButton>Middle</ButtonGroupButton>
  <ButtonGroupButton>Bottom</ButtonGroupButton>
</ButtonGroup>
```

## Keyboard Shortcuts Component

```tsx
import { Kbd } from "@/components/ui/kbd"

<div className="flex items-center gap-1">
  <Kbd>⌘</Kbd>
  <Kbd>K</Kbd>
</div>

// Search shortcut display
<div className="text-sm text-muted-foreground">
  Press <Kbd>⌘</Kbd> + <Kbd>K</Kbd> to search
</div>
```

## Empty State

```tsx
import { Empty } from "@/components/ui/empty"
import { FileIcon } from "lucide-react"

<Empty>
  <FileIcon className="size-10 text-muted-foreground" />
  <h3 className="mt-4 text-lg font-semibold">No files uploaded</h3>
  <p className="mb-4 mt-2 text-sm text-muted-foreground">
    Upload your first file to get started
  </p>
  <Button>Upload File</Button>
</Empty>
```
