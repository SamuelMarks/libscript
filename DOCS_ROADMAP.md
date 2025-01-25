Docs: Roadmap
=============

Each directory containing a `setup.sh` will also contain:

  - README.md
  - libscript.json (modelled after vcpkg.json)
    - static analyses of source-code will enable auto-inference of:
      - `.dependencies`
      - `.description` (first text line after title heading)
      - `.os_support`

Then a separate static site generator will take all these and create:

  - Versioned drop-down selectable docs
  - Docs having the README.md for each `port' (to use vcpkg nomenclature)
  - For each port also infer and auto-document what parameters are taken and/or settable in env vars
  - Outside of libscript's website, tree-shake to produce a website just for this port and its dependencies

[outside DOCS_ROADMAP.md scope: but this could then be used to tree-shake so only used libraries are the libscript-for-your-project]
