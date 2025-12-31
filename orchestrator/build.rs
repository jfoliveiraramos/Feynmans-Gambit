use std::{path::PathBuf, process::Command};

fn main() {
    let status = Command::new("zig")
        .args(&["build", "lib"])
        .current_dir("../engine")
        .status()
        .expect("failed to run Zig build");

    if !status.success() {
        panic!("Zig build failed");
    }

    let zig_lib = PathBuf::from("../engine/zig-out/lib");

    println!("cargo:rustc-link-search=native={}", zig_lib.display());
    println!("cargo:rustc-link-lib=static=engine");

    // Re-run if Zig lib changes
    println!("cargo:rerun-if-changed=../engine/src");
}
