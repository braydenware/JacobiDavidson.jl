using Documenter, JacobiDavidson

makedocs(
    modules = [JacobiDavidson],
    clean = false,
    format = :html,
    sitename = "JacobiDavidson.jl",
    authors = "Harmen Stoppels",
    linkcheck = !("skiplinks" in ARGS),
    pages = [
        "Home" => "index.md"
    ],
    html_prettyurls = !("local" in ARGS),
)

deploydocs(
    repo = "github.com/haampie/JacobiDavidson.jl.git",
    target = "build",
    deps = nothing,
    make = nothing,
)