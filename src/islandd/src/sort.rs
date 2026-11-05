use crate::util::home;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::Duration;

const INTERVAL: Duration = Duration::from_secs(5);

const CATEGORIES: &[(&str, &[&str])] = &[
    ("Images", &["jpg", "jpeg", "png", "gif", "webp", "bmp", "svg", "avif", "heic", "ico", "tiff"]),
    ("Video", &["mp4", "mkv", "webm", "avi", "mov", "m4v", "flv", "wmv"]),
    ("Audio", &["mp3", "flac", "wav", "ogg", "opus", "m4a", "aac", "wma"]),
    ("Documents", &["pdf", "epub", "djvu", "doc", "docx", "odt", "rtf", "txt", "md", "xls", "xlsx",
                    "ods", "csv", "ppt", "pptx", "odp"]),
    ("Archives", &["zip", "tar", "gz", "xz", "bz2", "zst", "7z", "rar", "tgz", "lz4"]),
    ("Packages", &["pkg", "deb", "rpm", "appimage", "apk", "flatpakref", "exe", "msi", "dmg"]),
    ("Code", &["py", "sh", "js", "ts", "rs", "go", "c", "h", "cpp", "java", "rb", "lua", "json",
               "toml", "yaml", "yml", "patch", "diff"]),
    ("Torrents", &["torrent"]),
    ("Disks", &["iso", "img", "qcow2", "vdi"]),
    ("Fonts", &["ttf", "otf", "woff", "woff2"]),
];

const PARTIAL: &[&str] = &[".part", ".crdownload", ".download", ".tmp", ".partial", ".!qb", ".aria2"];

const MIME_PREFIXES: &[(&str, &str)] = &[
    ("image/", "Images"), ("video/", "Video"), ("audio/", "Audio"), ("text/", "Documents"), ("font/", "Fonts"),
];

const MIME_EXACT: &[(&str, &str)] = &[
    ("application/pdf", "Documents"), ("application/epub+zip", "Documents"),
    ("application/zip", "Archives"), ("application/x-tar", "Archives"),
    ("application/gzip", "Archives"), ("application/x-xz", "Archives"),
    ("application/zstd", "Archives"), ("application/x-7z-compressed", "Archives"),
    ("application/x-rar", "Archives"), ("application/x-bittorrent", "Torrents"),
    ("application/vnd.debian.binary-package", "Packages"), ("application/x-rpm", "Packages"),
    ("application/x-alpine-package", "Packages"), ("application/x-executable", "Packages"),
    ("application/x-sharedlib", "Packages"), ("application/x-dosexec", "Packages"),
    ("application/x-iso9660-image", "Disks"), ("application/x-shellscript", "Code"),
    ("text/x-shellscript", "Code"), ("text/x-python", "Code"), ("text/x-script.python", "Code"),
    ("text/x-c", "Code"), ("text/x-c++", "Code"), ("text/x-java", "Code"), ("text/x-lua", "Code"),
    ("text/x-ruby", "Code"), ("text/x-perl", "Code"), ("text/x-php", "Code"),
    ("text/javascript", "Code"), ("text/css", "Code"), ("text/html", "Code"), ("text/xml", "Code"),
    ("text/csv", "Documents"), ("text/markdown", "Documents"), ("application/json", "Code"),
    ("application/xml", "Code"), ("application/x-sqlite3", "Documents"),
];

const SCRUB_EXT: &[&str] = &[
    "jpg", "jpeg", "png", "webp", "tif", "tiff", "heic", "avif", "mp4", "mkv", "mov", "webm", "m4v",
    "mp3", "flac", "m4a", "opus", "ogg", "wav", "pdf",
];

fn ext(p: &Path) -> String {
    p.extension().map(|e| e.to_string_lossy().to_lowercase()).unwrap_or_default()
}

