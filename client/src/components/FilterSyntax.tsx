export function FilterSyntax () {
  return (
    <details className="text-sm text-neutral-700 mt-1 w-full">
      <summary className="cursor-pointer">Advanced syntax</summary>

      <p>
        Prefix a term with an exclamation mark (!) to exclude it:
        <blockquote className="ps-5">!cobblestone</blockquote>
      </p>

      <p>
        Filter supports JEI prefixes for:
      </p>
      <ul className="list-disc ps-5">
        <li>@mod_name</li>
        <li>&item_id</li>
        <li>$ore_dict</li>
      </ul>

      <p>
        To match multiple filters, use the pipe (|) character:
        <blockquote className="ps-5">iron ore | dirt | cobblestone</blockquote>
      </p>
    </details>
  )
}