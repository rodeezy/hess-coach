import { Link, usePage } from "@inertiajs/react"
import type { ReactNode } from "react"

const NAV = [
  { href: "/", label: "Home" },
  { href: "/clients", label: "Clients" },
  { href: "/exercises", label: "Library" },
  { href: "/templates", label: "Templates" },
]

/** Bottom tab bar on iPhone, left rail on laptop (spec section 9). */
export default function Shell({ children }: { children: ReactNode }) {
  const { url } = usePage()
  const active = (href: string) => (href === "/" ? url === "/" : url.startsWith(href))

  return (
    <div className="min-h-dvh sm:flex">
      <nav
        className="fixed inset-x-0 bottom-0 z-10 flex border-t border-neutral-200 bg-[var(--surface)]
                   pb-[env(safe-area-inset-bottom)] sm:static sm:w-48 sm:shrink-0 sm:flex-col
                   sm:border-r sm:border-t-0 sm:pb-0 dark:border-neutral-800"
      >
        <div className="hidden px-4 py-5 text-sm font-semibold sm:block">Hess Coach</div>
        {NAV.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`flex min-h-11 flex-1 items-center justify-center px-4 py-3 text-sm
              sm:flex-none sm:justify-start
              ${active(item.href)
                ? "font-medium text-neutral-900 sm:bg-neutral-100 dark:text-neutral-50 sm:dark:bg-neutral-900"
                : "text-neutral-500 dark:text-neutral-400"}`}
          >
            {item.label}
          </Link>
        ))}
      </nav>

      <div className="flex-1 pb-20 sm:pb-0">{children}</div>
    </div>
  )
}
