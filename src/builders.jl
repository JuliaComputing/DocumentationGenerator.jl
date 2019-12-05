function build_git_docs(packagespec, buildpath, uri)
    return mktempdir() do dir
        return cd(dir) do
            run(`git clone --depth=1 $(uri) docsource`)
            docsproject = joinpath(dir, "docsource")
            return cd(docsproject) do
                return build_local_docs(packagespec, docsproject, "", docsproject)
            end
        end
    end
end

function build_hosted_docs(packagespec, buildpath, uri)
    pkgname = packagespec.name
    # js redirect
    open(joinpath(buildpath, "index.html"), "w") do io
        println(io,
            """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
                    <script type="text/javascript">
                        window.onload = function () {
                            window.location.replace("$(uri)");
                        }
                    </script>
                </head>
                <body>
                    Redirecting to <a href="$(uri)">$(uri)</a>.
                </body>
            </html>
            """
        )
    end
    # download search index
    try
        download(string(uri, "/search_index.js"), joinpath(buildpath, "search_index.js"))
    catch err
        @error("Search index download failed for `$(uri)`.", exception = err)
    end
    return Dict(
        "doctype" => :hosted,
        "success" => true
    )
end

function build_local_docs(packagespec, buildpath, uri, pkgroot = nothing)
    uri = something(uri, "docs")
    mktempdir() do envdir
        pkgname = packagespec.name
        installable = try_install_package(packagespec, envdir)

        documenter_errored = false

        if !installable
            @error("$(pkgname) is not installable. Stopped building docs.")
            return Dict(
                "installable" => false,
                "success" => false
            )
        end
        if pkgroot === nothing
            pkgfile = Base.find_package(pkgname)
            pkgroot = normpath(joinpath(pkgfile, "..", ".."))
        end
        mod = try_use_package(packagespec)

        # package doesn't load, so let's only use the README
        if mod === nothing
            return mktempdir() do docsdir
                output = build_readme_docs(pkgname, pkgroot, docsdir, mod)
                if output !== nothing
                    cp(output, buildpath, force = true)
                    return Dict(
                        "doctype" => :fallback,
                        "installable" => true,
                        "success" => true
                    )
                end
                return Dict(
                    "doctype" => :fallback,
                    "installable" => true,
                    "success" => false
                )
            end
        end

        # actual Documenter docs
        for docdir in joinpath.(pkgroot, (uri, "docs", "doc"))
            if isdir(docdir)
                output = build_documenter(packagespec, docdir)
                if output !== nothing
                    cp(output, buildpath, force = true)
                    return Dict(
                        "doctype" => :documenter,
                        "documenter_errored" => documenter_errored,
                        "installable" => true,
                        "success" => true
                    )
                end
                documenter_errored = true
            end
        end

        # fallback docs (readme & docstrings)
        return mktempdir() do docsdir
            output = build_readme_docs(pkgname, pkgroot, docsdir, mod)
            if output !== nothing
                cp(output, buildpath, force = true)
                return Dict(
                    "doctype" => :fallback_autodocs,
                    "documenter_errored" => documenter_errored,
                    "installable" => true,
                    "success" => true
                )
            end
            return Dict(
                "doctype" => :fallback_autodocs,
                "documenter_errored" => documenter_errored,
                "installable" => true,
                "success" => false
            )
        end
    end
end

function build_legacy_documenter(packagespec, docdir)
    open(joinpath(docdir, "Project.toml"), "w") do io
        println(io, """
            [deps]
            Documenter = "e30172f5-a6a5-5a46-863b-614d45cd2de4"

            [compat]
            Documenter = "~0.20"
        """)
    end
    build_documenter(packagespec, docdir)
end

