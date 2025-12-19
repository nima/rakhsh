return {
    source_dir = "tl",
    build_dir  = "lua",
    include_dir = {
        "tl",
        "../src/tl/types",
        "../extern/teal-types/types/neovim",
        "../extern/teal-types/types/luv",
    },
    global_env_def = "vim",
}
