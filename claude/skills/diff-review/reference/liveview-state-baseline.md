# LiveView state baseline

Phoenix LiveView–first. The concern — data held in per-connection server state that the page never needs — transfers to any stateful server UI, even where the specific fix does not.

Each LiveView process holds its assigns for as long as the page stays open, so the cost multiplies by every connected user. Large assigns also slow the diff LiveView computes after each change.

Judge each new or changed assign against the template that renders it: the `.heex` file or `render/1`. Read that template even when the diff leaves it unchanged, since "the page reads only a few fields" cannot be judged without it.

- Full struct where the template reads a few fields — the assign holds a whole Ecto struct, with every column and preload, and the page renders two of them. → `select: struct(p, [:id, :name])`, or a small map of the fields the page reads.
- Collection that should be a stream — a list assign that grows, or that the page renders as a long feed or table, stays in memory in full for the whole session. → `stream/3`, so LiveView keeps only the DOM, not the data.
- Data the page could fetch again on demand — picker options, search results, or a detail record kept in assigns after the picker, search, or modal closes. → clear the assign when the interaction ends, and fetch again when it reopens.
- Sensitive fields the page never renders — encrypted columns, PII, or third-party API payloads ride along in an assign. The size concern and the data-exposure concern share one fix. → select only the fields the page renders.