function build_documenter(packagespec, docdir)
    cd(docdir) do
        docsproject = joinpath(docdir, "Project.toml")
        docsmanifest = joinpath(docdir, "Manifest.toml")
        if !isfile(docsproject)
            return build_legacy_documenter(packagespec, docdir)
        end

        # fix permissions to allow us to add the main pacakge to the docs project
        chmod(docsproject, 0o660)
        isfile(docsmanifest) && chmod(docsmanifest, 0o660)

        rundcocumenter = joinpath(@__DIR__, "rundocumenter.jl")

        cmd = ```
            $(first(Base.julia_cmd()))
                --project="$(docdir)"
                $(rundcocumenter)
                $(docdir)
            ```

        makefile = joinpath(docdir, "make.jl")
        _, builddir = fix_makefile(makefile)

        try
            run(cmd)

            return builddir
        catch err
            @error("Failed to evaluate specified make.jl-file.", exception=err)
            return nothing
        end
    end
end

function build_readme_docs(pkgname, pkgroot, docsdir, mod)
    @info("Generating readme-only fallback docs.")

    if pkgroot === nothing || !ispath(pkgroot)
        @error("Julia could not find the package directory. Aborting.")
        return
    end

    pkgloads = mod !== nothing

    readme = find_readme(pkgroot)
    doc_src = joinpath(docsdir, "src")
    mkpath(doc_src)
    index = joinpath(doc_src, "index.md")
    preprocess_readme(readme, index)

    pages = ["Readme" => "index.md"]
    modules = :(Module[Module()])

    if pkgloads
        @info("Deploying `autodocs`.")
        add_autodocs(doc_src, mod)
        push!(pages, "Docstrings" => "autodocs.md")
        modules = :(Module[$mod])
    end

    @eval Module() begin
        using Pkg
        Pkg.add("Documenter")
        using Documenter
        makedocs(
            format = Documenter.HTML(),
            sitename = "$($pkgname).jl",
            modules = $(modules),
            root = $(docsdir),
            pages = $(pages)
        )
    end

    build_dir = joinpath(docsdir, "build")
    if ispath(build_dir)
        return build_dir
    end
    return nothing
end

function find_readme(pkgroot)
    for file in readdir(pkgroot)
        if occursin("readme", lowercase(file))
            readme = joinpath(pkgroot, file)
            if isfile(readme)
                return readme
            end
        end
    end
end

function preprocess_readme(readme, output_path)
    # GFM compatible rendering:
    rendergfm(readme, output_path)
    # copy local assets
    copylocallinks(readme, output_path)
end

function add_autodocs(docsdir, mod)
    open(joinpath(docsdir, "autodocs.md"), "w") do io
        println(io, """
        ```@autodocs
        Modules = [$(Symbol(mod))]
        ```
        """)
    end
end

function monkeypatchdocsearch(packagespec, buildpath)
    uuid = packagespec.uuid
    name = packagespec.name
    if !(get(ENV, "DISABLE_CENTRALIZED_SEARCH", false) in ("true", "1", 1))
        searchjs = joinpath(buildpath, "assets", "search.js")
        if isfile(searchjs)
            @info "monkey patching search.js for $(name)"
            rm(searchjs, force=true)
            template = String(read(joinpath(@__DIR__, "search.js.template")))
            template = replace(template, "{{{UUID}}}" => String(uuid))
            open(searchjs, "w") do io
                print(io, template)
            end
        end
    end
end

function copy_package_source(packagespec, buildpath)
    outpath = joinpath(buildpath, "_packagesource")
    try
        mktempdir() do envdir
            pkgname = packagespec.name
            installable = try_install_package(packagespec, envdir)

            if !installable
                @error("Package not installable. Can't get source code.")
                return
            end
            pkgfile = Base.find_package(pkgname)
            pkgroot = normpath(joinpath(pkgfile, "..", ".."))

            @info("Copying source code for $(pkgname).")
            if isdir(pkgroot)
                cp(pkgroot, outpath; force=true)
            end
            @info("Done copying source code for $(pkgname).")
            return outpath
        end
    catch err
        @error("Error trying to copy package source.", exception=err)
    end
end
