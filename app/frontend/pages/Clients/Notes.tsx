import { Head, Link, router, useForm } from "@inertiajs/react"
import { useState } from "react"
import Shell from "../../components/Shell"

interface Note {
  id: string; body: string; tag: string | null; isPinned: boolean; notedAt: string
}
interface Props {
  client: { id: string; name: string }
  filters: { q?: string; tag?: string }
  tags: string[]
  notes: Note[]
}

export default function Notes({ client, filters, tags, notes }: Props) {
  const [q, setQ] = useState(filters.q ?? "")
  const { data, setData, post, processing, reset } = useForm({ body: "", tag: "", is_pinned: false })

  const go = (next: Record<string, string>) =>
    router.get(`/clients/${client.id}/notes`, { ...filters, ...next },
      { preserveState: true, replace: true })

  return (
    <Shell>
      <Head title={`Notes · ${client.name}`} />
      <main className="mx-auto max-w-2xl px-4 py-8">
        <Link href={`/clients/${client.id}`} className="text-sm underline">← {client.name}</Link>
        <h1 className="mt-2 text-2xl font-semibold tracking-tight">Notes</h1>

        <form
          onSubmit={(e) => {
            e.preventDefault()
            post(`/clients/${client.id}/notes`, { onSuccess: () => reset() })
          }}
          className="mt-6 space-y-2 rounded-xl border border-neutral-200 p-3 dark:border-neutral-800"
        >
          <textarea value={data.body} rows={2} required placeholder="Add a note" aria-label="Note"
                    onChange={(e) => setData("body", e.target.value)}
                    className="w-full rounded-lg border border-neutral-300 bg-transparent px-3 py-2
                               text-base dark:border-neutral-700" />
          <div className="flex flex-wrap items-center gap-2">
            <select value={data.tag} onChange={(e) => setData("tag", e.target.value)} aria-label="Tag"
                    className="min-h-11 rounded-lg border border-neutral-300 bg-transparent px-3
                               text-sm dark:border-neutral-700">
              <option value="">No tag</option>
              {tags.map((t) => <option key={t} value={t}>{t}</option>)}
            </select>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={data.is_pinned} className="size-4"
                     onChange={(e) => setData("is_pinned", e.target.checked)} />
              Pin
            </label>
            <button type="submit" disabled={processing}
                    className="ml-auto min-h-11 rounded-lg bg-neutral-900 px-4 text-sm text-white
                               dark:bg-neutral-100 dark:text-neutral-900">Add</button>
          </div>
        </form>

        {/* Search within a client (NT-3). */}
        <form className="mt-6 flex flex-wrap gap-2"
              onSubmit={(e) => { e.preventDefault(); go({ q }) }}>
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search notes"
                 aria-label="Search notes"
                 className="min-h-11 flex-1 rounded-lg border border-neutral-300 bg-transparent px-3
                            text-base dark:border-neutral-700" />
          <select value={filters.tag ?? ""} onChange={(e) => go({ tag: e.target.value })}
                  aria-label="Filter by tag"
                  className="min-h-11 rounded-lg border border-neutral-300 bg-transparent px-3 text-sm
                             dark:border-neutral-700">
            <option value="">All tags</option>
            {tags.map((t) => <option key={t} value={t}>{t}</option>)}
          </select>
        </form>

        <ul className="mt-4 divide-y divide-neutral-200 dark:divide-neutral-800">
          {notes.map((n) => (
            <li key={n.id} className="flex items-start gap-2 py-3">
              <span className="flex-1 text-sm">
                <span className="flex flex-wrap items-center gap-2">
                  {n.isPinned && <span className="text-xs text-amber-700 dark:text-amber-500">pinned</span>}
                  {n.tag && (
                    <span className="text-xs uppercase tracking-wide text-neutral-400">{n.tag}</span>
                  )}
                  <span className="text-xs text-neutral-400">
                    {new Date(n.notedAt).toLocaleDateString()}
                  </span>
                </span>
                <span className="mt-1 block">{n.body}</span>
              </span>
              <span className="flex shrink-0 gap-2">
                <button
                  onClick={() => router.patch(`/clients/${client.id}/notes/${n.id}`,
                    { is_pinned: !n.isPinned })}
                  className="text-xs text-neutral-400 underline"
                >
                  {n.isPinned ? "Unpin" : "Pin"}
                </button>
                <button
                  onClick={() => router.delete(`/clients/${client.id}/notes/${n.id}`)}
                  className="text-xs text-neutral-400 underline"
                >
                  Delete
                </button>
              </span>
            </li>
          ))}
          {notes.length === 0 && (
            <li className="py-8 text-center text-sm text-neutral-500 dark:text-neutral-400">
              No notes match.
            </li>
          )}
        </ul>
      </main>
    </Shell>
  )
}
