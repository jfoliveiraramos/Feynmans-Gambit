use std::{env, path::PathBuf, process::Command};

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());

    if Command::new("zig").arg("--version").status().is_err() {
        panic!("Zig is not installed or not in PATH");
    }

    let engine_dir = manifest_dir.parent().unwrap().join("engine");

    let status = Command::new("zig")
        .args(&["build", "lib"])
        .current_dir(&engine_dir)
        .status()
        .expect("failed to run Zig build");

    let engine_lib = engine_dir.join("zig-out/lib").canonicalize().unwrap();

    println!("cargo:rustc-link-search=native={}", engine_lib.display());

    if !status.success() {
        panic!("Zig build failed");
    }

    let zig_lib = PathBuf::from("../engine/zig-out/lib");

    println!("cargo:rustc-link-search=native={}", zig_lib.display());
    println!("cargo:rustc-link-lib=static=engine");

    // Re-run if Zig lib changes
    println!("cargo:rerun-if-changed=../engine/src");
}
