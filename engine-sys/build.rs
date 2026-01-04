// Branches' Gambit Copyright (C) 2025 João Ramos
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

use std::{env, path::PathBuf, process::Command};

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let project_root = manifest_dir.parent().expect("Failed to find project root");

    let shared_header = project_root.join("shared").join("constants.h");
    let engine_dir = project_root.join("engine");
    let engine_src = engine_dir.join("src");
    let engine_lib_dir = engine_dir.join("zig-out").join("lib");

    let bindings = bindgen::Builder::default()
        .header(shared_header.to_str().unwrap())
        .parse_callbacks(Box::new(bindgen::CargoCallbacks::new()))
        .generate()
        .expect("Unable to generate bindings");

    let out_path = PathBuf::from(env::var("OUT_DIR").unwrap());
    bindings
        .write_to_file(out_path.join("constants.rs"))
        .expect("Couldn't write bindings!");

    if Command::new("zig").arg("--version").status().is_err() {
        panic!("Zig is not installed or not in PATH");
    }

    let status = Command::new("zig")
        .args(&["build", "lib"])
        .current_dir(&engine_dir)
        .status()
        .expect("failed to run Zig build");

    if !status.success() {
        panic!("Zig build failed");
    }

    let engine_lib_resolved = engine_lib_dir
        .canonicalize()
        .expect("Zig output directory does not exist");

    println!(
        "cargo:rustc-link-search=native={}",
        engine_lib_resolved.display()
    );
    println!("cargo:rustc-link-lib=static=engine");

    println!("cargo:rerun-if-changed={}", shared_header.display());
    println!("cargo:rerun-if-changed={}", engine_src.display());
}
