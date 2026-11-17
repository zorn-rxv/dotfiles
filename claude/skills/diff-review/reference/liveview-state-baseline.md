# LiveView state baseline

Phoenix LiveView–first. The concern *names* — full struct, should-be-stream, refetchable data, unrendered sensitive fields — transfer to any stateful server UI even where the specific *fix* does not.

Each LiveView process holds its assigns for as long as the page stays open, so the cost multiplies with the number of connected users. Large assigns also slow the diff LiveView computes after each change.

Leave how many rows a query loads to the Database axis. This baseline covers what an assign keeps after the load.

Judge each new or changed assign against the template that renders it: the `.heex` file or `render/1`. Read that template even when the diff leaves it unchanged, since "the page reads only a few fields" cannot be judged without it.

- Full struct where the template reads a few fields — the assign holds a whole Ecto struct, with every column and preload, and the page renders only a few of them. → `select: struct(p, [:id, :name])`, or a small map of the fields the page reads.
- Collection that should be a stream — a list assign that grows, or that renders as a long feed or table. The whole list stays in server memory until the page closes. → `stream/3`, which frees each item once it renders.
- Data the page could fetch again on demand — picker options, search results, or a detail record kept in assigns after the interaction ends. → clear the assign then, and fetch again when the interaction starts over.
- Sensitive fields the page never renders — encrypted columns, PII, or third-party API payloads ride along in an assign. The size concern and the data-exposure concern share one fix. → select only the fields the page renders.
