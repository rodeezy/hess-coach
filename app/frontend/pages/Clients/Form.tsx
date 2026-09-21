import { Head, Link, useForm } from "@inertiajs/react"
import Shell from "../../components/Shell"

interface Phase { id: string; name: string; sweetMin: number | null; sweetMax: number | null }
interface Props {
  client: Record<string, unknown> & { id?: string }
  phases: Phase[]
}

const field =
  "mt-1 min-h-11 w-full rounded-lg border border-neutral-300 bg-transparent px-3 text-base " +
  "dark:border-neutral-700"

export default function ClientForm({ client, phases }: Props) {
  const editing = Boolean(client.id)
  const { data, setData, post, patch, processing, errors } = useForm({
    first_name: (client.first_name as string) ?? "",
    last_name: (client.last_name as string) ?? "",
    email: (client.email as string) ?? "",
    phone: (client.phone as string) ?? "",
    date_of_birth: (client.date_of_birth as string) ?? "",
    sex: (client.sex as string) ?? "",
    height_cm: (client.height_cm as string) ?? "",
    start_date: (client.start_date as string) ?? "",
    current_phase_id: (client.current_phase_id as string) ?? "",
    phase_started_on: (client.phase_started_on as string) ?? "",
    disc_type: (client.disc_type as string) ?? "",
    max_hr: (client.max_hr as string) ?? "",
    uses_power_block: Boolean(client.uses_power_block),
    uses_vbt: Boolean(client.uses_vbt),
    intake_notes: (client.intake_notes as string) ?? "",
  })

  const submit = (e: React.FormEvent) => {
    e.preventDefault()
    editing ? patch(`/clients/${client.id}`) : post("/clients")
  }

  return (
    <Shell>
      <Head title={editing ? "Edit client" : "Add client"} />
      <main className="mx-auto max-w-lg px-4 py-8">
        <h1 className="text-2xl font-semibold tracking-tight">
          {editing ? "Edit client" : "Add client"}
        </h1>
        {/* Only a name is required; everything else can wait (UX-10). */}
        <p className="mt-1 text-sm text-neutral-500 dark:text-neutral-400">
          Only a first name is required. Fill in the rest whenever.
        </p>

        <form onSubmit={submit} className="mt-6 space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              First name
              <input value={data.first_name} required autoFocus className={field}
                     onChange={(e) => setData("first_name", e.target.value)} />
              {errors.first_name && (
                <span className="mt-1 block text-xs text-red-600">{errors.first_name}</span>
              )}
            </label>
            <label className="block text-sm">
              Last name
              <input value={data.last_name} className={field}
                     onChange={(e) => setData("last_name", e.target.value)} />
            </label>
          </div>

          <label className="block text-sm">
            Email
            <input type="email" value={data.email} className={field}
                   onChange={(e) => setData("email", e.target.value)} />
          </label>
          <label className="block text-sm">
            Phone
            <input type="tel" value={data.phone} className={field}
                   onChange={(e) => setData("phone", e.target.value)} />
          </label>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              Date of birth
              <input type="date" value={data.date_of_birth} className={field}
                     onChange={(e) => setData("date_of_birth", e.target.value)} />
            </label>
            <label className="block text-sm">
              Start date
              <input type="date" value={data.start_date} className={field}
                     onChange={(e) => setData("start_date", e.target.value)} />
            </label>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              Height (cm)
              <input type="number" inputMode="decimal" step="0.1" value={data.height_cm}
                     className={field}
                     onChange={(e) => setData("height_cm", e.target.value)} />
              <span className="mt-1 block text-xs text-neutral-500 dark:text-neutral-400">
                Needed for FFMI
              </span>
            </label>
            <label className="block text-sm">
              Sex
              <select value={data.sex} className={field}
                      onChange={(e) => setData("sex", e.target.value)}>
                <option value="">—</option>
                <option value="female">Female</option>
                <option value="male">Male</option>
              </select>
            </label>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              Phase
              <select value={data.current_phase_id} className={field}
                      onChange={(e) => setData("current_phase_id", e.target.value)}>
                <option value="">—</option>
                {phases.map((p) => <option key={p.id} value={p.id}>{p.name}</option>)}
              </select>
            </label>
            <label className="block text-sm">
              Phase started
              <input type="date" value={data.phase_started_on} className={field}
                     onChange={(e) => setData("phase_started_on", e.target.value)} />
            </label>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <label className="block text-sm">
              DiSC type
              <select value={data.disc_type} className={field}
                      onChange={(e) => setData("disc_type", e.target.value)}>
                <option value="">—</option>
                {["D", "i", "S", "C"].map((d) => <option key={d} value={d}>{d}</option>)}
              </select>
            </label>
            <label className="block text-sm">
              Max HR
              <input type="number" inputMode="numeric" value={data.max_hr} className={field}
                     onChange={(e) => setData("max_hr", e.target.value)} />
              <span className="mt-1 block text-xs text-neutral-500 dark:text-neutral-400">
                Blank estimates from age
              </span>
            </label>
          </div>

          <fieldset className="space-y-2">
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={data.uses_power_block} className="size-4"
                     onChange={(e) => setData("uses_power_block", e.target.checked)} />
              Programs a Power block
            </label>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" checked={data.uses_vbt} className="size-4"
                     onChange={(e) => setData("uses_vbt", e.target.checked)} />
              Uses velocity tracking
            </label>
          </fieldset>

          <label className="block text-sm">
            Intake notes
            <textarea value={data.intake_notes} rows={4}
                      className={`${field} min-h-24 py-2`}
                      onChange={(e) => setData("intake_notes", e.target.value)} />
          </label>

          <div className="flex gap-2 pt-2">
            <button type="submit" disabled={processing}
                    className="min-h-11 flex-1 rounded-lg bg-neutral-900 px-4 text-sm font-medium
                               text-white disabled:opacity-60 dark:bg-neutral-100 dark:text-neutral-900">
              {editing ? "Save" : "Add client"}
            </button>
            <Link href={editing ? `/clients/${client.id}` : "/clients"}
                  className="inline-flex min-h-11 items-center rounded-lg border border-neutral-300
                             px-4 text-sm dark:border-neutral-700">
              Cancel
            </Link>
          </div>
        </form>
      </main>
    </Shell>
  )
}
