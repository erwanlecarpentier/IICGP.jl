t = Template(;
    user="erwanlecarpentier",
    license="MIT",
    authors="Erwan Lecarpentier",
    julia=v"1.5",
    plugins=[
        License(; name="MPL"),
        Git(; manifest=true, ssh=true),
        GitHubActions(; x86=true),
        Codecov(),
        Documenter{GitHubActions}(),
        Develop(),
    ],
)

import Pkg; Pkg.add("IICGP")