fn by_mime(p: &Path) -> Option<&'static str> {
    let out = Command::new("file")
        .args(["--brief", "--mime-type", "--"])
        .arg(p)
        .stderr(Stdio::null())
        .output()
        .ok()
        .filter(|o| o.status.success())?;
    let mime = String::from_utf8_lossy(&out.stdout).trim().to_lowercase();
    if let Some((_, f)) = MIME_EXACT.iter().find(|(m, _)| *m == mime) {
        return Some(f);
    }
    MIME_PREFIXES.iter().find(|(pre, _)| mime.starts_with(pre)).map(|(_, f)| *f)
}

fn category(p: &Path) -> &'static str {
    let lower = p.file_name().unwrap_or_default().to_string_lossy().to_lowercase();
    if [".tar.gz", ".tar.xz", ".tar.bz2", ".tar.zst"].iter().any(|s| lower.ends_with(s)) {
        return "Archives";
    }
    let e = ext(p);
    if let Some((f, _)) = CATEGORIES.iter().find(|(_, exts)| exts.contains(&e.as_str())) {
        return f;
    }
    by_mime(p).unwrap_or("Other")
}

fn unique_target(t: PathBuf) -> PathBuf {
    if !t.exists() {
        return t;
    }
    let stem = t.file_stem().unwrap_or_default().to_string_lossy().into_owned();
    let suffix = t.extension().map(|e| format!(".{}", e.to_string_lossy())).unwrap_or_default();
    (2..)
        .map(|n| t.with_file_name(format!("{stem} ({n}){suffix}")))
        .find(|c| !c.exists())
        .unwrap()
}

fn candidates(dir: &Path) -> Vec<PathBuf> {
    let Ok(rd) = fs::read_dir(dir) else { return vec![] };
    rd.flatten()
        .filter_map(|e| {
            let name = e.file_name().to_string_lossy().into_owned();
            let p = e.path();
            if p.is_dir() || name.starts_with('.') {
                return None;
            }
            let lower = name.to_lowercase();
            (!PARTIAL.iter().any(|s| lower.ends_with(s))).then_some(p)
        })
        .collect()
}

fn move_file(from: &Path, to: &Path) -> std::io::Result<()> {
    match fs::rename(from, to) {
        Err(e) if e.raw_os_error() == Some(libc::EXDEV) => {
            fs::copy(from, to)?;
            fs::remove_file(from)
        }
        r => r,
    }
}

fn scrub(p: &Path) {
    let tool = home().join(".local/bin/scrub-meta");
    if !SCRUB_EXT.contains(&ext(p).as_str()) || !tool.is_file() {
        return;
    }
    let _ = Command::new(tool).arg(p).stdout(Stdio::null()).stderr(Stdio::null()).status();
}

fn notify(count: usize) {
    let word = if count == 1 { "file" } else { "files" };
    let _ = Command::new("notify-send")
        .args(["-a", "downloads-sort", "-i", "folder-download", "Downloads sorted"])
        .arg(format!("{count} {word} filed away"))
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

pub fn run() {
    let dir = home().join("Downloads");
    if !dir.is_dir() {
        eprintln!("{} does not exist", dir.display());
        std::process::exit(1);
    }
    let mut last: HashMap<PathBuf, u64> = HashMap::new();
    loop {
        let mut moved = 0;
        let mut seen = HashMap::new();
        for p in candidates(&dir) {
            let Ok(meta) = fs::metadata(&p) else { continue };
            let size = meta.len();
            seen.insert(p.clone(), size);
            if last.get(&p) != Some(&size) {
                continue;
            }
            let folder = dir.join(category(&p));
            let _ = fs::create_dir(&folder);
            let target = unique_target(folder.join(p.file_name().unwrap()));
            match move_file(&p, &target) {
                Ok(()) => {
                    scrub(&target);
                    moved += 1;
                }
                Err(e) => eprintln!("skip {}: {e}", p.file_name().unwrap().to_string_lossy()),
            }
        }
        last = seen;
        if moved > 0 {
            notify(moved);
        }
        std::thread::sleep(INTERVAL);
    }
}
