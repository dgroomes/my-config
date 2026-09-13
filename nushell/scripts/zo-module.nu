# Warning: Mostly unedited AI output

use zdu.nu err

# A Nushell interface over Zowe CLI
#
# For now, this works great. It compresses the workflow of using Zowe so that I can use the mainframe with fluency.
# It is NOT a goal to "build up a tall mound over the Zowe CLI". That would be inappropriate because the CLI is the
# wrong foundation. Instead, if I wanted to get a richer (and customized to me) experience (e.g. caching for
# auto-complete, my own abbreviated config/auth story) then I would build on the z/OSMF REST API directly. Zowe is
# building towards an interesting Zowe server-side executable thing that you invoke with an SSH flow, so keep an eye on
# that as well.
export def zo [] {
    help zo
}

# Assert that Zowe CLI is on PATH without invoking it.
def _zo-path-check [] {
    let executable = which zowe | where type == external
    if ($executable | is-empty) {
        err "zo requires the zowe CLI  on the PATH"
    }
}

# List PDS members as a compact table of names, record counts, and modification details.
#
#     zo ds ls-members ZXP.PUBLIC.INPUT
#     zo ds ls-members ZXP.PUBLIC.INPUT --long
export def "zo ds ls-members" [
    name: string # Partitioned dataset name
    --long(-l)   # Return every member attribute
]: nothing -> table {
    let name = $name | str trim | str uppercase
    if ($name | is-empty) {
        err "Provide a partitioned dataset name."
    }
    let response = zowe-json [zos-files list all-members $name --attributes]
    let listing = $response | get data.apiResponse
    if ($listing.moreRows? | default false) {
        err "Zowe returned a partial member list. Use the Zowe CLI --pattern option to narrow the results."
    }
    let members = $listing | get items
    if $long {
        $members
    } else {
        $members | select --optional member cnorc m4date mtime user
    }
}

# View a dataset or member as plain text for display or further pipelining.
#
#     zo ds view 'Z123456.SOURCE(RECIPE)'
#     zo ds view 'Z123456.SOURCE(RECIPE)' | lines
export def "zo ds view" [
    dataset: string # Dataset or DATA.SET(MEMBER) to read
]: nothing -> string {
    _zo-path-check
    let result = ^zowe zos-files view data-set $dataset | complete
    if $result.exit_code != 0 {
        err $"Zowe CLI failed; exit code ($result.exit_code): ($result.stderr | str trim)"
    }
    $result.stdout
}

# Copy a dataset or member using Zowe's native source and destination syntax.
# Quote member references so parentheses are passed as part of the name.
#
#     zo ds cp 'ZXP.PUBLIC.INPUT(PDSPART1)' 'Z123456.SOURCE(PDSPART1)'
#     zo ds cp 'ZXP.PUBLIC.INPUT(PDSPART2)' 'Z123456.SOURCE(PDSPART2)'
#     zo ds cp 'ZXP.PUBLIC.JCL(PDS1CCAT)' 'Z123456.JCL(PDS1CCAT)'
export def "zo ds cp" [
    source: string      # Source dataset or DATA.SET(MEMBER)
    destination: string # Destination dataset or DATA.SET(MEMBER)
    --replace           # Replace an existing destination member
]: nothing -> record {
    let args = [zos-files copy data-set $source $destination]
    let args = if $replace { $args | append '--replace' } else { $args }
    let response = zowe-json $args
    {
        source: $source
        destination: $destination
        message: ($response.data.commandResponse? | default "Copy completed.")
    }
}

# Rename a member within a PDS or PDSE using Zowe's native three-argument syntax.
#
#     zo ds rename-member Z123456.SOURCE PDS1OUT RECIPE
export def "zo ds rename-member" [
    dataset: string # Dataset containing the member
    before: string  # Current member name, without dataset or parentheses
    after: string   # New member name, without dataset or parentheses
]: nothing -> record {
    let response = zowe-json [zos-files rename data-set-member $dataset $before $after]
    {
        dataset: $dataset
        before: $before
        after: $after
        message: ($response.data.commandResponse? | default "Member renamed.")
    }
}

# Submit JCL from a dataset or member using Zowe's native dataset syntax.
# Submission success means JES accepted the job; inspect retcode after it reaches OUTPUT.
#
#     zo jobs submit 'Z123456.JCL(PDS1CCAT)'
#     zo jobs submit 'Z123456.JCL(PDS1CCAT)' --wait-for-output
#     zo jobs submit 'Z123456.JCL(PDS1CCAT)' --wait-for-output -l
export def "zo jobs submit" [
    dataset: string   # Dataset or DATA.SET(MEMBER) containing JCL
    --wait-for-output # Wait until the submitted job reaches OUTPUT status
    --long(-l)        # Return every job attribute
]: nothing -> record {
    let args = [zos-jobs submit data-set $dataset]
    let args = if $wait_for_output { $args | append '--wait-for-output' } else { $args }
    let response = zowe-json $args
    let job = $response | get data
    if $long {
        $job
    } else {
        $job | select --optional jobid jobname owner status retcode
    }
}

# Run Zowe in JSON mode. Keep failed commands distinct from empty successful results.
def zowe-json [args: list<string>]: nothing -> record {
    _zo-path-check
    let result = ^zowe ...$args --response-format-json | complete
    let response = try {
        $result.stdout | from json --strict
    } catch {
        err $"Zowe CLI did not return valid JSON; exit code ($result.exit_code): ($result.stderr | str trim)"
    }

    if $result.exit_code != 0 or ($response.success? != true) {
        let detail = [
            ($response.message? | default "")
            ($response.stderr? | default "")
            ($result.stderr | str trim)
        ] | where {|text| $text != "" } | str join "\n"
        err $"Zowe CLI failed; exit code ($result.exit_code): ($detail)"
    }
    $response
}

# List datasets as a compact table of names, organization, record layout, and volume.
# A bare HLQ becomes HLQ.*; dotted names and quoted patterns are passed through.
#
#     zo ds ls Z123456
#     zo ds ls 'ZXP.PUBLIC.*'
#     zo ds ls Z123456 | select dsname dsorg recfm lrecl
#     zo ds ls Z123456 --long
export def "zo ds ls" [
    name: string          # High-level qualifier, exact dataset name, or quoted pattern
    --long(-l)            # Return every attribute instead of the compact default columns
]: nothing -> table {
    let name = $name | str trim | str uppercase
    if ($name | is-empty) {
        err "Provide a high-level qualifier, dataset name, or pattern."
    }
    let pattern = if ($name | str contains '.') or ($name | str contains '*') or ($name | str contains '%') {
        $name
    } else {
        $"($name).*"
    }
    let args = [zos-files list data-set $pattern --attributes]
    let response = zowe-json $args
    let listing = $response | get data.apiResponse
    if ($listing.moreRows? | default false) {
        err "Zowe returned a partial dataset list. Use a narrower pattern or the Zowe CLI --start option to page through results."
    }
    let datasets = $listing | get items
    if $long {
        $datasets
    } else {
        $datasets | select --optional dsname dsorg recfm lrecl blksz volser
    }
}
